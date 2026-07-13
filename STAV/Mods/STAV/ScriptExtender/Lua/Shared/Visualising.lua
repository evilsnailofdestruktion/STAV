local COMPAT = {
	["8cc519bd-cfd3-4041-9468-518cc3e31b28"] = { all = true },		-- Unique Companion Assets
	["2396f116-b622-4940-96bf-083b120e2a30"] = {							-- A Candle In The Dark
		Jason = {
			charvis   = {
				""
			},
			scarMap   = "",
			scarMapNM = ""
		}
	}
}

local PLAYER_VIS = {
	DROW_F = {
		charvis   = {
			"2cc252c2-4eef-ce10-245b-de39bb45b39d",
			"187188d8-929a-d800-d5c3-33453a8cc25a",
			"27b58c9a-5efa-e736-d81e-98d124a6bb8a"
		},
		material  = "cd69fa48-def6-c323-ce85-07321817f10f"
	},
	DROW_M = {
		charvis   = {
			"477d8a7b-4025-eb61-b8ff-91c848a4c82e",
			"f2f3f92a-d471-bee8-064e-0614e238b0d0",
			"3b9ceab9-c731-db57-afc0-04d7eb424874",
			"0f54ca06-abfa-2b82-5982-58edae2f68e2"
		},
		material  = "c0759310-a004-7e3c-a4b8-8c25da11c770"
	},
	DROW_FS = {
		charvis   = {
			"06bc048a-2d5a-9943-b202-9d9261e9cde2",
			"fa98fc6b-a18d-7dd1-b9ed-709039e41e73",
			"1357ce70-9407-2f0d-8aa8-b22c206b8950"
		},
		material  = "3c6fb944-8b68-a4e1-9b4b-60dfebffdb90"
	},
	DROW_MS = {
		charvis   = {
			"f6bdb7da-ceb8-fd9e-9c04-78c93d3f0806",
			"dd25a73b-cdf6-7c41-e098-35828550112f",
			"52a2168f-d199-69bb-ca2f-cbdf6e3a2c04"
		},
		material  = "663ff294-20df-8dd2-e409-e60b8044f997"
	},
	DWR_F = {
		charvis   = {
			"9598d919-8272-0377-d2a5-879c0012f3fd",
			"252f9e78-9f65-a2e3-1236-84d1b8387306",
			"0f089ef3-2587-0603-8479-3c9b0679f9b8",
			"011d925e-12b8-9a6f-1d8e-06ad9bffd0fc",
			"aee6c3ff-dad0-0fc2-57a1-3b0d5e4b95c2",
			"44f07c8c-b28e-72ef-fa2e-7645fd410387"
		},
		material  = "f40c211c-5a5f-647c-e503-c4db338df300"
	},
	DWR_M = {
		charvis   = {
			"9dab2880-c88d-f2d8-98aa-358e962b8afa",
			"c6d50cc6-0120-90cb-b776-4cda0d2bc7d3",
			"8d6c967f-b24b-fce2-a54a-d9bbf0b79da9",
			"7997cde4-12c2-354b-cc1e-ff51ca00032c",
			"3fcf0675-a947-7d6e-5941-0d8d51ce7f95",
			"2acd2062-1c34-6890-0494-72c1df17973f",
			"664b1ba1-6f84-3446-7f83-03b7d82b3d99"
		},
		material  = "10432221-9250-adc3-c530-a717a5ec46c9"
	},
	ELF_F = {
		charvis   = {
			"e1254a4e-3d52-76c2-7b19-52e93941b6dd",
			"fa671c8c-487a-297a-9d73-5fb7b769a3e7",
			"d67bd924-3c1f-c33a-5298-feca5bbdc284",
			"69c6d55e-2faa-16a0-f0bd-7e3dce4529cf"
		},
		material  = "d1d50fe6-0fb2-533c-d8f6-7ab074df2913"
	},
	ELF_M = {
		charvis   = {
			"f7af9f10-cd33-3b88-e96a-d52952e81f5b",
			"015bd884-82d1-cc15-2a0f-0cb8524028f4",
			"f0c009b2-7868-784e-f2fc-dde5ac934aba"
		},
		material  = "4c58d01d-b005-f1b9-7084-6f1193de67f6"
	},
	ELF_FS = {
		charvis   = {
			"8d3b10f3-7f7c-626d-0d13-4d6223de9f94",
			"5064dd4e-d4ec-e30a-c784-a98596d7070f",
			"eb370ddf-f7a4-4349-116e-f489556bab1d"
		},
		material  = "16ffd4b3-3b00-f623-3686-703c2b828fdc"
	},
	ELF_MS = {
		charvis   = {
			"76172a38-007d-6213-d75c-820a8b67004a",
			"c457d519-ddf4-a023-667a-38d2565511e3",
			"dbe45e58-e009-91ae-91f1-e5311cbef090"
		},
		material  = "d232a086-0ded-c1ad-2c22-53336c2590b2"
	},
	GNO_F = {
		charvis   = {
			"80232477-0852-54ea-532a-f216bdf4be61",
			"4d66cbb8-05d8-807a-622c-55fbdf0719a9",
			"2a1aaf1e-683f-9af2-c8d1-2354634bbc45",
			"7556599d-28e9-14df-15a5-3e3c9d01bea4"
		},
		material  = "ba7b5e8f-27a1-035e-9109-44d4b6e6af10"
	},
	GNO_M = {
		charvis   = {
			"2190c1fe-8bf0-cf21-24f7-482defce3814",
			"6bec6b31-b86b-2c6b-68e1-fea2a943fec5",
			"eabe1080-a24e-5aed-1a26-7594172bfefd",
			"00313806-830f-9427-8b09-f1505de92a50"
		},
		material  = "6a67f147-229c-e6b8-25d1-2b427bde7a0b"
	},
	GTY_F = {
		charvis   = {
			"00f931b5-7105-da0c-8992-26beeb53dbbc",
			"40b40a77-9484-9cb2-f49a-1ae083815cf3"
		},
		material  = "73b1a66a-dc9a-9488-8adf-a1e4af9151af"
	},
	GTY_M = {
		charvis   = {
			"2c0ba7ad-66be-884e-b680-9b7e5a2203a0",
			"538eb02f-9e1b-4740-7e4f-024573ce2de7",
			"6a07e0d8-4110-54f7-c013-19ed2ff990ed"
		},
		material  = "6f701dcf-672b-966e-9136-62f4769bb72c"
	},
	HEL_F = {
		charvis   = {
			"a58738bb-b385-080c-11da-85a2787a9b3d",
			"eb625697-be9f-2820-6e2e-39d0d4a30a45",
			"1c36f857-0a5e-a0e2-66d9-9c5b24daf824",
			"23dac105-2cac-772e-3f25-f6f6416f4957",
			"d6b3078b-e4f1-ecfc-4801-b1a6da80e1be"
		},
		material  = "e9cdaf51-7e6f-4c8e-33f6-2c780f1166b0"
	},
	HEL_M = {
		charvis   = {
			"345d747b-fd96-f13c-cae5-a7f750e65040",
			"a4453c57-324b-60de-7e9a-ba17e5c31ba3",
			"d598ca76-ca77-2fb1-3010-ebff8dcaf3c5",
			"0d8094d2-9d1e-6da2-b028-a1e376df46ce",
			"0ccfb296-7f21-9281-08e0-1d75992072bb"
		},
		material  = "c05cc830-d12f-4eee-8cac-cd7b40d2550d"
	},
	HEL_FS = {
		charvis   = {
			"93acb59c-c9d9-f59d-41dc-b6d7e0e6fba6",
			"9f6ddfe1-e89d-c5e5-e54d-c1e2a755324c",
			"3a01c388-506f-3b91-721a-9c5692db3357",
			"639f5904-682b-2413-fbfc-191af52808b6"
		},
		material  = "c30c53d5-d0b5-4b41-a958-6bf5a4696d25"
	},
	HEL_MS = {
		charvis   = {
			"a97ff4b7-f9d9-0c00-9c1b-65275ba4b704",
			"e34dae3b-3dc7-3499-a68b-27288dbffd85",
			"9f573c86-3162-1d53-884b-05d8a00511ab",
			"a7739671-73cb-1005-8694-2ae556825885"
		},
		material  = "f455e079-c0d2-fe8c-9954-8fde6b76be36"
	},
	HFL_F = {
		charvis   = {
			"da852f7d-e4ed-610b-4d31-91fcc032e4fe",
			"a871cdb8-4d0e-9de8-8221-1c1f8950b49d",
			"752afaa1-8f92-a72d-3500-df162e899489",
			"788c94fb-c9a1-fbc7-7fd4-03d8a031e66e"
		},
		material  = "d840a2bd-14ce-6e7f-8c1c-3562c9d26e73"
	},
	HFL_M = {
		charvis   = {
			"9badecc0-804e-94d8-135e-cd70bb9e00bc",
			"ca90df09-a517-fa81-d248-8b111d352c5a",
			"a05d6235-48f4-93be-d113-38c550815176",
			"8e776d9d-344a-3265-50a3-6bd2bd6de5f8"
		},
		material  = "3cc12b3a-0c0a-2ecf-521f-82ed080de616"
	},
	HRC_F = {
		charvis   = {
			"1586dcb3-51ff-7489-bfa4-81263bf56686",
			"6bcf04be-942d-2980-2e59-089a5a6ba36e"
		},
		material  = "a79321f5-f966-485c-20d7-ddd87dc0329c"
	},
	HRC_M = {
		charvis   = {
			"cd67df82-8a06-2005-740f-9c7762097834",
			"355b3b3c-cdae-8805-04dd-d6299920876f"
		},
		material  = "b2dca29f-e14c-ce03-920b-32574161abcf"
	},
	HUM_F = {
		charvis   = {
			"51214aaf-d81d-60f3-b7a6-28002ade0a6f",
			"65508880-7afc-74cf-97eb-8d85c80b79b4",
			"fedf1050-a2b6-e913-1cd2-e3b9effd2b90",
			"1a1e412a-37ca-9425-6cfd-67ee7429d616"
		},
		material  = "608a2e39-56cc-c57c-be07-30812f08b5c3"
	},
	HUM_M = {
		charvis   = {
			"71aaadda-22e0-f962-14ff-f57d57a2e726",
			"40b6c0b8-693d-3726-6819-acbc8481f208",
			"58106c8e-8b3b-0854-5720-61c543805888"
		},
		material  = "cfd6618f-adc0-c531-06e7-24283aa05da3"
	},
	HUM_FS = {
		charvis   = {
			"df8ba65b-48da-8f7c-a814-c2fcb65ae67a",
			"3cea72b5-bbc3-a9d8-3bb9-edb85ef9738c"
		},
		material  = "3f3de6bd-56fa-63a5-7b72-5cd6a9deabc7"
	},
	HUM_MS = {
		charvis   = {
			"1d4e0fe8-969c-1050-8f3e-96f172a3d153",
			"0a9d0823-9a79-7a0b-9d37-c0ae1976051f",
			"783884de-ba13-3c69-1890-c59d2e4bcba8"
		},
		material  = "9f688deb-c24f-ca3d-524b-43dddda3b1a8"
	},
	TIF_F = {
		charvis   = {
			"41ac6638-8590-4c25-2789-44cdc8ef87d8",
			"0a902841-1c5b-7acc-9620-91b284a65436",
			"b2a2a57a-7690-681f-ad5c-61aa4c9754db",
			"4d42fb67-449d-1c13-8661-09610d477183",
			"d74056a1-922b-2e5b-54b9-e67de157d433"
		},
		material  = "cec04751-16eb-ddb2-2a55-7c0fa3f48a02"
	},
	TIF_M = {
		charvis   = {
			"35fa926e-18f4-2d3e-872a-04ab9e95b76c",
			"a178a41d-05c3-3bc8-4879-15d2effe3300",
			"127ae5d8-a7bd-0498-1d71-4e479d247922",
			"96b61e9f-9901-4406-fa22-f29631339bb9"
		},
		material  = "d2d1745c-979d-b1be-4f41-64c6adcd6d9a"
	},
	TIF_FS = {
		charvis   = {
			"f1cdcf6d-7469-14ec-380f-3cb5df440340",
			"fcff3667-ddc0-1b32-2b7f-1acedfa0cf50",
			"b873fc5f-67fb-72ca-ec6c-38f225d03477",
			"8bbe62dd-9fe5-f6e4-4700-884354f6a346"
		},
		material  = "cbbd294d-468c-bd37-ef2f-d2351ff2b45f"
	},
	TIF_MS = {
		charvis   = {
			"a9afff3b-121d-085e-12af-9e9fb07c788f",
			"351d13d4-a4de-0dd0-24df-3a194285c7e6",
			"ee113dde-55da-ce62-5d4e-a98ccf9606cd",
			"ea87e65b-5d45-26c0-c5bf-54a974913b91"
		},
		material  = "f31189c6-50ce-a198-93bb-cfa54fb75079"
	},
}

