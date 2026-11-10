local E             = Ext.Require("Shared/Events.lua")
local Params        = Ext.Require("Shared/Params.lua")
local P             = Ext.Require("Shared/Printing.lua")
local U             = Ext.Require("Shared/Utility.lua")
local Vis           = Ext.Require("Shared/Visualising.lua")

local O = {}

local CONFIG_FILE   = "STAVConfig.json"
local EMPORIUM      = "91994363-833a-4956-a552-acf0341c2e2e"
local ENGINE_BLACK  = "8f1f209a-dd37-4531-b1ee-5e81c1d169cc"
local STAV_BODY_MAT = "cd69fa48-def6-c323-ce85-07321817f10f" -- DRO_F_NKD_Body_A_000
local TOLERANCE     = 0.01

---@type table<string, { vanilla: Guid, ref: Guid, headParams?: boolean }>
O.HEAD_SHADERS      = {
	["0"] = { vanilla = "4d2f62a6-fa3e-34bf-0c30-5f5c5162f2a1", ref = "8be29c42-9d39-85c0-fe1d-f475be72bfcf", headParams = true },
	["1"] = { vanilla = "8eb32fc4-bc52-0a77-972e-f51b668e2d4c", ref = "788419de-0a61-d61e-bf4f-ce8f7098d6f7", headParams = true },
	["2"] = { vanilla = "81a56635-2d78-920d-79b9-cd64934a0844", ref = "6054be7e-5084-b747-abd0-4c7e19768ba9", headParams = true },
	["4"] = { vanilla = "7d56755e-eacf-b236-c1b9-876b424b12ee", ref = "fc6c66c5-c857-4d65-1076-b8f236a7ac13" }
}

local PARAM_LISTS   = {
	"ScalarParameters",
	"Texture2DParameters",
	"VectorParameters",
	"Vector2Parameters",
	"Vector3Parameters",
	"VirtualTextureParameters"
}

-- Some modded head shaders/materials lack these.
O.OPTIONAL_HEAD_PARAMS = {
	"Texture2DParameters:BaseColor_NonSkin",
	"Texture2DParameters:CancelMSK",
	"Texture2DParameters:WrinkleMapMSK",
	"Texture2DParameters:WrinkleMapNormal"
}

local sourceFile    = nil
---@type table<string, { names: table<string, boolean>, source: string, headParams?: boolean }>
local headShaders   = {}
local patched       = {}
local base          = false
---@type table<string, STAVVisEntry>[]
local compat        = {}
---@type STAVConfigEntry[]
local external      = {}
---@type table<Guid, true>
local races         = {}
local swaps         = 0

local function stavSourceFile()
	if not sourceFile then
		local mat = Ext.Resource.Get(STAV_BODY_MAT, "Material")
		sourceFile = mat and mat.SourceFile
	end
	return sourceFile
end

local function entrySourceFile(entry)
	if not entry.shader then return stavSourceFile() end
	local mat = Ext.Resource.Get(entry.material, "Material")
	return mat and mat.SourceFile
end

local function visualObjects(visual)
	if visual == "" then return nil end
	local vr = Ext.Resource.Get(visual, "Visual")
	if not vr then
		P.Debug():Raw("Visual "):C5(visual):Raw(" did not resolve."):Print()
		return nil
	end
	return vr.Objects
end

local function headObjects(cv)
	for _, s in ipairs(cv.VisualSet.Slots) do
		if s.Slot == "Head" then
			return visualObjects(s.VisualResource)
		end
	end
	return nil
end

