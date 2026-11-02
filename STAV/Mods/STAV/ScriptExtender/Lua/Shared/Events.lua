local U = Ext.Require("Shared/Utility.lua")
local E = {}

---@param ... EntityHandle?
---@return EntityHandle[]
local function subjects(...)
	local t = {}
	for i = 1, select('#', ...) do
		local e = select(i, ...)
		if e then t[#t + 1] = e end
	end
	return t
end

---@class EventSubject
---@field Raw string
---@field Guid Guid
---@field Entity EntityHandle?
---@param raw string
---@return EventSubject
local function toSubject(raw)
	return { Raw = raw, Guid = U.Guid(raw), Entity = Ext.Entity.Get(raw) }
end

local function wants(cb, p)
	if not cb.entity then return true end
	for _, s in ipairs(p.Subjects) do
		if s == cb.entity then return true end
	end
	return false
end

---@class EventOptions
---@field Priority? integer
---@field Entity? EntityHandle

---@class Event<T>
---@field Subscribe fun(fn: fun(p: T), opts?: EventOptions): integer
---@field Unsubscribe fun(id: integer)

---@generic T: EventParams
---@param makeRegister fun(fire: function): fun()
---@param makeParams? fun(...): T
---@return Event<T>
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

	local function remove(id)
		callbacks[id] = nil
		dirty         = true
		if unregister and not next(callbacks) then
			unregister(); unregister = nil
		end
	end

	local function fire(...)
		if dirty then rebuild() end
		if not makeParams then
			for _, cb in ipairs(sorted) do
				if callbacks[cb.id] then cb.fn(...) end
			end
			return
		end
		local p       = makeParams(...)
		local stopped = false
		p.StopPropagation = function() stopped = true end
		for _, cb in ipairs(sorted) do
			if callbacks[cb.id] and wants(cb, p) then
				p.Unsubscribe = cb.unsubscribe
				cb.fn(p)
				if stopped then break end
			end
		end
	end

	local function ensure()
		if not unregister then unregister = makeRegister(fire) end
	end

	return {
		Subscribe = function(fn, opts)
			if opts and opts.Entity and not makeParams then
				error("Entity filter needs an event with a params builder", 2)
			end
			ensure()
			local id      = nextId; nextId = nextId + 1
			callbacks[id] = {
				id          = id,
				fn          = fn,
				priority    = (opts and opts.Priority) or 100,
				entity      = opts and opts.Entity,
				unsubscribe = function() remove(id) end
			}
			dirty         = true
			return id
		end,
		Unsubscribe = remove
	}
end

---@param name string
---@param arity integer
---@param timing "before"|"after"
---@return fun(fire: function): fun()
local function OsirisEvent(name, arity, timing)
	return function(f)
		local id = Ext.Osiris.RegisterListener(name, arity, timing, f)
		return function() Ext.Osiris.UnregisterListener(id) end
	end
end

---@param seEvent SubscribableEvent<any>
---@return fun(fire: function): fun()
local function ExtEvent(seEvent)
	return function(f)
		local h = seEvent:Subscribe(f)
		return function() seEvent:Unsubscribe(h) end
	end
end

---@param subscribe function
---@return fun(target: string): fun(fire: function): fun()
local function EcsEvent(subscribe)
	return function(target)
		return function(f)
			local id = subscribe(target, f) --[[@as uint64]]
			return function() Ext.Entity.Unsubscribe(id) end
		end
	end
end

local EcsCreateDeferredEvent  = EcsEvent(Ext.Entity.OnCreateDeferred)
local EcsDestroyDeferredEvent = EcsEvent(Ext.Entity.OnDestroyDeferred)
local EcsSystemEvent          = EcsEvent(Ext.Entity.OnSystemUpdate)

---@class EventParams
---@field Subjects EntityHandle[]
---@field StopPropagation fun()
---@field Unsubscribe fun()

---@class EventEntityParams: EventParams
---@field Entity EntityHandle
---@return EventEntityParams
local function entityParams(entity)
	return { Entity = entity, Subjects = subjects(entity) }
end

---@class EventCharParams: EventParams
---@field Character EventSubject
---@return EventCharParams
local function charParams(char)
	local c = toSubject(char)
	return { Character = c, Subjects = subjects(c.Entity) }
end

---@class EventLevelParams: EventParams
---@field LevelName string
---@field IsEditor boolean
---@return EventLevelParams
local function levelParams(levelName, isEditorMode)
	return { LevelName = levelName, IsEditor = isEditorMode == 1, Subjects = {} }
end

---@class EventPhotoDummyParams: EventParams
---@field Character EntityHandle
---@field Carrier EntityHandle
---@return EventPhotoDummyParams
local function photoDummyParams(entity)
	local c = entity.PhotoModeDummy.Entity
	return { Character = c, Carrier = entity, Subjects = subjects(c) }
end

---@class EventCCDummyParams: EventParams
---@field Dummy EntityHandle
---@field Carrier EntityHandle
---@return EventCCDummyParams
local function ccDummyParams(entity)
	local d = entity.ClientCCDummyDefinition.Dummy
	return { Dummy = d, Carrier = entity, Subjects = subjects(d) }
end

if Ext.IsServer() then
	-- Appearance
	E.ChangeAppearanceCancelled   = Event(OsirisEvent("ChangeAppearanceCancelled", 1, "after"), charParams)
	E.ChangeAppearanceCompleted   = Event(OsirisEvent("ChangeAppearanceCompleted", 1, "after"), charParams)
	E.StartChangeAppearance       = Event(OsirisEvent("StartChangeAppearance", 1, "after"), charParams)
	-- Session
	E.LevelGameplayStarted        = Event(OsirisEvent("LevelGameplayStarted", 2, "after"), levelParams)
end

if Ext.IsClient() then
	E.CCDummyCreated          = Event(EcsCreateDeferredEvent("ClientCCDummyDefinition"), ccDummyParams)
	E.CCDummyDestroyed        = Event(EcsDestroyDeferredEvent("ClientCCDummyDefinition"), entityParams)
	E.ClientControlCreated    = Event(EcsCreateDeferredEvent("ClientControl"), entityParams)
	E.EquipmentVisualsUpdate  = Event(EcsSystemEvent("ClientEquipmentVisuals"))
	E.PhotoModeDummyCreated   = Event(EcsCreateDeferredEvent("PhotoModeDummy"), photoDummyParams)
	E.PhotoModeDummyDestroyed = Event(EcsDestroyDeferredEvent("PhotoModeDummy"), entityParams)
	E.TLPreviewDummyCreated   = Event(EcsCreateDeferredEvent("TLPreviewDummy"), entityParams)
end

E.StatsLoaded			= Event(ExtEvent(Ext.Events.StatsLoaded))
E.GameStateChanged	= Event(ExtEvent(Ext.Events.GameStateChanged))

return E
