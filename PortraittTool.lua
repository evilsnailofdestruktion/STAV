--[[
Features:
- Create icon requests icons for characters as they currently appear, including dyed gear and script overrides (ersatz eye, illithid, etc.)
- Supports custom requests if you want to change gear, colors, hair style, etc.
- Automatically syncs new icons across all clients. Icons are serialized by the game natively.
- Save icons as webp to your PC.
- Set webp from your PC as a character's icon.

Usage:
- See commands at the bottom
- Icon requests take ~3 seconds to be rendered by the game once submitted by a client. Be patient and try not to send another request while one is being rendered.
- Overwhelming majority of usage will be done from client context as renders are created by clients

Current issues:
- If the character doesn't have a piece of gear equipped, their placement is incorrect in the portrait. (Vanilla bug?)
- Only guaranteed to work for characters that have a generation trigger set up in SYS_PortraitPlayerRace. This is NOT the same as SYS_PortraitGeneration. Therefore will probably not work for non-humanoid characters.
--]]

---@class IconManager
IconManager = {
    System = "ClientCharacterIconRender",
    Net = Ext.Net.CreateChannel(ModuleUUID, "IconUpdate"),
    VisualSetParams = {},
    MaterialsParams = {},
    MaterialPresetParams = {},
    StatsOverrides = {}
}

---@param fileName? string default saves the request with an incremented counter
function IconManager:LogNextRequest(fileName)
    Ext.Entity.OnCreateDeferredOnce("ClientCharacterIconRequest", function (entity)
        local request = entity.ClientCharacterIconRequest
        local name = fileName or string.format("IconRequest_%s.json", Ext.Timer.ClockEpoch())
        Ext.IO.SaveFile(name, Ext.DumpExport(request))
        Ext.Log.Print("Saved new icon request as "..name)
    end)
end

---@param character? EntityHandle
---@param fileName? string
function IconManager:SaveIcon(character, fileName)
    character = character or _C()
    local icon = character.CustomIcon ~= nil and character.CustomIcon.Icon
    if icon then
        local name
        if fileName ~= nil then
            name = fileName
        else
            local characterName = character.DisplayName.Name:Get()
            local time = Ext.Timer.ClockEpoch()
            name = string.format("%s_%s.webp", characterName, time)
        end
        
        Ext.IO.SaveFile(name, icon)
        Ext.Log.Print("Saved new icon as "..name)
    end
end

---@param rgb vec3|vec4
---@return vec3
function IconManager:sRGBToLinearRGB(rgb)
    --[[
    -- Gamma correction to linear rgb
    for i = 1,3 do
        local c = rgb[i]
        if c <= 0.04045 then
            c = c / 12.92
        else
            c = ((c + 0.055) / 1.055) ^ 2.4
        end
        rgb[i] = c
    end
    --]]
    
    -- Game uses approximation
    return {rgb[1]^2.2, rgb[2]^2.2, rgb[3]^2.2}
end

function IconManager:RevertColorEdits()
    for templateId, parameters in pairs(self.VisualSetParams) do
        local template = Ext.Template.GetTemplate(templateId)
        if template ~= nil then
            Ext.Types.Unserialize(template.Equipment.VisualSet.MaterialOverrides.Vector3Parameters, parameters)
        end
        self.VisualSetParams[templateId] = nil
    end

    for materialId, parameters in pairs(self.MaterialsParams) do
        local material = Ext.Resource.Get(materialId, "Material")
        if material ~= nil then
            Ext.Types.Unserialize(material.Instance.Parameters.Vector3Parameters, parameters)
        end
        self.MaterialsParams[materialId] = nil
    end

    for presetId, parameters in pairs(self.MaterialPresetParams) do
        local preset = Ext.Resource.Get(presetId, "MaterialPreset")
        if preset ~= nil then
            Ext.Types.Unserialize(preset.Presets.Vector3Parameters, parameters)
        end
        self.MaterialPresetParams[presetId] = nil
    end 

    for stat, originalTemplate in pairs(self.StatsOverrides) do
        Ext.Stats.Get(stat).RootTemplate = originalTemplate
    end
end

