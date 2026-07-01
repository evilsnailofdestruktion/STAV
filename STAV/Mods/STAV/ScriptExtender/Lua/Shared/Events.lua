local U = Ext.Require("Shared/Utility.lua")
local E = {}

local function subjects(...)
	local t = {}
	for i = 1, select('#', ...) do
		local e = select(i, ...)
		if e then t[#t + 1] = e end
	end
	return t
end

local function isMatch(id)
	return function(...)
		for _, s in ipairs({ ... }) do if s == id then return true end end
		return false
	end
end

local function Event(makeRegister, makeParams)
	local callbacks  = {}
	local nextId     = 1
	local unregister = nil
	local dirty      = true
	local sorted     = {}

	local function rebuild()
		sorted = {}
		for _, cb in pairs(callbacks) do sorted[#sorted + 1] = cb end
		table.sort(sorted, function(a, b) return a.priority > b.priority end)
		dirty = false
	end

	local function unsubscribe(id)
		callbacks[id] = nil
		dirty         = true
		if unregister and not next(callbacks) then
			unregister(); unregister = nil
		end
	end

	local function fire(...)
		if dirty then rebuild() end
		if makeParams then
			local p           = makeParams(...)
			p._stopped        = false
			p.StopPropagation = function() p._stopped = true end
			for _, cb in ipairs(sorted) do
				if not callbacks[cb.id] then goto continue end
				if cb.entity then
					local match = false
					for _, s in ipairs(p.Subjects) do
						if s == cb.entity then match = true; break end
					end
					if not match then goto continue end
				end
				p.Unsubscribe = function() unsubscribe(cb.id) end
				cb.fn(p)
				if p._stopped then break end
				::continue::
			end
		else
			for _, cb in ipairs(sorted) do
				if callbacks[cb.id] then cb.fn(...) end
			end
		end
	end

	local function ensure()
		if not unregister then unregister = makeRegister(fire) end
	end

	return {
		Subscribe = function(fn, opts)
			ensure()
			local id      = nextId; nextId = nextId + 1
			callbacks[id] = { id = id, fn = fn, priority = (opts and opts.Priority) or 100, entity = opts and opts.Entity }
			dirty         = true
			return id
		end,
		Unsubscribe = function(id) unsubscribe(id) end,
	}
end

local function OsirisEvent(name, arity, timing)
	return function(f)
		local id = Ext.Osiris.RegisterListener(name, arity, timing, f)
		return function() Ext.Osiris.UnregisterListener(id) end
	end
end

local function ExtEvent(seEvent)
	return function(f)
		local h = seEvent:Subscribe(f)
		return function() seEvent:Unsubscribe(h) end
	end
end

local function OnCreateEvent(componentName)
	return function(f)
		local h = Ext.Entity.OnCreate(componentName, f)
		return function() Ext.Entity.Unsubscribe(h) end
	end
end

local function charParams(char)
	local e = U.GetEntity(char)
	return {
		CharacterRaw  = char,
		CharacterGuid = U.Guid(char),
		Character     = e,
		Subjects      = subjects(e),
	}
end

local function spellParams(caster, spell)
	local e = U.GetEntity(caster)
	return {
		CasterRaw  = caster,
		CasterGuid = U.Guid(caster),
		Caster     = e,
		SpellId    = spell,
		IsSpell    = isMatch(spell),
		Subjects   = subjects(e),
	}
end

local function levelParams(levelName, _)
	return { LevelName = levelName, Subjects = {} }
end

local function statusParams(object, statusId, causee, storyActionId)
	local obj   = U.GetEntity(object)
	local cause = U.GetEntity(causee)
	return {
		ObjectRaw     = object,
		ObjectGuid    = U.Guid(object),
		Object        = obj,
		StatusId      = statusId,
		CauseeRaw     = causee,
		CauseeGuid    = U.Guid(causee),
		Causee        = cause,
		StoryActionId = storyActionId,
		HasCausee     = cause ~= nil,
		IsStatus      = isMatch(statusId),
		Subjects      = subjects(obj, cause),
	}
end

local function statusAppliedFastParams(entity)
	local comp = entity.ServerStatusApplyEvent
	local obj  = comp.Target
	local sid  = comp.StatusId
	return {
		ObjectGuid = obj.Uuid.EntityUuid,
		Object     = obj,
		StatusId   = sid,
		Status     = comp.Status,
		IsStatus   = isMatch(sid),
		Subjects   = subjects(obj),
	}
end

local function statusRemovedFastParams(entity)
	local comp = entity.ServerStatusRemoveEvent
	local obj  = comp.Target
	local sid  = comp.StatusId
	return {
		ObjectGuid    = obj.Uuid.EntityUuid,
		Object        = obj,
		StatusId      = sid,
		Source        = comp.Source,
		StoryActionId = comp.StoryActionId,
		IsDeleting    = comp.IsDeleting,
		IsFromItem    = comp.IsFromItem,
		IsStatus      = isMatch(sid),
		Subjects      = subjects(obj),
	}
end

local function templateUseParams(character, template, item)
	local e = U.GetEntity(character)
	return {
		CharacterRaw  = character,
		CharacterGuid = U.Guid(character),
		Character     = e,
		Template      = U.Guid(template),
		ItemGuid      = U.Guid(item),
		Subjects      = subjects(e),
	}
end

local function templateAddedParams(root, item, holder, addType)
	local e = U.GetEntity(holder)
	return {
		Template   = U.Guid(root),
		ItemGuid   = U.Guid(item),
		HolderRaw  = holder,
		HolderGuid = U.Guid(holder),
		Holder     = e,
		AddType    = addType,
		Subjects   = subjects(e),
	}
end

local function templateRemovedParams(root, item, holder)
	local e = U.GetEntity(holder)
	return {
		Template   = U.Guid(root),
		ItemGuid   = U.Guid(item),
		HolderRaw  = holder,
		HolderGuid = U.Guid(holder),
		Holder     = e,
		Subjects   = subjects(e),
	}
end

local function thrownParams(thrownObject, thrownTemplate, thrower, storyActionId, x, y, z)
	local e = U.GetEntity(thrower)
	return {
		ThrownObjectGuid = U.Guid(thrownObject),
		Template         = U.Guid(thrownTemplate),
		ThrowerRaw       = thrower,
		ThrowerGuid      = U.Guid(thrower),
		Thrower          = e,
		StoryActionId    = storyActionId,
		X                = x,
		Y                = y,
		Z                = z,
		Subjects         = subjects(e),
	}
end

if Ext.IsServer() then
	-- Session
	E.LevelGameplayStarted = Event(OsirisEvent("LevelGameplayStarted", 2, "after"), levelParams)
	-- Character
	E.CharacterJoinedParty = Event(OsirisEvent("CharacterJoinedParty", 1, "after"), charParams)
	E.CharacterLeftParty   = Event(OsirisEvent("CharacterLeftParty", 1, "after"), charParams)
	E.Died                 = Event(OsirisEvent("Died", 1, "after"), charParams)
	E.LeveledUp            = Event(OsirisEvent("LeveledUp", 1, "after"), charParams)
	-- Combat
	E.TurnStarted          = Event(OsirisEvent("TurnStarted", 1, "after"), charParams)
	E.TurnEnded            = Event(OsirisEvent("TurnEnded", 1, "after"), charParams)
	E.CastedSpell          = Event(OsirisEvent("CastedSpell", 5, "after"), spellParams)
	-- Status
	E.StatusApplied        = Event(OsirisEvent("StatusApplied", 4, "after"), statusParams)
	E.StatusRemoved        = Event(OsirisEvent("StatusRemoved", 4, "after"), statusParams)
	E.StatusAttempt        = Event(OsirisEvent("StatusAttempt", 4, "before"), statusParams)
	E.StatusAppliedFast    = Event(OnCreateEvent("ServerStatusApplyEvent"), statusAppliedFastParams)
	E.StatusRemovedFast    = Event(OnCreateEvent("ServerStatusRemoveEvent"), statusRemovedFastParams)
	-- Items
	E.TemplateUseStarted   = Event(OsirisEvent("TemplateUseStarted", 3, "after"), templateUseParams)
	E.TemplateAddedTo      = Event(OsirisEvent("TemplateAddedTo", 4, "after"), templateAddedParams)
	E.TemplateRemovedFrom  = Event(OsirisEvent("TemplateRemovedFrom", 3, "after"), templateRemovedParams)
	E.OnThrown             = Event(OsirisEvent("OnThrown", 7, "after"), thrownParams)
end

E.StatsLoaded    = Event(ExtEvent(Ext.Events.StatsLoaded))
E.ResetCompleted = Event(ExtEvent(Ext.Events.ResetCompleted))
E.SessionLoaded  = Event(ExtEvent(Ext.Events.SessionLoaded))

return E
