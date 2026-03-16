local module = {}

local rs = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local VFX = rs:WaitForChild("VFX")
local vfxFolder = workspace:WaitForChild("VFX")
local VFX_Helper = require(rs.Modules:WaitForChild("VFX_Helper"))
local EmitModule = require(rs.Modules:WaitForChild("EmitModule"))
local GameSpeed = workspace.Info:WaitForChild("GameSpeed")

local function getEnemyPos(HRP, target)
	if target and target:FindFirstChild("HumanoidRootPart") then
		local pos = target.HumanoidRootPart.Position
		return Vector3.new(pos.X, HRP.Position.Y, pos.Z)
	end

	local range = HRP.Parent.Config:WaitForChild("Range").Value
	return (HRP.CFrame * CFrame.new(0, 0, -range)).Position
end

local function getVisual(folder, visualName)
	local obj = folder:FindFirstChild(visualName)
	if obj and (obj:IsA("BasePart") or obj:IsA("Model")) then
		return obj
	end

	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("BasePart") or child:IsA("Model") then
			return child
		end
	end

	return nil
end

local function setVFXCFrame(vfx, cf)
	if vfx:IsA("Model") then
		vfx:PivotTo(cf)
	else
		vfx.CFrame = cf
	end
end

local function playSimpleSkill(HRP, target, folderName, visualName, getCFrame, lifeTime, attackTime, offTime)
	if not HRP or not HRP.Parent then
		return
	end

	local unit = HRP.Parent
	local speed = GameSpeed.Value
	local folder = VFX:WaitForChild("Palpotin"):WaitForChild(folderName)
	local sound = folder:FindFirstChild("Sound")
	local template = getVisual(folder, visualName)

	if not template then
		warn(("VFX '%s' não encontrado em Palpotin/%s"):format(visualName, folderName))
		return
	end

	if sound and sound:IsA("Sound") then
		VFX_Helper.SoundPlay(HRP, sound)
	end

	if unit:FindFirstChild("Attacking") then
		unit.Attacking.Value = true
	end

	local vfx = template:Clone()
	setVFXCFrame(vfx, getCFrame(HRP, target))
	vfx.Parent = vfxFolder

	Debris:AddItem(vfx, (lifeTime or 3) / speed)

	if unit:FindFirstChild("Destroying") then
		unit.Destroying:Once(function()
			if vfx and vfx.Parent then
				vfx:Destroy()
			end
		end)
	end

	EmitModule.emit(vfx)

	task.delay((attackTime or 0.5) / speed, function()
		if unit and unit.Parent and unit:FindFirstChild("Attacking") then
			unit.Attacking.Value = false
		end
	end)
end

module["Palpotin light"] = function(HRP, target)
	playSimpleSkill(
		HRP,
		target,
		"Folder",
		"First",
		function(HRP, target)
			local enemyPos = getEnemyPos(HRP, target)
			local spawnPos = HRP.Position + HRP.CFrame.LookVector * 4
			return CFrame.lookAt(spawnPos, enemyPos)
		end,
		2.5,
		0.45,
		0.2
	)
end

module["Doom Bolt"] = function(HRP, target)
	playSimpleSkill(
		HRP,
		target,
		"Second",
		"Second",
		function(HRP, target)
			local enemyPos = getEnemyPos(HRP, target)
			return CFrame.new(enemyPos + Vector3.new(0, 0, 0))
		end,
		3,
		0.55,
		0.25
	)
end

module["Emperor Rage"] = function(HRP, target)
	playSimpleSkill(
		HRP,
		target,
		"Third",
		"Third",
		function(HRP, target)
			local enemyPos = getEnemyPos(HRP, target)
			return CFrame.new(enemyPos + Vector3.new(0, 0, 0))
		end,
		3.5,
		0.8,
		0.4
	)
end

return module