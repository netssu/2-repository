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

module["Eileen Secra Attack"] = function(HRP, target)
	local Folder = VFX["Eileen Secra"].First
	local speed = GameSpeed.Value
	local startCFrame = HRP.CFrame
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)
	local trail = Folder:WaitForChild("Trail"):Clone()
	trail.CFrame = HRP.Parent["Right Arm"].Handle.CFrame * CFrame.Angles(0, math.rad(90), 0)
	trail.Parent = vfxFolder
	Debris:AddItem(trail, 2/speed)

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP.Parent["Right Arm"].Handle
	weld.Part1 = trail
	weld.Parent = trail

	task.wait(0.5/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	VFX_Helper.SoundPlay(HRP,Folder.Sound)

	local emitHRP = Folder:WaitForChild("EffectHRP"):Clone()
	emitHRP.CFrame = HRP.CFrame
	emitHRP.Parent = HRP.Parent
	Debris:AddItem(emitHRP, 3/speed)

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP
	weld.Part1 = emitHRP
	weld.Parent = emitHRP
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local steps = 12  
	local duration = 0.4 / steps 
	local amplitude = 3.5 
	VFX_Helper.OnAllParticles(trail.Effect)
	local finalPosition = HRP.CFrame * CFrame.new(0, 0, -Range)
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing1')
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing2')

	for i = 1, steps do
		local progress = i / steps 
		local smoothProgress = math.sin(progress * math.pi * 0.4)  
		local dynamicAmplitude = amplitude * (1 - progress) 
		local offset = math.sin(progress * math.pi * 4) * dynamicAmplitude  
		local intermediatePosition = startCFrame:Lerp(finalPosition, smoothProgress)  
		intermediatePosition = intermediatePosition * CFrame.new(offset, 0, 0)  

		TS:Create(HRP, TweenInfo.new(duration/speed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {CFrame = intermediatePosition}):Play()
		task.wait(duration/speed)
	end


	VFX_Helper.OffAllParticles(emitHRP)
	VFX_Helper.OffAllParticles(trail.Effect)

	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame

	HRP.Parent.Attacking.Value = false
	task.wait(0.2/speed)
	if not HRP or not HRP.Parent then return end
end

return module