local COMPANIONS_VIS = {
	Astarion = {
		charvis   = {
			"14c23242-b819-0d30-f5ba-5e6c9b4b6088",
			"6788a271-9ad5-074f-8a5f-12b7dcb29174",
			"572763d2-d40a-1def-510b-f878b9cd8da8",
			"a66864fa-0820-7ed4-d26a-8dc0d397a5e5",
			"9ea09cc5-7842-d0d6-8961-93de27f16888",
			"1bf04545-26b5-95b9-92b6-18495961ba32",
			"28de6f26-806e-f02b-1e2b-8eb791406a89",
			"be9fbfe1-cf9c-7864-55d3-bbd6d329150b",
			"4c344a90-588a-59a9-5495-3fc33893b3b0",
			"b2da9993-29a6-dc63-23dd-8b319047230c",
			"255e4a19-65dc-27d5-bf7c-885ca92d6ea6",
			"8b717bd5-cdc9-66b4-9ae0-908f9b9173a2",
			"f0c1cd99-8f94-e5ba-86b3-bfc048af906e",
			"96824355-8954-2b76-5a1d-9503b93f796b",
			"7407f64a-af3f-1f9d-ae7d-8704227c5c27"
		},
		material  = "2e8da869-974a-209e-ea85-cecf69edcb64",
		scarMap   = "a8019fca-9d39-fb6f-e79a-b7d7aff2fc88",
		scarMapNM = "5ef09d5a-b114-e5b4-8ba0-1d6e67170242"
	},
	Gale = {
		charvis   = {
			"04262cdf-e58d-606d-af9f-a29d72643644",
			"1a4faa8c-7fca-1f62-e499-87d362d90512",
			"31548f9b-a200-9624-0817-61a71a50931a",
			"62d788a1-f777-4608-8ee1-55325ccf3360",
			"9f2b34c6-7914-efec-0f17-24a8a3abc758",
			"d486eb45-1949-3226-c6cc-1c3df31a0449",
			"871320c7-8b7a-8f2c-467a-1d727a025e76"
		},
		material  = "edd2cb50-b537-76ad-134e-c75c65d99705",
		scarMap   = "996c16c9-9d96-2264-9fde-f39283d1f737",
		scarMapNM = "69bc5c47-a2dd-d19b-5437-335ac3809a8e",
		overrides = {
			head = {
				Scalars = { TattooIndex = 57 },
				Vec4	  = { TattooIntensity = { 0, 0.88235295, 0, 0 } }
			},
			body = {
				Scalars = { SecretTatIndex = 5 }
			},
		},
	},
	GaleNoTats = {
		charvis   = {
			"9be0bb8c-8ee2-4edb-86e9-1bf024acba67"
		},
		material  = "c7be9d7e-8883-03af-f7d4-44b8730a71f4",
		scarMap   = "996c16c9-9d96-2264-9fde-f39283d1f737",
		scarMapNM = "69bc5c47-a2dd-d19b-5437-335ac3809a8e",
		overrides = {
			head = {
				Scalars = { TattooIndex = 57 },
				Vec4	  = { TattooIntensity = { 0, 0.88235295, 0, 0 } }
			},
			body = {
				Scalars = { SecretTatIndex = 5 }
			},
		},
	},
	Halsin = {
		charvis   = {
			"b7830265-b4d4-3419-bd41-1fe1099ccf16",
			"881301f4-4ccb-29ae-4336-3abf9cfba9f0",
			"a9af1b0f-f66a-b844-c22a-33151e1ed4fc"
		},
		material  = "cd3b1f46-fd4f-bfff-7e91-ee7cfbf3d574",
		scarMap   = "b3b25a5a-c28d-1468-b759-e119f1ad475a",
		scarMapNM = "249959cb-89b9-2ea2-1402-649a88b6b8e1",
		overrides = {
			head = {
				Scalars = { TattooIndex = 56 },
				Vec4    = { TattooIntensity = { 0, 0.88235295, 0, 0 } }
			}
		},
	},
	Jaheira = {
		charvis   = {
			"b90c6552-4529-e6ef-1084-34c56eca1521",
			"f09fbd8b-ee7d-4142-5a69-2be414c8852c",
			"966e8a68-24a0-fd94-8323-74f7b091df7c"
		},
		material  = "cebf12f5-c510-7e4a-513c-c3421a2e94ba",
		scarMap   = "872397ef-7d2d-139c-55c4-29a9ff58159c",
		scarMapNM = "df8d649a-a7ff-246a-74f7-6e0c5894508d"
	},
	Karlach = {
		charvis   = {
			"2dd12288-c71c-7db2-925c-2f884c1727bc",
			"7abb8ab4-2f85-8785-2762-ff11afc6f372",
			"39d59978-8a65-a8ec-6e8b-0d391f4035e3",
			"ce24301b-f705-ab7d-4354-d51ab93c5ae3"
		},
		material  = "1ece701e-a4f7-a466-f3ad-b8418191e284",
		scarMap   = "847f848a-53bf-87f8-105b-de75f01ff600",
		scarMapNM = "38f1af8d-c9ab-c64d-13aa-143062de1349",
		shader = true,
		overrides = {
			body = {
				Scalars = { SecretTatIndex = 4 }
			}
		},
	},
	KarlachNoGlow = {
		charvis   = {
			"5757770a-12aa-a3f6-35dd-39beeaf5489d"
		},
		material  = "1ece701e-a4f7-a466-f3ad-b8418191e284",
		scarMap   = "847f848a-53bf-87f8-105b-de75f01ff600",
		scarMapNM = "38f1af8d-c9ab-c64d-13aa-143062de1349",
		overrides = {
			body = {
				Scalars = { SecretTatIndex = 4 }
			}
		},
	},
	Laezel = {
		charvis   = {
			"685e521d-a4a8-0199-1064-05840a43d28e",
			"3a42ea31-54d2-6d3e-cf39-79b064972f5f",
			"b707448b-a558-c3fc-55a2-87fd5c87407e",
			"31227da2-963d-c611-11ad-52cf15e14580",
			"1088f4ee-579b-b49e-72cc-7ecc5fc5be79"
		},
		material  = "b153fa26-d9a8-9337-5dee-ffddaad4b282",
		scarMap   = "8b8585b6-1832-756b-14e8-ee9f9beb7cb9",
		scarMapNM = "66533581-5c36-817e-b22f-0086eccf4b41",
		overrides = {
			head = {
				Scalars = { TattooIndex = 54 },
				Vec4    = { TattooIntensity = { 0, 0.88235295, 0, 0 } }
			}
		},
	},
	Minsc = {
		charvis   = {
			"6acff363-4407-0b10-0a7c-c1e27fe03c58",
			"9404e0a4-fafd-47ec-ad6d-52d63cb116ff",
			"b933b9ae-e37a-95ff-0801-1dd31069ecfc"
		},
		material  = "b7bae40d-b2fd-4c10-6de4-9a492dc43e47",
		scarMap   = "2432d1f5-b05b-98bd-7599-98b9f73beffe",
		scarMapNM = "3dc4f7df-1933-548d-6b27-e061039c1db8",
		overrides = {
			head = {
				Scalars = { TattooIndex = 58 },
				Vec4    = { TattooIntensity = { 0, 0.88235295, 0, 0 } }
			}
		},
	},
	Minthara = {
		charvis   = {
			"63dcb01e-630a-b575-ef5c-10ff738b7d51",
			"383236f9-c7ab-7163-4638-d2e2702ec513",
			"6248f8a8-839e-956f-6986-e10a55406c81",
			"d1bc342f-c995-bad7-4622-4e3f09f3e5ed",
			"ee1200f2-51a4-7b28-f046-1d29de15a651",
			"a261b2a4-a3ba-9baf-0ec1-f6557e2ce22a",
			"39350e36-2c69-bc20-c2b8-981dfa5b263b",
			"5a78cb10-4528-5b3c-4029-1dff2d302dbc"
		},
		material  = "e35a200e-2fff-a8d3-d1c8-66d0cff91c2c",
		scarMap   = "ef953551-4cc3-643e-5250-bc4edbb5ea52",
		scarMapNM = "8215e82c-8774-8234-afa3-cbdf7093a9bb",
		overrides = {
			head = {
				Scalars = { TattooIndex = 55 },
				Vec4    = { TattooIntensity = { 0, 0.88235295, 0, 0 } }
			}
		},
	},
	Shadowheart = {
		charvis   = {
			"a4cb151d-de86-1cd2-3cbe-327fc71eec82",
			"a48523ae-0f47-ec7d-e3a0-2e7ce657a9f2",
			"da027039-ae35-8012-c351-44a7e7c890a5",
			"fa6a72dc-9ba4-eb5f-f442-40c4ab5d2418",
			"5b3f87f9-2a3e-00ca-d173-0b608f870995",
			"9ab62da4-a028-c237-b5b9-ca897f62b771",
			"f9dad0cb-4b58-c911-7eea-7d4c9871b04e",
			"0f6f29d0-e0c7-1a9f-e658-4a3f48f62d63",
			"508d18b3-3988-4f5e-58ef-b668ae53e704"
		},
		material  = "31ea4499-1f05-e225-1e1a-d3928fe3cd98",
		scarMap   = "f0804a81-6622-f7e0-efe0-c665626980b1",
		scarMapNM = "b6987be1-aae4-1bea-d9fe-63291810053b"
	},
	Wyll = {
		charvis   = {
			"252f4a0d-d502-0985-52f2-973c38377faa",
			"38721e3d-c3b5-a0eb-3048-128846b3cc0e",
			"dec1a8bc-f710-001d-9d0f-51e87aafde6c",
			"e85e0c93-1dc9-c156-bd0e-45f5290b0f0f",
			"ccd88084-87ef-fd3c-5720-ee8066d4f465",
			"5261cf40-599a-4db7-ce6c-8cf71173c4fb",
			"bdeebe6f-4e34-ae70-5f25-ea0eadb77a34",
			"faf5255f-4dfa-d8bb-7e7a-5e4b7e11497c",
			"f2b3631a-2641-49c9-6a10-45e4fbdcfa44"
		},
		material  = "ecfbf57a-704d-34df-7689-cda0b6c9ec99",
		scarMap   = "c641d02d-e466-ac9b-3e7e-bf534d485417",
		scarMapNM = "d9662fd1-f7f6-c482-b473-e1b60ecbd9b9"
	}
}

return {
	Compat     = COMPAT,
	Companions = COMPANIONS_VIS,
	Player     = PLAYER_VIS,
}
