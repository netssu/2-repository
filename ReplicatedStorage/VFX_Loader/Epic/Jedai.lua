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
local GameSpeed = game.Workspace.Info.GameSpeed
module["Jedai Attack"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX.Jedai.First
	VFX_Helper.SoundPlay(HRP,Folder.First)
	local startCFrame = HRP.CFrame
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	
	local trail = Folder:WaitForChild("Trail"):Clone()
	trail.CFrame = HRP.Parent["Right Arm"].Handle.CFrame * CFrame.Angles(0,math.rad(90),0)
	trail.Parent = vfxFolder
	Debris:AddItem(trail,1/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP.Parent["Right Arm"].Handle
	weld.Part1 = trail
	weld.Parent = trail
	task.wait(0.1/speed)
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing1')
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	local starsemit = Folder:WaitForChild("Ground"):Clone()
	starsemit.Position = HRP.Position + Vector3.new(0,1.55,0)
	starsemit.Parent = HRP.Parent
	VFX_Helper.EmitAllParticles(starsemit)
	Debris:AddItem(starsemit,2/speed)
	local enemyCFrame = CFrame.new(enemypos) * CFrame.Angles(HRP.CFrame:ToEulerAnglesXYZ())
	TS:Create(HRP, TweenInfo.new(0.1/speed, Enum.EasingStyle.Linear), {CFrame = enemyCFrame + enemyCFrame.LookVector * -2.5}):Play()
	task.wait(0.1/speed)
	local Hit = Folder:WaitForChild("Emit"):Clone()
	Hit.Position = enemypos 
	Hit.Parent = vfxFolder
	Debris:AddItem(Hit,1/speed)
	task.spawn(function()
		task.wait(0.1/speed)
		VFX_Helper.EmitAllParticles(Hit)

	end)
	if not HRP or not HRP.Parent then return end
	
	task.wait(0.54/speed)
	if not HRP or not HRP.Parent then return end
	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame
	HRP.Parent.Attacking.Value = false
end

return module
