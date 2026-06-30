local E = Ext.Require("Shared/Events.lua")
local U = Ext.Require("Shared/Utility.lua")
local C = Ext.Require("Shared/Constantine.lua")

local REAL_TEMPLATES = {}

local function findTempl()
	if next(REAL_TEMPLATES) ~= nil then return end
	for _, tier in ipairs(C.Tiers) do
		for _, rt in ipairs(C.RealTemplates(tier)) do
			REAL_TEMPLATES[rt] = tier
		end
	end
end

local function countOf(tier)
	local players = Osi.DB_Players:Get(nil)[1]
	if not players then return 0 end
	local total = 0
	for _, rt in ipairs(C.RealTemplates(tier)) do
		total = total + Osi.TemplateIsInPartyInventory(rt, players[1], 0) --[[@as integer]]
	end
	return total
end

local function scanParty()
	local members = {}
	for _, pm in ipairs(U.GetPartyMembers()) do
		members[pm.Guid] = C.GetProxies(pm.Entity)
	end
	return members
end

-- Last scan, keyed by member guid → tier.stat → { proxy uuids }. Rebuilt by
-- CheckWyeFey, read by syncStacks (proxies only change through events that
-- trigger a fresh check, so it stays accurate between checks).
local byMember = {}

-- Need to defer sync after CastedSpell for items that use it
local pendingProxyUse = {}

-- Timer needed to prevent SetStackAmount from overruling SetCanInteract(0)
local function setLock(toLock)
	if #toLock == 0 then return end
	Ext.Timer.WaitFor(33, function()
		for _, uuid in ipairs(toLock) do
			Osi.SetCanInteract(uuid, 0)
		end
	end)
end

local function syncStacks(tiers)
	local toLock = {}
	for _, t in ipairs(tiers or C.Tiers) do
		local c = countOf(t)
		for _, into in pairs(byMember) do
			for _, uuid in ipairs(into[t.stat]) do
				Osi.SetStackAmount(uuid, math.max(1, c))
				if c == 0 then toLock[#toLock + 1] = uuid end
			end
		end
	end
	setLock(toLock)
end

-- One proxy per member per tier. Re-add to anyone at zero, trim anyone above one.
-- The re-add/trim each fire their own add/remove event, which queues a follow-up
-- check that re-scans and settles the displayed number.
local function CheckWyeFey(tiers)
	byMember = scanParty()
	for guid, into in pairs(byMember) do
		for _, t in ipairs(tiers or C.Tiers) do
			local list = into[t.stat]
			local n    = #list
			if n == 0 then
				Osi.TemplateAddTo(t.template, guid, math.max(1, countOf(t)), 1)
			elseif n > 1 then
				for i = 2, n do Osi.RequestDelete(list[i]) end
				into[t.stat] = { list[1] }
			end
		end
	end
	syncStacks(tiers)
end

-- Tier-aware debounce: collapses a burst into one flush on the next frame.
-- Each dirtied tier carries a `check` flag — proxy changes need a full check,
-- real-potion changes only need a stack sync.
local pending = {}
local queued  = false

local function flush()
	local job        = pending
	pending, queued  = {}, false
	local checkTiers = {}
	local syncTiers  = {}
	for _, e in pairs(job) do
		if e.check then
			checkTiers[#checkTiers + 1] = e.tier
		else
			syncTiers[#syncTiers + 1] = e.tier
		end
	end
	if #checkTiers > 0 then CheckWyeFey(checkTiers) end
	if #syncTiers > 0 then syncStacks(syncTiers) end
end

local function mark(tier, check)
	local e = pending[tier.stat]
	if e then
		e.check = e.check or check
	else
		pending[tier.stat] = { tier = tier, check = check }
	end
	if not queued then
		queued = true
		Ext.Timer.WaitFor(33, flush)
	end
end

local function queueCheck(tier)
	if tier == nil then
		for _, t in ipairs(C.Tiers) do mark(t, true) end
	else
		mark(tier, true)
	end
end

local function queueSync(tier)
	mark(tier, false)
end

local function onTemplateChanged(p)
	local tier = C.TierByTemplate[p.Template]
	if tier then
		if Osi.IsPartyMember(p.HolderGuid, 0) == 1 then
			queueCheck(tier)
		end
		return
	end
	tier = REAL_TEMPLATES[p.Template]
	if tier and Osi.IsPartyMember(p.HolderGuid, 0) == 1 then
		queueSync(tier)
	end
end

local function Consume(tier)
	local anchor = Osi.DB_Players:Get(nil)[1][1]
	for _, rt in ipairs(C.RealTemplates(tier)) do
		local one = Osi.GetItemByTemplateInPartyInventory(rt, anchor)
		if one then
			local amt = Osi.GetStackAmount(one)
			if amt > 1 then
				Osi.SetStackAmount(one, amt - 1)
			else
				Osi.RequestDelete(one)
				-- RequestDelete settles after the 33ms sync, so the count would read one
				-- too high; a later sync catches the settled value. Only this branch needs it.
				Ext.Timer.WaitFor(100, function() queueSync(tier) end)
			end
			break
		end
	end
	queueSync(tier)
end

local function Init()
	local version = table.concat(Ext.Mod.GetMod(ModuleUUID).Info.ModVersion, ".")
	NZWFPrint():GradC(15, 20):G("/// Wye Fey Potions "):C17("v" .. version):G(" loaded"):Print()
end

E.SessionLoaded.Subscribe(Init)

E.ResetCompleted.Subscribe(function()
	findTempl()
	queueCheck(nil)
end)

E.LevelGameplayStarted.Subscribe(function(p)
	if p.LevelName == "SYS_CC_I" then return end
	findTempl()
	queueCheck(nil)
end)

E.CharacterJoinedParty.Subscribe(function(p)
	if Osi.GetRegion(p.CharacterRaw) == "SYS_CC_I" then return end		-- Why are you firing in CC?
	findTempl()
	queueCheck(nil)
end)

E.CharacterLeftParty.Subscribe(function() queueCheck(nil) end)

E.TemplateUseStarted.Subscribe(function(p)
	local tier = C.TierByTemplate[p.Template]
	if tier then
		if tier.useSpell then
			pendingProxyUse[p.CharacterGuid] = tier
		else
			Consume(tier)
		end
		return
	end
	tier = REAL_TEMPLATES[p.Template]
	if tier and Osi.IsPartyMember(p.CharacterGuid, 0) == 1 then
		if tier.useSpell then
			pendingProxyUse[p.CharacterGuid] = nil
		else
			queueSync(tier)
		end
	end
end)

E.TemplateAddedTo.Subscribe(onTemplateChanged)
E.TemplateRemovedFrom.Subscribe(onTemplateChanged)

E.OnThrown.Subscribe(function(p)
	local tier = C.TierByTemplate[p.Template]
	if tier and Osi.IsPartyMember(p.ThrowerGuid, 1) == 1 then
		Consume(tier)
		return
	end
	tier = REAL_TEMPLATES[p.Template]
	if tier and Osi.IsPartyMember(p.ThrowerGuid, 1) == 1 then
		queueSync(tier)
	end
end)

E.CastedSpell.Subscribe(function(p)
	local tier = C.TierBySpell[p.SpellId]
	if not tier or Osi.IsPartyMember(p.CasterGuid, 0) ~= 1 then return end
	if pendingProxyUse[p.CasterGuid] == tier then
		pendingProxyUse[p.CasterGuid] = nil
		Consume(tier)
	else
		queueSync(tier)
	end
end)
