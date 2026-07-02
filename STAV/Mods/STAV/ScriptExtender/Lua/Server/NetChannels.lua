local NetDefs  = Ext.Require("Shared/NetDefs.lua")
local Vars     = Ext.Require("Shared/Vars.lua")
local Creating = Ext.Require("Server/Creating.lua")

NetDefs.NET_APPLY:SetHandler(function(data, _)
	if not data or not data.characterUUID or not data.state then return end
	local entity = Ext.Entity.Get(data.characterUUID)
	if not entity then return end
	Vars.SetLook(entity, data.state)
	Creating.ApplyToCharacter(data.characterUUID)
end)
