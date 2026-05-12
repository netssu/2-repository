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
	if level >= 500 then return "Immortal" end
	if level >= 300 then return "Heaven Breaker" end
	if level >= 100 then return "Special Grade" end
	if level >= 50  then return "Grade 1" end
	return "Mortal IX"
end

local function get_cultivation_label(data: any): string
	local cultivation = data.cultivation or {}
	local realmIndex = cultivation.realmIndex or 1
	local stage = cultivation.stage or 1
	local realmNames = GameConfig.REALM_NAMES or {}
	return (realmNames[realmIndex] or get_rank_name(data.level or 1)) .. " " .. tostring(stage)
end

local function get_mechanic_text(data: any): string
	if data.world == "JJK" and data.jjk then
		return "Cursed Energy: " .. tostring(math.floor(data.jjk.curseEnergy)) .. "% | Rebirth: " .. tostring(data.rebirthCount or 0)
	end
	return "No mechanic"
end

local function calculate_immortality_pct(data: any): number
	local storyCount = data.storyQuests and #data.storyQuests or 0
	local abilityCount = data.abilitiesUnlocked and #data.abilitiesUnlocked or 0
	local loreCount = data.loreLogs and #data.loreLogs or 0
	local value = (math.clamp((data.level or 1) / 500, 0, 1) * 60)
		+ (math.clamp(storyCount / 7, 0, 1) * 20)
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
		permanent = {},
	}

	local upgrades = data.upgrades or {}
	upgrades[worldId] = upgrades[worldId] or deep_copy(defaults)
	data.upgrades = upgrades

	local state = upgrades[worldId]
	state.unlockedRepeatables = state.unlockedRepeatables or deep_copy(defaults.unlockedRepeatables or {})
	state.removedRepeatables = state.removedRepeatables or deep_copy(defaults.removedRepeatables or {})
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
	if stageInfo and stageInfo.description then
		return tostring(stageInfo.description)
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

			local storyBlocked = is_resource_blocked(data, questDef, questProgressValue or 0)
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
	local bloodline   = "Title: " .. tostring(data.activeTitle or "Chosen") .. " | Path: " .. tostring(data.moralPath or "Unchosen")
	local cultivation = data.cultivation or {}
	local qi = cultivation.qi or 0
	local qiRequired = cultivation.qiRequired or 100
	local manual = cultivation.manual or "None"
	local elapsedProfileDays = get_elapsed_profile_days(data)

	set_label_text(UIDictionary.labels.worldValue,       world and world.displayName or "No World")
	set_label_text(UIDictionary.labels.levelValue,       "Level " .. tostring(data.level))
	set_label_text(UIDictionary.labels.expValue,         format_number(data.exp) .. " / " .. format_number(requiredExp) .. " EXP")
	set_label_text(UIDictionary.labels.focusValue,       tostring(math.floor(focusValue)) .. "% Focus")
	set_label_text(UIDictionary.labels.mechanicValue,    get_mechanic_text(data) .. " | Immortality: " .. tostring(calculate_immortality_pct(data)) .. "%")
	set_label_text(UIDictionary.labels.cultivationValue, "Cultivation: " .. get_cultivation_label(data))
	set_label_text(UIDictionary.labels.ageValue,         "Age: " .. format_age_days(STARTING_AGE_DAYS + elapsedProfileDays))
	set_label_text(UIDictionary.labels.lifespanValue,    "Lifespan: " .. format_age_days(math.max(0, STARTING_LIFESPAN_DAYS - elapsedProfileDays)))
	set_label_text(UIDictionary.labels.qiValue,          "Current Qi: " .. format_decimal(qi, 2))
	set_label_text(UIDictionary.labels.qiNeededValue,    "Qi Needed: " .. format_decimal(qiRequired, 2))
	set_label_text(UIDictionary.labels.manualValue,      "Current Manual: " .. manual)
	set_label_text(UIDictionary.labels.bloodlineValue,   bloodline)
	set_label_text(UIDictionary.labels.statsValue,       "Strength: " .. format_decimal(stats.atk or 0, 2) .. "\nVitality: " .. format_decimal(stats.hp or 0, 2) .. "\nSpeed: " .. format_decimal(stats.spd or 0, 2) .. "\nDefense: " .. format_decimal(stats.def or 0, 2) .. "\nLuck: " .. format_decimal(stats.luck or 0, 2))
	update_fill(UIDictionary.labels.focusFill, focusValue, 100)
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
	local starterRepeatables = {"LookAround", "CryLoudly", "Sleep"}
	for _, starterQuestId in starterRepeatables do
		if list_has(availableRepeatables, starterQuestId) then
			table.insert(optionRepeatables, starterQuestId)
		end
	end

	local featuredQuestId: string? = nil
	for _, questId in availableRepeatables do
		if not list_has(starterRepeatables, questId) then
			featuredQuestId = questId
		end
	end
	if featuredQuestId and not list_has(optionRepeatables, featuredQuestId) then
		table.insert(optionRepeatables, featuredQuestId)
	end

	if #optionRepeatables < #repeatableButtons then
		for _, questId in availableRepeatables do
			if not list_has(optionRepeatables, questId) then
				table.insert(optionRepeatables, questId)
				if #optionRepeatables >= #repeatableButtons then
					break
				end
			end
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

