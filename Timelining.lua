local Vars     = Ext.Require("Shared/Vars.lua")
local Applying = Ext.Require("Client/Applying.lua")

local APPLY_DELAY = 300

local function findOwner(actor)
	for _, e in pairs(Ext.Entity.GetAllEntitiesWithComponent("TimelineActorData")) do
		if e.TimelineActorData.Actor == actor then return e end
	end
	return nil
end

local function apply(e)
	if not (e.Visual and e.Visual.Visual) then return end
	local tac = e.ClientTimelineActorControl
	if not tac then return end
	local owner = findOwner(tac.Actor)
	if not owner then return end
	local look = Vars.GetLook(owner)
	if not look then return end
	STAVDebug("Applying to %s (owner %s)", e.TLPreviewDummy.Name, owner.Uuid and owner.Uuid.EntityUuid or "?")
	Applying.ApplyLookToEntity(e, look)
end

local pending = false

local function flush()
	pending = false
	local dummies = Ext.Entity.GetAllEntitiesWithComponent("TLPreviewDummy")
	STAVDebug("Actors found:")
	for i, e in ipairs(dummies) do
		local d = e.TLPreviewDummy
		if d then
			local tac = e.ClientTimelineActorControl
			STAVDebug("  %d  %s  uuid=%s  actor=%s  vis=%s", i, d.Name,
				e.Uuid and e.Uuid.EntityUuid or "?",
				tac and tostring(tac.Actor) or "nil",
				(e.Visual and e.Visual.Visual) and "yes" or "no")
		end
	end
	for _, e in ipairs(dummies) do
		if e.TLPreviewDummy then apply(e) end
	end
end

Ext.Entity.OnCreateDeferred("TLPreviewDummy", function()
	if pending then return end
	pending = true
	Ext.Timer.WaitFor(APPLY_DELAY, flush)
end)
