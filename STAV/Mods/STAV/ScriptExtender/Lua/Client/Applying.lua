local Params = Ext.Require("Shared/Params.lua")
local Map    = Ext.Require("Client/UIMap.lua")
local P      = Ext.Require("Shared/Printing.lua")
local U      = Ext.Require("Shared/Utility.lua")

local A = {}

local function applyParam(am, param, value)
	local params = am.Material and am.Material.Parameters
	if not params then return end
	local isScalar = param.type ~= "colour"
	local list = isScalar and params.ScalarParameters or params.Vector3Parameters
	for _, e in pairs(list) do
		if e.ParameterName == param.name then
			local mapped = value
			if param.map then mapped = param.map(value) end
			if isScalar then
				am:SetScalar(param.name, mapped)
			else
				am:SetVector3(param.name, { mapped[1], mapped[2], mapped[3] })
			end
			return
		end
	end
end

local function walkMaterials(entity, fn)
	local visual = entity.Visual
	if not visual or not visual.Visual then return end
	for _, att in pairs(visual.Visual.Attachments) do
		if att.Visual then
			for _, desc in pairs(att.Visual.ObjectDescs) do
				if desc.Renderable and desc.Renderable.ActiveMaterial then
					fn(desc.Renderable.ActiveMaterial)
				end
			end
		end
	end
end

local lastKey = nil

local function getRenderEntities()
	local result = {}
	local dummies, keys = {}, {}
	local debugging = P.IsDebug()

	for _, d in pairs(Ext.Entity.GetAllEntitiesWithComponent("ClientCCDummyDefinition")) do
		-- Prevents the panel elements from affecting the guardian in first CC.
		local dummy = (d.CCCharacterDefinition or d.CCChangeAppearanceDefinition) and d.ClientCCDummyDefinition.Dummy
		if dummy then
			result[#result + 1] = dummy
			if debugging then
				dummies[#dummies + 1] = { tag = "CC", entity = dummy }
				keys[#keys + 1] = tostring(dummy)
			end
		end
	end
	local target = U.GetLiveCharacter()
	for _, pm in pairs(Ext.Entity.GetAllEntitiesWithComponent("PhotoModeDummy")) do
		local char = pm.PhotoModeDummy.Entity
		if char and target and char.Uuid.EntityUuid == target.Uuid.EntityUuid then
			local dummy = char.HasDummy and char.HasDummy.Entity
			if dummy then
				result[#result + 1] = dummy
				if debugging then
					dummies[#dummies + 1] = { tag = "Photo", entity = dummy }
					keys[#keys + 1] = tostring(dummy)
				end
			end
		end
	end

	if target then
		result[#result + 1] = target
		if debugging then
			dummies[#dummies + 1] = { tag = "Live", entity = target }
			keys[#keys + 1] = tostring(target)
		end
	end

	if debugging then
		local key = table.concat(keys, ",")
		if key ~= lastKey then
			lastKey = key
			local b = P.Debug():Raw("getRenderEntities: ")
			if #dummies == 0 then
				b:Raw("none")
			else
				for i, d in ipairs(dummies) do
					if i > 1 then b:Raw(" | ") end
					b:Raw(d.tag, ": "):C3(d.entity)
				end
			end
			b:Print()
		end
	end

	return result
end

local function applyPresetParam(list, param, value)
	for _, entry in pairs(list) do
		if entry.Parameter == param.name then
			if param.default == nil then entry.Enabled = value ~= nil end
			if value ~= nil then
				entry.Value = param.type == "colour" and { value[1], value[2], value[3] } or value
			end
		end
	end
end

function A.Apply(key, value)
	local param = Map[key]
	if not param then return end
	for _, entity in ipairs(getRenderEntities()) do
		walkMaterials(entity, function(am)
			applyParam(am, param, value)
		end)
	end
end

function A.ApplyLookToEntity(entity, look)
	walkMaterials(entity, function(am)
		for key, param in pairs(Map) do
			local value = look[key]
			if value ~= nil then applyParam(am, param, value) end
		end
	end)
end

function A.ApplyAll(state)
	for _, entity in ipairs(getRenderEntities()) do
		A.ApplyLookToEntity(entity, state)
	end
end

function A.ApplyLocalPreset(presetUUID, characterUUID, look)
	local preset = presetUUID and Ext.Resource.Get(presetUUID, "MaterialPreset")
	if preset and look then
		for key, p in pairs(Map) do
			if not Params.Toggles[key] then
				local v = look[key]
				if v ~= nil and p.map then v = p.map(v) end
				local list = p.type == "colour" and preset.Presets.Vector3Parameters or preset.Presets.ScalarParameters
				applyPresetParam(list, p, v)
			end
		end
	end
	local entity = characterUUID and Ext.Entity.Get(characterUUID)
	if entity then
		Ext.System.ClientVisual.ReloadVisuals[entity] = true
		P.Debug():Raw("Reload requested for "):Name(characterUUID):Print()
	end
end

return A
