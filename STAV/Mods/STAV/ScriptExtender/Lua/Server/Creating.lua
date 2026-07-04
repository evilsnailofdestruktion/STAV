local E       = Ext.Require("Shared/Events.lua")
local U       = Ext.Require("Shared/Utility.lua")
local NetDefs = Ext.Require("Shared/NetDefs.lua")
local Vars    = Ext.Require("Shared/Vars.lua")
local Params  = Ext.Require("Shared/Params.lua")

local C = {}

local slotMap   = {}
local usedSlots = {}

local stavCcams = {}
for _, slot in ipairs(Params.Slots) do stavCcams[slot.ccam] = true end
for _, ccam in pairs(Params.Toggles) do stavCcams[ccam] = true end

local function claimSlot(charUUID)
	if slotMap[charUUID] then return slotMap[charUUID] end
	for i = 1, #Params.Slots do
		if not usedSlots[i] then
			usedSlots[i]      = charUUID
			slotMap[charUUID] = i
			return i
		end
	end
	return nil
end

local function applyElements(entity, tattooCcam, look)
	local cca = entity.CharacterCreationAppearance
	if not cca then return false end
	local els        = {}
	local haveTattoo = false
	for _, el in ipairs(cca.Elements) do
		local m = tostring(el.Material)
		if m == tattooCcam then
			haveTattoo = true
			els[#els + 1] = el
		elseif not stavCcams[m] then
			els[#els + 1] = el
		end
	end
	if not haveTattoo then
		els[#els + 1] = { Material = tattooCcam }
	end
	for key, ccam in pairs(Params.Toggles) do
		if look[key] then
			els[#els + 1] = { Material = ccam }
		end
	end
	cca.Elements = els
	return true
end

local function stripFromReal(charUUID)
	local entity = charUUID and Ext.Entity.Get(charUUID)
	if not entity then return end
	local cca = entity.CharacterCreationAppearance
	if not cca then return end
	local els = {}
	local removed = false
	for _, el in ipairs(cca.Elements) do
		if stavCcams[tostring(el.Material)] then
			removed = true
		else
			els[#els + 1] = el
		end
	end
	if removed then
		cca.Elements = els
		entity:Replicate("CharacterCreationAppearance")
	end
end

local function applyToCharacter(charUUID)
	if not charUUID then return end
	local entity = Ext.Entity.Get(charUUID)
	if not entity then return end
	local look = Vars.GetLook(entity)
	if not look then return end

	local slotIdx = claimSlot(charUUID)
	if not slotIdx then
		STAVDebug("No free STAV slot for %s", charUUID)
		return
	end
	local slot = Params.Slots[slotIdx]

	if applyElements(entity, slot.ccam, look) then
		entity:Replicate("CharacterCreationAppearance")
		NetDefs.NET_APPLY_SYNC:Broadcast({
			characterUUID = charUUID,
			preset        = slot.preset,
			state         = look,
		})
	end
end
C.ApplyToCharacter = applyToCharacter

E.StartChangeAppearance.Subscribe(function(p)
	stripFromReal(p.CharacterGuid)
end)

E.ChangeAppearanceCompleted.Subscribe(function(p)
	applyToCharacter(p.CharacterGuid)
end)

E.ChangeAppearanceCancelled.Subscribe(function(p)
	applyToCharacter(p.CharacterGuid)
end)

-- On level load: ping clients (first-CC clients resend their in-memory look once their
-- avatar resolves) and re-apply any persisted look per avatar (reload case).
local didInitialApply = false

E.LevelGameplayStarted.Subscribe(function()
	Ext.Timer.WaitFor(33, function()
		NetDefs.NET_AVATAR_PING:Broadcast({})
		if didInitialApply then return end
		didInitialApply = true
		local players = Osi.DB_Players:Get(nil)
		if players then
			for _, row in ipairs(players) do
				applyToCharacter(U.Guid(row[1]))
			end
		end
	end)
end)

return C
