------------------//VARIABLES
local AbilityDictionary = {}

export type AbilityDefinition = {
	id: string,
	displayName: string,
	worldId: string,
	unlockLevel: number,
	cooldown: number,
	cost: number,
	multiplier: number,
	abilityType: string,
	startingAbility: boolean,
	moralPath: string?,
	description: string?,
}

AbilityDictionary.items = {
	JJK = {
		{
			id = "CursedStrike",
			displayName = "Cursed Strike",
			worldId = "JJK",
			unlockLevel = 1,
			cooldown = 2,
			cost = 0,
			multiplier = 1.1,
			abilityType = "Active",
			startingAbility = true,
			description = "A basic cursed-energy strike.",
		},
		{
			id = "CursedEnergySurge",
			displayName = "Cursed Energy Surge",
			worldId = "JJK",
			unlockLevel = 10,
			cooldown = 15,
			cost = 10,
			multiplier = 1.5,
			abilityType = "Active",
			startingAbility = false,
			description = "ATK x1.5 on the next hit.",
		},
		{
			id = "BlackFlash",
			displayName = "Black Flash",
			worldId = "JJK",
			unlockLevel = 25,
			cooldown = 30,
			cost = 20,
			multiplier = 2,
			abilityType = "Active",
			startingAbility = false,
			description = "ATK x2.0, or x3.0 while cursed energy is overflowing.",
		},
		{
			id = "DivergentFist",
			displayName = "Divergent Fist",
			worldId = "JJK",
			unlockLevel = 50,
			cooldown = 45,
			cost = 25,
			multiplier = 1.8,
			abilityType = "Active",
			startingAbility = false,
			description = "AoE strike against all enemies.",
		},
		{
			id = "CursedVeil",
			displayName = "Cursed Veil",
			worldId = "JJK",
			unlockLevel = 100,
			cooldown = 90,
			cost = 30,
			multiplier = 1.4,
			abilityType = "Active",
			startingAbility = false,
			moralPath = "Protector",
			description = "Protector ability. Absorbs part of incoming damage.",
		},
		{
			id = "MalevolentShrine",
			displayName = "Malevolent Shrine",
			worldId = "JJK",
			unlockLevel = 100,
			cooldown = 90,
			cost = 35,
			multiplier = 2.5,
			abilityType = "Active",
			startingAbility = false,
			moralPath = "Conqueror",
			description = "Conqueror ability. Heavy AoE and vulnerability debuff.",
		},
		{
			id = "HollowPurple",
			displayName = "Hollow Purple",
			worldId = "JJK",
			unlockLevel = 200,
			cooldown = 120,
			cost = 50,
			multiplier = 4,
			abilityType = "Active",
			startingAbility = false,
			description = "ATK x4.0 single target.",
		},
		{
			id = "DomainExpansion",
			displayName = "Domain Expansion",
			worldId = "JJK",
			unlockLevel = 500,
			cooldown = 300,
			cost = 100,
			multiplier = 6,
			abilityType = "Active",
			startingAbility = false,
			description = "ATK x6.0 and brief invincibility.",
		},
	},
}

------------------//FUNCTIONS
function AbilityDictionary.get_world_abilities(worldId: string): {AbilityDefinition}
	return AbilityDictionary.items[worldId] or {}
end

function AbilityDictionary.get_ability(worldId: string, abilityId: string): AbilityDefinition?
	for _, ability in AbilityDictionary.get_world_abilities(worldId) do
		if ability.id == abilityId then
			return ability
		end
	end
	return nil
end

function AbilityDictionary.can_unlock(ability: AbilityDefinition, data: any): boolean
	if data.level < ability.unlockLevel then
		return false
	end

	if ability.moralPath and data.moralPath ~= ability.moralPath then
		return false
	end

	return true
end

function AbilityDictionary.get_starting_abilities(worldId: string): {string}
	local abilities = AbilityDictionary.get_world_abilities(worldId)
	local startingAbilities = {}

	for _, ability in abilities do
		if ability.startingAbility then
			table.insert(startingAbilities, ability.id)
		end
	end

	return startingAbilities
end

function AbilityDictionary.get_default_equipped(worldId: string): {string}
	local startingAbilities = AbilityDictionary.get_starting_abilities(worldId)
	local equippedAbilities = {}

	for _, abilityId in startingAbilities do
		if #equippedAbilities < 3 then
			table.insert(equippedAbilities, abilityId)
		end
	end

	return equippedAbilities
end

------------------//INIT
return AbilityDictionary
