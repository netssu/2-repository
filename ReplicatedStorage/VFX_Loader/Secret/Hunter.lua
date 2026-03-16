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

module["Pistol"] = function(HRP, target)

	local Folder = VFX.Hunter.First
	local speed = GameSpeed.Value

	task.wait(0.3 / speed)
	if not HRP or not HRP.Parent then return end

	HRP.Parent.Attacking.Value = true

	local character = HRP.Parent
	local rightArm = character:FindFirstChild("Right Arm")
	if not rightArm then return end

	
	local Pistol = Folder.Pistol:Clone()
	Pistol.Anchored = false
	Pistol.CFrame = rightArm.CFrame * CFrame.new(0, -0.5, -0.6) * CFrame.Angles(0, math.rad(-90), 0)
	Pistol.Parent = character
	UnitSoundEffectLib.playSound(HRP.Parent, 'Blaster' .. tostring(math.random(1,3)))
	
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = rightArm
	weld.Part1 = Pistol
	weld.Parent = Pistol


	local Attachments = Pistol:FindFirstChild("Attachment")
	if not Attachments then return end

	for _, emitter in Attachments:GetChildren() do
		if emitter:IsA("ParticleEmitter") then
			emitter.Enabled = true
		end
	end

	
	task.delay(0.4 / speed, function()
		for _, emitter in Attachments:GetChildren() do
			if emitter:IsA("ParticleEmitter") then
				emitter.Enabled = false
			end
		end
		Pistol:Destroy()
	end)

	HRP.Parent.Attacking.Value = false
end




module["Electro Grenades"] = function(HRP, target)
	local Folder = VFX.Hunter.Second
	local speed = GameSpeed.Value
	local enemyPos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)
	local flameVFX = Folder["Electro Grenades"]:Clone()
	local emitters = {}

	task.wait(0.4 / speed)
	if not HRP or not HRP.Parent then return end

	HRP.Parent.Attacking.Value = true

	local RightArm = HRP.Parent:FindFirstChild("Right Arm")
	if not RightArm then return end

	flameVFX.CFrame = RightArm.CFrame
	flameVFX.Anchored = true
	flameVFX.Orientation += Vector3.new(0,-90,0)
	flameVFX.Parent = workspace.VFX

	local travelSpeed = 12
	local timeToTravel = getMag(RightArm.Position, enemyPos) / travelSpeed
	UnitSoundEffectLib.playSound(HRP.Parent, 'Flamethrower')
	
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
			UnitSoundEffectLib.playSound(HRP.Parent, 'Explosion')
		end)
	end
	HRP.Parent.Attacking.Value = false
end

module["Vibro Knife Throw"] = function(HRP, target)
	local Folder = VFX.Hunter.Third
	local speed = GameSpeed.Value
	local enemyPos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)
	local RightArm = HRP.Parent:FindFirstChild("Right Arm")
	if not RightArm then return end

	task.wait(0.4 / speed)
	if not HRP or not HRP.Parent then return end

	HRP.Parent.Attacking.Value = true

	local numberOfKnives = 3
	local spacing = 0.25
	local travelSpeed = 12

	for i = 1, numberOfKnives do
		UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing' .. tostring(math.random(1,2)))
		local knifeVFX = Folder["Vibro Knife Throw"]:Clone()
		knifeVFX.CFrame = RightArm.CFrame * CFrame.new((i - 2) * spacing, 0, 0)
		knifeVFX.Anchored = true
		knifeVFX.Orientation += Vector3.new(0, -90, 0)
		knifeVFX.Parent = workspace.VFX

		local timeToTravel = getMag(RightArm.Position, enemyPos) / travelSpeed
		tween(knifeVFX, timeToTravel, {Position = enemyPos})

		task.delay(timeToTravel, function()
			if knifeVFX then
				knifeVFX:Destroy()
			end
		end)

		local emitters = {}
		for _, descendant in knifeVFX:GetDescendants() do
			if descendant:IsA('ParticleEmitter') then
				table.insert(emitters, descendant)
			end
		end

		for _, emitter in emitters do
			emitter.Enabled = true
			task.delay(0.4 / speed, function()
				if emitter then
					emitter.Enabled = false
				end
			end)
		end
	end
	HRP.Parent.Attacking.Value = false
end

return module