-- Does not overwrite parameter values that may already exist in overrides
---@param presetParameters {Color:boolean, Custom:boolean, Enabled:boolean, Parameter:FixedString, Value:any}[]
---@param overrides table
function IconManager:AddPresetParametersToOverrides(presetParameters, overrides)
    for _, presetOverride in ipairs(presetParameters) do
        local foundParam = false
        for _, override in ipairs(overrides) do
            if override.Parameter == presetOverride.Parameter then
                foundParam = true
                break
            end
        end

        if not foundParam then
            overrides[#overrides+1] = {
                Override = presetOverride.Enabled,
                Parameter = presetOverride.Parameter,
                Preset = true,
                Value = presetOverride.Value,
                field_9 = 0
            }
        end
    end
end

---@param presetParameters {Color:boolean, Custom:boolean, Enabled:boolean, Parameter:FixedString, Value:any}[]
---@param overrides table
function IconManager:AddCCParametersToOverrides(presetParameters, overrides)
    for _, override in ipairs(presetParameters) do
        overrides[#overrides+1] = {
            Override = override.Enabled,
            Parameter = override.Parameter,
            Preset = true,
            Value = override.Value,
            field_9 = 0
        }
    end
end

---@param jsonPath string File at path should have have EclCharacterIconRequestComponent properties
---@return table|nil
function IconManager:CreateRequestFromJson(jsonPath)
    local file = Ext.IO.LoadFile(jsonPath)
    if file ~= nil then
        local request = Ext.Json.Parse(file)
        request.field_190 = nil
        request.field_1B0 = 1
        return request
    end
end

---@param item EntityHandle
---@return boolean
function IconManager:ShouldIncludeItemInPortrait(character, item)
    local slot = item.Equipable and item.Equipable.Slot
    if slot then
        local equipmentVisuals = character.ClientEquipmentVisuals.Equipment
        local isLoaded = equipmentVisuals[slot] ~= nil and equipmentVisuals[slot].Loaded
        if isLoaded then
            -- Underwear is always loaded if equipped, being hidden by vertex painting.
            -- TODO: Probably should look through character.Visual for underwear vertexmask.
            if slot == "Underwear" then
                local vanityBodyIsLoaded = equipmentVisuals.VanityBody ~= nil and equipmentVisuals.VanityBody.Loaded
                local chestIsLoaded = equipmentVisuals.Breast ~= nil and equipmentVisuals.Breast.Loaded
                return not vanityBodyIsLoaded and not chestIsLoaded
            else
                return isLoaded
            end
        end
    end

    return false
end

---@param character EntityHandle
---@param request EclCharacterIconRequestComponent
function IconManager:BuildRequestArmorSetState(character, request)
    if character.ArmorSetState ~= nil then
        request.ArmorSetState = character.ArmorSetState.State
    else
        request.ArmorSetState = "Normal"
    end
end

