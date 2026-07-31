local M = {}

function M.GetLook(entity)
	return entity.Vars["STAV_Look"]
end

function M.SetLook(entity, tbl)
	entity.Vars["STAV_Look"] = tbl
end

-- TODO: Delete everything below in a couple updates
local LEGACY_KEYS = {
	altColor  = "altColour",
	glowColor = "glowColour"
}

local LEGACY_VAMPIRISM = 0.25

function M.MigrateLook(look)
	local out, changed = {}, false
	for k, v in pairs(look) do
		local key = LEGACY_KEYS[k]
		if key then changed = true else key = k end
		if key == "vampirism" and type(v) == "boolean" then
			v = v and LEGACY_VAMPIRISM or 0
			changed = true
		end
		out[key] = v
	end
	return out, changed
end

return M
