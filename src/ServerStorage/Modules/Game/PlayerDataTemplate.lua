------------------//SERVICES
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------//VARIABLES
local replicatedModules: Folder = ReplicatedStorage:WaitForChild("Modules") :: Folder
local gameModules: Folder = replicatedModules:WaitForChild("Game") :: Folder
local GameConfig = require(gameModules:WaitForChild("GameConfig") :: ModuleScript)
local AnimeRegistry = require(gameModules:WaitForChild("AnimeRegistry") :: ModuleScript)

local PlayerDataTemplate = {}

export type PlayerData = any

local function clone_defaults(source: any): any
	if typeof(source) ~= "table" then
		return source
	end

	local copy = {}
	for key, value in source do
		copy[key] = clone_defaults(value)
	end
	return copy
end

local function get_world_upgrade_defaults(worldId: string): any
	local animeModule = AnimeRegistry.get(worldId)
	if animeModule and animeModule.initialUpgradeState then
		return clone_defaults(animeModule.initialUpgradeState)
	end

	return {
		stage = 0,
		storyRuns = 0,
		activeRepeatable = "",
		unlockedRepeatables = {},
		removedRepeatables = {},
		permanent = {},
	}
end

local TEMPLATE: PlayerData = {
	world = "JJK",
	level = 1,
	exp = 0,
	dataVersion = GameConfig.DATA_VERSION,
	createdAt = 0,
	currentAction = "Idle",
	stats = {
		hp = 100,
		atk = 10,
		def = 5,
		spd = 5,
		luck = 1,
	},
	cultivation = {
		qi = 0,
		qiRequired = 100,
		realmIndex = 1,
		stage = 1,
		talent = 1,
		affinity = "None",
		manual = "None",
		manualMultiplier = 1,
	},
	abilitiesUnlocked = {
		"CursedStrike",
	},
	abilitiesEquipped = {
		"CursedStrike",
	},
	abilityCooldowns = {},
	moralPath = nil,
	storyQuests = {},
	loreLogs = {},
	rivalStage = 0,
	titles = {
		"Chosen",
	},
	activeTitle = "Chosen",
	pinnedTitles = {},
	jjk = {
		curseEnergy = 0,
	},
	upgrades = {
		JJK = get_world_upgrade_defaults("JJK"),
		Naruto = get_world_upgrade_defaults("Naruto"),
		OnePiece = get_world_upgrade_defaults("OnePiece"),
	},
	naruto = nil,
	onePiece = nil,
	rebirthCount = 0,
	peakImmortalityPct = 0,
	lastLogin = 0,
	loginStreak = 0,
	dailyQuestsDone = {},
	dailyQuestsProgress = {
		Train200 = 0,
		Win5Battles = 0,
		Play30Minutes = 0,
	},
	rebirthShards = 0,
	worldSouls = 0,
	divineTokens = 0,
	boosts = {},
	shopPurchases = {},
	training = {
		focus = 0,
		totalTaps = 0,
		burstEndsAt = 0,
		bodyXp = 0,
		techniqueXp = 0,
	},
	tutorial = {
		step = 0,
		complete = false,
		skipped = false,
	},
	battle = {
		selectedTier = 1,
		sessionSouls = 0,
		reviveCharges = 0,
		lastResult = "",
		lastEnemy = "",
		lastGodTaunt = "",
	},
	boss = {
		activeBossId = "",
		remainingHp = 0,
		attempts = 0,
		lastPhase = 0,
	},
	resources = {
		stamina = 4,
		maxStamina = GameConfig.STAMINA_MAX,
		food = 3,
		knowledge = 10,
		gold = 0,
	},
	progress = {
		battleWins = 0,
		pvpWins = 0,
		questsCompleted = 0,
		playtimeSeconds = 0,
		questProgress = {},
		claimedQuests = {},
	},
	inventory = {
		items = {},
		equipmentBuffsApplied = false,
		itemStacks = {
			JJKBlindfold = 1,
			JJKCursedPendant = 1,
			JJKStudentUniform = 1,
			JJKTrackPants = 1,
			JJKTrainingKatana = 1,
			JJKPaperTalisman = 1,
			JJKRiceBall = 3,
			JJKEnergyDrink = 2,
			JJKSoulCandy = 1,
		},
		equipped = {
			head = "JJKBlindfold",
			neck = "JJKCursedPendant",
			shirt = "JJKStudentUniform",
			pants = "JJKTrackPants",
			weapon = "JJKTrainingKatana",
			enchantment = "JJKPaperTalisman",
		},
	},
	settings = {
		abbreviations = false,
		hardMode = false,
		autoBreakthrough = false,
	},
}

------------------//FUNCTIONS
local function copy_table(source: any): any
	if typeof(source) ~= "table" then
		return source
	end

	local copy = {}
	for key, value in source do
		copy[key] = copy_table(value)
	end
	return copy
end

local function merge_defaults(source: any, defaults: any): any
	if typeof(defaults) ~= "table" then
		if source == nil then
			return defaults
		end
		return source
	end

	local merged = copy_table(defaults)
	if typeof(source) ~= "table" then
		return merged
	end

	for key, value in source do
		if typeof(value) == "table" and typeof(merged[key]) == "table" then
			merged[key] = merge_defaults(value, merged[key])
		else
			merged[key] = value
		end
	end

	return merged
end

function PlayerDataTemplate.create(): PlayerData
	return copy_table(TEMPLATE)
end

function PlayerDataTemplate.merge(data: any): PlayerData
	local merged = merge_defaults(data, TEMPLATE)
	merged.dataVersion = GameConfig.DATA_VERSION
	return merged
end

function PlayerDataTemplate.copy(data: PlayerData): PlayerData
	return copy_table(data)
end

------------------//INIT
return PlayerDataTemplate
