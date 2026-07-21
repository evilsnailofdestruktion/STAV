local U = Ext.Require("Shared/Utility.lua")

local M = {}

local DIR = "STAV"

local function presetPath(name)
	return DIR .. "/" .. name .. ".json"
end

local function loadIndex()
	local data = U.TryParseJson(Ext.IO.LoadFile(DIR .. "/index.json"))
	return data and type(data.names) == "table" and data.names or {}
end

local function saveIndex(names)
	Ext.IO.SaveFile(DIR .. "/index.json", Ext.Json.Stringify({ names = names }))
end

local function register(name)
	local names = loadIndex()
	for _, n in ipairs(names) do
		if n == name then return end
	end
	names[#names + 1] = name
	saveIndex(names)
end

function M.Normalize(name)
	name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
	return name ~= "" and name or nil
end

function M.List()
	local names = loadIndex()
	table.sort(names)
	return names
end

function M.Load(name)
	name = M.Normalize(name)
	if not name then return nil end
	return U.TryParseJson(Ext.IO.LoadFile(presetPath(name)))
end

function M.Save(name, values)
	name = M.Normalize(name)
	if not name then return end
	M.Export(name, values)
	register(name)
end

function M.Delete(name)
	name = M.Normalize(name)
	if not name then return end
	local names = loadIndex()
	local out = {}
	for _, n in ipairs(names) do
		if n ~= name then out[#out + 1] = n end
	end
	saveIndex(out)
end

function M.Export(name, values)
	name = M.Normalize(name)
	if not name then return false end
	Ext.IO.SaveFile(presetPath(name), Ext.Json.Stringify(values))
	return true
end

function M.Import(name)
	name = M.Normalize(name)
	if not name or not M.Load(name) then return nil end
	register(name)
	return name
end

return M
