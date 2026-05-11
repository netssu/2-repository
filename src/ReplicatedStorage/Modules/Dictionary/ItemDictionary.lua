------------------//VARIABLES
local ItemDictionary = {}

export type ItemDefinition = {
	id: string,
	displayName: string,
	worldId: string?,
	category: string,
	slot: string?,
	emoji: string,
	description: string,
	buffs: {[string]: number}?,
	useEffects: {[string]: number}?,
	stackable: boolean?,
}

ItemDictionary.items = {
	JJKBlindfold = {
		id = "JJKBlindfold",
		displayName = "Student Blindfold",
		worldId = "JJK",
		category = "Equipment",
		slot = "head",
		emoji = "🕶️",
		description = "Focus discipline and reaction training.",
		buffs = {def = 2, spd = 1},
	},
	JJKCursedPendant = {
		id = "JJKCursedPendant",
		displayName = "Cursed Pendant",
		worldId = "JJK",
		category = "Equipment",
		slot = "neck",
		emoji = "📿",
		description = "A talisman that steadies cursed flow.",
		buffs = {luck = 0.6, atk = 1},
	},
	JJKStudentUniform = {
		id = "JJKStudentUniform",
		displayName = "Student Uniform",
		worldId = "JJK",
		category = "Equipment",
		slot = "shirt",
		emoji = "🥋",
		description = "Standard issue combat cloth.",
		buffs = {hp = 10, def = 2},
	},
	JJKTrackPants = {
		id = "JJKTrackPants",
		displayName = "Training Pants",
		worldId = "JJK",
		category = "Equipment",
		slot = "pants",
		emoji = "👖",
		description = "Flexible gear for movement drills.",
		buffs = {hp = 6, spd = 1},
	},
	JJKTrainingKatana = {
		id = "JJKTrainingKatana",
		displayName = "Training Katana",
		worldId = "JJK",
		category = "Equipment",
		slot = "weapon",
		emoji = "🗡️",
		description = "A balanced blade for cursed edge practice.",
		buffs = {atk = 8, spd = 1},
	},
	JJKPaperTalisman = {
		id = "JJKPaperTalisman",
		displayName = "Paper Talisman",
		worldId = "JJK",
		category = "Equipment",
		slot = "enchantment",
		emoji = "🧿",
		description = "A basic enchantment from the school archives.",
		buffs = {atk = 3, def = 1, luck = 0.4},
	},
	JJKRiceBall = {
		id = "JJKRiceBall",
		displayName = "Rice Ball",
		worldId = "JJK",
		category = "Consumable",
		emoji = "🍙",
		description = "Restores meal energy after training.",
		useEffects = {food = 3, stamina = 1},
		stackable = true,
	},
	JJKEnergyDrink = {
		id = "JJKEnergyDrink",
		displayName = "Cursed Energy Drink",
		worldId = "JJK",
		category = "Consumable",
		emoji = "🧃",
		description = "Sharpens focus and restores stamina.",
		useEffects = {stamina = 4, focus = 25},
		stackable = true,
	},
	JJKSoulCandy = {
		id = "JJKSoulCandy",
		displayName = "Soul Candy",
		worldId = "JJK",
		category = "Consumable",
		emoji = "🍬",
		description = "Compressed spirit sugar for quick progress.",
		useEffects = {worldSouls = 25, qi = 12},
		stackable = true,
	},
}

ItemDictionary.worldOrder = {
	JJK = {
		"JJKBlindfold",
		"JJKCursedPendant",
		"JJKStudentUniform",
		"JJKTrackPants",
		"JJKTrainingKatana",
		"JJKPaperTalisman",
		"JJKRiceBall",
		"JJKEnergyDrink",
		"JJKSoulCandy",
	},
}

------------------//FUNCTIONS
function ItemDictionary.get_item(itemId: string): ItemDefinition?
	return ItemDictionary.items[itemId]
end

function ItemDictionary.get_world_items(worldId: string): {ItemDefinition}
	local items = {}
	local order = ItemDictionary.worldOrder[worldId] or {}
	for _, itemId in order do
		local item = ItemDictionary.get_item(itemId)
		if item then
			table.insert(items, item)
		end
	end
	return items
end

function ItemDictionary.get_world_item_ids(worldId: string): {string}
	local ids = {}
	for _, item in ItemDictionary.get_world_items(worldId) do
		table.insert(ids, item.id)
	end
	return ids
end

------------------//INIT
return ItemDictionary
