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

function cubicBezier(t, p0, p1, p2, p3)
	return (1 - t)^3*p0 + 3*(1 - t)^2*t*p1 + 3*(1 - t)*t^2*p2 + t^3*p3
end

local function emit(particle: ParticleEmitter)
	local delayTime = particle:GetAttribute("DelayTime")
	local emitCount = particle:GetAttribute("EmitCount") or particle.Rate
	
	if delayTime and delayTime > 0 then
		task.delay(delayTime, function()
			particle:Emit(emitCount)
		end)
	else
		particle:Emit(emitCount)
	end
end

module["Assault Rifle"] = function(HRP: BasePart, target: Model)
	local Folder = VFX["Crosshair"].First
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)
	local speed = GameSpeed.Value

	task.wait(.2 / speed)
	
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	
	local assaultRifle = Folder["Assult Rifle"]:Clone()
	assaultRifle.CFrame = HRP.CFrame * CFrame.new(0,0,-.5)
	assaultRifle.Parent = vfxFolder
	
	UnitSoundEffectLib.playSound(HRP.Parent, 'Sniper' .. tostring(math.random(1,3)))
	
	for _, particle in assaultRifle:GetDescendants() do
		if not particle:IsA("ParticleEmitter") then continue end
		emit(particle)
	end
	
	Debris:AddItem(assaultRifle, 2)
	
	task.wait(.2 / speed)
	
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = false
end

module["Sniper"] = function(HRP: BasePart, target: Model)
	local Folder = VFX["Crosshair"].Second
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)
	local speed = GameSpeed.Value

	task.wait(.2 / speed)

	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true

	local sniper = Folder["Sniper Multiple Hit"]:Clone()
	sniper.CFrame = HRP.CFrame * CFrame.new(0,0,-.5)
	sniper.Parent = vfxFolder
	UnitSoundEffectLib.playSound(HRP.Parent, 'Sniper' .. tostring(math.random(1,3)))

	for _, particle in sniper:GetDescendants() do
		if not particle:IsA("ParticleEmitter") then continue end
		emit(particle)
	end

	Debris:AddItem(sniper, 2)

	task.wait(.2 / speed)

	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = false
end

module["Sniper Boom"] = function(HRP: BasePart, target: Model)
	local Folder = VFX["Crosshair"].Third
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)
	local speed = GameSpeed.Value

	task.wait(.2 / speed)

	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true

	local sniper = Folder["Sniper Boom"]:Clone()
	sniper.CFrame = HRP.CFrame * CFrame.new(0,0,-.5)
	sniper.Parent = vfxFolder
	UnitSoundEffectLib.playSound(HRP.Parent, 'Sniper' .. tostring(math.random(1,3)))

	for _, particle in sniper:GetDescendants() do
		if not particle:IsA("ParticleEmitter") then continue end
		emit(particle)
	end

	Debris:AddItem(sniper, 2)
	UnitSoundEffectLib.playSound(HRP.Parent, 'Explosion')
	task.wait(.2 / speed)

	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = false
end

return module