local function applyParam(list, param)
	for _, p in pairs(list) do
		if p.ParameterName == param.ParameterName then
			for k, v in pairs(param) do p[k] = v end
			return
		end
	end
	list[#list + 1] = param
end

-- Credit to Volitio for most of this
local function patchMaterial(mat, params, source)
	swaps = swaps + 1
	mat.SourceFile = source
	for _, s in ipairs(params.Scalars or {}) do
		applyParam(mat.ScalarParameters, { Enabled = false, ParameterName = s.name, Value = s.value, BaseValue = s.value })
	end
	for _, s in ipairs(params.Vec3 or {}) do
		applyParam(mat.Vector3Parameters, { Enabled = false, ParameterName = s.name, IsColor = true, Value = s.value, BaseValue = s.value })
	end
	for _, s in ipairs(params.Tex2D or {}) do
		applyParam(mat.Texture2DParameters, { Enabled = s.enabled ~= false, ParameterName = s.name, ID = s.id })
	end
end

local function applyScar(mat, entry)
	if entry.scarMap and entry.scarMap ~= "" then
		applyParam(mat.Texture2DParameters, { Enabled = true, ParameterName = "BodyScarMap", ID = entry.scarMap })
	end
	if entry.scarMapNM and entry.scarMapNM ~= "" then
		applyParam(mat.Texture2DParameters, { Enabled = true, ParameterName = "BodyScarNM", ID = entry.scarMapNM })
	end
end

local function newParams(values, isColour)
	local out = {}
	for name, value in pairs(values or {}) do
		out[#out + 1] = { Parameter = name, Value = value, Enabled = true, Color = isColour, Custom = false }
	end
	return out
end

local function presetParams(list, values, drop, isColour)
	local out = {}
	for _, p in pairs(list) do
		if values[p.Parameter] == nil and drop[p.Parameter] == nil then
			out[#out + 1] = { Parameter = p.Parameter, Value = p.Value, Enabled = p.Enabled, Color = p.Color, Custom = p.Custom }
		end
	end
	for _, p in ipairs(newParams(values, isColour)) do out[#out + 1] = p end
	return out
end

local function sameValue(current, value)
	if type(value) ~= "table" then return math.abs(current - value) <= TOLERANCE end
	for i, v in ipairs(value) do
		if math.abs(current[i] - v) > TOLERANCE then return false end
	end
	return true
end

local function replaceParams(data, spec)
	local wrote = false
	for field, values in pairs({ ScalarParameters = spec.Scalars, VectorParameters = spec.Vec4, Vector3Parameters = spec.Vec3 }) do
		local out, replaced = {}, false
		for _, p in pairs(data[field]) do
			local value = values[p.Parameter]
			if value == nil then
				value = p.Value
			elseif not sameValue(p.Value, value) then
				replaced = true
			end
			out[#out + 1] = { Parameter = p.Parameter, Value = value, Enabled = p.Enabled, Color = p.Color, Custom = p.Custom }
		end
		if replaced then
			data[field] = out
			wrote = true
		end
	end
	return wrote
end

local function patchPresetData(data, spec)
	local vec4             = spec.Vec4 or {}
	data.ScalarParameters  = presetParams(data.ScalarParameters, spec.Scalars or {}, vec4, false)
	data.Vector3Parameters = presetParams(data.Vector3Parameters, spec.Vec3 or {}, {}, true)
	data.VectorParameters  = presetParams(data.VectorParameters, vec4, {}, false)
end

-- Pass 1 builds the per-charvis writes, pass 2 commits each VisualSet field once.
---@class STAVCharvisWrite
---@field cv ResourceCharacterVisualResource
---@field rmo? table<string, Guid>
---@field mats? table<Guid, table>
---@field head? STAVOverrides
---@return STAVCharvisWrite?
local function getCharvis(writes, charvis)
	local p = writes[charvis]
	if p then return p end
	local cv = Ext.Resource.Get(charvis, "CharacterVisual")
	if not cv then
		P.Debug():Raw("Charvis "):C5(charvis):Raw(" did not resolve."):Print()
		return nil
	end
	p = { cv = cv }
	writes[charvis] = p
	return p
end

local function addMats(p, matIds, overrides)
	local scalars, vecs, vec3s = newParams(overrides.Scalars, false), newParams(overrides.Vec4, false), newParams(overrides.Vec3, true)
	p.mats = p.mats or {}
	for matId in pairs(matIds) do
		p.mats[matId] = { MaterialResource = matId, ScalarParameters = scalars, VectorParameters = vecs, Vector3Parameters = vec3s, MaterialPresets = {} }
	end
end

local function queueOverrides(entry, p)
	local objects = visualObjects(p.cv.VisualSet.BodySetVisual)
	if not objects then return end
	p.rmo = p.rmo or {}
	for _, o in ipairs(objects) do p.rmo[o.ObjectID] = entry.material end
	local body = entry.overrides and entry.overrides.body
	if body then addMats(p, { [entry.material] = true }, body) end
end

local function patchBody(entry, p, source)
	local objects = visualObjects(p.cv.VisualSet.BodySetVisual)
	if not objects then return end
	local matIds = {}
	for _, o in ipairs(objects) do
		if not patched[o.MaterialID] then
			local mat = Ext.Resource.Get(o.MaterialID, "Material")
			if mat then
				patched[o.MaterialID] = true
				patchMaterial(mat, Params.CompBodyParams, source)
				applyScar(mat, entry)
			end
		end
		matIds[o.MaterialID] = true
	end
	local body = entry.overrides and entry.overrides.body
	if body and next(matIds) then addMats(p, matIds, body) end
end

function O.paramNames(mat)
	local names = {}
	for _, list in ipairs(PARAM_LISTS) do
		for _, p in pairs(mat[list]) do names[list .. ":" .. p.ParameterName] = true end
	end
	return names
end

local function hasParams(names, set)
	for name in pairs(set) do
		if not names[name] then return false end
	end
	return true
end

local function mapHeadShaders()
	for lod, shader in pairs(O.HEAD_SHADERS) do
		local vanilla, ref = Ext.Resource.Get(shader.vanilla, "Material"), Ext.Resource.Get(shader.ref, "Material")
		if vanilla and ref then
			local names = O.paramNames(vanilla)
			for _, name in ipairs(O.OPTIONAL_HEAD_PARAMS) do names[name] = nil end
			headShaders[lod] = { names = names, source = ref.SourceFile, headParams = shader.headParams }
		end
	end
end

-- Heuristics to ensure we patch head mats only (Wyll's Horns mostly).
function O.blanksAtlases(mat)
	for _, p in pairs(mat.Texture2DParameters) do
		if (p.ParameterName == "TattooAtlas" or p.ParameterName == "MakeUpAtlas") and p.Enabled and p.ID == ENGINE_BLACK then return true end
	end
	return false
end

local function findHeadShader(mat)
	if mat.MaterialType ~= "Flesh" or O.blanksAtlases(mat) then return nil end
	local names = O.paramNames(mat)
	for _, shader in pairs(headShaders) do
		if hasParams(names, shader.names) then
			local lod = mat.SourceFile:lower():match("lod(%d)[^/]*$") or "0"
			return headShaders[lod == "3" and "2" or lod]
		end
	end
	return nil
end

local function patchHeadMats(objects)
	local heads = {}
	for _, o in ipairs(objects or {}) do
		if not patched[o.MaterialID] then
			local mat = Ext.Resource.Get(o.MaterialID, "Material")
			local shader = mat and findHeadShader(mat)
			if shader then
				patched[o.MaterialID] = true
				patchMaterial(mat, shader.headParams and Params.CompHeadParams or {}, shader.source)
			end
		end
		if patched[o.MaterialID] then heads[#heads + 1] = o end
	end
	return heads
end

local function patchHead(entry, p)
	local matIds = {}
	for _, o in ipairs(patchHeadMats(headObjects(p.cv))) do matIds[o.MaterialID] = true end
	local head = entry.overrides and entry.overrides.head
	if head and next(matIds) then
		addMats(p, matIds, head)
		p.head = head
	end
end

local function patchNPCHeads(writes)
	for charvis, material in pairs(Vis.NPCHeads) do
		local p = getCharvis(writes, charvis)
		if p then
			p.rmo = p.rmo or {}
			for _, o in ipairs(patchHeadMats(headObjects(p.cv))) do p.rmo[o.ObjectID] = material end
		end
	end
end

local function applyEntry(writes, entry, source, withHead)
	for _, charvis in ipairs(entry.charvis) do
		local p = getCharvis(writes, charvis)
		if p then
			if source then patchBody(entry, p, source) elseif source == false then queueOverrides(entry, p) end
			if withHead then patchHead(entry, p) end
		end
	end
end

local function mergeParams(existing, additions)
	local list, index, changed = {}, {}, false
	for _, param in pairs(existing) do
		list[#list + 1] = param
		index[param.Parameter] = #list
	end
	for _, param in ipairs(additions) do
		local at = index[param.Parameter]
		local row = at and list[at]
		if not row or row.Enabled ~= param.Enabled or row.Color ~= param.Color or row.Custom ~= param.Custom or not sameValue(row.Value, param.Value) then
			list[at or #list + 1] = param
			changed = true
		end
	end
	if changed then return list end
end

local function commit(writes)
	local wrote = false
	for _, p in pairs(writes) do
		if p.rmo then
			local rmo, changed = {}, false
			for k, v in pairs(p.cv.VisualSet.RealMaterialOverrides) do rmo[k] = v end
			for objId, mat in pairs(p.rmo) do
				changed = changed or rmo[objId] ~= mat
				rmo[objId] = mat
			end
			if changed then
				p.cv.VisualSet.RealMaterialOverrides = rmo
				wrote = true
			end
		end
		if p.mats then
			for matId, entry in pairs(p.mats) do
				local current = p.cv.VisualSet.Materials[matId]
				if current then
					for _, field in ipairs({ "ScalarParameters", "VectorParameters", "Vector3Parameters" }) do
						local list = mergeParams(current[field], entry[field])
						if list then
							current[field] = list
							wrote = true
						end
					end
				else
					p.cv.VisualSet.Materials[matId] = entry
					wrote = true
				end
			end
		end
		if p.head and replaceParams(p.cv.VisualSet.MaterialOverrides, p.head) then wrote = true end
	end
	return wrote
end

local function warnConfig(mod, ...)
	P.Log():C1("[STAV] ", CONFIG_FILE, " (", mod.Info.Name, "): ", ...):Print()
end

local function parameterMapError(label, value, width)
	if value == nil then return nil end
	if type(value) ~= "table" then return "'" .. label .. "' must be an object." end
	for name, param in pairs(value) do
		if type(name) ~= "string" then return "'" .. label .. "' must use parameter names." end
		if not width then
			if type(param) ~= "number" then return "'" .. label .. "." .. name .. "' must be a number." end
		else
			local expected = "'" .. label .. "." .. name .. "' must be a " .. width .. "-number array."
			if not U.IsDenseArray(param) or #param ~= width then return expected end
			for _, component in ipairs(param) do
				if type(component) ~= "number" then return expected end
			end
		end
	end
end

local function readConfig(mod)
	local raw = Ext.IO.LoadFile("Mods/" .. mod.Info.Directory .. "/" .. CONFIG_FILE, "data")
	if not raw or raw == "" then return nil end
	local ok, data = pcall(Ext.Json.Parse, raw)
	if not ok then
		warnConfig(mod, "Invalid JSON format, check for missing commas, brackets or invalid uuids.")
		return nil
	end
	if type(data) ~= "table" then
		warnConfig(mod, "Top level must be a JSON object.")
		return nil
	end
	if type(data.Entries) ~= "table" then
		warnConfig(mod, "Missing 'Entries' object.")
		return nil
	end
	return data
end

local function entryError(entry)
	if type(entry) ~= "table" then return "must be an object." end
	if entry.type ~= "override" and entry.type ~= "upsert" then return "'type' must be 'override' or 'upsert'." end
	if not U.IsDenseArray(entry.charvis) or #entry.charvis == 0 then return "'charvis' must be a non-empty array." end
	for i, cv in ipairs(entry.charvis) do
		if not U.IsGuid(cv) then return "'charvis[" .. i .. "]' is not a valid UUID." end
	end
	if entry.type == "override" and not U.IsGuid(entry.material) then return "'material' must be a valid UUID (required for override)." end
	if entry.overrides ~= nil then
		if type(entry.overrides) ~= "table" then return "'overrides' must be an object." end
		local body = entry.overrides.body
		if body ~= nil then
			if type(body) ~= "table" then return "'overrides.body' must be an object." end
			local err = parameterMapError("overrides.body.Scalars", body.Scalars)
				 or parameterMapError("overrides.body.Vec3", body.Vec3, 3)
				 or parameterMapError("overrides.body.Vec4", body.Vec4, 4)
			if err then return err end
		end
	end
end

local function lowerId(mod, label, id)
	if type(id) ~= "string" or id == id:lower() then return id end
	warnConfig(mod, "Entry '", label, "' uses upper-case letters in '", id, "'. Make sure to use lowercase instead.")
	return id:lower()
end

---@class STAVConfigEntry: STAVVisEntry
---@field type "override"|"upsert"
local function collectEntries(mod)
	local data = readConfig(mod)
	if not data then return end
	for label, entry in pairs(data.Entries) do
		local err = entryError(entry)
		if err then
			warnConfig(mod, "Entry '", label, "' ", err)
		else
			for i, id in ipairs(entry.charvis) do entry.charvis[i] = lowerId(mod, label, id) end
			entry.material  = lowerId(mod, label, entry.material)
			entry.scarMap   = lowerId(mod, label, entry.scarMap)
			entry.scarMapNM = lowerId(mod, label, entry.scarMapNM)
			external[#external + 1] = entry
		end
	end
	if U.IsDenseArray(data.Races) then
		for _, race in ipairs(data.Races) do
			if U.IsGuid(race) then
				races[race] = true
			else
				warnConfig(mod, "Race '", race, "' is not a valid UUID.")
			end
		end
	elseif data.Races ~= nil then
		warnConfig(mod, "'Races' must be an array of UUIDs.")
	end
end

local function scanLO()
	for _, modId in ipairs(Ext.Mod.GetLoadOrder()) do
		local spec = Vis.Compat[modId]
		if spec then
			if spec.all then base = true else compat[#compat + 1] = spec end
		end
		collectEntries(Ext.Mod.GetMod(modId))
	end
end

local function applyScalesPassives()
	local tables, count = U.ProgressionTables(races, "Race")
	if next(tables) then
		U.PatchProgressions(tables, "PassivesAdded", Params.ScalesPassive, 1)
	end
	return count
end

local function PatchCCHeads()
	local seen = {}
	for _, id in ipairs(Ext.StaticData.GetAll("CharacterCreationAppearanceVisual")) do
		local cc = Ext.StaticData.Get(id, "CharacterCreationAppearanceVisual")
		if cc.SlotName == "Head" and cc.VisualResource ~= U.NULL_UUID and not seen[cc.VisualResource] then
			seen[cc.VisualResource] = true
			patchHeadMats(visualObjects(cc.VisualResource))
		end
	end
end

-- Need to patch after Baldur's Emporium for the tattoos etc to be correct.
local function ApplyCCOverrides()
	for _, entry in pairs(Vis.Companions) do
		local cv = entry.ccOverrides and Ext.Resource.Get(entry.ccOverrides.id, "CharacterVisual")
		if cv then patchPresetData(cv.VisualSet.MaterialOverrides, entry.ccOverrides) end
	end
end

local function ApplyAll(retry)
	local start, swapped = Ext.Timer.MonotonicTime(), swaps
	local writes = {}

	mapHeadShaders()
	PatchCCHeads()
	for _, entry in pairs(Vis.Companions) do
		applyEntry(writes, entry, base and entrySourceFile(entry), true)
		local preset = not retry and entry.skinMatPreset and Ext.Resource.Get(entry.skinMatPreset.id, "MaterialPreset")
		if preset then patchPresetData(preset.Presets, entry.skinMatPreset) end
	end
	if not retry and not Ext.Mod.IsModLoaded(EMPORIUM) then ApplyCCOverrides() end
	patchNPCHeads(writes)

	if not retry then
		for _, entry in pairs(Vis.Player) do
			applyEntry(writes, entry, false, false)
		end
	end

	for _, spec in ipairs(compat) do
		for _, entry in pairs(spec) do
			applyEntry(writes, entry, entrySourceFile(entry), true)
		end
	end

	for _, entry in ipairs(external) do
		applyEntry(writes, entry, entry.type ~= "override" and stavSourceFile(), false)
	end

	local wrote = commit(writes)
	local raceCount = applyScalesPassives()
	if retry then
		if wrote or swaps > swapped then P.Debug():Raw("Patched missed heads and materials entries."):Print() end
		return
	end
	local elapsed = Ext.Timer.MonotonicTime() - start
	if raceCount > 0 then
		P.Debug():Raw("Heads, materials and "):C21(raceCount):Raw(" races patched in "):C3(elapsed):Raw(" ms."):Print()
	else
		P.Debug():Raw("Heads and materials patched in "):C3(elapsed):Raw(" ms."):Print()
	end
end

E.StatsLoaded.Subscribe(function()
	P.Log():GradC(36, 22):G("[STAV] Snailzx Tattoos And VTs "):C33("v", U.Version):G(" loaded."):Print()
	scanLO()
	ApplyAll()
end)

-- Retry in case StatsLoaded didn't patch them.
E.GameStateChanged.Subscribe(function(e)
	if e.FromState == "LoadModule" then ApplyAll(true) end
end)

Ext.ModEvents.BaldursEmporium.CharvisPatched:Subscribe(ApplyCCOverrides)

return O
