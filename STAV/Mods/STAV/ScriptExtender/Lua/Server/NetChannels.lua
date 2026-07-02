local NetDefs = Ext.Require("Shared/NetDefs.lua")
local Vars    = Ext.Require("Shared/Vars.lua")

NetDefs.NET_APPLY:SetHandler(function(payload, _)
	local data = Ext.Json.Parse(payload)
	if not data or not data.state then return end
	Vars.LatestLook = data.state
	local host = Osi.GetHostCharacter()
	if not host then return end
	local entity = Ext.Entity.Get(host)
	if not entity then return end
	Vars.SetLook(entity, data.state)
end)
