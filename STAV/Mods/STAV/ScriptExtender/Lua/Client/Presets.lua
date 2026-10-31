local U   = Ext.Require("Shared/Utility.lua")
local Map = Ext.Require("Client/UIMap.lua")

local M = {}

local DIR = "STAV"

local function validateLook(look)
	for key, value in pairs(look) do
		local spec = Map[key]
		local kind = spec and spec.type
		if kind == "boolean" then
			if type(value) ~= "boolean" then return nil end
		elseif kind == "index" then
			if type(value) ~= "number" or value % 1 ~= 0 or value < 1 or value > spec.max then return nil end
		elseif kind == "number" then
			if type(value) ~= "number" or value < 0 or value > spec.max then return nil end
		elseif kind == "colour" then
			if type(value) ~= "table" or #value < 3 or #value > 4 then return nil end
			for i = 1, #value do
				if type(value[i]) ~= "number" then return nil end
			end
			look[key] = { value[1], value[2], value[3], value[4] or 1 }
		end
	end
	return look
end

local function presetPath(name)
	return DIR .. "/" .. name .. ".json"
end

local function loadIndex()
	local data = U.TryParseJson(Ext.IO.LoadFile(DIR .. "/index.json"))
	return data and type(data.names) == "table" and data.names or {}
end

local function saveIndex(names)
	return Ext.IO.SaveFile(DIR .. "/index.json", Ext.Json.Stringify({ names = names }))
end

local function register(name)
	local names = loadIndex()
	for _, n in ipairs(names) do
		if n == name then return true end
	end
	names[#names + 1] = name
	return saveIndex(names)
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
	local data = U.TryParseJson(Ext.IO.LoadFile(presetPath(name)))
	if not data then return nil end
	return validateLook(data)
end

function M.Save(name, values)
	name = M.Normalize(name)
	if not name then return false end
	return M.Export(name, values) and register(name)
end

function M.Delete(name)
	name = M.Normalize(name)
	if not name then return false end
	local names = loadIndex()
	local out = {}
	for _, n in ipairs(names) do
		if n ~= name then out[#out + 1] = n end
	end
	return saveIndex(out)
end

function M.Export(name, values)
	name = M.Normalize(name)
	if not name then return false end
	return Ext.IO.SaveFile(presetPath(name), Ext.Json.Stringify(values))
end

function M.Import(name)
	name = M.Normalize(name)
	if not name then return nil, "invalid" end
	local look = M.Load(name)
	if not look then return nil, "invalid" end
	if not register(name) then return nil, "write" end
	return name, look
end

return M
