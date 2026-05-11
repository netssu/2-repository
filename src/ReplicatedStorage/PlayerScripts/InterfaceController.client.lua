--!strict
------------------//SERVICES
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------//CONSTANTS
local MODULES_FOLDER_NAME: string = "Modules"

------------------//VARIABLES
local replicatedModules: Folder = ReplicatedStorage:WaitForChild(MODULES_FOLDER_NAME) :: Folder
local uiModules: Folder = replicatedModules:WaitForChild("UI") :: Folder
local interfaceControllerRuntime = require(uiModules:WaitForChild("InterfaceControllerRuntime") :: ModuleScript)

------------------//INIT
interfaceControllerRuntime.start()
