local M = {}

-- UI slider index → shader true-index
local headCache    = { 31 }
local headNextTrue = 0

local function headIndex(uiIdx)
	while #headCache < uiIdx do
		while headNextTrue == 15 or headNextTrue == 47 or headNextTrue == 79 do
			headNextTrue = headNextTrue + 1
		end
		headCache[#headCache + 1] = headNextTrue
		headNextTrue = headNextTrue + 1
	end
	return headCache[uiIdx]
end

M.CompHeadParams = {
	Scalars = {
		{ name = "GlowIntensity",   value = 1 },
		{ name = "GlowTattooIndex", value = 31 },
		{ name = "Vampirism",       value = 0 },
		{ name = "AltTattooIndex",  value = 31 },
		{ name = "Swirlies",        value = 0 },
		{ name = "Tiling_Noise",    value = 1.5 },
		{ name = "Speed",           value = 0.25 },
	},
	Vec3 = {
		{ name = "TatGlowColor",    value = { 0, 0, 0 } },
		{ name = "BodyTattooColor", value = { 0, 0, 0 } },
		{ name = "NonSkinTipColor", value = { 0.075, 0.217, 0.298 } },
	},
	Tex2D = {
		{ name = "TattooAtlas", id = "3e2b453f-83d5-cf51-6b81-9d109e69b318", enabled = false },
		{ name = "MakeUpAtlas", id = "be1e3d5e-5f9e-9e20-e9ee-80c5fce076ed", enabled = false },
		{ name = "HeadWarp",    id = "e081db36-b103-47a9-25ca-edf481c00e22", enabled = false },
	},
}

M.CompBodyParams = {
	Scalars = {
		{ name = "BodyGlowyIndex",      value = 0 },
		{ name = "GlowIntensity",       value = 0 },
		{ name = "BodyScar",            value = 0 },
		{ name = "ScarColor",           value = 0 },
		{ name = "BM_Adjust_Weight",    value = 0 },
		{ name = "Vampirism",           value = 0 },
		{ name = "SecretTatIndex",      value = 22 },
		{ name = "BodyAltTatIndex",     value = 0 },
		{ name = "Swirlies",            value = 0 },
		{ name = "Tiling_Noise",        value = 1.5 },
		{ name = "Speed",               value = 0.25 },
		{ name = "BM_Adjust_Metalness", value = 0 },
	},
	Vec3 = {
		{ name = "TatGlowColor",    value = { 0.01144391, 0.7513394, 1.0 } },
		{ name = "CustomColor",     value = { 0.027, 0.027, 0.027 } },
		{ name = "BM_Adjust_Color", value = { 1.0, 0.546, 0.0 } },
		{ name = "TattooColor",     value = { 0.0, 0.0, 0.0 } },
		{ name = "NonSkinTipColor", value = { 0.07456587, 0.2169727, 0.2980006 } },
	},
	Tex2D = {
		{ name = "BodyWarp", id = "6380c4b4-3517-9d97-c8fa-a7aed30b6bd2" },
	},
}

-- UI.State key → material/preset param
M.Map = {
	bodyMain      = { name = "BodyTattooIndex",  kind = "scalar", map = function(v) return v - 1 end },
	bodyAlt       = { name = "BodyAltTatIndex",  kind = "scalar", map = function(v) return v - 1 end },
	bodyGlow      = { name = "BodyGlowyIndex",   kind = "scalar", map = function(v) return v - 1 end },
	headAlt       = { name = "AltTattooIndex",   kind = "scalar", map = function(v) return headIndex(v) end },
	headGlow      = { name = "GlowTattooIndex",  kind = "scalar", map = function(v) return headIndex(v) end },
	scar          = { name = "BodyScar",         kind = "scalar", map = function(v) return v and 1 or 0 end },
	swirl         = { name = "Swirlies",         kind = "scalar", map = function(v) return v and 1 or 0 end },
	vampirism     = { name = "Vampirism",			kind = "scalar", map = function(v) return v and 1 or 0 end },
	glowIntensity = { name = "GlowIntensity",    kind = "scalar" },
	glowColor     = { name = "TatGlowColor",     kind = "vec3"   },
	altColor      = { name = "BodyTattooColor",  kind = "vec3"   },
}

-- CCAM slots — one claimed per character (CCAM uuid → preset uuid)
M.Slots = {
	{ ccam = "fffa139e-2b12-4175-83ab-a15eb18d486c", preset = "f3a16e69-b757-4676-af7b-e922ef30b042" },
	{ ccam = "33346ac5-5dc6-497e-8fd5-77e26515c693", preset = "148e52a9-abac-4173-d752-f81cafd4a27e" },
	{ ccam = "9e05a569-54dc-43b9-bff0-8c8bfd4a7b96", preset = "531e5a3a-1331-33b3-40bf-61d48c798c42" },
	{ ccam = "a1b02643-f542-4e62-b948-b20d4351af44", preset = "b5f41781-ac6d-20e8-5e71-c336e57116b3" },
	{ ccam = "6d1f64bd-2fb1-4b1b-89c1-554516a03eea", preset = "b60e6d34-21a4-b43b-8d02-7b539e619e7e" },
	{ ccam = "348fa226-e411-43a0-ba82-ddf938ffedf3", preset = "4ceb7da5-7d2d-7e5a-3e87-bebdf0ecee50" },
	{ ccam = "f666eb8c-c2a6-469f-aaea-482d0ed5d63f", preset = "43b63d89-865f-ae15-1723-192d92ac0fc2" },
	{ ccam = "0348b311-c3b8-44c9-81ba-d22859f3a8ff", preset = "95bad513-7f5b-344f-f052-5d3b56e72f1e" },
	{ ccam = "aee9078e-171a-433c-8396-2f4275aff346", preset = "af535070-75a6-0429-f1b6-dbc1c76f7c4b" },
	{ ccam = "cc148c66-7906-4c6f-993f-a90e89f5fa2f", preset = "138a9f78-83c2-531a-446d-cb7fd1f5fb82" },
	{ ccam = "240f41df-d95c-4bb6-9106-f8121c11787d", preset = "10a451cd-0340-f659-0355-ff1ff2a9f8b6" },
	{ ccam = "98c23a1e-6a8e-4a36-ac58-39d9504c4837", preset = "85178d2f-5c2f-da23-4116-592049ff2e17" },
	{ ccam = "0b272392-25c2-43e0-8f51-3bf1d21bd07b", preset = "65903fec-5ff6-5f92-7610-2064de9b2208" },
	{ ccam = "1e6654e0-a1aa-4799-be7f-37b4c1e57ad9", preset = "5dcf52af-f514-7134-9d45-c9696f23875c" },
	{ ccam = "2a079995-68fb-4fad-b752-e624b117e8a9", preset = "54244a40-9aa8-9515-86d9-89179e821870" },
	{ ccam = "b330ef33-6615-45c2-b32c-c3023338c628", preset = "f27f9323-0555-82e4-3138-769f2b2b6b8b" },
	{ ccam = "a573ef20-9807-4731-9db1-3eb9ecde7fd6", preset = "1db6dac7-0963-245f-e1c4-594a4f68c60e" },
	{ ccam = "ab224214-5f43-4c43-bd01-a3414be8b482", preset = "b244ddd2-a86c-67d5-8a32-8fc03e7411d7" },
	{ ccam = "f414f91e-7ad5-4fef-905b-39c945ebadc1", preset = "1abc9854-4af5-e969-479a-c16827e42784" },
	{ ccam = "dc8bb620-752f-4b9c-b1c0-3f664071b9d7", preset = "693ccc25-e9e3-90f0-9961-1c5849859ce9" },
	{ ccam = "cb67e389-429d-49b0-8413-43a937fb360c", preset = "4bf6ab3a-b402-a196-d6f3-22ccf007e262" },
	{ ccam = "2525b01c-fcb4-4ae2-9c6f-111789963ec0", preset = "fe66e378-fd29-d44d-e906-503096afee81" },
	{ ccam = "6e3aee33-1239-4d25-9912-e985e65494e3", preset = "a6e202e4-e0ff-71ec-a251-01a77a1faba6" },
	{ ccam = "8f87881e-6d89-4ce6-b784-3fc7976fa72e", preset = "0bed6d08-aae1-0a2f-9448-4c44cf5add95" },
}

M.Toggles = {
	swirl     = "2a2f351a-6603-45bd-a87f-b567c74fa9d1",
	vampirism = "56ea96b0-d436-4efd-b200-dfdd93e83671",
}

M.ScalesPassive = "ST_DraconicScales"

return M
