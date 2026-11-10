local NetDefs = {}

NetDefs.NET_APPLY       = Ext.Net.CreateChannel(ModuleUUID, "STAV_Apply")
NetDefs.NET_APPLY_SYNC  = Ext.Net.CreateChannel(ModuleUUID, "STAV_ApplySync")
NetDefs.NET_AVATAR_PING = Ext.Net.CreateChannel(ModuleUUID, "STAV_AvatarPing")

return NetDefs
