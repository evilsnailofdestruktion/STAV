local Maps = Ext.Require("Shared/IndexMaps.lua")

local P = {
	bodyMain      = { name = "BodyTattooIndex",  kind = "scalar", map = function(v) return Maps.BodyIndex(v) end },
	bodyAlt       = { name = "BodyAltTatIndex",  kind = "scalar", map = function(v) return Maps.BodyIndex(v) end },
	bodyGlow      = { name = "BodyGlowyIndex",   kind = "scalar", map = function(v) return Maps.BodyIndex(v) end },
	headAlt       = { name = "AltTattooIndex",   kind = "scalar", map = function(v) return Maps.HeadIndex(v) end },
	headGlow      = { name = "GlowyTattooIndex", kind = "scalar", map = function(v) return Maps.HeadIndex(v) end },
	scar          = { name = "BodyScar",         kind = "scalar", map = function(v) return v and 1 or 0 end },
	swirl         = { name = "Swirlies",         kind = "scalar", map = function(v) return v and 1 or 0 end },
	glowIntensity = { name = "GlowIntensity",    kind = "scalar", map = function(v) return v end },
	glowColor     = { name = "TatGlowColor",     kind = "vec3",   map = function(v) return v end },
	altColor      = { name = "BodyTattooColor",  kind = "vec3",   map = function(v) return v end },
}

return P
