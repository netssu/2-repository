local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local player = Players.LocalPlayer
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")

local Debris = game:GetService("Debris")

local SelectedTowers = {}

local MPS = game:GetService("MarketplaceService")
local Shortner = require(ReplicatedStorage.Modules.NumberFormat)
local itemModule = require(ReplicatedStorage.ItemStats)
local ChallengeModule = require(ReplicatedStorage.Modules.ChallengeModule)
local UIMapLoadingScreenModule = require(ReplicatedStorage.Modules.Client.UIMapLoadingScreen)
local ViewModule = require(ReplicatedStorage.Modules.ViewModule)
local UIHandler = require(ReplicatedStorage.Modules.Client.UIHandler)
local GetPlayerBoost = require(game.ReplicatedStorage.Modules.GetPlayerBoost)
local GetVipsBoost = require(game.ReplicatedStorage.Modules.GetVipsBoost) 
local TraitsModule = require(ReplicatedStorage.Modules.Traits)
local modules = ReplicatedStorage:WaitForChild("Modules")
local health = require(modules:WaitForChild("Health"))
local ViewPortModule = require(ReplicatedStorage.Modules.ViewPortModule)
local FormatStats = require(ReplicatedStorage.Modules.FormatStats)
local TowerInfo = require(ReplicatedStorage.Modules.Helpers.TowerInfo)
local Format = require(game.ReplicatedStorage.Modules.MathFormat)

local playerMoney = Players.LocalPlayer:WaitForChild("Money")
local GetUnitModel = require(ReplicatedStorage.Modules.GetUnitModel)
local playerguix = player.PlayerGui
local SpeedButton = script.Parent.Health.Speed
local functions = ReplicatedStorage:WaitForChild("Functions")
local requestTowerFunction = functions:WaitForChild("RequestTower")
local spawnTowerFunction = functions:WaitForChild("SpawnTower")
local UpgradeFunction = functions:WaitForChild("Upgrade")
local sellTowerFunction = functions:WaitForChild("SellTower")
local changeModeFunction = functions:WaitForChild("ChangeTowerMode")
local getDataFunction = functions:WaitForChild("GetData")
local requestAbilityFunction = functions:WaitForChild("RequestAbility")

local events = ReplicatedStorage:WaitForChild("Events")
local fireAbilityEvent = events:WaitForChild("FireAbility")
local ActivateAbility = ReplicatedStorage.Remotes.DestroyerRemotes.CallDestroyer
local possessEvent = events:WaitForChild("PossessTower")

local Traits = require(ReplicatedStorage.Traits)
local VFX_Loader = require(ReplicatedStorage.VFX_Loader)
local ExpModule = require(ReplicatedStorage.Modules.ExpModule)
local StoryModeStats = require(ReplicatedStorage.StoryModeStats)
local RaidModeStats = require(ReplicatedStorage.RaidModeStats)
local mouse = game.Players.LocalPlayer:GetMouse()
local camera = workspace.CurrentCamera
local gui = script.Parent
local GlobalGUI = gui.Parent:WaitForChild('GlobalGUI')
local EmitModule = require(ReplicatedStorage.Modules:WaitForChild("EmitModule"))
EmitModule.init()

local info = workspace:WaitForChild("Info")


local selectedTower = nil
local towerToSpawn = nil
local towerToSpawnValue = nil
local IsOwner = nil
local canPlace = false
local rotation = 0
local placedTowers = 0
local maxTowers
local lastTouch = tick()

local requiredSlotLevel = {0,0,0,10,20,30}

local UnitGradients = ReplicatedStorage.Borders

local upgradesModule = require(ReplicatedStorage.Upgrades)
local AbilityStatus = ReplicatedStorage.States.AbilityStatus

repeat task.wait() until player:FindFirstChild("DataLoaded")

script.Parent.StartVote.VoteFrame.Yes.MouseButton1Click:Connect(function()
	UIHandler.PlaySound("Skip")
	if not 	script.Parent.StartVote.VoteFrame.Visible then
		return
	end

	events.Client.VoteStartGame:FireServer()
	task.spawn(function()
		TweenService:Create(script.Parent.StartVote.VoteFrame,TweenInfo.new(0.5,Enum.EasingStyle.Exponential), {Position = UDim2.new(0.438, 0,-0.5, 0)}):Play()
		task.wait(0.2)
		script.Parent.StartVote.VoteFrame.Visible = false
	end)

end)
script.Parent.StartVote.VoteFrame.No.MouseButton1Click:Connect(function()
	TweenService:Create(script.Parent.StartVote.VoteFrame,TweenInfo.new(0.5,Enum.EasingStyle.Exponential), {Position = UDim2.new(0.438, 0,-0.5, 0)}):Play()
	task.wait(0.2)
	script.Parent.StartVote.VoteFrame.Visible = false
end)

local function updateSpeedText()
	local gamSped = workspace.Info.GameSpeed

	--if gamSped == 1.5 then
	--    gamSped = 1.5
	--elseif gamSped == 2 then
	--    gamSped = 2
	--elseif gamSped == 3 then
	--    gamSped = 3
	--end

	SpeedButton.Contents.TextLabel.Text = "Speed: " .. gamSped.Value .. "x"
end

updateSpeedText()

local function startCooldown()
	SpeedButton.Interactable = false
	local SpeedCD = workspace.Info.SpeedCD

	for i = 3.2, 0, -0.1 do
		SpeedButton.Contents.TextLabel.Text = string.format("Cooldown: %.1f", i)
		task.wait(0.1)
	end
	SpeedButton.Interactable = true
	updateSpeedText()
end

workspace.Info.GameSpeed.Changed:Connect(startCooldown)

SpeedButton.MouseButton1Click:Connect(function()
	if workspace.Info.SpeedCD.Value == true then 
		_G.Message("Please Wait Before Changing Speed!",Color3.fromRGB(255, 0, 0))
		return
	end
	local GameSpeed = workspace.Info:WaitForChild("GameSpeed")

	local changeSuccess, failReason = game.ReplicatedStorage.Functions.SpeedRemote:InvokeServer()
	if not changeSuccess then
		_G.Message(failReason,Color3.fromRGB(255, 0, 0))
	end
	--SpeedButton.TextLabel.Text = "Speed: 1x"
end)


