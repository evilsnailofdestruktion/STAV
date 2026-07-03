local M = {}

function M.GetLook(entity)
	if not entity then return nil end
	return entity.Vars["STAV_Look"]
end

function M.SetLook(entity, tbl)
	if not entity then return end
	entity.Vars["STAV_Look"] = tbl
end

return M
