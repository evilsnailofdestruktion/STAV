local U = Ext.Require("Shared/Utility.lua")
local P = Ext.Require("Shared/Printing.lua")

if Ext.IsClient() then
	local O = Ext.Require("Client/Overriding.lua")

	Ext.RegisterConsoleCommand("stav", function()
		STAVToggleUI()
	end)

	local BUILT_IN = { Shared = true, SharedDev = true, STAV = true }
	local RUNTIME  = { Info = { Name = "Created at runtime", ModuleUUID = U.NULL_UUID } }

	local function publicDir(path)
		return path:match("[Pp]ublic/([^/]+)/[Aa]ssets/")
	end

	local function shaderLOD(path)
		local lod = path:lower():match("lod(%d)[^/]*$") or "0"
		return lod == "3" and "2" or lod
	end

	local function isHeadShader(file)
		local name = file:lower()
		return name:find("^char_skin_head_v3") and not name:find("_gm", 1, true)
	end

	local function meshName(objectId)
		return objectId:match("^[^.]+%.(.+)%.%d+$") or objectId
	end

	local function writeParams(log, names)
		if #names > 10 then return log:C4(#names):C7(" params") end
		for i, name in ipairs(names) do
			log:C7(i > 1 and ", " or ""):C4(name:match(":(.+)$") or name)
		end
		return log
	end

	local function compareHead(names, run)
		local isHead, best = false, nil
		for lod, ref in pairs(run.refs) do
			local missing, extra, required = {}, {}, 0
			for name in pairs(ref) do
				if not names[name] then
					missing[#missing + 1] = name
					if not run.optional[name] then required = required + 1 end
				end
			end
			for name in pairs(names) do
				if not ref[name] then extra[#extra + 1] = name end
			end
			isHead = isHead or required == 0
			if not best or #missing + #extra < #best.missing + #best.extra then
				best = { lod = lod, missing = missing, extra = extra }
			end
		end
		table.sort(best.missing)
		table.sort(best.extra)
		return isHead, best
	end

	local function closestIssues(issues)
		local fewest, closest = math.huge, {}
		for _, issue in ipairs(issues) do fewest = math.min(fewest, #issue.params) end
		for _, issue in ipairs(issues) do
			if #issue.params == fewest then closest[#closest + 1] = issue end
		end
		return closest
	end

	local function addIssue(head, issue)
		head.issues[#head.issues + 1] = issue
		head.has[issue.kind] = true
	end

	local function checkMaterials(head, visual, run)
		local patchable, failed, foreign = false, {}, {}
		for _, o in ipairs(visual.Objects) do
			local mesh, mat = meshName(o.ObjectID), Ext.Resource.Get(o.MaterialID, "Material")
			if not mat then
				addIssue(head, { kind = "missingMaterial", mesh = mesh, id = o.MaterialID })
			else
				local dir, shader = publicDir(mat.SourceFile), mat.SourceFile:match("[^/]+$")
				local isHead, best = compareHead(O.paramNames(mat), run)
				local flesh, blanks = mat.MaterialType == "Flesh", O.blanksAtlases(mat)
				if isHead and flesh and not blanks then
					patchable = true
					run.users[o.MaterialID] = run.users[o.MaterialID] or {}
					run.users[o.MaterialID][head] = mesh

					local lod, before = shaderLOD(mat.SourceFile), #head.issues
					if dir ~= "STAV" then addIssue(head, { kind = "unpatched", mesh = mesh, shader = shader, matched = true }) end
					if #best.missing > 0 then addIssue(head, { kind = "lacksParams", mesh = mesh, params = best.missing }) end
					if #best.extra > 0 then addIssue(head, { kind = "extraParams", mesh = mesh, params = best.extra }) end
					if best.lod ~= lod then addIssue(head, { kind = "wrongLOD", mesh = mesh, from = best.lod, to = lod }) end
					if #head.issues > before then
						run.problMats[o.MaterialID] = true
						head.has.matIssue = true
					end
				else
					local list = isHeadShader(shader) and failed or not BUILT_IN[dir] and foreign
					if list then
						list[#list + 1] = {
							kind = "unpatched",
							mesh = mesh,
							shader = shader,
							materialType = not flesh and tostring(mat.MaterialType),
							blanks = blanks,
							params = best.missing
						}
					end
				end
			end
		end
		if not patchable then
			for _, issue in ipairs(#failed > 0 and failed or closestIssues(foreign)) do addIssue(head, issue) end
		end
	end

	local function findOwnShaders(heads, run)
		local shaders, scanned, copied = {}, {}, {}
		for _, head in ipairs(heads) do
			local dir = head.mod.Info.Directory
			if dir and not BUILT_IN[dir] and not scanned[dir] then
				scanned[dir] = true
				local root = "Public/" .. dir .. "/Content"
				for _, file in ipairs(Ext.IO.FindFiles(root, "*.lsf", "data", true)) do
					local raw = Ext.IO.LoadFile(root .. "/" .. file, "data") or ""
					for matId, using in pairs(run.users) do
						local at = not copied[matId] and raw:find(matId, 1, true)
						local shader = at and raw:match("([%w_%-%./]+%.lsf)", at + #matId)
						if shader and not BUILT_IN[publicDir(shader)] then
							copied[matId] = true
							shaders[shader] = true
							run.problMats[matId] = true
							for user, mesh in pairs(using) do
								addIssue(user, { kind = "ownShader", mesh = mesh, shader = shader:match("[^/]+$") })
								user.has.matIssue = true
							end
						end
					end
				end
			end
		end
		return shaders
	end

	local function collectHeads(modId)
		local run, owner = { refs = {}, optional = {}, users = {}, problMats = {} }, {}
		for lod, shader in pairs(O.HEAD_SHADERS) do
			run.refs[lod] = O.paramNames(Ext.Resource.Get(shader.vanilla, "Material"))
		end
		for _, name in ipairs(O.OPTIONAL_HEAD_PARAMS) do run.optional[name] = true end
		for mod, ids in pairs(Ext.StaticData.GetSources("CharacterCreationAppearanceVisual")) do
			for _, id in pairs(ids) do owner[id] = mod end
		end

		local heads, seen = {}, {}
		for _, id in ipairs(Ext.StaticData.GetAll("CharacterCreationAppearanceVisual")) do
			local cc = Ext.StaticData.Get(id, "CharacterCreationAppearanceVisual")
			local visualId = cc.VisualResource
			if cc.SlotName == "Head" and visualId ~= U.NULL_UUID and not seen[visualId] then
				seen[visualId] = true
				-- Ext.Mod.GetMod(owner[id]) should normally never be nil but just in case.
				local mod = owner[id] and Ext.Mod.GetMod(owner[id]) or RUNTIME
				if not modId or mod.Info.ModuleUUID == modId then
					local visual = Ext.Resource.Get(visualId, "Visual")
					local head = {
						mod = mod,
						id = visualId,
						display = cc.DisplayName:Get() or id,
						name = visual and visual.SourceFile:match("([^/]+)%.%w+$") or "missing visual",
						issues = {},
						has = {}
					}
					heads[#heads + 1] = head
					if visual then checkMaterials(head, visual, run) else addIssue(head, { kind = "missingVisual" }) end
				end
			end
		end

		return heads, run.problMats, findOwnShaders(heads, run)
	end

	local function printIssue(issue)
		local log = P.Log():C7("      ")
		if issue.kind == "missingVisual" then
			log:C7("Visual does not resolve."):Print()
			return
		end

		log:C5(issue.mesh)
		if issue.kind == "missingMaterial" then
			if issue.id == "" then
				log:C7(" has no material.")
			else
				log:C7(" uses missing material ["):C3(issue.id):C7("].")
			end
		elseif issue.kind == "ownShader" then
			log:C7(" uses its own copy of the head shader ["):C17(issue.shader):C7("].")
		elseif issue.kind == "lacksParams" then
			writeParams(log:C7(" lacks "), issue.params):C7(".")
		elseif issue.kind == "extraParams" then
			writeParams(log:C7(" adds "), issue.params):C7(".")
		elseif issue.kind == "wrongLOD" then
			log:C7(" carries LOD", issue.from, " params on a LOD", issue.to, " shader.")
		elseif issue.matched then
			log:C7(" matches a head shader but is not patched ["):C17(issue.shader):C7("].")
		else
			log:C7(" ["):C17(issue.shader):C7("] ")
			if issue.materialType then
				log:C7("is a ", issue.materialType, " material.")
			elseif issue.blanks then
				log:C7("blanks its atlases.")
			else
				writeParams(log:C7("lacks "), issue.params):C7(".")
			end
		end
		log:Print()
	end

	local function countHeads(heads, issue)
		local count = 0
		for _, head in ipairs(heads) do
			if head.has[issue] then count = count + 1 end
		end
		return count
	end

	local function printSection(title, heads, issue)
		local counts, mods = {}, {}
		for _, head in ipairs(heads) do
			if head.has[issue] then
				if not counts[head.mod] then
					counts[head.mod] = 0
					mods[#mods + 1] = head.mod
				end
				counts[head.mod] = counts[head.mod] + 1
			end
		end
		if #mods == 0 then return end

		P.Log():C7(title):Print()
		for _, mod in ipairs(mods) do
			P.Log():C2("   " .. mod.Info.Name):C7(" ["):C21(mod.Info.ModuleUUID):C7("]: "):C1(counts[mod]):C7(" heads."):Print()
		end
	end

	-- Someone deliver me from this lunacy that is visual modding.
	Ext.RegisterConsoleCommand("stav_heads_check", function(_, modId)
		if modId then
			local mod = U.IsGuid(modId) and Ext.Mod.GetMod(modId)
			if not mod then
				P.Log():C16("[STAV] "):C7("Mod not found or not loaded."):Print()
				return
			end
			local heads = collectHeads(modId)
			for _, head in ipairs(heads) do
				if #head.issues > 0 then
					P.Log():C7("=== "):C21(head.display):C23(" - "):C23(head.name):C7(" ["):C2(head.id):C7("]"):Print()
					for _, issue in ipairs(head.issues) do printIssue(issue) end
				end
			end
			P.Log():C16("[STAV] "):C3(#heads):C7(" heads checked for "):C2(mod.Info.Name):C7("."):Print()
			return
		end

		local heads, problMats, shaders = collectHeads()

		printSection("=== Mods with heads not patched:", heads, "unpatched")
		printSection("=== Mods with head visuals that do not resolve:", heads, "missingVisual")
		printSection("=== Mods with heads using missing materials:", heads, "missingMaterial")
		printSection("=== Mods using their own copy of the head shader:", heads, "ownShader")
		printSection("=== Modded head materials missing params:", heads, "lacksParams")
		printSection("=== Modded head materials with additional params:", heads, "extraParams")
		printSection("=== Modded head materials carrying another LOD's params:", heads, "wrongLOD")

		P.Log():C16("[STAV] "):C3(#heads):C7(" heads checked: ")
			:C3(countHeads(heads, "missingVisual")):C7(" missing visuals, ")
			:C3(countHeads(heads, "missingMaterial")):C7(" missing materials, ")
			:C3(countHeads(heads, "unpatched")):C7(" heads not patched, ")
			:C3(U.CountElements(problMats)):C7(" head materials with issues across "):C3(countHeads(heads, "matIssue")):C7(" heads, ")
			:C3(U.CountElements(shaders)):C7(" custom head shaders."):Print()
	end)

	Ext.RegisterConsoleCommand("stav_race", function(_, sub, kind, uuid)
		if sub ~= "gen" or (kind ~= "override" and kind ~= "upsert") or not uuid then
			P.Log():C16("[STAV] "):Raw("Usage: !stav_race gen <override|upsert> <mod uuid>"):Print()
			return
		end
		if not U.IsGuid(uuid) then
			P.Log():C16("[STAV] "):Raw("Invalid mod UUID."):Print()
			return
		end
		local mod = Ext.Mod.GetMod(uuid)
		if not mod then
			P.Log():C16("[STAV] "):Raw("Mod not found or not loaded."):Print()
			return
		end

		local found = {}
		local races = {}
		local seg = "/" .. mod.Info.Directory .. "/"
		for _, t in pairs(Ext.Template.GetAllRootTemplates()) do
			if t.TemplateType == "character" and t.FileName:find(seg, 1, true) then
				local ct = t --[[@as CharacterTemplate]]
				local cv = ct.CharacterVisualResourceID
				if cv ~= "" then found[cv] = ct.Name end
				if ct.Race ~= U.NULL_UUID then races[ct.Race] = true end
			end
		end

		local entries = {}
		local count = 0
		for cv, name in pairs(found) do
			local key = entries[name] and (name .. "_" .. cv:sub(1, 8)) or name
			if kind == "override" then
				entries[key] = { type = "override", charvis = { cv }, material = "" }
			else
				entries[key] = {
					type = "upsert",
					charvis = { cv },
					scarMap = "",
					scarMapNM = "",
					--[[ overrides = {
						body = {
							Scalars = { SecretTatIndex = 0 },
							Vec4 = { TattooIntensity = { 0, 0.88235295, 0, 0 } }
						}
					} ]]
				}
			end
			count = count + 1
		end

		if count == 0 then
			P.Log():C16("[STAV] "):Raw("No race charvis found for ", mod.Info.Name, "."):Print()
			return
		end

		local raceList = {}
		for race in pairs(races) do raceList[#raceList + 1] = race end
		table.sort(raceList)

		Ext.IO.SaveFile("STAVConfig.json", Ext.Json.Stringify({ Entries = entries, Races = raceList }))
		P.Log():C16("[STAV] Exported ", count, " ", kind, " charvis and ", #raceList, " races for ", mod.Info.Name, " to Script Extender/STAVConfig.json."):Print()
	end)
end
