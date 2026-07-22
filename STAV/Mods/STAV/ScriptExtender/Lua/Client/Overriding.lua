local E           = Ext.Require("Shared/Events.lua")
local Params		= Ext.Require("Shared/Params.lua")
local Vis         = Ext.Require("Shared/Visualising.lua")
local U           = Ext.Require("Shared/Utility.lua")

local STAV_HEAD_MAT = "489d7f2c-9839-e1d0-67c5-260294337785"
local CONFIG_FILE   = "STAVConfig.json"

local sourceFile
local headSource
local patched     = {}

local function stavSourceFile()
	if sourceFile then return sourceFile end
	for _, entry in pairs(Vis.Player) do
		local mat = Ext.Resource.Get(entry.material, "Material")
		if mat then
			sourceFile = mat.SourceFile
			break
		end
	end
	return sourceFile
end

local function stavHeadSourceFile()
	if headSource then return headSource end
	local mat = Ext.Resource.Get(STAV_HEAD_MAT, "Material")
	if mat then headSource = mat.SourceFile end
	return headSource
end

local function objectsOf(visual)
	if not visual or visual == "" then return nil end
	local vr = Ext.Resource.Get(visual, "Visual")
	if not vr then
		STAVDebug():Raw("Visual "):C5(visual):Raw(" did not resolve"):Print()
		return nil
	end
	return vr.Objects
end

local function headObjects(cv)
	for _, s in ipairs(cv.VisualSet.Slots) do
		if s.Slot == "Head" then
			return objectsOf(s.VisualResource)
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
	if source then mat.SourceFile = source end
	for _, s in ipairs(params.Scalars) do
		applyParam(mat.ScalarParameters, { Enabled = false, ParameterName = s.name, Value = s.value, BaseValue = s.value })
	end
	for _, s in ipairs(params.Vec3) do
		applyParam(mat.Vector3Parameters, { Enabled = false, ParameterName = s.name, IsColor = true, Value = s.value, BaseValue = s.value })
	end
	for _, s in ipairs(params.Tex2D) do
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

-- Pass 1 (gather) accumulates per-charvis writes; pass 2 commits each VisualSet field once.
local function planFor(plan, charvis)
	if not charvis or charvis == "" then return nil end
	local p = plan[charvis]
	if p then return p end
	local cv = Ext.Resource.Get(charvis, "CharacterVisual")
	if not cv then
		STAVDebug():Raw("Charvis "):C5(charvis):Raw(" did not resolve"):Print()
		return nil
	end
	p = { cv = cv }
	plan[charvis] = p
	return p
end

