local Vars          = Ext.Require("Shared/Vars.lua")
local Utility       = Ext.Require("Shared/Utility.lua")
local L             = Ext.Require("Shared/Localization.lua")
local NetDefs       = Ext.Require("Shared/NetDefs.lua")
local Applying      = Ext.Require("Client/Applying.lua")
local Config        = Ext.Require("Shared/Config.lua")

local BODY_MAX      = 96
local HEAD_MAX      = 93
local INTENSITY_MAX = 5

local UI = {}

UI.State = {
	scar          = false,
	bodyMain      = 1,
	bodyAlt       = 1,
	bodyGlow      = 1,
	headAlt       = 1,
	headGlow      = 1,
	altColor      = { 1, 1, 1, 1 },
	glowColor     = { 1, 1, 1, 1 },
	glowIntensity = 1,
	swirl         = false,
	vampirism     = false
}

local function copyState(src)
	local out = {}
	for k, v in pairs(src) do
		out[k] = type(v) == "table" and { v[1], v[2], v[3], v[4] } or v
	end
	return out
end

local DEFAULTS = copyState(UI.State)

UI.Widgets = {}

local function resolveCharacterUUID()
	local char = _C()
	if not char then return nil end
	if char.Level.LevelName == "SYS_CC_I" then return nil end
	return char.Uuid.EntityUuid
end

local function sendLook(characterUUID)
	NetDefs.NET_APPLY:SendToServer({
		characterUUID = characterUUID,
		state         = UI.State,
	})
end

local sendTimer = nil

local function syncToServer()
	if sendTimer then return end
	sendTimer = Ext.Timer.WaitFor(300, function()
		sendTimer = nil
		local uuid = resolveCharacterUUID()
		if uuid then sendLook(uuid) end
	end)
end

local function onChange(key, value)
	UI.State[key] = value
	UI.Changed = true
	Applying.Apply(key, value)
	syncToServer()
end

local function addCheckbox(parent, label, key)
	local c         = parent:AddCheckbox(label, UI.State[key])
	c.IDContext     = "STAV_" .. key
	UI.Widgets[key] = c
	c.OnChange      = function(w) onChange(key, w.Checked) end
	return c
end

local function addSlider(parent, label, max, key)
	local s         = parent:AddSliderInt(string.format("%s (1-%d)", label, max), UI.State[key], 1, max)
	s.IDContext     = "STAV_" .. key
	UI.Widgets[key] = s
	s.OnChange      = function(w) onChange(key, w.Value[1]) end
	return s
end

local function addFloatSlider(parent, label, max, key)
	local s         = parent:AddSlider(label, UI.State[key], 0, max)
	s.IDContext     = "STAV_" .. key
	UI.Widgets[key] = s
	s.OnChange      = function(w) onChange(key, w.Value[1]) end
	return s
end

local function addPicker(parent, label, key)
	local p         = parent:AddColorEdit(label)
	p.IDContext     = "STAV_" .. key
	p.Float         = true
	p.NoAlpha       = false
	p.Color         = UI.State[key]
	UI.Widgets[key] = p
	p.OnChange      = function(w) onChange(key, w.Color) end
	return p
end

local vp               = Ext.IMGUI.GetViewportSize()
local win              = Ext.IMGUI.NewWindow("STAV")
win.Open               = false
win.Closeable          = true
win.NoFocusOnAppearing = true
win.Scaling            = 'Scaled'
win.AlwaysAutoResize   = false
win:SetPos({ vp[1] / 6, vp[2] / 10 })
win:SetSize({ 593, 809 })

local function tint(base, alpha)
	return { base[1], base[2], base[3], alpha }
end

local function scale(c, f)
	return { c[1] * f, c[2] * f, c[3] * f }
end

local function lighten(c, t)
	return { c[1] + (1 - c[1]) * t, c[2] + (1 - c[2]) * t, c[3] + (1 - c[3]) * t }
end

local DARK = { 0.09, 0.09, 0.11 }

