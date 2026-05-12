------------------//VARIABLES
local AnimeJJK = require(script.Parent:WaitForChild("AnimeJJK") :: ModuleScript)

local AnimeRegistry = {
	JJK = AnimeJJK,
}

------------------//FUNCTIONS
function AnimeRegistry.get(worldId: string): any
	return AnimeRegistry[worldId]
end

------------------//INIT
return AnimeRegistry
