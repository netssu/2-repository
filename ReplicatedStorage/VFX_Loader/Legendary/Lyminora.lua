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

module["Lyminora Attack"] = function(HRP, target)
	local Folder = VFX.Lyminora.First
	local speed = GameSpeed.Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	task.wait(0.65/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	VFX_Helper.SoundPlay(HRP,Folder.Sound)
	local HRPCF = HRP.CFrame
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local direction = HRPCF.LookVector
	task.wait(0.15/speed)
	if not HRP or not HRP.Parent then return end
	local connection = nil

	for i = 1, 5 do
		
		if not HRP or not  HRP.Parent then return end
		local randomoffset = Vector3.new(math.random(-3,3),-1,math.random(-3,3))
		local readyrand = enemypos + randomoffset
		local Ball = Folder:WaitForChild("Ball"):Clone()
		Ball.CFrame = HRP.Parent["Right Arm"].Regular.Pos.CFrame
		Ball.Position = HRP.Parent["Right Arm"].Regular.Pos.Position 
		Ball.Parent = vfxFolder
		Debris:AddItem(Ball,2/speed)
		connection = HRP.Parent.Destroying:Once(function()
			Ball:Destroy()
		end)
		TS:Create(Ball,TweenInfo.new(0.1/speed,Enum.EasingStyle.Linear),{Position = readyrand}):Play()
		VFX_Helper.EmitAllParticles(HRP.Parent["Right Arm"].Regular.Winnd)
		task.wait(0.09/speed)
		if not HRP or not HRP.Parent then return end
		local Endlemit = Folder:WaitForChild("EndlEmit"):Clone()
		Endlemit.Position = readyrand
		Endlemit.Parent = vfxFolder
		Debris:AddItem(Endlemit,2/speed)
		VFX_Helper.EmitAllParticles(Endlemit)
		VFX_Helper.OffAllParticles(Ball)
		Ball.Transparency = 1
		
		UnitSoundEffectLib.playSound(HRP.Parent, 'Blaster' .. tostring(math.random(1,3)))
	end
	
	task.wait(1/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = false
	connection:Disconnect()

end


return module
