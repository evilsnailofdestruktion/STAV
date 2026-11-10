local M = {}

function M.GetLook(entity)
	return entity.Vars["STAV_Look"]
end

function M.SetLook(entity, tbl)
	entity.Vars["STAV_Look"] = tbl
end

return M
