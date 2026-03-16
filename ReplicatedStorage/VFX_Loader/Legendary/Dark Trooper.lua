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
module["Rifle Blast"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX["Dark Trooper"].First
	task.wait(1/speed)

	VFX_Helper.SoundPlay(HRP,Folder.First)
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	local HRPCF = HRP.CFrame
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	print(Range, "new range")
	local direction = HRPCF.LookVector
	local targetPosition = (HRPCF * CFrame.new(0, 0, -Range)).Position
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end

	local function createBall(fromPoint)
		local Ball = Folder:WaitForChild("Ball"):Clone()
		Ball.CFrame = fromPoint.CFrame
		Ball.Position = fromPoint.Position
		Ball.Parent = vfxFolder
		Debris:AddItem(Ball, 1/speed)

		TS:Create(Ball, TweenInfo.new(0.13/speed, Enum.EasingStyle.Linear), {Position = targetPosition}):Play()

		task.delay(0.13/speed, function()
			if HRP and HRP.Parent then
				Ball.Transparency = 1
			end
		end)
	end

	local parentModel = HRP.Parent
	if parentModel then
		local rightPoint = parentModel:FindFirstChild("RightHand") and parentModel.RightHand:FindFirstChild("Point")
		local leftPoint = parentModel:FindFirstChild("LeftHand") and parentModel.LeftHand:FindFirstChild("Point")

		if rightPoint and leftPoint then
			UnitSoundEffectLib.playSound(HRP.Parent, 'LaserGun' .. tostring(math.random(1,4)))
			createBall(rightPoint)
			createBall(leftPoint)
		end
	end

	task.wait(0.13/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = false

end

return module
