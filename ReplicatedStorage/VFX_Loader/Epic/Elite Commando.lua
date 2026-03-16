local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local repStorage = game:GetService('ReplicatedStorage')
local tweenService = game:GetService('TweenService')
local Debris = game:GetService("Debris")

local vfxFolder = repStorage.VFX
local supperCommandoVfx = vfxFolder["SuperCommando"]

local module = {}

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

local function connect(p0, p1, c0)
	local weld = Instance.new("Weld")
	weld.Part0 = p0
	weld.Part1 = p1
	weld.C0 = c0 or CFrame.new(0,0,0)
	weld.Parent = p0	

	return weld
end

local function getMag(pos1, pos2)
	return (pos1 - pos2).Magnitude
end

local function tween(obj, length, details)
	tweenService:Create(obj, TweenInfo.new(length), details):Play()
end

module["Turbo Laser"] = function(HRP, target)
	task.wait(.25)
	
	local folder = vfxFolder["Elite Commando"]
	local vfx = folder["Turbo Laser"]:Clone()
	
	if not HRP or not HRP.Parent then
		return
	end 
	
	HRP.Parent.Attacking.Value = true
	
	local enemyPos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z) 
	local dir = (HRP.Position-enemyPos).Unit
	
	enemyPos = enemyPos - (dir * 1.7)
	
	local travelSpeed = 50
	local timeToTravel = getMag(HRP.Position, enemyPos) / travelSpeed
	
	vfx.CFrame = HRP.CFrame
	vfx.Parent = workspace.VFX
	local weld = connect(vfx, HRP)
	
	local endPoint = vfx.EndPoint
	
	for _, instance in vfx:GetDescendants() do
		if instance:IsA("Beam") then
			instance.Enabled = true
		elseif instance:IsA("ParticleEmitter") then
			instance.Enabled = true
		end
	end
	
	UnitSoundEffectLib.playSound(HRP.Parent, "Blaster1")
	
	task.delay(.5, function()
		tween(vfx.EndPoint, timeToTravel, {WorldPosition = enemyPos})
	end)
	
	task.wait(timeToTravel + 2)
	
	if HRP and HRP.Parent then
		HRP.Parent.Attacking.Value = false
	end
	
	for _, instance in vfx:GetDescendants() do
		if instance:IsA("Beam") then
			instance.Enabled = false
		elseif instance:IsA("ParticleEmitter") then
			instance.Enabled = false
		end
	end
	
	if weld then
		weld:Destroy()
	end
	
	if vfx then
		vfx:Destroy()
	end
end

return module