events.Client.StartGUI.OnClientEvent:Connect(function(Bool)
	local WorldValue = StoryModeStats.Worlds[info.World.Value]



	if info.Raid.Value then
		warn(info.WorldString.Value)
		WorldValue = info.WorldString.Value
	end

	local Frame = script.Parent.Start.StartFrame
	Frame.Visible = true
	if info.ChallengeNumber.Value > 0 then
		Frame.InformationFrame.ModeText.Text = ChallengeModule.Data[info.ChallengeNumber.Value].Name
		Frame.InformationFrame.ModeText.ChallangeGradient.Enabled = true
		Frame.InformationFrame.ModeText.HardGradient.Enabled = false
		Frame.InformationFrame.ModeText.NormalGradient.Enabled = false
	end
	if game.Workspace.Info.Event.Value then
		warn("Event Textttttt")
		Frame.InformationFrame.ModeText.Text = "Event"
		Frame.InformationFrame.ModeText.ChallangeGradient.Enabled = true
		Frame.InformationFrame.ModeText.HardGradient.Enabled = false
		Frame.InformationFrame.ModeText.NormalGradient.Enabled = false
	else
		if info.Infinity.Value then
			Frame.InformationFrame.ModeText.Text = "Hard"
			Frame.InformationFrame.ModeText.HardGradient.Enabled = true
			Frame.InformationFrame.ModeText.ChallangeGradient.Enabled = false
			Frame.InformationFrame.ModeText.NormalGradient.Enabled = false
		else
			if game.Workspace.Info.Mode.Value == 2 and not game.Workspace.Info.Event.Value then
				Frame.InformationFrame.ModeText.Text = "Hard"
				Frame.InformationFrame.ModeText.HardGradient.Enabled = true
				Frame.InformationFrame.ModeText.ChallangeGradient.Enabled = false
				Frame.InformationFrame.ModeText.NormalGradient.Enabled = false
			else
				Frame.InformationFrame.ModeText.Text = "Normal"
				Frame.InformationFrame.ModeText.HardGradient.Enabled = false
				Frame.InformationFrame.ModeText.ChallangeGradient.Enabled = false
				Frame.InformationFrame.ModeText.NormalGradient.Enabled = true
			end
		end
	end

	if WorldValue then
		Frame.InformationFrame.StoryName.Text = WorldValue
	else
		Frame.InformationFrame.StoryName.Text = 'Destroyed Kamino'
	end
	if info.Infinity.Value then
		Frame.InformationFrame.ActName.Text = "Infinity Mode"
	elseif info.Raid.Value then
		print('[Raid Mode] world value:')
		print(WorldValue)
		Frame.InformationFrame.ActName.Text = "Act " .. info.Level.Value .. " - " ..  RaidModeStats.LevelName[WorldValue][info.Level.Value]
	elseif info.Event.Value then
		Frame.InformationFrame.ActName.Text = "Best Of Luck In Defeating This Foe."
	else
		Frame.InformationFrame.ActName.Text = "Act " .. info.Level.Value .. " - " ..  StoryModeStats.LevelName[WorldValue][info.Level.Value]
	end
	TweenService:Create(Frame.InformationFrame.StoryName,TweenInfo.new(0.25,Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
	TweenService:Create(Frame.InformationFrame.StoryName.UIStroke,TweenInfo.new(0.25,Enum.EasingStyle.Exponential), {Transparency = 0.18}):Play()
	task.wait(0.5)
	TweenService:Create(Frame.InformationFrame.Separation,TweenInfo.new(0.75,Enum.EasingStyle.Linear), {ImageTransparency = 0}):Play()
	task.wait(0.5)
	TweenService:Create(Frame.InformationFrame.ActName,TweenInfo.new(0.5,Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
	TweenService:Create(Frame.InformationFrame.ActName.UIStroke,TweenInfo.new(0.5,Enum.EasingStyle.Exponential), {Transparency = 0.18}):Play()
	task.wait(0.5)
	TweenService:Create(Frame.InformationFrame.ModeText,TweenInfo.new(0.8,Enum.EasingStyle.Linear), {TextTransparency = 0}):Play()
	TweenService:Create(Frame.InformationFrame.ModeText.UIStroke,TweenInfo.new(0.8,Enum.EasingStyle.Linear), {Transparency = 0.18}):Play()
	task.wait(4)
	TweenService:Create(Frame.InformationFrame.StoryName,TweenInfo.new(0.85,Enum.EasingStyle.Linear), {TextTransparency = 1}):Play()
	TweenService:Create(Frame.InformationFrame.StoryName.UIStroke,TweenInfo.new(0.85,Enum.EasingStyle.Linear), {Transparency = 1}):Play()
	TweenService:Create(Frame.InformationFrame.Separation,TweenInfo.new(0.85,Enum.EasingStyle.Linear), {ImageTransparency = 1}):Play()
	TweenService:Create(Frame.InformationFrame.ActName,TweenInfo.new(0.85,Enum.EasingStyle.Linear), {TextTransparency = 1}):Play()
	TweenService:Create(Frame.InformationFrame.ActName.UIStroke,TweenInfo.new(0.85,Enum.EasingStyle.Linear), {Transparency = 1}):Play()
	TweenService:Create(Frame.InformationFrame.ModeText,TweenInfo.new(0.85,Enum.EasingStyle.Linear), {TextTransparency = 1}):Play()
	TweenService:Create(Frame.InformationFrame.ModeText.UIStroke,TweenInfo.new(0.85,Enum.EasingStyle.Linear), {Transparency = 1}):Play()

end)

local arrowCoroutine = coroutine.create(function()
	local mapFolder = workspace:WaitForChild("Map")
	local mainMap
	while mainMap == nil do
		mainMap = mapFolder:GetChildren()[1]
		task.wait()
	end
	while true do
		for i=1,5 do
			local arrow = game.ReplicatedStorage:WaitForChild("VFX"):WaitForChild("Arrow"):Clone()
			arrow.Parent = mainMap
			arrow.ArrowScript.Enabled = true
			task.wait(0.5)
		end
		task.wait(2)
	end
end)
coroutine.resume(arrowCoroutine)
_G.Timestarted = tick()
events.Client.VoteStartGame.OnClientEvent:Connect(function(secondsLeft,YesVote,lastCall, UpdatedArgument)

	local VoteFrame = script.Parent.StartVote.VoteFrame

	if UpdatedArgument then
		VoteFrame.Visible = true
		-- {0.5, 0},{0.35, 0}
		TweenService:Create(VoteFrame,TweenInfo.new(0.5,Enum.EasingStyle.Exponential), {Position = UDim2.fromScale(0.5,0.35)}):Play()
		return
	end



	VoteFrame.PlayersVoteText.Text = `{#YesVote}/{math.ceil(#Players:GetPlayers()) }` 
	VoteFrame.StartingText.Text = "Starting in: "..secondsLeft

	if lastCall then
		coroutine.close(arrowCoroutine)
		_G.Message("Game has started!",Color3.fromRGB(255, 170, 0),nil,true)
		UIHandler.PlaySound("WaveComplete")

		task.spawn(function()
			TweenService:Create(VoteFrame,TweenInfo.new(0.5,Enum.EasingStyle.Exponential), {Position = UDim2.fromScale(0.5, -0.5)}):Play()
			task.wait(0.2)
			VoteFrame.Visible = false
		end)
	end
end)


if not info.Versus.Value and not info.Competitive.Value then
	task.spawn(function()
		for i, v in game.Workspace.Mobs:GetChildren() do
			health.Setup(v)
		end
	end)

	workspace.Mobs.ChildAdded:Connect(function(mob)
		health.Setup(mob)
	end)
else
	task.spawn(function()
		for i, v in workspace:WaitForChild('RedMobs'):GetChildren() do
			health.Setup(v)
		end

		for i, v in workspace:WaitForChild('BlueMobs'):GetChildren() do
			health.Setup(v)
		end
	end)

	workspace:WaitForChild('RedMobs').ChildAdded:Connect(function(mob)
		health.Setup(mob)
	end)

	workspace:WaitForChild('BlueMobs').ChildAdded:Connect(function(mob)
		health.Setup(mob)
	end)
end

function FindEquippedTowerName(towerName)
	local Player = Players.LocalPlayer

	for i, v in Player.OwnedTowers:GetChildren() do
		if v:GetAttribute("Equipped") == true and v.Name == towerName then
			return v
		end
	end

	return false
end

local function MouseRaycast(model)
	local mousePosition = UserInputService:GetMouseLocation()
	local mouseRay = camera:ViewportPointToRay(mousePosition.X, mousePosition.Y)
	local raycastParams = RaycastParams.new()

	local blacklist = camera:GetChildren()
	table.insert(blacklist, model)
	table.insert(blacklist, player.Character)
	--table.insert(blacklist, ReplicatedStorage.VFX:GetDescendants())
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = blacklist
	raycastParams.CollisionGroup = 'UnitSelection'

	local raycastResult = workspace:Raycast(mouseRay.Origin, mouseRay.Direction * 1000, raycastParams)
	for i = 1, 10 do
		if not raycastResult or raycastResult.Instance.CanQuery then break end
		table.insert(blacklist, raycastResult.Instance)
		raycastResult = workspace:Raycast(mouseRay.Origin, mouseRay.Direction * 1000, raycastParams)
	end


	return raycastResult
end
function createplacementbox()
	local offset = Vector3.new(0,-2,0)
	local e = workspace.Towers:GetChildren() 
	for i, tower in e do
		if tower:FindFirstChild("PlacementBox") or tower:GetAttribute('Ignore') then continue end
		local p = Instance.new("Part")
		local w = Instance.new("WeldConstraint")
		p.Name = "PlacementBox"
		p.Parent = tower
		w.Name = "PlacementWeld"
		w.Parent = tower
		w.Part0 = tower.VFXTowerBasePart
		w.Part1 = p
		p.Anchored = true
		p.CanCollide = true
		p.CFrame = tower.VFXTowerBasePart.CFrame
		p.Color = Color3.new(0.988235, 0, 0)
		p.Material = Enum.Material.ForceField
		p.Size = Vector3.new(2.623, 3.256, 3.256)
		p.Orientation = Vector3.new(0,90,-90)
		p.Shape = Enum.PartType.Cylinder
		PhysicsService:SetPartCollisionGroup(p, "Tower")
	end

	for i,v: BasePart in workspace:WaitForChild('RedZones'):GetChildren() do
		v.Transparency = 0
	end
end
local function CreateRangeCircle(tower:Model, placeholder)

	local HumanoidRootPart = tower:WaitForChild("HumanoidRootPart")
	local rangesize = Vector3.new(0,0,0)
	if game.Workspace.Camera:FindFirstChild("Range") then
		rangesize = game.Workspace.Camera.Range.Size
	end
	game.Workspace.Camera:ClearAllChildren()
	local config = if placeholder then upgradesModule[tower.Name].Upgrades[1] else upgradesModule[tower.Name].Upgrades[tower.Config:WaitForChild("Upgrades").Value]
	local range = TowerInfo.GetRange(tower, placeholder)

	--print("total range",range, tower.Name)

	local height = (HumanoidRootPart.Size.Y*2.5)/2
	--local height = (tower.PrimaryPart.Size.Y / 2) + tower.Humanoid.HipHeight
	local offset = CFrame.new(0, -height, 0)

	local _,YOrientation,_ = HumanoidRootPart.CFrame:ToOrientation()

	local VFXTowerBasePart 

	if tower:FindFirstChild("VFXTowerBasePart") then
		VFXTowerBasePart = tower:FindFirstChild("VFXTowerBasePart")
	else
		VFXTowerBasePart = Instance.new("Part")
		VFXTowerBasePart.Name = "VFXTowerBasePart"
		VFXTowerBasePart.CanCollide = false
		VFXTowerBasePart.CanTouch = false
		VFXTowerBasePart.CanQuery = false
		VFXTowerBasePart.Transparency = 1
		VFXTowerBasePart.Anchored = true
		VFXTowerBasePart.Position = HumanoidRootPart.Position
		VFXTowerBasePart.Size = Vector3.new(HumanoidRootPart.Size.Y,HumanoidRootPart.Size.Y,HumanoidRootPart.Size.Y)
		VFXTowerBasePart.Parent = tower
	end

	local TowerBasePart 
	if tower:FindFirstChild("TowerBasePart") then
		TowerBasePart = tower:FindFirstChild("TowerBasePart")
	else
		TowerBasePart = Instance.new("Part")
		TowerBasePart.Name = "TowerBasePart"
		TowerBasePart.CanCollide = false
		TowerBasePart.CanTouch = false
		TowerBasePart.CanQuery = false
		TowerBasePart.Transparency = 1
		TowerBasePart.Anchored = true
		TowerBasePart.Position = HumanoidRootPart.Position
		TowerBasePart.Size = Vector3.new(HumanoidRootPart.Size.Y,HumanoidRootPart.Size.Y,HumanoidRootPart.Size.Y)
		TowerBasePart.Parent = tower
	end


	if placeholder then
		local p = ReplicatedStorage.VFX.Range:Clone()
		p.CFrame = VFXTowerBasePart.CFrame * offset-- * CFrame.Angles(0, 0, math.rad(90))
		p.Size = Vector3.new(range * 2, 0.01, range * 2)
		p.Anchored	 = false
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = p
		weld.Part1 = VFXTowerBasePart
		weld.Parent = p
		p.Parent = tower

		local p2 = ReplicatedStorage.VFX.RangeSphere:Clone()
		p2.Name = "Range"
		p2.Size = Vector3.new(range * 2, range * 2, range * 2)
		p2.CFrame = p.CFrame * CFrame.Angles(0, 0, math.rad(-90))
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = p2
		weld.Part1 = p
		weld.Parent = p2
		p2.Parent = p

		local att = script.Attachments.PlacementParticles:Clone()
		att.Orientation = Vector3.new(0,0,0)
		att.Position = Vector3.new(0,VFXTowerBasePart.Size.Y * -1.45,0)
		att.Parent = VFXTowerBasePart
		att.Outline:Emit(1)
	else
		tower.VFXTowerBasePart.CFrame = CFrame.new(tower.VFXTowerBasePart.Position) * CFrame.Angles(0,YOrientation,0)

		local p = ReplicatedStorage.VFX.RangeSphere:Clone()
		p.Name = "Range"
		p.Size = rangesize
		p.CFrame = tower.VFXTowerBasePart.CFrame * offset
		local p2 = ReplicatedStorage.VFX.Range:Clone()
		p2.Name = "Range2" 
		p2.Anchored = true
		p2.CFrame = tower.VFXTowerBasePart.CFrame * offset-- * CFrame.Angles(0, 0, math.rad(90))
		p2.Size = Vector3.new(rangesize.X + 0.01,0.01,rangesize.Z + 0.01)
		p2.Parent = workspace.Camera

		p.Anchored = true
		p.Parent = workspace.Camera

		TweenService:Create(p2,TweenInfo.new(0.5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0),{Size = Vector3.new(range * 2, 0.01, range * 2)}):Play()

		TweenService:Create(p,TweenInfo.new(0.5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0),{Size = Vector3.new(range * 2, range * 2, range * 2)}):Play()
	end

	warn('DEBUG XO1')
	if tower.TowerBasePart:FindFirstChild("PlacementParticles") and false then
		warn('wee woo dont execute')
		tower.TowerBasePart.PlacementParticles.Outline.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 170, 0)),
			ColorSequenceKeypoint.new(.649, Color3.fromRGB(255, 170, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 242, 58))
		}
		tower.TowerBasePart.PlacementParticles.RIPPLE.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 170, 0)),
			ColorSequenceKeypoint.new(.649, Color3.fromRGB(255, 170, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 242, 58))
		}
	end

	--Allow bigger clickable hitbox
	tower.TowerBasePart.Size = Vector3.new(2,3,2)
	tower.TowerBasePart.CanQuery = true

	if config.AOEType then
		if config.AOEType == "Cone" then
			local coneaoe = ReplicatedStorage.VFX.ConeAOE:Clone()
			local weld = Instance.new("WeldConstraint")
			coneaoe.Size = Vector3.new((config.AOESize/45)*range*2,0,range)
			coneaoe.CFrame = tower.VFXTowerBasePart.CFrame * CFrame.new(0,VFXTowerBasePart.Size.Y*-1.45,-(coneaoe.Size.Z/2))
			weld.Part0 = coneaoe
			weld.Part1 = tower.VFXTowerBasePart
			weld.Parent = coneaoe
			coneaoe.Parent = game.Workspace.Camera
		elseif config.AOEType == "Splash" and config.Type.Value ~= 'Spawner' then

			local splashaoe = ReplicatedStorage.VFX.SplashPart:Clone()
			splashaoe.Anchored = false
			local weld = Instance.new("WeldConstraint")
			splashaoe.Size = Vector3.new(config.AOESize*2,0,config.AOESize*2)
			if not placeholder then
				splashaoe.CFrame =  CFrame.new(tower:WaitForChild("SplashPositionPart").Position) 
				weld.Part1 = tower.SplashPositionPart
			else
				local newCFrame = CFrame.new((VFXTowerBasePart.CFrame * CFrame.new(0,0,-config.AOESize*1.5)).Position)-- 
				splashaoe.CFrame = newCFrame--HumanoidRootPart.CFrame * CFrame.new(0,0,-config.AOESize*1.5)
				weld.Part1 = VFXTowerBasePart
			end
			weld.Part0 = splashaoe
			weld.Parent = splashaoe

			splashaoe.Parent = game.Workspace.Camera
			TweenService:Create(splashaoe, TweenInfo.new(4, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, math.huge, false), {Rotation = Vector3.new(0,360,0)}):Play()
			local arrows = script.Arrows:Clone()
			arrows.Parent = splashaoe
			arrows.Part1.Position = tower.VFXTowerBasePart.Position
			if placeholder then
				local weld1 = Instance.new("WeldConstraint")
				weld1.Part0 = arrows.Part1
				weld1.Part1 = tower.VFXTowerBasePart
				weld1.Parent = arrows.Part1
				arrows.Part1.Anchored = false
			end
			arrows.Part2.Position = splashaoe.Position
			arrows.Part2.Anchored = if placeholder then false else true
			local weld2 = Instance.new("WeldConstraint")
			weld2.Part0 = arrows.Part2
			weld2.Part1 = splashaoe
			weld2.Parent = arrows.Part2
		elseif config.AOEType == "AOE" then
			local fullaoe = ReplicatedStorage.VFX.SplashPart:Clone()
			fullaoe.Size = Vector3.new(range*2,0,range*2)
			fullaoe.Position = tower.VFXTowerBasePart.Position - Vector3.new(0,VFXTowerBasePart.Size.Y*1.45,0)
			local weld1 = Instance.new("WeldConstraint")
			weld1.Part0 = fullaoe
			weld1.Part1 = tower.VFXTowerBasePart
			weld1.Parent = fullaoe
			fullaoe.Parent = game.Workspace.Camera
			TweenService:Create(fullaoe, TweenInfo.new(4, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, math.huge, false), {Rotation = Vector3.new(0,360,0)}):Play()
		end
	end
