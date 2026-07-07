local E      = Ext.Require("Shared/Events.lua")
local Vis    = Ext.Require("Shared/Visualising.lua")
local Config = Ext.Require("Shared/Config.lua")

local function buildKeys(meshDef, material)
	local keys = {}
	for _, visual in ipairs(meshDef.visuals) do
		for lod = 0, #material - 1 do
			keys[string.format("%s.%s_Mesh%s.%d", visual, visual, lod == 0 and "" or "_LOD" .. lod, lod)] = material[lod + 1]
		end
	end
	return keys
end

local function patchCharvis(charvis, keys)
	local cv = Ext.Resource.Get(charvis, "CharacterVisual")
	if not cv then
		STAVDebug("No charvis found, skipped: %s", charvis)
		return false
	end
	local vs = cv.VisualSet
	local overrides = {}
	for k, v in pairs(vs.RealMaterialOverrides) do overrides[k] = v end
	for k, v in pairs(keys) do overrides[k] = v end
	vs.RealMaterialOverrides = overrides

	if STAV_DebugEnabled or Config.Get("Debug") then
		local sorted = {}
		for k in pairs(keys) do sorted[#sorted + 1] = k end
		table.sort(sorted)
		local lines = { string.format("=== %s ===", charvis) }
		for _, k in ipairs(sorted) do lines[#lines + 1] = string.format("\t%s\t=>\t%s", k, keys[k]) end
		STAVDebug(table.concat(lines, "\n"))
	end

	return true
end

local function applyEntry(entry)
	local meshDef = Vis.Meshes[entry.mesh]
	if not meshDef then
		STAVDebug("Unknown mesh '%s', skipped", tostring(entry.mesh))
		return 0
	end
	local keys  = buildKeys(meshDef, entry.material)
	local count = 0
	for _, charvis in ipairs(entry.charvis) do
		if patchCharvis(charvis, keys) then count = count + 1 end
	end
	return count
end

local function applyGroup(group)
	local count = 0
	for _, entry in pairs(group) do
		count = count + applyEntry(entry)
	end
	return count
end

local function applyAll()
	local count = applyGroup(Vis.Companions)
	if Vis.Players then count = count + applyGroup(Vis.Players) end
	STAVDebug("Patched %d charvis with STAV materials", count)
end

E.StatsLoaded.Subscribe(applyAll)
