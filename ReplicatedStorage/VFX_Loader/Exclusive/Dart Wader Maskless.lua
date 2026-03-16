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
local GameSpeed = game.Workspace.Info.GameSpeed
local StoryModeStats = require(rs.StoryModeStats)
function cubicBezier(t, p0, p1, p2, p3)
	return (1 - t)^3*p0 + 3*(1 - t)^2*t*p1 + 3*(1 - t)*t^2*p2 + t^3*p3
end

local function connect(p0, p1, c0)
	local weld = Instance.new("Weld")
	weld.Part0 = p0
	weld.Part1 = p1
	weld.C0 = c0
	weld.Parent = p0
	return weld
end

local function emit(particle: ParticleEmitter)
	local delayTime = particle:GetAttribute("DelayTime") or 0
	local emitCount = particle:GetAttribute("EmitCount") or 10

	if delayTime > 0 then
		task.delay(delayTime, function()
			particle:Emit(emitCount)
		end)
	else
		particle:Emit(emitCount)
	end
end

local function getMag(pos1, pos2)
	return (pos1 - pos2).Magnitude
end

local function tween(obj, length, details)
	TS:Create(obj, TweenInfo.new(length, Enum.EasingStyle.Linear), details):Play()
end



local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")

module["Fury"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX["Dart Wader Maskless"].First
	local characterModel = HRP.Parent
	local Range = characterModel.Config:WaitForChild("Range").Value
	local enemyPos = target:GetPivot().Position

	local originalCFrame = characterModel:GetPivot()
	UnitSoundEffectLib.playSound(HRP.Parent, 'Flamethrower')
	task.wait(1 / speed)  -- adjusted timing here
	if not HRP or not HRP.Parent then return end

	characterModel.Attacking.Value = true

	local SaberDash = Folder["Fury"]:Clone()

	for _, part in pairs(SaberDash:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.CanQuery = false
		end
	end

	SaberDash.Parent = workspace.VFX
	SaberDash.CFrame = HRP.CFrame
	Debris:AddItem(SaberDash, 1.5 / speed)

	local distance = (HRP.Position - enemyPos).Magnitude
	local timeToTravel = math.max(0.5, distance / speed)

	TS:Create(SaberDash, TweenInfo.new(timeToTravel, Enum.EasingStyle.Linear), {Position = enemyPos}):Play()

	for _, v in pairs(SaberDash:GetChildren()) do
		if v:IsA("ParticleEmitter") or v:IsA("Beam") then
			v.Enabled = true
		elseif v:IsA("Attachment") then
			for _, child in pairs(v:GetChildren()) do
				if child:IsA("ParticleEmitter") or child:IsA("Beam") then
					child.Enabled = true
				end
			end
		end
	end

	task.delay(0.5 / speed, function()
		for _, v in pairs(SaberDash:GetDescendants()) do
			if v:IsA("ParticleEmitter") or v:IsA("Beam") then
				v.Enabled = false
			end
		end
	end)

	local targetCFrame = HRP.CFrame * CFrame.new(0, 0, -Range)
	TS:Create(HRP, TweenInfo.new(0.15 / speed, Enum.EasingStyle.Linear), {CFrame = targetCFrame}):Play()

	task.wait(1 / speed)
	if not HRP or not HRP.Parent then return end

	characterModel:PivotTo(originalCFrame)
	characterModel.Attacking.Value = false
end





module["Force Slam"] = function(HRP: BasePart, target: Model)
	local Folder = VFX.Kenobi.Second
	local anikinFolder = VFX["Dart Wader Maskless"].Second
	local speed = GameSpeed.Value

	local MobName = target.Name
	local targetCF = target.HumanoidRootPart.CFrame
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local startCFrame = HRP.CFrame
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)

	task.wait(1.1/speed)
	UnitSoundEffectLib.playSound(HRP.Parent, 'Force1')
	VFX_Helper.SoundPlay(HRP,Folder.Second)
	HRP.Parent.Attacking.Value = true
	if not HRP or not HRP.Parent then return end
	if target then targetCF = target.HumanoidRootPart.CFrame end
	local Mob = if workspace.Info.TestingMode.Value then rs.Enemies.TestMap:FindFirstChildOfClass("Model"):Clone() else nil
	if not workspace.Info.TestingMode.Value then
		local folders  = StoryModeStats.Maps
		
		Mob = target
		
		--for _, folder in folders do
		--	for i, mob in rs.Enemies[folder]:GetChildren() do
		--		if mob.Name == MobName then
		--			Mob = mob:Clone()
		--		end
		--	end
		--end
	end
	Mob.PrimaryPart.CFrame = targetCF
	Mob.Parent = vfxFolder
	--Debris:AddItem(Mob,2/speed)
	--local connection = HRP.Parent.Destroying:Once(function()
	--	Mob:Destroy()
	--end)
	Mob.HumanoidRootPart.Anchored = true
	local humanoid = Mob:FindFirstChildOfClass("Humanoid")
	local animation = Folder:WaitForChild("Animation")
	if humanoid  and animation then
		local animTrack = humanoid:LoadAnimation(animation)
		animTrack:Play() 
	end

	local forceChoke = anikinFolder["force slam"]:Clone()
	forceChoke.Parent = workspace.VFX

	connect(forceChoke, Mob.HumanoidRootPart, CFrame.new(0,-1,0))

	for _, particle in forceChoke:GetDescendants() do
		if particle:IsA("ParticleEmitter") then
			particle.Enabled = true
		end
	end

	local Uppos = Mob.HumanoidRootPart.CFrame * CFrame.new(0,10,0)
	local tweenUp = TS:Create(Mob.HumanoidRootPart, TweenInfo.new(1/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = Uppos}):Play()
	task.wait(1/speed)
	if not HRP or not HRP.Parent then return end

	for _, particle in forceChoke:GetDescendants() do
		if particle:IsA("ParticleEmitter") then
			particle.Enabled = false
		end
	end

	Debris:AddItem(forceChoke, 2)

	local tweendown = TS:Create(Mob.HumanoidRootPart, TweenInfo.new(0.3/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = targetCF}):Play()
	task.wait(0.2/speed)
	if not HRP or not HRP.Parent then return end
	local groundemit = Folder:WaitForChild("ground"):Clone()
	groundemit.CFrame = targetCF + Vector3.new(0,-1.2,0)
	groundemit.Parent = vfxFolder
	Debris:AddItem(groundemit,3/speed)
	VFX_Helper.EmitAllParticles(groundemit)
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	
	--local returnTween = TS:Create(Mob.HumanoidRootPart, TweenInfo.new(1/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
	--	CFrame = CFrame.new(enemypos, enemypos + Mob.HumanoidRootPart.CFrame.LookVector)
	--})
	--returnTween:Play()

	for _, part in Mob:GetDescendants() do
		if part:IsA("BasePart") then
			part.Transparency = 0
		end
	end

	task.delay(1/speed, function()
		if Mob and Mob:FindFirstChild("HumanoidRootPart") then
			Mob.HumanoidRootPart.Anchored = false
		end
	end)

	HRP.Parent.Attacking.Value = false
	--connection:Disconnect()

end



module["AOE Attack"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX["Dart Wader Maskless"].Third
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end

	
	task.wait(0.7/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	UnitSoundEffectLib.playSound(HRP.Parent, 'Force1')

	local Emit = Folder:WaitForChild("aoe"):Clone()
	Emit.Position = HRP.Position
	Emit.Parent = vfxFolder
	Debris:AddItem(Emit,7/speed)
	local connection = HRP.Parent.Destroying:Once(function()
		Emit:Destroy()
	end)
	TS:Create(HRP,TweenInfo.new(0.15/speed, Enum.EasingStyle.Linear),{CFrame = HRP.CFrame * CFrame.new(0, 4, 0)}):Play()
	--HRP.Anchored = true
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end

	
	if not HRP or not HRP.Parent then return end

	VFX_Helper.OnAllParticles(Emit)

	local points = {}
	local center = HRP.Position

	for i = 1, 18 do
		local angle = math.rad((360 / 18) * i)
		local radius = 15
		local x = math.cos(angle) * radius
		local z = math.sin(angle) * radius
		local y = math.random(-3, 7)
		table.insert(points, center + Vector3.new(x, y, z))
	end

	for i = 1, #points do
		if not HRP or not HRP.Parent then return end
		HRP.CFrame = CFrame.new(points[i])
		task.wait((1.75 / #points) / speed)
	end


	VFX_Helper.OffAllParticles(Emit)
	task.wait(0.35/speed)
	if not HRP or not HRP.Parent then return end


	--HRP.Anchored = false

	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame
	task.wait(1/speed)
	if not HRP or not HRP.Parent then return end
	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame
	HRP.Parent.Attacking.Value = false
	connection:Disconnect()
end


return module