end

local function RemovePlaceholderTower()
	if towerToSpawn then
		local UnitSlot = nil
		for _, slot in script.Parent.Slots.Slots.Units_Bar:GetChildren() do
			if slot:IsA("ImageButton") then
				if slot.Internal:FindFirstChild(towerToSpawn.Name) then
					UnitSlot = slot
				end
			end
		end
		if UnitSlot  then
			UnitSlot.LimitText.Visible = false
		end


		script.Parent.PhoneControls.Visible = false
		towerToSpawn:Destroy()
		towerToSpawn = nil
		rotation = 0
		gui.Controls.Visible = false
		for i, tower in workspace.Towers:GetChildren() do
			if tower:FindFirstChild("PlacementBox") then
				tower.PlacementWeld:Destroy()
				tower.PlacementBox:Destroy()
			end
		end
		game.Workspace.Camera:ClearAllChildren()

		for i,v in workspace:WaitForChild('RedZones'):GetChildren() do
			v.Transparency = 1
		end
	end
end

local function AddPlaceholderTower(name,unit)
	game.Workspace.Camera:ClearAllChildren()
	local towerExists = GetUnitModel[name]
	if towerExists then
		RemovePlaceholderTower()

		towerToSpawn = towerExists:Clone()
		local counter = 0
		local Limit = if not info.Versus.Value and (unit:GetAttribute("Trait") == "Cosmic Crusader" or unit:GetAttribute("Trait") == "Waders Will") then 1 else  upgradesModule[towerToSpawn.Name]["Place Limit"]

		for _, unit in game.Workspace.Towers:GetChildren() do
			if unit.Name == towerToSpawn.Name and unit.Config.Owner.Value == player.Name then
				counter = counter + 1
			end
		end
		local UnitSlot = nil
		for _, slot in script.Parent.Slots.Slots.Units_Bar:GetChildren() do
			if slot:IsA("ImageButton") then
				if slot.Internal:FindFirstChild(towerToSpawn.Name) then
					UnitSlot = slot
				end
			end
		end
		if UnitSlot then
			UnitSlot.LimitText.Visible = true
			UnitSlot.LimitText.Text = counter .. "/" .. Limit
		end
		local result = MouseRaycast(towerToSpawn)
		if result and result.Instance then
			local height = towerToSpawn:WaitForChild("HumanoidRootPart").Size.Y*1.5
			local x = result.Position.X
			local y = result.Position.Y + height
			local z = result.Position.Z

			local cframe = CFrame.new(x,y,z) * CFrame.Angles(0, math.rad(rotation), 0)
			towerToSpawn:SetPrimaryPartCFrame(cframe)
			if towerToSpawn:FindFirstChild("VFXTowerBasePart",true) then
				towerToSpawn:FindFirstChild("VFXTowerBasePart",true).CFrame = cframe
			end
		end
		--towerToSpawn.HumanoidRootPart.Anchored = true
		towerToSpawn.Parent = workspace
		if towerToSpawn:FindFirstChild("Animations") then
			if towerToSpawn.Animations:FindFirstChild("Idle") then
				towerToSpawn.Humanoid:LoadAnimation(towerToSpawn.Animations.Idle):Play()
			end
		end

		CreateRangeCircle(towerToSpawn, true)
		createplacementbox(towerToSpawn, true)
		local equippedTower = FindEquippedTowerName(name)
		if equippedTower then
			Traits.AddVisualAura(towerToSpawn, equippedTower:GetAttribute("Trait"))
		end

		for i, object in towerToSpawn:GetDescendants() do
			if object:IsA("BasePart") then
				PhysicsService:SetPartCollisionGroup(object, "Tower")
			end
		end
		if  UserInputService.TouchEnabled then
			script.Parent.PhoneControls.Visible = UserInputService.TouchEnabled
		else
			gui.Controls.Visible = true
			local offSet = Vector2.new(mouse.X - gui.Controls.AbsolutePosition.X,mouse.Y - gui.Controls.AbsolutePosition.Y)

			local connection
			local function UpdateControlPosition()
				if not gui.Controls.Visible then connection:Disconnect() end
				if UserInputService.GamepadEnabled then
					gui.Controls.Position = UDim2.new(0.075,mouse.X,0,mouse.Y) --@Colton: Added for controller support.
				else gui.Controls.Position = UDim2.new(0.0125,mouse.X,0,mouse.Y)
				end
			end
			UpdateControlPosition()
			connection = mouse.Move:Connect(UpdateControlPosition)
		end
	end
end

local LevelFrame = script.Parent.Slots.Slots.Exp_Frame
local LevelBar = LevelFrame.CanvasGroup.Glow
local LevelNumber = LevelFrame.Level

local function UpdatePlayerLevelBar()
	local playerLevelValue = player.PlayerLevel.Value
	local playerExpValue = player.PlayerExp.Value

	local requireExp = ExpModule.playerExpCalculation(playerLevelValue)

	LevelBar.Size = UDim2.fromScale((playerExpValue/requireExp) * (0.904 - 0.031), 1)
	LevelNumber.Text = `Level {playerLevelValue} [{playerExpValue}/{requireExp}]`
end

player.PlayerLevel.Changed:Connect(UpdatePlayerLevelBar)
player.PlayerExp.Changed:Connect(UpdatePlayerLevelBar)

local Upgrade = script.Parent.SelectionUi.Selection
local SoundService = game:GetService("SoundService")
local Click = SoundService.SoundFX.Click

local TweenModule = require(ReplicatedStorage.AceLib.TweenModule)

local abilityConn = nil :: RBXScriptConnection
local abilityTick = nil
local abilityActivateConn = nil :: RBXScriptConnection

local function updateAbilityStatus()
	-- Upgrade.Ability
	Upgrade.Ability.DisplayBind.TextLabel.Text = AbilityStatus.Value
end

updateAbilityStatus()
AbilityStatus.Changed:Connect(updateAbilityStatus)

