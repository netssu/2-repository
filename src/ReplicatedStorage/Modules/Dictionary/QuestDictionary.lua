------------------//SERVICES
-- N/A

------------------//CONSTANTS
-- N/A

------------------//VARIABLES
local QuestDictionary = {}

export type QuestDefinition = {
	id: string,
	displayName: string,
	questType: string,
	worldId: string?,
	rewardExp: number,
	rewardSouls: number,
	staminaChange: number,
	foodChange: number,
	knowledgeChange: number,
	repeatable: boolean,
	requiredProgress: number,
	minUpgradeStage: number?,
	maxCompletions: number?,
	statCosts: {[string]: number}?,
	statRewards: {[string]: number}?,
	unlockRepeatables: {string}?,
	removeRepeatables: {string}?,
	setUpgradeStage: number?,
	cycleGroup: string?,
	upgradeText: string?,
	actionDelaySeconds: number?,
	rewardItems: {[string]: number}?,
	unlockUpgrades: {string}?,
}

QuestDictionary.items = {
	SchoolTrial = {
		id = "SchoolTrial",
		displayName = "Instructor's Trial",
		questType = "Story",
		worldId = "JJK",
		rewardExp = 120,
		rewardSouls = 12,
		staminaChange = 0,
		foodChange = 0,
		knowledgeChange = 0,
		repeatable = false,
		requiredProgress = 0,
		maxCompletions = 5,
		statRewards = {
			hp = 2,
			atk = 0.6,
			def = 0.6,
		},
		setUpgradeStage = 1,
		rewardItems = {
			JJKEnergyDrink = 1,
			JJKTatteredCharm = 1,
		},
		unlockUpgrades = {"cursedBody"},
		upgradeText = "Story chapters are one-time milestones. Finish this chapter and wait for the next window.",
		actionDelaySeconds = 2.25,
	},
	LookAround = {
		id = "LookAround",
		displayName = "Look Around",
		questType = "Repeatable",
		worldId = "JJK",
		rewardExp = 6,
		rewardSouls = 1,
		staminaChange = -1,
		foodChange = 0,
		knowledgeChange = 1,
		repeatable = true,
		requiredProgress = 1,
		minUpgradeStage = 0,
		cycleGroup = "JJKCycle",
		upgradeText = "Recovery loop: spend Stamina to recover exactly +1 Knowledge.",
		actionDelaySeconds = 0.8,
	},
	CryLoudly = {
		id = "CryLoudly",
		displayName = "Find Snacks",
		questType = "Repeatable",
		worldId = "JJK",
		rewardExp = 6,
		rewardSouls = 1,
		staminaChange = 0,
		foodChange = 1,
		knowledgeChange = -1,
		repeatable = true,
		requiredProgress = 1,
		minUpgradeStage = 0,
		cycleGroup = "JJKCycle",
		upgradeText = "Recovery loop: spend Knowledge to recover exactly +1 Food.",
		actionDelaySeconds = 0.8,
	},
	Sleep = {
		id = "Sleep",
		displayName = "Catch Breath",
		questType = "Repeatable",
		worldId = "JJK",
		rewardExp = 6,
		rewardSouls = 0,
		staminaChange = 1,
		foodChange = -1,
		knowledgeChange = 0,
		repeatable = true,
		requiredProgress = 1,
		minUpgradeStage = 0,
		cycleGroup = "JJKCycle",
		upgradeText = "Recovery loop: spend Food to recover exactly +1 Stamina.",
		actionDelaySeconds = 0.8,
	},
	WiggleAround = {
		id = "WiggleAround",
		displayName = "Talk to Servants",
		questType = "Repeatable",
		worldId = "JJK",
		rewardExp = 16,
		rewardSouls = 3,
		staminaChange = -2,
		foodChange = 0,
		knowledgeChange = 2,
		repeatable = true,
		requiredProgress = 1,
		minUpgradeStage = 0,
		cycleGroup = "JJKCycle",
		statRewards = {
			atk = 0.2,
			def = 0.1,
		},
		upgradeText = "Spending loop: heavy Stamina cost to push Knowledge and EXP.",
		actionDelaySeconds = 1.05,
	},
	WanderHalls = {
		id = "WanderHalls",
		displayName = "Wander the Halls",
		questType = "Repeatable",
		worldId = "JJK",
		rewardExp = 18,
		rewardSouls = 3,
		staminaChange = 0,
		foodChange = 2,
		knowledgeChange = -2,
		repeatable = true,
		requiredProgress = 1,
		minUpgradeStage = 1,
		cycleGroup = "JJKCycle",
		statRewards = {
			def = 0.15,
			luck = 0.03,
		},
		upgradeText = "Spending loop: heavy Knowledge cost to generate Food and tougher stats.",
		actionDelaySeconds = 1.1,
	},
	ShadowDrill = {
		id = "ShadowDrill",
		displayName = "Shadow Drill",
		questType = "Repeatable",
		worldId = "JJK",
		rewardExp = 30,
		rewardSouls = 5,
		staminaChange = -3,
		foodChange = -1,
		knowledgeChange = 0,
		repeatable = true,
		requiredProgress = 1,
		minUpgradeStage = 1,
		cycleGroup = "JJKCycle",
		statRewards = {
			hp = 0.9,
			atk = 0.35,
			def = 0.2,
		},
		upgradeText = "Combat drill: spends Stamina/Food for direct stat growth.",
		actionDelaySeconds = 1.3,
	},
	ExorciseGrade4 = {
		id = "ExorciseGrade4",
		displayName = "Exorcise Grade 4 Curse",
		questType = "Repeatable",
		worldId = "JJK",
		rewardExp = 50,
		rewardSouls = 9,
		staminaChange = -4,
		foodChange = -2,
		knowledgeChange = -1,
		repeatable = true,
		requiredProgress = 1,
		minUpgradeStage = 1,
		cycleGroup = "JJKCycle",
		statRewards = {
			hp = 1.2,
			atk = 0.8,
			def = 0.25,
			luck = 0.1,
		},
		upgradeText = "First chapter unlock. Costs multiple resources and pays strong growth.",
		actionDelaySeconds = 1.8,
	},
	ArchiveResearch = {
		id = "ArchiveResearch",
		displayName = "Archive Research",
		questType = "Repeatable",
		worldId = "JJK",
		rewardExp = 34,
		rewardSouls = 6,
		staminaChange = 0,
		foodChange = -2,
		knowledgeChange = 3,
		repeatable = true,
		requiredProgress = 1,
		minUpgradeStage = 2,
		cycleGroup = "JJKCycle",
		statRewards = {
			def = 0.3,
			luck = 0.07,
		},
		upgradeText = "Mid-loop conversion: spend Food to surge Knowledge for advanced steps.",
		actionDelaySeconds = 1.4,
	},
	BarrierPractice = {
		id = "BarrierPractice",
		displayName = "Barrier Practice",
		questType = "Repeatable",
		worldId = "JJK",
		rewardExp = 45,
		rewardSouls = 8,
		staminaChange = -3,
		foodChange = 0,
		knowledgeChange = -2,
		repeatable = true,
		requiredProgress = 1,
		minUpgradeStage = 3,
		cycleGroup = "JJKCycle",
		statRewards = {
			hp = 1.1,
			def = 0.75,
		},
		upgradeText = "Advanced control: burns Stamina/Knowledge to harden your defensive core.",
		actionDelaySeconds = 1.65,
	},
	SquadPatrol = {
		id = "SquadPatrol",
		displayName = "Squad Patrol",
		questType = "Repeatable",
		worldId = "JJK",
		rewardExp = 58,
		rewardSouls = 10,
		staminaChange = -4,
		foodChange = -2,
		knowledgeChange = -1,
		repeatable = true,
		requiredProgress = 1,
		minUpgradeStage = 4,
		cycleGroup = "JJKCycle",
		statRewards = {
			hp = 1.4,
			atk = 0.6,
			luck = 0.12,
		},
		upgradeText = "Field cycle: coordinated patrol for stronger EXP and soul gains.",
		actionDelaySeconds = 1.85,
	},
	BlackFlashFocus = {
		id = "BlackFlashFocus",
		displayName = "Black Flash Focus",
		questType = "Repeatable",
		worldId = "JJK",
		rewardExp = 76,
		rewardSouls = 14,
		staminaChange = -5,
		foodChange = -2,
		knowledgeChange = -3,
		repeatable = true,
		requiredProgress = 1,
		minUpgradeStage = 5,
		cycleGroup = "JJKCycle",
		statRewards = {
			hp = 1.8,
			atk = 1.2,
			spd = 0.45,
			luck = 0.2,
		},
		upgradeText = "Late cycle burst: high cost, high reward, heavy stat acceleration.",
		actionDelaySeconds = 2.2,
	},
}

