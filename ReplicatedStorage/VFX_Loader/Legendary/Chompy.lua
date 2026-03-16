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

module["Crossblast"] = function(HRP, target)
	local speed = GameSpeed.Value
	local x = 0.3
	local Folder = VFX["Chompy"].First
	local BallTemplate = Folder:WaitForChild("Ball")
	local vfxFolder = workspace:WaitForChild("VFX")

	task.wait(1 / speed)
	VFX_Helper.SoundPlay(HRP, Folder.First)

	local HRPCF = HRP.CFrame
	if not HRP or not HRP.Parent then return end

	HRP.Parent.Attacking.Value = true
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local targetPosition = (HRPCF * CFrame.new(0, 0, -Range)).Position

	for i = 1, 3 do
		if not HRP or not HRP.Parent then return end

		local Ball = BallTemplate:Clone()
		Ball.CFrame = HRP.Parent.Point.CFrame
		Ball.Position = HRP.Parent.Point.Position
		Ball.Parent = vfxFolder

		Debris:AddItem(Ball, 1 / speed)
		TS:Create(Ball, TweenInfo.new(0.13 / speed, Enum.EasingStyle.Linear), {
			Position = targetPosition
		}):Play()

		UnitSoundEffectLib.playSound(HRP.Parent, 'BlasterBurst1')

		task.wait(x / speed)
	end

	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = false
end


return module
