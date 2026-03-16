local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local repStorage = game:GetService('ReplicatedStorage')
local tweenService = game:GetService('TweenService')
local Debris = game:GetService("Debris")

local vfxFolder = repStorage.VFX
local templeGuardVfx = vfxFolder["Temple Guard"]

local module = {}

local function emitParticles(particle: ParticleEmitter)
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

function module.Shunt(HRP, target)
	local shunt = templeGuardVfx.Shunt:Clone()
	shunt.CFrame = HRP.CFrame * CFrame.new(0,0,-2)
	shunt.Parent = workspace.VFX
	
	task.delay(.5, function() -- random number to time with animation
		for _, particle in shunt:GetDescendants() do
			if not particle:IsA("ParticleEmitter") then continue end
			emitParticles(particle)
			UnitSoundEffectLib.playSound(HRP.Parent, 'Force1')
		end
		
		Debris:AddItem(shunt, 2)
	end)
end

return module