local THEMES = {
	chromed = function(accent, glow)
		return {
			{ "TitleBgActive",    tint(accent, 1.00) },
			{ "Tab",              tint(scale(accent, 0.5), 0.86) },
			{ "TabHovered",       tint(accent, 0.70) },
			{ "TabActive",        tint(accent, 0.90) },
			{ "Header",           tint(accent, 0.35) },
			{ "HeaderHovered",    tint(accent, 0.60) },
			{ "HeaderActive",     tint(accent, 0.80) },
			{ "CheckMark",        tint(glow, 1.00) },
			{ "SliderGrab",       tint(accent, 0.65) },
			{ "SliderGrabActive", tint(glow, 1.00) },
			{ "Separator",        tint(accent, 0.00) },
		}
	end,
	ccee = function(accent, glow)
		return {
			{ "TitleBgActive",    tint(DARK, 1.00) },
			{ "Tab",              tint(DARK, 0.90) },
			{ "TabHovered",       tint(accent, 0.45) },
			{ "TabActive",        tint(accent, 0.65) },
			{ "Header",           tint(accent, 0.00) },
			{ "HeaderHovered",    tint(accent, 0.20) },
			{ "HeaderActive",     tint(accent, 0.30) },
			{ "CheckMark",        tint(accent, 1.00) },
			{ "SliderGrab",       tint(accent, 0.65) },
			{ "SliderGrabActive", tint(glow, 1.00) },
			{ "Separator",        tint(accent, 0.90) },
		}
	end,
}

local function applyTheme(style, accentIdx)
	local rgb    = STAVPalette.Colours[accentIdx] or STAVPalette.Colours[18]
	local accent = { rgb[1] / 255, rgb[2] / 255, rgb[3] / 255 }
	local glow   = lighten(accent, 0.45)
	for _, c in ipairs((THEMES[style] or THEMES.chromed)(accent, glow)) do
		win:SetColor(c[1], c[2])
	end
	win:SetColor("ResizeGrip", tint(accent, 0.18))
	win:SetColor("ResizeGripHovered", tint(accent, 0.60))
	win:SetColor("ResizeGripActive", tint(accent, 0.90))
	win:SetColor("SeparatorHovered", tint(accent, 0.60))
	win:SetColor("SeparatorActive", tint(accent, 0.90))
end

for _, s in ipairs({
	{ "WindowRounding",   10 },
	{ "ChildRounding",    8 },
	{ "FrameRounding",    5 },
	{ "GrabRounding",     4 },
	{ "TabRounding",      5 },
	{ "WindowBorderSize", 1 },
	{ "WindowMinSize",    380, 380 },
	{ "WindowPadding",    12,  12 },
	{ "ItemSpacing",      8,   6 },
	{ "FramePadding",     8,   4 },
}) do
	if s[3] then win:SetStyle(s[1], s[2], s[3]) else win:SetStyle(s[1], s[2]) end
end

for _, c in ipairs({
	{ "Text",           { 0.90, 0.90, 0.88, 1.00 } },
	{ "WindowBg",       { 0.07, 0.07, 0.07, 0.95 } },
	{ "FrameBg",        { 0.20, 0.20, 0.22, 1.00 } },
	{ "FrameBgHovered", { 0.26, 0.26, 0.29, 1.00 } },
	{ "FrameBgActive",  { 0.30, 0.30, 0.33, 1.00 } },
	{ "Button",         { 0.22, 0.22, 0.25, 1.00 } },
	{ "ButtonHovered",  { 0.28, 0.28, 0.32, 1.00 } },
	{ "ButtonActive",   { 0.33, 0.33, 0.37, 1.00 } },
	{ "PopupBg",        { 0.12, 0.12, 0.14, 0.98 } },
	{ "ScrollbarBg",          { 0.12, 0.12, 0.14, 1.00 } },
	{ "ScrollbarGrab",        { 0.30, 0.30, 0.33, 1.00 } },
	{ "ScrollbarGrabHovered", { 0.36, 0.36, 0.40, 1.00 } },
	{ "ScrollbarGrabActive",  { 0.42, 0.42, 0.47, 1.00 } },
}) do
	win:SetColor(c[1], c[2])
end

applyTheme(Config.Get("ThemeStyle"), Config.Get("ThemeAccent"))

UI.Window    = win

local bar    = win:AddTabBar("STAV_Tabs")
local mainTab = bar:AddTabItem(L.T("Main"))

mainTab:AddDummy(0, 4)

