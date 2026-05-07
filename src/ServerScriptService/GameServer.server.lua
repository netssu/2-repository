------------------//SERVICES
local Players: Players = game:GetService("Players")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage: ServerStorage = game:GetService("ServerStorage")

------------------//CONSTANTS
local MODULES_FOLDER_NAME: string = "Modules"

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
local DataUtility = ModuleCache.require(utilityModules:WaitForChild("DataUtility") :: ModuleScript)
local GameConfig = ModuleCache.require(gameModules:WaitForChild("GameConfig") :: ModuleScript)
local ExpFormula = ModuleCache.require(gameModules:WaitForChild("ExpFormula") :: ModuleScript)
local WorldDictionary = ModuleCache.require(dictionaryModules:WaitForChild("WorldDictionary") :: ModuleScript)
local AbilityDictionary = ModuleCache.require(dictionaryModules:WaitForChild("AbilityDictionary") :: ModuleScript)
local QuestDictionary = ModuleCache.require(dictionaryModules:WaitForChild("QuestDictionary") :: ModuleScript)
local PlayerDataTemplate = ModuleCache.require(serverGameModules:WaitForChild("PlayerDataTemplate") :: ModuleScript)

local playerData: {[Player]: PlayerDataTemplate.PlayerData} = {}
local lastTrainAt: {[Player]: number} = {}
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
	return math.floor(timestamp / 86400)
end

local function calculate_qi_required(realmIndex: number, stage: number): number
	return math.floor(100 * realmIndex ^ 1.8 * stage ^ 1.25)
end

local function get_realm_name(realmIndex: number): string
	return GameConfig.REALM_NAMES[realmIndex] or "Unknown Realm"
end

local function get_cultivation(data: PlayerDataTemplate.PlayerData)
	local cultivation = data.cultivation
	cultivation.realmIndex = cultivation.realmIndex or 1
	cultivation.stage = cultivation.stage or 1
	cultivation.qi = cultivation.qi or 0
	cultivation.talent = cultivation.talent or 1
	cultivation.affinity = cultivation.affinity or "None"
	cultivation.manual = cultivation.manual or "None"
	cultivation.manualMultiplier = cultivation.manualMultiplier or 1
	cultivation.qiRequired = cultivation.qiRequired or calculate_qi_required(cultivation.realmIndex, cultivation.stage)
	return cultivation
end

local function refresh_qi_required(data: PlayerDataTemplate.PlayerData): number
	local cultivation = get_cultivation(data)
	cultivation.qiRequired = calculate_qi_required(cultivation.realmIndex, cultivation.stage)
	return cultivation.qiRequired
end

local function get_cultivation_label(data: PlayerDataTemplate.PlayerData): string
	local cultivation = get_cultivation(data)
	return get_realm_name(cultivation.realmIndex) .. " " .. tostring(cultivation.stage)
end

local function apply_daily_login(data: PlayerDataTemplate.PlayerData): ()
	local currentTime = os.time()
	local lastLoginDay = get_day_number(data.lastLogin)
	local currentDay = get_day_number(currentTime)

	if lastLoginDay ~= currentDay then
		data.dailyQuestsDone = {}
		if currentDay - lastLoginDay == 1 then
			data.loginStreak += 1
		else
			data.loginStreak = 1
		end
	end

	data.lastLogin = currentTime
end

local function apply_player_attributes(player: Player, data: PlayerDataTemplate.PlayerData): ()
	local world = WorldDictionary.get_world(data.world)
	local cultivation = get_cultivation(data)

	player:SetAttribute("World", data.world)
	player:SetAttribute("WorldName", world and world.displayName or "")
	player:SetAttribute("Level", data.level)
	player:SetAttribute("Exp", data.exp)
	player:SetAttribute("Qi", math.floor(cultivation.qi))
	player:SetAttribute("Realm", get_realm_name(cultivation.realmIndex))
	player:SetAttribute("RealmStage", cultivation.stage)
	player:SetAttribute("CurrentAction", data.currentAction)
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

local function save_player_data(player: Player): boolean
	local data = playerData[player]
	if not data then
		return true
	end

	local saved = true
	for fieldName, value in data do
		local success = pcall(DataUtility.server.set, player, fieldName, value)
		if not success then
			saved = false
			break
		end
	end

	return saved
end

