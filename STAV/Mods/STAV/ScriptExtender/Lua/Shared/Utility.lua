local U = {}

function U.IsGuid(value)
	if type(value) ~= "string" then
		return false
	end
	return value:match("^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$") ~= nil
end

U.NULL_UUID = "00000000-0000-0000-0000-000000000000"

function U.Guid(uuid)
	return uuid:sub(-36)
end

function U.GetEntity(raw)
	return Ext.Entity.Get(raw:sub(-36))
end

function U.GetObject(entity)
	if entity.ServerCharacter then return entity.ServerCharacter end
	if entity.ServerItem then return entity.ServerItem.Item end
end

function U.GetPartyMembers()
	local members = {}
	for _, row in pairs(Osi.DB_Players:Get(nil)) do
		local guid   = U.Guid(row[1])
		local entity = Ext.Entity.Get(guid)
		if entity then
			members[#members + 1] = { Guid = guid, Entity = entity }
		end
	end
	return members
end

function U.ScanInventory(entity, visit)
	if not entity.InventoryOwner then return end
	for _, entry in pairs(entity.InventoryOwner.PrimaryInventory.InventoryContainer.Items) do
		visit(entry.Item)
		if entry.Item.InventoryOwner then U.ScanInventory(entry.Item, visit) end
	end
end

function U.ResolveDisplayName(handle, fallback)
	local translated = Ext.Loca.GetTranslatedString(handle, fallback)
	return (translated ~= "" and translated ~= handle) and translated or fallback
end

function U.GetDisplayName(uuid, fallback)
	local handle = Osi.GetDisplayName(uuid)
	return U.ResolveDisplayName(handle, fallback or uuid)
end

function U.GetStatusDuration(target, statusId)
	local entity = Ext.Entity.Get(target)
	if not entity or not entity.ServerCharacter then return nil end
	for _, s in pairs(entity.ServerCharacter.StatusManager.Statuses) do
		if s.StatusId == statusId then return math.floor(s.CurrentLifeTime) end
	end
	return nil
end

function U.Timer(n, callback)
	n = (n or 13) * 1000
	local startTime = Ext.Timer.MonotonicTime()
	local eventId
	eventId = Ext.Events.Tick:Subscribe(function()
		if Ext.Timer.MonotonicTime() - startTime >= n then
			if callback then callback() end
			Ext.Events.Tick:Unsubscribe(eventId)
		end
	end)
	return eventId, function()
		return Ext.Timer.MonotonicTime()
	end
end

return U
