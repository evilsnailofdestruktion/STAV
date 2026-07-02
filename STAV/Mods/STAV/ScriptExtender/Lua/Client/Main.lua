local Vars    = Ext.Require("Shared/Vars.lua")
local Utility = Ext.Require("Shared/Utility.lua")
local L       = Ext.Require("Shared/Localization.lua")
local NetDefs   = Ext.Require("Shared/NetDefs.lua")
local Applying  = Ext.Require("Client/Applying.lua")
-- local Params = Ext.Require("Shared/Params.lua") -- nudge-only; superseded by clean-path

local BODY_MAX      = 60
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
	swirl			  = false
}

UI.Widgets = {}

local function resolveCharacterUUID()
	local partyEntity = Ext.Entity.GetAllEntitiesWithComponent("PartyView")[1]
	if not partyEntity then return nil end
	for _, view in pairs(partyEntity.PartyView.Views) do
		if view.UserID == 1 then
			for _, ch in pairs(view.Characters) do
				if ch.Avatar and ch.Uuid then return ch.Uuid.EntityUuid end
			end
		end
	end
	return nil
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
	STAVDebug("%s = %s", key, tostring(value))
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

local vp  = Ext.IMGUI.GetViewportSize()
local win = Ext.IMGUI.NewWindow("STAV")
win.Open              = false
win.Closeable         = true
win.NoFocusOnAppearing = true
win.Scaling           = 'Scaled'
win.AlwaysAutoResize  = false
win:SetPos({ vp[1] / 6, vp[2] / 10 })
if vp[1] <= 1920 and vp[2] <= 1080 then
	win:SetSize({ 480 / 1.333, 600 / 1.333 })
else
	win:SetSize({ 480, 600 })
end
local ACCENT = { 0.424, 0.447, 0.796 }
local GLOW   = { 0.58, 0.62, 1.00 }

local function tint(base, alpha)
	return { base[1], base[2], base[3], alpha }
end

for _, s in ipairs({
	{ "WindowRounding", 10 },
	{ "ChildRounding", 8 },
	{ "FrameRounding", 5 },
	{ "GrabRounding", 4 },
	{ "TabRounding", 5 },
	{ "WindowBorderSize", 1 },
	{ "WindowMinSize", 380, 380 },
	{ "WindowPadding", 12, 12 },
	{ "ItemSpacing", 8, 6 },
	{ "FramePadding", 8, 4 },
}) do
	if s[3] then win:SetStyle(s[1], s[2], s[3]) else win:SetStyle(s[1], s[2]) end
end

for _, c in ipairs({
	{ "Text", { 0.90, 0.90, 0.88, 1.00 } },
	{ "TitleBgActive", tint(ACCENT, 1.00) },
	{ "Tab", { 0.20, 0.21, 0.36, 0.86 } },
	{ "TabHovered", tint(ACCENT, 0.70) },
	{ "TabActive", tint(ACCENT, 0.90) },
	{ "Header", tint(ACCENT, 0.35) },
	{ "HeaderHovered", tint(ACCENT, 0.60) },
	{ "HeaderActive", tint(ACCENT, 0.80) },
	{ "CheckMark", tint(GLOW, 1.00) },
	{ "SliderGrab", tint(ACCENT, 0.65) },
	{ "SliderGrabActive", tint(GLOW, 1.00) },
	{ "Separator", tint(ACCENT, 0.40) },
}) do
	win:SetColor(c[1], c[2])
end

UI.Window = win

local bar    = win:AddTabBar("STAV_Tabs")
local tatTab = bar:AddTabItem(L.T("Tattoos"))

tatTab:AddDummy(0, 4)

local body = tatTab:AddCollapsingHeader(L.T("Body"))
body.DefaultOpen = true
addCheckbox(body, L.T("Body Scar"), "scar")
addSlider(body, L.T("Main Tattoo"), BODY_MAX, "bodyMain")
addSlider(body, L.T("Alt Tattoo"), BODY_MAX, "bodyAlt")
addSlider(body, L.T("Glow Tattoo"), BODY_MAX, "bodyGlow")

