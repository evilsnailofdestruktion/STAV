local EM = {}

local NewElements = {}



--- Adds new element to CharacterCreationAppearance. Name is just for convenience or something
--- entity and elementName are optional
function EM.AddNewElementToCharacter(entity, elementName)
	local entity = entity or _C()
	local elementName = elementName or 'Unknown'

	local uuid = entity.Uuid.EntityUuid
	local CCA  = entity.CharacterCreationAppearance
	if CCA then
		local Elements       = CCA.Elements
		local availableIndex = #Elements + 1

		--- Just to keep track or something. This is optional (Haven't checked it actaully)
		NewElements[uuid] = {ElementName = elementName, ElementIndex = availableIndex}

		--- Adds new element here. Persists if done on server.
		entity.CharacterCreationAppearance.Elements[availableIndex] = {}

		return NewElements[uuid]
	end
end

--- Alias for the console
function AddElem() return EM.AddNewElementToCharacter() end



function EM.AddNewElementToCCDummy()
	assert(false, 'AddNewElementToCCDummy is not implemented')
end





--- Some stuff for the console
--- ff46 is my test material, use 318f, it is Snail's
function AddMat(xd)
	if xd == 1 then
		_C().CharacterCreationAppearance.Elements[10].Material = 'ff46dcab-747b-4e0d-86a3-ad7005c14edf'
	else
		_C().CharacterCreationAppearance.Elements[10].Material = '318ff3f1-b2c6-4097-b8c3-c48c29d22af5'
	end
end



function GStat()
	return Ext.StaticData.Get('ff46dcab-747b-4e0d-86a3-ad7005c14edf', 'CharacterCreationAppearanceMaterial')
end



function GRes()
	return Ext.Resource.Get('bbffc283-f29d-2b11-bcbd-17352dac2e19', 'MaterialPreset')
end



function Rep()
	_C():Replicate('CharacterCreationAppearance')
end



function CCA()
	return _C().CharacterCreationAppearance
end



--- So what was my implementation (nothing fancy, all classic stuff, except for adding new element)
--- Just my thought process

--- Add new Element to character - EM.AddNewElementToCharacter()

--- Assign to the Element Snail's CharacterCreationAppearanceMaterial (CCAM) - CharacterCreationAppearance.Elements[newElement].Material = CCAM

--- If there's a character with this CCAM assign next one :mhm:

--- To edit the MaterialPreset that linked to current CCAM we need resource's uuid. Check GStat().ResourceUUID (LOL I DON"T REMBEMR IF IT"S ResouceUUID, but it is somewhere there)

--- When you got MaterialPreset uuid, check GRes(), then just edit the resource, when you've made the changes, just Replicate('CharacterCreationAppearance') character (fudge, I think ther's a way to do without replication, but I don't remember, I think CCEE does it or something or I'm remember)

--- Store parameters and their values in UserVars

--- Since new elements persis whem you load save file, just apply stored stuff to MaterialPreset on gamesession or something

--- Since it's a new Element, the game won't validate it, and won't let confirm in the mirror. I was thinking instead of copying ConfirmWorkaround() from CCEE, make something similar but
--- add own Confirm button to this mod's UI that will for a moment remove new Element, :Execute() noesis working confirm button, and then add the element back

--- Not sure how mirror dummies work anymore, but you will figure



--- How CharacterCreationAppearanceMaterial work, and how Elements work

--- Elements are CC stuff that you know (Tattoo, Makeup, Scales, Lips makeup, etc), you can't apply more than one element of the same type. For example, you can't have two elements with type Tattoo, only one will work OR
--- for example you added own MaterialPreset that has MelaninAmount, it won't work because SkinPreset already has MelaninAmount. If you want yours to work, you need to zero uuid SkinPreset or Tattoo (0000-0000...)

--- You can also use a different name for paramters, then you can add as much as you want, you can have TattoIndex and new TattooIndex_2, both will work as long as they have different CCAM types

--- Unfortunately, there's no way to add new Element types, you are limited to default ones, since it's not possible to have two Tattoo types, we decided to use Passive (Scales), cuz they are not that common. If you can find a better way without relying on jank like :SetScalar() etc, would be cool; so
--- all CCAM should have type Passive
