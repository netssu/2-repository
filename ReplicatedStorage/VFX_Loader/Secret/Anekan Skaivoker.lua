local module = {}

local rs = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local VFX = rs:WaitForChild("VFX")
local vfxFolder = workspace:WaitForChild("VFX")
local VFX_Helper = require(rs.Modules:WaitForChild("VFX_Helper"))
local GameSpeed = workspace.Info:WaitForChild("GameSpeed")

local function getSkillAssets(folder, assetName)
	local sound, visual

	for _, obj in ipairs(folder:GetChildren()) do
		if obj.Name == assetName then
			if obj:IsA("Sound") then
				sound = obj
			elseif obj:IsA("BasePart") or obj:IsA("Model") then
				visual = obj
			end
		end
	end

	return sound, visual
end

local function setVFXCFrame(vfx, cf)
	if vfx:IsA("Model") then
		vfx:PivotTo(cf)
	else
		vfx.CFrame = cf
	end
end

local function getTargetPosition(HRP, target)
	if target and target:FindFirstChild("HumanoidRootPart") then
		return target.HumanoidRootPart.Position
	end

	local range = HRP.Parent.Config:WaitForChild("Range").Value
	return (HRP.CFrame * CFrame.new(0, 0, -range)).Position
end

local function playSimpleSkill(HRP, target, folderName, assetName, getCFrame, lifeTime, attackTime)
	if not HRP or not HRP.Parent then
		return
	end

	local unit = HRP.Parent
	local speed = GameSpeed.Value
	local folder = VFX:WaitForChild("Dart Wader"):WaitForChild(folderName)

	local sound, template = getSkillAssets(folder, assetName)
	if not template then
		warn(("VFX '%s' não encontrado em Dart Wader/%s"):format(assetName, folderName))
		return
	end

	if sound then
		VFX_Helper.SoundPlay(HRP, sound)
	end

	unit.Attacking.Value = true

	local vfx = template:Clone()
	setVFXCFrame(vfx, getCFrame(HRP, target))
	vfx.Parent = vfxFolder

	VFX_Helper.EmitAllParticles(vfx)
	Debris:AddItem(vfx, (lifeTime or 3) / speed)

	task.delay((attackTime or 0.4) / speed, function()
		if unit and unit.Parent and unit:FindFirstChild("Attacking") then
			unit.Attacking.Value = false
		end
	end)
end

module["Dart Wader attack"] = function(HRP, target)
	playSimpleSkill(HRP, target, "First", "First", function(HRP)
		local range = HRP.Parent.Config.Range.Value
		return HRP.CFrame * CFrame.new(0, 0, -math.clamp(range * 0.5, 4, 12))
	end, 3, 0.45)
end

module["Anekan Skaivoker"] = function(HRP, target)
	playSimpleSkill(HRP, target, "First_Blue", "First", function(HRP)
		local range = HRP.Parent.Config.Range.Value
		return HRP.CFrame * CFrame.new(0, 0, -math.clamp(range * 0.5, 4, 12))
	end, 3, 0.45)
end

module["Stone Rain attack"] = function(HRP, target)
	playSimpleSkill(HRP, target, "Second", "Second", function(HRP, target)
		local pos = getTargetPosition(HRP, target)
		return CFrame.new(pos)
	end, 3, 0.6)
end

module["Stone Rain"] = function(HRP, target)
	playSimpleSkill(HRP, target, "Second_Blue", "Second", function(HRP, target)
		local pos = getTargetPosition(HRP, target)
		return CFrame.new(pos)
	end, 3, 0.6)
end

module["Death Star"] = function(HRP, target)
	playSimpleSkill(HRP, target, "Third", "Third", function(HRP, target)
		local pos = getTargetPosition(HRP, target)
		return CFrame.lookAt(pos + Vector3.new(0, 10, 0), pos)
	end, 4, 1)
end

return module