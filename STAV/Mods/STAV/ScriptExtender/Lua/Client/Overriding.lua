local E      = Ext.Require("Shared/Events.lua")
local Params = Ext.Require("Shared/Params.lua")
local Vis    = Ext.Require("Shared/Visualising.lua")
local U      = Ext.Require("Shared/Utility.lua")
local P      = Ext.Require("Shared/Printing.lua")

local STAV_HEAD_MAT = "489d7f2c-9839-e1d0-67c5-260294337785"
local CONFIG_FILE   = "STAVConfig.json"
local EMPORIUM      = "91994363-833a-4956-a552-acf0341c2e2e"
local ENGINE_BLACK  = "8f1f209a-dd37-4531-b1ee-5e81c1d169cc"

local sourceFile, headSource = nil, nil
local patched = {}

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

local function entrySourceFile(entry)
	return entry.shader and Ext.Resource.Get(entry.material, "Material").SourceFile or stavSourceFile()
end

local function visualObjects(visual)
	if visual == "" then return nil end
	local vr = Ext.Resource.Get(visual, "Visual")
	if not vr then
		P.Debug():Raw("Visual "):C5(visual):Raw(" did not resolve"):Print()
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
	if source then mat.SourceFile = source end
	for _, s in ipairs(params.Scalars or {}) do
		applyParam(mat.ScalarParameters, { Enabled = false, ParameterName = s.name, Value = s.value, BaseValue = s.value })
	end
	for _, s in ipairs(params.Vec3 or {}) do
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

local function patchPresetData(data, spec)
	local vec4 = spec.Vec4 or {}
	data.ScalarParameters  = presetParams(data.ScalarParameters, spec.Scalars or {}, vec4, false)
	data.Vector3Parameters = presetParams(data.Vector3Parameters, spec.Vec3 or {}, {}, true)
	data.VectorParameters  = presetParams(data.VectorParameters, vec4, {}, false)
end

-- Pass 1 builds the per-charvis writes, pass 2 commits each VisualSet field once.
---@class STAVCharvisWrite
---@field cv ResourceCharacterVisualResource
---@field rmo? table<string, Guid>
---@field mats? table<Guid, table>
---@return STAVCharvisWrite?
local function getCharvis(writes, charvis)
	local p = writes[charvis]
	if p then return p end
	local cv = Ext.Resource.Get(charvis, "CharacterVisual")
	if not cv then
		P.Debug():Raw("Charvis "):C5(charvis):Raw(" did not resolve"):Print()
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

local function getDefaultBody(entry, p)
	local objects = visualObjects(p.cv.VisualSet.BodySetVisual)
	if not objects then return end
	p.rmo = p.rmo or {}
	for _, o in ipairs(objects) do p.rmo[o.ObjectID] = entry.material end
	local body = entry.overrides and entry.overrides.body
	if body then addMats(p, { [entry.material] = true }, body) end
end

local function getCompatBody(entry, p, source)
	local objects = visualObjects(p.cv.VisualSet.BodySetVisual)
	if not objects then return end
	local matIds = {}
	for _, o in ipairs(objects) do
		if not patched[o.MaterialID] then
			patched[o.MaterialID] = true
			local mat = Ext.Resource.Get(o.MaterialID, "Material")
			patchMaterial(mat, Params.CompBodyParams, source)
			applyScar(mat, entry)
		end
		matIds[o.MaterialID] = true
	end
	local body = entry.overrides and entry.overrides.body
	if body and next(matIds) then addMats(p, matIds, body) end
end

-- Heuristics to ensure we patch head mats only.
local function blanksAtlases(mat)
	for _, p in pairs(mat.Texture2DParameters) do
		if (p.ParameterName == "TattooAtlas" or p.ParameterName == "MakeUpAtlas") and p.Enabled and p.ID == ENGINE_BLACK then return true end
	end
	return false
end

local function isHeadMat(mat)
	return mat.MaterialType == "Flesh" and mat.SourceFile:find("CHAR_Skin_Head_v3", 1, true) and not blanksAtlases(mat)
end

