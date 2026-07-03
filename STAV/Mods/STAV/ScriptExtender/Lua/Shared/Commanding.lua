local U = Ext.Require("Shared/Utility.lua")

if Ext.IsClient() then
	Ext.RegisterConsoleCommand("stav", function(_)
		STAVToggleUI()
	end)
end
