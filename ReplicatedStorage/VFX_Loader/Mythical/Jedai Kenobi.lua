local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local RocksModule = require(rs.Modules.RocksModule)
local StoryModeStats = require(rs.StoryModeStats)
local GameSpeed = workspace.Info.GameSpeed

module["Kenobi first attack"] = function(HRP, target)
	local Folder = VFX.Kenobi.First
	local speed = GameSpeed.Value

	VFX_Helper.SoundPlay(HRP,Folder.First)
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	
	local trail = Folder:WaitForChild("Trail"):Clone()
	trail.CFrame = HRP.Parent["Right Arm"].Handle.CFrame * CFrame.Angles(0,math.rad(90),0)
	trail.Parent = vfxFolder
	Debris:AddItem(trail,1.1/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP.Parent["Right Arm"].Handle
	weld.Part1 = trail
	weld.Parent = trail
	task.wait(0.3/speed)
	UnitSoundEffectLib.playSound(HRP.Parent, 'Sniper' .. tostring(math.random(1,3)))
	HRP.Parent.Attacking.Value = true
	if not HRP or not HRP.Parent then return end

	RocksModule.Trail(HRP.CFrame,HRP.CFrame.LookVector,Range,3,Vector3.new(0.5,0.5,0.5),0.02,0.05,0.4,true,6,3)
	local targetPosition = ( HRP.CFrame * CFrame.new(0, 0, -Range))
	TS:Create(HRP, TweenInfo.new(0.4/speed, Enum.EasingStyle.Linear), {CFrame = targetPosition}):Play()
	local Start = Folder:WaitForChild("Downslam"):Clone()
	Start.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame + Vector3.new(0,0,-1)
	Start.Parent = HRP.Parent
	Debris:AddItem(Start,3/speed)
	VFX_Helper.EmitAllParticles(Start)

	task.wait(0.8/speed)
	if not HRP or not HRP.Parent then return end
	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame
	HRP.Parent.Attacking.Value = false
end


module["Force Grip"] = function(HRP, target)
	local Folder = VFX.Kenobi.Second
	local speed = GameSpeed.Value

	local MobName = target.Name
	local targetCF = target.HumanoidRootPart.CFrame
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local startCFrame = HRP.CFrame
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	
	task.wait(1.1/speed)
	VFX_Helper.SoundPlay(HRP,Folder.Second)
	UnitSoundEffectLib.playSound(HRP.Parent, 'Force1')
	HRP.Parent.Attacking.Value = true
	if not HRP or not HRP.Parent then return end
	if target then targetCF = target.HumanoidRootPart.CFrame end
	local Mob = if workspace.Info.TestingMode.Value then rs.Enemies.TestMap:FindFirstChildOfClass("Model"):Clone() else nil
	if not workspace.Info.TestingMode.Value then
		local folders  = StoryModeStats.Maps
		for _, folder in folders do
			for i, mob in rs.Enemies[folder]:GetChildren() do
				if mob.Name == MobName then
					Mob = mob:Clone()
				end
			end
		end
	end
	Mob.PrimaryPart.CFrame = targetCF
	Mob.Parent = vfxFolder
	Debris:AddItem(Mob,2/speed)
	local connection = HRP.Parent.Destroying:Once(function()
		Mob:Destroy()
	end)
	Mob.HumanoidRootPart.Anchored = true
	local humanoid = Mob:FindFirstChildOfClass("Humanoid")
	local animation = Folder:WaitForChild("Animation")
	if humanoid  and animation then
		local animTrack = humanoid:LoadAnimation(animation)
		animTrack:Play() 
	end
	local Uppos = Mob.HumanoidRootPart.CFrame * CFrame.new(0,10,0)
	local tweenUp = TS:Create(Mob.HumanoidRootPart, TweenInfo.new(1/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = Uppos}):Play()
	task.wait(1/speed)
	if not HRP or not HRP.Parent then return end
	local tweendown = TS:Create(Mob.HumanoidRootPart, TweenInfo.new(0.3/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = targetCF}):Play()
	task.wait(0.2/speed)
	if not HRP or not HRP.Parent then return end
	local groundemit = Folder:WaitForChild("ground"):Clone()
	groundemit.CFrame = targetCF + Vector3.new(0,-1.2,0)
	groundemit.Parent = vfxFolder
	Debris:AddItem(groundemit,3/speed)
	VFX_Helper.EmitAllParticles(groundemit)
	UnitSoundEffectLib.playSound(HRP.Parent, 'Explosion')
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	for _, part in Mob:GetDescendants() do
		if part:IsA("BasePart") then
			TS:Create(part, TweenInfo.new(1/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1}):Play()
		end
	end
	HRP.Parent.Attacking.Value = false
	connection:Disconnect()

end


module["Stone Storm"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX.Kenobi.Thrid
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)
	
	local handle = HRP.Parent["Right Arm"].Handle
	handle.Transparency = 1
	VFX_Helper.OffAllParticles(handle.GlowPart)
	for _, part in handle:GetDescendants() do
		if part:IsA("BasePart") then
			part.Transparency = 1
		end
	end
	task.wait(1.7 / speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	local rocks = {}

	local lookDirection = -HRP.CFrame.LookVector 
	local rightVector = HRP.CFrame.RightVector 

	for i, rockName in ({"Rock1", "Rock2", "Rock3"}) do
		local rock = Folder:WaitForChild(rockName):Clone()
		
		local offsetX = (i - 2) * 5 
		local spawnPosition = HRP.Position + lookDirection * 7 + rightVector * offsetX + Vector3.new(0, -5, 0)

		rock.CFrame = CFrame.new(spawnPosition)
		rock.Parent = vfxFolder
		table.insert(rocks, rock)
		Debris:AddItem(rock, 5 / speed)

	end

	for i, rock in (rocks) do
		task.spawn(function()
			local randomOffset = Vector3.new(math.random(-5, 5), -4, math.random(-5, 5))
			local readyRand = enemypos + randomOffset
			task.wait((i - 1) * 0.3 / speed) 
			if not HRP or not HRP.Parent then return end
			local connection = HRP.Parent.Destroying:Once(function()
				rock:Destroy()
			end)
			local startGroundEmit = Folder:WaitForChild("Startground"):Clone()
			startGroundEmit.Position = rock.Position + Vector3.new(0, 1.7, 0)
			startGroundEmit.Parent = vfxFolder
			Debris:AddItem(startGroundEmit, 2 / speed)
			UnitSoundEffectLib.playSound(HRP.Parent, 'Explosion')
			VFX_Helper.EmitAllParticles(startGroundEmit)

			local upTime = math.random(10, 15) / 10 / speed

			local liftTween = TS:Create(rock, TweenInfo.new(upTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = rock.Position + Vector3.new(0, 17, 0)})
			local rotateTween = TS:Create(rock, TweenInfo.new(upTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {Orientation = Vector3.new(math.random(0, 360), math.random(0, 360), math.random(0, 360))})

			liftTween:Play()
			rotateTween:Play()

			task.wait(upTime) 
			if not HRP or not HRP.Parent then return end

			local currentOrientation = rock.Orientation
			TS:Create(rock, TweenInfo.new(0.35 / speed, Enum.EasingStyle.Linear), {Orientation = Vector3.new(currentOrientation.X, currentOrientation.Y + 90, currentOrientation.Z)}):Play()

			task.wait(0.2/ speed)
			if not HRP or not HRP.Parent then return end


			TS:Create(rock, TweenInfo.new(0.15 / speed, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = readyRand}):Play()
			task.wait(0.15 / speed)
			if not HRP or not HRP.Parent then return end

			local ground = Folder:WaitForChild("Ground"):Clone()
			ground.Position = readyRand + Vector3.new(0, 3, 0)
			ground.Parent = vfxFolder
			Debris:AddItem(ground, 3 / speed)
			VFX_Helper.EmitAllParticles(ground)
			connection:Disconnect()

		end)
	end
	task.wait(2.8/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.OnAllParticles(handle.GlowPart)
	handle.Transparency = 0
	for _, part in handle:GetDescendants() do
		if part:IsA("BasePart") then
			part.Transparency = 0
		end
	end
	HRP.Parent.Attacking.Value = false

end






return module