local body = mainTab:AddCollapsingHeader(L.T("Body"))
body.DefaultOpen = true
addCheckbox(body, L.T("Body Scar"), "scar")
addSlider(body, L.T("Main Tattoo"), BODY_MAX, "bodyMain")
addSlider(body, L.T("Alt Tattoo"), BODY_MAX, "bodyAlt")
addSlider(body, L.T("Glow Tattoo"), BODY_MAX, "bodyGlow")
mainTab:AddSeparator()

local head = mainTab:AddCollapsingHeader(L.T("Head"))
head.DefaultOpen = true
addSlider(head, L.T("Alt Tattoo"), HEAD_MAX, "headAlt")
addSlider(head, L.T("Glow Tattoo"), HEAD_MAX, "headGlow")
mainTab:AddSeparator()

local shared = mainTab:AddCollapsingHeader(L.T("Shared"))
shared.DefaultOpen = true
addPicker(shared, L.T("Alt Tattoo Colour"), "altColor")
addPicker(shared, L.T("Glow Colour"), "glowColor")
addFloatSlider(shared, L.T("Glow Intensity"), INTENSITY_MAX, "glowIntensity")
addCheckbox(shared, L.T("Swirlies"), "swirl")
addCheckbox(shared, L.T("Vampirism"), "vampirism")
mainTab:AddSeparator()

mainTab:AddDummy(0, 6)
local resetBtn = mainTab:AddButton(L.T("Reset"))
resetBtn.IDContext = "STAV_Reset"
resetBtn.OnClick = function() UI.Reset() end

local themeTab = bar:AddTabItem(L.T("Themes"))
themeTab:AddDummy(0, 4)

local chromedCb = themeTab:AddCheckbox(L.T("Chromed"), Config.Get("ThemeStyle") ~= "ccee")
chromedCb.IDContext = "STAV_ThemeChromed"
local cceeCb = themeTab:AddCheckbox("CCEE", Config.Get("ThemeStyle") == "ccee")
cceeCb.IDContext = "STAV_ThemeCcee"
cceeCb.SameLine = true

local function setStyle(style)
	Config.Set("ThemeStyle", style)
	chromedCb.Checked = style == "chromed"
	cceeCb.Checked = style == "ccee"
	applyTheme(style, Config.Get("ThemeAccent"))
end

chromedCb.OnChange = function() setStyle("chromed") end
cceeCb.OnChange = function() setStyle("ccee") end

local accentNames = {}
for i, name in ipairs(STAVPalette.Names) do
	accentNames[i] = L.T(name)
end

local accentCombo = themeTab:AddCombo(L.T("Accent"))
accentCombo.IDContext = "STAV_ThemeAccent"
accentCombo.Options = accentNames
accentCombo.SelectedIndex = Config.Get("ThemeAccent") - 1
accentCombo.OnChange = function(w)
	local idx = w.SelectedIndex + 1
	Config.Set("ThemeAccent", idx)
	applyTheme(Config.Get("ThemeStyle"), idx)
end

function UI.Toggle()
	UI.Window.Open = not UI.Window.Open
	if UI.Window.Open then UI.PopulateFromEntity() end
end

function UI.Open()
	UI.Window.Open = true
	UI.PopulateFromEntity()
end

function UI.Close()
	UI.Window.Open = false
end

function UI.RefreshWidgets()
	for key, widget in pairs(UI.Widgets) do
		local v = UI.State[key]
		if type(v) == "boolean" then
			widget.Checked = v
		elseif type(v) == "table" then
			widget.Color = v
		else
			widget.Value = { v, 0, 0, 0 }
		end
	end
end

local function seedState(look)
	for k, v in pairs(look) do
		if UI.State[k] ~= nil then
			UI.State[k] = v
		end
	end
	UI.RefreshWidgets()
end

function UI.PopulateFromEntity(char)
	char = char or _C()
	if not char then return end
	seedState(Vars.GetLook(char) or copyState(DEFAULTS))
	Applying.ApplyAll(UI.State)
end

function UI.Reset()
	UI.State = copyState(DEFAULTS)
	UI.RefreshWidgets()
	Applying.ApplyAll(UI.State)
	syncToServer()
end

function STAVToggleUI()
	UI.Toggle()
end

if type(MCM) == "table" then
	MCM.Keybinding.SetCallback("STAV_UI_Panel", function(_)
		UI.Toggle()
	end)
	MCM.EventButton.RegisterCallback("STAV_UI_Open", function()
		UI.Toggle()
	end)
