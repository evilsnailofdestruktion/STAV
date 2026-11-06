local Applying       = Ext.Require("Client/Applying.lua")
local Config         = Ext.Require("Shared/Config.lua")
local NetDefs        = Ext.Require("Shared/NetDefs.lua")
local Presets        = Ext.Require("Client/Presets.lua")
local Vars           = Ext.Require("Shared/Vars.lua")
local E              = Ext.Require("Shared/Events.lua")
local L              = Ext.Require("Shared/Localization.lua")
local P              = Ext.Require("Shared/Printing.lua")
local Map            = Ext.Require("Client/UIMap.lua")
local Timelining     = Ext.Require("Client/Timelining.lua")
local U              = Ext.Require("Shared/Utility.lua")

local SELECTOR_WIDTH = 28
local LABEL_WIDTH    = 240

local DEFAULT_SPOTS_COLOUR = { 0.027, 0.027, 0.027 }

local UI             = {}

Timelining.SetUI(UI)

local function copyState(src)
	local out = {}
	for k, v in pairs(src) do
		out[k] = type(v) == "table" and { v[1], v[2], v[3], v[4] } or v
	end
	return out
end

local DEFAULTS = {}
for key, spec in pairs(Map) do DEFAULTS[key] = spec.default end

UI.State = copyState(DEFAULTS)

UI.Widgets = {}

local swatches = {}
local lastSent = nil
local sendTimer = nil

local function sendLook(characterUUID)
	lastSent = characterUUID
	NetDefs.NET_APPLY:SendToServer({
		characterUUID = characterUUID,
		state         = UI.State
	})
end

local function syncToServer()
	if sendTimer then return end
	sendTimer = Ext.Timer.WaitFor(300, function()
		sendTimer = nil
		local char = U.GetLiveCharacter()
		if char then sendLook(char.Uuid.EntityUuid) end
	end)
end

local function onChange(key, value)
	UI.State[key] = value
	UI.Changed = true
	Applying.Apply(key, value)
	if key == "spots" and value > 0 and UI.Widgets.spotsIntensity.Value[1] == 0 then
		UI.Widgets.spotsIntensity.Value = { 1, 0, 0, 0 }
		onChange("spotsIntensity", 1)
	end
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
	local new = math.max(min, math.min(max, UI.Widgets[key].Value[1] + delta))
	UI.Widgets[key].Value = { new, 0, 0, 0 }
	onChange(key, new)
end

local function addRow(parent, id, cells, selectors)
	local t = parent:AddTable("##STAV_" .. id .. "_row", cells + (selectors and 3 or 1))
	for _ = 1, cells do t:AddColumn("", "WidthStretch", 1) end
	if selectors then
		t:AddColumn("", "WidthFixed", SELECTOR_WIDTH)
		t:AddColumn("", "WidthFixed", SELECTOR_WIDTH)
	end
	t:AddColumn("", "WidthFixed", LABEL_WIDTH)
	return t:AddRow()
end

local function addSlider(parent, label, key)
	local min         = Map[key].min or 1
	local max         = Map[key].max
	local row         = addRow(parent, key, 1, true)
	local s           = row:AddCell():AddSliderInt("##" .. key, UI.State[key], min, max)
	s.IDContext       = "STAV_" .. key
	s.ItemWidth       = -1
	UI.Widgets[key]   = s
	s.OnChange        = function(w) onChange(key, w.Value[1]) end

	local prevBtn     = row:AddCell():AddButton("<")
	prevBtn.IDContext = "STAV_" .. key .. "_prev"
	prevBtn.Size      = { -1, 0 }
	prevBtn.OnClick   = function() step(key, min, max, -1) end

	local nextBtn     = row:AddCell():AddButton(">")
	nextBtn.IDContext = "STAV_" .. key .. "_next"
	nextBtn.Size      = { -1, 0 }
	nextBtn.OnClick   = function() step(key, min, max, 1) end

	row:AddCell():AddText(key == "spots" and label or label .. " [" .. min .. "-" .. max .. "]")
	return s
end

local function addFloatSlider(parent, label, key)
	local row       = addRow(parent, key, 1, false)
	local s         = row:AddCell():AddSlider("##" .. key, UI.State[key], 0, Map[key].max)
	s.IDContext     = "STAV_" .. key
	s.ItemWidth     = -1
	UI.Widgets[key] = s
	s.OnChange      = function(w) onChange(key, w.Value[1]) end
	row:AddCell():AddText(label)
	return s
end

local function paintSwatch(button, colour)
	for _, name in ipairs({ "Button", "ButtonHovered", "ButtonActive" }) do
		button:SetColor(name, colour)
	end
end

