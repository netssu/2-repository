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

local LightningSparks = require(rs.VFXModules.LightningBolt.LightningSparks)
local LightningModule = require(rs.VFXModules.LightningModule)

local GameSpeed = workspace.Info.GameSpeed

module["Red Guard Attack"] = function(HRP, target)
	local Folder = VFX["Red Guard"].First
	local speed = GameSpeed.Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)

	local lightning = HRP.Parent["Right Arm"].Handle.PosPart	
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.OnAllParticles(lightning)
	task.wait(0.73/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	VFX_Helper.SoundPlay(HRP,Folder.First)
	local StartAttachment = Folder:WaitForChild("start"):Clone()
	StartAttachment.Position = HRP.Parent["Right Arm"].Handle.PosPart.Position
	StartAttachment.Parent = vfxFolder
	Debris:AddItem(StartAttachment,2/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP.Parent["Right Arm"].Handle.PosPart
	weld.Part1 = StartAttachment
	weld.Parent = StartAttachment
	
	local EndAttachment = Folder:WaitForChild("end"):Clone()
	EndAttachment.Position = enemypos + Vector3.new(0,-1,0)
	EndAttachment.Parent = vfxFolder
	Debris:AddItem(EndAttachment,2/speed)
	local Lightning = LightningModule.new(StartAttachment.Attachment, EndAttachment.Attachment, 9)
	Lightning.MinRadius = 0.5 
	Lightning.MaxRadius = 1 
	Lightning.AnimationSpeed = 5 
	Lightning.FadeLength = 0.5 
	Lightning.PulseLength = 5 
	Lightning.Thickness = 0.5
	Lightning.MinTransparency, Lightning.MaxTransparency = 0.3, 2.5 
	Lightning.ContractFrom = 3
	Lightning.PulseSpeed = math.random(8, 12) 
	Lightning.MinThicknessMultiplier, Lightning.MaxThicknessMultiplier = 0.3, 0.5 
	Lightning.Color = ColorSequence.new(Color3.fromRGB(199, 0, 149), Color3.fromRGB(199, 0, 149)) 

	UnitSoundEffectLib.playSound(HRP.Parent, 'Thunder')

	LightningSparks.new(Lightning)
	local endemit = Folder:WaitForChild("PartDown"):Clone()
	endemit.Position = enemypos + Vector3.new(0,-1,0)
	endemit.Parent = vfxFolder
	Debris:AddItem(endemit,3/speed)
	VFX_Helper.EmitAllParticles(endemit)
	task.wait(0.3/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.OffAllParticles(lightning)
	HRP.Parent.Attacking.Value = false
end

return module
