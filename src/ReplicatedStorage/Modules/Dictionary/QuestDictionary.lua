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
}

QuestDictionary.items = {
	LookAround = {
		id = "LookAround",
		displayName = "Enter the Courtyard",
		questType = "Story",
		worldId = "JJK",
		rewardExp = 60,
		rewardSouls = 5,
		staminaChange = -1,
		foodChange = 0,
		knowledgeChange = -2,
		repeatable = false,
		requiredProgress = 2,
		maxCompletions = 4,
		statCosts = {
			atk = 0.5,
			def = 0.25,
		},
		statRewards = {
			hp = 2,
			atk = 0.5,
			def = 0.5,
		},
		setUpgradeStage = 1,
		unlockRepeatables = {
			"CryLoudly",
			"Sleep",
		},
		upgradeText = "Story upgrade. Repeat it to push JJK progression forward, spending stats and Knowledge.",
	},
	CryLoudly = {
		id = "CryLoudly",
		displayName = "Wander the Halls",
		questType = "Repeatable",
		worldId = "JJK",
		rewardExp = 10,
		rewardSouls = 2,
		staminaChange = 0,
		foodChange = 2,
		knowledgeChange = -1,
		repeatable = true,
		requiredProgress = 2,
		minUpgradeStage = 0,
		cycleGroup = "JJKCircle",
		statRewards = {
			luck = 0.05,
		},
		upgradeText = "Food node of the circular loop: spends Knowledge and supplies Food.",
	},
	Sleep = {
		id = "Sleep",
		displayName = "Recover in the Alley",
		questType = "Repeatable",
		worldId = "JJK",
		rewardExp = 8,
		rewardSouls = 0,
		staminaChange = 4,
		foodChange = -1,
		knowledgeChange = 0,
		repeatable = true,
		requiredProgress = 1,
		minUpgradeStage = 0,
		cycleGroup = "JJKCircle",
		statRewards = {
			hp = 0.5,
			def = 0.1,
		},
		upgradeText = "Stamina node of the circular loop: spends Food and restores Stamina.",
	},
	WiggleAround = {
		id = "WiggleAround",
		displayName = "Talk to Servants",
		questType = "Repeatable",
		worldId = "JJK",
		rewardExp = 28,
		rewardSouls = 4,
		staminaChange = -2,
		foodChange = 0,
		knowledgeChange = 2,
		repeatable = true,
		requiredProgress = 3,
		minUpgradeStage = 2,
		cycleGroup = "JJKCircle",
		statRewards = {
			atk = 0.35,
			def = 0.15,
		},
		upgradeText = "Level node of the circular loop: spends Stamina and generates Knowledge + EXP.",
	},
	ExorciseGrade4 = {
		id = "ExorciseGrade4",
		displayName = "Exorcise Grade 4 Curse",
		questType = "Repeatable",
		worldId = "JJK",
		rewardExp = 45,
		rewardSouls = 8,
		staminaChange = -2,
		foodChange = -1,
		knowledgeChange = 0,
		repeatable = true,
		requiredProgress = 5,
		minUpgradeStage = 3,
		cycleGroup = "JJKCircle",
		statRewards = {
			hp = 1,
			atk = 0.6,
			luck = 0.1,
		},
		upgradeText = "Unlocked by Story stage 3. High-risk level node that drains Stamina/Food for big growth.",
	},
}

QuestDictionary.order = {
	"LookAround",
	"CryLoudly",
	"Sleep",
	"WiggleAround",
	"ExorciseGrade4",
}

QuestDictionary.jjkStoryStages = {
	{
		run = 1,
		stage = 1,
		unlockRepeatables = {"CryLoudly", "Sleep"},
		removeRepeatables = {},
		description = "Awaken cursed perception.",
	},
	{
		run = 2,
		stage = 2,
		unlockRepeatables = {"WiggleAround"},
		removeRepeatables = {},
		description = "Unlock cursed dummy training.",
	},
	{
		run = 3,
		stage = 3,
		unlockRepeatables = {"ExorciseGrade4"},
		removeRepeatables = {},
		description = "Exorcism node unlocked; circular economy remains active.",
	},
	{
		run = 4,
		stage = 4,
		unlockRepeatables = {},
		removeRepeatables = {},
		description = "Foundation Jujutsu upgrade path complete.",
	},
}

------------------//FUNCTIONS
function QuestDictionary.get_quest(questId: string): QuestDefinition?
	return QuestDictionary.items[questId]
end

function QuestDictionary.get_jjk_story_stage(run: number): any
	return QuestDictionary.jjkStoryStages[run]
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
