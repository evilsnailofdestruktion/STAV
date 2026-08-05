-- Credits to Focus
local Config = Ext.Require("Shared/Config.lua")
local U      = Ext.Require("Shared/Utility.lua")

local P = {}

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
	{ 211, 152, 255 },	-- C21 #D398FF Fae Lilac
	{ 173, 72,  255 },	-- C22 #ad48ff Umbral Bloom
	{ 229, 196, 255 },	-- C23 #e5c4ff Orchid Mist
	{ 18, 58, 122 },		-- C24 #123a7a Arcane Azure
	{ 169, 216, 255 },	-- C25 #a9d8ff Mystra's Light
	{ 22, 50, 92 },		-- C26 #16325c Netherese Shroud
	{ 199, 233, 255 },	-- C27 #c7e9ff Glacial Gleam
	{ 173, 235, 179 },	-- C28 #adebb3 Mint Green
	{ 239, 197, 118 } 	-- C29 #efc576 Lathander's Dawn
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

function P.Log()
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

function CoreBuilder:Name(uuid)
	if type(uuid) ~= "string" or uuid == "" then
		return self:C3("nil")
	end
	local name = U.GetDisplayName(uuid)
	if name and name ~= uuid then
		return self:C5(name):Raw(" ["):C3(uuid):Raw("]")
	end
	return self:C3(uuid)
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

P.Palette = {
	Colours = PRESETS,
	Names   = {
		"Red", "Orange", "Yellow", "Green", "Blue", "Violet", "White", "Silver", "Black", "Magenta", "Blush",
		"Seelie Green", "Unseelie Violet", "Deep Teal", "Neon Seelie Green", "Neon Unseelie Violet",
		"Neon Teal", "Twilight Veil", "Gloaming Wisp", "Dusk Violet", "Fae Lilac", "Umbral Bloom", "Orchid Mist",
		"Arcane Azure", "Mystra's Light", "Netherese Shroud", "Glacial Gleam", "Mint Green", "Lathander's Dawn"
	},
}

local function noop(self) return self end
local NullBuilder = setmetatable({}, { __index = function() return noop end })

function P.IsDebug()
	return Config.Get("Debug")
end

function P.Debug()
	if not P.IsDebug() then return NullBuilder end
	return P.Log():C16(string.format("[STAV - %s]", Machine)):C21("[" .. Ext.Timer.MonotonicTime() .. "] ")
end

return P