-- Adds character creation information to override tables within overrides
---@param character EntityHandle
---@param overrides MaterialParameterPresetsContainer
function IconManager:BuildRequestOverridesFromCharacterCreation(character, overrides)
    if character.CharacterCreationAppearance ~= nil then

        -- Add preset information
        local eyeColor = Ext.StaticData.Get(character.CharacterCreationAppearance.EyeColor, "CharacterCreationEyeColor") --[[@as ResourceCharacterCreationEyeColor]]
        local eyeColorRes = eyeColor ~= nil and Ext.Resource.Get(eyeColor.MaterialPresetUUID, "MaterialPreset") --[[@as ResourceMaterialPresetResource]]
        local secondEyeColor = Ext.StaticData.Get(character.CharacterCreationAppearance.SecondEyeColor, "CharacterCreationEyeColor") --[[@as ResourceCharacterCreationEyeColor]]
        local secondEyeColorRes = secondEyeColor ~= nil and Ext.Resource.Get(secondEyeColor.MaterialPresetUUID, "MaterialPreset") --[[@as ResourceMaterialPresetResource]]
        local hairColor = Ext.StaticData.Get(character.CharacterCreationAppearance.HairColor, "CharacterCreationHairColor") --[[@as ResourceCharacterCreationHairColor]]
        local hairColorRes = hairColor ~= nil and Ext.Resource.Get(hairColor.MaterialPresetUUID, "MaterialPreset") --[[@as ResourceMaterialPresetResource]]
        local skinColor = Ext.StaticData.Get(character.CharacterCreationAppearance.SkinColor, "CharacterCreationSkinColor") --[[@as ResourceCharacterCreationSkinColor]]
        local skinColorRes = skinColor ~= nil and Ext.Resource.Get(skinColor.MaterialPresetUUID, "MaterialPreset") --[[@as ResourceMaterialPresetResource]]

        for _, res in pairs({eyeColorRes, secondEyeColorRes, hairColorRes, skinColorRes}) do
            if res then
                self:AddPresetParametersToOverrides(res.Presets.ScalarParameters, overrides.FloatOverrides)
                self:AddPresetParametersToOverrides(res.Presets.Texture2DParameters, overrides.TextureOverrides)
                self:AddPresetParametersToOverrides(res.Presets.Vector2Parameters, overrides.Vec2Overrides)
                self:AddPresetParametersToOverrides(res.Presets.Vector3Parameters, overrides.Vec3Overrides)
                self:AddPresetParametersToOverrides(res.Presets.VectorParameters, overrides.Vec4Overrides)
                self:AddPresetParametersToOverrides(res.Presets.VirtualTextureParameters, overrides.VirtualTextureOverrides)
            end
        end

        -- Add selectable CC option information
        for _, element in pairs(character.CharacterCreationAppearance.Elements) do
            local ccMaterial = Ext.StaticData.Get(element.Material, "CharacterCreationAppearanceMaterial") --[[@as ResourceCharacterCreationAppearanceMaterial]]
            local materialPreset = ccMaterial ~= nil and Ext.Resource.Get(ccMaterial.MaterialPresetUUID, "MaterialPreset") --[[@as ResourceMaterialPresetResource]]
            if materialPreset then
                local materialPresets = materialPreset.Presets
                local colorDefinition = Ext.StaticData.Get(element.Color, "ColorDefinition") --[[@as ResourceCharacterCreationColor]]
                local rgb = colorDefinition ~= nil and self:sRGBToLinearRGB(colorDefinition.Color) or {0,0,0}

                if ccMaterial.MaterialTypeName == "Tattoo" then
                    local newParam = {
                        Override = true,
                        Parameter = "TattooColorB",
                        Preset = true,
                        field_9 = 0,
                        Value = rgb
                    }
                    overrides.Vec3Overrides[#overrides.Vec3Overrides+1] = newParam
                end

                for _, param in ipairs(materialPresets.ScalarParameters) do
                    local newParam = {
                        Override = true,
                        Parameter = param.Parameter,
                        Preset = true,
                        field_9 = 0
                    }
                    --TODO: Roughness
                    if param.Parameter:find("Intensity$") then
                        newParam.Value = element.ColorIntensity
                    elseif param.Parameter:find("Color") then
                        newParam.Value = element.ColorIntensity -- TODO: Verify
                    elseif param.Parameter:find("Metalness$") then
                        newParam.Value = element.MetallicTint
                    else
                        newParam.Value = param.Value
                    end
                    overrides.FloatOverrides[#overrides.FloatOverrides+1] = newParam
                end

                for _, param in pairs(materialPresets.Texture2DParameters) do
                    local newParam = {
                        Override = true,
                        Parameter = param.Parameter,
                        Preset = true,
                        field_9 = 0
                    }
                    newParam.Value = param.Value
                    overrides.TextureOverrides[#overrides.TextureOverrides+1] = newParam
                end

                for _, param in pairs(materialPresets.Vector2Parameters) do
                    local newParam = {
                        Override = true,
                        Parameter = param.Parameter,
                        Preset = true,
                        field_9 = 0
                    }
                    newParam.Value = param.Value
                    overrides.Vec2Overrides[#overrides.Vec2Overrides+1] = newParam
                end

                for _, param in pairs(materialPresets.Vector3Parameters) do
                    local newParam = {
                        Override = true,
                        Parameter = param.Parameter,
                        Preset = true,
                        field_9 = 0
                    }
                    if param.Parameter:find("Intensity$") then
                        newParam.Value = {0, 0, element.ColorIntensity}
                    elseif param.Parameter:find("Color") then
                        newParam.Value = rgb -- TODO: Verify
                    else
                        newParam.Value = param.Value
                    end
                    overrides.Vec3Overrides[#overrides.Vec3Overrides+1] = newParam
                end

                for _, param in pairs(materialPresets.VectorParameters) do
                    local newParam = {
                        Override = true,
                        Parameter = param.Parameter,
                        Preset = true,
                        field_9 = 0
                    }
                    if param.Parameter:find("Intensity$") then
                        newParam.Value = {0, 0, element.ColorIntensity, 0}
                    elseif param.Parameter:find("Color") then
                        newParam.Value = {rgb[1], rgb[2], rgb[3], 1} -- TODO: Verify
                    else
                        newParam.Value = param.Value
                    end
                    overrides.Vec4Overrides[#overrides.Vec4Overrides+1] = newParam
                end

                for _, param in pairs(materialPresets.VirtualTextureParameters) do
                    local newParam = {
                        Override = true,
                        Parameter = param.Parameter,
                        Preset = true,
                        field_9 = 0
                    }
                    newParam.Value = param.Value
                    overrides.VirtualTextureOverrides[#overrides.VirtualTextureOverrides+1] = newParam
                end

            end
        end
    end
end

-- Script overrides, e.g. selune shart, ersatz eye, illithid
---@param character EntityHandle
---@param overrides MaterialParameterPresetsContainer
function IconManager:AddRequestOverridesFromScriptMaterialOverrides(character, overrides)
    local scriptOverrides = character.MaterialParameterOverride
    if scriptOverrides ~= nil then
        -- TODO: Move this somewhere sensible
        local ParamTypeOverrideTypes = {
            Integer = "FloatOverrides",
            Float = "FloatOverrides",
            Float2 = "Vec2Overrides",
            Float3 = "Vec3Overrides",
            Float4 = "Vec4Overrides",
            FixedString = "TextureOverrides", --TODO: Verify
        }

        for _, guid in pairs(scriptOverrides.field_0) do
            local presetOverride = Ext.StaticData.Get(guid, "ScriptMaterialPresetOverride") --[[@as ResourceScriptMaterialPresetOverride]]
            for _, parameterGuid in pairs(presetOverride.ParameterUuids) do
                local scriptParameter = Ext.StaticData.Get(parameterGuid, "ScriptMaterialParameterOverride") --[[@as ResourceScriptMaterialParameterOverride]]
                local paramType = scriptParameter.ParameterType
                local overrideType = paramType ~= "" and ParamTypeOverrideTypes[paramType]
                if overrideType then
                    local overrideGroup = overrides[overrideType]
                    local foundParam = false
                    for _, override in ipairs(overrideGroup) do
                        if override.Parameter == scriptParameter.ParameterName then
                            override.Value = scriptParameter.ParameterValue
                            foundParam = true
                            break
                        end
                    end

                    if not foundParam then
                        overrideGroup[#overrideGroup+1] = {
                            Override = true,
                            Parameter = scriptParameter.ParameterName,
                            Preset = true,
                            Value = scriptParameter.ParameterValue,
                            field_9 = 0
                        }
                    end
                end
            end
        end
    end
end

---@param character EntityHandle
---@param request EclCharacterIconRequestComponent
function IconManager:BuildRequestEquipment(character, request)
    local equipment = {}
    local equippedItems = character.InventoryOwner.Inventories[#character.InventoryOwner.Inventories]

    for _, itemEntry in pairs(equippedItems.InventoryContainer.Items) do
        local item = itemEntry.Item
        if self:ShouldIncludeItemInPortrait(character, item) then
            local template = item.OriginalTemplate ~= nil and item.OriginalTemplate.OriginalTemplate ~= "" and Ext.Template.GetTemplate(item.OriginalTemplate.OriginalTemplate) --[[@as ItemTemplate]]
            if template then

                -- Fix stinky templates who don't recurse on their visuals via stats
                local statsEntry = Ext.Stats.Get(template.Stats)
                if statsEntry.RootTemplate ~= "" and statsEntry.RootTemplate ~= item.OriginalTemplate.OriginalTemplate then
                    self.StatsOverrides[template.Stats] = statsEntry.RootTemplate
                    statsEntry.RootTemplate = item.OriginalTemplate.OriginalTemplate
                end

                equipment[#equipment+1] = template.Name
                equipment[#equipment+1] = template.Stats

                -- Color support
                local equipmentVisual = character.ClientEquipmentVisuals.Equipment[item.Equipable.Slot]
                if equipmentVisual ~= nil and equipmentVisual.VisualData ~= nil then

                    -- Flatten visual params on top of dye params
                    local colorParameters = {}
                    if item.ItemDye ~= nil then
                        local dyeResource = Ext.Resource.Get(item.ItemDye.Color, "MaterialPreset")
                        if dyeResource ~= nil then
                            colorParameters = Ext.Types.Serialize(dyeResource.Presets.Vector3Parameters)
                        end
                    end

                    local visualParams = Ext.Types.Serialize(equipmentVisual.VisualData.Vector3Parameters)
                    for _, visualParam in ipairs(visualParams) do
                        local matchedParam = false
                        for j, colorParam in ipairs(colorParameters) do
                            if visualParam.Parameter == colorParam.Parameter then
                                colorParameters[j] = visualParam
                                matchedParam = true
                                break
                            end
                        end

                        if not matchedParam then
                            colorParameters[#colorParameters+1] = visualParam
                        end
                    end


                    local hasVisualSet = template.Equipment ~= nil and template.Equipment.VisualSet ~= nil
                    if hasVisualSet and not IconManager.VisualSetParams[template.Id] then
                        local overrideParams = Ext.Types.Serialize(template.Equipment.VisualSet.MaterialOverrides.Vector3Parameters)
                        IconManager.VisualSetParams[template.Id] = overrideParams

                        local newOverrideParams = {}
                        for _, setParam in ipairs(overrideParams) do
                            local matchedParam = false
                            for _, colorParam in ipairs(colorParameters) do
                                if setParam.Parameter == colorParam.Parameter then
                                    newOverrideParams[#newOverrideParams+1] = {
                                        Value = colorParam.Value,
                                        Custom = colorParam.Custom,
                                        Enabled = setParam.Enabled,
                                        Color = colorParam.Color,
                                        Parameter = colorParam.Parameter
                                    }
                                    matchedParam = true
                                    break
                                end
                            end

                            if not matchedParam then
                                newOverrideParams[#newOverrideParams+1] = setParam
                            end
                        end

                        Ext.Types.Unserialize(template.Equipment.VisualSet.MaterialOverrides.Vector3Parameters, newOverrideParams)

                        for _, preset in pairs(template.Equipment.VisualSet.MaterialOverrides.MaterialPresets) do
                            if preset.MaterialPresetResource ~= "00000000-0000-0000-0000-000000000000" and
                            not IconManager.MaterialPresetParams[preset.MaterialPresetResource] then
                                local presetResource = Ext.Resource.Get(preset.MaterialPresetResource, "MaterialPreset")
                                local presetParams = Ext.Types.Serialize(presetResource.Presets.Vector3Parameters)
                                IconManager.MaterialPresetParams[preset.MaterialPresetResource] = presetParams

                                for _, presetParam in ipairs(presetResource.Presets.Vector3Parameters) do
                                    for _, colorParam in ipairs(colorParameters) do
                                        if presetParam.Parameter == colorParam.Parameter then
                                            presetParam.Value = colorParam.Value
                                            break
                                        end
                                    end
                                end
                            end
                        end
                    end
                    
                end
            else
                equipment[#equipment+1] = item.Data.StatsId
            end
        end
    end

    request.Equipment = equipment
end

---@param character EntityHandle
---@param request EclCharacterIconRequestComponent
function IconManager:BuildRequestTemplate(character, request)
    request.Template = character.ClientCharacter.OriginalTemplate.Id
end

---@param character EntityHandle
---@param request EclCharacterIconRequestComponent
function IconManager:BuildRequestTrigger(character, request)
    request.Trigger = character.ClientCharacter.OriginalTemplate.GeneratePortrait
end

---@param character EntityHandle
---@param request EclCharacterIconRequestComponent
function IconManager:BuildRequestVisual(character, request)
    request.Visual = Ext.Resource.Get(character.ClientCharacter.OriginalTemplate.CharacterVisualResourceID, "CharacterVisual").BaseVisual
end

---@param character EntityHandle
---@param overrides MaterialParameterPresetsContainer
function IconManager:BuildRequestVisualSetOverrides(character, overrides)
    local characterVisualResource = Ext.Resource.Get(character.ClientCharacter.OriginalTemplate.CharacterVisualResourceID, "CharacterVisual") --[[@as ResourceCharacterVisualResource]]
    local visualSetInfo = characterVisualResource.VisualSet

    self:AddPresetParametersToOverrides(visualSetInfo.MaterialOverrides.ScalarParameters, overrides.FloatOverrides)
    self:AddPresetParametersToOverrides(visualSetInfo.MaterialOverrides.Texture2DParameters, overrides.TextureOverrides)
    self:AddPresetParametersToOverrides(visualSetInfo.MaterialOverrides.Vector2Parameters, overrides.Vec2Overrides)
    self:AddPresetParametersToOverrides(visualSetInfo.MaterialOverrides.Vector3Parameters, overrides.Vec3Overrides)
    self:AddPresetParametersToOverrides(visualSetInfo.MaterialOverrides.VectorParameters, overrides.Vec4Overrides)
    self:AddPresetParametersToOverrides(visualSetInfo.MaterialOverrides.VirtualTextureParameters, overrides.VirtualTextureOverrides)
end

---@param character EntityHandle
---@param request EclCharacterIconRequestComponent
---@param ignoreScriptOverrides? boolean
function IconManager:BuildRequestVisualSet(character, request, ignoreScriptOverrides)
    local characterVisualResource = Ext.Resource.Get(character.ClientCharacter.OriginalTemplate.CharacterVisualResourceID, "CharacterVisual") --[[@as ResourceCharacterVisualResource]]
    local visualSetInfo = characterVisualResource.VisualSet
    local visualSet = {
        LocatorAttachments = {},
        MaterialOverrides = {},
        MaterialParameters = {
            FloatOverrides = {},
            TextureOverrides = {},
            Vec2Overrides = {},
            Vec3Overrides = {},
            Vec4Overrides = {},
            VirtualTextureOverrides = {},
            Presets = {},
            field_60 = ""
        },
        MaterialRemaps = {},
        Materials = {},
        VisualSlots = {},
    }

    self:BuildRequestOverridesFromCharacterCreation(character, visualSet.MaterialParameters)

    visualSet.BodySetVisual = visualSetInfo.BodySetVisual

    --TODO: Verify
    for i, attachment in ipairs(visualSetInfo.LocatorAttachments) do
        visualSet.LocatorAttachments[i] = {
            LocatorName = attachment.LocatorId,
            DisplayName = attachment.VisualResource
        }
    end

    --TODO: Verify
    for k,v in pairs(visualSetInfo.RealMaterialOverrides) do
        visualSet.MaterialOverrides[k] = v
    end

    for k, preset in pairs(visualSetInfo.MaterialOverrides.MaterialPresets) do
        visualSet.MaterialParameters.Presets[k] = {
            CCPreset = preset.MaterialPresetResource,
            GroupName = preset.GroupName,
            field_8 = 0 --TODO: What is this? seemingly irrelevant bitfield
        }
    end

    self:BuildRequestVisualSetOverrides(character, visualSet.MaterialParameters)
    
    for k,v in pairs(visualSetInfo.MaterialRemaps) do
        visualSet.MaterialRemaps[k] = v
    end

    --[[ TODO: transcribe from 
    --- @field Materials table<FixedString, MaterialParameterPresetsContainer>
        to
    --- @field Materials table<FixedString, ResourcePresetData>
    --visualSet.Materials = {}
    --]]
    

    visualSet.ShowEquipmentVisuals = visualSetInfo.ShowEquipmentVisuals

    visualSet.VisualSet = ""


    -- It's possible to scrape slot information through visualSetInfo.Slots but it can miss out on overrides
    for _, attachment in ipairs(character.ClientCharacter.ClothVisual.Attachments) do
        if attachment.Flags & Ext.Enums.VisualAttachmentFlags.VisualSet ~= 0 then
            local visResource = attachment.Visual.VisualResource
            if visResource.Slot ~= "NakedBody" then
                visualSet.VisualSlots[#visualSet.VisualSlots+1] = {
                    Slot = visResource.Slot,
                    Visual = visResource.Guid,
                    field_8 = visResource.AttachBone
                }
            end
        end
    end

    if not ignoreScriptOverrides then
        self:AddRequestOverridesFromScriptMaterialOverrides(character, visualSet.MaterialParameters)
    end
    
    request.VisualSet = visualSet

end

---@param character EntityHandle
---@param ignoreScriptOverrides? boolean
---@return table|nil
function IconManager:BuildRequestForCharacter(character, ignoreScriptOverrides)
    local request = {} --[[@as EclCharacterIconRequestComponent]]
    self:BuildRequestArmorSetState(character, request)
    self:BuildRequestEquipment(character, request)
    self:BuildRequestTemplate(character, request)
    self:BuildRequestTrigger(character, request)
    self:BuildRequestVisual(character, request)
    self:BuildRequestVisualSet(character, request, ignoreScriptOverrides)
    request.field_1B0 = 1

    return request
end

---@param request table Should have EclCharacterIconRequestComponent properties
function IconManager:SubmitRequest(request)
    local sys = Ext.System[self.System]
    sys.SessionCount = sys.SessionCount + 1
    local reqEntity = Ext.Entity.Create()
    local comp = reqEntity:CreateComponent("ClientCharacterIconRequest")
    for k in pairs(request) do
        comp[k] = request[k]
    end
end

---@param entity EntityHandle
---@param icon ScratchBuffer webp binary
function IconManager:SetIcon(entity, icon)
    local customIconComp = entity.CustomIcon or entity:CreateComponent("CustomIcon")
    customIconComp.Icon = icon
    customIconComp.Source = 0
    entity:Replicate("CustomIcon")

    local iconComp = entity.Icon or entity:CreateComponent("Icon")
    iconComp.Icon = "CustomIconSet"
    entity:Replicate("Icon")
end

if Ext.IsServer() then
    IconManager.Net:SetHandler(function(data)
        IconManager:SetIcon(Ext.Entity.Get(data.Target), data.Icon)
    end)
end

if Ext.IsClient() then
    Ext.Entity.OnCreateDeferred("ClientCharacterIconResult", function()
        IconManager:RevertColorEdits()
    end)
end


-- Client only
---@param target? Guid
Ext.RegisterConsoleCommand("RequestIcon", function(_, target, ignoreScriptOverrides)
    target = target or _C().Uuid.EntityUuid
    local targetEntity = Ext.Entity.Get(target)
    if targetEntity ~= nil then
        local request = IconManager:BuildRequestForCharacter(targetEntity, ignoreScriptOverrides)
        if request ~= nil then
            IconManager:SubmitRequest(request)

            Ext.Entity.OnCreateDeferredOnce("ClientCharacterIconResult", function (entity)
                Ext.System.ClientCharacterIconRender.SessionCount = math.max(Ext.System.ClientCharacterIconRender.SessionCount - 1, 0)
                IconManager.Net:SendToServer({
                    Icon = entity.ClientCharacterIconResult.Icon,
                    Target = target
                })
            end)
        end
    end
end)

-- Client only
---@param target? Guid
Ext.RegisterConsoleCommand("SaveIcon", function(_, target)
    local targetEntity = target ~= nil and Ext.Entity.Get(target) or _C()
    IconManager:SaveIcon(targetEntity)
end)

-- Client only
---@param target? Guid
---@param iconPath string should be a .webp in %localappdata%\Larian Studios\Baldur's Gate 3\Script Extender
Ext.RegisterConsoleCommand("LoadIcon", function(_, target, iconPath)
    local targetEntity = target ~= nil and target ~= "" and Ext.Entity.Get(target) or _C()
    local icon = Ext.IO.LoadFile(iconPath)
    IconManager.Net:SendToServer({
        Icon = icon,
        Target = targetEntity.Uuid.EntityUuid
    })
end)

-- Client only
Ext.RegisterConsoleCommand("LogRequest", function()
    IconManager:LogNextRequest()
end)