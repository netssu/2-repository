------------------//SERVICES
local ServerStorage: ServerStorage = game:GetService("ServerStorage")

------------------//CONSTANTS
local MODULES_FOLDER_NAME: string = "Modules"

------------------//VARIABLES
local serverModules: Folder = ServerStorage:WaitForChild(MODULES_FOLDER_NAME) :: Folder
local gameModules: Folder = serverModules:WaitForChild("Game") :: Folder
local gameServerRuntime = require(gameModules:WaitForChild("GameServerRuntime") :: ModuleScript)

------------------//INIT
gameServerRuntime.start()
