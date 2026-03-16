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
local RunService = game:GetService("RunService")
local GameSpeed = workspace.Info.GameSpeed

function cubicBezier(t, p0, p1, p2, p3)
	return (1 - t)^3*p0 + 3*(1 - t)^2*t*p1 + 3*(1 - t)*t^2*p2 + t^3*p3
end

module["Dakar Guard Attack"] = function(HRP, target)
	local Folder = VFX["Dakar Guard"].first
	local speed = GameSpeed.Value
	local Range = HRP.Parent.Config:WaitForChild("Range").Value

	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)

	task.wait(0.35/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	VFX_Helper.SoundPlay(HRP,Folder.Sound)

	local trail = Folder:WaitForChild("Trail"):Clone()
	trail.CFrame = HRP.Parent["Right Arm"].sword.CFrame 
	trail.Parent = vfxFolder
	Debris:AddItem(trail,1/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP.Parent["Right Arm"].sword
	weld.Part1 = trail
	weld.Parent = trail
	local Start = HRP.CFrame
	local End = CFrame.new(enemypos + Vector3.new(0, 0, 0)) 
	local Offset = (End.Position - HRP.Position).unit * -2 
	End = CFrame.new(enemypos + Offset) 

	local Middle = CFrame.new((Start.Position + End.Position) / 2 + Vector3.new(0, 4, 0))
	local Middle2 = CFrame.new((Start.Position + End.Position) / 2 + Vector3.new(0, 3, 0))

	local startRotation = HRP.CFrame - HRP.Position
	local startCFrame = HRP.CFrame
	UnitSoundEffectLib.playSound(HRP.Parent, 'Flamethrower')
	task.spawn(function()
		task.wait(0.5/speed)
		local Emit = Folder:WaitForChild("Pos"):Clone()
		Emit.Position = enemypos + Vector3.new(0,1,0)
		Emit.CFrame = HRP.CFrame 
		Emit.Parent = vfxFolder
		Debris:AddItem(Emit, 2/speed)
		VFX_Helper.EmitAllParticles(Emit)
	end)
	task.spawn(function()
		task.wait(0.1/speed)
		local startemit = Folder:WaitForChild("StartEmit"):Clone()
		startemit.CFrame = startCFrame + Vector3.new(0, -1, 0)
		startemit.Parent = vfxFolder
		Debris:AddItem(startemit, 2/speed)
		VFX_Helper.EmitAllParticles(startemit)

		local teleposrtter = Folder:WaitForChild("teleport"):Clone()
		teleposrtter.CFrame = startCFrame + Vector3.new(0, -0.5, 0)
		teleposrtter.Parent = vfxFolder    
		Debris:AddItem(teleposrtter, 1/speed)
		VFX_Helper.EmitAllParticles(teleposrtter)
	end)
	

	for i = 1, 100, 4.3 do
		local t = i / 100
		local NewPos = cubicBezier(t, Start.Position, Middle.Position, Middle2.Position, End.Position)
		HRP.CFrame = CFrame.fromMatrix(NewPos, startRotation.XVector, startRotation.YVector, startRotation.ZVector)

		task.wait(0.005/speed)
	end

	task.wait(0.88/speed)
	local teleposr = Folder:WaitForChild("teleport"):Clone()
	teleposr.CFrame = HRP.CFrame + Vector3.new(0, -0.5, 0)
	teleposr.Parent = vfxFolder	
	Debris:AddItem(teleposr, 1/speed)
	VFX_Helper.EmitAllParticles(teleposr)
	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame
	HRP.Parent.Attacking.Value = false
end

module["Whirlwind Slash"] = function(HRP, target)
	local Folder = VFX["Dakar Guard"].Second
	local speed = GameSpeed.Value
	local Range = HRP.Parent.Config:WaitForChild("Range").Value

	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)

	task.wait(0.35/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	
	local AOEEmit = Folder:WaitForChild("AOE_emit"):Clone()
	AOEEmit.CFrame = HRP.CFrame
	AOEEmit.Parent = HRP
	Debris:AddItem(AOEEmit,2.5/speed)
	VFX_Helper.EmitAllParticles(AOEEmit)
	
	HRP.Parent.Attacking.Value = false
end




return module
