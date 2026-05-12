local GameServerRuntime = {}

function GameServerRuntime.start(): ()
------------------//SERVICES
local Players: Players = game:GetService("Players")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage: ServerStorage = game:GetService("ServerStorage")
local DataStoreService: DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService: RunService = game:GetService("RunService")

------------------//CONSTANTS
local DATA_STORE_BASE_NAME: string = "ChosenByGod_PlayerData_V1"
local MODULES_FOLDER_NAME: string = "Modules"
local SESSION_LOCK_TIMEOUT_SECONDS = 120
local SESSION_LOCKS_ENABLED = not RunService:IsStudio()
local SECONDS_PER_DAY = 86400
local STARTING_WORLD_ID = "JJK"

------------------//VARIABLES
local replicatedModules: Folder = ReplicatedStorage:WaitForChild(MODULES_FOLDER_NAME) :: Folder
local serverModules: Folder = ServerStorage:WaitForChild(MODULES_FOLDER_NAME) :: Folder
local utilityModules: Folder = replicatedModules:WaitForChild("Utility") :: Folder
local dictionaryModules: Folder = replicatedModules:WaitForChild("Dictionary") :: Folder
local gameModules: Folder = replicatedModules:WaitForChild("Game") :: Folder
local serverGameModules: Folder = serverModules:WaitForChild("Game") :: Folder

local ModuleCache = require(utilityModules:WaitForChild("ModuleCache") :: ModuleScript)
local RemoteNames = ModuleCache.require(utilityModules:WaitForChild("RemoteNames") :: ModuleScript)
local RemoteController = ModuleCache.require(utilityModules:WaitForChild("RemoteController") :: ModuleScript)
local GameConfig = ModuleCache.require(gameModules:WaitForChild("GameConfig") :: ModuleScript)
local ExpFormula = ModuleCache.require(gameModules:WaitForChild("ExpFormula") :: ModuleScript)
local AnimeRegistry = ModuleCache.require(gameModules:WaitForChild("AnimeRegistry") :: ModuleScript)
local WorldDictionary = ModuleCache.require(dictionaryModules:WaitForChild("WorldDictionary") :: ModuleScript)
local AbilityDictionary = ModuleCache.require(dictionaryModules:WaitForChild("AbilityDictionary") :: ModuleScript)
local QuestDictionary = ModuleCache.require(dictionaryModules:WaitForChild("QuestDictionary") :: ModuleScript)
local ItemDictionary = ModuleCache.require(dictionaryModules:WaitForChild("ItemDictionary") :: ModuleScript)
local PlayerDataTemplate = ModuleCache.require(serverGameModules:WaitForChild("PlayerDataTemplate") :: ModuleScript)

local function get_data_store_name(): string
	return DATA_STORE_BASE_NAME .. (if RunService:IsStudio() then "_Studio" else "_Published")
end

local playerDataStore = DataStoreService:GetDataStore(get_data_store_name())
local playerData: {[Player]: PlayerDataTemplate.PlayerData} = {}
local lastTrainAt: {[Player]: number} = {}
local repeatableInFlight: {[Player]: string} = {}
local sessionLockIdByPlayer = {}
local remoteFolder: Folder? = nil
local getPlayerDataRemote: RemoteFunction? = nil
local selectWorldRemote: RemoteFunction? = nil
local trainRemote: RemoteFunction? = nil
local playerActionRemote: RemoteFunction? = nil
local battleActionRemote: RemoteFunction? = nil
local questActionRemote: RemoteFunction? = nil
local updateSettingRemote: RemoteFunction? = nil
local dataChangedRemote: RemoteEvent? = nil
local notifyRemote: RemoteEvent? = nil

------------------//FUNCTIONS
local function get_day_number(timestamp: number): number
	return math.floor(timestamp / SECONDS_PER_DAY)
end

local function apply_created_timestamp(data: PlayerDataTemplate.PlayerData): ()
	local currentTime = os.time()
	local createdAt = data.createdAt

	if typeof(createdAt) == "number" and createdAt > 0 and createdAt <= currentTime then
		return
	end

	local lastLogin = data.lastLogin
	if typeof(lastLogin) == "number" and lastLogin > 0 and lastLogin <= currentTime then
		data.createdAt = lastLogin
	else
		data.createdAt = currentTime
	end
end

local function reset_daily_state(data: PlayerDataTemplate.PlayerData): ()
	data.dailyQuestsDone = {}
	data.dailyQuestsProgress = {
		Train200 = 0,
		Win5Battles = 0,
		Play30Minutes = 0,
	}
	data.shopPurchases = {}
end

local function apply_daily_login(data: PlayerDataTemplate.PlayerData): boolean
	local currentTime = os.time()
	local previousLogin = data.lastLogin
	local shouldGrantLoginReward = false

	if typeof(previousLogin) ~= "number" or previousLogin <= 0 or previousLogin > currentTime then
		previousLogin = 0
	end

	local lastLoginDay = get_day_number(previousLogin)
	local currentDay = get_day_number(currentTime)

	if previousLogin == 0 then
		reset_daily_state(data)
		data.loginStreak = 1
		shouldGrantLoginReward = true
	elseif lastLoginDay ~= currentDay then
		reset_daily_state(data)
		if currentDay - lastLoginDay == 1 then
			data.loginStreak += 1
		else
			data.loginStreak = 1
		end
		shouldGrantLoginReward = true
	end

	data.lastLogin = currentTime
	return shouldGrantLoginReward
end

local function apply_starting_world(data: PlayerDataTemplate.PlayerData): ()
	if data.world ~= "" then
		if data.world ~= STARTING_WORLD_ID then
			data.world = STARTING_WORLD_ID
			data.abilitiesUnlocked = AbilityDictionary.get_starting_abilities(STARTING_WORLD_ID)
			data.abilitiesEquipped = AbilityDictionary.get_default_equipped(STARTING_WORLD_ID)
		end
		if not data.jjk then
			data.jjk = {
				curseEnergy = 0,
			}
		end
		return
	end

	data.world = STARTING_WORLD_ID
	data.abilitiesUnlocked = AbilityDictionary.get_starting_abilities(STARTING_WORLD_ID)
	data.abilitiesEquipped = AbilityDictionary.get_default_equipped(STARTING_WORLD_ID)
	data.jjk = {
		curseEnergy = 0,
	}
end

local function get_data_key(player: Player): string
	return tostring(player.UserId)
end

local function get_active_lock_id(payload, nowTime)
	if not SESSION_LOCKS_ENABLED then
		return nil
	end

	if typeof(payload) ~= "table" then
		return nil
	end

	local lockId = payload.lockId
	local lockTimestamp = payload.lockTimestamp
	if typeof(lockId) ~= "string" or lockId == "" or typeof(lockTimestamp) ~= "number" then
		return nil
	end

	if nowTime - lockTimestamp > SESSION_LOCK_TIMEOUT_SECONDS then
		return nil
	end

	return lockId
end

local function load_saved_data(player)
	if not SESSION_LOCKS_ENABLED then
		local loadedData = nil
		local success = pcall(function()
			loadedData = playerDataStore:GetAsync(get_data_key(player))
		end)

		if not success then
			warn("Data load failed for " .. player.Name)
			return nil, "error"
		end

		return loadedData, "ok"
	end

	local lockId = HttpService:GenerateGUID(false)
	local nowTime = os.time()
	local loadedData = nil

	local success = pcall(function()
		return playerDataStore:UpdateAsync(get_data_key(player), function(previousValue)
			local previousTable = if typeof(previousValue) == "table" then previousValue else {}
			local activeLockId = get_active_lock_id(previousTable, nowTime)

			if activeLockId and activeLockId ~= lockId then
				return nil
			end

			local wrappedData = previousTable.data
			if typeof(wrappedData) ~= "table" then
				wrappedData = previousTable
			end

			loadedData = wrappedData

			return {
				data = wrappedData,
				lockId = lockId,
				lockTimestamp = nowTime,
			}
		end)
	end)

	if success and loadedData ~= nil then
		sessionLockIdByPlayer[player] = lockId
		return loadedData, "ok"
	end

	if not success then
		warn("Data load failed for " .. player.Name)
		return nil, "error"
	else
		warn("Data load blocked by active session for " .. player.Name)
		return nil, "locked"
	end
end

local function apply_player_attributes(player: Player, data: PlayerDataTemplate.PlayerData): ()
	local world = WorldDictionary.get_world(data.world)

	player:SetAttribute("World", data.world)
	player:SetAttribute("WorldName", world and world.displayName or "")
	player:SetAttribute("Level", data.level)
	player:SetAttribute("Exp", data.exp)
	player:SetAttribute("RebirthCount", data.rebirthCount)
	player:SetAttribute("WorldSouls", data.worldSouls)
end

local function get_client_data(data: PlayerDataTemplate.PlayerData): PlayerDataTemplate.PlayerData
	return PlayerDataTemplate.copy(data)
end

local function fire_data_changed(player: Player): ()
	local data = playerData[player]
	if not data or not dataChangedRemote then
		return
	end

	dataChangedRemote:FireClient(player, get_client_data(data))
end

local function send_notice(player: Player, message: string): ()
	if notifyRemote then
		notifyRemote:FireClient(player, {
			message = message,
		})
	end
end

local function list_has(list: {any}, value: any): boolean
	for _, item in list do
		if item == value then
			return true
		end
	end
	return false
end

local function add_unique(list: {any}, value: any): boolean
	if list_has(list, value) then
		return false
	end

	table.insert(list, value)
	return true
end

