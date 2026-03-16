local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed
module["Rifleman Attack"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX.Rifleman.First
	VFX_Helper.SoundPlay(HRP,Folder.First)
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	task.wait(0.15/speed)
	HRP.Parent.Attacking.Value = true
	if not HRP or not HRP.Parent then return end

	local HRPCF = HRP.CFrame
	if not HRP or not HRP.Parent then return end
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local direction = HRPCF.LookVector
	local targetPosition = (HRPCF * CFrame.new(0, 0, -Range)).Position
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end

	local Ball = Folder:WaitForChild("Ball"):Clone()
	Ball.CFrame = HRP.Parent["Right Arm"].Gun.Point.CFrame
	Ball.Position = HRP.Parent["Right Arm"].Gun.Point.Position 
	Ball.Parent = vfxFolder
	Debris:AddItem(Ball,1/speed)
	TS:Create(Ball,TweenInfo.new(0.1/speed,Enum.EasingStyle.Linear),{Position = targetPosition}):Play()
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = false
	Ball.Transparency = 1
end




return module
