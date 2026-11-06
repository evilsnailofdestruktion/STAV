-- Usage:
--   local L = Ext.Require("Shared/Localization.lua")
--   local text = L.T("SomeKey")  -- returns translated string or fallback key

local L = {}
local translationTable = {
	-- Main
	["Main"]                              = "hbe107a60gc779g405bga284gdfba68f82969",
	["Tattoos"]                           = "h274b36b0gcbcbgd49fg580age1d856c42a9a",
	["Head Alt"]                          = "h8771d9cbg0c02g1524g748ag9d1c16624a52",
	["Alt Colour"]                        = "h9647b6b7gd745gc60eg475ag6dd1a3267316",
	["Body Main"]                         = "h7c81b77bg6af3g035fg616cgaab3cf45b7e1",
	["Body Alt"]                          = "h1ebbb3f1g2cc2g950ag8219ga3aa40279d4e",
	["Metalness"]                         = "h60aded62gf892g6cb0gbff2g701ba393dbbb",
	["Glowing Tattoos"]                   = "hd5d0404fg77b1g659eg6d3fg4be1aaab6318",
	["Head"]                              = "hb75263dagfeb4g48e1g8de6g5c74d687cb57",
	["Body"]                              = "had728168g63d5g481cg9038gd5f07350958d",
	["Glow Colours"]                      = "h1e4b081ag44fcg237cgd784g366610f67b3d",
	["Glow Intensity"]                    = "he5e05ed1g7eb8g4df0g8030gcff90b9da34c",
	["Additional Choices"]                = "hee9bfab7gac0agf445g532bgd2f32e732cef",
	["Head Spots"]                        = "hbd190f73gbb1agaccege2f2g27e14b631d64",
	["Spots Colour"]                      = "hc23b4bd0gb1b1g659bg3c8dg49dcd809e3c2",
	["Spots Intensity"]                   = "h3b5d7db9g33e3g3f22gfc6dg2b9a2cb9a3f5",
	["Vampirism"]                         = "h1cba0ec1gfcb1g48cbg9b82gac8aff69c550",
	["Body Scars"]                        = "hc3960c45g7025g4a14g226fg4b0a30ce06d6",
	["Glow Pulse"]                       = "h2c47b146g87e9g4413g97d4g770c835c79b8",
	["Swirlies"]                          = "hbd829e71g8edcg468fg9b63gdbb79b1fd31f",
	["Reset"]                             = "h9ceb4c21ga27cg4ea3gbf1bgf02d336152e2",

	-- Presets
	["Presets"]                           = "hd9d3201bg359eg4ae5g9705g43b5f3c07bd7",
	["New Preset Name"]                   = "h79d382a8gbd53g4fa4gb4ecga36a86c716f5",
	["Save as New"]                       = "hbc44634dg8c9bg4ed9gae5dge260ea8d60d8",
	["Delete"]                            = "hcbd703aeg8c2eg4766gbe34g03f2e5d1ca5a",
	["Export As"]                         = "h392f604cgbf77g4be6ga086ge37070bdf66c",
	["Export"]                            = "hc1295e87ge8d5g4fffg9509g2b6a61061334",
	["Invalid export filename."]          = "hc9cbb4ebg100dg4847gaa7ag6d388019d1db",
	["Exported"]                          = "he0fb457dg68ceg41dcgb8f3g936a616e81b2",
	["Import From"]                       = "h33f9abd8g3261g47f8gb1fegdde1ed9df892",
	["Filename..."]                       = "h97907478g8e62g4590gb08dg26a0511c9971",
	["Import"]                            = "h4028d3c8gd1c5g4276gab27g095e3d1ac284",
	["Preset file could not be written."] = "h8f1d7345g0288g4bf0g84a2g7897c49ee6fb",
	["Preset file not found or invalid."] = "h6f6d69d1g25b3g4703ga525g5bdded8c8f12",
	["Imported"]                          = "h52e55529gd500g4a5fg8ceage6252b0a1ceb",

	-- Themes
	["Themes"]                            = "hcd0bed63g4b5dg40fdg8324g384da5864daf",
	["Chromed"]                           = "h0c008b66g6d1cg4546g8679g50068a42313d",
	["Accent"]                            = "h6f3c1ae7gc7e4g4d68g9606g6589b2463ba0",
	["Red"]                               = "h3f930a28g38f1g461dgbadagd441672ab0f1",
	["Orange"]                            = "hb6a79fb5g0933g4214gad2cgf3a35ead7f4f",
	["Yellow"]                            = "h159896f6g6036g460fgb1d7g24e53cab0b48",
	["Green"]                             = "h6c8271e9gbecdg4ef0g9049g09385e375b13",
	["Blue"]                              = "hc04c39ffg6b8eg4e8cg90f7gb4d87b98f99a",
	["Violet"]                            = "h413d3f96ge5a4g4bbbgaba6gc17ec839f175",
	["White"]                             = "h71ec8977gdbabg4f00g8d39gab4fb223f470",
	["Silver"]                            = "heb6b9907g0b03g4c73g97a6g80f88f1429a5",
	["Black"]                             = "hf267a96bg5416g4f88gb42cg4ad9814c9825",
	["Magenta"]                           = "h95955df8g3c96g4c39gb089g308fe4e2440f",
	["Blush"]                             = "haca46d3agc268g40a8g9119g15a2c237a96f",
	["Seelie Green"]                      = "hc02c521bg84f7g4017gb746g76ef7cd8c175",
	["Unseelie Violet"]                   = "hc2618f32ge8e7g41fdg8b73gabc0bc29e480",
	["Deep Teal"]                         = "hda7e5cbbgb4f2g416eg943agbc0c459ffeb9",
	["Neon Seelie Green"]                 = "hd76bc332g94dag4aa4ga1c4ga7f0c63dedb9",
	["Neon Unseelie Violet"]              = "h35388a14gfd10g46e2g934bgda3f11225c8f",
	["Neon Teal"]                         = "h6201e53fg6709g4bf0gb6d3g8cf0742c5a5c",
	["Twilight Veil"]                     = "h3a73e52fgfb29g4294ga68egb895e4477226",
	["Gloaming Wisp"]                     = "h9b8d8926gc00bg4144ga14dg0847887c22ac",
	["Dusk Violet"]                       = "hf383c4e9g0ca8g41ceg9403g0789ba6d7b0c",
	["Fae Lilac"]                         = "h49a0bc53g9c20g4fbdg97d3gdc504eb4e644",
	["Nightshade"]                        = "h10a9665fgb73fg41f0gb53fg0d2fb1272d6c",
	["Moonshade"]                         = "h9bdd295fg256fg42a1g8b29gcef1710a4865",
	["Umbral Bloom"]                      = "h1b0600cfg7cd9g4e77g9a5dg29533ce0e304",
	["Orchid Mist"]                       = "h4f80b91ag3ec7g4a1ag9306g0c1d6b6d448a",
	["Arcane Azure"]                      = "h53ef1686ga852g4d5bg9e61g8073c34ea8fb",
	["Mystra's Light"]                    = "h6c8f7f40gdfd9g4a40g89e9g6fee8ed9724f",
	["Netherese Shroud"]                  = "hd33bf362g040dg4516gb6b5gd5e488b7c3d0",
	["Glacial Gleam"]                     = "ha639f6f3gfd98g4e19gb7d9g042c1e14b06a",
	["Midnight Weave"]                    = "h4ff2fb4agc742g40cag8832g0f9c4f2738fe",
	["Arcane Radiance"]                   = "hb7687eccg487cg41c3ga579g2a3f5582f213",
	["Mint Green"]                        = "h619a2de4g15adg4059g90bagf668a4b7aa5c",
	["Lathander's Dawn"]                  = "h4c20f1f9ga881g46cag8743ga1b3d3d5bd51",
	["Arcane Violet"]                     = "hcf453850gd356g4141gb02egd9e7430eac98",
	["Pale Lilac"]                        = "hd4114bbcg4602g4063g824ag81925099f527",

	-- Advanced
	["Advanced"]                          = "h5e138bc4gf04dg4f65g977fg94d21267cf05",
	["Auto-open in Character Creation"]   = "hd58efd5agda7fg4fbdgb5b5gdf0d4a88b2b7",
	["Auto-open in Photo Mode"]           = "h72af5f23gd8d5g4decg8cefg038b93dbfab4",
	["Debug Logging"]                     = "h8be41d65g1606g40f3gb4a3gc3c5bdc588a8"
}

function L.T(key)
	local handle = translationTable[key]
	if handle then
		return Ext.Loca.GetTranslatedString(handle, key)
	end
	return key
end

return L