local function toggleTowerInfo()
	abilityTick = tick()
	if abilityConn then
		abilityConn:Disconnect()
		abilityConn = nil
		abilityActivateConn:Disconnect()
		abilityActivateConn = nil
	end

	local newHighlight = Instance.new("Highlight")
	newHighlight.FillTransparency = 1
	if selectedTower then
		local towerName = type(selectedTower) == "string" and selectedTower or selectedTower.Name
		local towerUpgrades = upgradesModule[towerName]

		if not towerUpgrades then
			return
		end

		local hasMoneyUpgrade = false
		if towerUpgrades.Upgrades then
			for _, upgrade in towerUpgrades.Upgrades do
				if upgrade.Money then
					hasMoneyUpgrade = true
					break
				end
			end
		end

		for i,v:Model in workspace:WaitForChild('Spawnables'):GetChildren() do -- reset selection
			if v:FindFirstChild('Radius') then
				TweenModule.tween(v.Radius, 0.3, {Transparency = 1})
			end
		end

		for i,v:Model in workspace:WaitForChild('Spawnables'):GetChildren() do
			if v:IsA('Model') then
				if v:FindFirstChild('OwnedBy') and v.OwnedBy.Value == selectedTower then
					if v:FindFirstChild('Radius') then
						TweenModule.tween(v.Radius, 0.3, {Transparency = 0.7})
					end
				end
			end
		end

		-- select sound effect
		Click:Play()


		local unitStats = script.Parent.SelectionUi.Selection:FindFirstChild("UnitStats")
		if not unitStats then return end

		--Upgrade.UnitStats.Damage.Icon.Enabled = hasMoneyUpgrade ~= true

		local includePrefixs
		if not hasMoneyUpgrade then
			unitStats.Damage.Icon.Image = `rbxassetid://{93635387578503}`

			includePrefixs = {"Damage", "VFXText", "Cooldown", "Range"}
		else
			unitStats.Damage.Icon.Image = `rbxassetid://{132305833180435}`

			includePrefixs = {"Damage", "VFXText"}
		end
		for _, ui in unitStats:GetChildren() do
			local include = false
			for _, element in includePrefixs do
				if string.sub(ui.Name,1,#element) == element then
					include = true
				end
			end
			if include then
				ui.Visible = true
			else
				if ui:IsA('GuiBase2d') then
					ui.Visible = false
				end
			end
		end

		local towername = selectedTower.Name

		local sameTower = false
		for i, v in Upgrade.Unit:GetChildren() do
			if v:IsA("ViewportFrame") and v.Name ~= towername then
				v:Destroy()
			elseif v:IsA("ViewportFrame") then
				sameTower = true
			end
		end

		CreateRangeCircle(selectedTower)

		newHighlight.Parent = selectedTower
		script.Parent.SelectionUi.Selection.Visible = true
		Upgrade.Visible = true

		local config = selectedTower.Config

		Upgrade.UnitName.Text = selectedTower.Name
		Upgrade.Unit.OwnerText.Text = config.Owner.Value .. ""

		local buffs = {}

		local TraitBuff = config.Trait
		local TraitValue = Traits.Traits[TraitBuff.Value]
		local TraitImage = Upgrade.Unit.TraitIcon

		if TraitValue and TraitBuff.Value ~= "" and not info.Versus.Value then
			TraitImage.Visible = true
			TraitImage.Image = TraitValue.ImageID
			TraitImage.UIGradient.Color = Traits.TraitColors[TraitValue.Rarity].Gradient
		else
			TraitImage.Visible = false
		end

		local buffstring = ""
		local index = 0
		for i, v in buffs do
			index += 1
			if index == 1 then
				buffstring = "Buffs: "..i.." "..tostring(v).."%"
			else
				buffstring ..= ", "..i.." "..tostring(v).."%"
			end
		end

		if not sameTower then
			local vp = ViewPortModule.CreateViewPort(towername,config.Shiny.Value)
			vp.Parent = Upgrade.Unit
		end 

		if config.Shiny.Value then
			Upgrade.Unit.Shiny.Visible = true
		else
			Upgrade.Unit.Shiny.Visible = false
		end

		local TowerRarity = upgradesModule[towername].Rarity

		if TowerRarity then
			Upgrade.Unit.Image.UIGradient.Color = UnitGradients[TowerRarity].Color
			Upgrade.Unit.GlowEffect.UIGradient.Color = UnitGradients[TowerRarity].Color
			--Upgrade.Gradient.UIGradient.Color = UnitGradients[TowerRarity].Color

		end

		Upgrade.Target.InfoText.Text = config.TargetMode.Value

		Upgrade.Upgrade.Visible = true
		Upgrade.Target.Visible = true
		Upgrade.Sell.Visible = true

		local upgradeTower = config:FindFirstChild("Upgrades")
		local UpgradeModule = require(ReplicatedStorage.Upgrades)
		local UnitStats = UpgradeModule[selectedTower.Name].Upgrades

		local CurrentData = UnitStats[upgradeTower.Value]

		-- Ability Logic
		--abilityConn
		--abilityTick

		Upgrade.Ability.Visible = if CurrentData.AbilityCooldown then true else false
		if CurrentData.AbilityCooldown then
			-- this will need tweaking if we wanna add more abilities in the future

			abilityConn = UserInputService.InputBegan:Connect(function(key, gp)
				if not gp then
					if (key.KeyCode == Enum.KeyCode.G or key.KeyCode == Enum.KeyCode.ButtonB)
						and AbilityStatus.Value == "G" then
						ActivateAbility:FireServer(selectedTower)
					end
				end
			end)

			abilityActivateConn = Upgrade.Ability.Activated:Connect(function()
				ActivateAbility:FireServer(selectedTower)
			end)
		end

		-- End of ability logic

		if upgradeTower then
			local UpgradeData = UnitStats[upgradeTower.Value + 1]

			local priceMultiplier = 1
			if Traits.Traits[config.Trait.Value] and not info.Versus.Value then
				if Traits.Traits[config.Trait.Value]["Money"] then
					priceMultiplier = (1-(Traits.Traits[config.Trait.Value]["Money"]/100))
				end
			end
			if workspace.Info.ChallengeNumber.Value ~= -1 then
				local challengeData = ChallengeModule.Data[workspace.Info.ChallengeNumber.Value]
				if challengeData and challengeData.UnitStats ~= nil then
					priceMultiplier += (challengeData.UnitStats.Price / 100)
				end
			end

			if UpgradeData then
				if UnitStats[upgradeTower.Value].AttackName ~= UpgradeData.AttackName then
					Upgrade.VFXText.Text = "+"..UpgradeData.AttackName
				else
					Upgrade.VFXText.Text = ''
				end
			else
				Upgrade.VFXText.Text = ''
			end
			local levelboost = 1 + config.Level.Value*(1/50)
			local UpgradeStats = {
				Damage = nil,
				Range = nil,
				Cooldown = nil,
			}


			for _, stat in (hasMoneyUpgrade and {"Damage"}) or {"Damage", "Range", "Cooldown"} do
				if UpgradeData ~= nil then
					UpgradeStats[stat] = UpgradeData[stat]
				end
			end

			if UpgradeStats.Damage ~= nil then
				UpgradeStats.Damage = math.round(UpgradeStats.Damage * levelboost) > 100 and (UpgradeStats.Damage * levelboost)  or ((UpgradeStats.Damage * levelboost) * 10) / 10
				warn(math.round(UpgradeStats.Damage))
			end

			local sellPrice = math.round(selectedTower.Config.Worth.Value / 2)
			Upgrade.Sell.InfoText.Text = "Sell: " .. math.round(sellPrice) .. "$"

			warn(Upgrade)

			for _, stat in (hasMoneyUpgrade and {"Damage"}) or {"Damage","Range","Cooldown"} do
				if not UpgradeData then
					Upgrade.bottom.Upgrade.Text = "Upgrade [Max]"
					Upgrade.Upgrade.InfoText.Text = "Upgrade [Max]"
					Upgrade.Upgrade.Visible = false
					Upgrade.UnitStats[stat]['Arrow'].Visible = false
					Upgrade.UnitStats[stat]['after'].Visible = false
				else
					Upgrade.bottom.Upgrade.Text = "Upgrade [" .. config.Upgrades.Value - 1 .. "]"
					Upgrade.Upgrade.Visible = true
					Upgrade.Upgrade.InfoText.Text = "Upgrade: " .. math.round(UpgradeData.Price * priceMultiplier) .. "$"
					Upgrade.UnitStats[stat]['Arrow'].Visible = true
					Upgrade.UnitStats[stat]['after'].Visible = true
				end
				local Value
				if hasMoneyUpgrade then
					Value = config["Money"].Value
				else
					Value = TowerInfo["Get" .. stat](selectedTower)
				end

				if not info.Versus.Value and stat == 'Cooldown' and workspace:GetAttribute('CosmicCrusader') then
					Value *= Traits.Traits["Cosmic Crusader"].TowerBuffs.Cooldown
				end

				Upgrade.UnitStats[stat]['before'].Text = Format.Format(Value, 1)

				if UpgradeData then					
					local Value
					if hasMoneyUpgrade then
						Value = UpgradeData["Money"]
					else
						--Value = TowerInfo["Get" .. stat](selectedTower) -- message from ace: whoever did this, you are stupid.
						Value = UpgradeData[stat]
					end

					if not info.Versus.Value and stat == 'Damage' then
						Value *= levelboost
					end

					if not info.Versus.Value and stat == 'Cooldown' and workspace:GetAttribute('CosmicCrusader') then
						Value *= Traits.Traits["Cosmic Crusader"].TowerBuffs.Cooldown
					end


					Upgrade.UnitStats[stat]['after'].Text = Format.Format(Value, 1)
				end

			end
		else
			Upgrade.Upgrade.Visible = false
		end

		if config.Owner.Value == Players.LocalPlayer.Name then
			IsOwner = true
			Upgrade.Upgrade.Visible = true
			Upgrade.Target.Visible = true
			Upgrade.Sell.Visible = true
		else
			IsOwner = false
			Upgrade.Upgrade.Visible = false
			Upgrade.Target.Visible = false
			Upgrade.Sell.Visible = false
		end


		local originalTower = selectedTower

		local function updateTotalDamage()
			local newTotalDamage = originalTower.Config.TotalDamage.Value
			Upgrade.TotalDamage.Text = `Total Damage: {Shortner.ShortenNum(newTotalDamage)}`
		end

		updateTotalDamage()
		local connection; connection = selectedTower.Config.TotalDamage:GetPropertyChangedSignal("Value"):Connect(function()
			if selectedTower == nil or selectedTower ~=originalTower then connection:Disconnect() return end
			updateTotalDamage()
		end)

	else
		workspace.Camera:ClearAllChildren()
		Upgrade.Visible = false

		for i,v:Model in workspace:WaitForChild('Spawnables'):GetChildren() do
			if v:FindFirstChild('Radius') then
				TweenModule.tween(v.Radius, 0.3, {Transparency = 1})
			end
		end
	end

	coroutine.wrap(function()
		repeat wait(0.01) until selectedTower == nil
		newHighlight:Destroy()
	end)()
end

local spawnCooldown = 0.5 
local lastSpawnTime = 0

local function SpawnNewTower()

	local currentTime = tick()

	if canPlace and currentTime - lastSpawnTime >= spawnCooldown then
		lastSpawnTime = currentTime
		if towerToSpawn.HumanoidRootPart.CFrame == GetUnitModel[towerToSpawn.Name].HumanoidRootPart.CFrame then
			return
		end
		local placedTower = spawnTowerFunction:InvokeServer(towerToSpawnValue, towerToSpawn:WaitForChild("HumanoidRootPart").CFrame, false, true)
		if placedTower then
			placedTowers += 1

			--events.Client.TowerPlace:Fire("TowerPlaced", placedTower)

			--greenparticles()
			selectedTower = placedTower

			local placeanimation = script.PlaceAnimation:Clone()
			placeanimation.Parent = placedTower
			placedTower:WaitForChild("Humanoid"):LoadAnimation(placeanimation):Play()

			local effect = script.PlacementEffect:Clone()
			effect.Position = placedTower:WaitForChild("HumanoidRootPart").Position - Vector3.new(0,1,0)
			effect.Parent = game.Workspace.VFX
			VFX_Loader.EmitAllParticles(effect)

			Debris:AddItem(effect,2)
			Debris:AddItem(placeanimation,2)

			local att = script.Attachments.PlacementParticles:Clone()
			att.Outline.LockedToPart = false
			att.RIPPLE.LockedToPart = false
			att.Position = Vector3.new(0,selectedTower:WaitForChild("HumanoidRootPart").Size.Y * -1.45,0)
			att.Orientation = Vector3.new(0,0,0)
			att.Parent = selectedTower:WaitForChild("TowerBasePart")
			att.Outline:Emit(1)
			RemovePlaceholderTower()
			selectedTower = nil
			toggleTowerInfo()
		else
			warn("Bro Cant Spawn")
		end
	end
end

local function UpgradeFunc()
	print(selectedTower)
	print(IsOwner)

	if selectedTower and IsOwner then
		local upgradeTower = selectedTower:WaitForChild("Config").Upgrades.Value
		local upgradeSuccess = UpgradeFunction:InvokeServer(selectedTower)

		if typeof(upgradeSuccess) == "string" then
			_G.Message(upgradeSuccess,Color3.fromRGB(221, 0, 0))
		elseif upgradeSuccess then
			local effect = script.UpgradeEffect:Clone()
			effect.Position = selectedTower.PrimaryPart.Position - Vector3.new(0,1,0)
			effect.Parent = game.Workspace.VFX
			VFX_Loader.EmitAllParticles(effect)

			events.Client.TowerUpgrade:Fire(selectedTower)

			Debris:AddItem(effect,2)
			toggleTowerInfo()
		end
	end
end

local function SellFunc()
	if selectedTower and IsOwner then
		local soldTower = sellTowerFunction:InvokeServer(selectedTower)

		if soldTower then
			--events.Client.TowerPlace:Fire("RemoveTower", selectedTower)	

			selectedTower = nil
			placedTowers -= 1
			toggleTowerInfo()

		end
	end
end

local function TargetFunc()
	if selectedTower and IsOwner then
		local modeChangeSuccess = changeModeFunction:InvokeServer(selectedTower)
		if modeChangeSuccess then
			toggleTowerInfo()
		end
	end
end

local function SpectateFunc()
	if IsOwner then
		local unitHum = selectedTower:FindFirstChild("Humanoid",true)
		local cameraPartTransparencies = {}
		if unitHum then
			game.Workspace.CurrentCamera.CameraSubject = selectedTower:FindFirstChild("HumanoidRootPart",true)
			for i, v in game.Workspace.CurrentCamera:GetDescendants() do
				if v:IsA("BasePart") then
					cameraPartTransparencies[v] = v.Transparency
					v.Transparency = 1
				elseif v:IsA("ImageLabel") then
					cameraPartTransparencies[v] = v.ImageTransparency
					v.ImageTransparency = 1
				elseif v:IsA("Beam") then
					cameraPartTransparencies[v] = v.Enabled
					v.Enabled = false
				end
			end
			--gui.Slots.Level.Visible = false
			gui.Slots.Currency.Visible = false
			gui.SelectionUi.Selection.Visible = false
			gui.Slots.Slots.Visible = false
			gui.SelectionUi.StopButton.Visible = true
			gui.SelectionUi.StopButton.MouseButton1Click:Once(function()
				for i, v in cameraPartTransparencies do
					if i:IsA("BasePart") then
						i.Transparency = v
					elseif i:IsA("ImageLabel") then
						i.ImageTransparency = v
					elseif i:IsA("Beam") then
						i.Enabled = v
					end
				end
				gui.Slots.Currency.Visible = true
				gui.SelectionUi.StopButton.Visible = false
				gui.SelectionUi.Selection.Visible = true
				gui.Slots.Slots.Visible = true
				gui.SelectionUi.Selection.Visible = true
				local playerChr = player.Character or player.CharacterAdded:Wait()
				game.Workspace.CurrentCamera.CameraSubject = playerChr:WaitForChild("Humanoid")
			end)
		end
	end
end

local function CommandFunc()
	if selectedTower and IsOwner then
		local currentPossession = player:GetAttribute("PossessingTower")

		if currentPossession == selectedTower.Name then
			possessEvent:FireServer(nil) 
		else
			possessEvent:FireServer(selectedTower) 
		end
	end
end

local KeyBinds = {
	F = UpgradeFunc,
	X = SellFunc,
	R = TargetFunc,
	V = SpectateFunc,
	E = CommandFunc,

	ButtonY = UpgradeFunc,
	DPadLeft = TargetFunc,
	DPadRight = SellFunc
}

local actions = {
	Upgrade = UpgradeFunc,
	Sell = SellFunc,
	Target = TargetFunc,
	Spectate = SpectateFunc,
	Command = CommandFunc
}

for buttonName, func in actions do
	Upgrade[buttonName].Activated:Connect(func)
end

local function onKeyBindPress(input, processed)
	if processed or not Upgrade.Visible then
		return
	end
	for key, action in KeyBinds do
		if input.KeyCode == Enum.KeyCode[key] then
			print(input.KeyCode)
			action()
		end
	end
end
print('Input began registered')
UserInputService.InputBegan:Connect(onKeyBindPress)

local function CheckIfPc()
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not UserInputService.MouseEnabled then
		return false
	elseif not UserInputService.TouchEnabled and UserInputService.KeyboardEnabled and UserInputService.MouseEnabled then
		return true
	end
end

local hoveredInstance = nil

function InputBegan(input, processed)
	if processed then
		return
	end
	if player:GetAttribute("PossessingTower") ~= nil then return end
	if towerToSpawn then
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonX then --@Colton: Added to support controller.
			SpawnNewTower()
		elseif input.KeyCode == Enum.KeyCode.R or input.KeyCode == Enum.KeyCode.ButtonY then --@Colton: Added to support controller.
			rotation += 90
		elseif input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.ButtonB then --@Colton: Added to support controller.
			RemovePlaceholderTower()
		end
	elseif hoveredInstance and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch or input.KeyCode == Enum.KeyCode.ButtonX) then
		local model = hoveredInstance and hoveredInstance:FindFirstAncestorOfClass("Model")
		while model and model.Parent ~= workspace.Towers do
			model = model.Parent:FindFirstAncestorOfClass("Model")
		end
		if model and model.Parent == workspace.Towers then
			if model == selectedTower then
				selectedTower = nil
			else
				selectedTower = model
			end
		else
			selectedTower = nil
		end


		toggleTowerInfo()
	end

	local Player = Players.LocalPlayer

	for i, v in Player.OwnedTowers:GetChildren() do
		if v:GetAttribute("Equipped") == true then
			if table.find(SelectedTowers, v) then continue end
			table.insert(SelectedTowers,v)
		end
	end
	local keys = {Enum.KeyCode.One,Enum.KeyCode.Two,Enum.KeyCode.Three,Enum.KeyCode.Four,Enum.KeyCode.Five,Enum.KeyCode.Six}
	for i, v in keys do
		if input.KeyCode == v then
			local towerselected = SelectedTowers[i]
			if towerselected == nil then
				continue
			end
			local tower = GetUnitModel[towerselected.Name]
			if tower == nil then
				continue
			end
			local allowedToSpawn = true --requestTowerFunction:InvokeServer(towerselected)
			if allowedToSpawn then

				towerToSpawnValue = towerselected
				AddPlaceholderTower(tower.Name,towerselected)
			end
		end
	end