local function addSwatch(parent, row, key)
	local b         = row:AddCell():AddButton("##" .. key)
	b.IDContext     = "STAV_" .. key
	b.Size          = { -1, 0 }
	swatches[key]   = b

	local popup     = parent:AddPopup("##STAV_" .. key .. "_popup")
	local p         = popup:AddColorPicker("##" .. key)
	p.IDContext     = "STAV_" .. key .. "_picker"
	p.NoAlpha       = true
	p.NoLabel       = true
	p.DisplayHSV    = true
	p.DisplayHex    = true
	UI.Widgets[key] = p
	p.OnChange      = function(w)
		paintSwatch(b, w.Color)
		onChange(key, w.Color)
	end
	b.OnClick       = function() popup:Open() end

	if UI.State[key] then
		p.Color = UI.State[key]
		paintSwatch(b, UI.State[key])
	end
end

local function addPicker(parent, label, keys)
	local row = addRow(parent, keys[1], #keys, false)
	for _, key in ipairs(keys) do addSwatch(parent, row, key) end
	row:AddCell():AddText(label)
end

local function addConfigCheckbox(parent, label, key)
	local c     = parent:AddCheckbox(label, Config.Get(key))
	c.IDContext = "STAV_cfg_" .. key
	c.OnChange  = function(w) Config.Set(key, w.Checked) end
	return c
end

local function getTemplateId(char)
	for _, h in pairs(Ext.Entity.GetAllEntitiesWithComponent("ClientCCDummyDefinition")) do
		if h.CCCharacterDefinition then return h.CCCharacterDefinition.Definition.Definition.RootTemplate end
	end
	return char and char.GameObjectVisual.RootTemplateId
end

local function getSpotDefaults(char)
	local templateId = getTemplateId(char or _C())
	local template = templateId and Ext.Template.GetRootTemplate(templateId) --[[@as CharacterTemplate]]
	local charvis = template and Ext.Resource.Get(template.CharacterVisualResourceID, "CharacterVisual")
	local rows = {}
	if charvis then
		local overrides = charvis.VisualSet.MaterialOverrides
		for _, list in ipairs({ overrides.ScalarParameters, overrides.Vector3Parameters }) do
			for _, r in pairs(list) do
				if r.Enabled then rows[r.Parameter] = r.Value end
			end
		end
	end
	local intensity = rows[Map.spotsIntensity.name] or 0
	local colour = rows[Map.spotsColour.name] or DEFAULT_SPOTS_COLOUR
	return {
		spots          = intensity > 0 and math.floor(rows[Map.spots.name] or 0) + 1 or 0,
		spotsIntensity = intensity,
		spotsColour    = { colour[1], colour[2], colour[3], 1 }
	}
end

local vp               = Ext.IMGUI.GetViewportSize()
local win              = Ext.IMGUI.NewWindow("STAV")
win.Open               = false
win.Closeable          = true
win.NoFocusOnAppearing = true
win.Scaling            = 'Scaled'
win.AlwaysAutoResize   = false
win:SetPos({ vp[1] / 6, vp[2] / 10 })
win:SetSize({ 661, 947 })

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
	{ "Text",                 { 0.90, 0.90, 0.88, 1.00 } },
	{ "WindowBg",             { 0.07, 0.07, 0.07, 0.95 } },
	{ "FrameBg",              { 0.20, 0.20, 0.22, 1.00 } },
	{ "FrameBgHovered",       { 0.26, 0.26, 0.29, 1.00 } },
	{ "FrameBgActive",        { 0.30, 0.30, 0.33, 1.00 } },
	{ "Button",               { 0.22, 0.22, 0.25, 1.00 } },
	{ "ButtonHovered",        { 0.28, 0.28, 0.32, 1.00 } },
	{ "ButtonActive",         { 0.33, 0.33, 0.37, 1.00 } },
	{ "PopupBg",              { 0.12, 0.12, 0.14, 0.98 } },
	{ "ScrollbarBg",          { 0.12, 0.12, 0.14, 1.00 } },
	{ "ScrollbarGrab",        { 0.30, 0.30, 0.33, 1.00 } },
	{ "ScrollbarGrabHovered", { 0.36, 0.36, 0.40, 1.00 } },
	{ "ScrollbarGrabActive",  { 0.42, 0.42, 0.47, 1.00 } },
}