end

local function ccDummyCount()
	return #Ext.Entity.GetAllEntitiesWithComponent("ClientCCDummyDefinition")
end

local function hasAny(set)
	for _ in pairs(set) do return true end
	return false
end

local rebuildHook  = nil
local rebuildTimer = nil

local function registerRebuildHook()
	if rebuildHook then return end
	rebuildHook = Ext.Entity.OnSystemUpdate("ClientEquipmentVisuals", function()
		local sys = Ext.System.ClientEquipmentVisuals
		if (hasAny(sys.DestroyVisuals) or hasAny(sys.InitVisualLevel)) and not rebuildTimer then
			rebuildTimer = Ext.Timer.WaitFor(100, function()
				rebuildTimer = nil
				if ccDummyCount() > 0 then Applying.ApplyAll(UI.State) end
			end)
		end
	end)
end

local function unregisterRebuildHook()
	if rebuildHook then
		Ext.Entity.Unsubscribe(rebuildHook)
		rebuildHook = nil
	end
end

local function onDummyCreated()
	UI.Open()
	registerRebuildHook()
end

Ext.Entity.OnCreateDeferred("ClientCCDummyDefinition", function()
	onDummyCreated()
end)

Ext.Entity.OnDestroyDeferred("ClientCCDummyDefinition", function()
	if ccDummyCount() == 0 then
		UI.Close()
		unregisterRebuildHook()
	end
end)

if ccDummyCount() > 0 then
	onDummyCreated()
end

Ext.Entity.OnCreateDeferred("ClientControl", function(e)
	if UI.Window.Open then UI.PopulateFromEntity(e) end
end)

Ext.Entity.OnCreateDeferred("PhotoModeDummy", function()
	if Config.Get("AutoOpenPhotoMode") then UI.Open() end
end)

Ext.Entity.OnDestroyDeferred("PhotoModeDummy", function()
	if Config.Get("AutoOpenPhotoMode") and #Ext.Entity.GetAllEntitiesWithComponent("PhotoModeDummy") == 0 then
		UI.Close()
	end
end)

local TL_APPLY_DELAY = 333

local function findTimelineOwner(actor)
	for _, e in pairs(Ext.Entity.GetAllEntitiesWithComponent("Origin")) do
		if e.TimelineActorData and e.TimelineActorData.Actor == actor then return e end
	end
end

-- Cutscene actors are TLPreviewDummy entities whose visual streams in ~189ms
-- after the entity is created; defer past that, then apply the owner's look.
Ext.Entity.OnCreateDeferred("TLPreviewDummy", function(e)
	Ext.Timer.WaitFor(TL_APPLY_DELAY, function()
		if not (e.Visual and e.Visual.Visual) then return end
		local tac = e.ClientTimelineActorControl
		if not tac then return end
		local owner = findTimelineOwner(tac.Actor)
		local look = owner and Vars.GetLook(owner)
		if not look then
			local uuid = resolveCharacterUUID()
			local own = uuid and Ext.Entity.Get(uuid)
			if own and e.TLPreviewDummy.OriginalCharacterTemplate == own.GameObjectVisual.RootTemplateId then
				look = Vars.GetLook(own)
				if not look and UI.Changed then look = UI.State end
			end
		end
		if not look then return end
		STAVDebug("TL %s: applying (%s)", e.TLPreviewDummy.Name, owner and "owner" or "self")
		Applying.ApplyLookToEntity(e, look)
	end)
end)

NetDefs.NET_APPLY_SYNC:SetHandler(function(data)
	Applying.ApplyLocalPreset(data.preset, data.characterUUID, data.state)
end)

NetDefs.NET_AVATAR_PING:SetHandler(function()
	local uuid = resolveCharacterUUID()
	if not uuid then return end
	local look = Vars.GetLook(Ext.Entity.Get(uuid))
	if look then
		STAVDebug("Aavatar ping: seeded from persisted look for %s", uuid)
		seedState(look)
	elseif UI.Changed then
		STAVDebug("Avatar ping: resending unsynced look for %s", uuid)
		sendLook(uuid)
	else
		STAVDebug("Avatar ping: no-op for %s", uuid)
	end
end)