local head = tatTab:AddCollapsingHeader(L.T("Head"))
head.DefaultOpen = true
addSlider(head, L.T("Alt Tattoo"), HEAD_MAX, "headAlt")
addSlider(head, L.T("Glow Tattoo"), HEAD_MAX, "headGlow")

local shared = tatTab:AddCollapsingHeader(L.T("Shared"))
shared.DefaultOpen = true
addPicker(shared, L.T("Alt Tattoo Colour"), "altColor")
addPicker(shared, L.T("Glow Colour"), "glowColor")
addFloatSlider(shared, L.T("Glow Intensity"), INTENSITY_MAX, "glowIntensity")
addCheckbox(shared, L.T("Swirlies"), "swirl")

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

function UI.PopulateFromEntity()
	local me = _C()
	if not me then return end
	local look = Vars.GetLook(me)
	if not look then return end
	for k, v in pairs(look) do
		if UI.State[k] ~= nil then
			UI.State[k] = v
		end
	end
	UI.RefreshWidgets()
	Applying.ApplyAll(UI.State)
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

local rebuildHook = nil

local function registerRebuildHook()
	if rebuildHook then return end
	rebuildHook = Ext.Entity.OnSystemUpdate("ClientEquipmentVisuals", function()
		local sys = Ext.System.ClientEquipmentVisuals
		if hasAny(sys.DestroyVisuals) or hasAny(sys.InitVisualLevel) then
			Ext.Timer.WaitFor(100, function()
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

--[[ nudge fallback — superseded by the clean-path server strip (Creating.lua StartChangeAppearance)
local stavCcams = {}
for _, slot in ipairs(Params.Slots) do stavCcams[slot.ccam] = true end

local function stripStav(visual)
	if not visual then return false end
	local els = {}
	local removed = false
	for _, el in ipairs(visual.Elements) do
		if stavCcams[tostring(el.Material)] then
			removed = true
		else
			els[#els + 1] = el
		end
	end
	if removed then visual.Elements = els end
	return removed
end

local function prepareMirror()
	local d = Ext.Entity.GetAllEntitiesWithComponent("ClientCCDummyDefinition")[1]
	if not d then return end
	_P("[STAV] dummy born elements", d.ClientCCDummyDefinition.Visual and #d.ClientCCDummyDefinition.Visual.Elements)
	local stripped = stripStav(d.ClientCCDummyDefinition.Visual)
	if d.ClientCCChangeAppearanceDefinition then
		stripped = stripStav(d.ClientCCChangeAppearanceDefinition.Definition.Visual) or stripped
	end
	if stripped then
		local ok = pcall(function() Ext.UI.GetRoot():Child(1):Child(1):Child(24):Child(1).StartCharacterCreation:Execute() end)
		_P("[STAV] nudge fired ok=", ok)
	end
end
]]

local function onDummyCreated()
	UI.Open()
	registerRebuildHook()
	--[[ nudge fallback — superseded by clean-path
	local char = _C()
	if char and char.Level and char.Level.LevelName ~= "SYS_CC_I" then
		Ext.Timer.WaitFor(100, prepareMirror)
	end
	]]
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

NetDefs.NET_APPLY_SYNC:SetHandler(function(data)
	if not data then return end
	Applying.ApplyLocalPreset(data.preset, data.characterUUID, data.state)
end)

NetDefs.NET_AVATAR_PING:SetHandler(function()
	local uuid = resolveCharacterUUID()
	if not uuid then return end
	local entity = Ext.Entity.Get(uuid)
	local look = entity and Vars.GetLook(entity)
	if look then
		for k, v in pairs(look) do
			if UI.State[k] ~= nil then UI.State[k] = v end
		end
		UI.RefreshWidgets()
	else
		sendLook(uuid)
	end
end)
