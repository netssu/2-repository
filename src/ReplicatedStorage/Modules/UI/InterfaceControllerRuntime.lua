--!strict
local InterfaceControllerRuntime = {}

function InterfaceControllerRuntime.start(): ()
------------------//SERVICES
local Players: Players = game:GetService("Players")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService: RunService = game:GetService("RunService")

------------------//CONSTANTS
local MODULES_FOLDER_NAME: string = "Modules"
local SECONDS_PER_DAY = 24 * 60 * 60
local STARTING_AGE_DAYS = (18 * 365) + (6 * 30) + 10
local STARTING_LIFESPAN_DAYS = (100 * 365) + (4 * 30) + 2

------------------//VARIABLES
local player: Player = Players.LocalPlayer
local playerGui: PlayerGui = player:WaitForChild("PlayerGui") :: PlayerGui
local replicatedModules: Folder = ReplicatedStorage:WaitForChild(MODULES_FOLDER_NAME) :: Folder
local utilityModules: Folder = replicatedModules:WaitForChild("Utility") :: Folder
local dictionaryModules: Folder = replicatedModules:WaitForChild("Dictionary") :: Folder
local gameModules: Folder = replicatedModules:WaitForChild("Game") :: Folder
local uiModules: Folder = replicatedModules:WaitForChild("UI") :: Folder

local ModuleCache = require(utilityModules:WaitForChild("ModuleCache") :: ModuleScript)
local RemoteNames = ModuleCache.require(utilityModules:WaitForChild("RemoteNames") :: ModuleScript)
local RemoteController = ModuleCache.require(utilityModules:WaitForChild("RemoteController") :: ModuleScript)
local UIDictionary = ModuleCache.require(dictionaryModules:WaitForChild("UIDictionary") :: ModuleScript)
local WorldDictionary = ModuleCache.require(dictionaryModules:WaitForChild("WorldDictionary") :: ModuleScript)
local ItemDictionary = ModuleCache.require(dictionaryModules:WaitForChild("ItemDictionary") :: ModuleScript)
local ExpFormula = ModuleCache.require(gameModules:WaitForChild("ExpFormula") :: ModuleScript)
local GameConfig = ModuleCache.require(gameModules:WaitForChild("GameConfig") :: ModuleScript)
local AnimeRegistry = ModuleCache.require(gameModules:WaitForChild("AnimeRegistry") :: ModuleScript)
local CharacterSelectionController = ModuleCache.require(uiModules:WaitForChild("CharacterSelectionController") :: ModuleScript)

local getPlayerDataRemote: RemoteFunction = RemoteController.get_function(RemoteNames.getPlayerData)
local selectWorldRemote: RemoteFunction = RemoteController.get_function(RemoteNames.selectWorld)
local trainRemote: RemoteFunction = RemoteController.get_function(RemoteNames.train)
local playerActionRemote: RemoteFunction = RemoteController.get_function(RemoteNames.playerAction)
local battleActionRemote: RemoteFunction = RemoteController.get_function(RemoteNames.battleAction)
local questActionRemote: RemoteFunction = RemoteController.get_function(RemoteNames.questAction)
local updateSettingRemote: RemoteFunction = RemoteController.get_function(RemoteNames.updateSetting)
local dataChangedRemote: RemoteEvent = RemoteController.get_event(RemoteNames.dataChanged)
local notifyRemote: RemoteEvent = RemoteController.get_event(RemoteNames.notify)

local hud: ScreenGui? = playerGui:WaitForChild(UIDictionary.screenGuiName, 10) :: ScreenGui?
local currentData: any = nil
local currentPage: string = UIDictionary.pages.options
local hasSelectedSave: boolean = false
local run_player_action: any = nil
local pendingButtons: {[GuiButton]: boolean} = {}
local pendingQuestIds: {[string]: boolean} = {}
local pendingRepeatableQuestId: string? = nil
local optionButtonQuestByName: {[string]: string} = {}
local inventoryFilter: string = "All"

local INVENTORY_FILTER_ORDER = {"All", "Consumable", "Quest", "head", "neck", "shirt", "pants", "weapon", "enchantment"}
local INVENTORY_FILTER_LABELS = {
	All = "ALL",
	Consumable = "USE",
	Quest = "KEY",
	head = "HEAD",
	neck = "NECK",
	shirt = "SHIRT",
	pants = "PANTS",
	weapon = "WEAPON",
	enchantment = "ENCHANT",
}

------------------//FUNCTIONS
local function get_hud_child(childName: string): Instance?
	if not hud then return nil end
	return hud:FindFirstChild(childName, true)
end

local function get_label(labelName: string): TextLabel?
	local label = get_hud_child(labelName)
	if label and label:IsA("TextLabel") then return label end
	return nil
end

local function get_button(buttonName: string): GuiButton?
	local button = get_hud_child(buttonName)
	if button and button:IsA("GuiButton") then return button end
	return nil
end

local function set_label_text(labelName: string, text: string): ()
	local label = get_label(labelName)
	if label then label.Text = text end
end

local function set_notice(message: string): ()
	set_label_text(UIDictionary.labels.notice, message)
end

local function format_number(value: number): string
	if currentData and currentData.settings and currentData.settings.abbreviations then
		if value >= 1000000 then return string.format("%.1fM", value / 1000000) end
		if value >= 1000 then return string.format("%.1fK", value / 1000) end
	end
	return tostring(math.floor(value))
end

local function format_decimal(value: number, digits: number): string
	return string.format("%." .. tostring(digits) .. "f", value)
end

local function format_bool(value: boolean): string
	return value and "ON" or "OFF"
end

local function get_elapsed_profile_days(data: any): number
	local createdAt = data.createdAt
	if typeof(createdAt) ~= "number" or createdAt <= 0 then
		return 0
	end

	return math.max(0, math.floor((os.time() - createdAt) / SECONDS_PER_DAY))
end

local function format_age_days(totalDays: number): string
	local years = math.floor(totalDays / 365)
	local remainingDays = totalDays % 365
	local months = math.floor(remainingDays / 30)
	local days = remainingDays % 30

	return tostring(years) .. " Years, " .. tostring(months) .. " Months, " .. tostring(days) .. " Days"
end

local function invoke_remote(remote: RemoteFunction, ...): any
	local success, result = pcall(function(...)
		return remote:InvokeServer(...)
	end, ...)
	if not success then
		set_notice("Server request failed.")
		return nil
	end
	return result
end

local function show_screen(screenName: string): ()
	if not hud then return end

	local charSelection = hud:FindFirstChild("CharacterSelection")
	local root = hud:FindFirstChild("Root")

	if screenName == "CharacterSelection" then
		if charSelection then charSelection.Visible = true end
		if root then root.Visible = false end
	else
		if charSelection then charSelection.Visible = false end
		if root then 
			root.Visible = true 
			local main = root:FindFirstChild("Main")
			if main then main.Visible = true end
		end
	end
end

local function set_tab_selected(tabName: string, selected: boolean): ()
	local button = get_button(tabName)
	if button then
		button.BackgroundColor3 = selected and UIDictionary.colors.card or UIDictionary.colors.panel
		if button:IsA("ImageButton") then
			button.ImageColor3 = button.BackgroundColor3
		end
	end
end

