local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed

module["Burst Fire"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX.Greedy.First
	local BallTemplate = Folder:WaitForChild("Ball")
	local vfxFolder = workspace:WaitForChild("VFX")

	VFX_Helper.SoundPlay(HRP, Folder.First)

	local HRPCF = HRP.CFrame
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true

	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local targetPosition = (HRPCF * CFrame.new(0, 0, -Range)).Position

	local points = {HRP.Parent.LPoint, HRP.Parent.RPoint}

	for i = 1, 4 do
		if not HRP or not HRP.Parent then return end

		local currentPoint = points[(i % 2) + 1]
		local Ball = BallTemplate:Clone()
		Ball.CFrame = currentPoint.CFrame
		Ball.Position = currentPoint.Position
		Ball.Parent = vfxFolder

		Debris:AddItem(Ball, 1 / speed)
		TS:Create(Ball, TweenInfo.new(0.13 / speed, Enum.EasingStyle.Linear), {
			Position = targetPosition
		}):Play()

		task.wait(0.5 / speed)
	end

	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = false
end



return module