-- Engine defaults for the colours Daniela overrides but Chromed/CCEE leave alone;
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
	DANIELA      = {
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
	local rgb    = P.Palette.Colours[accentIdx] or P.Palette.Colours[18]
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

UI.Window     = win

local bar     = win:AddTabBar("STAV_Tabs")
local mainTab = bar:AddTabItem(L.T("Main"))

mainTab:AddDummy(0, 4)

local tattoos = mainTab:AddCollapsingHeader(L.T("Tattoos"))
tattoos.DefaultOpen = true
addSlider(tattoos, L.T("Head Alt"), "headAlt")
addPicker(tattoos, L.T("Alt Colour"), { "altColour" })
addSlider(tattoos, L.T("Body Main"), "bodyMain")
addSlider(tattoos, L.T("Body Alt"), "bodyAlt")
addFloatSlider(tattoos, L.T("Metalness"), "tatMetalness")
mainTab:AddSeparator()

local glowing = mainTab:AddCollapsingHeader(L.T("Glowing Tattoos"))
glowing.DefaultOpen = true
addSlider(glowing, L.T("Head"), "headGlow")
addSlider(glowing, L.T("Body"), "bodyGlow")
addPicker(glowing, L.T("Glow Colours"), { "glowColour", "glowColour2", "glowColour3" })
addFloatSlider(glowing, L.T("Glow Intensity"), "glowIntensity")
mainTab:AddSeparator()

local additional = mainTab:AddCollapsingHeader(L.T("Additional Choices"))
additional.DefaultOpen = true
addSlider(additional, L.T("Head Spots"), "spots")
addPicker(additional, L.T("Spots Colour"), { "spotsColour" })
addFloatSlider(additional, L.T("Spots Intensity"), "spotsIntensity")
addFloatSlider(additional, L.T("Vampirism"), "vampirism")
addCheckbox(additional, L.T("Body Scars"), "scar")
local pulseCb = addCheckbox(additional, L.T("Glow Pulse"), "glowPulse")
pulseCb.SameLine = true
pulseCb:SetStyle("ItemSpacing", 24, 6)
local swirlCb = addCheckbox(additional, L.T("Swirlies"), "swirl")
swirlCb.SameLine = true
swirlCb:SetStyle("ItemSpacing", 24, 6)
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

local function recordActive(name)
	UI.ActivePresetName = name
	local char = U.GetLiveCharacter()
	if char then charPresets[char.Uuid.EntityUuid] = (name ~= "" and name) or nil end
end

presetCombo.OnChange = function(c)
	local name = c.Options[c.SelectedIndex + 1]
	if type(name) ~= "string" or name == "" then return end
	recordActive(name)
	local look = Presets.Load(name)
	if look then UI.ApplyLook(look) end
end

presetTab:AddSeparator()

local presetStatus
local presetName = presetTab:AddInputText("##STAV_PresetName", "")
presetName.IDContext = "STAV_PresetName"
presetName.Hint = L.T("New Preset Name")

local savePresetBtn = presetTab:AddButton(L.T("Save as New"))
savePresetBtn.IDContext = "STAV_PresetSave"
savePresetBtn.OnClick = function()
	local name = Presets.Normalize(presetName.Text)
	if not name then return end
	if not Presets.Save(name, copyState(UI.State)) then
		presetStatus.Text = L.T("Preset file could not be written.")
		return
	end
	presetName.Text = ""
	recordActive(name)
	refreshPresets()
	presetStatus.Text = ""
end

local deletePresetBtn = presetTab:AddButton(L.T("Delete"))
deletePresetBtn.SameLine = true
deletePresetBtn.IDContext = "STAV_PresetDelete"
deletePresetBtn.OnClick = function()
	if not UI.ActivePresetName or UI.ActivePresetName == "" then return end
	if not Presets.Delete(UI.ActivePresetName) then
		presetStatus.Text = L.T("Preset file could not be written.")
		return
	end
	recordActive("")
	refreshPresets()
	presetStatus.Text = ""
end

presetTab:AddSeparator()

local exportInput = presetTab:AddInputText(L.T("Export As") .. "##STAV_ExportAs", "MyPreset")
local exportBtn = presetTab:AddButton(L.T("Export") .. "##STAV_Export")
exportBtn.OnClick = function()
	local name = Presets.Normalize(exportInput.Text)
	if not name then presetStatus.Text = L.T("Invalid export filename.") return end
	if not Presets.Export(name, (UI.ActivePresetName and Presets.Load(UI.ActivePresetName)) or copyState(UI.State)) then
		presetStatus.Text = L.T("Preset file could not be written.")
		return
	end
	presetStatus.Text = L.T("Exported") .. " " .. name
end

local importInput = presetTab:AddInputText(L.T("Import From") .. "##STAV_ImportFrom", "")
importInput.Hint = L.T("Filename...")
local importBtn = presetTab:AddButton(L.T("Import") .. "##STAV_Import")
importBtn.OnClick = function()
	local name, look = Presets.Import(importInput.Text)
	if not name then
		presetStatus.Text = L.T(look == "write" and "Preset file could not be written." or "Preset file not found or invalid.")
		return
	end
	recordActive(name)
	UI.ApplyLook(look)
	refreshPresets()
	presetStatus.Text = L.T("Imported") .. " " .. name
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
for i, name in ipairs(P.Palette.Names) do
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

function UI.RefreshWidgets(char)
	local spotDefaults = getSpotDefaults(char)
	for key, widget in pairs(UI.Widgets) do
		local v = UI.State[key]
		if v == nil then v = spotDefaults[key] end
		if type(v) == "boolean" then
			widget.Checked = v
		elseif type(v) == "table" then
			widget.Color = v
			paintSwatch(swatches[key], v)
		else
			widget.Value = { v, 0, 0, 0 }
		end
	end
end

local function seedState(look, char)
	for k, spec in pairs(Map) do
		if spec.default == nil then UI.State[k] = nil end
	end
	for k, v in pairs(look) do
		if Map[k] then UI.State[k] = v end
	end
	UI.RefreshWidgets(char)
end

local function restoreSpots(previous)
	for key, value in pairs(getSpotDefaults()) do
		if previous[key] ~= nil and UI.State[key] == nil then Applying.Apply(key, value) end
	end
end

function UI.PopulateFromEntity(char)
	char = char or _C()
	if not char then return end
	seedState(Vars.GetLook(char) or copyState(DEFAULTS), char)
	Applying.ApplyAll(UI.State)
	UI.ActivePresetName = charPresets[char.Uuid.EntityUuid] or ""
	refreshPresets()
end

function UI.ApplyLook(look)
	local previous = copyState(UI.State)
	seedState(look)
	restoreSpots(previous)
	UI.Changed = true
	Applying.ApplyAll(UI.State)
	syncToServer()
end

function UI.Reset()
	local previous = UI.State
	UI.State = copyState(DEFAULTS)
	UI.RefreshWidgets()
	restoreSpots(previous)
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
	local n = 0
	for _, h in pairs(Ext.Entity.GetAllEntitiesWithComponent("ClientCCDummyDefinition")) do
		if h.CCCharacterDefinition or h.CCChangeAppearanceDefinition then n = n + 1 end
	end
	return n
end

local function hasAny(set)
	for _ in pairs(set) do return true end
	return false
end

local rebuildHook  = nil
local rebuildTimer = nil

local function registerRebuildHook()
	if rebuildHook then return end
	rebuildHook = E.EquipmentVisualsUpdate.Subscribe(function()
		local sys = Ext.System.ClientEquipmentVisuals
		if (hasAny(sys.DestroyVisuals) or hasAny(sys.InitVisualLevel)) and not rebuildTimer then
			rebuildTimer = Ext.Timer.WaitFor(100, function()
				rebuildTimer = nil
				if ccDummyCount() > 0 then
					UI.RefreshWidgets()
					Applying.ApplyAll(UI.State)
				end
			end)
		end
	end)
end

local function unregisterRebuildHook()
	if rebuildHook then
		E.EquipmentVisualsUpdate.Unsubscribe(rebuildHook)
		rebuildHook = nil
	end
end

local function onDummyCreated()
	if Config.Get("AutoOpenCC") then UI.Open() end
	registerRebuildHook()
end

E.CCDummyCreated.Subscribe(function(p)
	if p.Carrier.CCCharacterDefinition or p.Carrier.CCChangeAppearanceDefinition then onDummyCreated() end
end)

E.CCDummyDestroyed.Subscribe(function()
	if ccDummyCount() == 0 then
		UI.Close()
		unregisterRebuildHook()
	end
end)

if ccDummyCount() > 0 then
	onDummyCreated()
end

E.ClientControlCreated.Subscribe(function(p)
	if UI.Window.Open then UI.PopulateFromEntity(p.Entity) end
end)

E.PhotoModeDummyCreated.Subscribe(function()
	if Config.Get("AutoOpenPhotoMode") then UI.Open() end
end)

E.PhotoModeDummyDestroyed.Subscribe(function()
	if Config.Get("AutoOpenPhotoMode") and #Ext.Entity.GetAllEntitiesWithComponent("PhotoModeDummy") == 0 then
		UI.Close()
	end
end)

NetDefs.NET_APPLY_SYNC:SetHandler(function(data)
	Applying.ApplyLocalPreset(data.preset, data.characterUUID, data.state)
	Timelining.PatchCharvis(data.characterUUID, data.state)
	if data.characterUUID == lastSent then
		UI.Changed = false
		UI.RefreshWidgets()
	end
end)

NetDefs.NET_AVATAR_PING:SetHandler(function()
	local char = U.GetLiveCharacter()
	if not char then return end
	local uuid = char.Uuid.EntityUuid
	local look = Vars.GetLook(char)
	if look then
		P.Debug():Raw("Avatar ping: seeded from persisted look for "):Name(uuid):Print()
		seedState(look, char)
	elseif UI.Changed then
		P.Debug():Raw("Avatar ping: resending unsynced look for "):Name(uuid):Print()
		sendLook(uuid)
	end
	if look or UI.Changed then Timelining.ApplyToTimelineDummies() end
end)