local function get_resource_max(data: PlayerDataTemplate.PlayerData, resourceName: string): number?
	if resourceName == "stamina" then
		return data.resources.maxStamina or GameConfig.STAMINA_MAX
	end

	if resourceName == "food" or resourceName == "knowledge" then
		return GameConfig.RESOURCE_MAX
	end

	return nil
end

local function change_resource(data: PlayerDataTemplate.PlayerData, resourceName: string, amount: number): ()
	local currentValue = data.resources[resourceName] or 0
	local maxValue = get_resource_max(data, resourceName)
	local nextValue = currentValue + amount

	if maxValue then
		data.resources[resourceName] = math.clamp(nextValue, 0, maxValue)
	else
		data.resources[resourceName] = math.max(nextValue, 0)
	end
end

local function can_pay_resource(data: PlayerDataTemplate.PlayerData, resourceName: string, amount: number): boolean
	if amount >= 0 then
		return true
	end

	local currentValue = data.resources[resourceName] or 0
	return currentValue + amount >= 0
end

local function add_player_exp(player: Player, data: PlayerDataTemplate.PlayerData, expGain: number): number
	local expResult = ExpFormula.add_exp(data.level, data.exp, expGain, GameConfig.LEVEL_CAP)

	data.level = expResult.level
	data.exp = expResult.exp

	if expResult.levelsGained > 0 then
		save_player_data(player)
	end

	return expResult.levelsGained
end

local function load_player_data(player: Player): PlayerDataTemplate.PlayerData
	local savedData = DataUtility.server.get(player)
	local data = PlayerDataTemplate.merge(savedData)

	apply_daily_login(data)
	data.currentAction = "Idle"
	data.resources.maxStamina = data.resources.maxStamina or GameConfig.STAMINA_MAX
	data.resources.stamina = math.clamp(data.resources.stamina or 0, 0, data.resources.maxStamina)
	refresh_qi_required(data)
	playerData[player] = data
	lastTrainAt[player] = 0
	apply_player_attributes(player, data)
	save_player_data(player)
	return data
end

local function get_player_data(player: Player): PlayerDataTemplate.PlayerData
	local data = playerData[player]
	if data then
		return data
	end

	return load_player_data(player)
end

local function set_world_data(data: PlayerDataTemplate.PlayerData, worldId: string): ()
	local cultivation = get_cultivation(data)

	if worldId == "JJK" then
		data.jjk = {
			curseEnergy = 0,
		}
		data.naruto = nil
		cultivation.affinity = "Cursed"
		cultivation.manual = "Basic Cursed Breathing"
		cultivation.manualMultiplier = 1.05
	elseif worldId == "Naruto" then
		data.naruto = {
			affinity = "",
			clan = "",
		}
		data.jjk = nil
		cultivation.affinity = "Chakra"
		cultivation.manual = "Academy Breathing"
		cultivation.manualMultiplier = 1
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

local function get_cultivation_multiplier(data: PlayerDataTemplate.PlayerData): number
	local cultivation = get_cultivation(data)
	local multiplier = cultivation.talent * cultivation.manualMultiplier

	if data.world == "JJK" and cultivation.affinity == "Cursed" then
		multiplier += 0.1
	end

	return multiplier
end

local function apply_training_tick(player: Player, data: PlayerDataTemplate.PlayerData): string?
	local currentTime = os.time()

	if not can_pay_resource(data, "stamina", -GameConfig.TRAIN_STAMINA_COST) then
		data.currentAction = "Exhausted"
		return "Exhausted. Rest to recover stamina."
	end

	data.training.totalTaps += 1
	data.training.bodyXp += GameConfig.TRAIN_EXP_PER_TICK
	data.training.focus += GameConfig.FOCUS_PER_TAP
	change_resource(data, "stamina", -GameConfig.TRAIN_STAMINA_COST)

	if data.training.focus >= GameConfig.FOCUS_MAX then
		data.training.focus = 0
		data.training.burstEndsAt = currentTime + GameConfig.FOCUS_BURST_SECONDS
	end

	if data.world == "JJK" and data.jjk then
		data.jjk.curseEnergy = math.clamp(data.jjk.curseEnergy + GameConfig.JJK_CURSE_ENERGY_PER_TAP, 0, 100)
	end

	local multiplier = get_training_multiplier(data)
	add_player_exp(player, data, math.floor(GameConfig.TRAIN_EXP_PER_TICK * multiplier))
	data.stats.atk += GameConfig.TRAIN_ATK_PER_TICK * multiplier
	data.stats.def += GameConfig.TRAIN_DEF_PER_TICK * multiplier
	data.stats.spd += GameConfig.TRAIN_SPD_PER_TICK * multiplier
	data.stats.hp += GameConfig.TRAIN_HP_PER_TICK * multiplier

	return nil
