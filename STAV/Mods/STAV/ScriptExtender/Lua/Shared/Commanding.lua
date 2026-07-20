local U = Ext.Require("Shared/Utility.lua")

if Ext.IsClient() then
	Ext.RegisterConsoleCommand("stav", function(_)
		STAVToggleUI()
	end)

	Ext.RegisterConsoleCommand("stav_race", function(_, sub, kind, uuid)
		if sub ~= "gen" or (kind ~= "override" and kind ~= "upsert") or not uuid then
			STAVPrint():C16("[STAV] "):C7("Usage: !stav_race gen <override|upsert> <mod uuid>"):Print()
			return
		end
		if not U.IsGuid(uuid) then
			STAVPrint():C16("[STAV] "):C7("Invalid mod UUID"):Print()
			return
		end
		local mod = Ext.Mod.GetMod(uuid)
		if not mod then
			STAVPrint():C16("[STAV] "):C7("Mod not found or not loaded"):Print()
			return
		end

		local found = {}
		local seg = "/" .. mod.Info.Directory .. "/"
		for _, t in pairs(Ext.Template.GetAllRootTemplates()) do
			if t.TemplateType == "character" and t.FileName:find(seg, 1, true) then
				local ct = t --[[@as CharacterTemplate]]
				local cv = ct.CharacterVisualResourceID
				if cv and cv ~= "" then found[cv] = ct.Name end
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
			STAVPrint():C16("[STAV] "):C7(string.format("No race charvis found for %s", mod.Info.Name)):Print()
			return
		end

		Ext.IO.SaveFile("STAVConfig.json", Ext.Json.Stringify({ Entries = entries }))
		STAVPrint():C16(string.format("[STAV] Exported %d %s charvis for %s to Script Extender/STAVConfig.json", count, kind, mod.Info.Name)):Print()
	end)
end
