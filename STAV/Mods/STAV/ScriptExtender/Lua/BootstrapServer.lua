local USER_VAR_FLAGS = {
	Server = true,
	Client = true,
	WriteableOnServer = true,
	SyncToClient = true,
	SyncOnWrite = true,
	Persistent = true
}

for _, varName in ipairs({"STAV_Look"}) do
	Ext.Vars.RegisterUserVariable(varName, USER_VAR_FLAGS)
end

Ext.Require("Shared/_Init.lua")
Ext.Require("Server/_Init.lua")