local function remove_value(list: {any}, value: any): ()
	for index = #list, 1, -1 do
		if list[index] == value then
			table.remove(list, index)
		end
	end
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

local function get_rebirth_stat_multiplier(data: PlayerDataTemplate.PlayerData): number
	local multiplier = 1
	for index = 1, math.min(data.rebirthCount or 0, #GameConfig.REBIRTH_MULTIPLIERS) do
		multiplier *= GameConfig.REBIRTH_MULTIPLIERS[index]
	end
	return multiplier
end

local function get_equipped_slot_count(data: PlayerDataTemplate.PlayerData): number
	return if data.level >= 250 then 4 else 3
end

local function trim_equipped_abilities(data: PlayerDataTemplate.PlayerData): ()
	local slotCount = get_equipped_slot_count(data)
	local trimmed = {}

	for _, abilityId in data.abilitiesEquipped do
		if #trimmed >= slotCount then
			break
		end

		if list_has(data.abilitiesUnlocked, abilityId) then
			table.insert(trimmed, abilityId)
		end
	end

	data.abilitiesEquipped = trimmed
end

local function get_world_ability_count(data: PlayerDataTemplate.PlayerData): number
	local total = 0
	for _, ability in AbilityDictionary.get_world_abilities(data.world) do
		if ability.abilityType ~= "Passive" or AbilityDictionary.can_unlock(ability, data) then
			total += 1
		end
	end
	return math.max(total, 1)
end

local function calculate_immortality_pct(data: PlayerDataTemplate.PlayerData): number
	local levelProgress = math.clamp((data.level / 500) * 100, 0, 100)
	local storyProgress = math.clamp((#data.storyQuests / #GameConfig.STORY_MILESTONES) * 100, 0, 100)
	local abilityProgress = math.clamp((#data.abilitiesUnlocked / get_world_ability_count(data)) * 100, 0, 100)
	local loreProgress = math.clamp((#data.loreLogs / GameConfig.LORE_LOGS_PER_WORLD) * 100, 0, 100)

	return math.floor((levelProgress * 0.6 + storyProgress * 0.2 + abilityProgress * 0.1 + loreProgress * 0.1) * 10) / 10
end

local function update_peak_immortality(data: PlayerDataTemplate.PlayerData): ()
	data.peakImmortalityPct = math.max(data.peakImmortalityPct or 0, calculate_immortality_pct(data))
end

local function unlock_progression_rewards(data: PlayerDataTemplate.PlayerData): ()
	for _, ability in AbilityDictionary.get_world_abilities(data.world) do
		if AbilityDictionary.can_unlock(ability, data) then
			add_unique(data.abilitiesUnlocked, ability.id)
		end
	end

	for _, milestone in GameConfig.STORY_MILESTONES do
		if data.level >= milestone.level then
			add_unique(data.storyQuests, milestone.questId)
			add_unique(data.titles, milestone.title)
			data.activeTitle = milestone.title
		end
	end

	for index, level in GameConfig.RIVAL_LEVELS do
		if data.level >= level then
			data.rivalStage = math.max(data.rivalStage or 0, index)
		end
	end

	local loreTarget = math.clamp(math.floor(data.level / 25), 0, GameConfig.LORE_LOGS_PER_WORLD)
	for index = 1, loreTarget do
		add_unique(data.loreLogs, data.world .. "_Lore_" .. tostring(index))
	end

	trim_equipped_abilities(data)
	update_peak_immortality(data)
end

local function get_active_exp_multiplier(data: PlayerDataTemplate.PlayerData): number
	local multiplier = 1
	local nowTime = os.time()

	for _, boost in data.boosts do
		if boost.expiresAt and boost.expiresAt > nowTime and boost.expMultiplier then
			multiplier = math.max(multiplier, boost.expMultiplier)
		end
	end

	return multiplier
end

local function grant_world_souls(data: PlayerDataTemplate.PlayerData, amount: number): ()
	local gained = math.max(math.floor(amount), 0)
	data.worldSouls += gained
	data.battle.sessionSouls = (data.battle.sessionSouls or 0) + gained
end

local function add_daily_quest_progress(data: PlayerDataTemplate.PlayerData, questId: string, amount: number): ()
	if list_has(data.dailyQuestsDone, questId) then
		return
	end

	data.dailyQuestsProgress[questId] = (data.dailyQuestsProgress[questId] or 0) + amount

	local target = if questId == "Train200" then 200 elseif questId == "Win5Battles" then 5 else 1800
	if data.dailyQuestsProgress[questId] >= target then
		add_unique(data.dailyQuestsDone, questId)
		data.rebirthShards += if #data.dailyQuestsDone >= 3 then 1 else 0
	end
end

local function get_anime_module(worldId: string): any
	return AnimeRegistry.get(worldId)
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

local function get_world_upgrade_state(data: PlayerDataTemplate.PlayerData, worldId: string): any
	local animeModule = get_anime_module(worldId)
	local defaults = if animeModule and animeModule.initialUpgradeState then animeModule.initialUpgradeState else {
		stage = 0,
		storyRuns = 0,
		unlockedRepeatables = {},
		removedRepeatables = {},
		permanent = {},
	}

	data.upgrades = data.upgrades or {}
	data.upgrades[worldId] = data.upgrades[worldId] or deep_copy(defaults)

	local state = data.upgrades[worldId]
	state.unlockedRepeatables = state.unlockedRepeatables or deep_copy(defaults.unlockedRepeatables or {})
	state.removedRepeatables = state.removedRepeatables or deep_copy(defaults.removedRepeatables or {})
	state.permanent = state.permanent or deep_copy(defaults.permanent or {})
	state.stage = state.stage or 0
	state.storyRuns = state.storyRuns or 0
	ensure_repeatable_defaults(state, defaults)
	return state
end

local function get_jjk_upgrade_state(data: PlayerDataTemplate.PlayerData): any
	return get_world_upgrade_state(data, "JJK")
end

local function can_pay_stat_costs(data: PlayerDataTemplate.PlayerData, statCosts: {[string]: number}?): boolean
	if not statCosts then
		return true
	end

	for statName, amount in statCosts do
		if (data.stats[statName] or 0) < amount then
			return false
		end
	end

	return true
end

local function get_total_repeatable_completions(data: PlayerDataTemplate.PlayerData): number
	local progressTable = data.progress and data.progress.questProgress or {}
	local total = 0

	for questId, value in progressTable do
		local quest = QuestDictionary.get_quest(questId)
		if quest and quest.repeatable then
			total += math.max(tonumber(value) or 0, 0)
		end
	end

	return total
end

local function apply_stat_changes(data: PlayerDataTemplate.PlayerData, statChanges: {[string]: number}?, sign: number): ()
	if not statChanges then
		return
	end

	for statName, amount in statChanges do
		data.stats[statName] = math.max((data.stats[statName] or 0) + (amount * sign), 0)
	end
end

local function is_quest_available(data: PlayerDataTemplate.PlayerData, quest: QuestDictionary.QuestDefinition): (boolean, string)
	if quest.worldId and quest.worldId ~= data.world then
		return false, "Unavailable."
	end

	if data.world == "JJK" then
		local state = get_jjk_upgrade_state(data)
		if quest.questType == "Story" then
			if quest.maxCompletions and state.storyRuns >= quest.maxCompletions then
				return false, "Story path complete."
			end

			local nextRun = state.storyRuns + 1
			local requiredCompletions = QuestDictionary.get_jjk_story_requirement(nextRun)
			if requiredCompletions and get_total_repeatable_completions(data) < requiredCompletions then
				return false, "No story chapter available right now."
			end

			return true, ""
		end

		if quest.repeatable then
			if not list_has(state.unlockedRepeatables, quest.id) or list_has(state.removedRepeatables, quest.id) then
				return false, "Unavailable."
			end
			if state.stage < (quest.minUpgradeStage or 0) then
				return false, "Unavailable."
			end
		end
	end

	return true, ""
end

local function apply_jjk_story_upgrade(data: PlayerDataTemplate.PlayerData, quest: QuestDictionary.QuestDefinition): string
	local state = get_jjk_upgrade_state(data)
	state.storyRuns += 1

	local stageInfo = QuestDictionary.get_jjk_story_stage(state.storyRuns)
	if stageInfo then
		state.stage = math.max(state.stage, stageInfo.stage)
		for _, questId in stageInfo.unlockRepeatables or {} do
			add_unique(state.unlockedRepeatables, questId)
		end
		for _, questId in stageInfo.removeRepeatables or {} do
			add_unique(state.removedRepeatables, questId)
			remove_value(state.unlockedRepeatables, questId)
		end
	else
		state.stage = math.max(state.stage, quest.setUpgradeStage or state.stage)
		for _, questId in quest.unlockRepeatables or {} do
			add_unique(state.unlockedRepeatables, questId)
		end
		for _, questId in quest.removeRepeatables or {} do
			add_unique(state.removedRepeatables, questId)
			remove_value(state.unlockedRepeatables, questId)
		end
	end

	return stageInfo and stageInfo.description or "Jujutsu story upgraded."
end

local function save_player_data(player: Player): boolean
	local data = playerData[player]
	if not data then
		return false
	end

	if not SESSION_LOCKS_ENABLED then
		local success = pcall(function()
			playerDataStore:SetAsync(get_data_key(player), data)
		end)
		if not success then
			warn("Data save failed for " .. player.Name)
		end
		return success
	end

	local lockId = sessionLockIdByPlayer[player]
	if not lockId then
		warn("Data save blocked (no session lock) for " .. player.Name)
		return false
	end

	local nowTime = os.time()
	local savedWithLock = false
	local success = pcall(function()
		playerDataStore:UpdateAsync(get_data_key(player), function(previousValue)
			local previousTable = if typeof(previousValue) == "table" then previousValue else {}
			local activeLockId = get_active_lock_id(previousTable, nowTime)

			if activeLockId and activeLockId ~= lockId then
				return nil
			end

			savedWithLock = true
			return {
				data = data,
				lockId = lockId,
				lockTimestamp = nowTime,
			}
		end)
	end)

	if not success or not savedWithLock then
		warn("Data save failed for " .. player.Name)
	end

	return success and savedWithLock
end

local function change_resource(data: PlayerDataTemplate.PlayerData, resourceName: string, amount: number): ()
	local currentValue = data.resources[resourceName] or 0
	if resourceName == "gold" then
		data.resources[resourceName] = math.max(currentValue + amount, 0)
		return
	end

	local maxValue = if resourceName == "stamina" then data.resources.maxStamina or GameConfig.STAMINA_MAX else GameConfig.RESOURCE_MAX
	data.resources[resourceName] = math.clamp(currentValue + amount, 0, maxValue)
end

local function can_pay_resource(data: PlayerDataTemplate.PlayerData, resourceName: string, amount: number): boolean
	if amount >= 0 then
		return true
	end

	local currentValue = data.resources[resourceName] or 0
	return currentValue + amount >= 0
end

local LEGACY_ITEM_ID_MAP = {
	["Training Wraps"] = "JJKTrainingKatana",
	["Plain Uniform"] = "JJKStudentUniform",
}

local function get_world_equipment_slots(worldId: string): {string}
	local animeModule = get_anime_module(worldId)
	if animeModule and animeModule.equipmentSlots then
		return deep_copy(animeModule.equipmentSlots)
	end

	return {
		"head",
		"neck",
		"shirt",
		"pants",
		"weapon",
	}
end

local function is_item_stacks_empty(itemStacks: {[string]: number}): boolean
	for _, amount in itemStacks do
		if amount > 0 then
			return false
		end
	end
	return true
end

local function ensure_inventory_state(data: PlayerDataTemplate.PlayerData): ()
	data.inventory = data.inventory or {}
	local inventory = data.inventory
	inventory.items = inventory.items or {}
	inventory.itemStacks = inventory.itemStacks or {}
	inventory.equipped = inventory.equipped or {}
	if typeof(inventory.equipmentBuffsApplied) ~= "boolean" then
		inventory.equipmentBuffsApplied = false
	end

	for _, slot in get_world_equipment_slots(data.world) do
		if typeof(inventory.equipped[slot]) ~= "string" then
			inventory.equipped[slot] = ""
		elseif LEGACY_ITEM_ID_MAP[inventory.equipped[slot]] then
			inventory.equipped[slot] = LEGACY_ITEM_ID_MAP[inventory.equipped[slot]]
		end
	end

	if is_item_stacks_empty(inventory.itemStacks) and #inventory.items > 0 then
		for _, legacyName in inventory.items do
			local itemId = LEGACY_ITEM_ID_MAP[legacyName] or legacyName
			local itemDef = ItemDictionary.get_item(itemId)
			if itemDef then
				inventory.itemStacks[itemId] = (inventory.itemStacks[itemId] or 0) + 1
			end
		end
	end

	if is_item_stacks_empty(inventory.itemStacks) then
		local starterIds = ItemDictionary.get_world_item_ids(data.world)
		for _, itemId in starterIds do
			local itemDef = ItemDictionary.get_item(itemId)
			if itemDef then
				local amount = if itemDef.category == "Consumable" then 2 else 1
				inventory.itemStacks[itemId] = amount
			end
		end
	end
end

local function get_item_stack_amount(data: PlayerDataTemplate.PlayerData, itemId: string): number
	ensure_inventory_state(data)
	return data.inventory.itemStacks[itemId] or 0
end

local function add_inventory_item_stack(data: PlayerDataTemplate.PlayerData, itemId: string, amount: number): ()
	local stackAmount = math.max(math.floor(amount), 0)
	if stackAmount <= 0 then
		return
	end

	ensure_inventory_state(data)
	local itemDef = ItemDictionary.get_item(itemId)
	if not itemDef then
		return
	end
	if itemDef.worldId and itemDef.worldId ~= data.world then
		return
	end

	data.inventory.itemStacks[itemId] = (data.inventory.itemStacks[itemId] or 0) + stackAmount
	add_unique(data.inventory.items, itemId)
end

local function grant_quest_item_rewards(data: PlayerDataTemplate.PlayerData, rewardItems: {[string]: number}?): ()
	if not rewardItems then
		return
	end

	for itemId, amount in rewardItems do
		add_inventory_item_stack(data, itemId, amount)
	end
end

local function apply_upgrade_level_bonus(data: PlayerDataTemplate.PlayerData, worldId: string, upgradeId: string, levelCount: number): ()
	local animeModule = get_anime_module(worldId)
	local upgrade = animeModule and animeModule.upgrades and animeModule.upgrades[upgradeId] or nil
	if not upgrade then
		return
	end

	for _ = 1, math.max(levelCount, 0) do
		if upgrade.hpPerLevel then
			data.stats.hp += upgrade.hpPerLevel
		end
		if upgrade.defPerLevel then
			data.stats.def += upgrade.defPerLevel
		end
		if upgrade.atkPerLevel then
			data.stats.atk += upgrade.atkPerLevel
		end
		if upgrade.speedPerLevel then
			data.stats.spd += upgrade.speedPerLevel
		end
		if upgrade.curseEnergyPerLevel and worldId == "JJK" and data.jjk then
			data.jjk.curseEnergy = math.clamp((data.jjk.curseEnergy or 0) + upgrade.curseEnergyPerLevel, 0, 100)
		end
	end
end

local function apply_story_upgrade_unlocks(data: PlayerDataTemplate.PlayerData, worldId: string, unlockUpgrades: {string}?): ()
	if not unlockUpgrades then
		return
	end

	local animeModule = get_anime_module(worldId)
	if not animeModule or not animeModule.upgrades then
		return
	end

	local state = get_world_upgrade_state(data, worldId)
	for _, upgradeId in unlockUpgrades do
		local upgradeDef = animeModule.upgrades[upgradeId]
		if upgradeDef then
			local currentLevel = state.permanent[upgradeId] or 0
			if currentLevel < upgradeDef.maxLevel then
				state.permanent[upgradeId] = currentLevel + 1
				apply_upgrade_level_bonus(data, worldId, upgradeId, 1)
			end
		end
	end
end

local function apply_item_buffs(data: PlayerDataTemplate.PlayerData, buffs: {[string]: number}?, sign: number): ()
	if not buffs then
		return
	end

	for statName, amount in buffs do
		local delta = amount * sign
		if data.stats[statName] ~= nil then
			data.stats[statName] = math.max((data.stats[statName] or 0) + delta, 0)
		elseif statName == "maxStamina" then
			data.resources.maxStamina = math.max((data.resources.maxStamina or GameConfig.STAMINA_MAX) + delta, 1)
			data.resources.stamina = math.clamp(data.resources.stamina or 0, 0, data.resources.maxStamina)
		elseif statName == "curseEnergy" and data.jjk then
			data.jjk.curseEnergy = math.clamp((data.jjk.curseEnergy or 0) + delta, 0, 100)
		end
	end
end

local function ensure_equipment_buffs_applied(data: PlayerDataTemplate.PlayerData): ()
	ensure_inventory_state(data)
	if data.inventory.equipmentBuffsApplied then
		return
	end

	for _, slotName in get_world_equipment_slots(data.world) do
		local itemId = data.inventory.equipped[slotName]
		if typeof(itemId) == "string" and itemId ~= "" then
			local itemDef = ItemDictionary.get_item(itemId)
			if itemDef and itemDef.category == "Equipment" then
				apply_item_buffs(data, itemDef.buffs, 1)
			end
		end
	end

	data.inventory.equipmentBuffsApplied = true
end

local function apply_consumable_effects(data: PlayerDataTemplate.PlayerData, effects: {[string]: number}?): ()
	if not effects then
		return
	end

	for effectName, amount in effects do
		if effectName == "stamina" or effectName == "food" or effectName == "knowledge" or effectName == "gold" then
			change_resource(data, effectName, amount)
		elseif effectName == "focus" then
			data.training.focus = math.clamp((data.training.focus or 0) + amount, 0, GameConfig.FOCUS_MAX)
		elseif effectName == "qi" then
			local cultivation = data.cultivation
			cultivation.qi = math.min((cultivation.qi or 0) + amount, cultivation.qiRequired or 100)
		elseif effectName == "worldSouls" then
			grant_world_souls(data, amount)
		elseif effectName == "rebirthShards" then
			data.rebirthShards = math.max((data.rebirthShards or 0) + amount, 0)
		elseif data.stats[effectName] ~= nil then
			data.stats[effectName] = math.max((data.stats[effectName] or 0) + amount, 0)
		end
	end
end

local function equip_inventory_item(player: Player, data: PlayerDataTemplate.PlayerData, itemId: string): {ok: boolean, message: string, data: PlayerDataTemplate.PlayerData?}
	ensure_equipment_buffs_applied(data)
	local item = ItemDictionary.get_item(itemId)
	if not item then
		return {
			ok = false,
			message = "Unknown item.",
			data = get_client_data(data),
		}
	end

	if item.category ~= "Equipment" then
		return {
			ok = false,
			message = "This item is not equippable.",
			data = get_client_data(data),
		}
	end

	if item.worldId and item.worldId ~= data.world then
		return {
			ok = false,
			message = "This item belongs to another world.",
			data = get_client_data(data),
		}
	end

	if get_item_stack_amount(data, itemId) <= 0 then
		return {
			ok = false,
			message = "You do not own this item.",
			data = get_client_data(data),
		}
	end

	local slot = item.slot or ""
	if slot == "" then
		return {
			ok = false,
			message = "This item has no equip slot.",
			data = get_client_data(data),
		}
	end

	local validSlots = get_world_equipment_slots(data.world)
	if not table.find(validSlots, slot) then
		return {
			ok = false,
			message = "Slot is not available for this world.",
			data = get_client_data(data),
		}
	end

	local equipped = data.inventory.equipped
	local previousItemId = equipped[slot] or ""
	if previousItemId == itemId then
		return {
			ok = true,
			message = item.displayName .. " is already equipped.",
			data = get_client_data(data),
		}
	end

	if previousItemId ~= "" then
		local previousItem = ItemDictionary.get_item(previousItemId)
		if previousItem then
			apply_item_buffs(data, previousItem.buffs, -1)
		end
	end

	equipped[slot] = itemId
	apply_item_buffs(data, item.buffs, 1)
	apply_player_attributes(player, data)
	fire_data_changed(player)
	save_player_data(player)

	return {
		ok = true,
		message = item.displayName .. " equipped.",
		data = get_client_data(data),
	}
end

local function unequip_inventory_slot(player: Player, data: PlayerDataTemplate.PlayerData, slotName: string): {ok: boolean, message: string, data: PlayerDataTemplate.PlayerData?}
	ensure_equipment_buffs_applied(data)
	local validSlots = get_world_equipment_slots(data.world)
	if not table.find(validSlots, slotName) then
		return {
			ok = false,
			message = "Unknown slot.",
			data = get_client_data(data),
		}
	end

	local equipped = data.inventory.equipped
	local itemId = equipped[slotName] or ""
	if itemId == "" then
		return {
			ok = false,
			message = "Slot is already empty.",
			data = get_client_data(data),
		}
	end

	local item = ItemDictionary.get_item(itemId)
	if item then
		apply_item_buffs(data, item.buffs, -1)
	end

	equipped[slotName] = ""
	apply_player_attributes(player, data)
	fire_data_changed(player)
	save_player_data(player)

	return {
		ok = true,
		message = slotName .. " slot unequipped.",
		data = get_client_data(data),
	}
end

local function use_consumable_item(player: Player, data: PlayerDataTemplate.PlayerData, itemId: string): {ok: boolean, message: string, data: PlayerDataTemplate.PlayerData?}
	ensure_equipment_buffs_applied(data)
	local item = ItemDictionary.get_item(itemId)
	if not item then
		return {
			ok = false,
			message = "Unknown item.",
			data = get_client_data(data),
		}
	end

	if item.category ~= "Consumable" then
		return {
			ok = false,
			message = "This item is not consumable.",
			data = get_client_data(data),
		}
	end

	if item.worldId and item.worldId ~= data.world then
		return {
			ok = false,
			message = "This item belongs to another world.",
			data = get_client_data(data),
		}
	end

	local currentAmount = get_item_stack_amount(data, itemId)
	if currentAmount <= 0 then
		return {
			ok = false,
			message = "You do not have this consumable.",
			data = get_client_data(data),
		}
	end

	data.inventory.itemStacks[itemId] = currentAmount - 1
	apply_consumable_effects(data, item.useEffects)
	apply_player_attributes(player, data)
	fire_data_changed(player)
	save_player_data(player)

	return {
		ok = true,
		message = item.displayName .. " used.",
		data = get_client_data(data),
	}
end

local function add_player_exp(player: Player, data: PlayerDataTemplate.PlayerData, expGain: number): number
	local adjustedExp = math.max(math.floor(expGain * get_active_exp_multiplier(data)), 0)
	local expResult = ExpFormula.add_exp(data.level, data.exp, adjustedExp, GameConfig.LEVEL_CAP)

	data.level = expResult.level
	data.exp = expResult.exp
	unlock_progression_rewards(data)

	if expResult.levelsGained > 0 then
		save_player_data(player)
	end

	return expResult.levelsGained
end

local function grant_login_reward(player: Player, data: PlayerDataTemplate.PlayerData): ()
	local rewardIndex = ((math.max(data.loginStreak, 1) - 1) % #GameConfig.LOGIN_REWARDS) + 1
	local reward = GameConfig.LOGIN_REWARDS[rewardIndex]

	if reward.exp then
		add_player_exp(player, data, reward.exp)
	end

	if reward.worldSouls then
		grant_world_souls(data, reward.worldSouls)
	end

	if reward.rebirthShards then
		data.rebirthShards += reward.rebirthShards
	end

	if reward.item then
		add_inventory_item_stack(data, reward.item, 1)
	end

	if reward.title then
		add_unique(data.titles, reward.title)
	end

	if reward.boostId then
		data.boosts[reward.boostId] = {
			expiresAt = os.time() + reward.boostSeconds,
			expMultiplier = reward.expMultiplier,
		}
	end
end

local function load_player_data(player: Player): PlayerDataTemplate.PlayerData
	local savedData, status = load_saved_data(player)
	if status == "locked" then
		player:SetAttribute("SkipDataSave", true)
		player:Kick("Your data is already active in another server. Please rejoin in a moment.")
	end

	local data = PlayerDataTemplate.merge(savedData)

	apply_created_timestamp(data)
	apply_starting_world(data)
	ensure_inventory_state(data)
	ensure_equipment_buffs_applied(data)
	local shouldGrantLoginReward = apply_daily_login(data)
	unlock_progression_rewards(data)
	playerData[player] = data
	lastTrainAt[player] = 0
	if shouldGrantLoginReward then
		grant_login_reward(player, data)
	end
	apply_player_attributes(player, data)
	return data
end

local function get_player_data(player: Player): PlayerDataTemplate.PlayerData
	local data = playerData[player]
	if data then
		return data
	end

	return load_player_data(player)
end

local function release_session_lock(player: Player): ()
	if not SESSION_LOCKS_ENABLED then
		return
	end

	local lockId = sessionLockIdByPlayer[player]
	if not lockId then
		return
	end

	local success = pcall(function()
		playerDataStore:UpdateAsync(get_data_key(player), function(previousValue)
			local previousTable = if typeof(previousValue) == "table" then previousValue else {}
			if previousTable.lockId ~= lockId then
				return nil
			end

			return {
				data = previousTable.data,
				lockId = "",
				lockTimestamp = 0,
			}
		end)
	end)

	if not success then
		warn("Data lock release failed for " .. player.Name)
	end

	sessionLockIdByPlayer[player] = nil
end

local function set_world_data(data: PlayerDataTemplate.PlayerData, worldId: string): ()
	if worldId == "JJK" then
		data.jjk = data.jjk or {
			curseEnergy = 0,
		}
	end
end

local function select_world(player: Player, worldId: string): {ok: boolean, message: string, data: PlayerDataTemplate.PlayerData?}
	local data = get_player_data(player)
	local world = WorldDictionary.get_world(worldId)

	if data.world ~= "" then
		return {
			ok = false,
			message = "World already selected.",
			data = get_client_data(data),
		}
	end

	if not world then
		return {
			ok = false,
			message = "Unknown world.",
			data = get_client_data(data),
		}
	end

	if not world.active then
		return {
			ok = false,
			message = world.displayName .. " is prepared as a foundation slot.",
			data = get_client_data(data),
		}
	end

	data.world = world.id
	data.abilitiesUnlocked = AbilityDictionary.get_starting_abilities(world.id)
	data.abilitiesEquipped = AbilityDictionary.get_default_equipped(world.id)
	set_world_data(data, world.id)
	ensure_inventory_state(data)
	apply_player_attributes(player, data)
	fire_data_changed(player)
	save_player_data(player)

	return {
		ok = true,
		message = world.displayName .. " selected.",
		data = get_client_data(data),
	}
end

local function get_training_multiplier(data: PlayerDataTemplate.PlayerData): number
	local multiplier = 1
	if os.time() <= data.training.burstEndsAt then
		multiplier *= GameConfig.FOCUS_BURST_MULTIPLIER
	end

	if data.world == "JJK" and data.jjk and data.jjk.curseEnergy >= GameConfig.JJK_OVERFLOW_MIN then
		multiplier += GameConfig.JJK_OVERFLOW_EXP_BONUS
	end

	return multiplier
end

local function train_player(player: Player): {ok: boolean, message: string, data: PlayerDataTemplate.PlayerData?}
	local data = get_player_data(player)
	local currentClock = os.clock()
	local currentTime = os.time()
	local lastTap = lastTrainAt[player] or 0

	if data.world == "" then
		return {
			ok = false,
			message = "Choose a world first.",
			data = get_client_data(data),
		}
	end

	if not can_pay_resource(data, "stamina", -GameConfig.TRAIN_STAMINA_COST) then
		return {
			ok = false,
			message = "Not enough stamina. Use Rest.",
			data = get_client_data(data),
		}
	end

	if currentClock - lastTap < GameConfig.MIN_TRAIN_INTERVAL then
		return {
			ok = false,
			message = "Training too fast.",
			data = get_client_data(data),
		}
	end

	lastTrainAt[player] = currentClock
	data.training.totalTaps += 1
	data.training.focus += GameConfig.FOCUS_PER_TAP
	change_resource(data, "stamina", -GameConfig.TRAIN_STAMINA_COST)
	change_resource(data, "knowledge", GameConfig.CULTIVATE_KNOWLEDGE_GAIN)
	add_daily_quest_progress(data, "Train200", 1)

	local burstTriggered = false
	if data.training.focus >= GameConfig.FOCUS_MAX then
		data.training.focus = 0
		data.training.burstEndsAt = currentTime + GameConfig.FOCUS_BURST_SECONDS
		burstTriggered = true
	end

	if data.world == "JJK" and data.jjk then
		data.jjk.curseEnergy = math.clamp(data.jjk.curseEnergy + GameConfig.JJK_CURSE_ENERGY_PER_TAP, 0, 100)
	end

	if data.training.totalTaps % 10 == 0 then
		grant_world_souls(data, GameConfig.TRAIN_WORLD_SOULS_PER_10_TAPS)
	end

	if data.tutorial and not data.tutorial.complete then
		data.tutorial.step = math.max(data.tutorial.step, if burstTriggered then 4 elseif data.training.focus >= 50 then 3 else 2)
	end

	local expGain = math.floor(GameConfig.TRAIN_EXP_PER_TICK * get_training_multiplier(data))
	local levelsGained = add_player_exp(player, data, expGain)
	local rebirthMultiplier = get_rebirth_stat_multiplier(data)
	data.stats.hp += GameConfig.TRAIN_HP_PER_TICK * rebirthMultiplier
	data.stats.atk += GameConfig.TRAIN_ATK_PER_TICK * rebirthMultiplier
	data.stats.def += GameConfig.TRAIN_DEF_PER_TICK * rebirthMultiplier
	data.stats.spd += GameConfig.TRAIN_SPD_PER_TICK

	apply_player_attributes(player, data)
	fire_data_changed(player)

	return {
		ok = true,
		message = burstTriggered and "Focus Burst!" or levelsGained > 0 and "Level up!" or "Cultivation gained.",
		data = get_client_data(data),
	}
end

local function get_battle_tier(tierNumber: number): any
	local clampedTier = math.clamp(math.floor(tierNumber), 1, #GameConfig.BATTLE_TIERS)
	return GameConfig.BATTLE_TIERS[clampedTier]
end

local function get_enemy_name(data: PlayerDataTemplate.PlayerData, tier: any): string
	return tier.jjkEnemy
end

local function get_scaled_enemy_stats(data: PlayerDataTemplate.PlayerData, tier: any): {hp: number, atk: number, def: number}
	local level = data.level
	local rebirthScale = 1 + ((data.rebirthCount or 0) * 0.25)

	return {
		hp = tier.baseHp * (1 + level / 80) * rebirthScale,
		atk = tier.baseAtk * (1 + level / 100) * rebirthScale,
		def = tier.baseDef * (1 + level / 120) * rebirthScale,
	}
end

local function get_damage_after_defense(rawDamage: number, defense: number): number
	return rawDamage * (1 - defense / (defense + 500))
end

local function get_crit_chance(data: PlayerDataTemplate.PlayerData): number
	local bonus = if list_has(data.abilitiesUnlocked, "SharinganPerception") then 0.15 else 0
	return math.clamp((data.stats.luck or 0) / 1000 + bonus, 0, 0.4)
end

local function get_dodge_chance(data: PlayerDataTemplate.PlayerData): number
	return math.clamp((data.stats.spd or 0) / 800, 0, 0.35)
end

local function get_action_ability(data: PlayerDataTemplate.PlayerData, actionName: string): AbilityDictionary.AbilityDefinition?
	if actionName == "Punch" then
		return AbilityDictionary.get_ability(data.world, data.abilitiesEquipped[1] or data.abilitiesUnlocked[1] or "")
	elseif actionName == "Whack" then
		return AbilityDictionary.get_ability(data.world, data.abilitiesEquipped[2] or data.abilitiesEquipped[1] or data.abilitiesUnlocked[1] or "")
	end

	return AbilityDictionary.get_ability(data.world, actionName)
end

local function prepare_ability_use(data: PlayerDataTemplate.PlayerData, ability: AbilityDictionary.AbilityDefinition, nowTime: number): (boolean, string, boolean, boolean)
	if not list_has(data.abilitiesUnlocked, ability.id) then
		return false, ability.displayName .. " is locked.", false, false
	end

	local cooldownEnd = data.abilityCooldowns[ability.id]
	if typeof(cooldownEnd) == "number" and cooldownEnd > nowTime then
		return false, ability.displayName .. " is on cooldown.", false, false
	end

	local overflow = false
	local backlash = false

	if data.world == "JJK" and data.jjk and ability.cost > 0 then
		local meter = data.jjk.curseEnergy or 0
		overflow = meter >= GameConfig.JJK_OVERFLOW_MIN

		if meter < 10 then
			backlash = true
		elseif meter >= GameConfig.FOCUS_MAX then
			data.jjk.curseEnergy = 0
		elseif meter >= ability.cost then
			data.jjk.curseEnergy = math.max(meter - ability.cost, 0)
		else
			return false, "Not enough Cursed Energy.", false, false
		end
	end

	if ability.cooldown > 0 then
		local upgradeState = get_world_upgrade_state(data, data.world)
		local animeModule = get_anime_module(data.world)
		local cooldownUpgrade = animeModule and animeModule.upgrades and animeModule.upgrades.cooldownFocus or nil
		local cooldownFocus = upgradeState.permanent and upgradeState.permanent.cooldownFocus or 0
		local reductionPerLevel = cooldownUpgrade and cooldownUpgrade.cooldownReductionPerLevel or 0
		local cooldownReduction = math.clamp(cooldownFocus * reductionPerLevel, 0, 0.25)
		data.abilityCooldowns[ability.id] = nowTime + math.max(1, ability.cooldown * (1 - cooldownReduction))
	end

	return true, "", overflow, backlash
end

local function resolve_standard_battle(player: Player, data: PlayerDataTemplate.PlayerData, tierNumber: number, manual: boolean, ability: AbilityDictionary.AbilityDefinition?): {ok: boolean, message: string, data: PlayerDataTemplate.PlayerData?}
	local tier = get_battle_tier(tierNumber)
	if data.level < tier.levelGate then
		return {
			ok = false,
			message = "Tier " .. tostring(tier.tier) .. " unlocks at Level " .. tostring(tier.levelGate) .. ".",
			data = get_client_data(data),
		}
	end

	local nowTime = os.time()
	local enemy = get_scaled_enemy_stats(data, tier)
	local enemyName = get_enemy_name(data, tier)
	local multiplier = 1
	local overflow = false
	local backlash = false

	if ability then
		local canUse, reason
		canUse, reason, overflow, backlash = prepare_ability_use(data, ability, nowTime)
		if not canUse then
			return {
				ok = false,
				message = reason,
				data = get_client_data(data),
			}
		end

		multiplier = ability.multiplier
		if data.world == "JJK" and overflow then
			if ability.id == "BlackFlash" then
				multiplier = 3
			else
				multiplier *= 1.15
			end
		end
	end

	local rawDamage = (data.stats.atk or 0) * multiplier
	local playerDamage = get_damage_after_defense(rawDamage, enemy.def)
	if manual then
		playerDamage *= 1.5
	end

	local didCrit = math.random() < get_crit_chance(data)
	if didCrit then
		playerDamage *= 1.5
	end

	local roundsToWin = math.max(math.ceil(enemy.hp / math.max(playerDamage, 1)), 1)
	local enemyDamage = get_damage_after_defense(enemy.atk, data.stats.def or 0)
	local expectedIncomingDamage = enemyDamage * roundsToWin * (1 - get_dodge_chance(data))
	if ability and (ability.id == "CursedVeil" or ability.id == "SagesGuard") then
		expectedIncomingDamage *= 0.5
	end
	if backlash then
		expectedIncomingDamage += (data.stats.hp or 100) * GameConfig.JJK_BACKLASH_MAX_HP_PERCENT
	end

	local won = expectedIncomingDamage < (data.stats.hp or 100)
	local baseExp = GameConfig.BATTLE_EXP_GAIN * tier.expMultiplier
	local expGain = math.floor(baseExp * (manual and (1 + GameConfig.MANUAL_BATTLE_EXP_BONUS) or 1))
	if data.moralPath == "Conqueror" then
		expGain = math.floor(expGain * (1 + GameConfig.CONQUEROR_BATTLE_EXP_BONUS))
	end

	if won then
		local levelsGained = add_player_exp(player, data, expGain)
		grant_world_souls(data, tier.souls)
		add_daily_quest_progress(data, "Win5Battles", 1)
		data.progress.battleWins += 1
		data.stats.hp += 0.35 * get_rebirth_stat_multiplier(data)
		data.stats.atk += 0.5 * get_rebirth_stat_multiplier(data)
		data.stats.def += 0.25 * get_rebirth_stat_multiplier(data)
		data.stats.luck += 0.05
		data.battle.lastResult = "Win"
		data.battle.lastEnemy = enemyName
		data.battle.lastGodTaunt = ""
		if data.tutorial and data.level >= 3 then
			data.tutorial.step = math.max(data.tutorial.step, 7)
		end

		apply_player_attributes(player, data)
		fire_data_changed(player)

		return {
			ok = true,
			message = (levelsGained > 0 and "Level up! " or "") .. enemyName .. " defeated.",
			data = get_client_data(data),
		}
	end

	if data.battle.reviveCharges and data.battle.reviveCharges > 0 then
		data.battle.reviveCharges -= 1
		add_player_exp(player, data, math.floor(expGain * 0.5))
	end

	local soulsLost = math.floor((data.battle.sessionSouls or 0) * 0.02)
	data.worldSouls = math.max(data.worldSouls - soulsLost, 0)
	if data.world == "JJK" and data.jjk then
		data.jjk.curseEnergy = 0
	end

	local taunts = {
		"Pathetic.",
		"Get up. You're better than this. Probably.",
		"Did you really think it would be that easy?",
		"Even the chosen fall. The question is - do you stay down?",
		"I've seen souls break at this exact moment. Don't be one of them.",
	}
	data.battle.lastResult = "Loss"
	data.battle.lastEnemy = enemyName
	data.battle.lastGodTaunt = if math.random() < 0.3 then taunts[math.random(1, #taunts)] else ""

	apply_player_attributes(player, data)
	fire_data_changed(player)

	return {
		ok = true,
		message = enemyName .. " defeated you.",
		data = get_client_data(data),
	}
end

local function battle_action(player: Player, actionName: string): {ok: boolean, message: string, data: PlayerDataTemplate.PlayerData?}
	local data = get_player_data(player)
	if data.world == "" then
		return {
			ok = false,
			message = "Choose a world first.",
			data = get_client_data(data),
		}
	end

	if actionName == "Block" then
		change_resource(data, "stamina", 1)
		data.stats.def += 0.4
		data.battle.lastResult = "Block"
		fire_data_changed(player)
		return {
			ok = true,
			message = "Blocked and recovered stamina.",
			data = get_client_data(data),
		}
	end

	local tierNumber = tonumber(string.match(actionName, "%d+")) or data.battle.selectedTier or 1
	local manual = not string.find(actionName, "Auto")
	local ability = get_action_ability(data, actionName)
	if not ability then
		ability = AbilityDictionary.get_ability(data.world, data.abilitiesEquipped[1] or data.abilitiesUnlocked[1] or "")
	end

	return resolve_standard_battle(player, data, tierNumber, manual, ability)
end

local function quest_action(player: Player, questId: string): {ok: boolean, message: string, data: PlayerDataTemplate.PlayerData?}
	local data = get_player_data(player)
	local quest = QuestDictionary.get_quest(questId)

	if data.world == "" then
		return {
			ok = false,
			message = "Choose a world first.",
			data = get_client_data(data),
		}
	end

	if not quest then
		return {
			ok = false,
			message = "Unknown quest.",
			data = get_client_data(data),
		}
	end

	local available, unavailableReason = is_quest_available(data, quest)
	if not available then
		return {
			ok = false,
			message = unavailableReason,
			data = get_client_data(data),
		}
	end

	local questProgress = data.progress.questProgress
	local claimedQuests = data.progress.claimedQuests
	local requiredProgress = quest.requiredProgress
	local currentProgress = questProgress[quest.id] or 0
	local isClaimed = table.find(claimedQuests, quest.id) ~= nil
	local storyRunCount = if data.world == "JJK" and quest.questType == "Story" then get_jjk_upgrade_state(data).storyRuns else 0

	if quest.repeatable then
		local activeRepeatable = repeatableInFlight[player]
		if activeRepeatable then
			return {
				ok = false,
				message = "Finish the current repeatable first.",
				data = get_client_data(data),
			}
		end

		repeatableInFlight[player] = quest.id
		if not can_pay_resource(data, "stamina", quest.staminaChange) or not can_pay_resource(data, "food", quest.foodChange) or not can_pay_resource(data, "knowledge", quest.knowledgeChange) then
			repeatableInFlight[player] = nil
			return {
				ok = false,
				message = "Not enough resources.",
				data = get_client_data(data),
			}
		end

		change_resource(data, "stamina", quest.staminaChange)
		change_resource(data, "food", quest.foodChange)
		change_resource(data, "knowledge", quest.knowledgeChange)
		apply_stat_changes(data, quest.statRewards, 1)
		questProgress[quest.id] = (questProgress[quest.id] or 0) + 1
		grant_quest_item_rewards(data, quest.rewardItems)

		grant_world_souls(data, quest.rewardSouls)
		data.progress.questsCompleted += 1
		local repeatableExp = quest.rewardExp
		if data.moralPath == "Protector" then
			repeatableExp = math.floor(repeatableExp * (1 + GameConfig.PROTECTOR_QUEST_EXP_BONUS))
		end
		add_player_exp(player, data, repeatableExp)

		apply_player_attributes(player, data)
		fire_data_changed(player)
		repeatableInFlight[player] = nil

		return {
			ok = true,
			message = quest.displayName .. " completed.",
			data = get_client_data(data),
		}
	end

	if not quest.repeatable and not quest.maxCompletions and (table.find(data.storyQuests, quest.id) or isClaimed) then
		return {
			ok = false,
			message = quest.displayName .. " already completed.",
			data = get_client_data(data),
		}
	end

	if quest.maxCompletions and storyRunCount >= quest.maxCompletions then
		return {
			ok = false,
			message = "Story path complete.",
			data = get_client_data(data),
		}
	end

	if currentProgress < requiredProgress then
		if not can_pay_resource(data, "stamina", quest.staminaChange) or not can_pay_resource(data, "food", quest.foodChange) or not can_pay_resource(data, "knowledge", quest.knowledgeChange) then
			return {
				ok = false,
				message = "Not enough resources.",
				data = get_client_data(data),
			}
		end

		change_resource(data, "stamina", quest.staminaChange)
		change_resource(data, "food", quest.foodChange)
		change_resource(data, "knowledge", quest.knowledgeChange)

		currentProgress += 1
		questProgress[quest.id] = currentProgress
		apply_player_attributes(player, data)
		fire_data_changed(player)

		return {
			ok = true,
			message = "Story progress advanced.",
			data = get_client_data(data),
		}
	end

	if not quest.repeatable and not can_pay_stat_costs(data, quest.statCosts) then
		return {
			ok = false,
			message = "Not enough stats for this Story upgrade.",
			data = get_client_data(data),
		}
	end

	if not quest.repeatable then
		apply_stat_changes(data, quest.statCosts, -1)
	end

	apply_stat_changes(data, quest.statRewards, 1)

	grant_world_souls(data, quest.rewardSouls)
	data.progress.questsCompleted += 1
	local questExp = quest.rewardExp
	if data.moralPath == "Protector" then
		questExp = math.floor(questExp * (1 + GameConfig.PROTECTOR_QUEST_EXP_BONUS))
	end
	add_player_exp(player, data, questExp)
	grant_quest_item_rewards(data, quest.rewardItems)
	apply_story_upgrade_unlocks(data, data.world, quest.unlockUpgrades)

	questProgress[quest.id] = 0
	if quest.maxCompletions then
		local upgradeMessage = apply_jjk_story_upgrade(data, quest)
		table.insert(data.storyQuests, quest.id .. "_" .. tostring(get_jjk_upgrade_state(data).storyRuns))
		if get_jjk_upgrade_state(data).storyRuns >= quest.maxCompletions then
			table.insert(claimedQuests, quest.id)
		end
		save_player_data(player)
		apply_player_attributes(player, data)
		fire_data_changed(player)
		return {
			ok = true,
			message = upgradeMessage,
			data = get_client_data(data),
		}
	else
		table.insert(claimedQuests, quest.id)
		table.insert(data.storyQuests, quest.id)
	end
	save_player_data(player)

	apply_player_attributes(player, data)
	fire_data_changed(player)

	return {
		ok = true,
		message = quest.displayName .. " completed.",
		data = get_client_data(data),
	}
end

local function buy_shop_item(player: Player, data: PlayerDataTemplate.PlayerData, itemId: string): {ok: boolean, message: string, data: PlayerDataTemplate.PlayerData?}
	local item = GameConfig.SHOP_ITEMS[itemId]
	if not item then
		return {
			ok = false,
			message = "Unknown shop item.",
			data = get_client_data(data),
		}
	end

	local purchasedToday = data.shopPurchases[itemId] or 0
	if purchasedToday >= item.dailyLimit then
		return {
			ok = false,
			message = "Daily limit reached.",
			data = get_client_data(data),
		}
	end

	if data.worldSouls < item.price then
		return {
			ok = false,
			message = "Not enough World Souls.",
			data = get_client_data(data),
		}
	end

	data.worldSouls -= item.price
	data.shopPurchases[itemId] = purchasedToday + 1

	if item.exp then
		add_player_exp(player, data, item.exp)
	end

	if item.statMultiplier then
		data.boosts.StatBoostPill = {
			expiresAt = os.time() + item.boostSeconds,
			statMultiplier = item.statMultiplier,
		}
	end

	if item.resetCooldowns then
		data.abilityCooldowns = {}
	end

	if item.focusCharge then
		data.training.focus = GameConfig.FOCUS_MAX
	end

	if item.battleRevive then
		data.battle.reviveCharges = (data.battle.reviveCharges or 0) + 1
	end

	apply_player_attributes(player, data)
	fire_data_changed(player)
	save_player_data(player)

	return {
		ok = true,
		message = "Purchased " .. itemId .. ".",
		data = get_client_data(data),
	}
end

local function buy_world_upgrade(player: Player, data: PlayerDataTemplate.PlayerData, worldId: string, upgradeId: string): {ok: boolean, message: string, data: PlayerDataTemplate.PlayerData?}
	if data.world ~= worldId then
		return {
			ok = false,
			message = "This upgrade path belongs to another world.",
			data = get_client_data(data),
		}
	end

	local animeModule = get_anime_module(worldId)
	local upgrade = animeModule and animeModule.upgrades and animeModule.upgrades[upgradeId] or nil
	if not upgrade then
		return {
			ok = false,
			message = "Unknown world upgrade.",
			data = get_client_data(data),
		}
	end

	local state = get_world_upgrade_state(data, worldId)
	local currentLevel = state.permanent[upgradeId] or 0
	if currentLevel >= upgrade.maxLevel then
		return {
			ok = false,
			message = "Upgrade is maxed.",
			data = get_client_data(data),
		}
	end

	local nextLevel = currentLevel + 1
	local soulCost = upgrade.baseSoulCost * nextLevel
	local shardCost = if upgrade.shardCostEvery > 0 and nextLevel % upgrade.shardCostEvery == 0 then 1 else 0

	if data.worldSouls < soulCost then
		return {
			ok = false,
			message = "Need " .. tostring(soulCost) .. " World Souls.",
			data = get_client_data(data),
		}
	end

	if data.rebirthShards < shardCost then
		return {
			ok = false,
			message = "Need " .. tostring(shardCost) .. " Rebirth Shard.",
			data = get_client_data(data),
		}
	end

	data.worldSouls -= soulCost
	data.rebirthShards -= shardCost
	state.permanent[upgradeId] = nextLevel
	apply_upgrade_level_bonus(data, worldId, upgradeId, 1)

	apply_player_attributes(player, data)
	fire_data_changed(player)
	save_player_data(player)

	return {
		ok = true,
		message = "Upgrade " .. upgradeId .. " Lv " .. tostring(nextLevel) .. ".",
		data = get_client_data(data),
	}
end

local function choose_moral_path(player: Player, data: PlayerDataTemplate.PlayerData, moralPath: string): {ok: boolean, message: string, data: PlayerDataTemplate.PlayerData?}
	if data.level < 100 then
		return {
			ok = false,
			message = "Moral path unlocks at Level 100.",
			data = get_client_data(data),
		}
	end

	if data.moralPath ~= nil then
		return {
			ok = false,
			message = "Moral path already chosen.",
			data = get_client_data(data),
		}
	end

	data.moralPath = moralPath
	add_unique(data.titles, if moralPath == "Protector" then "Protector" else "Conqueror")
	unlock_progression_rewards(data)
	fire_data_changed(player)
	save_player_data(player)

	return {
		ok = true,
		message = moralPath .. " path chosen.",
		data = get_client_data(data),
	}
end

local function rebirth_player(player: Player, data: PlayerDataTemplate.PlayerData): {ok: boolean, message: string, data: PlayerDataTemplate.PlayerData?}
	if data.level < 500 then
		return {
			ok = false,
			message = "Rebirth unlocks at Level 500.",
			data = get_client_data(data),
		}
	end

	if data.rebirthCount >= GameConfig.MAX_REBIRTHS then
		return {
			ok = false,
			message = "True Immortal reached.",
			data = get_client_data(data),
		}
	end

	local worldId = data.world
	local keptTitles = PlayerDataTemplate.copy(data.titles)
	local keptLore = PlayerDataTemplate.copy(data.loreLogs)
	local keptSouls = data.worldSouls
	local keptTokens = data.divineTokens
	local keptShards = data.rebirthShards
	local keptPeak = math.max(data.peakImmortalityPct or 0, calculate_immortality_pct(data))
	local nextRebirth = data.rebirthCount + 1

	local freshData = PlayerDataTemplate.create()
	for key, value in freshData do
		data[key] = value
	end

	data.world = worldId
	set_world_data(data, worldId)
	data.rebirthCount = nextRebirth
	data.worldSouls = keptSouls
	data.divineTokens = keptTokens
	data.rebirthShards = keptShards
	data.peakImmortalityPct = keptPeak
	data.loreLogs = keptLore
	data.titles = keptTitles
	add_unique(data.titles, GameConfig.REBIRTH_TITLES[nextRebirth])
	data.activeTitle = GameConfig.REBIRTH_TITLES[nextRebirth]
	data.abilitiesUnlocked = AbilityDictionary.get_starting_abilities(worldId)
	data.abilitiesEquipped = AbilityDictionary.get_default_equipped(worldId)
	unlock_progression_rewards(data)
	apply_player_attributes(player, data)
	fire_data_changed(player)
	save_player_data(player)

	return {
		ok = true,
		message = "Rebirth complete.",
		data = get_client_data(data),
	}
end

local function resolve_boss_fight(player: Player, data: PlayerDataTemplate.PlayerData): {ok: boolean, message: string, data: PlayerDataTemplate.PlayerData?}
	local bossLevel = if data.level >= 500 then 500 elseif data.level >= 300 then 300 elseif data.level >= 100 then 100 elseif data.level >= 25 then 25 else 1
	local bossId = data.world .. "_Boss_" .. tostring(bossLevel)
	local hpMultiplier = if bossLevel >= 500 then 30 elseif bossLevel >= 300 then 22 elseif bossLevel >= 100 then 15 elseif bossLevel >= 25 then 8 else 5
	local atkMultiplier = if bossLevel >= 500 then 2.5 elseif bossLevel >= 300 then 2.2 elseif bossLevel >= 100 then 1.8 elseif bossLevel >= 25 then 1.5 else 1.2

	if data.boss.activeBossId ~= bossId or data.boss.remainingHp <= 0 then
		data.boss.activeBossId = bossId
		data.boss.remainingHp = (data.stats.hp or 100) * hpMultiplier
		data.boss.attempts = 0
	end

	local bossAtk = (data.stats.atk or 10) * atkMultiplier
	if data.boss.attempts >= 5 then
		bossAtk *= 0.85
	end

	local ability = AbilityDictionary.get_ability(data.world, data.abilitiesEquipped[1] or data.abilitiesUnlocked[1] or "")
	local playerDamage = get_damage_after_defense((data.stats.atk or 10) * (ability and ability.multiplier or 1), (data.stats.def or 0) * hpMultiplier)
	if data.boss.remainingHp <= ((data.stats.hp or 100) * 0.33) then
		playerDamage *= 2
	end

	data.boss.remainingHp = math.max(data.boss.remainingHp - playerDamage, 0)
	data.boss.lastPhase = if data.boss.remainingHp <= ((data.stats.hp or 100) * hpMultiplier * 0.33) then 3 elseif data.boss.remainingHp <= ((data.stats.hp or 100) * hpMultiplier * 0.66) then 2 else 1

	if data.boss.remainingHp <= 0 then
		data.boss.activeBossId = ""
		data.boss.attempts = 0
		data.boss.lastPhase = 0
		grant_world_souls(data, bossLevel)
		add_player_exp(player, data, GameConfig.BATTLE_EXP_GAIN * bossLevel)
		add_unique(data.storyQuests, "Boss_" .. tostring(bossLevel))
		unlock_progression_rewards(data)
		save_player_data(player)
		fire_data_changed(player)
		return {
			ok = true,
			message = "Story boss defeated.",
			data = get_client_data(data),
		}
	end

	local incomingDamage = get_damage_after_defense(bossAtk, data.stats.def or 0)
	local survived = incomingDamage < (data.stats.hp or 100)
	if not survived then
		data.boss.attempts += 1
	end

	fire_data_changed(player)
	return {
		ok = true,
		message = survived and "Boss phase advanced." or "Boss attempt failed. Boss HP stayed damaged.",
		data = get_client_data(data),
	}
end

local function player_action(player: Player, actionName: string): {ok: boolean, message: string, data: PlayerDataTemplate.PlayerData?}
	local data = get_player_data(player)

	if actionName == "Stop" then
		data.currentAction = "Idle"
		fire_data_changed(player)
		return {
			ok = true,
			message = "Action stopped.",
			data = get_client_data(data),
		}
	end

	if data.world == "" then
		return {
			ok = false,
			message = "Choose a world first.",
			data = get_client_data(data),
		}
	end

	ensure_equipment_buffs_applied(data)

	local message = ""

	if string.sub(actionName, 1, 10) == "EquipItem:" then
		return equip_inventory_item(player, data, string.sub(actionName, 11))
	elseif string.sub(actionName, 1, 11) == "UnequipSlot:" then
		return unequip_inventory_slot(player, data, string.sub(actionName, 12))
	elseif string.sub(actionName, 1, 8) == "UseItem:" then
		return use_consumable_item(player, data, string.sub(actionName, 9))
	elseif string.sub(actionName, 1, 3) == "Buy" then
		return buy_shop_item(player, data, string.sub(actionName, 4))
	elseif string.sub(actionName, 1, 10) == "JJKUpgrade" then
		return buy_world_upgrade(player, data, "JJK", string.sub(actionName, 11))
	elseif actionName == "ChooseProtector" then
		return choose_moral_path(player, data, "Protector")
	elseif actionName == "ChooseConqueror" then
		return choose_moral_path(player, data, "Conqueror")
	elseif actionName == "Rebirth" then
		return rebirth_player(player, data)
	elseif actionName == "Boss" then
		return resolve_boss_fight(player, data)
	elseif string.sub(actionName, 1, 13) == "SetBattleTier" then
		local tierNumber = tonumber(string.sub(actionName, 14)) or 1
		data.battle.selectedTier = math.clamp(math.floor(tierNumber), 1, #GameConfig.BATTLE_TIERS)
		message = "Battle tier set to " .. tostring(data.battle.selectedTier) .. "."
	elseif actionName == "Cultivate" then
		if not can_pay_resource(data, "stamina", -GameConfig.CULTIVATE_STAMINA_COST) then
			return {
				ok = false,
				message = "Not enough stamina. Use Rest.",
				data = get_client_data(data),
			}
		end

		local cultivation = data.cultivation
		local qiGain = GameConfig.CULTIVATE_QI_PER_TICK * (cultivation.manualMultiplier or 1)
		change_resource(data, "stamina", -GameConfig.CULTIVATE_STAMINA_COST)
		cultivation.qi = math.min((cultivation.qi or 0) + qiGain, cultivation.qiRequired or 100)
		add_player_exp(player, data, GameConfig.TRAIN_EXP_PER_TICK)
		if data.world == "JJK" and data.jjk then
			data.jjk.curseEnergy = math.clamp((data.jjk.curseEnergy or 0) + GameConfig.JJK_CURSE_ENERGY_PER_TAP, 0, 100)
		end
		data.currentAction = "Cultivate"
		message = "Cultivation gained."
	elseif actionName == "Rest" then
		change_resource(data, "stamina", GameConfig.REST_STAMINA_PER_TICK)
		change_resource(data, "food", 1)
		data.currentAction = "Rest"
		message = "Recovered stamina."
	elseif actionName == "Work" then
		if not can_pay_resource(data, "stamina", -GameConfig.WORK_STAMINA_COST) then
			return {
				ok = false,
				message = "Not enough stamina to work.",
				data = get_client_data(data),
			}
		end

		change_resource(data, "stamina", -GameConfig.WORK_STAMINA_COST)
		change_resource(data, "gold", GameConfig.WORK_GOLD_GAIN)
		data.currentAction = "Work"
		message = "Work completed."
	elseif actionName == "Explore" then
		if not can_pay_resource(data, "stamina", -GameConfig.EXPLORE_STAMINA_COST) then
			return {
				ok = false,
				message = "Not enough stamina to explore.",
				data = get_client_data(data),
			}
		end

		change_resource(data, "stamina", -GameConfig.EXPLORE_STAMINA_COST)
		change_resource(data, "knowledge", GameConfig.EXPLORE_KNOWLEDGE_GAIN)
		change_resource(data, "gold", GameConfig.EXPLORE_GOLD_GAIN)
		data.currentAction = "Explore"
		message = "Exploration completed."
	elseif actionName == "Breakthrough" then
		local cultivation = data.cultivation
		local qi = cultivation.qi or 0
		local qiRequired = cultivation.qiRequired or 100
		if qi < qiRequired then
			return {
				ok = false,
				message = "Not enough Qi for breakthrough.",
				data = get_client_data(data),
			}
		end

		local maxRealm = #GameConfig.REALM_NAMES
		if (cultivation.realmIndex or 1) >= maxRealm and (cultivation.stage or 1) >= 9 then
			return {
				ok = false,
				message = "Peak realm reached.",
				data = get_client_data(data),
			}
		end

		local successChance = math.clamp(GameConfig.BREAKTHROUGH_BASE_CHANCE + ((data.stats.luck or 0) * 0.01), 0, 0.95)
		if math.random() <= successChance then
			cultivation.qi = 0
			cultivation.stage = (cultivation.stage or 1) + 1
			if cultivation.stage > 9 then
				cultivation.stage = 1
				cultivation.realmIndex = math.min((cultivation.realmIndex or 1) + 1, maxRealm)
			end
			cultivation.qiRequired = math.max(100, math.floor(qiRequired * 1.35))
			add_player_exp(player, data, GameConfig.TRAIN_EXP_PER_TICK * 4)
			message = "Breakthrough succeeded."
		else
			cultivation.qi = math.floor(qi * (1 - GameConfig.BREAKTHROUGH_QI_LOSS_LIGHT))
			message = "Breakthrough failed."
		end

		data.currentAction = "Idle"
	else
		return {
			ok = false,
			message = "Unknown action.",
			data = get_client_data(data),
		}
	end

	apply_player_attributes(player, data)
	fire_data_changed(player)

	return {
		ok = true,
		message = message,
		data = get_client_data(data),
	}
end

local function update_setting(player: Player, settingName: string, enabled: boolean): {ok: boolean, message: string, data: PlayerDataTemplate.PlayerData?}
	local data = get_player_data(player)
	if typeof(data.settings[settingName]) ~= "boolean" then
		return {
			ok = false,
			message = "Unknown setting.",
			data = get_client_data(data),
		}
	end

	data.settings[settingName] = enabled == true
	fire_data_changed(player)

	return {
		ok = true,
		message = "Setting updated.",
		data = get_client_data(data),
	}
end

local function ensure_remotes(): ()
	remoteFolder = RemoteController.create_folder()
	getPlayerDataRemote = RemoteController.create_function(RemoteNames.getPlayerData)
	selectWorldRemote = RemoteController.create_function(RemoteNames.selectWorld)
	trainRemote = RemoteController.create_function(RemoteNames.train)
	playerActionRemote = RemoteController.create_function(RemoteNames.playerAction)
	battleActionRemote = RemoteController.create_function(RemoteNames.battleAction)
	questActionRemote = RemoteController.create_function(RemoteNames.questAction)
	updateSettingRemote = RemoteController.create_function(RemoteNames.updateSetting)
	dataChangedRemote = RemoteController.create_event(RemoteNames.dataChanged)
	notifyRemote = RemoteController.create_event(RemoteNames.notify)
end

------------------//MAIN FUNCTIONS
local function on_player_added(player: Player): ()
	load_player_data(player)
	fire_data_changed(player)
end

local function on_player_removing(player: Player): ()
	if player:GetAttribute("SkipDataSave") ~= true then
		save_player_data(player)
	end
	release_session_lock(player)
	repeatableInFlight[player] = nil
	playerData[player] = nil
	lastTrainAt[player] = nil
end

local function connect_remotes(): ()
	(getPlayerDataRemote :: RemoteFunction).OnServerInvoke = function(player: Player)
		return get_client_data(get_player_data(player))
	end

	(selectWorldRemote :: RemoteFunction).OnServerInvoke = function(player: Player, worldId: string)
		local result = select_world(player, worldId)
		if not result.ok then
			send_notice(player, result.message)
		end
		return result
	end

	(trainRemote :: RemoteFunction).OnServerInvoke = function(player: Player)
		local result = train_player(player)
		if not result.ok then
			send_notice(player, result.message)
		end
		return result
	end

	(playerActionRemote :: RemoteFunction).OnServerInvoke = function(player: Player, actionName: string)
		local result = player_action(player, actionName)
		if not result.ok then
			send_notice(player, result.message)
		end
		return result
	end

	(battleActionRemote :: RemoteFunction).OnServerInvoke = function(player: Player, actionName: string)
		local result = battle_action(player, actionName)
		if not result.ok then
			send_notice(player, result.message)
		end
		return result
	end

	(questActionRemote :: RemoteFunction).OnServerInvoke = function(player: Player, questId: string)
		local result = quest_action(player, questId)
		if not result.ok then
			send_notice(player, result.message)
		end
		return result
	end

	(updateSettingRemote :: RemoteFunction).OnServerInvoke = function(player: Player, settingName: string, enabled: boolean)
		local result = update_setting(player, settingName, enabled)
		if not result.ok then
			send_notice(player, result.message)
		end
		return result
	end
end

local function start_auto_save(): ()
	task.spawn(function()
		while true do
			task.wait(GameConfig.AUTO_SAVE_SECONDS)
			for player in playerData do
				save_player_data(player)
			end
		end
	end)
end

local function start_progress_loop(): ()
	task.spawn(function()
		local elapsedSeconds = 0
		while true do
			task.wait(GameConfig.ACTION_TICK_SECONDS)
			elapsedSeconds += GameConfig.ACTION_TICK_SECONDS

			for player, data in playerData do
				data.progress.playtimeSeconds += GameConfig.ACTION_TICK_SECONDS
				add_daily_quest_progress(data, "Play30Minutes", GameConfig.ACTION_TICK_SECONDS)

				if data.world == "JJK" and data.jjk then
					local passiveGain = GameConfig.JJK_CURSE_ENERGY_PASSIVE_PER_10_SECONDS / 10 * GameConfig.ACTION_TICK_SECONDS
					data.jjk.curseEnergy = math.clamp((data.jjk.curseEnergy or 0) + passiveGain, 0, 100)
				end

				if data.currentAction == "Rest" then
					change_resource(data, "stamina", GameConfig.REST_STAMINA_PER_TICK)
				elseif data.currentAction == "Cultivate" then
					local cultivation = data.cultivation
					cultivation.qi = math.min((cultivation.qi or 0) + GameConfig.CULTIVATE_QI_PER_TICK, cultivation.qiRequired or 100)
					add_player_exp(player, data, math.floor(GameConfig.IDLE_EXP_PER_MINUTE / 60))
				elseif data.currentAction == "Work" and can_pay_resource(data, "stamina", -GameConfig.WORK_STAMINA_COST) then
					change_resource(data, "stamina", -GameConfig.WORK_STAMINA_COST)
					change_resource(data, "gold", GameConfig.WORK_GOLD_GAIN)
				end

				update_peak_immortality(data)

				if elapsedSeconds % 5 == 0 then
					fire_data_changed(player)
				end
			end
		end
	end)
end

------------------//INIT
ensure_remotes()
connect_remotes()
start_auto_save()
start_progress_loop()

for _, player in Players:GetPlayers() do
	on_player_added(player)
end

Players.PlayerAdded:Connect(on_player_added)
Players.PlayerRemoving:Connect(on_player_removing)

game:BindToClose(function()
	for player in playerData do
		save_player_data(player)
		release_session_lock(player)
	end
end)

end

return GameServerRuntime