local function render_inventory_page(data: any): ()
	local inventory = data.inventory or {}
	local itemStacks = inventory.itemStacks or {}
	local equipped = inventory.equipped or {}
	local worldItems = ItemDictionary.get_world_items(data.world)
	local equippedText = "Head: " .. get_item_display(equipped.head or "")
		.. "\nNeck: " .. get_item_display(equipped.neck or "")
		.. "\nShirt: " .. get_item_display(equipped.shirt or "")
		.. "\nPants: " .. get_item_display(equipped.pants or "")
		.. "\nWeapon: " .. get_item_display(equipped.weapon or "")
		.. "\nEnchantment: " .. get_item_display(equipped.enchantment or "")

	set_label_text(UIDictionary.labels.inventoryValue, equippedText)
	render_player_viewport()

	local grid = get_hud_child("InventoryGrid")
	if not grid or not grid:IsA("GuiObject") then
		return
	end

	local itemList = grid:FindFirstChild("InventoryItemList")
	if not itemList then
		local scrolling = Instance.new("ScrollingFrame")
		scrolling.Name = "InventoryItemList"
		scrolling.BackgroundTransparency = 1
		scrolling.BorderSizePixel = 0
		scrolling.Position = UDim2.fromScale(0.03, 0.03)
		scrolling.Size = UDim2.fromScale(0.94, 0.94)
		scrolling.ScrollBarThickness = 8
		scrolling.CanvasSize = UDim2.fromOffset(0, 0)
		scrolling.Parent = grid

		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 8)
		layout.Parent = scrolling
		itemList = scrolling
	end

	if not itemList or not itemList:IsA("ScrollingFrame") then
		return
	end

	for _, child in itemList:GetChildren() do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end

	local visibleCount = 0
	for _, itemDef in worldItems do
		local amount = itemStacks[itemDef.id] or 0
		if amount > 0 then
			visibleCount += 1

			local card = Instance.new("Frame")
			card.Name = itemDef.id .. "Card"
			card.BackgroundColor3 = UIDictionary.colors.card
			card.BorderSizePixel = 0
			card.Size = UDim2.new(1, -4, 0, 104)
			card.Parent = itemList

			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 8)
			corner.Parent = card

			local emoji = Instance.new("TextLabel")
			emoji.BackgroundTransparency = 1
			emoji.Position = UDim2.fromOffset(8, 4)
			emoji.Size = UDim2.fromOffset(44, 44)
			emoji.Font = Enum.Font.GothamBlack
			emoji.TextScaled = true
			emoji.Text = itemDef.emoji or "?"
			emoji.TextColor3 = UIDictionary.colors.text
			emoji.Parent = card

			local title = Instance.new("TextLabel")
			title.BackgroundTransparency = 1
			title.Position = UDim2.fromOffset(60, 8)
			title.Size = UDim2.new(1, -68, 0, 22)
			title.Font = Enum.Font.GothamBold
			title.TextSize = 16
			title.TextXAlignment = Enum.TextXAlignment.Left
			title.TextColor3 = UIDictionary.colors.text
			title.Text = itemDef.displayName .. " x" .. tostring(amount)
			title.Parent = card

			local desc = Instance.new("TextLabel")
			desc.BackgroundTransparency = 1
			desc.Position = UDim2.fromOffset(60, 30)
			desc.Size = UDim2.new(1, -68, 0, 20)
			desc.Font = Enum.Font.Gotham
			desc.TextSize = 13
			desc.TextXAlignment = Enum.TextXAlignment.Left
			desc.TextColor3 = UIDictionary.colors.mutedText
			desc.Text = itemDef.description or ""
			desc.Parent = card

			local statLine = Instance.new("TextLabel")
			statLine.BackgroundTransparency = 1
			statLine.Position = UDim2.fromOffset(8, 52)
			statLine.Size = UDim2.new(1, -16, 0, 18)
			statLine.Font = Enum.Font.GothamBold
			statLine.TextSize = 12
			statLine.TextXAlignment = Enum.TextXAlignment.Left
			statLine.TextColor3 = UIDictionary.colors.blueAction
			statLine.Text = itemDef.category == "Equipment" and get_buff_text(itemDef) or get_effect_text(itemDef)
			statLine.Parent = card

			local actionButton = Instance.new("TextButton")
			actionButton.BackgroundColor3 = UIDictionary.colors.darkButton
			actionButton.BorderSizePixel = 0
			actionButton.Position = UDim2.new(1, -122, 1, -30)
			actionButton.Size = UDim2.fromOffset(114, 24)
			actionButton.AutoButtonColor = true
			actionButton.Font = Enum.Font.GothamBold
			actionButton.TextSize = 12
			actionButton.TextColor3 = UIDictionary.colors.whiteText
			actionButton.Parent = card

			local buttonCorner = Instance.new("UICorner")
			buttonCorner.CornerRadius = UDim.new(0, 6)
			buttonCorner.Parent = actionButton

			if itemDef.category == "Equipment" then
				local slotName = itemDef.slot or ""
				local isEquipped = slotName ~= "" and equipped[slotName] == itemDef.id
				actionButton.Text = isEquipped and "UNEQUIP" or "EQUIP"
				actionButton.BackgroundColor3 = isEquipped and UIDictionary.colors.redAction or UIDictionary.colors.darkButton
				if isEquipped then
					actionButton.Activated:Connect(function()
						run_player_action("UnequipSlot:" .. slotName)
					end)
				else
					actionButton.Activated:Connect(function()
						run_player_action("EquipItem:" .. itemDef.id)
					end)
				end
			else
				actionButton.Text = "USE"
				actionButton.Activated:Connect(function()
					run_player_action("UseItem:" .. itemDef.id)
				end)
			end
		end
	end

	local layout = itemList:FindFirstChildOfClass("UIListLayout")
	if layout then
		itemList.CanvasSize = UDim2.fromOffset(0, math.max(visibleCount * 112, 1))
	end
