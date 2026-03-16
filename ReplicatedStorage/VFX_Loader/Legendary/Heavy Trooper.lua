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

module["Heavy Trooper Attack"] = function(HRP, target)
	local Folder = VFX["Heavy Trooper"].First
	local speed = GameSpeed.Value

	--VFX_Helper.SoundPlay(HRP,Folder.First)
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	task.wait(0.15/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	local HRPCF = HRP.CFrame
	if not HRP or not HRP.Parent then return end
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local direction = HRPCF.LookVector
	local targetPosition = (HRPCF * CFrame.new(0, -0.4, -Range)).Position

	local Ball = Folder:WaitForChild("Ball"):Clone()
	Ball.CFrame = HRP.Parent["Right Arm"].Regular.Ball.CFrame
	Ball.Position = HRP.Parent["Right Arm"].Regular.Ball.Position 
	Ball.Parent = vfxFolder
	Debris:AddItem(Ball,1/speed)
	task.wait(0.02/speed)
	local emitgun = HRP.Parent["Right Arm"].Regular.Ball
	VFX_Helper.EmitAllParticles(emitgun)
	UnitSoundEffectLib.playSound(HRP.Parent, 'EliteBlaster1')
	
	TS:Create(Ball,TweenInfo.new(0.1/speed,Enum.EasingStyle.Linear),{Position = targetPosition}):Play()
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	Ball.Transparency = 1
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.OffAllParticles(Ball)
	HRP.Parent.Attacking.Value = false
end

return module
