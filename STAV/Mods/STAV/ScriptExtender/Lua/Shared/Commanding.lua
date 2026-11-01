local U = Ext.Require("Shared/Utility.lua")
local P = Ext.Require("Shared/Printing.lua")

Ext.RegisterConsoleCommand("stav_head_check", function(_)
	local owner, broken = {}, 0
	for mod, ids in pairs(Ext.StaticData.GetSources("CharacterCreationAppearanceVisual")) do
		for _, id in pairs(ids) do owner[id] = mod end
	end
	for _, id in ipairs(Ext.StaticData.GetAll("CharacterCreationAppearanceVisual")) do
		local cc = Ext.StaticData.Get(id, "CharacterCreationAppearanceVisual")
		local visual = cc.SlotName == "Head" and Ext.Resource.Get(cc.VisualResource, "Visual")
		local listed = false
		for _, o in ipairs(visual and visual.Objects or {}) do
			if not Ext.Resource.Get(o.MaterialID, "Material") then
				if not listed then
					local mod = owner[id] and Ext.Mod.GetMod(owner[id])
					P.Log():C16("[STAV] "):C5(mod and mod.Info.Name or "Unknown mod"):Raw(" "):C7(cc.DisplayName:Get() or id):C3(" [" .. cc.VisualResource .. "]."):Print()
					listed = true
				end
				broken = broken + 1
				P.Log():Raw("    "):C7(o.ObjectID):Raw(" "):C1((o.MaterialID == "" and "has no material" or "uses missing material " .. o.MaterialID) .. "."):Print()
			end
		end
	end
	P.Log():C16("[STAV] "):C7(string.format("%d head objects with a missing material.", broken)):Print()
end)

if Ext.IsClient() then
	Ext.RegisterConsoleCommand("stav", function(_)
		STAVToggleUI()
	end)

	Ext.RegisterConsoleCommand("stav_race", function(_, sub, kind, uuid)
		if sub ~= "gen" or (kind ~= "override" and kind ~= "upsert") or not uuid then
			P.Log():C16("[STAV] "):C7("Usage: !stav_race gen <override|upsert> <mod uuid>"):Print()
			return
		end
		if not U.IsGuid(uuid) then
			P.Log():C16("[STAV] "):C7("Invalid mod UUID."):Print()
			return
		end
		local mod = Ext.Mod.GetMod(uuid)
		if not mod then
			P.Log():C16("[STAV] "):C7("Mod not found or not loaded."):Print()
			return
		end

		local found = {}
		local races = {}
		local seg = "/" .. mod.Info.Directory .. "/"
		for _, t in pairs(Ext.Template.GetAllRootTemplates()) do
			if t.TemplateType == "character" and t.FileName:find(seg, 1, true) then
				local ct = t --[[@as CharacterTemplate]]
				local cv = ct.CharacterVisualResourceID
				if cv ~= "" then found[cv] = ct.Name end
				if ct.Race ~= U.NULL_UUID then races[ct.Race] = true end
			end
		end

		local entries = {}
		local count = 0
		for cv, name in pairs(found) do
			local key = entries[name] and (name .. "_" .. cv:sub(1, 8)) or name
			if kind == "override" then
				entries[key] = { type = "override", charvis = { cv }, material = "" }
			else
				entries[key] = {
					type = "upsert",
					charvis = { cv },
					scarMap = "",
					scarMapNM = "",
					--[[ overrides = {
						body = {
							Scalars = { SecretTatIndex = 0 },
							Vec4 = { TattooIntensity = { 0, 0.88235295, 0, 0 } }
						}
					} ]]
				}
			end
			count = count + 1
		end

		if count == 0 then
			P.Log():C16("[STAV] "):C7(string.format("No race charvis found for %s.", mod.Info.Name)):Print()
			return
		end

		local raceList = {}
		for race in pairs(races) do raceList[#raceList + 1] = race end
		table.sort(raceList)

		Ext.IO.SaveFile("STAVConfig.json", Ext.Json.Stringify({ Entries = entries, Races = raceList }))
		P.Log():C16(string.format("[STAV] Exported %d %s charvis and %d races for %s to Script Extender/STAVConfig.json.", count, kind, #raceList, mod.Info.Name)):Print()
	end)
end