end

local function render_static_pages(data: any): ()
	local dailyDone = data.dailyQuestsDone and #data.dailyQuestsDone or 0
	local leaderboardScore = (data.level or 1) + ((data.rebirthCount or 0) * 300)
	local battle = data.battle or {}
	local jjkUpgrades = get_jjk_upgrade_state(data)
	local permanent = jjkUpgrades.permanent or {}
	local QuestDictionaryLocal = require(dictionaryModules:WaitForChild("QuestDictionary") :: ModuleScript)
	local storyQuest = QuestDictionaryLocal.get_quest("SchoolTrial")
	local storyPhaseText = if storyQuest then get_story_phase_text(data, storyQuest, QuestDictionaryLocal) else "Story path locked."
	set_label_text(UIDictionary.labels.guildValue,    "Moral Path: " .. tostring(data.moralPath or "Unchosen") .. "\nProtector: +15% quest EXP\nConqueror: +20% battle EXP")
	set_label_text(UIDictionary.labels.shopValue,     "World Souls: " .. tostring(data.worldSouls) .. "\nDivine Tokens: " .. tostring(data.divineTokens) .. "\nRebirth Shards: " .. tostring(data.rebirthShards) .. "\nSmall EXP Potion, Focus Charge, and Rebirth are connected.")
	set_label_text(UIDictionary.labels.miscValue,     "Score: " .. tostring(leaderboardScore) .. "\nDaily Quests: " .. tostring(dailyDone) .. "/3\nLast Battle: " .. tostring(battle.lastResult or "None") .. " " .. tostring(battle.lastEnemy or "") .. "\nGod: " .. tostring(battle.lastGodTaunt or "Watching."))
	set_label_text(UIDictionary.labels.settingsValue, "Abbreviations: " .. format_bool(data.settings.abbreviations) .. "\nHard Mode: " .. format_bool(data.settings.hardMode) .. "\nAuto Breakthrough: " .. format_bool(data.settings.autoBreakthrough))
	set_label_text(UIDictionary.labels.upgradeStatus, "JJK Stage: " .. tostring(jjkUpgrades.stage or 0) .. "\nStory Phase: " .. storyPhaseText .. "\nBody " .. tostring(permanent.cursedBody or 0) .. " | Control " .. tostring(permanent.cursedControl or 0) .. " | Focus " .. tostring(permanent.cooldownFocus or 0))
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
	connect_button(UIDictionary.buttons.cultivate, function() run_player_action("Cultivate") end)
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
