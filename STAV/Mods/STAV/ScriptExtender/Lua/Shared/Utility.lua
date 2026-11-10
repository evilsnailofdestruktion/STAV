local U = {}

U.Version = table.concat(Ext.Mod.GetMod(ModuleUUID).Info.ModVersion, ".")

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

function U.TryParseJson(raw)
	if type(raw) ~= "string" or raw == "" then return nil end
	local ok, data = pcall(Ext.Json.Parse, raw)
	return ok and type(data) == "table" and data or nil
end

function U.GetLiveCharacter()
	local char = _C()
	if char and char.Level.LevelName ~= "SYS_CC_I" then return char end
end

function U.GetDisplayName(uuid, fallback)
	local entity = Ext.Entity.Get(uuid)
	if not entity then return fallback or uuid end
	if entity.CustomName then return entity.CustomName.Name end
	if entity.DisplayName then return entity.DisplayName.Name:Get() or fallback or uuid end
	return fallback or uuid
end

function U.AddIfMissing(current, entry)
	entry = entry:match("^%s*(.-)%s*$")
	for existing in current:gmatch("[^;]+") do
		if existing:match("^%s*(.-)%s*$") == entry then return current end
	end
	return current == "" and entry or current .. ";" .. entry
end

function U.ProgressionTables(uuids, dataType)
	local tables, count = {}, 0
	for uuid in pairs(uuids) do
		local entry = Ext.StaticData.Get(uuid, dataType)
		if entry then
			tables[entry.ProgressionTableUUID] = true
			count = count + 1
		end
	end
	return tables, count
end

function U.PatchProgressions(tableUUIDs, field, entry, level)
	local patched = 0
	for _, uuid in pairs(Ext.StaticData.GetAll("Progression")) do
		local prog = Ext.StaticData.Get(uuid, "Progression")
		if tableUUIDs[prog.TableUUID] and (not level or prog.Level == level) then
			local value = U.AddIfMissing(prog[field], entry)
			if value ~= prog[field] then prog[field] = value end
			patched = patched + 1
		end
	end
	return patched
end

function U.CountElements(tbl)
	if not tbl then return 0 end
	local count = 0
	for _ in pairs(tbl) do count = count + 1 end
	return count
end

function U.IsDenseArray(value)
	if type(value) ~= "table" then return false end
	for i = 1, U.CountElements(value) do
		if value[i] == nil then return false end
	end
	return true
end

return U
