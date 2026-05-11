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
	clan: string?,
	fruitType: string?,
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
			description = "ATK x2.0, or x3.0 while Cursed Energy is overflowing.",
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
	Naruto = {
		{
			id = "BasicKunai",
			displayName = "Basic Kunai",
			worldId = "Naruto",
			unlockLevel = 1,
			cooldown = 2,
			cost = 0,
			multiplier = 1,
			abilityType = "Active",
			startingAbility = true,
			description = "A basic ninja attack.",
		},
		{
			id = "CloneJutsu",
			displayName = "Clone Jutsu",
			worldId = "Naruto",
			unlockLevel = 10,
			cooldown = 15,
			cost = 0,
			multiplier = 2,
			abilityType = "Active",
			startingAbility = false,
			description = "Doubles hit count for the next attacks.",
		},
		{
			id = "Rasengan",
			displayName = "Rasengan",
			worldId = "Naruto",
			unlockLevel = 25,
			cooldown = 30,
			cost = 0,
			multiplier = 2.5,
			abilityType = "Active",
			startingAbility = false,
			description = "ATK x2.5 single target.",
		},
		{
			id = "SageMode",
			displayName = "Sage Mode",
			worldId = "Naruto",
			unlockLevel = 100,
			cooldown = 60,
			cost = 0,
			multiplier = 1.5,
			abilityType = "Active",
			startingAbility = false,
			description = "All stats +50% during battle.",
		},
		{
			id = "SagesGuard",
			displayName = "Sage's Guard",
			worldId = "Naruto",
			unlockLevel = 100,
			cooldown = 80,
			cost = 0,
			multiplier = 1.2,
			abilityType = "Active",
			startingAbility = false,
			moralPath = "Protector",
			description = "Protector ability. Halves incoming damage.",
		},
		{
			id = "KillingIntent",
			displayName = "Killing Intent",
			worldId = "Naruto",
			unlockLevel = 100,
			cooldown = 80,
			cost = 0,
			multiplier = 1.4,
			abilityType = "Active",
			startingAbility = false,
			moralPath = "Conqueror",
			description = "Conqueror ability. Reduces enemy speed and defense.",
		},
		{
			id = "TailedBeastMode",
			displayName = "Tailed Beast Mode",
			worldId = "Naruto",
			unlockLevel = 300,
			cooldown = 180,
			cost = 0,
			multiplier = 4,
			abilityType = "Active",
			startingAbility = false,
			description = "ATK x4.0 with AoE shockwave.",
		},
		{
			id = "SharinganPerception",
			displayName = "Sharingan Perception",
			worldId = "Naruto",
			unlockLevel = 1,
			cooldown = 0,
			cost = 0,
			multiplier = 1,
			abilityType = "Passive",
			startingAbility = false,
			clan = "Uchiha",
			description = "+15% critical chance.",
		},
		{
			id = "SixPathsMode",
			displayName = "Six Paths Mode",
			worldId = "Naruto",
			unlockLevel = 600,
			cooldown = 300,
			cost = 0,
			multiplier = 3,
			abilityType = "Active",
			startingAbility = false,
			description = "All stats x3.",
		},
	},
	OnePiece = {
		{
			id = "BasicCutlass",
			displayName = "Basic Cutlass",
			worldId = "OnePiece",
			unlockLevel = 1,
			cooldown = 2,
			cost = 0,
			multiplier = 1,
			abilityType = "Active",
			startingAbility = true,
			description = "A basic pirate attack.",
		},
		{
			id = "DevilFruitAwakening",
			displayName = "Devil Fruit Awakening",
			worldId = "OnePiece",
			unlockLevel = 10,
			cooldown = 0,
			cost = 0,
			multiplier = 1,
			abilityType = "Passive",
			startingAbility = false,
			description = "Unlocks the selected fruit power.",
		},
		{
			id = "ObservationHaki",
			displayName = "Haki - Observation",
			worldId = "OnePiece",
			unlockLevel = 25,
			cooldown = 20,
			cost = 0,
			multiplier = 1.1,
			abilityType = "Active",
			startingAbility = false,
			description = "+25% dodge chance briefly.",
		},
		{
			id = "ArmamentHaki",
			displayName = "Haki - Armament",
			worldId = "OnePiece",
			unlockLevel = 50,
			cooldown = 35,
			cost = 0,
			multiplier = 1.4,
			abilityType = "Active",
			startingAbility = false,
			description = "ATK x1.4 and DEF bonus.",
		},
		{
			id = "CrewShield",
			displayName = "Crew Shield",
			worldId = "OnePiece",
			unlockLevel = 100,
			cooldown = 90,
			cost = 0,
			multiplier = 1.3,
			abilityType = "Active",
			startingAbility = false,
			moralPath = "Protector",
			description = "Protector ability. Doubles crew bonuses.",
		},
		{
			id = "ConquerorsDeclaration",
			displayName = "Conqueror's Declaration",
			worldId = "OnePiece",
			unlockLevel = 100,
			cooldown = 90,
			cost = 0,
			multiplier = 1.6,
			abilityType = "Active",
			startingAbility = false,
			moralPath = "Conqueror",
			description = "Conqueror ability. Stuns enemies briefly.",
		},
		{
			id = "ParameciaAwakening",
			displayName = "Paramecia Awakening",
			worldId = "OnePiece",
			unlockLevel = 200,
			cooldown = 120,
			cost = 0,
			multiplier = 3.5,
			abilityType = "Active",
			startingAbility = false,
			fruitType = "Paramecia",
			description = "ATK x3.5 and speed surge.",
		},
		{
			id = "ElementalBurst",
			displayName = "Elemental Burst",
			worldId = "OnePiece",
			unlockLevel = 200,
			cooldown = 120,
			cost = 0,
			multiplier = 3,
			abilityType = "Active",
			startingAbility = false,
			fruitType = "Logia",
			description = "ATK x3.0 and enemy DEF reduction.",
		},
		{
			id = "FullBeastForm",
			displayName = "Full Beast Form",
			worldId = "OnePiece",
			unlockLevel = 200,
			cooldown = 120,
			cost = 0,
			multiplier = 2.5,
			abilityType = "Active",
			startingAbility = false,
			fruitType = "Zoan",
			description = "HP x2 and ATK x2.5.",
		},
		{
			id = "ConquerorsHaki",
			displayName = "Conqueror's Haki",
			worldId = "OnePiece",
			unlockLevel = 500,
			cooldown = 300,
			cost = 0,
			multiplier = 2,
			abilityType = "Active",
			startingAbility = false,
			description = "Stuns enemies and leaves a permanent aura.",
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

	if ability.clan and (not data.naruto or data.naruto.clan ~= ability.clan) then
		return false
	end

	if ability.fruitType and (not data.onePiece or data.onePiece.fruitType ~= ability.fruitType) then
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