end

local function apply_cultivation_tick(data: PlayerDataTemplate.PlayerData): string?
	local cultivation = get_cultivation(data)
	refresh_qi_required(data)

	if cultivation.qi >= cultivation.qiRequired then
		data.currentAction = "Idle"
		return "Qi is full. Attempt a breakthrough."
	end

	local qiGain = GameConfig.CULTIVATE_QI_PER_TICK * get_cultivation_multiplier(data)
	cultivation.qi = math.min(cultivation.qi + qiGain, cultivation.qiRequired)

	if data.world == "JJK" and data.jjk then
		data.jjk.curseEnergy = math.clamp(data.jjk.curseEnergy + 1, 0, 100)
	end

	if cultivation.qi >= cultivation.qiRequired then
		data.currentAction = "Idle"
		return "Qi is full. Attempt a breakthrough."
	end

	return nil
end

local function apply_rest_tick(data: PlayerDataTemplate.PlayerData): string?
	local maxStamina = data.resources.maxStamina or GameConfig.STAMINA_MAX

	if data.resources.stamina >= maxStamina then
		data.resources.stamina = maxStamina
		data.currentAction = "Idle"
		return "Already rested."
	end

	change_resource(data, "stamina", GameConfig.REST_STAMINA_PER_TICK)

	if data.resources.stamina >= maxStamina then
		data.currentAction = "Idle"
		return "Rested."
	end

	return nil
end

local function train_player(player: Player): {ok: boolean, message: string, data: PlayerDataTemplate.PlayerData?}
	local data = get_player_data(player)
	local currentClock = os.clock()
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
			message = "Not enough stamina. Rest first.",
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
	data.currentAction = "Training"
	local tickMessage = apply_training_tick(player, data)
	apply_player_attributes(player, data)
	fire_data_changed(player)

	return {
		ok = true,
		message = tickMessage or "Training started.",
		data = get_client_data(data),
	}
end

local function cultivate_player(player: Player): {ok: boolean, message: string, data: PlayerDataTemplate.PlayerData?}
	local data = get_player_data(player)

	if data.world == "" then
		return {
			ok = false,
			message = "Choose a world first.",
			data = get_client_data(data),
		}
	end

	data.currentAction = "Cultivating"
	local tickMessage = apply_cultivation_tick(data)
	apply_player_attributes(player, data)
	fire_data_changed(player)

	return {
		ok = true,
		message = tickMessage or "Cultivation started.",
		data = get_client_data(data),
	}
end

local function rest_player(player: Player): {ok: boolean, message: string, data: PlayerDataTemplate.PlayerData?}
	local data = get_player_data(player)
	data.currentAction = "Resting"
	local tickMessage = apply_rest_tick(data)
	apply_player_attributes(player, data)
	fire_data_changed(player)

	return {
		ok = true,
		message = tickMessage or "Resting.",
		data = get_client_data(data),
	}
end

local function stop_player_action(player: Player): {ok: boolean, message: string, data: PlayerDataTemplate.PlayerData?}
	local data = get_player_data(player)
	data.currentAction = "Idle"
	apply_player_attributes(player, data)
	fire_data_changed(player)

	return {
		ok = true,
		message = "Action stopped.",
		data = get_client_data(data),
	}
end

local function work_player(player: Player): {ok: boolean, message: string, data: PlayerDataTemplate.PlayerData?}
	local data = get_player_data(player)

	if not can_pay_resource(data, "stamina", -GameConfig.WORK_STAMINA_COST) then
		return {
			ok = false,
			message = "Not enough stamina to work.",
			data = get_client_data(data),
		}
	end

	data.currentAction = "Idle"
	change_resource(data, "stamina", -GameConfig.WORK_STAMINA_COST)
	change_resource(data, "gold", GameConfig.WORK_GOLD_GAIN)
	apply_player_attributes(player, data)
	fire_data_changed(player)

	return {
		ok = true,
		message = "Worked and earned gold.",
		data = get_client_data(data),
	}
end

