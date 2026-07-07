local MESHES = {
	HUM_M = { visuals = { "HUM_M_NKD_Body_A" } },
	HUM_F = { visuals = { "HUM_F_NKD_Body_A" } },
}

local PLAYER_VIS = {}

local COMPANIONS_VIS = {
	Gale = {
		charvis  = {
			"1a4faa8c-7fca-1f62-e499-87d362d90512",
			"04262cdf-e58d-606d-af9f-a29d72643644",
			"31548f9b-a200-9624-0817-61a71a50931a",
			"62d788a1-f777-4608-8ee1-55325ccf3360",
			"9f2b34c6-7914-efec-0f17-24a8a3abc758",
			"d486eb45-1949-3226-c6cc-1c3df31a0449",
			"871320c7-8b7a-8f2c-467a-1d727a025e76",
			"9be0bb8c-8ee2-4edb-86e9-1bf024acba67"
		},
		mesh     = "HUM_M",
		material = {
			"cfd6618f-adc0-c531-06e7-24283aa05da3",
		},
	},
	Shadowheart = {
		charvis  = {
			"9ab62da4-a028-c237-b5b9-ca897f62b771",
		},
		mesh     = "HUM_F",
		material = {
			"<LOD0 mat>",
			"<LOD1 mat>",
			"<LOD2 mat>",
			"<LOD3 mat>",
			"<LOD4 mat>",
		},
	},
}

return {
	Meshes     = MESHES,
	Companions = COMPANIONS_VIS,
}
