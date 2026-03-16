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
local GameSpeed = workspace.Info.GameSpeed
local tweenService = game:GetService("TweenService")
function cubicBezier(t, p0, p1, p2, p3)
	return (1 - t)^3*p0 + 3*(1 - t)^2*t*p1 + 3*(1 - t)*t^2*p2 + t^3*p3
end


local function getMag(pos1, pos2)
	return (pos1 - pos2).Magnitude
end

local function tween(obj, length, details)
	tweenService:Create(obj, TweenInfo.new(length, Enum.EasingStyle.Linear), details):Play()
end

module["Pistol and rocket"] = function(HRP, target)
	local Folder = VFX.Django.First
	local speed = GameSpeed.Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)
	task.wait(0.3 / speed)
	if not HRP or not HRP.Parent then return end

	HRP.Parent.Attacking.Value = true
	--VFX_Helper.SoundPlay(HRP, Folder.Sound)
	local GunShoot = Folder["Gun Shoot"]:Clone()
	GunShoot.CFrame = HRP.CFrame
	GunShoot.Parent = HRP.Parent
	local Attatchments = GunShoot.Attachment
	local tableEmit = {}
	
	local speed = 16
	local enemyPos = target:GetPivot().Position
	local timeToTravel = getMag(HRP.Position, enemyPos) / speed

	tween(GunShoot, timeToTravel, {Position = enemyPos})
	UnitSoundEffectLib.playSound(HRP.Parent, 'EliteBlaster1')
	task.delay(timeToTravel, function()
		GunShoot:Destroy()
	end)
	
	for i,v in Attatchments:GetChildren() do
		table.insert(tableEmit, v)
	end
	
	warn(tableEmit, "Particles for gun")
	
	for i,v in tableEmit do
		v.Enabled = true
		task.wait(0.4 / speed, function()
			v.Enabled = false
		end)
	end
	HRP.Parent.Attacking.Value = false
end

module["Rockets"] = function(HRP, target)
	local Folder = VFX.Django.Second
	local speed = GameSpeed.Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)

	task.wait(0.3 / speed)
	if not HRP or not HRP.Parent then return end

	HRP.Parent.Attacking.Value = true
	--VFX_Helper.SoundPlay(HRP, Folder.Sound)
	local MRE = Folder["Multiple Rocket Explosion"]:Clone()
	MRE.CFrame = HRP.CFrame
	MRE.Parent = workspace.VFX
	local Attatchments = {}
	local tableEmit = {}

	local speed = 16
	local enemyPos = target:GetPivot().Position
	local timeToTravel = getMag(HRP.Position, enemyPos) / speed
	UnitSoundEffectLib.playSound(HRP.Parent, 'Rockets' .. tostring(math.random(1,2)))

	for i, v in MRE:GetChildren() do
		table.insert(Attatchments, v)
	end
	

	

	tween(MRE, timeToTravel, {Position = enemyPos})
	task.delay(timeToTravel, function()
		UnitSoundEffectLib.playSound(HRP.Parent, 'Explosion')
		MRE:Destroy()
	end)

	for i, value in Attatchments do
		for _, v in value:GetChildren() do
			table.insert(tableEmit, v)
		end 
	end

	for i,v in tableEmit do
		v.Enabled = true
		task.wait(0.1 / speed, function()
			v.Enabled = false
		end)
	end
	HRP.Parent.Attacking.Value = false
end

module["Flamethrower"] = function(HRP, target)
	local Folder = VFX.Django.Third
	local speed = GameSpeed.Value
	local enemyPos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)
	local flameVFX = Folder.Flamethrower:Clone()
	local emitters = {}

	task.wait(0.4 / speed)
	if not HRP or not HRP.Parent then return end

	HRP.Parent.Attacking.Value = true

	local RightArm = HRP.Parent:FindFirstChild("Right Arm")
	UnitSoundEffectLib.playSound(HRP.Parent, 'Flamethrower')
	if not RightArm then return end

	flameVFX.CFrame = RightArm.CFrame
	flameVFX.Anchored = true
	flameVFX.Orientation += Vector3.new(0,-90,0)
	flameVFX.Parent = workspace.VFX

	local travelSpeed = 12
	local timeToTravel = getMag(RightArm.Position, enemyPos) / travelSpeed
	tween(flameVFX, timeToTravel, {Position = enemyPos})

	task.delay(timeToTravel, function()
		if flameVFX then
			flameVFX:Destroy()
		end
	end)

	for i, particle in flameVFX.Parent:GetDescendants() do
		if particle:IsA('ParticleEmitter') then
			table.insert(emitters, particle)
		end
	end
	
	warn(emitters)
	
	local displayed = false
	
	for _, emitter in emitters do
		emitter.Enabled = true
		task.delay(1 / speed, function() -- 0.15
			if not displayed then
				warn(emitters)
				displayed = true
			end
			
			if emitter then
				emitter.Enabled = false
			end
		end)
	end
	HRP.Parent.Attacking.Value = false
end


return module
