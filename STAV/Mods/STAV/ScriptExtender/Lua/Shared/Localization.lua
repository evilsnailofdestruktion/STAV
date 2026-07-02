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
	["Tattoos"]           = "hbe107a60gc779g405bga284gdfba68f82969",
	["Body"]              = "had728168g63d5g481cg9038gd5f07350958d",
	["Head"]              = "hb75263dagfeb4g48e1g8de6g5c74d687cb57",
	["Shared"]            = "h2b46fe7dg4dbfg4f5agb3cdg8ddba4a1aeb2",
	["Body Scar"]         = "h02214271g2763g4fd4g8df9g78ddfd25a5de",
	["Main Tattoo"]       = "h4c156923g1df2g4fc0g8d85g1108dfae9019",
	["Alt Tattoo"]        = "hf61918adgf88eg4d03g9aacg98e7c3f6fd3a",
	["Glow Tattoo"]       = "hb69427e0g557ag432fgbf6dgc2b62bd0aaca",
	["Alt Tattoo Colour"] = "h813692a2g6214g4768ga749gf8a2d35b1f7b",
	["Glow Colour"]       = "h24b4b838g7e1fg442dgb7d8g1f64831c0d14",
	["Glow Intensity"]    = "he5e05ed1g7eb8g4df0g8030gcff90b9da34c",
	["Swirlies"]          = "hbd829e71g8edcg468fg9b63gdbb79b1fd31f",
})

return L
