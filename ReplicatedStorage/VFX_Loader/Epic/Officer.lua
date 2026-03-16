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

module["Officer Attack"] = function(HRP, target)
	local Folder = VFX.Officer.First
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	local speed = GameSpeed.Value

	task.wait(0.3/speed)
	HRP.Parent.Attacking.Value = true
	if not HRP or not HRP.Parent then return end
	VFX_Helper.SoundPlay(HRP,Folder.Sound)

	local HRPCF = HRP.CFrame
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local direction = HRPCF.LookVector
	local targetPosition = (HRPCF * CFrame.new(0, 0, -Range)).Position
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	local Ball = Folder:WaitForChild("Ball"):Clone()
	Ball.CFrame = HRP.Parent["Left Arm"].Handle.Positions.CFrame
	Ball.Position = HRP.Parent["Left Arm"].Handle.Positions.Position 
	Ball.Parent = vfxFolder
	UnitSoundEffectLib.playSound(HRP.Parent, 'Blaster3')
	Debris:AddItem(Ball,1/speed)
	TS:Create(Ball,TweenInfo.new(0.15/speed,Enum.EasingStyle.Linear),{Position = targetPosition}):Play()
	VFX_Helper.EmitAllParticles(HRP.Parent["Left Arm"].Handle.Winnd)
	task.wait(0.15/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = false
	VFX_Helper.OffAllParticles(Ball)
	Ball.Transparency = 1
end

return module
