local NetDefs = {}

local ModuleUUID = "2b9e05c8-d15a-3ac2-7237-6aa263f1dceb"

NetDefs.NET_APPLY       = Ext.Net.CreateChannel(ModuleUUID, "STAV_Apply")
NetDefs.NET_APPLY_SYNC  = Ext.Net.CreateChannel(ModuleUUID, "STAV_ApplySync")
NetDefs.NET_AVATAR_PING = Ext.Net.CreateChannel(ModuleUUID, "STAV_AvatarPing")

return NetDefs
