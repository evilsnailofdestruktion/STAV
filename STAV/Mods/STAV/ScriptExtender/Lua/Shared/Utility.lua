local U = {}

U.Version = table.concat(Ext.Mod.GetMod(ModuleUUID).Info.ModVersion, ".")

function U.IsGuid(value)
	if type(value) ~= "string" then
		return false
	end
	return value:match("^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$") ~= nil
end

function U.Guid(uuid)
	return uuid:sub(-36)
end

function U.TryParseJson(raw)
	if type(raw) ~= "string" or raw == "" then return nil end
	local ok, data = pcall(Ext.Json.Parse, raw)
	return ok and type(data) == "table" and data or nil
end

function U.GetDisplayName(uuid, fallback)
	local entity = Ext.Entity.Get(uuid)
	if not entity then return fallback or uuid end
	if entity.CustomName then return entity.CustomName.Name end
	if entity.DisplayName then return entity.DisplayName.Name:Get() or fallback or uuid end
	return fallback or uuid
end

function U.AddIfMissing(current, entry)
	current = current or ""
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
		if entry and entry.ProgressionTableUUID then
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
			prog[field] = U.AddIfMissing(prog[field], entry)
			patched = patched + 1
		end
	end
	return patched
end

return U
