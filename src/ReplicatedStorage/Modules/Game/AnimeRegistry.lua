------------------//VARIABLES
local AnimeJJK = require(script.Parent:WaitForChild("AnimeJJK") :: ModuleScript)
local AnimeNaruto = require(script.Parent:WaitForChild("AnimeNaruto") :: ModuleScript)
local AnimeOnePiece = require(script.Parent:WaitForChild("AnimeOnePiece") :: ModuleScript)

local AnimeRegistry = {
	JJK = AnimeJJK,
	Naruto = AnimeNaruto,
	OnePiece = AnimeOnePiece,
}

------------------//FUNCTIONS
function AnimeRegistry.get(worldId: string): any
	return AnimeRegistry[worldId]
end

------------------//INIT
return AnimeRegistry
