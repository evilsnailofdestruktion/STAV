local Params = Ext.Require("Shared/Params.lua")
local P      = Ext.Require("Shared/Printing.lua")

local A = {}

local function applyParam(am, param, value)
	local params = am.Material and am.Material.Parameters
	if not params then return end
	local isScalar = param.kind == "scalar"
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
		local dummy = (d.CCCharacterDefinition or d.CCChangeAppearanceDefinition) and d.ClientCCDummyDefinition.Dummy
		if dummy then
			local e = Ext.Entity.Get(dummy)
			result[#result + 1] = e
			if debugging then
				dummies[#dummies + 1] = { tag = "CC", entity = e }
				keys[#keys + 1] = tostring(e)
			end
		end
	end
	local target = _C()
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
					b:Raw(d.tag .. ": "):C3(tostring(d.entity))
				end
			end
			b:Print()
		end
	end

	return result
end

function A.Apply(key, value)
	local param = Params.Map[key]
	if not param then return end
	for _, entity in ipairs(getRenderEntities()) do
		walkMaterials(entity, function(am)
			applyParam(am, param, value)
		end)
	end
end

function A.ApplyLookToEntity(entity, look)
	walkMaterials(entity, function(am)
		for key, param in pairs(Params.Map) do
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
		for key, p in pairs(Params.Map) do
			local v = look[key]
			if v ~= nil and not Params.Toggles[key] then
				local mapped = v
				if p.map then mapped = p.map(v) end
				if p.kind == "scalar" then
					for _, entry in pairs(preset.Presets.ScalarParameters) do
						if entry.Parameter == p.name then entry.Value = mapped end
					end
				else
					for _, entry in pairs(preset.Presets.Vector3Parameters) do
						if entry.Parameter == p.name then
							entry.Value = { mapped[1], mapped[2], mapped[3] }
						end
					end
				end
			end
		end
	end
	local entity = characterUUID and Ext.Entity.Get(characterUUID)
	if entity then
		Ext.System.ClientVisual.ReloadVisuals[entity] = true
	end
end

return A
