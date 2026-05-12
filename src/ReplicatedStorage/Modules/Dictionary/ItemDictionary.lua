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
	JJKSixEyesBand = {
		id = "JJKSixEyesBand",
		displayName = "Six Eyes Band",
		worldId = "JJK",
		category = "Equipment",
		slot = "head",
		emoji = "👁️",
		description = "A resonance band that sharpens cursed precision.",
		buffs = {atk = 2, luck = 0.5},
	},
	JJKFoxMask = {
		id = "JJKFoxMask",
		displayName = "Fox Spirit Mask",
		worldId = "JJK",
		category = "Equipment",
		slot = "head",
		emoji = "🦊",
		description = "Ceremonial mask used in spirit tracking drills.",
		buffs = {def = 1, spd = 1.5},
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
	JJKRitualBeads = {
		id = "JJKRitualBeads",
		displayName = "Ritual Beads",
		worldId = "JJK",
		category = "Equipment",
		slot = "neck",
		emoji = "🧿",
		description = "Prayer beads that anchor your defense in tense fights.",
		buffs = {def = 2.5, hp = 6},
	},
	JJKSilverCharm = {
		id = "JJKSilverCharm",
		displayName = "Silver Curse Charm",
		worldId = "JJK",
		category = "Equipment",
		slot = "neck",
		emoji = "🔮",
		description = "A polished charm that channels unstable cursed echoes.",
		buffs = {atk = 1.5, luck = 0.8},
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
	JJKRitualCoat = {
		id = "JJKRitualCoat",
		displayName = "Ritual Coat",
		worldId = "JJK",
		category = "Equipment",
		slot = "shirt",
		emoji = "🧥",
		description = "Heavy coat lined with binding thread.",
		buffs = {hp = 14, def = 3},
	},
	JJKSquadVest = {
		id = "JJKSquadVest",
		displayName = "Squad Vest",
		worldId = "JJK",
		category = "Equipment",
		slot = "shirt",
		emoji = "🦺",
		description = "Field vest used during school patrol assignments.",
		buffs = {hp = 8, atk = 2, def = 1},
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
	JJKShadowLeggings = {
		id = "JJKShadowLeggings",
		displayName = "Shadow Leggings",
		worldId = "JJK",
		category = "Equipment",
		slot = "pants",
		emoji = "🩳",
		description = "Lightweight gear for cursed footwork and evasive movement.",
		buffs = {spd = 2, def = 1},
	},
	JJKWardTrousers = {
		id = "JJKWardTrousers",
		displayName = "Ward Trousers",
		worldId = "JJK",
		category = "Equipment",
		slot = "pants",
		emoji = "🛡️",
		description = "Inscribed trousers that help absorb curse impact.",
		buffs = {hp = 7, def = 2},
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
	JJKBoneKnife = {
		id = "JJKBoneKnife",
		displayName = "Bone Knife",
		worldId = "JJK",
		category = "Equipment",
		slot = "weapon",
		emoji = "🔪",
		description = "Close-range cursed blade for rapid pressure strikes.",
		buffs = {atk = 6, spd = 2},
	},
	JJKSpearReplica = {
		id = "JJKSpearReplica",
		displayName = "Inverted Spear Replica",
		worldId = "JJK",
		category = "Equipment",
		slot = "weapon",
		emoji = "⚔️",
		description = "A heavy replica used to force clean cursed control.",
		buffs = {atk = 11, def = 1},
	},
	JJKPaperTalisman = {
		id = "JJKPaperTalisman",
		displayName = "Paper Talisman",
		worldId = "JJK",
		category = "Equipment",
		slot = "enchantment",
		emoji = "🧾",
		description = "A basic enchantment from the school archives.",
		buffs = {atk = 3, def = 1, luck = 0.4},
	},
	JJKSealingTag = {
		id = "JJKSealingTag",
		displayName = "Sealing Tag",
		worldId = "JJK",
		category = "Equipment",
		slot = "enchantment",
		emoji = "📜",
		description = "A reinforced tag that improves containment and defense.",
		buffs = {def = 2.5, luck = 0.5},
	},
	JJKDomainChalk = {
		id = "JJKDomainChalk",
		displayName = "Domain Chalk",
		worldId = "JJK",
		category = "Equipment",
		slot = "enchantment",
		emoji = "✒️",
		description = "Marks temporary barrier lines to improve cursed output.",
		buffs = {atk = 2.5, spd = 1, luck = 0.4},
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
	JJKCurryBread = {
		id = "JJKCurryBread",
		displayName = "Curry Bread",
		worldId = "JJK",
		category = "Consumable",
		emoji = "🍞",
		description = "Street food that restores Food and a little Knowledge.",
		useEffects = {food = 2, knowledge = 1},
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
	JJKFocusTea = {
		id = "JJKFocusTea",
		displayName = "Focus Tea",
		worldId = "JJK",
		category = "Consumable",
		emoji = "🍵",
		description = "Calm tea used before cursed technique practice.",
		useEffects = {knowledge = 2, focus = 15},
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
	JJKTatteredCharm = {
		id = "JJKTatteredCharm",
		displayName = "Tattered Charm",
		worldId = "JJK",
		category = "Consumable",
		emoji = "🎴",
		description = "A worn charm fragment from a curse scene report.",
		useEffects = {knowledge = 3, qi = 6},
		stackable = true,
	},
	JJKSpiritRation = {
		id = "JJKSpiritRation",
		displayName = "Spirit Ration",
		worldId = "JJK",
		category = "Consumable",
		emoji = "🥪",
		description = "Patrol ration that restores Food and Stamina together.",
		useEffects = {food = 2, stamina = 2},
		stackable = true,
	},
}

ItemDictionary.worldOrder = {
	JJK = {
		"JJKBlindfold",
		"JJKSixEyesBand",
		"JJKFoxMask",
		"JJKCursedPendant",
		"JJKRitualBeads",
		"JJKSilverCharm",
		"JJKStudentUniform",
		"JJKRitualCoat",
		"JJKSquadVest",
		"JJKTrackPants",
		"JJKShadowLeggings",
		"JJKWardTrousers",
		"JJKTrainingKatana",
		"JJKBoneKnife",
		"JJKSpearReplica",
		"JJKPaperTalisman",
		"JJKSealingTag",
		"JJKDomainChalk",
		"JJKRiceBall",
		"JJKCurryBread",
		"JJKEnergyDrink",
		"JJKFocusTea",
		"JJKSoulCandy",
		"JJKTatteredCharm",
		"JJKSpiritRation",
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
