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

local function charParams(char)
	local e = U.GetEntity(char)
	return {
		CharacterRaw  = char,
		CharacterGuid = U.Guid(char),
		Character     = e,
		Subjects      = subjects(e),
	}
end

local function levelParams(levelName, _)
	return { LevelName = levelName, Subjects = {} }
end

local function ccParams()
	return { Subjects = {} }
end

if Ext.IsServer() then
	E.LevelGameplayStarted      = Event(OsirisEvent("LevelGameplayStarted", 2, "after"), levelParams)
	E.LeveledUp                 = Event(OsirisEvent("LeveledUp", 1, "after"), charParams)
	E.CharacterCreationStarted  = Event(OsirisEvent("CharacterCreationStarted", 0, "after"), ccParams)
	E.CharacterCreationFinished = Event(OsirisEvent("CharacterCreationFinished", 0, "after"), ccParams)
	E.StartChangeAppearance     = Event(OsirisEvent("StartChangeAppearance", 1, "after"), charParams)
	E.ChangeAppearanceCompleted = Event(OsirisEvent("ChangeAppearanceCompleted", 1, "after"), charParams)
	E.ChangeAppearanceCancelled = Event(OsirisEvent("ChangeAppearanceCancelled", 1, "after"), charParams)
end

E.SessionLoaded  = Event(ExtEvent(Ext.Events.SessionLoaded))
E.ResetCompleted = Event(ExtEvent(Ext.Events.ResetCompleted))
E.StatsLoaded	  = Event(ExtEvent(Ext.Events.StatsLoaded))

return E
