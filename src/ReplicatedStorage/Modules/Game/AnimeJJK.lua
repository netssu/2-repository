------------------//VARIABLES
local AnimeJJK = {
	worldId = "JJK",
	displayName = "Jujutsu Kaisen",
	initialUpgradeState = {
		stage = 0,
		storyRuns = 0,
		unlockedRepeatables = {"LookAround", "CryLoudly", "Sleep", "WiggleAround"},
		removedRepeatables = {},
		permanent = {
			cursedBody = 0,
			cursedControl = 0,
			cooldownFocus = 0,
		},
	},
	repeatableOrder = {
		"LookAround",
		"CryLoudly",
		"Sleep",
		"WiggleAround",
		"WanderHalls",
		"ShadowDrill",
		"ExorciseGrade4",
		"ArchiveResearch",
		"BarrierPractice",
		"SquadPatrol",
		"BlackFlashFocus",
	},
	equipmentSlots = {
		"head",
		"neck",
		"shirt",
		"pants",
		"weapon",
		"enchantment",
	},
	upgrades = {
		cursedBody = {
			maxLevel = 10,
			baseSoulCost = 75,
			shardCostEvery = 5,
			hpPerLevel = 5,
			defPerLevel = 0.75,
		},
		cursedControl = {
			maxLevel = 10,
			baseSoulCost = 90,
			shardCostEvery = 5,
			atkPerLevel = 1,
			curseEnergyPerLevel = 3,
		},
		cooldownFocus = {
			maxLevel = 5,
			baseSoulCost = 150,
			shardCostEvery = 3,
			speedPerLevel = 0.5,
			cooldownReductionPerLevel = 0.03,
		},
	},
}

------------------//INIT
return AnimeJJK
