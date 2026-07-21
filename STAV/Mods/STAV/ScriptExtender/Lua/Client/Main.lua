local Vars          = Ext.Require("Shared/Vars.lua")
local L             = Ext.Require("Shared/Localization.lua")
local NetDefs       = Ext.Require("Shared/NetDefs.lua")
local Applying      = Ext.Require("Client/Applying.lua")
local Config        = Ext.Require("Shared/Config.lua")
local Presets       = Ext.Require("Client/Presets.lua")
local Printing      = Ext.Require("Shared/Printing.lua")

local BODY_MAX      = 96
local HEAD_MAX      = 93
local INTENSITY_MAX = 5
local SLIDER_RESERVE = 286

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

local function resolveCharacter()
	local char = _C()
	if not char then return nil end
	if char.Level.LevelName == "SYS_CC_I" then return nil end
	return char
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
		local char = resolveCharacter()
		if char then sendLook(char.Uuid.EntityUuid) end
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

local function step(key, min, max, delta)
	local new = math.max(min, math.min(max, UI.State[key] + delta))
	UI.Widgets[key].Value = { new, 0, 0, 0 }
	onChange(key, new)
end

local function addSlider(parent, label, max, key)
	local s           = parent:AddSliderInt("##" .. key, UI.State[key], 1, max)
	s.IDContext       = "STAV_" .. key
	s.ItemWidth       = -SLIDER_RESERVE
	UI.Widgets[key]   = s
	s.OnChange        = function(w) onChange(key, w.Value[1]) end

	local prevBtn     = parent:AddButton("<")
	prevBtn.IDContext = "STAV_" .. key .. "_prev"
	prevBtn.SameLine  = true
	prevBtn.OnClick   = function() step(key, 1, max, -1) end

	local nextBtn     = parent:AddButton(">")
	nextBtn.IDContext = "STAV_" .. key .. "_next"
	nextBtn.SameLine  = true
	nextBtn.OnClick   = function() step(key, 1, max, 1) end

	local labelText    = parent:AddText(string.format("%s (1-%d)", label, max))
	labelText.SameLine = true
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

local function addConfigCheckbox(parent, label, key)
	local c     = parent:AddCheckbox(label, Config.Get(key))
	c.IDContext = "STAV_cfg_" .. key
	c.OnChange  = function(w) Config.Set(key, w.Checked) end
	return c
end

local vp               = Ext.IMGUI.GetViewportSize()
local win              = Ext.IMGUI.NewWindow("STAV")
win.Open               = false
win.Closeable          = true
win.NoFocusOnAppearing = true
win.Scaling            = 'Scaled'
win.AlwaysAutoResize   = false
win:SetPos({ vp[1] / 6, vp[2] / 10 })
win:SetSize({ 597, 809 })

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

local DEFAULT = {
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
}

-- engine defaults for the colours Daniela overrides but Chromed/CCEE leave alone;
-- re-applied on the non-Daniela path so a Daniela → other switch fully reverts
local DEFAULT_EXTRAS = {
	{ "TextDisabled",              { 0.86, 0.79, 0.68, 0.28 } },
	{ "ChildBg",                   { 0.12, 0.11, 0.11, 0.40 } },
	{ "Border",                    { 0.24, 0.15, 0.08, 0.00 } },
	{ "BorderShadow",              { 0.07, 0.07, 0.07, 0.78 } },
	{ "TitleBg",                   { 0.07, 0.07, 0.07, 1.00 } },
	{ "TitleBgCollapsed",          { 0.05, 0.05, 0.05, 0.75 } },
	{ "MenuBarBg",                 { 0.07, 0.07, 0.07, 0.47 } },
	{ "TabUnfocusedActive",        { 0.05, 0.05, 0.05, 0.78 } },
	{ "TabDimmedSelectedOverline", { 0.05, 0.05, 0.05, 0.78 } },
}

