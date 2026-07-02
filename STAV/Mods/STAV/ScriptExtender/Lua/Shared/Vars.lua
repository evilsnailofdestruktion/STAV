local M = {}

M.STAV_LOOK = "STAV_Look"

-- server-transient: last look received via NET_APPLY (not an entity var)
M.LatestLook = nil

function M.GetLook(entity)
	if not entity then return nil end
	return entity.Vars[M.STAV_LOOK]
end

function M.SetLook(entity, tbl)
	if not entity then return end
	entity.Vars[M.STAV_LOOK] = tbl
end

return M