local function explore_player(player: Player): {ok: boolean, message: string, data: PlayerDataTemplate.PlayerData?}
	local data = get_player_data(player)

	if not can_pay_resource(data, "stamina", -GameConfig.EXPLORE_STAMINA_COST) then
		return {
			ok = false,
			message = "Not enough stamina to explore.",
			data = get_client_data(data),
		}
	end

	data.currentAction = "Idle"
	change_resource(data, "stamina", -GameConfig.EXPLORE_STAMINA_COST)

	local roll = math.random(1, 100)
	local message = "You found nothing."

	if roll <= 40 then
		message = "You found nothing."
	elseif roll <= 65 then
		change_resource(data, "gold", GameConfig.EXPLORE_GOLD_GAIN)
		message = "You found a few coins."
	elseif roll <= 80 then
		message = "You found traces of an enemy."
	elseif roll <= 90 then
		change_resource(data, "knowledge", GameConfig.EXPLORE_KNOWLEDGE_GAIN)
		message = "You noticed something useful."
	elseif roll <= 97 then
		change_resource(data, "food", 1)
		message = "You found a useful herb."
	else
		local cultivation = get_cultivation(data)
		cultivation.manual = "Ancient Breathing Manual"
		cultivation.manualMultiplier = math.max(cultivation.manualMultiplier, 1.2)
		table.insert(data.loreLogs, "Found an ancient manual while exploring.")
		message = "You found an ancient manual."
	end

	apply_player_attributes(player, data)
	fire_data_changed(player)

	return {
		ok = true,
		message = message,
		data = get_client_data(data),
	}
end

local function breakthrough_player(player: Player): {ok: boolean, message: string, data: PlayerDataTemplate.PlayerData?}
	local data = get_player_data(player)
	local cultivation = get_cultivation(data)
	refresh_qi_required(data)

	if cultivation.qi < cultivation.qiRequired then
		return {
			ok = false,
			message = "Not enough Qi for breakthrough.",
			data = get_client_data(data),
		}
	end

	data.currentAction = "Idle"
	local chance = math.clamp(GameConfig.BREAKTHROUGH_BASE_CHANCE + (data.stats.luck * 0.005) + ((cultivation.talent - 1) * 0.08), 0.05, 0.95)

	if math.random() <= chance then
		cultivation.qi = 0
		cultivation.stage += 1
		if cultivation.stage > 9 then
			cultivation.stage = 1
			cultivation.realmIndex += 1
		end

		data.level = math.min(data.level + 1, GameConfig.LEVEL_CAP)
		data.resources.maxStamina += 1
		data.stats.hp += 5
		data.stats.atk += 1
		data.stats.def += 0.5
		refresh_qi_required(data)
		apply_player_attributes(player, data)
		fire_data_changed(player)

		return {
			ok = true,
			message = "Breakthrough succeeded: " .. get_cultivation_label(data) .. ".",
			data = get_client_data(data),
		}
	end

	local failureRoll = math.random()
	if failureRoll <= 0.65 then
		cultivation.qi = math.floor(cultivation.qi * (1 - GameConfig.BREAKTHROUGH_QI_LOSS_LIGHT))
		apply_player_attributes(player, data)
		fire_data_changed(player)
		return {
			ok = false,
			message = "Breakthrough failed. Some Qi was lost.",
			data = get_client_data(data),
		}
	elseif failureRoll <= 0.9 then
		cultivation.qi = math.floor(cultivation.qi * (1 - GameConfig.BREAKTHROUGH_QI_LOSS_HEAVY))
		change_resource(data, "stamina", -math.min(data.resources.stamina, 2))
		apply_player_attributes(player, data)
		fire_data_changed(player)
		return {
			ok = false,
			message = "Breakthrough backlash. Qi and stamina were lost.",
			data = get_client_data(data),
		}
	end

	cultivation.qi = 0
	data.stats.hp = math.max(data.stats.hp - 2, 1)
	apply_player_attributes(player, data)
	fire_data_changed(player)
	return {
		ok = false,
		message = "Critical failure. Your foundation was injured.",
		data = get_client_data(data),
	}
end

