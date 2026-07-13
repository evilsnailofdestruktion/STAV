-- Usage:
--   local L = Ext.Require("Shared/Localization.lua")
--   local text = L.T("SomeKey")  -- returns translated string or fallback key

local L = {}
local translationTable = {
	-- Main
	["Main"]                 = "hbe107a60gc779g405bga284gdfba68f82969",
	["Body"]                 = "had728168g63d5g481cg9038gd5f07350958d",
	["Head"]                 = "hb75263dagfeb4g48e1g8de6g5c74d687cb57",
	["Shared"]               = "h2b46fe7dg4dbfg4f5agb3cdg8ddba4a1aeb2",
	["Body Scar"]            = "h02214271g2763g4fd4g8df9g78ddfd25a5de",
	["Main Tattoo"]          = "h4c156923g1df2g4fc0g8d85g1108dfae9019",
	["Alt Tattoo"]           = "hf61918adgf88eg4d03g9aacg98e7c3f6fd3a",
	["Glow Tattoo"]          = "hb69427e0g557ag432fgbf6dgc2b62bd0aaca",
	["Alt Tattoo Colour"]    = "h813692a2g6214g4768ga749gf8a2d35b1f7b",
	["Glow Colour"]          = "h24b4b838g7e1fg442dgb7d8g1f64831c0d14",
	["Glow Intensity"]       = "he5e05ed1g7eb8g4df0g8030gcff90b9da34c",
	["Swirlies"]             = "hbd829e71g8edcg468fg9b63gdbb79b1fd31f",
	["Vampirism"]            = "h1cba0ec1gfcb1g48cbg9b82gac8aff69c550",
	["Reset"]                = "h9ceb4c21ga27cg4ea3gbf1bgf02d336152e2",

	-- Themes
	["Themes"]               = "hcd0bed63g4b5dg40fdg8324g384da5864daf",
	["Chromed"]              = "h0c008b66g6d1cg4546g8679g50068a42313d",
	["Accent"]               = "h6f3c1ae7gc7e4g4d68g9606g6589b2463ba0",
	["Red"]                  = "h3f930a28g38f1g461dgbadagd441672ab0f1",
	["Orange"]               = "hb6a79fb5g0933g4214gad2cgf3a35ead7f4f",
	["Yellow"]               = "h159896f6g6036g460fgb1d7g24e53cab0b48",
	["Green"]                = "h6c8271e9gbecdg4ef0g9049g09385e375b13",
	["Blue"]                 = "hc04c39ffg6b8eg4e8cg90f7gb4d87b98f99a",
	["Violet"]               = "h413d3f96ge5a4g4bbbgaba6gc17ec839f175",
	["White"]                = "h71ec8977gdbabg4f00g8d39gab4fb223f470",
	["Silver"]               = "heb6b9907g0b03g4c73g97a6g80f88f1429a5",
	["Black"]                = "hf267a96bg5416g4f88gb42cg4ad9814c9825",
	["Magenta"]              = "h95955df8g3c96g4c39gb089g308fe4e2440f",
	["Blush"]                = "haca46d3agc268g40a8g9119g15a2c237a96f",
	["Seelie Green"]         = "hc02c521bg84f7g4017gb746g76ef7cd8c175",
	["Unseelie Violet"]      = "hc2618f32ge8e7g41fdg8b73gabc0bc29e480",
	["Deep Teal"]            = "hda7e5cbbgb4f2g416eg943agbc0c459ffeb9",
	["Neon Seelie Green"]    = "hd76bc332g94dag4aa4ga1c4ga7f0c63dedb9",
	["Neon Unseelie Violet"] = "h35388a14gfd10g46e2g934bgda3f11225c8f",
	["Neon Teal"]            = "h6201e53fg6709g4bf0gb6d3g8cf0742c5a5c",
	["Twilight Veil"]        = "h3a73e52fgfb29g4294ga68egb895e4477226",
	["Gloaming Wisp"]        = "h9b8d8926gc00bg4144ga14dg0847887c22ac",
	["Dusk Violet"]          = "hf383c4e9g0ca8g41ceg9403g0789ba6d7b0c",
}

function L.T(key)
	local handle = translationTable[key]
	if handle then
		return Ext.Loca.GetTranslatedString(handle, key)
	end
	return key
end

return L
