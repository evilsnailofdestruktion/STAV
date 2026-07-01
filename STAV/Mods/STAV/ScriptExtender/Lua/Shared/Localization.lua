-- Usage:
--   local L = Ext.Require("Shared/Localization.lua")
--   local text = L.T("SomeKey")  -- returns translated string or fallback key

local L = {}
local translationTable = {}

function L.RegisterHandles(handleMap)
	for key, value in pairs(handleMap) do
		translationTable[key] = value
	end
end

function L.T(key)
	local handle = translationTable[key]
	if handle then
		return Ext.Loca.GetTranslatedString(handle, key)
	end
	return key
end

L.RegisterHandles({
})

return L
