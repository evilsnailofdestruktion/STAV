-- UI slider index → shader true-index
local headIndices    = { 31 }
local headNextTrue   = 0

local function headIndex(uiIdx)
	while #headIndices < uiIdx do
		while headNextTrue == 15 or headNextTrue == 47 or headNextTrue == 79 do
			headNextTrue = headNextTrue + 1
		end
		headIndices[#headIndices + 1] = headNextTrue
		headNextTrue = headNextTrue + 1
	end
	return headIndices[uiIdx]
end

local function bodyIndex(v)
	return v - 1
end

local function spotIndex(v)
	return v == 0 and 31 or v - 1
end

local function flag(v)
	return v and 1 or 0
end

---@class STAVLookParam
---@field name string
---@field type "boolean"|"index"|"number"|"colour"
---@field default? boolean|number|number[]
---@field min? integer
---@field max? number
---@field map? fun(value: any): number

-- UI.State key → material/preset param
---@type table<string, STAVLookParam>
local Map = {
	scar           = { name = "BodyScar",        type = "boolean", default = false,           map = flag },
	bodyMain       = { name = "BodyTattooIndex", type = "index",   default = 1,     max = 96,  map = bodyIndex },
	bodyAlt        = { name = "BodyAltTatIndex", type = "index",   default = 1,     max = 96,  map = bodyIndex },
	bodyGlow       = { name = "BodyGlowyIndex",  type = "index",   default = 1,     max = 96,  map = bodyIndex },
	headAlt        = { name = "AltTattooIndex",  type = "index",   default = 1,     max = 93,  map = headIndex },
	headGlow       = { name = "GlowTattooIndex", type = "index",   default = 1,     max = 93,  map = headIndex },
	altColour      = { name = "BodyTattooColor", type = "colour",  default = { 1, 1, 1, 1 } },
	glowColour     = { name = "TatGlowColor",    type = "colour",  default = { 1, 1, 1, 1 } },
	glowColour2    = { name = "TatGlowColor2",   type = "colour",  default = { 0, 0, 0, 1 } },
	glowColour3    = { name = "TatGlowColor3",   type = "colour",  default = { 0, 0, 0, 1 } },
	glowIntensity  = { name = "GlowIntensity",   type = "number",  default = 1,     max = 5 },
	tatMetalness   = { name = "TattooMetalness", type = "number",  default = 0,     max = 1 },
	vampirism      = { name = "Vampirism",       type = "number",  default = 0,     max = 0.5 },
	glowPulse      = { name = "GlowyPulse",      type = "boolean", default = false,           map = flag },
	swirl          = { name = "Swirlies",        type = "boolean", default = false,           map = flag },
	spots          = { name = "CustomIndex",     type = "index",   min = 0,         max = 16,  map = spotIndex },
	spotsIntensity = { name = "CustomIntensity", type = "number",                   max = 1 },
	spotsColour    = { name = "CustomColor",     type = "colour" },
}

return Map