local function patchHeadMats(objects)
	local heads = {}
	for _, o in ipairs(objects or {}) do
		if not patched[o.MaterialID] then
			local mat = Ext.Resource.Get(o.MaterialID, "Material")
			if isHeadMat(mat) then
				patched[o.MaterialID] = true
				patchMaterial(mat, Params.CompHeadParams, stavHeadSourceFile())
			end
		end
		if patched[o.MaterialID] then heads[#heads + 1] = o end
	end
	return heads
end

local function patchCCHeads()
	local seen = {}
	for _, id in ipairs(Ext.StaticData.GetAll("CharacterCreationAppearanceVisual")) do
		local cc = Ext.StaticData.Get(id, "CharacterCreationAppearanceVisual")
		if cc.SlotName == "Head" and cc.VisualResource ~= U.NULL_UUID and not seen[cc.VisualResource] then
			seen[cc.VisualResource] = true
			patchHeadMats(visualObjects(cc.VisualResource))
		end
	end
end

local function getHead(entry, p)
	local matIds = {}
	for _, o in ipairs(patchHeadMats(headObjects(p.cv))) do matIds[o.MaterialID] = true end
	local head = entry.overrides and entry.overrides.head
	if head and next(matIds) then addMats(p, matIds, head) end
end

local function getNPCHeads(writes)
	for charvis, material in pairs(Vis.NPCHeads) do
		local p = getCharvis(writes, charvis)
		if p then
			p.rmo = p.rmo or {}
			for _, o in ipairs(patchHeadMats(headObjects(p.cv))) do p.rmo[o.ObjectID] = material end
		end
	end
end

local function applyEntry(writes, entry, useCompat, source, withHead)
	for _, charvis in ipairs(entry.charvis) do
		local p = getCharvis(writes, charvis)
		if p then
			if useCompat then getCompatBody(entry, p, source) else getDefaultBody(entry, p) end
			if withHead then getHead(entry, p) end
		end
	end
end

local function mergeParams(existing, additions)
	local list, index = {}, {}
	for _, param in pairs(existing) do
		list[#list + 1] = param
		index[param.Parameter] = #list
	end
	for _, param in ipairs(additions) do
		local at = index[param.Parameter]
		if at then list[at] = param else list[#list + 1] = param end
	end
	return list
end

local function commit(writes)
	for _, p in pairs(writes) do
		if p.rmo then
			local rmo = {}
			for k, v in pairs(p.cv.VisualSet.RealMaterialOverrides) do rmo[k] = v end
			for objId, mat in pairs(p.rmo) do rmo[objId] = mat end
			p.cv.VisualSet.RealMaterialOverrides = rmo
		end
		if p.mats then
			for matId, entry in pairs(p.mats) do
				local current = p.cv.VisualSet.Materials[matId]
				if current then
					current.ScalarParameters  = mergeParams(current.ScalarParameters, entry.ScalarParameters)
					current.VectorParameters  = mergeParams(current.VectorParameters, entry.VectorParameters)
					current.Vector3Parameters = mergeParams(current.Vector3Parameters, entry.Vector3Parameters)
				else
					p.cv.VisualSet.Materials[matId] = entry
				end
			end
		end
	end
end

local function warnConfig(mod, msg)
	P.Log():C1(string.format("[STAV] %s (%s): %s", CONFIG_FILE, mod.Info.Name, msg)):Print()
end

local function isDenseArray(value)
	if type(value) ~= "table" then return false end
	local count = 0
	for _ in pairs(value) do count = count + 1 end
	for i = 1, count do
		if value[i] == nil then return false end
	end
	return true
end

local function parameterMapError(label, value, width)
	if value == nil then return nil end
	if type(value) ~= "table" then return string.format("'%s' must be an object", label) end
	for name, param in pairs(value) do
		if type(name) ~= "string" then return string.format("'%s' must use parameter names", label) end
		if not width then
			if type(param) ~= "number" then return string.format("'%s.%s' must be a number", label, name) end
		else
			local expected = string.format("'%s.%s' must be a %d-number array", label, name, width)
			if not isDenseArray(param) or #param ~= width then return expected end
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
	if not isDenseArray(entry.charvis) or #entry.charvis == 0 then return "'charvis' must be a non-empty array" end
	for i, cv in ipairs(entry.charvis) do
		if not U.IsGuid(cv) then return string.format("'charvis[%d]' is not a valid UUID", i) end
	end
	if entry.type == "override" and not U.IsGuid(entry.material) then return "'material' must be a valid UUID (required for override)" end
	if entry.overrides ~= nil then
		if type(entry.overrides) ~= "table" then return "'overrides' must be an object" end
		local body = entry.overrides.body
		if body ~= nil then
			if type(body) ~= "table" then return "'overrides.body' must be an object" end
			local err = parameterMapError("overrides.body.Scalars", body.Scalars)
				or parameterMapError("overrides.body.Vec3", body.Vec3, 3)
				or parameterMapError("overrides.body.Vec4", body.Vec4, 4)
			if err then return err end
		end
	end
end

---@class STAVConfigEntry: STAVVisEntry
---@field type "override"|"upsert"
---@param external STAVConfigEntry[]
local function collectEntries(mod, external, races)
	local data = readConfig(mod)
	if not data then return end
	for label, entry in pairs(data.Entries) do
		local err = entryError(entry)
		if err then
			warnConfig(mod, string.format("Entry '%s' %s", label, err))
		else
			external[#external + 1] = entry
		end
	end
	if isDenseArray(data.Races) then
		for _, race in ipairs(data.Races) do
			if U.IsGuid(race) then
				races[race] = true
			else
				warnConfig(mod, string.format("Race '%s' is not a valid UUID", race))
			end
		end
	elseif data.Races ~= nil then
		warnConfig(mod, "'Races' must be an array of UUIDs")
	end
end

local function scanLO()
	local base, targeted, external, races = false, {}, {}, {}
	for _, modId in ipairs(Ext.Mod.GetLoadOrder()) do
		local spec = Vis.Compat[modId]
		if spec then
			if spec.all then base = true else targeted[#targeted + 1] = spec end
		end
		collectEntries(Ext.Mod.GetMod(modId), external, races)
	end
	return base, targeted, external, races
end

local function applyScalesPassives(races)
	local tables, count = U.ProgressionTables(races, "Race")
	if next(tables) then
		U.PatchProgressions(tables, "PassivesAdded", Params.ScalesPassive, 1)
	end
	return count
end

-- Need to patch after Baldur's Emporium for the tattoos etc to be correct.
local function applyCCOverrides()
	for _, entry in pairs(Vis.Companions) do
		if entry.ccOverrides then
			patchPresetData(Ext.Resource.Get(entry.ccOverrides.id, "CharacterVisual").VisualSet.MaterialOverrides, entry.ccOverrides)
		end
	end
end

local function applyAll()
	local start = Ext.Timer.MonotonicTime()
	local base, targeted, external, races = scanLO()
	local writes = {}

	patchCCHeads()
	for _, entry in pairs(Vis.Companions) do
		applyEntry(writes, entry, base, base and entrySourceFile(entry), true)
		if entry.skinMatPreset then
			patchPresetData(Ext.Resource.Get(entry.skinMatPreset.id, "MaterialPreset").Presets, entry.skinMatPreset)
		end
	end
	if not Ext.Mod.IsModLoaded(EMPORIUM) then applyCCOverrides() end
	getNPCHeads(writes)

	for _, entry in pairs(Vis.Player) do
		applyEntry(writes, entry, false, nil, false)
	end

	for _, spec in ipairs(targeted) do
		for _, entry in pairs(spec) do
			applyEntry(writes, entry, true, entrySourceFile(entry), true)
		end
	end

	for _, entry in ipairs(external) do
		local compat = entry.type ~= "override"
		applyEntry(writes, entry, compat, compat and stavSourceFile() or nil, false)
	end

	commit(writes)
	local raceCount = applyScalesPassives(races)
	local elapsed = Ext.Timer.MonotonicTime() - start
	if raceCount > 0 then
		P.Debug():Raw("Materials and "):C21(raceCount):Raw(" races patched in "):C3(elapsed):Raw(" ms"):Print()
	else
		P.Debug():Raw("Materials patched in "):C3(elapsed):Raw(" ms"):Print()
	end
end

E.StatsLoaded.Subscribe(function()
	P.Log():GradC(16, 21):G("[STAV] Snailzx Tattoos And VTs "):C17("v" .. U.Version):G(" loaded"):Print()
	applyAll()
end)

-- Retry in case StatsLoaded didn't patch them.
E.GameStateChanged.Subscribe(function(e)
	if e.FromState == "LoadModule" then patchCCHeads() end
end)

Ext.ModEvents.BaldursEmporium.CharvisPatched:Subscribe(applyCCOverrides)
