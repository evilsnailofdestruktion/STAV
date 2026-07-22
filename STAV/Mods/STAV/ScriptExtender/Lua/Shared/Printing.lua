-- Credits to Focus
local Config = Ext.Require("Shared/Config.lua")

local PRESETS = {
	{ 255, 0,   0 },		-- C1  #ff0000 Red
	{ 255, 165, 0 },		-- C2  #ffa500 Orange
	{ 255, 255, 0 },		-- C3  #ffff00 Yellow
	{ 0,   255, 0 },		-- C4  #00ff00 Green
	{ 0,   191, 255 },	-- C5  #00bfff Blue
	{ 238, 130, 238 },	-- C6  #ee82ee Violet
	{ 255, 255, 255 },	-- C7  #ffffff White
	{ 192, 192, 192 },	-- C8  #c0c0c0 Silver
	{ 0,   0,   0 },		-- C9  #000000 Black
	{ 199, 44,  134 },	-- C10 #c72c86 Magenta
	{ 255, 214, 238 },	-- C11 #ffd6ee Blush
	{ 18,  78,  43 },		-- C12 #124e2b Seelie Green
	{ 59,  20,  80 },		-- C13 #3b1450 Unseelie Violet
	{ 30,  58,  70 },		-- C14 #1e3a46 Deep Teal
	{ 12,  217, 119 },	-- C15 #0cd977 Neon Seelie Green
	{ 168, 50,  255 },	-- C16 #a832ff Neon Unseelie Violet
	{ 0,   194, 203 },	-- C17 #00c2cb Neon Teal
	{ 109, 114, 203 },	-- C18 #6c72cb Twilight Veil | Faeblue | Witchlight
	{ 114, 108, 208 },	-- C19 #726cd0 Gloaming Wisp
	{ 120, 101, 213 },	-- C20 #7865d5 Dusk Violet | Duskbloom | Nightshade
	{ 211, 152, 255 }		-- C21 #D398FF Fae Lilac
}

-- Internals
local Machine = Ext.IsServer() and "S" or "C"
local RESET   = "\x1b[0m"

local function Lerp(a, b, t)
	return math.floor(a + (b - a) * t + 0.5)
end

local function RgbToANSI(r, g, b)
	return string.format("\x1b[1;38;2;%d;%d;%dm", r, g, b)
end

-- CoreBuilder
local CoreBuilder = {}
CoreBuilder.__index = CoreBuilder

function STAVPrint()
	return setmetatable({ _segs = {} }, CoreBuilder)
end

-- Set the line-wide gradient endpoints (by preset). Text added with :G is
-- coloured across the whole line at Build time, fixed-colour inserts (C methods)
-- are lifted out and don't consume gradient positions.
function CoreBuilder:GradC(startPreset, endPreset)
	self._grad = { PRESETS[startPreset], PRESETS[endPreset] }
	return self
end

function CoreBuilder:G(text)
	self._segs[#self._segs + 1] = { Text = tostring(text), Grad = true }
	return self
end

function CoreBuilder:Raw(text)
	self._segs[#self._segs + 1] = { Text = tostring(text) }
	return self
end

function CoreBuilder:Build()
	local total = 0
	for _, seg in ipairs(self._segs) do
		if seg.Grad then total = total + #seg.Text end
	end
	local parts = {}
	local g     = 0
	for _, seg in ipairs(self._segs) do
		if seg.Grad and self._grad then
			local a, b = self._grad[1], self._grad[2]
			for i = 1, #seg.Text do
				local t = total > 1 and g / (total - 1) or 0
				parts[#parts + 1] = RgbToANSI(Lerp(a[1], b[1], t), Lerp(a[2], b[2], t), Lerp(a[3], b[3], t)) ..
				seg.Text:sub(i, i) .. RESET
				g = g + 1
			end
		elseif seg.Ansi then
			parts[#parts + 1] = seg.Ansi .. seg.Text .. RESET
		else
			parts[#parts + 1] = seg.Text
		end
	end
	return table.concat(parts)
end

function CoreBuilder:Print()
	print(self:Build())
end

for i, color in ipairs(PRESETS) do
	local ansi = RgbToANSI(color[1], color[2], color[3])
	CoreBuilder["C" .. i] = function(self, text)
		self._segs[#self._segs + 1] = { Text = tostring(text), Ansi = ansi }
		return self
	end
end

-- Public
local Palette = {
	Colours = PRESETS,
	Names   = {
		"Red", "Orange", "Yellow", "Green", "Blue", "Violet", "White", "Silver", "Black", "Magenta", "Blush",
		"Seelie Green", "Unseelie Violet", "Deep Teal", "Neon Seelie Green", "Neon Unseelie Violet",
		"Neon Teal", "Twilight Veil", "Gloaming Wisp", "Dusk Violet", "Fae Lilac"
	},
}

local function noop(self) return self end
local NullBuilder = setmetatable({}, { __index = function() return noop end })

function STAVDebug()
	if not Config.Get("Debug") then return NullBuilder end
	return STAVPrint():C16(string.format("[STAV - %s] ", Machine))
end

return { Palette = Palette }
