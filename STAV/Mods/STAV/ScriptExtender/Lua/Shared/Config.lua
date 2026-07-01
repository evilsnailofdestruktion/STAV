local M = {}

local Vars = Ext.Require("Shared/Vars.lua")

local CONFIG_PATH = "STAV/config.json"

function M.SaveConfig()
	Ext.IO.SaveFile(CONFIG_PATH, Ext.Json.Stringify({}))
end

return M
