------------------//VARIABLES
local AnimeOnePiece = {
	worldId = "OnePiece",
	displayName = "One Piece",
	initialUpgradeState = {
		stage = 0,
		storyRuns = 0,
		activeRepeatable = "",
		unlockedRepeatables = {},
		removedRepeatables = {},
		permanent = {},
	},
	repeatableOrder = {},
	equipmentSlots = {
		"head",
		"neck",
		"shirt",
		"pants",
		"weapon",
		"fruitCharm",
	},
	upgrades = {},
}

------------------//INIT
return AnimeOnePiece
