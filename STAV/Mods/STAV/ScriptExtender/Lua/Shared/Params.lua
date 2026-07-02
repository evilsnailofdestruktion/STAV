local M = {}

-- UI slider index → shader true-index
function M.BodyIndex(uiIdx)
	return uiIdx - 1
end

local HEAD_MAP_CACHE = nil

function M.HeadIndex(uiIdx)
	if not HEAD_MAP_CACHE then
		HEAD_MAP_CACHE = {}
		HEAD_MAP_CACHE[1] = 31
		local trueIdx = 0
		for ui = 2, 200 do
			while trueIdx == 15 or trueIdx == 47 or trueIdx == 79 do
				trueIdx = trueIdx + 1
			end
			HEAD_MAP_CACHE[ui] = trueIdx
			trueIdx = trueIdx + 1
		end
	end
	return HEAD_MAP_CACHE[uiIdx] or 0
end

-- UI.State key → material/preset param
M.Map = {
	bodyMain      = { name = "BodyTattooIndex",  kind = "scalar", map = function(v) return M.BodyIndex(v) end },
	bodyAlt       = { name = "BodyAltTatIndex",  kind = "scalar", map = function(v) return M.BodyIndex(v) end },
	bodyGlow      = { name = "BodyGlowyIndex",   kind = "scalar", map = function(v) return M.BodyIndex(v) end },
	headAlt       = { name = "AltTattooIndex",   kind = "scalar", map = function(v) return M.HeadIndex(v) end },
	headGlow      = { name = "GlowTattooIndex",  kind = "scalar", map = function(v) return M.HeadIndex(v) end },
	scar          = { name = "BodyScar",         kind = "scalar", map = function(v) return v and 1 or 0 end },
	swirl         = { name = "Swirlies",         kind = "scalar", map = function(v) return v and 1 or 0 end },
	glowIntensity = { name = "GlowIntensity",    kind = "scalar", map = function(v) return v end },
	glowColor     = { name = "TatGlowColor",     kind = "vec3",   map = function(v) return v end },
	altColor      = { name = "BodyTattooColor",  kind = "vec3",   map = function(v) return v end },
}

-- 8 CCAM slots — one claimed per character (CCAM uuid → preset uuid)
M.Slots = {
	{ ccam = "fffa139e-2b12-4175-83ab-a15eb18d486c", preset = "f3a16e69-b757-4676-af7b-e922ef30b042" },
	{ ccam = "33346ac5-5dc6-497e-8fd5-77e26515c693", preset = "148e52a9-abac-4173-d752-f81cafd4a27e" },
	{ ccam = "9e05a569-54dc-43b9-bff0-8c8bfd4a7b96", preset = "531e5a3a-1331-33b3-40bf-61d48c798c42" },
	{ ccam = "a1b02643-f542-4e62-b948-b20d4351af44", preset = "b5f41781-ac6d-20e8-5e71-c336e57116b3" },
	{ ccam = "6d1f64bd-2fb1-4b1b-89c1-554516a03eea", preset = "b60e6d34-21a4-b43b-8d02-7b539e619e7e" },
	{ ccam = "348fa226-e411-43a0-ba82-ddf938ffedf3", preset = "4ceb7da5-7d2d-7e5a-3e87-bebdf0ecee50" },
	{ ccam = "f666eb8c-c2a6-469f-aaea-482d0ed5d63f", preset = "43b63d89-865f-ae15-1723-192d92ac0fc2" },
	{ ccam = "0348b311-c3b8-44c9-81ba-d22859f3a8ff", preset = "95bad513-7f5b-344f-f052-5d3b56e72f1e" },
}

return M