local function show_page(pageName: string): ()
	currentPage = pageName
	for _, targetPageName in UIDictionary.pages do
		local page = get_hud_child(targetPageName)
		if page and page:IsA("GuiObject") then
			page.Visible = targetPageName == pageName
		end
	end
	set_tab_selected(UIDictionary.buttons.optionsTab,    pageName == UIDictionary.pages.options)
	set_tab_selected(UIDictionary.buttons.statsTab,      pageName == UIDictionary.pages.stats)
	set_tab_selected(UIDictionary.buttons.questsTab,     pageName == UIDictionary.pages.quests)
	set_tab_selected(UIDictionary.buttons.inventoryTab,  pageName == UIDictionary.pages.inventory)
	set_tab_selected(UIDictionary.buttons.guildTab,      pageName == UIDictionary.pages.guild)
	set_tab_selected(UIDictionary.buttons.shopTab,       pageName == UIDictionary.pages.shop)
	set_tab_selected(UIDictionary.buttons.miscTab,       pageName == UIDictionary.pages.misc)
	set_tab_selected(UIDictionary.buttons.settingsTab,   pageName == UIDictionary.pages.settings)
end

local function update_fill(fillName: string, value: number, maxValue: number): ()
	local fill = get_hud_child(fillName)
	if fill and fill:IsA("GuiObject") then
		fill.Size = UDim2.fromScale(math.clamp(value / maxValue, 0, 1), 1)
	end
end

local function get_rank_name(level: number): string
	if level >= 500 then return "Special Grade" end
	if level >= 320 then return "Semi-Grade 1" end
	if level >= 220 then return "Grade 1" end
	if level >= 130 then return "Grade 2" end
	if level >= 60  then return "Grade 3" end
	return "Grade 4"
end