local DANIELA
do
	local base   = { 0.32, 0.00, 0.00, 1.00 }
	local hover  = { 0.37, 0.00, 0.00, 1.00 }
	local active = { 0.28, 0.00, 0.00, 1.00 }
	DANIELA = {
		{ "Text",                      { 0.90, 0.90, 0.90, 1.00 } },
		{ "TextDisabled",              { 0.55, 0.55, 0.55, 1.00 } },
		{ "WindowBg",                  { 0.15, 0.00, 0.00, 1.00 } },
		{ "ChildBg",                   { 0.05, 0.05, 0.05, 1.00 } },
		{ "PopupBg",                   { 0.05, 0.05, 0.05, 1.00 } },
		{ "Border",                    { 0.32, 0.20, 0.20, 0.25 } },
		{ "BorderShadow",              { 0.00, 0.00, 0.00, 0.90 } },
		{ "FrameBg",                   base },
		{ "FrameBgHovered",            hover },
		{ "FrameBgActive",             active },
		{ "TitleBg",                   base },
		{ "TitleBgActive",             { 0.30, 0.00, 0.00, 1.00 } },
		{ "TitleBgCollapsed",          active },
		{ "MenuBarBg",                 base },
		{ "ScrollbarBg",               { 0.06, 0.06, 0.06, 1.00 } },
		{ "ScrollbarGrab",             base },
		{ "ScrollbarGrabHovered",      hover },
		{ "ScrollbarGrabActive",       active },
		{ "CheckMark",                 { 0.90, 0.90, 0.90, 1.00 } },
		{ "SliderGrab",                { 0.48, 0.02, 0.02, 1.00 } },
		{ "SliderGrabActive",          { 0.45, 0.02, 0.02, 1.00 } },
		{ "Button",                    base },
		{ "ButtonHovered",             hover },
		{ "ButtonActive",              active },
		{ "Header",                    base },
		{ "HeaderHovered",             hover },
		{ "HeaderActive",              active },
		{ "Separator",                 base },
		{ "SeparatorHovered",          hover },
		{ "SeparatorActive",           active },
		{ "ResizeGrip",                base },
		{ "ResizeGripHovered",         hover },
		{ "ResizeGripActive",          active },
		{ "Tab",                       base },
		{ "TabHovered",                hover },
		{ "TabActive",                 active },
		{ "TabUnfocusedActive",        { 0.10, 0.08, 0.08, 1.00 } },
		{ "TabDimmedSelectedOverline", { 0.40, 0.15, 0.15, 1.00 } },
	}
end

local function applyTheme(style, accentIdx)
	if style == "daniela" then
		for _, c in ipairs(DANIELA) do
			win:SetColor(c[1], c[2])
		end
		return
	end
	local rgb    = Printing.Palette.Colours[accentIdx] or Printing.Palette.Colours[18]
	local accent = { rgb[1] / 255, rgb[2] / 255, rgb[3] / 255 }
	local glow   = lighten(accent, 0.45)
	for _, c in ipairs(DEFAULT) do
		win:SetColor(c[1], c[2])
	end
	for _, c in ipairs(DEFAULT_EXTRAS) do
		win:SetColor(c[1], c[2])
	end
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

local presetTab = bar:AddTabItem(L.T("Presets"))
presetTab:AddDummy(0, 4)

presetTab:AddText(L.T("Presets"))
local presetCombo = presetTab:AddCombo("##STAV_Presets")
presetCombo.IDContext = "STAV_Presets"

local function refreshPresets()
	UI.PresetNames = Presets.List()
	presetCombo.Options = UI.PresetNames
	presetCombo.SelectedIndex = -1
	for i, n in ipairs(UI.PresetNames) do
		if n == UI.ActivePresetName then
			presetCombo.SelectedIndex = i - 1
			break
		end
	end
end

local charPresets = {}

local function applyPreset(name)
	local values = Presets.Load(name)
	if values then UI.ApplyLook(values) end
end

local function recordActive(name)
	UI.ActivePresetName = name or ""
	local char = resolveCharacter()
	if char then charPresets[char.Uuid.EntityUuid] = (name ~= "" and name) or nil end
end

presetCombo.OnChange = function(c)
	local name = c.Options[c.SelectedIndex + 1]
	if type(name) ~= "string" or name == "" then return end
	recordActive(name)
	applyPreset(name)
end

presetTab:AddSeparator()

local presetName = presetTab:AddInputText("##STAV_PresetName", "")
presetName.IDContext = "STAV_PresetName"
presetName.Hint = L.T("New Preset Name")

local savePresetBtn = presetTab:AddButton(L.T("Save as New"))
savePresetBtn.IDContext = "STAV_PresetSave"
savePresetBtn.OnClick = function()
	local name = Presets.Normalize(presetName.Text)
	if not name then return end
	Presets.Save(name, copyState(UI.State))
	presetName.Text = ""
	recordActive(name)
	refreshPresets()
end

local deletePresetBtn = presetTab:AddButton(L.T("Delete"))
deletePresetBtn.SameLine = true
deletePresetBtn.IDContext = "STAV_PresetDelete"
deletePresetBtn.OnClick = function()
	if not UI.ActivePresetName or UI.ActivePresetName == "" then return end
	Presets.Delete(UI.ActivePresetName)
	recordActive("")
	refreshPresets()
end

presetTab:AddSeparator()
local presetStatus

local exportInput = presetTab:AddInputText(L.T("Export As") .. "##STAV_ExportAs", "MyPreset")
local exportBtn = presetTab:AddButton(L.T("Export") .. "##STAV_Export")
exportBtn.OnClick = function()
	local name = Presets.Normalize(exportInput.Text)
	if not name then presetStatus.Text = L.T("Invalid export filename.") return end
	Presets.Export(name, (UI.ActivePresetName and Presets.Load(UI.ActivePresetName)) or copyState(UI.State))
	presetStatus.Text = string.format("%s %s", L.T("Exported"), name)
end

