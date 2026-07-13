local E           = Ext.Require("Shared/Events.lua")
local Params		= Ext.Require("Shared/Params.lua")
local Vis         = Ext.Require("Shared/Visualising.lua")

local STAV_HEAD_MAT = "489d7f2c-9839-e1d0-67c5-260294337785"

local sourceFile
local headSource
local patched     = {}

local function stavSourceFile()
	if sourceFile then return sourceFile end
	for _, entry in pairs(Vis.Companions) do
		if not entry.shader then
			local mat = Ext.Resource.Get(entry.material, "Material")
			if mat then
				sourceFile = mat.SourceFile
				break
			end
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
		STAVDebug("visual %s did not resolve", visual)
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

-- Pass 1 (gather) accumulates per-charvis writes; pass 2 commits each VisualSet field once.
local function planFor(plan, charvis)
	if not charvis or charvis == "" then return nil end
	local p = plan[charvis]
	if p then return p end
	local cv = Ext.Resource.Get(charvis, "CharacterVisual")
	if not cv then
		STAVDebug("charvis %s did not resolve", charvis)
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
			patchMaterial(Ext.Resource.Get(o.MaterialID, "Material") --[[@as ResourceMaterialResource]], Params.CompBodyParams, source)
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

local function applyAll()
	local base = false
	local targeted = {}
	for uuid, spec in pairs(Vis.Compat) do
		if Ext.Mod.IsModLoaded(uuid) then
			if spec.all then base = true else targeted[#targeted + 1] = spec end
		end
	end

	local plan = {}

	for _, entry in pairs(Vis.Companions) do
		local source = base and (entry.shader and Ext.Resource.Get(entry.material, "Material").SourceFile or stavSourceFile())
		for _, charvis in ipairs(entry.charvis) do
			local p = planFor(plan, charvis)
			if p then
				if base then gatherCompatBody(entry, p, source)
				else gatherDefaultBody(entry, p) end
				gatherHead(entry, p)
			end
		end
	end

	for _, entry in pairs(Vis.Player) do
		for _, charvis in ipairs(entry.charvis) do
			local p = planFor(plan, charvis)
			if p then gatherDefaultBody(entry, p) end
		end
	end

	for _, spec in ipairs(targeted) do
		for _, entry in pairs(spec) do
			local source = entry.shader and Ext.Resource.Get(entry.material, "Material").SourceFile or stavSourceFile()
			for _, charvis in ipairs(entry.charvis) do
				local p = planFor(plan, charvis)
				if p then
					gatherCompatBody(entry, p, source)
					gatherHead(entry, p)
				end
			end
		end
	end

	commit(plan)
	STAVDebug("body coverage applied (base mod: %s)", tostring(base))
end

E.StatsLoaded.Subscribe(applyAll)
