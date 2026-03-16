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

module["332nd Trooper Attack"] = function(HRP, target)
	local Folder = VFX.Epic["nd 332 Trooper"]
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	local speed = GameSpeed.Value

	task.wait(0.84/speed)
	if not HRP or not HRP.Parent then return end

	HRP.Parent.Attacking.Value = true
	VFX_Helper.SoundPlay(HRP,Folder.Sound)

	local lookAtPos = enemypos + Vector3.new(0, -1, 0)

	local Ball = Folder:WaitForChild("Part"):Clone()
	Ball.CFrame = HRP.Parent["Right Arm"].Gun.Pos.CFrame
	Ball.Position = HRP.Parent["Right Arm"].Gun.Pos.Position 
	Ball.Parent = vfxFolder
	Debris:AddItem(Ball,1/speed)
	
	UnitSoundEffectLib.playSound(HRP.Parent, 'Blaster1')
	
	task.wait(0.01/speed)
	if not HRP or not HRP.Parent then return end
	TS:Create(Ball,TweenInfo.new(0.1/speed,Enum.EasingStyle.Linear),{Position = lookAtPos}):Play()
	task.wait(0.05/speed)
	if not HRP or not HRP.Parent then return end
	local explosion = Folder:WaitForChild("Explosionnnnns"):Clone()
	explosion.Position = enemypos
	explosion.Parent = vfxFolder
	Debris:AddItem(explosion,2)
	VFX_Helper.EmitAllParticles(explosion)
	task.wait(0.05/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.OffAllParticles(Ball)
	Ball.Transparency = 1
	task.wait(1.2/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = false
end

return module
