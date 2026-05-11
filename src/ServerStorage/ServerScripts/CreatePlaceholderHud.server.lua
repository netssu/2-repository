------------------//SERVICES
local ServerStorage: ServerStorage = game:GetService("ServerStorage")

------------------//CONSTANTS
local MODULES_FOLDER_NAME: string = "Modules"

------------------//VARIABLES
local serverModules: Folder = ServerStorage:WaitForChild(MODULES_FOLDER_NAME) :: Folder
local gameModules: Folder = serverModules:WaitForChild("Game") :: Folder
local createPlaceholderHudRuntime = require(gameModules:WaitForChild("CreatePlaceholderHudRuntime") :: ModuleScript)

------------------//INIT
createPlaceholderHudRuntime.start()