local function get_stage_roman(stage: number): string
	local roman = {"I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX"}
	return roman[math.clamp(math.floor(stage), 1, #roman)] or "I"
end

local function get_path_display(moralPath: string?): string
	if moralPath == "Protector" then
		return "Jujutsu Sorcerer"
	end
	if moralPath == "Conqueror" then
		return "Curse User"
	end
	return "Non-Sorcerer"
end

local function get_cultivation_label(data: any): string
	local cultivation = data.cultivation or {}
	local realmIndex = cultivation.realmIndex or 1
	local stage = cultivation.stage or 1
	local realmNames = GameConfig.REALM_NAMES or {}
	local gradeName = realmNames[realmIndex] or get_rank_name(data.level or 1)
	return gradeName .. " " .. get_stage_roman(stage)
end

local function get_mechanic_text(data: any): string
	if data.world == "JJK" and data.jjk then
		return "Output Control: " .. tostring(math.floor(data.jjk.curseEnergy)) .. "% | Rebirth: " .. tostring(data.rebirthCount or 0)
	end
	return "No mechanic"
end

local function calculate_immortality_pct(data: any): number
	local storyCount = data.storyQuests and #data.storyQuests or 0
	local abilityCount = data.abilitiesUnlocked and #data.abilitiesUnlocked or 0
	local loreCount = data.loreLogs and #data.loreLogs or 0
	local value = (math.clamp((data.level or 1) / 500, 0, 1) * 60)
		+ (math.clamp(storyCount / 13, 0, 1) * 20)
		+ (math.clamp(abilityCount / 8, 0, 1) * 10)
		+ (math.clamp(loreCount / 20, 0, 1) * 10)
	return math.floor(value * 10) / 10
end

local function format_list(list: {any}?, fallback: string): string
	if not list or #list == 0 then
		return fallback
	end

	local parts = {}
	for _, value in list do
		table.insert(parts, tostring(value))
	end
	return table.concat(parts, ", ")
end

local function list_has(list: {any}?, value: any): boolean
	if not list then
		return false
	end

	for _, item in list do
		if item == value then
			return true
		end
	end

	return false
end

local function deep_copy(value: any): any
	if typeof(value) ~= "table" then
		return value
	end

	local copy = {}
	for key, child in value do
		copy[key] = deep_copy(child)
	end
	return copy
end

local function ensure_repeatable_defaults(state: any, defaults: any): ()
	local unlocked = defaults.unlockedRepeatables or {}
	local removed = state.removedRepeatables or {}
	for _, questId in unlocked do
		if not list_has(state.unlockedRepeatables, questId) and not list_has(removed, questId) then
			table.insert(state.unlockedRepeatables, questId)
		end
	end
end

local function get_world_upgrade_state(data: any, worldId: string): any
	local animeModule = AnimeRegistry.get(worldId)
	local defaults = if animeModule and animeModule.initialUpgradeState then animeModule.initialUpgradeState else {
		stage = 0,
		storyRuns = 0,
		unlockedRepeatables = {},
		removedRepeatables = {},
		repeatableSlotCap = 3,
		chapterFlags = {},
		upgradeFlags = {},
		permanent = {},
	}

	local upgrades = data.upgrades or {}
	upgrades[worldId] = upgrades[worldId] or deep_copy(defaults)
	data.upgrades = upgrades

	local state = upgrades[worldId]
	state.unlockedRepeatables = state.unlockedRepeatables or deep_copy(defaults.unlockedRepeatables or {})
	state.removedRepeatables = state.removedRepeatables or deep_copy(defaults.removedRepeatables or {})
	state.repeatableSlotCap = state.repeatableSlotCap or defaults.repeatableSlotCap or 3
	state.chapterFlags = state.chapterFlags or deep_copy(defaults.chapterFlags or {})
	state.upgradeFlags = state.upgradeFlags or deep_copy(defaults.upgradeFlags or {})
	state.permanent = state.permanent or deep_copy(defaults.permanent or {})
	state.stage = state.stage or 0
	state.storyRuns = state.storyRuns or 0
	ensure_repeatable_defaults(state, defaults)
	return state
end

local function get_jjk_upgrade_state(data: any): any
	return get_world_upgrade_state(data, "JJK")
end

local function set_button_text(button: GuiButton, text: string): ()
	local buttonText = button:FindFirstChild("ButtonText", true)
	if buttonText and buttonText:IsA("TextLabel") then
		buttonText.Text = text
	elseif button:IsA("TextButton") then
		button.Text = text
	end
end

local function get_total_repeatable_completions(data: any, QuestDictionaryLocal: any): number
	local progressTable = data.progress and data.progress.questProgress or {}
	local total = 0

	for questId, value in progressTable do
		local quest = QuestDictionaryLocal.get_quest(questId)
		if quest and quest.repeatable then
			total += math.max(tonumber(value) or 0, 0)
		end
	end

	return total
end

local function is_story_chapter_open(data: any, questDef: any, QuestDictionaryLocal: any): boolean
	if questDef.questType ~= "Story" or data.world ~= "JJK" then
		return true
	end

	local state = get_jjk_upgrade_state(data)
	if questDef.maxCompletions and (state.storyRuns or 0) >= questDef.maxCompletions then
		return false
	end

	local nextRun = (state.storyRuns or 0) + 1
	local requiredCompletions = QuestDictionaryLocal.get_jjk_story_requirement(nextRun)
	if requiredCompletions == nil then
		return true
	end

	return get_total_repeatable_completions(data, QuestDictionaryLocal) >= requiredCompletions
end

local function get_story_phase_text(data: any, questDef: any, QuestDictionaryLocal: any): string
	local state = get_jjk_upgrade_state(data)
	if questDef.maxCompletions and (state.storyRuns or 0) >= questDef.maxCompletions then
		return "Story path complete."
	end

	local nextRun = (state.storyRuns or 0) + 1
	local requiredCompletions = QuestDictionaryLocal.get_jjk_story_requirement(nextRun)
	if requiredCompletions and not is_story_chapter_open(data, questDef, QuestDictionaryLocal) then
		return "No story chapter available right now."
	end

	local stageInfo = QuestDictionaryLocal.get_jjk_story_stage(nextRun)
	if stageInfo then
		local title = tostring(stageInfo.chapterTitle or "")
		local text = tostring(stageInfo.chapterText or stageInfo.description or "")
		if title ~= "" and text ~= "" then
			return title .. " - " .. text
		end
		if text ~= "" then
			return text
		end
	end

	return "Advance the current story phase."
end

local function is_resource_blocked(data: any, questDef: any, currentProgress: number): boolean
	local resources = data.resources or {}
	local readyToClaimStory = questDef.questType == "Story" and currentProgress >= (questDef.requiredProgress or 1)

	if readyToClaimStory and typeof(questDef.statCosts) == "table" then
		local stats = data.stats or {}
		for statName, amount in questDef.statCosts do
			if (stats[statName] or 0) < amount then
				return true
			end
		end
		return false
	end

	if (questDef.staminaChange or 0) < 0 and (resources.stamina or 0) < math.abs(questDef.staminaChange) then
		return true
	end
	if (questDef.foodChange or 0) < 0 and (resources.food or 0) < math.abs(questDef.foodChange) then
		return true
	end
	if (questDef.knowledgeChange or 0) < 0 and (resources.knowledge or 0) < math.abs(questDef.knowledgeChange) then
		return true
	end

	return false
end

local function is_story_blocked_by_requirements(data: any, questDef: any, QuestDictionaryLocal: any): boolean
	if questDef.questType ~= "Story" or data.world ~= "JJK" then
		return false
	end

	local state = get_jjk_upgrade_state(data)
	local nextRun = (state.storyRuns or 0) + 1
	local stageInfo = QuestDictionaryLocal.get_jjk_story_stage(nextRun)
	local requiredItems = if stageInfo and stageInfo.requiredItems then stageInfo.requiredItems else questDef.requiredItems
	local requiredFlags = if stageInfo and stageInfo.requiredUpgradeFlags then stageInfo.requiredUpgradeFlags else questDef.requiredUpgradeFlags

	if requiredFlags then
		local flags = state.upgradeFlags or {}
		for _, flagId in requiredFlags do
			if flags[flagId] ~= true then
				return true
			end
		end
	end

	if requiredItems then
		local stacks = (((data.inventory or {}).itemStacks) or {})
		for itemId, amount in requiredItems do
			if (stacks[itemId] or 0) < amount then
				return true
			end
		end
	end

	return false
end

local function get_quest_visual_state(data: any, questDef: any, questProgressValue: number, QuestDictionaryLocal: any): (boolean, boolean, string, boolean, string)
	if questDef.worldId and questDef.worldId ~= data.world then
		return false, false, "LOCKED", false, ""
	end

	local storyPhaseText = ""
	if data.world == "JJK" then
		local state = get_jjk_upgrade_state(data)

		if questDef.questType == "Story" then
			storyPhaseText = get_story_phase_text(data, questDef, QuestDictionaryLocal)
			if questDef.maxCompletions and (state.storyRuns or 0) >= questDef.maxCompletions then
				return false, false, "COMPLETE", false, storyPhaseText
			end
			if not is_story_chapter_open(data, questDef, QuestDictionaryLocal) then
				return false, false, "LOCKED", false, storyPhaseText
			end

			local storyBlocked = is_resource_blocked(data, questDef, questProgressValue or 0) or is_story_blocked_by_requirements(data, questDef, QuestDictionaryLocal)
			return true, not storyBlocked, "STORY", storyBlocked, storyPhaseText
		end

		if questDef.repeatable then
			local unlocked = list_has(state.unlockedRepeatables, questDef.id)
			local removed = list_has(state.removedRepeatables, questDef.id)
			local stageOk = (state.stage or 0) >= (questDef.minUpgradeStage or 0)
			if removed or not unlocked or not stageOk then
				return false, false, "LOCKED", false, storyPhaseText
			end

			if pendingRepeatableQuestId and pendingRepeatableQuestId ~= questDef.id then
				return true, false, "WAIT", false, storyPhaseText
			end

			local blocked = is_resource_blocked(data, questDef, 0)
			return true, not blocked, "DO", blocked, storyPhaseText
		end
	end

	local blocked = is_resource_blocked(data, questDef, questProgressValue or 0)
	return true, not blocked, "DO", blocked, storyPhaseText
end

local function render_options_quest_button(data: any, buttonName: string, questId: string): ()
	local button = get_button(buttonName)
	if not button then
		return
	end

	local QuestDictionaryLocal = require(dictionaryModules:WaitForChild("QuestDictionary") :: ModuleScript)
	local questDef = QuestDictionaryLocal.get_quest(questId)
	if not questDef then
		return
	end

	local questProgress = data.progress and data.progress.questProgress or {}
	local currentProgress = questProgress[questId] or 0
	local visible, enabled, stateText, resourceBlocked, storyPhaseText = get_quest_visual_state(data, questDef, currentProgress, QuestDictionaryLocal)
	local isPending = pendingQuestIds[questId] == true or pendingButtons[button] == true
	button.Visible = visible
	button.Active = enabled and not isPending
	button.AutoButtonColor = enabled and not isPending
	button.BackgroundColor3 = if isPending then UIDictionary.colors.blueAction elseif enabled then UIDictionary.colors.darkButton elseif resourceBlocked then UIDictionary.colors.redAction else UIDictionary.colors.disabled

	local text = if isPending then (questDef.displayName .. "...") else questDef.displayName
	set_button_text(button, text)
end

local function render_resources(data: any): ()
	local resources = data.resources or {}
	local stamina   = resources.stamina   or 0
	local maxStamina = resources.maxStamina or GameConfig.STAMINA_MAX
	local food      = resources.food      or 0
	local knowledge = resources.knowledge or 0
	local gold      = resources.gold      or 0
	set_label_text(UIDictionary.labels.staminaValue,   "Stamina: "   .. format_number(stamina)   .. "/" .. tostring(maxStamina))
	set_label_text(UIDictionary.labels.foodValue,      "Food: "      .. format_number(food)      .. "/" .. tostring(GameConfig.RESOURCE_MAX))
	set_label_text(UIDictionary.labels.knowledgeValue, "Knowledge: " .. format_number(knowledge) .. "/" .. tostring(GameConfig.RESOURCE_MAX))
	set_label_text(UIDictionary.labels.goldValue,      "Gold: "      .. format_number(gold))
	update_fill(UIDictionary.labels.staminaFill,   stamina,   maxStamina)
	update_fill(UIDictionary.labels.foodFill,      food,      GameConfig.RESOURCE_MAX)
	update_fill(UIDictionary.labels.knowledgeFill, knowledge, GameConfig.RESOURCE_MAX)
end

local function render_stats_page(data: any): ()
	local world       = WorldDictionary.get_world(data.world)
	local requiredExp = ExpFormula.get_required_exp(data.level)
	local focusValue  = data.training and data.training.focus or 0
	local stats       = data.stats
	local bloodline   = "Title: " .. tostring(data.activeTitle or "Chosen") .. " | Path: " .. get_path_display(data.moralPath)
	local cultivation = data.cultivation or {}
	local qi = cultivation.qi or 0
	local qiRequired = cultivation.qiRequired or 100
	local manual = cultivation.manual or "None"
	local elapsedProfileDays = get_elapsed_profile_days(data)

	set_label_text(UIDictionary.labels.worldValue,       world and world.displayName or "No World")
	set_label_text(UIDictionary.labels.levelValue,       "Level " .. tostring(data.level))
	set_label_text(UIDictionary.labels.expValue,         format_number(data.exp) .. " / " .. format_number(requiredExp) .. " EXP")
	set_label_text(UIDictionary.labels.focusValue,       tostring(math.floor(focusValue)) .. "% Output Control")
	set_label_text(UIDictionary.labels.mechanicValue,    get_mechanic_text(data) .. " | Immortality: " .. tostring(calculate_immortality_pct(data)) .. "%")
	set_label_text(UIDictionary.labels.cultivationValue, "Sorcerer Grade: " .. get_cultivation_label(data))
	set_label_text(UIDictionary.labels.ageValue,         "Age: " .. format_age_days(STARTING_AGE_DAYS + elapsedProfileDays))
	set_label_text(UIDictionary.labels.lifespanValue,    "Lifespan: " .. format_age_days(math.max(0, STARTING_LIFESPAN_DAYS - elapsedProfileDays)))
	set_label_text(UIDictionary.labels.qiValue,          "Current CE: " .. format_decimal(qi, 2))
	set_label_text(UIDictionary.labels.qiNeededValue,    "CE Needed: " .. format_decimal(qiRequired, 2))
	set_label_text(UIDictionary.labels.manualValue,      "Current Technique: " .. manual)
	set_label_text(UIDictionary.labels.bloodlineValue,   bloodline)
	set_label_text(UIDictionary.labels.statsValue,       "Strength: " .. format_decimal(stats.atk or 0, 2) .. "\nVitality: " .. format_decimal(stats.hp or 0, 2) .. "\nSpeed: " .. format_decimal(stats.spd or 0, 2) .. "\nDefense: " .. format_decimal(stats.def or 0, 2) .. "\nLuck: " .. format_decimal(stats.luck or 0, 2))
	update_fill(UIDictionary.labels.focusFill, focusValue, 100)

	local cultivateButton = get_button(UIDictionary.buttons.cultivate)
	if cultivateButton then
		local stamina = ((data.resources or {}).stamina or 0)
		local canMeditate = stamina >= (GameConfig.CULTIVATE_STAMINA_COST or 1)
		local isPending = pendingButtons[cultivateButton] == true
		cultivateButton.Active = canMeditate and not isPending
		cultivateButton.AutoButtonColor = canMeditate and not isPending
		cultivateButton.BackgroundColor3 = if isPending then UIDictionary.colors.blueAction elseif canMeditate then UIDictionary.colors.darkButton else UIDictionary.colors.redAction
		set_button_text(cultivateButton, "MEDITATE")
	end
end

local function render_quests_page(data: any): ()
	local QuestDictionaryLocal = require(dictionaryModules:WaitForChild("QuestDictionary") :: ModuleScript)
	local questProgress = data.progress and data.progress.questProgress or {}
	optionButtonQuestByName = {}

	local storyQuestId: string? = nil
	local availableRepeatables = {}
	for _, questId in QuestDictionaryLocal.order do
		local questDef = QuestDictionaryLocal.get_quest(questId)
		if not questDef then
			continue
		end
		local currentProg = questProgress[questId] or 0
		local visible, _, _, _, _ = get_quest_visual_state(data, questDef, currentProg, QuestDictionaryLocal)
		if not visible then
			continue
		end

		if questDef.questType == "Story" and not storyQuestId then
			storyQuestId = questId
		elseif questDef.repeatable then
			table.insert(availableRepeatables, questId)
		end
	end

	local storyButton = get_button(UIDictionary.buttons.storyQuest)
	if storyButton then
		if storyQuestId then
			optionButtonQuestByName[UIDictionary.buttons.storyQuest] = storyQuestId
			render_options_quest_button(data, UIDictionary.buttons.storyQuest, storyQuestId)
		else
			storyButton.Visible = false
		end
	end

	local repeatableButtons = {
		UIDictionary.buttons.cryQuest,
		UIDictionary.buttons.sleepQuest,
		UIDictionary.buttons.wiggleQuest,
		UIDictionary.buttons.exorciseQuest,
	}
	local optionRepeatables = {}
	local stageState = get_jjk_upgrade_state(data)
	local repeatableSlotCap = if data.world == "JJK" then math.max(stageState.repeatableSlotCap or 3, 1) else #repeatableButtons
	local visibleRepeatableCount = math.min(#repeatableButtons, repeatableSlotCap)

	local preferredOrder = {}
	local starterRepeatables = {"LookAround", "CryLoudly", "Sleep"}
	for _, starterQuestId in starterRepeatables do
		if list_has(availableRepeatables, starterQuestId) then
			table.insert(preferredOrder, starterQuestId)
		end
	end

	for _, questId in QuestDictionaryLocal.order do
		local questDef = QuestDictionaryLocal.get_quest(questId)
		if questDef and questDef.repeatable and list_has(availableRepeatables, questId) and not list_has(preferredOrder, questId) then
			table.insert(preferredOrder, questId)
		end
	end

	for _, questId in preferredOrder do
		table.insert(optionRepeatables, questId)
		if #optionRepeatables >= visibleRepeatableCount then
			break
		end
	end

	for index, buttonName in repeatableButtons do
		local questId = optionRepeatables[index]
		local button = get_button(buttonName)
		if not button then
			continue
		end

		if questId then
			optionButtonQuestByName[buttonName] = questId
			render_options_quest_button(data, buttonName, questId)
		else
			button.Visible = false
		end
	end

	for _, questId in QuestDictionaryLocal.order do
		local questDef = QuestDictionaryLocal.get_quest(questId)
		if not questDef then continue end

		local card = get_hud_child(questId .. "Card")
		if card then
			local currentProg = questProgress[questId] or 0
			local visible, enabled, stateText, resourceBlocked, storyPhaseText = get_quest_visual_state(data, questDef, currentProg, QuestDictionaryLocal)
			if card:IsA("GuiObject") then
				card.Visible = visible
			end

			local barFill = card:FindFirstChild("ProgressBar") and card.ProgressBar:FindFirstChild("ProgressFill")
			local progressTextLabel = card:FindFirstChild("ProgressBar") and card.ProgressBar:FindFirstChild("ProgressText")
			local actionBtn = card:FindFirstChild(questId .. "Button")

			if barFill and progressTextLabel then
				if questDef.questType == "Story" then
					local requiredProgress = questDef.requiredProgress or 0
					local ratio = if requiredProgress <= 0 then 1 else math.clamp(currentProg / requiredProgress, 0, 1)
					barFill.Size = UDim2.fromScale(ratio, 1)
					progressTextLabel.Text = storyPhaseText
				else
					barFill.Size = UDim2.fromScale(enabled and 1 or 0, 1)
					progressTextLabel.Text = enabled and tostring(questDef.upgradeText or "Repeatable action") or "Locked"
				end
			end

			if actionBtn then
				local button = actionBtn :: GuiButton
				local isPending = pendingQuestIds[questId] == true or pendingButtons[button] == true
				button.Active = enabled and not isPending
				button.AutoButtonColor = enabled and not isPending

				if isPending then
					button.BackgroundColor3 = UIDictionary.colors.blueAction
					set_button_text(button, "IN PROGRESS...")
				elseif not enabled then
					button.BackgroundColor3 = resourceBlocked and UIDictionary.colors.redAction or UIDictionary.colors.disabled
					set_button_text(button, if stateText == "WAIT" then "WAIT" elseif stateText == "LOCKED" then "LOCKED" else (questDef.questType == "Story" and "STORY" or "DO"))
				else
					button.BackgroundColor3 = UIDictionary.colors.darkButton
					set_button_text(button, questDef.questType == "Story" and "STORY" or "DO")
				end
			end
		end
	end
end

local function get_buff_text(itemDef: any): string
	local buffs = itemDef and itemDef.buffs
	if typeof(buffs) ~= "table" then
		return ""
	end

	local parts = {}
	for statName, amount in buffs do
		table.insert(parts, string.upper(statName) .. " +" .. tostring(amount))
	end
	table.sort(parts)
	return table.concat(parts, " | ")
end

local function get_effect_text(itemDef: any): string
	local effects = itemDef and itemDef.useEffects
	if typeof(effects) ~= "table" then
		return ""
	end

	local parts = {}
	for effectName, amount in effects do
		table.insert(parts, string.upper(effectName) .. " +" .. tostring(amount))
	end
	table.sort(parts)
	return table.concat(parts, " | ")
end

local function get_item_display(itemId: string): string
	if itemId == "" then
		return "None"
	end

	local itemDef = ItemDictionary.get_item(itemId)
	if not itemDef then
		return itemId
	end

	return tostring(itemDef.emoji or "") .. " " .. tostring(itemDef.displayName or itemId)
end

local function render_player_viewport(): ()
	local viewport = get_hud_child("PlayerViewport")
	if not viewport or not viewport:IsA("ViewportFrame") then
		return
	end

	viewport:ClearAllChildren()

	local worldModel = Instance.new("WorldModel")
	worldModel.Parent = viewport

	local camera = Instance.new("Camera")
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	local character = player.Character
	if not character then
		return
	end

	local clone = character:Clone()
	for _, descendant in clone:GetDescendants() do
		if descendant:IsA("Script") or descendant:IsA("LocalScript") then
			descendant:Destroy()
		elseif descendant:IsA("Humanoid") then
			descendant.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		end
	end

	clone:PivotTo(CFrame.new(0, 0, 0))
	clone.Parent = worldModel

	local _, size = clone:GetBoundingBox()
	local distance = math.max(size.X, size.Y, size.Z) * 1.8 + 2
	camera.CFrame = CFrame.new(Vector3.new(0, size.Y * 0.35, distance), Vector3.new(0, size.Y * 0.45, 0))
end

local function get_slot_icon(slotName: string): string
	local icons = {
		head = "🎭",
		neck = "📿",
		shirt = "🥋",
		pants = "👖",
		weapon = "🗡️",
		enchantment = "🧿",
	}
	return icons[slotName] or "⬜"
end

local function item_matches_filter(itemDef: any, filterId: string): boolean
	if filterId == "All" then
		return true
	end

	if filterId == "Consumable" then
		return itemDef.category == "Consumable"
	end

	if filterId == "Quest" then
		return itemDef.category == "Quest"
	end

	if itemDef.category ~= "Equipment" then
		return false
	end

	return (itemDef.slot or "") == filterId
end

local function render_inventory_page(data: any): ()
	local inventory = data.inventory or {}
	local itemStacks = inventory.itemStacks or {}
	local equipped = inventory.equipped or {}
	local worldItems = ItemDictionary.get_world_items(data.world)
	render_player_viewport()

	local equippedLabel = get_label(UIDictionary.labels.inventoryValue)
	if equippedLabel then
		equippedLabel.Visible = false
	end

	local equippedPanel = get_hud_child("EquippedPanel")
	if equippedPanel and equippedPanel:IsA("GuiObject") then
		local existingSlots = equippedPanel:FindFirstChild("EquipSlotGrid")
		if existingSlots then
			existingSlots:Destroy()
		end

		local slotsFrame = Instance.new("Frame")
		slotsFrame.Name = "EquipSlotGrid"
		slotsFrame.BackgroundTransparency = 1
		slotsFrame.BorderSizePixel = 0
		slotsFrame.Position = UDim2.fromScale(0.06, 0.58)
		slotsFrame.Size = UDim2.fromScale(0.88, 0.36)
		slotsFrame.Parent = equippedPanel

		local slotsFrameOutline = Instance.new("UIStroke")
		slotsFrameOutline.Color = UIDictionary.colors.line
		slotsFrameOutline.Thickness = 1
		slotsFrameOutline.Transparency = 0.15
		slotsFrameOutline.Parent = slotsFrame

		local slotOrder = {"head", "neck", "shirt", "pants", "weapon", "enchantment"}
		local columns = 3
		local tileSize = UDim2.fromScale(0.3, 0.45)
		for index, slotName in slotOrder do
			local row = math.floor((index - 1) / columns)
			local column = (index - 1) % columns
			local xScale = column * 0.34
			local yScale = row * 0.5

			local slotButton = Instance.new("TextButton")
			slotButton.Name = slotName .. "EquipSlot"
			slotButton.BackgroundColor3 = UIDictionary.colors.panel
			slotButton.BorderSizePixel = 0
			slotButton.Position = UDim2.fromScale(xScale, yScale)
			slotButton.Size = tileSize
			slotButton.Text = ""
			slotButton.Parent = slotsFrame

			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 6)
			corner.Parent = slotButton

			local equippedId = equipped[slotName] or ""
			local equippedDef = if equippedId ~= "" then ItemDictionary.get_item(equippedId) else nil

			local stroke = Instance.new("UIStroke")
			stroke.Color = if equippedDef then UIDictionary.colors.gold else UIDictionary.colors.line
			stroke.Thickness = 2
			stroke.Parent = slotButton

			local emojiLabel = Instance.new("TextLabel")
			emojiLabel.BackgroundTransparency = 1
			emojiLabel.Size = UDim2.fromScale(1, 0.62)
			emojiLabel.Position = UDim2.fromScale(0, 0)
			emojiLabel.Font = Enum.Font.GothamBlack
			emojiLabel.TextScaled = true
			emojiLabel.TextColor3 = UIDictionary.colors.text
			emojiLabel.Text = if equippedDef then tostring(equippedDef.emoji or "") else get_slot_icon(slotName)
			emojiLabel.Parent = slotButton

			local slotLabel = Instance.new("TextLabel")
			slotLabel.BackgroundTransparency = 1
			slotLabel.Size = UDim2.fromScale(1, 0.38)
			slotLabel.Position = UDim2.fromScale(0, 0.62)
			slotLabel.Font = Enum.Font.GothamBold
			slotLabel.TextScaled = true
			slotLabel.TextColor3 = UIDictionary.colors.whiteText
			slotLabel.Text = string.upper(slotName)
			slotLabel.Parent = slotButton

			if equippedDef then
				slotButton.BackgroundColor3 = UIDictionary.colors.card
				slotButton.AutoButtonColor = true
				slotButton.Activated:Connect(function()
					run_player_action("UnequipSlot:" .. slotName)
				end)
			else
				slotButton.AutoButtonColor = false
				slotButton.Active = false
			end
		end
	end

	local grid = get_hud_child("InventoryGrid")
	if not grid or not grid:IsA("GuiObject") then
		return
	end

	for _, child in grid:GetChildren() do
		child:Destroy()
	end

	local filterBar = Instance.new("Frame")
	filterBar.Name = "InventoryFilterBar"
	filterBar.BackgroundTransparency = 1
	filterBar.BorderSizePixel = 0
	filterBar.Position = UDim2.fromScale(0.02, 0.02)
	filterBar.Size = UDim2.fromScale(0.96, 0.12)
	filterBar.Parent = grid

	local filterLayout = Instance.new("UIListLayout")
	filterLayout.FillDirection = Enum.FillDirection.Horizontal
	filterLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	filterLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	filterLayout.Padding = UDim.new(0, 5)
	filterLayout.Parent = filterBar

	for _, filterId in INVENTORY_FILTER_ORDER do
		local filterButton = Instance.new("TextButton")
		filterButton.Name = "Filter_" .. filterId
		filterButton.Size = UDim2.fromScale(0.102, 0.95)
		filterButton.BackgroundColor3 = if inventoryFilter == filterId then UIDictionary.colors.blueAction else UIDictionary.colors.darkButton
		filterButton.BorderSizePixel = 0
		filterButton.AutoButtonColor = true
		filterButton.TextColor3 = UIDictionary.colors.whiteText
		filterButton.Font = Enum.Font.GothamBold
		filterButton.TextScaled = true
		filterButton.TextWrapped = true
		filterButton.Text = INVENTORY_FILTER_LABELS[filterId] or string.upper(filterId)
		filterButton.Parent = filterBar

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = filterButton

		filterButton.Activated:Connect(function()
			if inventoryFilter == filterId then
				return
			end
			inventoryFilter = filterId
			render_inventory_page(currentData or data)
		end)
	end

	local itemGrid = Instance.new("ScrollingFrame")
	itemGrid.Name = "InventoryItemGrid"
	itemGrid.BackgroundTransparency = 1
	itemGrid.BorderSizePixel = 0
	itemGrid.Position = UDim2.fromScale(0.02, 0.16)
	itemGrid.Size = UDim2.fromScale(0.96, 0.82)
	itemGrid.ScrollBarThickness = 8
	itemGrid.CanvasSize = UDim2.fromOffset(0, 0)
	itemGrid.AutomaticCanvasSize = Enum.AutomaticSize.Y
	itemGrid.Parent = grid

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.fromOffset(112, 112)
	gridLayout.CellPadding = UDim2.fromOffset(8, 8)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	gridLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	gridLayout.Parent = itemGrid

	local visibleCount = 0
	for _, itemDef in worldItems do
		local amount = itemStacks[itemDef.id] or 0
		if amount > 0 and item_matches_filter(itemDef, inventoryFilter) then
			visibleCount += 1
			local slotName = itemDef.slot or ""
			local isEquipped = slotName ~= "" and equipped[slotName] == itemDef.id

			local tile = Instance.new("TextButton")
			tile.Name = itemDef.id .. "Tile"
			tile.BackgroundColor3 = if isEquipped then UIDictionary.colors.gold else UIDictionary.colors.card
			tile.BorderSizePixel = 0
			tile.Text = ""
			tile.AutoButtonColor = true
			tile.LayoutOrder = visibleCount
			tile.Parent = itemGrid

			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 6)
			corner.Parent = tile

			local stroke = Instance.new("UIStroke")
			stroke.Color = if isEquipped then UIDictionary.colors.gold else UIDictionary.colors.line
			stroke.Thickness = 2
			stroke.Parent = tile

			local emojiLabel = Instance.new("TextLabel")
			emojiLabel.BackgroundTransparency = 1
			emojiLabel.Position = UDim2.fromScale(0.1, 0.06)
			emojiLabel.Size = UDim2.fromScale(0.8, 0.44)
			emojiLabel.Font = Enum.Font.GothamBlack
			emojiLabel.TextScaled = true
			emojiLabel.TextColor3 = UIDictionary.colors.text
			emojiLabel.Text = tostring(itemDef.emoji or "")
			emojiLabel.Parent = tile

			local qtyLabel = Instance.new("TextLabel")
			qtyLabel.BackgroundTransparency = 1
			qtyLabel.Position = UDim2.fromScale(0.58, 0.02)
			qtyLabel.Size = UDim2.fromScale(0.38, 0.2)
			qtyLabel.Font = Enum.Font.GothamBold
			qtyLabel.TextScaled = true
			qtyLabel.TextColor3 = UIDictionary.colors.whiteText
			qtyLabel.TextXAlignment = Enum.TextXAlignment.Right
			qtyLabel.Text = "x" .. tostring(amount)
			qtyLabel.Parent = tile

			local nameLabel = Instance.new("TextLabel")
			nameLabel.BackgroundTransparency = 1
			nameLabel.Position = UDim2.fromScale(0.08, 0.52)
			nameLabel.Size = UDim2.fromScale(0.84, 0.3)
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.TextScaled = true
			nameLabel.TextWrapped = true
			nameLabel.TextColor3 = UIDictionary.colors.whiteText
			nameLabel.Text = itemDef.displayName
			nameLabel.Parent = tile

			local actionLabel = Instance.new("TextLabel")
			actionLabel.BackgroundTransparency = 1
			actionLabel.Position = UDim2.fromScale(0.08, 0.83)
			actionLabel.Size = UDim2.fromScale(0.84, 0.14)
			actionLabel.Font = Enum.Font.Gotham
			actionLabel.TextScaled = true
			actionLabel.TextColor3 = if isEquipped then UIDictionary.colors.background else UIDictionary.colors.mutedText
			actionLabel.Text = if itemDef.category == "Consumable" then "USE" elseif itemDef.category == "Equipment" and isEquipped then "EQUIPPED" elseif itemDef.category == "Equipment" then "EQUIP" else "KEY"
			actionLabel.Parent = tile

			if itemDef.category == "Consumable" then
				tile.Activated:Connect(function()
					run_player_action("UseItem:" .. itemDef.id)
				end)
			elseif itemDef.category == "Equipment" then
				tile.Activated:Connect(function()
					local latestData = currentData or data
					local latestInventory = latestData and latestData.inventory or {}
					local latestEquipped = latestInventory and latestInventory.equipped or {}
					local currentlyEquippedId = if slotName ~= "" then (latestEquipped[slotName] or "") else ""
					if slotName ~= "" and currentlyEquippedId == itemDef.id then
						run_player_action("UnequipSlot:" .. slotName)
					else
						run_player_action("EquipItem:" .. itemDef.id)
					end
				end)
			else
				tile.AutoButtonColor = false
				tile.Active = false
			end
		end
	end

	if visibleCount == 0 then
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Name = "EmptyInventoryLabel"
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Position = UDim2.fromScale(0.08, 0.1)
		emptyLabel.Size = UDim2.fromScale(0.84, 0.2)
		emptyLabel.Font = Enum.Font.GothamBold
		emptyLabel.TextScaled = true
		emptyLabel.TextColor3 = UIDictionary.colors.mutedText
		emptyLabel.Text = "No items in this filter."
		emptyLabel.Parent = itemGrid
	end
end

local function render_static_pages(data: any): ()
	local dailyDone = data.dailyQuestsDone and #data.dailyQuestsDone or 0
	local leaderboardScore = (data.level or 1) + ((data.rebirthCount or 0) * 300)
	local battle = data.battle or {}
	local jjkUpgrades = get_jjk_upgrade_state(data)
	local permanent = jjkUpgrades.permanent or {}
	local chapterCount = 0
	for _, value in (jjkUpgrades.chapterFlags or {}) do
		if value == true then
			chapterCount += 1
		end
	end
	local QuestDictionaryLocal = require(dictionaryModules:WaitForChild("QuestDictionary") :: ModuleScript)
	local storyQuest = QuestDictionaryLocal.get_quest("SchoolTrial")
	local storyPhaseText = if storyQuest then get_story_phase_text(data, storyQuest, QuestDictionaryLocal) else "Story path locked."
	set_label_text(UIDictionary.labels.guildValue,    "Sorcerer Path: " .. get_path_display(data.moralPath) .. "\nJujutsu Sorcerer: +15% quest EXP\nCurse User: +20% battle EXP")
	set_label_text(UIDictionary.labels.shopValue,     "World Souls: " .. tostring(data.worldSouls) .. "\nDivine Tokens: " .. tostring(data.divineTokens) .. "\nRebirth Shards: " .. tostring(data.rebirthShards) .. "\nSmall EXP Potion, Focus Charge, and Rebirth are connected.")
	set_label_text(UIDictionary.labels.miscValue,     "Score: " .. tostring(leaderboardScore) .. "\nDaily Quests: " .. tostring(dailyDone) .. "/3\nLast Battle: " .. tostring(battle.lastResult or "None") .. " " .. tostring(battle.lastEnemy or "") .. "\nGod: " .. tostring(battle.lastGodTaunt or "Watching."))
	set_label_text(UIDictionary.labels.settingsValue, "Abbreviations: " .. format_bool(data.settings.abbreviations) .. "\nHard Mode: " .. format_bool(data.settings.hardMode) .. "\nAuto Awakening: " .. format_bool(data.settings.autoBreakthrough))
	set_label_text(UIDictionary.labels.upgradeStatus, "JJK Stage: " .. tostring(jjkUpgrades.stage or 0) .. " | Chapters: " .. tostring(chapterCount) .. "/13\nStory Phase: " .. storyPhaseText .. "\nSlots: " .. tostring(jjkUpgrades.repeatableSlotCap or 3) .. " | Body " .. tostring(permanent.cursedBody or 0) .. " | Control " .. tostring(permanent.cursedControl or 0) .. " | Focus " .. tostring(permanent.cooldownFocus or 0))
end

local function render_data(data: any): ()
	currentData = data
	if not data then return end

	render_resources(data)
	render_stats_page(data)
	render_quests_page(data)
	render_inventory_page(data)
	render_static_pages(data)

	if not hasSelectedSave then
		show_screen("CharacterSelection")
	else
		show_screen("Main")
		show_page(currentPage)
	end
end

local function apply_remote_result(result: any): ()
	if not result then return end
	if result.message then set_notice(result.message) end
	if result.data    then render_data(result.data)   end
end

local function select_world(worldId: string): boolean
	local result = invoke_remote(selectWorldRemote, worldId)
	apply_remote_result(result)

	if typeof(result) == "table" and result.ok == true then
		hasSelectedSave = true
		show_screen("Main")
		return true
	end

	return false
end

run_player_action = function(actionName: string): ()
	apply_remote_result(invoke_remote(playerActionRemote, actionName))
end

local function run_train(): ()
	apply_remote_result(invoke_remote(trainRemote))
end

local function run_battle_action(actionName: string): ()
	apply_remote_result(invoke_remote(battleActionRemote, actionName))
end

local function run_quest(questId: string): ()
	apply_remote_result(invoke_remote(questActionRemote, questId))
end

local function ensure_button_progress_fill(button: GuiButton): Frame
	local progressContainer = button:FindFirstChild("DelayProgress")
	if not progressContainer or not progressContainer:IsA("Frame") then
		progressContainer = Instance.new("Frame")
		progressContainer.Name = "DelayProgress"
		progressContainer.BackgroundColor3 = Color3.fromRGB(22, 26, 36)
		progressContainer.BackgroundTransparency = 0.45
		progressContainer.BorderSizePixel = 0
		progressContainer.ClipsDescendants = true
		progressContainer.Size = UDim2.fromScale(1, 1)
		progressContainer.ZIndex = button.ZIndex + 1
		progressContainer.Visible = false
		progressContainer.Parent = button
	end

	local fill = progressContainer:FindFirstChild("Fill")
	if not fill or not fill:IsA("Frame") then
		fill = Instance.new("Frame")
		fill.Name = "Fill"
		fill.BackgroundColor3 = UIDictionary.colors.blueAction
		fill.BackgroundTransparency = 0.25
		fill.BorderSizePixel = 0
		fill.AnchorPoint = Vector2.new(1, 0)
		fill.Position = UDim2.fromScale(1, 0)
		fill.Size = UDim2.fromScale(0, 1)
		fill.ZIndex = progressContainer.ZIndex + 1
		fill.Parent = progressContainer
	end

	return fill :: Frame
end

local function run_button_delay(button: GuiButton?, delaySeconds: number, callback: () -> ()): ()
	if not button or delaySeconds <= 0 then
		callback()
		return
	end

	if pendingButtons[button] then
		return
	end

	pendingButtons[button] = true
	task.spawn(function()
		local fill = ensure_button_progress_fill(button)
		local container = fill.Parent :: Frame
		local previousActive = button.Active
		local previousAutoButtonColor = button.AutoButtonColor

		container.Visible = true
		button.Active = false
		button.AutoButtonColor = false
		fill.Size = UDim2.fromScale(0, 1)
		fill.Position = UDim2.fromScale(1, 0)

		local startedAt = os.clock()
		while true do
			if not button:IsDescendantOf(game) then
				break
			end

			local ratio = math.clamp((os.clock() - startedAt) / delaySeconds, 0, 1)
			fill.Size = UDim2.fromScale(ratio, 1)
			fill.Position = UDim2.fromScale(1 - ratio, 0)
			if ratio >= 1 then
				break
			end
			RunService.RenderStepped:Wait()
		end

		container.Visible = false
		if button:IsDescendantOf(game) then
			button.Active = previousActive
			button.AutoButtonColor = previousAutoButtonColor
		end
		pendingButtons[button] = nil
		callback()
	end)
end

local function run_quest_with_visual_delay(questId: string, buttonName: string): ()
	local QuestDictionaryLocal = require(dictionaryModules:WaitForChild("QuestDictionary") :: ModuleScript)
	local questDef = QuestDictionaryLocal.get_quest(questId)
	if pendingQuestIds[questId] then
		return
	end

	if questDef and questDef.repeatable and pendingRepeatableQuestId and pendingRepeatableQuestId ~= questId then
		return
	end

	local delaySeconds = if questDef and questDef.actionDelaySeconds then math.max(questDef.actionDelaySeconds, 0) else 0
	local button = get_button(buttonName)
	if button and pendingButtons[button] then
		return
	end

	pendingQuestIds[questId] = true
	if questDef and questDef.repeatable then
		pendingRepeatableQuestId = questId
	end
	run_button_delay(button, delaySeconds, function()
		run_quest(questId)
		if pendingRepeatableQuestId == questId then
			pendingRepeatableQuestId = nil
		end
		pendingQuestIds[questId] = nil
	end)
end

local function run_cultivate_with_visual_delay(): ()
	local buttonName = UIDictionary.buttons.cultivate
	local button = get_button(buttonName)
	if not button then
		run_player_action("Cultivate")
		return
	end

	if pendingButtons[button] then
		return
	end

	local delaySeconds = math.max(GameConfig.MEDITATE_DELAY_SECONDS or 1, 0)
	run_button_delay(button, delaySeconds, function()
		run_player_action("Cultivate")
	end)
end

local function run_option_quest(buttonName: string): ()
	local questId = optionButtonQuestByName[buttonName]
	if not questId then
		return
	end

	run_quest_with_visual_delay(questId, buttonName)
end

local function toggle_setting(settingName: string): ()
	if not currentData or not currentData.settings then return end
	apply_remote_result(invoke_remote(updateSettingRemote, settingName, not currentData.settings[settingName]))
end

local function connect_button(buttonName: string, callback: () -> ()): ()
	local button = get_button(buttonName)
	if button then button.Activated:Connect(callback) end
end

local function connect_navigation(): ()
	connect_button(UIDictionary.buttons.optionsTab,   function() show_page(UIDictionary.pages.options)   end)
	connect_button(UIDictionary.buttons.statsTab,     function() show_page(UIDictionary.pages.stats)     end)
	connect_button(UIDictionary.buttons.questsTab,    function() show_page(UIDictionary.pages.quests)    end)
	connect_button(UIDictionary.buttons.inventoryTab, function() show_page(UIDictionary.pages.inventory) end)
	connect_button(UIDictionary.buttons.guildTab,     function() show_page(UIDictionary.pages.guild)     end)
	connect_button(UIDictionary.buttons.shopTab,      function() show_page(UIDictionary.pages.shop)      end)
	connect_button(UIDictionary.buttons.miscTab,      function() show_page(UIDictionary.pages.misc)      end)
	connect_button(UIDictionary.buttons.settingsTab,  function() show_page(UIDictionary.pages.settings)  end)
end

local function connect_actions(): ()
	CharacterSelectionController.setup(hud, function()
		if currentData and currentData.world == "JJK" then
			hasSelectedSave = true
			show_screen("Main")
			show_page(currentPage)
			set_notice("JJK loaded.")
			return
		end
		select_world("JJK")
	end)

	local QuestDictionaryLocal = require(dictionaryModules:WaitForChild("QuestDictionary") :: ModuleScript)
	for _, questId in QuestDictionaryLocal.order do
		local btn = get_button(questId .. "Button")
		if btn then
			btn.Activated:Connect(function()
				run_quest_with_visual_delay(questId, questId .. "Button")
			end)
		end
	end
	connect_button(UIDictionary.buttons.train, run_train)
	connect_button(UIDictionary.buttons.cultivate, run_cultivate_with_visual_delay)
	connect_button(UIDictionary.buttons.rest, function() run_player_action("Rest") end)
	connect_button(UIDictionary.buttons.stop, function() run_player_action("Stop") end)
	connect_button(UIDictionary.buttons.work, function() run_player_action("Work") end)
	connect_button(UIDictionary.buttons.explore, function() run_player_action("Explore") end)
	connect_button(UIDictionary.buttons.breakthrough, function() run_player_action("Breakthrough") end)
	connect_button(UIDictionary.buttons.trophy, function()
		run_player_action("Boss")
	end)
	connect_button(UIDictionary.buttons.punch,  function() run_battle_action("Punch") end)
	connect_button(UIDictionary.buttons.whack,  function() run_battle_action("Whack") end)
	connect_button(UIDictionary.buttons.block,  function() run_battle_action("Block") end)
	connect_button(UIDictionary.buttons.storyQuest,  function() run_option_quest(UIDictionary.buttons.storyQuest) end)
	connect_button(UIDictionary.buttons.cryQuest,    function() run_option_quest(UIDictionary.buttons.cryQuest)   end)
	connect_button(UIDictionary.buttons.sleepQuest,  function() run_option_quest(UIDictionary.buttons.sleepQuest) end)
	connect_button(UIDictionary.buttons.wiggleQuest, function() run_option_quest(UIDictionary.buttons.wiggleQuest) end)
	connect_button(UIDictionary.buttons.exorciseQuest, function() run_option_quest(UIDictionary.buttons.exorciseQuest) end)
	connect_button(UIDictionary.buttons.upgradeCursedBody, function() run_player_action("JJKUpgradecursedBody") end)
	connect_button(UIDictionary.buttons.upgradeCursedControl, function() run_player_action("JJKUpgradecursedControl") end)
	connect_button(UIDictionary.buttons.upgradeCooldownFocus, function() run_player_action("JJKUpgradecooldownFocus") end)
	connect_button(UIDictionary.buttons.guildJoin,   function() run_player_action("ChooseProtector")                  end)
	connect_button(UIDictionary.buttons.guildCreate, function() run_player_action("ChooseConqueror")                  end)
	connect_button(UIDictionary.buttons.shopReincarnate, function() run_player_action("Rebirth")                      end)
	connect_button(UIDictionary.buttons.shopEarly,   function() run_player_action("BuySmallExpPotion")                end)
	connect_button(UIDictionary.buttons.shopGift,    function() run_player_action("BuyFocusCharge")                   end)
	connect_button(UIDictionary.buttons.miscLeaderboards, function() set_notice("Leaderboards are static for now.")    end)
	connect_button(UIDictionary.buttons.miscStats,   function() set_notice("Stats are shown on the Stats tab.")        end)
	connect_button(UIDictionary.buttons.miscCodes,   function() set_notice("Codes will connect to rewards later.")     end)
	connect_button(UIDictionary.buttons.miscConsole, function() set_notice("Console is disabled in the foundation build.") end)
	connect_button(UIDictionary.buttons.settingAbbreviations,    function() toggle_setting("abbreviations")    end)
	connect_button(UIDictionary.buttons.settingHardMode,         function() toggle_setting("hardMode")         end)
	connect_button(UIDictionary.buttons.settingAutoBreakthrough, function() toggle_setting("autoBreakthrough") end)
end

------------------//INIT
if not hud then
	warn("ChosenByGodHud not found in PlayerGui.")
	return
end

show_screen("CharacterSelection")

connect_navigation()
connect_actions()

dataChangedRemote.OnClientEvent:Connect(render_data)
notifyRemote.OnClientEvent:Connect(function(payload: any)
	if typeof(payload) == "table" and payload.message then
		set_notice(payload.message)
	else
		set_notice(tostring(payload))
	end
end)

render_data(invoke_remote(getPlayerDataRemote))

end

return InterfaceControllerRuntime