local importInput = presetTab:AddInputText(L.T("Import From") .. "##STAV_ImportFrom", "")
importInput.Hint = L.T("Filename...")
local importBtn = presetTab:AddButton(L.T("Import") .. "##STAV_Import")
importBtn.OnClick = function()
	local name = Presets.Import(importInput.Text)
	if not name then presetStatus.Text = L.T("Preset file not found or invalid.") return end
	recordActive(name)
	applyPreset(name)
	refreshPresets()
	presetStatus.Text = string.format("%s %s", L.T("Imported"), name)
end

presetStatus = presetTab:AddInputText("##STAV_PresetStatus", "")
presetStatus.ReadOnly = true
presetStatus:SetColor("FrameBg", { 0, 0, 0, 0 })

refreshPresets()

local themeTab = bar:AddTabItem(L.T("Themes"))
themeTab:AddDummy(0, 4)

local themeStyle = Config.Get("ThemeStyle")
local chromedCb = themeTab:AddCheckbox(L.T("Chromed"), themeStyle == "chromed")
chromedCb.IDContext = "STAV_ThemeChromed"
local cceeCb = themeTab:AddCheckbox("CCEE", themeStyle == "ccee")
cceeCb.IDContext = "STAV_ThemeCcee"
cceeCb.SameLine = true
local danielaCb = themeTab:AddCheckbox("Daniela", themeStyle == "daniela")
danielaCb.IDContext = "STAV_ThemeDaniela"
danielaCb.SameLine = true

local function setStyle(style)
	Config.Set("ThemeStyle", style)
	chromedCb.Checked = style == "chromed"
	cceeCb.Checked = style == "ccee"
	danielaCb.Checked = style == "daniela"
	applyTheme(style, Config.Get("ThemeAccent"))
end

chromedCb.OnChange = function() setStyle("chromed") end
cceeCb.OnChange = function() setStyle("ccee") end
danielaCb.OnChange = function() setStyle("daniela") end

local accentNames = {}
for i, name in ipairs(Printing.Palette.Names) do
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

local advTab = bar:AddTabItem(L.T("Advanced"))
advTab:AddDummy(0, 4)
addConfigCheckbox(advTab, L.T("Auto-open in Character Creation"), "AutoOpenCC")
addConfigCheckbox(advTab, L.T("Auto-open in Photo Mode"), "AutoOpenPhotoMode")
addConfigCheckbox(advTab, L.T("Debug Logging"), "Debug")

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
	UI.ActivePresetName = charPresets[char.Uuid.EntityUuid] or ""
	refreshPresets()
end

function UI.ApplyLook(look)
	seedState(look)
	UI.Changed = true
	Applying.ApplyAll(UI.State)
	syncToServer()
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
	if Config.Get("AutoOpenCC") then UI.Open() end
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

local TL_RETRY_MS  = 333
local TL_MAX_TRIES = 3

local function findTimelineOwner(actor)
	for _, e in pairs(Ext.Entity.GetAllEntitiesWithComponent("Origin")) do
		if e.TimelineActorData and e.TimelineActorData.Actor == actor then return e end
	end
end

local function applyTimelineLook(e)
	local tac = e.ClientTimelineActorControl
	if not tac then return end
	local owner = findTimelineOwner(tac.Actor)
	local look = owner and Vars.GetLook(owner)
	if not look then
		local own = resolveCharacter()
		if own and e.TLPreviewDummy.OriginalCharacterTemplate == own.GameObjectVisual.RootTemplateId then
			look = Vars.GetLook(own)
			if not look and UI.Changed then look = UI.State end
		end
	end
	if not look then return end
	STAVDebug("TL %s: applying (%s)", e.TLPreviewDummy.Name, owner and "owner" or "self")
	Applying.ApplyLookToEntity(e, look)
end

Ext.Entity.OnCreateDeferred("TLPreviewDummy", function(e)
	if e.TLPreviewDummy.OriginalCharacterTemplate == "" then return end
	local tries = 0
	local function attempt()
		tries = tries + 1
		if e.Visual and e.Visual.Visual then
			applyTimelineLook(e)
		elseif tries < TL_MAX_TRIES then
			Ext.Timer.WaitFor(TL_RETRY_MS, attempt)
		end
	end
	Ext.Timer.WaitFor(TL_RETRY_MS, attempt)
end)

NetDefs.NET_APPLY_SYNC:SetHandler(function(data)
	Applying.ApplyLocalPreset(data.preset, data.characterUUID, data.state)
end)

NetDefs.NET_AVATAR_PING:SetHandler(function()
	local char = resolveCharacter()
	if not char then return end
	local uuid = char.Uuid.EntityUuid
	local look = Vars.GetLook(char)
	if look then
		STAVDebug("Avatar ping: seeded from persisted look for %s", uuid)
		seedState(look)
	elseif UI.Changed then
		STAVDebug("Avatar ping: resending unsynced look for %s", uuid)
		sendLook(uuid)
	else
		STAVDebug("Avatar ping: no-op for %s", uuid)
	end
end)
