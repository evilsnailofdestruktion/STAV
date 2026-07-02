local PARAMS = Ext.Require("Shared/Params.lua")

local A = {}

local function applyParam(am, param, value)
	local mapped = param.map(value)
	if param.kind == "scalar" then
		if am:GetScalar(param.name) ~= nil then
			am:SetScalar(param.name, mapped)
		end
	else
		if am:GetVector3(param.name) ~= nil then
			am:SetVector3(param.name, { mapped[1], mapped[2], mapped[3] })
		end
	end
end

local function walkMaterials(entity, fn)
	local visual = entity.Visual
	if not visual then return end
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

local function getRenderEntities()
	local me = _C()
	if not me then return {} end
	if me.Level and me.Level.LevelName == "SYS_CC_I" then
		local result = {}
		for _, d in pairs(Ext.Entity.GetAllEntitiesWithComponent("ClientCCDummyDefinition")) do
			local dummy = d.ClientCCDummyDefinition.Dummy
			if dummy then
				result[#result + 1] = Ext.Entity.Get(dummy)
			end
		end
		return result
	end
	return { me }
end

function A.Apply(key, value)
	local param = PARAMS[key]
	if not param then return end
	for _, entity in ipairs(getRenderEntities()) do
		walkMaterials(entity, function(am)
			applyParam(am, param, value)
		end)
	end
end

function A.ApplyAll(state)
	for key, value in pairs(state) do
		if PARAMS[key] then
			A.Apply(key, value)
		end
	end
end

return A
