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
local tweenService = game:GetService("TweenService")
local LightningSparks = require(rs.VFXModules.LightningBolt.LightningSparks)
local LightningModule = require(rs.VFXModules.LightningModule)

local GameSpeed = workspace.Info.GameSpeed

local function getMag(pos1, pos2)
	return (pos1 - pos2).Magnitude
end

local function tween(obj, length, details)
	tweenService:Create(obj, TweenInfo.new(length, Enum.EasingStyle.Linear), details):Play()
end


module["Saber Throw"] = function(HRP, target)
	local Folder = VFX["Grand Inquisitor"].First
	local speed = GameSpeed.Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	local saber = Folder["Saber Throw"]:Clone()
	saber.CFrame = HRP.CFrame
	saber.Parent = HRP.Parent
	local Attachment = saber.Attachment
	local tableEmit = {}

	local speed = 16
	local enemyPos = target:GetPivot().Position
	local timeToTravel = getMag(HRP.Position, enemyPos) / speed
	UnitSoundEffectLib.playSound(HRP.Parent, 'Rockets' .. tostring(math.random(1,2)))

	HRP.Parent.Attacking.Value = true

	tween(saber, timeToTravel, {Position = enemyPos})
	task.delay(timeToTravel, function()
		saber:Destroy()
	end)
	--Debris:AddItem(saber, timeToTravel)


	for i,v in Attachment:GetChildren() do
		table.insert(tableEmit, v)
	end

	for i,v in tableEmit do
		v.Enabled = true
		task.wait(0.1 / speed, function()
			v.Enabled = false
		end)
	end

	for i,v in saber:GetChildren() do
		if v:IsA("Attachment") then
			continue
		else
			v.Enabled = true
		end
	end


	HRP.Parent.Attacking.Value = false
end


module["Force Lightning"] = function(HRP, target)
	local Folder = VFX["Grand Inquisitor"].Second
	local speed = GameSpeed.Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	local saber = Folder["Force Lightning"]:Clone()
	saber.CFrame = HRP.CFrame
	saber.Parent = HRP.Parent
	local Attachment = saber.Attachment
	local tableEmit = {}

	local speed = 16
	local enemyPos = target:GetPivot().Position
	local timeToTravel = getMag(HRP.Position, enemyPos) / speed
	UnitSoundEffectLib.playSound(HRP.Parent, 'Thunder1')

	HRP.Parent.Attacking.Value = true

	tween(saber, timeToTravel, {Position = enemyPos})
	task.delay(timeToTravel, function()
		saber:Destroy()
	end)
	--Debris:AddItem(saber, timeToTravel)


	for i,v in Attachment:GetChildren() do
		table.insert(tableEmit, v)
	end

	for i,v in tableEmit do
		v.Enabled = true
		task.wait(0.1 / speed, function()
			v.Enabled = false
		end)
	end

	for i,v in saber:GetChildren() do
		if v:IsA("Attachment") then
			continue
		else
			v.Enabled = true
		end
	end


	HRP.Parent.Attacking.Value = false
end


module["Jedai Explosion"] = function(HRP, target)
	local Folder = VFX["Grand Inquisitor"].Third
	local speed = GameSpeed.Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	task.wait(0.05/speed)
	local saber = Folder["AOE Attack"]:Clone()
	saber.CFrame = HRP.CFrame
	saber.Parent = HRP.Parent
	local Attachment = saber.Attachment
	local tableEmit = {}

	local speed = 3.5
	local enemyPos = target:GetPivot().Position
	local timeToTravel = getMag(HRP.Position, enemyPos) / speed
	UnitSoundEffectLib.playSound(HRP.Parent, 'Force1')

	HRP.Parent.Attacking.Value = true

	tween(saber, timeToTravel, {Position = enemyPos})
	task.wait(0.1/speed)
	task.delay(timeToTravel, function()
		saber:Destroy()
	end)
	--Debris:AddItem(saber, timeToTravel)


	for i,v in Attachment:GetChildren() do
		table.insert(tableEmit, v)
	end

	for i,v in tableEmit do
		v.Enabled = true
		task.wait(0.1 / speed, function()
			v.Enabled = false
		end)
	end
	task.wait(0.05/speed)
	UnitSoundEffectLib.playSound(HRP.Parent, 'Explosion')
	for i,v in saber:GetChildren() do
		if v:IsA("Attachment") then
			continue
		else
			v.Enabled = true
		end
	end

	HRP.Parent.Attacking.Value = false
end







return module
