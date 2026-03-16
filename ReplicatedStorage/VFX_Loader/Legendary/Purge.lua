local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local vfxFolder = workspace.VFX
local supperCommandoVfx = game:GetService("ReplicatedStorage").VFX.Purge
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed
local tweenService = game:GetService("TweenService")

local module = {}

local function getMag(pos1, pos2)
	return (pos1 - pos2).Magnitude
end

local function tween(obj, length, details)
	tweenService:Create(obj, TweenInfo.new(length, Enum.EasingStyle.Linear), details):Play()
end


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

module["Electric Blast"] = function(HRP, target)
	local rocketExplosion = supperCommandoVfx.First["electric blast"]:Clone()
	
	task.delay(0.3, function()
		rocketExplosion.CFrame = HRP.CFrame * CFrame.new(0,0,-2)
		rocketExplosion.Parent = workspace.VFX
		
		UnitSoundEffectLib.playSound(HRP.Parent, 'Thunder')
		
		for _, particle in rocketExplosion:GetDescendants() do
			if not particle:IsA("ParticleEmitter") then continue end
			emitParticles(particle)
		end
		
		Debris:AddItem(rocketExplosion, 2)
	end)
end


module["Electric Judgement"] = function(HRP, target)
	local Folder = VFX.Purge.Second
	local speed = GameSpeed.Value
	local characterModel = HRP.Parent
	local enemyPos = target:GetPivot().Position
	local distance = (HRP.Position - enemyPos).Magnitude
	local timeToTravel = math.clamp(distance / 5, 0.5, 1.5)

	task.wait(0.3 / speed)
	if not HRP or not HRP.Parent then return end

	characterModel.Attacking.Value = true

	local BallTemplate = Folder:FindFirstChild("Ball")
	if not BallTemplate then error("Ball effect missing in VFX.Purge.Second") end

	local Ball = BallTemplate:Clone()
	Ball.CFrame = HRP.CFrame
	Ball.Parent = workspace.VFX

	local attachment1 = Ball.Ball
	

	for _, v in attachment1:GetChildren() do
		if v:IsA("ParticleEmitter") then
			v.Enabled = true
		end
	end

	

	TS:Create(Ball, TweenInfo.new(timeToTravel, Enum.EasingStyle.Linear), {Position = enemyPos}):Play()
	UnitSoundEffectLib.playSound(HRP.Parent, 'Thunder')
	
	Debris:AddItem(Ball, timeToTravel)
	
	
	
	
	characterModel.Attacking.Value = false
end





return module