local function addMats(p, matIds, overrides)
	local scalars, vecs = {}, {}
	for name, v in pairs(overrides.Scalars or {}) do
		scalars[#scalars + 1] = { Parameter = name, Value = v, Enabled = true, Color = false, Custom = false }
	end
	for name, v in pairs(overrides.Vec4 or {}) do
		vecs[#vecs + 1] = { Parameter = name, Value = v, Enabled = true, Color = true, Custom = false }
	end
	p.mats = p.mats or {}
	for matId in pairs(matIds) do
		p.mats[matId] = { MaterialResource = matId, ScalarParameters = scalars, VectorParameters = vecs, MaterialPresets = {} }
	end
end

local function gatherDefaultBody(entry, p)
	local objects = objectsOf(p.cv.VisualSet.BodySetVisual)
	if not objects then return end
	p.rmo = p.rmo or {}
	for _, o in ipairs(objects) do p.rmo[o.ObjectID] = entry.material end
end

local function gatherCompatBody(entry, p, source)
	local objects = objectsOf(p.cv.VisualSet.BodySetVisual)
	if not objects then return end
	local matIds = {}
	for _, o in ipairs(objects) do
		if not patched[o.MaterialID] then
			patched[o.MaterialID] = true
			local mat = Ext.Resource.Get(o.MaterialID, "Material") --[[@as ResourceMaterialResource]]
			patchMaterial(mat, Params.CompBodyParams, source)
			applyScar(mat, entry)
		end
		matIds[o.MaterialID] = true
	end
	local body = entry.overrides and entry.overrides.body
	if body and next(matIds) then addMats(p, matIds, body) end
end

local function gatherHead(entry, p)
	local objects = headObjects(p.cv)
	if not objects then return end
	local matIds = {}
	for _, o in ipairs(objects) do
		if not patched[o.MaterialID] then
			local mat = Ext.Resource.Get(o.MaterialID, "Material") --[[@as ResourceMaterialResource]]
			if mat.SourceFile:find("CHAR_Skin_Head_v3", 1, true) then
				patched[o.MaterialID] = true
				patchMaterial(mat, Params.CompHeadParams, stavHeadSourceFile())
			end
		end
		if patched[o.MaterialID] then matIds[o.MaterialID] = true end
	end
	local head = entry.overrides and entry.overrides.head
	if head and next(matIds) then addMats(p, matIds, head) end
end

local function applyEntry(plan, entry, useCompat, source, withHead)
	for _, charvis in ipairs(entry.charvis) do
		local p = planFor(plan, charvis)
		if p then
			if useCompat then gatherCompatBody(entry, p, source) else gatherDefaultBody(entry, p) end
			if withHead then gatherHead(entry, p) end
		end
	end
end

local function commit(plan)
	for _, p in pairs(plan) do
		if p.rmo then
			local rmo = {}
			for k, v in pairs(p.cv.VisualSet.RealMaterialOverrides) do rmo[k] = v end
			for objId, mat in pairs(p.rmo) do rmo[objId] = mat end
			p.cv.VisualSet.RealMaterialOverrides = rmo
		end
		if p.mats then
			for matId, entry in pairs(p.mats) do
				p.cv.VisualSet.Materials[matId] = entry
			end
		end
	end
end

local function warnConfig(mod, msg)
	STAVPrint():C1(string.format("[STAV] %s (%s): %s", CONFIG_FILE, mod.Info.Name, msg)):Print()
end

local function readConfig(mod)
	local raw = Ext.IO.LoadFile("Mods/" .. mod.Info.Directory .. "/" .. CONFIG_FILE, "data")
	if not raw or raw == "" then return nil end
	local ok, data = pcall(Ext.Json.Parse, raw)
	if not ok then
		warnConfig(mod, "Invalid JSON format, check for missing commas, brackets or invalid uuids")
		return nil
	end
	if type(data) ~= "table" then
		warnConfig(mod, "Top level must be a JSON object")
		return nil
	end
	if type(data.Entries) ~= "table" then
		warnConfig(mod, "Missing 'Entries' object")
		return nil
	end
	return data
end

local function entryError(entry)
	if type(entry) ~= "table" then return "must be an object" end
	if entry.type ~= "override" and entry.type ~= "upsert" then return "'type' must be 'override' or 'upsert'" end
	if type(entry.charvis) ~= "table" or #entry.charvis == 0 then return "'charvis' must be a non-empty array" end
	for i, cv in ipairs(entry.charvis) do
		if not U.IsGuid(cv) then return string.format("charvis[%d] is not a valid UUID", i) end
	end
	if entry.type == "override" and not U.IsGuid(entry.material) then return "'material' must be a valid UUID (required for override)" end
end

local function collectEntries(mod, external, races)
	local data = readConfig(mod)
	if not data then return end
	for label, entry in pairs(data.Entries) do
		local err = entryError(entry)
		if err then
			warnConfig(mod, string.format("Entry '%s' %s", tostring(label), err))
		else
			external[#external + 1] = entry
		end
	end
	if type(data.Races) == "table" then
		for _, race in ipairs(data.Races) do
			if U.IsGuid(race) then
				races[race] = true
			else
				warnConfig(mod, string.format("Race '%s' is not a valid UUID", tostring(race)))
			end
		end
	elseif data.Races ~= nil then
		warnConfig(mod, "'Races' must be an array of UUIDs")
	end
end

local function discover()
	local base, targeted, external, races = false, {}, {}, {}
	for _, modId in ipairs(Ext.Mod.GetLoadOrder()) do
		local spec = Vis.Compat[modId]
		if spec then
			if spec.all then base = true else targeted[#targeted + 1] = spec end
		end
		local mod = Ext.Mod.GetMod(modId)
		if mod then collectEntries(mod, external, races) end
	end
	return base, targeted, external, races
end

local function applyScalesPassives(races)
	local tables = {}
	local count = 0
	for race in pairs(races) do
		local r = Ext.StaticData.Get(race, "Race")
		if r and r.ProgressionTableUUID then
			tables[r.ProgressionTableUUID] = true
			count = count + 1
		end
	end
	if not next(tables) then return count end
	for _, uuid in pairs(Ext.StaticData.GetAll("Progression")) do
		local prog = Ext.StaticData.Get(uuid, "Progression")
		if tables[prog.TableUUID] and prog.Level == 1 then
			local added = prog.PassivesAdded or ""
			if not added:find(Params.ScalesPassive, 1, true) then
				prog.PassivesAdded = added == "" and Params.ScalesPassive or added .. ";" .. Params.ScalesPassive
			end
		end
	end
	return count
end

local function applyAll()
	local start = Ext.Timer.MonotonicTime()
	local base, targeted, external, races = discover()
	local plan = {}

	for _, entry in pairs(Vis.Companions) do
		local source = base and (entry.shader and Ext.Resource.Get(entry.material, "Material").SourceFile or stavSourceFile())
		applyEntry(plan, entry, base, source, true)
	end

	for _, entry in pairs(Vis.Player) do
		applyEntry(plan, entry, false, nil, false)
	end

	for _, spec in ipairs(targeted) do
		for _, entry in pairs(spec) do
			local source = entry.shader and Ext.Resource.Get(entry.material, "Material").SourceFile or stavSourceFile()
			applyEntry(plan, entry, true, source, true)
		end
	end

	for _, entry in ipairs(external) do
		local compat = entry.type ~= "override"
		applyEntry(plan, entry, compat, compat and stavSourceFile() or nil, false)
	end

	commit(plan)
	local raceCount = applyScalesPassives(races)
	STAVDebug():Raw("Materials and "):C21(raceCount):Raw(" races patched in "):C3(Ext.Timer.MonotonicTime() - start):Raw(" ms"):Print()
end

E.StatsLoaded.Subscribe(function()
	STAVPrint():GradC(16, 21):G("[STAV] Snailzx Tattoos And VTs "):C17("v" .. U.Version):G(" loaded"):Print()
	applyAll()
end)
