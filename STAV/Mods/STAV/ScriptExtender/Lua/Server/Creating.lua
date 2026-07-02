local E       = Ext.Require("Shared/Events.lua")
local NetDefs = Ext.Require("Shared/NetDefs.lua")
local Vars    = Ext.Require("Shared/Vars.lua")
local Params  = Ext.Require("Shared/Params.lua")

local function commitLook(charUUID)
	if not charUUID or not Vars.LatestLook then return end
	local entity = Ext.Entity.Get(charUUID)
	if not entity then return end
	Vars.SetLook(entity, Vars.LatestLook)
end

-- 8 CCAM slots — one claimed per character (CCAM uuid → preset uuid)
local SLOTS = {
	{ ccam = "fffa139e-2b12-4175-83ab-a15eb18d486c", preset = "f3a16e69-b757-4676-af7b-e922ef30b042" },
	{ ccam = "33346ac5-5dc6-497e-8fd5-77e26515c693", preset = "148e52a9-abac-4173-d752-f81cafd4a27e" },
	{ ccam = "9e05a569-54dc-43b9-bff0-8c8bfd4a7b96", preset = "531e5a3a-1331-33b3-40bf-61d48c798c42" },
	{ ccam = "a1b02643-f542-4e62-b948-b20d4351af44", preset = "b5f41781-ac6d-20e8-5e71-c336e57116b3" },
	{ ccam = "6d1f64bd-2fb1-4b1b-89c1-554516a03eea", preset = "b60e6d34-21a4-b43b-8d02-7b539e619e7e" },
	{ ccam = "348fa226-e411-43a0-ba82-ddf938ffedf3", preset = "4ceb7da5-7d2d-7e5a-3e87-bebdf0ecee50" },
	{ ccam = "f666eb8c-c2a6-469f-aaea-482d0ed5d63f", preset = "43b63d89-865f-ae15-1723-192d92ac0fc2" },
	{ ccam = "0348b311-c3b8-44c9-81ba-d22859f3a8ff", preset = "95bad513-7f5b-344f-f052-5d3b56e72f1e" },
}

-- charUUID → slot index (1-8); persists across CC→game boundary in VM
local slotMap = {}
local usedSlots = {}

local function claimSlot(charUUID)
	if slotMap[charUUID] then return slotMap[charUUID] end
	for i = 1, #SLOTS do
		if not usedSlots[i] then
			usedSlots[i]      = charUUID
			slotMap[charUUID] = i
			return i
		end
	end
	return nil
end

local function applyPreset(presetUUID, look)
	local preset = Ext.Resource.Get(presetUUID, "MaterialPreset")
	if not preset then return end
	for key, p in pairs(Params) do
		local v = look[key]
		if v ~= nil then
			local mapped = p.map(v)
			if p.kind == "scalar" then
				for _, entry in pairs(preset.Presets.ScalarParameters) do
					if entry.Parameter == p.name then entry.Value = mapped end
				end
			else
				for _, entry in pairs(preset.Presets.Vector3Parameters) do
					if entry.Parameter == p.name then
						entry.Value = { mapped[1], mapped[2], mapped[3] }
					end
				end
			end
		end
	end
end

local function ensureElement(entity, ccamUUID)
	local cca  = entity.CharacterCreationAppearance
	if not cca then return false end
	local els  = {}
	local found = false
	for _, el in pairs(cca.Elements) do
		els[#els + 1] = el
		if el.Material == ccamUUID then found = true end
	end
	if not found then
		els[#els + 1] = { Material = ccamUUID }
	end
	cca.Elements = els
	return true
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
	local slot = SLOTS[slotIdx]

	applyPreset(slot.preset, look)
	if ensureElement(entity, slot.ccam) then
		entity:Replicate("CharacterCreationAppearance")
	end
end

local function broadcastCCState(open)
	NetDefs.NET_CC_STATE:Broadcast(Ext.Json.Stringify(open))
end

E.CharacterCreationStarted.Subscribe(function()
	broadcastCCState(true)
end)

E.CharacterCreationFinished.Subscribe(function()
	commitLook(Osi.GetHostCharacter())
	broadcastCCState(false)
end)

E.StartChangeAppearance.Subscribe(function()
	broadcastCCState(true)
end)

E.ChangeAppearanceCompleted.Subscribe(function(p)
	commitLook(p.CharacterGuid)
	applyToCharacter(p.CharacterGuid)
	broadcastCCState(false)
end)

E.ChangeAppearanceCancelled.Subscribe(function()
	broadcastCCState(false)
end)

E.LevelGameplayStarted.Subscribe(function()
	Ext.Timer.WaitFor(33, function()
		applyToCharacter(Osi.GetHostCharacter())
	end)
end)
