local NetDefs = {}

local ModuleUUID = "2b9e05c8-d15a-3ac2-7237-6aa263f1dceb"

NetDefs.NET_APPLY    = Ext.Net.CreateChannel(ModuleUUID, "STAV_Apply")
NetDefs.NET_CC_STATE = Ext.Net.CreateChannel(ModuleUUID, "STAV_CCState")

return NetDefs