QuestDictionary.order = {
	"SchoolTrial",
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
}

QuestDictionary.jjkStoryRunRequirements = {
	3,
	12,
	26,
	44,
	68,
}

QuestDictionary.jjkStoryStages = {
	{
		run = 1,
		stage = 1,
		unlockRepeatables = {"WanderHalls", "ShadowDrill", "ExorciseGrade4"},
		removeRepeatables = {},
		description = "You receive your first assignment and unlock real curse field work.",
	},
	{
		run = 2,
		stage = 2,
		unlockRepeatables = {"ArchiveResearch"},
		removeRepeatables = {},
		description = "The school archives open. New repeatables enter your resource loop.",
	},
	{
		run = 3,
		stage = 3,
		unlockRepeatables = {"BarrierPractice"},
		removeRepeatables = {},
		description = "Barrier classes begin and your progression loop gets tougher.",
	},
	{
		run = 4,
		stage = 4,
		unlockRepeatables = {"SquadPatrol"},
		removeRepeatables = {},
		description = "You are assigned to squad patrols with higher pressure and rewards.",
	},
	{
		run = 5,
		stage = 5,
		unlockRepeatables = {"BlackFlashFocus"},
		removeRepeatables = {},
		description = "Your cursed control peaks and elite repeatables are now available.",
	},
}

------------------//FUNCTIONS
function QuestDictionary.get_quest(questId: string): QuestDefinition?
	return QuestDictionary.items[questId]
end

function QuestDictionary.get_jjk_story_stage(run: number): any
	return QuestDictionary.jjkStoryStages[run]
end

function QuestDictionary.get_jjk_story_requirement(run: number): number?
	return QuestDictionary.jjkStoryRunRequirements[run]
end

function QuestDictionary.get_repeatable_order(worldId: string): {string}
	local order = {}
	for _, questId in QuestDictionary.order do
		local quest = QuestDictionary.get_quest(questId)
		if quest and quest.repeatable and quest.worldId == worldId then
			table.insert(order, questId)
		end
	end
	return order
end

------------------//INIT
return QuestDictionary
