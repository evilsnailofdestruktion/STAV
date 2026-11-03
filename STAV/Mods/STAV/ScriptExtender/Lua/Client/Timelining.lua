local Applying        = Ext.Require("Client/Applying.lua")
local Vars            = Ext.Require("Shared/Vars.lua")
local E               = Ext.Require("Shared/Events.lua")
local P               = Ext.Require("Shared/Printing.lua")

local T               = {}

local TL_RETRY_MS     = 333
local TL_MAX_TRIES    = 3
local KARLACH_GLOW    = "a1292048-0f09-89e2-2fd6-42d8afe3ef02"
local KARLACH_VFX     = "8a538ded-ae8c-edf1-5183-7249a3b242e7"
local KARLACH_ACTORS  = {
	["2bde0431-2532-49ee-befd-ff4517cbd91b"] = "CAMP_Karlach_CRD_ROM_Date",
	["811f62f2-5972-4612-97ec-7e8abfc5d62a"] = "CAMP_Karlach_SD_ROM_ForgingOfTheHeart",
	["c88bd127-d359-40a6-b73a-16a1879ccbb7"] = "END_GameFinale_DeathofKarlach",
	["16cf06d8-5a6f-40f7-9548-407cfdfb2c80"] = "EPI_Epilogue_Karlach",
	["26b59002-38c0-2867-3511-20d1d8184db6"] = "Karlach_InParty",
	["f212ec52-f798-4c35-b700-1a9b52f11bb7"] = "Karlach_InPartyEND"
}

---@type table
local ui              = nil
local blackColourMats = {}
---@type EntityHandle
local watched         = nil
local scene           = nil
local matched         = false
local tick            = nil

local function findTimelineOwner(actor)
	for _, e in pairs(Ext.Entity.GetAllEntitiesWithComponent("Origin")) do
		if e.TimelineActorData and e.TimelineActorData.Actor == actor then return e end
	end
end

local function hasParam(list, name)
	for _, p in pairs(list) do
		if p.ParameterName == name then return true end
	end
	return false
end

local function hasBlackColour(am)
	if not am.Material then return false end
	local name = am.MaterialName
	if blackColourMats[name] == nil then
		local params = am.Material.Parameters
		blackColourMats[name] = hasParam(params.Vector3Parameters, "BlackBody_Colour") and hasParam(params.ScalarParameters, "Colour_BlackBody")
	end
	return blackColourMats[name]
end

local function findVFX(renderable)
	for _, m in pairs(renderable.AppliedOverlayMaterials) do
		if m and m.MaterialName == KARLACH_VFX then return m end
	end
end

local function copyBlackColour(from, to)
	local colour, current = from:GetVector3("BlackBody_Colour"), to:GetVector3("BlackBody_Colour")
	if colour[1] ~= current[1] or colour[2] ~= current[2] or colour[3] ~= current[3] then
		to:SetVector3("BlackBody_Colour", colour)
	end
	local weight = from:GetScalar("Colour_BlackBody")
	if weight ~= to:GetScalar("Colour_BlackBody") then to:SetScalar("Colour_BlackBody", weight) end
end

local function UpdateKarlach()
	if not watched:IsAlive() then
		if not matched then P.Debug():Raw("TL "):C21(scene):Raw(": Karlach's glow never matched."):Print() end
		E.Tick.Unsubscribe(tick)
		tick = nil
		return
	end
	local visual = watched.Visual and watched.Visual.Visual
	if not visual then return end
	for _, att in pairs(visual.Attachments) do
		if att.Visual and att.Visual.VisualResource and att.Visual.VisualResource.Guid == KARLACH_GLOW then
			for _, desc in pairs(att.Visual.ObjectDescs) do
				local body = desc.Renderable and desc.Renderable.ActiveMaterial
				local vfx = body and findVFX(desc.Renderable)
				if vfx and hasBlackColour(body) and hasBlackColour(vfx) then
					matched = true
					copyBlackColour(vfx, body)
				end
			end
		end
	end
end

local function WatchKarlach(e)
	if tick then return end
	local tac = e.ClientTimelineActorControl
	local name = tac and KARLACH_ACTORS[tac.Actor]
	if not name then return end
	watched, scene, matched = e, name, false
	tick = E.Tick.Subscribe(UpdateKarlach)
end

local function ApplyTimelineLook(e)
	local tac = e.ClientTimelineActorControl
	if not tac then return end
	local owner = findTimelineOwner(tac.Actor)
	local look = owner and Vars.GetLook(owner)
	if not look then
		local own = Applying.resolveCharacter()
		if own and e.TLPreviewDummy.OriginalCharacterTemplate == own.GameObjectVisual.RootTemplateId then
			look = Vars.GetLook(own)
			if not look and ui.Changed then look = ui.State end
		end
	end
	if not look then return end
	P.Debug():Raw("TL "):C21(e.TLPreviewDummy.Name):Raw(": applying ("):C21(owner and "owner" or "self"):Raw(")."):Print()
	Applying.ApplyLookToEntity(e, look)
end

local function ApplyWhenReady(e)
	local tries = 0
	local function attempt()
		tries = tries + 1
		if e.Visual and e.Visual.Visual then
			ApplyTimelineLook(e)
			WatchKarlach(e)
		elseif tries < TL_MAX_TRIES then
			Ext.Timer.WaitFor(TL_RETRY_MS, attempt)
		end
	end
	Ext.Timer.WaitFor(TL_RETRY_MS, attempt)
end

function T.ApplyToTimelineDummies()
	for _, e in pairs(Ext.Entity.GetAllEntitiesWithComponent("TLPreviewDummy")) do
		local tl = e.TLPreviewDummy
		if tl and tl.OriginalCharacterTemplate ~= "" then ApplyWhenReady(e) end
	end
end

function T.SetUI(panel)
	ui = panel
end

E.TLPreviewDummyCreated.Subscribe(function(p)
	if p.Entity.TLPreviewDummy.OriginalCharacterTemplate == "" then return end
	ApplyWhenReady(p.Entity)
end)

return T
