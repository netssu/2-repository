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
 
local function tween(obj, length, details)
	TS:Create(obj, TweenInfo.new(length), details):Play()
end
local function getMag(pos1, pos2)
	return (pos1 - pos2).Magnitude
end

module["Saber Slash"] = function(HRP, target)
	local Folder = VFX["Bo Kotan"].First
	local speed = GameSpeed.Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	local saber = Folder["Saber Slash"]:Clone()
	saber.CFrame = HRP.CFrame
	saber.Parent = HRP.Parent
	local Attachment = saber.Attachment
	local tableEmit = {}

	local speed = 16
	local enemyPos = target:GetPivot().Position
	local timeToTravel = getMag(HRP.Position, enemyPos) / speed
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing' .. tostring(math.random(1,2)))

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
end

module["Saber Slam"] = function(HRP, target)
	local Folder = VFX["Bo Kotan"]
	local speed = GameSpeed.Value

	if not HRP or not HRP.Parent then return end
	local character = HRP.Parent

	local spawnPoint = character:FindFirstChild("SpawnPoint")
	if not spawnPoint then
		spawnPoint = Instance.new("Part")
		spawnPoint.Name = "SpawnPoint"
		spawnPoint.Size = Vector3.new(0.5, 0.5, 0.5)
		spawnPoint.Anchored = true
		spawnPoint.CanCollide = false
		spawnPoint.Transparency = 1
		spawnPoint.CFrame = HRP.CFrame
		spawnPoint.Parent = character
	end

	local enemyPos = target:GetPivot().Position
	local travelSpeed = 16
	local travelTime = (HRP.Position - enemyPos).Magnitude / travelSpeed

	local saberSmoke = Folder["SaberSlamSmoke"]:Clone()
	saberSmoke.Parent = workspace.Terrain
	saberSmoke.Position = enemyPos
	UnitSoundEffectLib.playSound(HRP.Parent, 'Explosion')

	local startTime = tick()
	while tick() - startTime < travelTime do
		local alpha = (tick() - startTime) / travelTime
		HRP.CFrame = HRP.CFrame:Lerp(CFrame.new(enemyPos), alpha)
		task.wait()
	end

	HRP.CFrame = CFrame.new(enemyPos)

	VFX_Helper.EmitAllParticles(saberSmoke)

	task.delay(1, function()
		if saberSmoke then
			saberSmoke:Destroy()
		end
	end)

	task.wait(0.2)

	if spawnPoint then
		HRP.CFrame = spawnPoint.CFrame
	end
end


return module
