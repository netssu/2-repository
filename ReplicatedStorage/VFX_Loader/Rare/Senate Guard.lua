local ReplicatedStorage = game:GetService("ReplicatedStorage")
local module = {}
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed

local function emitParticles(particle: ParticleEmitter)
	local delayTime = particle:GetAttribute("DelayTime") or 0
	local emitCount = particle:GetAttribute("EmitCount") or particle.Rate

	if delayTime > 0 then
		task.delay(delayTime, function()
			particle:Emit(emitCount)
		end)
	else
		particle:Emit(emitCount)
	end
end

local function canAttack(HRP, target)
	if not HRP or not HRP.Parent then
		warn("no humanoidrootpart for unit")
		return false
	end
	if not target or not target:FindFirstChild("HumanoidRootPart") then
		warn("no target")
		return false
	end
	
	return true
end

module["Semi Auto Fire"] = function(HRP, target)
	task.wait(.25)
	if not canAttack(HRP, target) then
		return
	end
	
	local folder = VFX["Senate Guard"]
	
	HRP.Parent.Attacking.Value = true
	
	for i = 1, 3 do
		if not canAttack(HRP, target) then
			break
		end
		
		local vfxPart = folder["3 Big Laser"]:Clone()
		local vfxCFrame = (HRP.CFrame) * CFrame.Angles(0,math.rad(-90),0)

		vfxPart.CFrame = vfxCFrame
		vfxPart.Parent = workspace.VFX

		for i,v in vfxPart:GetDescendants() do
			if not v:IsA("ParticleEmitter") then continue end
			emitParticles(v)
		end

		Debris:AddItem(vfxPart, 2)
		UnitSoundEffectLib.playSound(HRP.Parent, 'LaserGun1')
		
		task.wait(.25)
	end
	
	if HRP and HRP.Parent then
		HRP.Parent.Attacking.Value = false
	end
end


return module
