local M = {}

local PATH = "STAV/config.json"

-- config key → MCM setting id
local MCM_IDS = {
	AutoOpenPhotoMode = "STAV_AutoOpenPhotoMode",
	Debug             = "STAV_Debug",
}

local DEFAULT = {
	AutoOpenPhotoMode = false,
	Debug             = false,
	ThemeStyle        = "chromed",
	ThemeAccent       = 18,
}

local data = {}

local function load()
	local raw = Ext.IO.LoadFile(PATH)
	local parsed
	if raw then pcall(function() parsed = Ext.Json.Parse(raw) end) end
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
	if not raw or dirty then
		Ext.IO.SaveFile(PATH, Ext.Json.Stringify(data))
	end
end

-- MCM first, config as fallback
function M.Get(key)
	local id = MCM_IDS[key]
	if id and type(MCM) == "table" then
		local v = MCM.Get(id)
		if v ~= nil then return v end
	end
	return data[key]
end

function M.Set(key, value)
	data[key] = value
	Ext.IO.SaveFile(PATH, Ext.Json.Stringify(data))
end

load()

return M