end

UserInputService.InputBegan:Connect(InputBegan)
script.Parent.PhoneControls.Place.TouchTap:Connect(function()
	InputBegan({
		UserInputType = Enum.UserInputType.MouseButton1
	})
end)

script.Parent.PhoneControls.Rotate.TouchTap:Connect(function()
	InputBegan({
		KeyCode = Enum.KeyCode.R
	})
end)

script.Parent.PhoneControls.Cancel.TouchTap:Connect(function()
	InputBegan({
		KeyCode = Enum.KeyCode.Q
	})
end)


local lastHighlight = nil
local lastValidResult = nil

local function setPlacementVFXEnabled(tower:Model, state)
	if state then
		-- make it all blue
	else
		-- make it all red


	end
end

local function createHoverHighlight()
	lastHighlight = Instance.new("Highlight")
	lastHighlight.FillTransparency = 1
	lastHighlight.OutlineTransparency = 1
	lastHighlight.Parent = hoveredInstance.Parent
	TweenService:Create(lastHighlight,TweenInfo.new(1,Enum.EasingStyle.Exponential),{OutlineTransparency = 0.25}):Play()

	-- check if spawner
	if hoveredInstance.Parent.Config.Type.Value == 'Spawner' then
		for i,v in workspace:WaitForChild('Spawnables'):GetChildren() do
			if v:IsA('Model') then
				if v.OwnedBy.Value == hoveredInstance.Parent then
					local tempHighlight = Instance.new("Highlight")
					tempHighlight.FillTransparency = 1
					tempHighlight.OutlineTransparency = 1
					tempHighlight.Parent = v
					TweenService:Create(tempHighlight,TweenInfo.new(1,Enum.EasingStyle.Exponential),{OutlineTransparency = 0.25}):Play()

					lastHighlight:GetPropertyChangedSignal('Parent'):Once(function()
						tempHighlight:Destroy()
					end)
				end
			end
		end
	end
end

local function getAncestor(model, ancestor)
	local ancestor = model:FindFirstAncestor(ancestor)
	local success = false
	if ancestor then
		for _, child in ipairs(ancestor:GetChildren()) do
			if hoveredInstance:IsDescendantOf(child) then
				return child
			end
		end
	end
end

