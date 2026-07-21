local U = Ext.Require("Shared/Utility.lua")

local M = {}

local PATH = "STAV/config.json"

local DEFAULT = {
	AutoOpenCC        = true,
	AutoOpenPhotoMode = true,
	Debug             = false,
	ThemeStyle        = "chromed",
	ThemeAccent       = 16,
}

local data = {}

local function load()
	local parsed = U.TryParseJson(Ext.IO.LoadFile(PATH))
	local dirty = false
	for key, default in pairs(DEFAULT) do
		local v = parsed and parsed[key]
		if type(v) == type(default) then
			data[key] = v
		else
			data[key] = default
			dirty = true
		end
	end
	if dirty then
		Ext.IO.SaveFile(PATH, Ext.Json.Stringify(data))
	end
end

function M.Get(key)
	return data[key]
end

function M.Set(key, value)
	data[key] = value
	Ext.IO.SaveFile(PATH, Ext.Json.Stringify(data))
end

load()

return M