local function handle_player_action(player: Player, actionName: string): {ok: boolean, message: string, data: PlayerDataTemplate.PlayerData?}
	if actionName == "Train" then
		return train_player(player)
	elseif actionName == "Cultivate" then
		return cultivate_player(player)
	elseif actionName == "Rest" or actionName == "Sleep" then
		return rest_player(player)
	elseif actionName == "Stop" then
		return stop_player_action(player)
	elseif actionName == "Work" then
		return work_player(player)
	elseif actionName == "Explore" or actionName == "LookAround" then
		return explore_player(player)
	elseif actionName == "Breakthrough" then
		return breakthrough_player(player)
	end

	return {
		ok = false,
		message = "Unknown action.",
		data = get_client_data(get_player_data(player)),
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

	if (actionName == "Punch" or actionName == "Whack") and not can_pay_resource(data, "stamina", -GameConfig.BATTLE_STAMINA_COST) then
		return {
			ok = false,
			message = "Not enough stamina.",
			data = get_client_data(data),
		}
	end

	local expGain = GameConfig.BATTLE_EXP_GAIN
	if actionName == "Punch" then
		change_resource(data, "stamina", -GameConfig.BATTLE_STAMINA_COST)
		data.stats.atk += 0.5
	elseif actionName == "Whack" then
		change_resource(data, "stamina", -GameConfig.BATTLE_STAMINA_COST)
		data.stats.atk += 0.25
		expGain += 4
	elseif actionName == "Block" then
		data.stats.def += 0.4
		expGain -= 4
	else
		return {
			ok = false,
			message = "Unknown action.",
			data = get_client_data(data),
		}
	end

	if data.world == "JJK" and data.jjk then
		data.jjk.curseEnergy = math.clamp(data.jjk.curseEnergy + 1, 0, 100)
	end

	data.currentAction = "Idle"
	data.worldSouls += GameConfig.BATTLE_SOULS_GAIN
	data.progress.battleWins += 1
	add_player_exp(player, data, expGain)
	apply_player_attributes(player, data)
	fire_data_changed(player)

	return {
		ok = true,
		message = actionName .. " resolved.",
		data = get_client_data(data),
	}
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

	if questId == "LookAround" then
		return explore_player(player)
	elseif questId == "Sleep" then
		return rest_player(player)
	end

	local questProgress = data.progress.questProgress
	local claimedQuests = data.progress.claimedQuests
	local requiredProgress = quest.requiredProgress
	local currentProgress = questProgress[quest.id] or 0
	local isClaimed = table.find(claimedQuests, quest.id) ~= nil

	if not quest.repeatable and (table.find(data.storyQuests, quest.id) or isClaimed) then
		return {
			ok = false,
			message = quest.displayName .. " already completed.",
			data = get_client_data(data),
		}
	end

	if currentProgress < requiredProgress then
		if not can_pay_resource(data, "stamina", quest.staminaChange) or not can_pay_resource(data, "food", quest.foodChange) then
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
			message = currentProgress >= requiredProgress and (quest.displayName .. " ready to claim.") or (quest.displayName .. " progress: " .. tostring(currentProgress) .. "/" .. tostring(requiredProgress)),
			data = get_client_data(data),
		}
	end

	data.worldSouls += quest.rewardSouls
	data.progress.questsCompleted += 1
	add_player_exp(player, data, quest.rewardExp)

	if quest.repeatable then
		questProgress[quest.id] = 0
	else
		table.insert(claimedQuests, quest.id)
		table.insert(data.storyQuests, quest.id)
		save_player_data(player)
	end

	apply_player_attributes(player, data)
	fire_data_changed(player)

	return {
		ok = true,
		message = quest.displayName .. " completed.",
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
	DataUtility.server.ensure_remotes()
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
	save_player_data(player)
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
		local result = handle_player_action(player, "Train")
		if not result.ok then
			send_notice(player, result.message)
		end
		return result
	end

	(playerActionRemote :: RemoteFunction).OnServerInvoke = function(player: Player, actionName: string)
		local result = handle_player_action(player, actionName)
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

local function start_action_tick(): ()
	task.spawn(function()
		while true do
			task.wait(GameConfig.ACTION_TICK_SECONDS)

			for player, data in playerData do
				local action = data.currentAction
				local message: string? = nil

				if action == "Training" then
					message = apply_training_tick(player, data)
				elseif action == "Cultivating" then
					message = apply_cultivation_tick(data)
				elseif action == "Resting" then
					message = apply_rest_tick(data)
				end

				if action == "Training" or action == "Cultivating" or action == "Resting" then
					apply_player_attributes(player, data)
					fire_data_changed(player)

					if message then
						send_notice(player, message)
					end
				end
			end
		end
	end)
end

------------------//INIT
ensure_remotes()
connect_remotes()
start_auto_save()
start_action_tick()

for _, player in Players:GetPlayers() do
	on_player_added(player)
end

Players.PlayerAdded:Connect(on_player_added)
Players.PlayerRemoving:Connect(on_player_removing)

game:BindToClose(function()
	for player in playerData do
		save_player_data(player)
	end
end)