RunService.Heartbeat:Connect(function() -- Handle hovering over units
	local MousePos = game:GetService("UserInputService"):GetMouseLocation() - game:GetService("GuiService"):GetGuiInset()
	local getGUI = player:WaitForChild("PlayerGui"):GetGuiObjectsAtPosition(MousePos.X,MousePos.Y)

	local result = MouseRaycast(towerToSpawn)

	for _,ui in getGUI do
		if ui:IsA("GuiButton") then
			result = lastValidResult
		end
	end

	if result and result.Instance then
		lastValidResult = result
		if towerToSpawn then
			hoveredInstance = nil
			--player.Team.Name
			local parentName = result.Instance.Parent.Name
			-- debugxo1

			if parentName == "GroundPlace" or (player.Team and parentName == player.Team.Name .. 'GroundPlace') then -- and upgradesModule[towerToSpawn.Name].Upgrades[1].Type == "Ground" then
				setPlacementVFXEnabled(towerToSpawn, true)
				canPlace = true
			elseif parentName == "AirPlace" and upgradesModule[towerToSpawn.Name].Upgrades[1].Type == "Air"  then
				setPlacementVFXEnabled(towerToSpawn, true)
				canPlace = true
			else
				setPlacementVFXEnabled(towerToSpawn, false)
				canPlace = false
			end

			local height = towerToSpawn:WaitForChild("HumanoidRootPart").Size.Y*1.5
			local x = result.Position.X
			local y = result.Position.Y + height
			local z = result.Position.Z

			local cframe = CFrame.new(x,y,z) * CFrame.Angles(0, math.rad(rotation), 0)
			towerToSpawn:SetPrimaryPartCFrame(cframe)
			if towerToSpawn:FindFirstChild("VFXTowerBasePart",true) then
				towerToSpawn:FindFirstChild("VFXTowerBasePart",true).CFrame = cframe
			end
		else
			hoveredInstance = result.Instance :: Model
			if hoveredInstance:FindFirstAncestor("Towers") then --hoveredInstance.Parent.Parent == workspace.Towers
				local topModel = getAncestor(hoveredInstance, 'Towers')

				if topModel then
					if not lastHighlight then
						hoveredInstance = topModel:GetChildren()[1]
						createHoverHighlight()
					end
				else
					if lastHighlight then
						lastHighlight:Destroy()
						lastHighlight = nil
					end
				end
			elseif hoveredInstance:FindFirstAncestor('Spawnables') then

				local success = false

				local topModel = getAncestor(hoveredInstance, 'Spawnables')

				if topModel then
					success = true
					if topModel:FindFirstChild('OwnedBy') then
						hoveredInstance = topModel.OwnedBy.Value:GetChildren()[1] -- just go down a tree, we're selecting a vehicle
					end
					if not lastHighlight then
						createHoverHighlight()
					end
				end

				if not success then
					if lastHighlight then
						lastHighlight:Destroy()
						lastHighlight = nil
					end
				end
			else
				if lastHighlight then
					lastHighlight:Destroy()
					lastHighlight = nil
				end
			end
		end
	else
		hoveredInstance = nil
	end
end)

local function formatTime(seconds)
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local seconds = math.floor(seconds % 60)

	return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

local function EndScreenGUIDisable(value)
	gui.Slots.Currency.Visible = value
	gui.Slots.Slots.Visible = value

	if info.Versus.Value then
		gui.Health.VersusHealth.Visible = value
	else
		gui.Health.BaseHealth.Visible = value
	end
end






local function DisplayEndScreen(status)
	print('Display End Screen, Status:', status)
	--local frame = gui.EndScreen.VictoryFrame.Frame
	local EndScreen = GlobalGUI.EndScreen.EndGame

	-- Display Stats
	local MatchStats = EndScreen.InformationFrame.Matchstats

	MatchStats.TimePlayed.TextLabel.Text = 
		`<stroke  joins="round" thickness="2" color="rgb(12,12,12)">Time Played:<font color="rgb(69, 252, 3)"> {formatTime(tick()-_G.Timestarted)}</font><font color="rgb(96,255,80)"></font></stroke>`

	MatchStats.WavesBeaten.TextLabel.Text = 
		`<stroke  joins="round" thickness="2" color="rgb(12,12,12)">Waves Beaten:<font color="rgb(252, 3, 227)"> {info.Wave.Value}</font><font color="rgb(96,255,80)"></font></stroke>`

	MatchStats.DamageDealt.TextLabel.Text = 
		`<stroke  joins="round" thickness="2" color="rgb(12,12,12)">Damage Dealt:<font color="rgb(255, 0, 0)"> {Players.LocalPlayer.Damage.Value}</font><font color="rgb(96,255,80)"></font></stroke>`

	local XP = player:GetAttribute("PlayerXP")
	local StringXP = tostring(XP)


	MatchStats.XPGained.TextLabel.Text =  "Total XP Earned: " .. StringXP 
	--frame.GameResult.Frame.EXPgain.exp.Text = math.round(workspace.Info.Wave.Value / 0.5)

	if info.Event.Value or info.Versus.Value then
		EndScreen.Buttons.PlayNext.Visible = false
		if info.Versus.Value then
			EndScreen.Buttons.PlayAgain.Visible = false
		end
	end	

	local Saber = EndScreen.ImageLabel.ImageLabel

	if info.Versus.Value then
		if not info.Competitive.Value then
			-- versus
			EndScreen.InformationFrame.Comp.Visible = false
			EndScreen.RankedInfo.Visible = false
			EndScreen.matchStats.Position = UDim2.fromScale(0.5, 0.094)
		end
		print('Your team:')
		print(player.Team.Name)
		print('Winning team:')
		print(info.WinningTeam.Value)

		if player.Team and player.Team.Name == info.WinningTeam.Value then
			-- we won
			Saber.TextLabel.Text = 'YOU WON'
		else
			-- we lost
			Saber.ImageColor3 = Color3.fromRGB(255,0,0)
			Saber.TextLabel.TextColor3 = Color3.fromRGB(255,0,0)
			Saber.TextLabel.Text = 'YOU LOST'
		end
	else
		-- default
		EndScreen.InformationFrame.Comp.Visible = false
		EndScreen.RankedInfo.Visible = false
		EndScreen.matchStats.Position = UDim2.fromScale(0.5, 0.094)
		if status == "GAME OVER" then
			Saber.ImageColor3 = Color3.fromRGB(255,0,0)
			Saber.TextLabel.TextColor3 = Color3.fromRGB(255,0,0)
			Saber.TextLabel.Text = 'YOU LOST'
			EndScreen.Buttons.PlayNext.Visible = false
		else
			Saber.TextLabel.Text = 'YOU WON'
		end
		if workspace.Info.ChallengeNumber.Value > 0 then
			EndScreen.Buttons.PlayAgain.Visible = true
			EndScreen.Buttons.PlayNext.Visible = false
		end
	end

	local events = ReplicatedStorage:WaitForChild("Events")
	local exitEvent = events:WaitForChild("ExitGame")
	local clicked = false

	EndScreen.Buttons.BackToLobby.Activated:Connect(function()
		if clicked then return end
		clicked = true
		exitEvent:FireServer("Return")
		if workspace.CurrentCamera:FindFirstChild("Blur") then 
			workspace.CurrentCamera:FindFirstChild("Blur"):Destroy()
		end
		EndScreen.Visible = false
		EndScreenGUIDisable(true)
	end)

	EndScreen.Buttons.PlayAgain.Activated:Connect(function()
		if clicked then return end
		clicked = true
		exitEvent:FireServer("Replay")
		if workspace.CurrentCamera:FindFirstChild("Blur") then 
			workspace.CurrentCamera:FindFirstChild("Blur"):Destroy()
		end
		EndScreen.Visible = false
		EndScreenGUIDisable(true)
	end)

	if status ~= "GAME OVER" and info.ChallengeNumber.Value < 0 then 
		EndScreen.Buttons.PlayNext.Activated:Connect(function()
			if clicked then return end
			clicked = true
			exitEvent:FireServer("Next")
			if workspace.CurrentCamera:FindFirstChild("Blur") then 
				workspace.CurrentCamera:FindFirstChild("Blur"):Destroy()
			end
			EndScreen.Visible = false
			EndScreenGUIDisable(true)
		end)
	end

	task.wait(1)
	print(gui.Parent:FindFirstChild("HatchInfo"))
	if gui.Parent:FindFirstChild("HatchInfo") then 
		print('found')
		return
	end

	EndScreenGUIDisable(false)
	local blureffect = Instance.new("BlurEffect",workspace.CurrentCamera)
	blureffect.Size = 0
	blureffect.Enabled = true 
	local tweenStyle = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0)
	local zoomTween = TweenService:Create(blureffect, tweenStyle, {Size = 16})
	zoomTween:Play()
	EndScreen.Visible = true
end

local NumberValueConvert = require(ReplicatedStorage.AceLib.NumberValueConvert)
local RankCalculator = require(ReplicatedStorage.CompetitiveData.RankCalculator)
local RomanNumeralsConverter = require(ReplicatedStorage.AceLib.RomanNumeralsConverter)

local function convertNum(ELO)
	return ELO % 100
end

