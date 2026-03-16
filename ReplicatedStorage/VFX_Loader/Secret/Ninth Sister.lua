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

module["Charge Down"] = function(HRP, target)
	local Folder = VFX["Ninth Sister"].First
	local speed = GameSpeed.Value * 16

	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)

	if not HRP or not HRP.Parent then return end

	local mag = getMag(HRP.Position, target:GetPivot().Position)
	tween(HRP, mag/speed, {CFrame = CFrame.new(enemypos)})

	HRP.Parent.Attacking.Value = true

	local vfx = Folder["Charge Down"]:Clone()
	vfx.Parent = workspace.VFX
	
	UnitSoundEffectLib.playSound(HRP.Parent, 'Force1')
	UnitSoundEffectLib.playSound(HRP.Parent, 'Punch' .. tostring(math.random(1,3)))

	local weld = connect(vfx, HRP, CFrame.new(0,-.5,0))

	for _, particle in vfx:GetDescendants() do
		if not particle:IsA("ParticleEmitter") then continue end
		particle.Enabled = true
	end

	task.wait(mag / speed) -- Fully wait for the tween

	if not HRP or not HRP.Parent then return end

	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame


	for _, particle in vfx:GetDescendants() do
		if not particle:IsA("ParticleEmitter") then continue end
		particle.Enabled = false
	end

	HRP.Parent.Attacking.Value = false

	for _, track in HRP.Parent.Humanoid.Animator:GetPlayingAnimationTracks() do
		if track.Animation.AnimationId == "128527655134187" or track.Animation.AnimationId == "rbxassetid://128527655134187" or track.Animation.AnimationId == "132379076203645"  or track.Animation.AnimationId == "rbxassetid://132379076203645" then
			warn("Stopping track")
			track:Stop(.1)
		end
	end

	Debris:AddItem(vfx, 2)
end

module["Force Choke"] = function(HRP, target)
	warn("Force Choke")
	local Folder = VFX.Kenobi.Second
	local anikinFolder = VFX["Ninth Sister"].Second
	local speed = GameSpeed.Value

	local MobName = target.Name
	local targetCF = target.HumanoidRootPart.CFrame
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local startCFrame = HRP.CFrame
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)

	task.wait(0.6/speed)
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

	local forceChoke = anikinFolder["Force Choke"]:Clone()
	warn(anikinFolder["Force Choke"].Parent)
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
	for _, part in Mob:GetDescendants() do
		if part:IsA("BasePart") then
			TS:Create(part, TweenInfo.new(1/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1}):Play()
		end
	end
	HRP.Parent.Attacking.Value = false
	connection:Disconnect()

end



module["Force Slam"] = function(HRP: BasePart, target: Model)
	local Folder = VFX.Kenobi.Second
	local anikinFolder = VFX["Ninth Sister"].Third
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

	local forceChoke = anikinFolder["Force Slam"]:Clone()
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
	UnitSoundEffectLib.playSound(HRP.Parent, 'Explosion')

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
	for _, part in Mob:GetDescendants() do
		if part:IsA("BasePart") then
			TS:Create(part, TweenInfo.new(1/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1}):Play()
		end
	end
	HRP.Parent.Attacking.Value = false
	connection:Disconnect()

end


return module
