local Maps = {}

function Maps.BodyIndex(uiIdx)
	return uiIdx - 1
end

local HEAD_MAP_CACHE = nil

function Maps.HeadIndex(uiIdx)
	if not HEAD_MAP_CACHE then
		HEAD_MAP_CACHE = {}
		HEAD_MAP_CACHE[1] = 31
		local trueIdx = 0
		for ui = 2, 200 do
			while trueIdx == 15 or trueIdx == 47 or trueIdx == 79 do
				trueIdx = trueIdx + 1
			end
			HEAD_MAP_CACHE[ui] = trueIdx
			trueIdx = trueIdx + 1
		end
	end
	return HEAD_MAP_CACHE[uiIdx] or 0
end

return Maps