ReplicatedStorage.Events.Client.ReceiveRewards.OnClientEvent:Connect(function(rewards,dontShowGui, isFirstTime)
	warn('[REWARDS CLIENT] called')

	task.spawn(function()
		local info = workspace:FindFirstChild("Info")
		if not info then return end

		local unit = info:FindFirstChild("DisplayingUnit")
		if unit and unit.Value then
			task.delay(7, function()
				local delayedUnit = workspace:FindFirstChild("Info") and workspace.Info:FindFirstChild("DisplayingUnit")
				if delayedUnit then
					delayedUnit.Value = false
				end
			end)

			repeat
				task.wait(0.1)
			until not (unit and unit.Value)
		end
	end)

	warn('[REWARDS CLIENT] xo1')
	local EndScreen = GlobalGUI.EndScreen.EndGame


	local function EndScreenGUIDisable(value)
		gui.Slots.Currency.Visible = value
		gui.Slots.Slots.Visible = value
		--gui.Slots.Level.Visible = value
		gui.Health.BaseHealth.Visible = value
	end

	if not dontShowGui then
		--gui.EndScreen.VictoryFrame.Frame.Size = UDim2.new(0,0,0,0)
		local blureffect = Instance.new("BlurEffect",workspace.CurrentCamera)
		blureffect.Size = 0
		blureffect.Enabled = true 
		local tweenStyle = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0)
		local zoomTween = TweenService:Create(blureffect, tweenStyle, {Size = 16})
		zoomTween:Play()
		EndScreenGUIDisable(false)

		EndScreen.Visible = true
		--game.TweenService:Create(gui.EndScreen.VictoryFrame.Frame,TweenInfo.new(0.4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size = UDim2.new(1,0,1,0)}):Play()
	end


	warn('[REWARDS CLIENT] xo2')

	if workspace.CurrentCamera:FindFirstChild("Blur") then 
		workspace.CurrentCamera:FindFirstChild("Blur"):Destroy()
	end
	EndScreenGUIDisable(true)
	warn(rewards)

	local EndScreen = GlobalGUI.EndScreen.EndGame
	-- Display Stats
	local MatchStats = EndScreen.InformationFrame.Matchstats


	local DoubleEXP = if player.OwnGamePasses["2x Player XP"].Value then 2 else 1
	if workspace.Info.Infinity.Value then
		local InfExp = math.floor(workspace.Info.Wave.Value / 10)
		MatchStats.TimePlayed.TextLabel.Text = 
			`<stroke  joins="round" thickness="2" color="rgb(12,12,12)">Time Played:<font color="rgb(69, 252, 3)"> {math.round(5 * ( GetPlayerBoost(player, "XP") * GetVipsBoost(player) * DoubleEXP) ) * InfExp}</font><font color="rgb(96,255,80)"></font></stroke>`
	else
		MatchStats.TimePlayed.TextLabel.Text = 
			`<stroke  joins="round" thickness="2" color="rgb(12,12,12)">Time Played:<font color="rgb(69, 252, 3)"> {math.round((25 * GetPlayerBoost(player,"XP"))* GetVipsBoost(player) * DoubleEXP)}</font><font color="rgb(96,255,80)"></font></stroke>`
	end

	local RewardsFrame = EndScreen.RewardsFrame
	local isHidden = true



	print('Client rewards:')
	warn(rewards)

	for reward, amount in rewards do
		if reward == "Items" then
			for item, quantity in amount do
				if quantity <= 0 then continue end
				--SkipReward.Activated:Connect(function()
				--	gui.EndScreen.VictoryFrame.Visible = true
				--	return
				--end)
				for _ = 1, quantity do
					local nextItem = false
					if isHidden then
						EndScreen.Visible = false
						isHidden = false
					end		

					local itemStats = itemModule[item]
					if workspace.CurrentCamera:FindFirstChild("Blur") then 
						workspace.CurrentCamera:FindFirstChild("Blur"):Destroy()
					end
					EndScreenGUIDisable(true)
					ViewModule.Item({
						itemStats,
						nil,
						function()
							nextItem = true
						end,
					})

					repeat task.wait() until nextItem
				end
			end
		elseif reward == "OwnedTowers" then
			for _, tower in amount do
				local goNext = false
				--[[
				local UnitInfo = Info[1]
				local PlayerUnit = Info[2]
				local _resumeCallback = Info[3]
				]]
				--_G.Message("A mysterious unit has been added to your collection", Color3.fromRGB(255, 73, 76), 'Mystery', nil, 10)
				local success = pcall(function()
					local unitStats = upgradesModule[tower.Name]
					ViewModule.Hatch({
						unitStats,
						tower,
						function()
							goNext = true
						end,
					})
				end)
				if not success then
					goNext = true
				end

				repeat task.wait() until goNext
			end
		elseif reward == "Tower" then

			local tower = amount.unit
			local goNext = false
			if workspace.CurrentCamera:FindFirstChild("Blur") then 
				workspace.CurrentCamera:FindFirstChild("Blur"):Destroy()
			end

			EndScreen.Visible = false
			EndScreenGUIDisable(true)
			local success, err = pcall(function()
				local unitStats = upgradesModule[tower.Name]
				ViewModule.Hatch({
					unitStats,
					tower,
					function()
						goNext = true
					end,
				})
			end)
			if not success then
				warn(err)
				goNext = true
			end

			repeat task.wait() until goNext
			_G.Message("A mysterious unit has been added to your collection", Color3.fromRGB(255, 46, 46), 'Mystery')
		elseif reward == 'CompReward' then
			--rewards['CompReward'] = {
			--	OldELO = oldELO,
			--	ELO = ELOCalculated	
			--}
			local EPChanged = amount['ELO'] - amount['oldELO']

			local OriginRank, OriginDiv = RankCalculator.getRankAndDivision(amount['oldELO'])
			local nowRank, division = RankCalculator.getRankAndDivision(amount['ELO'])
			local CompRankConfig = ReplicatedStorage.CompetitiveData.CompetitiveRankConfigurations[nowRank]

			local InformationFrame = EndScreen.InformationFrame.Comp
			InformationFrame.Rank.Text = nowRank .. ' ' .. RomanNumeralsConverter.toRoman(division)

			InformationFrame.Bar.UIGradient.Color = CompRankConfig.UIGradient.Color
			InformationFrame.Bar.TextLabel.Text = convertNum(amount['ELO']) .. '/100 EP'
			InformationFrame.Bar.Front.UIGradient.Color = CompRankConfig.UIGradient.Color
			InformationFrame.Bar.Front.Size = UDim2.fromScale(convertNum(amount['ELO'])/100, 1)

			InformationFrame.Icon.Image = CompRankConfig.Image

			if EPChanged < 0 then
				InformationFrame.EPAmount.Text = '-' .. tostring(EPChanged)
			else
				InformationFrame.EPAmount.Text = EPChanged
			end

		else
			if amount <= 0 then continue end
			if reward == "fdasfasfsafsd" then
				local itemStats = itemModule.Star
				for _ = 1, amount do
					local nextItem = false

					ViewModule.Item({
						itemStats,
						nil,
						function()
							nextItem = true
						end,
					})

					repeat task.wait() until nextItem
				end


			elseif RewardsFrame:FindFirstChild(reward) then 
				local icon = RewardsFrame[reward]
				icon.Button.DisplayNameLabel.Text = reward
				icon.Button.ItemCount.CountLabel.Text = amount ..'x'
				icon.Visible = true
			end
		end
	end

	if workspace.Info.Infinity.Value then
		print('MEDAL_CLIP_TRIGGER_GAMEOVER:{INFINITY}')
	else
		print('MEDAL_CLIP_TRIGGER_GAMEOVER:{STORY}')
	end

	local blureffect = Instance.new("BlurEffect",workspace.CurrentCamera)
	blureffect.Size = 0
	blureffect.Enabled = true 
	local tweenStyle = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0)
	local zoomTween = TweenService:Create(blureffect, tweenStyle, {Size = 16})
	zoomTween:Play()
	EndScreenGUIDisable(false)
	--gui.EndScreen.VictoryFrame.Visible = true
	EndScreen.Visible = true
end)

local timer = gui.Health.BaseHealth.Timer

ReplicatedStorage.Events.Client.Timer.OnClientEvent:Connect(function(round, restTime)

	local gameSpeed = workspace.Info.GameSpeed.Value
	if round ~= 1 then
		_G.Message("Wave Completed!",Color3.fromRGB(255, 170, 0),nil,true)
		UIHandler.PlaySound("WaveComplete")
	end

	timer.Visible = true

	for i=restTime, 1, -1  do
		timer.Text = i
		TweenService:Create(timer,TweenInfo.new(0.25/gameSpeed, Enum.EasingStyle.Exponential),{TextColor3 = Color3.new(1, 0, 0)}):Play()
		task.wait(0.25/gameSpeed)
		TweenService:Create(timer,TweenInfo.new(0.25/gameSpeed, Enum.EasingStyle.Exponential),{TextColor3 = Color3.new(1, 1, 1)}):Play()
		task.wait(0.75/gameSpeed)
	end

	timer.Visible = false
	_G.Message("Wave " .. round.. " Begins!",Color3.fromRGB(255, 170, 0),nil,true)
	UIHandler.PlaySound("WaveStart")
	gui.Health.BaseHealth.Wave.Text = 'Wave ' .. round
	gui.Health.VersusHealth.Wave.Text = 'Wave ' .. round
	-- need to do the same for versus

	--gui.Health.Frame.GemsInfMode.GemsAmount.Text = math.max(0,(round-1)*8)
	if round == info.MaxWaves.Value and not info.Versus.Value then
		task.delay(1/gameSpeed,function()
			_G.Message("FINAL WAVE!",Color3.fromRGB(255, 170, 0),nil,true)
			UIHandler.PlaySound("WaveStart")
		end)
	end
end)

events.Client.Teleporting.OnClientEvent:Connect(function(...)
	TeleportService:SetTeleportGui(UIMapLoadingScreenModule.CreateLoadingGui(...))
end)

local function getUnitRarity(unit)
	local rarity = nil

	for i,v in ReplicatedStorage.Towers:GetChildren() do
		if v:IsA('Folder') then
			if v:FindFirstChild(unit) then
				rarity = v.Name
				break
			end
		end
	end

	return rarity
end

local function SetupGameGui()
	if not info.GameRunning.Value then return end
	task.spawn(function()
		TweenService:Create(script.Parent.StartVote.VoteFrame,TweenInfo.new(0.5,Enum.EasingStyle.Exponential), {Position = UDim2.fromScale(0.5,-0.5)}):Play()
		task.wait(0.2)
		script.Parent.StartVote.VoteFrame.Visible = false
	end)
	local map = workspace.Map:FindFirstChildOfClass("Folder") or workspace
	local HealthFrame = gui.Health.BaseHealth
	local VersusHealth = HealthFrame.Parent.VersusHealth
	local SpeedButton = HealthFrame.Parent.Speed

	if not info.Versus.Value and not info.Competitive.Value then
		HealthFrame.Visible = true
		SpeedButton.Visible = true
		VersusHealth.Visible = false
		map:WaitForChild("Base").Humanoid.HealthChanged:Connect(function()
			HealthFrame.TextLabel.Text = 'Health: ' .. tostring(map:WaitForChild("Base").Humanoid.Health.."/"..map:WaitForChild("Base").Humanoid.MaxHealth)
			HealthFrame.Bar.Front.Size = UDim2.fromScale(map:WaitForChild("Base").Humanoid.Health/map:WaitForChild("Base").Humanoid.MaxHealth,1)
		end)

		HealthFrame.TextLabel.Text = 'Health: ' .. tostring(map:WaitForChild("Base").Humanoid.Health.."/"..map:WaitForChild("Base").Humanoid.MaxHealth)
		HealthFrame.Bar.Front.Size = UDim2.fromScale(map:WaitForChild("Base").Humanoid.Health/map:WaitForChild("Base").Humanoid.MaxHealth,1)
	else
		warn('[Game Controller] Awaiting for versus UI to be scripted sir')
		HealthFrame.Visible = false
		SpeedButton.Visible = false

		VersusHealth.Visible = true

		-- connections for health
		local RedBase = map:WaitForChild('RedBase') :: Model
		local BlueBase = map:WaitForChild('BlueBase') :: Model
		local RedHumanoid = RedBase:WaitForChild('Humanoid') :: Humanoid
		local BlueHumanoid = BlueBase:WaitForChild('Humanoid') :: Humanoid

		local function updateRedHealth()
			local team = 'Red'
			VersusHealth[team].Bar.Front.Size = UDim2.fromScale(RedHumanoid.Health/RedHumanoid.MaxHealth ,1)
			VersusHealth[team].Bar.NumberDisplay.Text = `Health: {RedHumanoid.Health}/{RedHumanoid.MaxHealth}`
		end

		local function updateBlueHealth()
			local team = 'Blue'
			VersusHealth[team].Bar.Front.Size = UDim2.fromScale(BlueHumanoid.Health/BlueHumanoid.MaxHealth ,1)
			VersusHealth[team].Bar.NumberDisplay.Text = `Health: {BlueHumanoid.Health}/{BlueHumanoid.MaxHealth}`
		end

		RedHumanoid.HealthChanged:Connect(updateRedHealth)
		BlueHumanoid.HealthChanged:Connect(updateBlueHealth)

		updateRedHealth()
		updateBlueHealth()
	end

	if workspace.Info.ChallengeNumber.Value == 9 then
		HealthFrame.TextLabel.Text = 'Health: 1/100'
		HealthFrame.Bar.Size =  UDim2.fromScale(1/100, 1)
	end


	UpdatePlayerLevelBar()

	playerMoney.Changed:Connect(function(change)
		gui.Slots.Currency.Coins.CoinsAmount.Text = playerMoney.Value .. "$"
	end)
	gui.Slots.Currency.Coins.CoinsAmount.Text = playerMoney.Value .. "$"


	for Key, _ in KeyBinds do
		for _, button in Upgrade:GetDescendants() do
			if button.Name == "InfoText" then
				if CheckIfPc() then
					button.TextXAlignment = "Left"
				else
					button.TextXAlignment = "Center"
				end

			end
			if button:FindFirstChild(Key) then
				if not CheckIfPc() then
					button[Key].Visible = false
				else
					button[Key].Visible = true
				end
			end
		end 
	end

	local function stringToKeyCode(keyCodeString)
		local keyCode = Enum.KeyCode[keyCodeString]
		if keyCode then
			return keyCode
		end
		return nil
	end

	local function setupConsoleButton(consoleButton, imageLabel)
		if consoleButton:GetAttribute("Input") then
			local enumKeyCode = stringToKeyCode(consoleButton:GetAttribute("Input"))
			if not enumKeyCode then return end
			local mappedIcon = UserInputService:GetImageForKeyCode(enumKeyCode)
			if not mappedIcon then return end
			if imageLabel then
				imageLabel.Image = mappedIcon
				imageLabel.Visible = true
			else 
				consoleButton.Image = mappedIcon 
				if consoleButton:FindFirstChildOfClass("TextLabel") then
					consoleButton:FindFirstChildOfClass("TextLabel").Visible = false
				elseif consoleButton:FindFirstChildWhichIsA("ImageLabel") then
					consoleButton:FindFirstChildOfClass("ImageLabel").Visible = false
				end
			end
		end
	end

	if UserInputService.GamepadEnabled then
		for _, consoleButton in pairs(CollectionService:GetTagged("Controller")) do
			if consoleButton:FindFirstChild("TOOLBAR") then
				consoleButton.TOOLBAR.Visible = false
				local imageLabel = consoleButton:FindFirstChildWhichIsA("ImageLabel")
				if imageLabel then
					setupConsoleButton(consoleButton, imageLabel)
				end
			elseif consoleButton:FindFirstChild("DisplayBind") then
				consoleButton.DisplayBind.Visible = false
				local imageLabel = consoleButton:FindFirstChild("Controller")
				if imageLabel then
					setupConsoleButton(consoleButton, imageLabel)
				end
			else
				if consoleButton:IsA("ImageLabel") or consoleButton:IsA("ImageButton") then
					setupConsoleButton(consoleButton)
				end
			end
		end
	end

	--	gui.Divider.Number.Text = Players.LocalPlayer:FindFirstChild("PlayerLevel").Value
	task.delay(2,function()
		local SelectedTowers = {}
		for i, v in player.OwnedTowers:GetChildren() do
			if v:GetAttribute("Equipped") == true then
				if table.find(SelectedTowers, v) then continue end
				table.insert(SelectedTowers,v)
			end
		end

		for i = 1, 6 do
			local tower = SelectedTowers[i]
			if tower then
				local slot = script.Parent.Slots.Slots.Units_Bar["Unit"..i]

				local rarity = getUnitRarity(tower.Name)
				if rarity == 'Mythical' or rarity == 'Secret' then
					slot.Backend.valEnabled.Value = true
				else
					slot.Backend.valEnabled.Value = false
				end

				if tower:GetAttribute("Shiny") then
					slot.Internal.Glow.Visible = true
				else
					slot.Internal.Glow.Visible = false
				end

				local UnitTrait = if not info.Versus.Value and tower:GetAttribute("Trait") ~= "" then Traits.Traits[tower:GetAttribute("Trait")] else nil
				local UnitRarity = upgradesModule[tower.Name].Rarity

				slot.Visible = true

				-- work here
				--slot.Image.UIGradient.Color = UnitGradients[UnitRarity].Color
				--slot.GlowEffect.UIGradient.Color = UnitGradients[UnitRarity].Color
				--print(tower, rarity)
				print(tower, rarity)
				local gradientRarity = ReplicatedStorage.Borders:FindFirstChild(rarity)
				if gradientRarity then
					slot.Internal.Glow.UIGradient.Color = gradientRarity.Color
					slot.Internal['Main_Unit_ Frame'].UIGradient.Color = gradientRarity.Color
				end


				if tower:GetAttribute("Trait") == "" or info.Versus.Value then
					slot.Internal.TraitIcon.Visible = false
				else
					slot.Internal.TraitIcon.Visible = true
					slot.Internal.TraitIcon.Image = TraitsModule.Traits[tower:GetAttribute("Trait")].ImageID
					slot.Internal.TraitIcon.UIGradient.Color = TraitsModule.TraitColors[TraitsModule.Traits[tower:GetAttribute("Trait")].Rarity].Gradient
					slot.Internal.TraitIcon.UIGradient.Rotation = TraitsModule.TraitColors[TraitsModule.Traits[tower:GetAttribute("Trait")].Rarity].GradientAngle
				end

				local priceMultiplier = 1
				if Traits.Traits[tower:GetAttribute("Trait")] and not info.Versus.Value then
					if Traits.Traits[tower:GetAttribute("Trait")]["Money"] then
						priceMultiplier = (1-(Traits.Traits[tower:GetAttribute("Trait")]["Money"]/100))
					end
				end
				if workspace.Info.ChallengeNumber.Value ~= -1 then
					local challengeData = ChallengeModule.Data[workspace.Info.ChallengeNumber.Value]
					if challengeData and challengeData.UnitStats ~= nil then
						priceMultiplier += (challengeData.UnitStats.Price / 100)
					end
				end

				--slot.UnitPrice.Text = math.round(upgradesModule[tower.Name].Upgrades[1].Price * priceMultiplier).."$"
				slot.Internal.Unit_Value.Text = math.round(upgradesModule[tower.Name].Upgrades[1].Price*priceMultiplier).."$"

				--slot.UnitLvl.Text = tower:GetAttribute("Level")
				slot.Internal.Text_Container.Unit_Level.Text = 'Lvl '

				if info.Versus.Value then
					tower:SetAttribute('Level', 1) -- level 1 on versus
				end

				slot.Internal.Text_Container.Unit_Level.Text = 'Lvl ' .. tower:GetAttribute("Level")
				slot.Internal['Text_Container'].Unit_Name.Text = tower.Name

				local vp = ViewPortModule.CreateViewPort(tower.Name,tower:GetAttribute("Shiny"))
				vp.Parent = slot.Internal

				slot.Activated:Connect(function()
					local allowedToSpawn = requestTowerFunction:InvokeServer(tower)
					if allowedToSpawn then
						createplacementbox()
						towerToSpawnValue = tower
						AddPlaceholderTower(tower.Name,tower)
					end
				end)
			else
				local slot = script.Parent.Slots.Slots.Units_Bar["Unit"..i]

				slot.Backend.valEnabled.Value = false
				--slot.Internal.Glow.UIGradient.Color = ColorSequence.new(Color3.fromRGB(147, 7, 11), Color3.fromRGB(147, 7, 11))
				local gray = Color3.fromRGB(100,100,100)
				slot.Internal['Main_Unit_ Frame'].UIGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, gray),ColorSequenceKeypoint.new(1, gray)}

				slot.Internal.TraitIcon.Visible = false
				slot.Internal.Glow.Visible = false
				slot.Internal.Text_Container.Unit_Level.Text = "" ; slot.Internal.Text_Container.Unit_Level.Text = ""
				slot.Internal.Unit_Value.Text = ""
				if slot:FindFirstChild("Locked") then
					slot.Locked.Visible = false
				end



				--button["Lvl Text"].Text = ""
				--button.UnitLvl.Text = ""
				slot.Internal['Text_Container'].Unit_Name.Text = ""
				slot.Internal['Text_Container'].Unit_Level.Text = ""
				slot.Internal.Unit_Value.Text = ""

				if player.PlayerLevel.Value < requiredSlotLevel[i] then
					--slot.Internal.Unit_Value.Text = "Level "..requiredSlotLevel[i]



					if not slot:FindFirstChild("UIGradient") then
						local Grad = Instance.new("UIGradient")
						Grad.Parent = slot
						Grad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.new(0.211765, 0.211765, 0.211765)),ColorSequenceKeypoint.new(1,Color3.new(0.129412, 0.129412, 0.129412))}
					end
					if slot:FindFirstChild("Locked") then
						slot.Locked.Visible = true
					end
				end

				--if not button:FindFirstChild("UIGradient") then
				--	local Grad = Instance.new("UIGradient")
				--	Grad.Parent = button
				--	Grad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.new(0.211765, 0.211765, 0.211765)),ColorSequenceKeypoint.new(1,Color3.new(0.129412, 0.129412, 0.129412))}
				--end

				local Empty = ViewPortModule.CreateEmptyPort()
				if not slot:FindFirstChild("Empty_Slot") then
					Empty:Clone().Parent = slot.Internal
				end
				if slot:FindFirstChild("UIGradient") then
					slot.UIGradient:Destroy()
				end
			end
		end
	end)
end

player:GetAttributeChangedSignal("PossessingTower"):Connect(function()
	if player:GetAttribute("PossessingTower") ~= nil then
		if towerToSpawn then
			RemovePlaceholderTower()
		end
		selectedTower = nil
		toggleTowerInfo()
	end
end)

local function LoadGui()
	--gui.Info.Message.Text = info.Message.Value
	--warn('load gui')

	local gameOverd = false

	info.GameOver.Changed:Connect(function(val)
		if val and not gameOverd then
			gameOverd = true -- GAME OVER

			local change = 'GAME OVER'

			if info.Victory.Value then
				change = 'VICTORY'
			end

			DisplayEndScreen(change)
		end
	end)


	info.Message.Changed:Connect(function(change)
		--warn('message changed')
		--gui.Info.Message.Text = change
		if change ~= "" then
			--warn('xo1', change)
			if not string.find(change, 'Wave') and not string.find(change, 'Waiting') and not gameOverd then
				DisplayEndScreen(change)
			end
		end
	end)

	SetupGameGui()

	info.GameRunning.Changed:Connect(SetupGameGui)
end

LoadGui()
