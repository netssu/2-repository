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

function cubicBezier(t, p0, p1, p2, p3)
	return (1 - t)^3*p0 + 3*(1 - t)^2*t*p1 + 3*(1 - t)*t^2*p2 + t^3*p3
end


module["Rocket Shot"] = function(HRP, target)
	local Folder = VFX["Commander Codi 222th"].First
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)
	local speed = GameSpeed.Value

	task.wait(0.7 / speed)
	HRP.Parent.Attacking.Value = true
	if not HRP or not HRP.Parent then return end
	VFX_Helper.SoundPlay(HRP,Folder.Sound)
	UnitSoundEffectLib.playSound(HRP.Parent, 'Rockets' .. tostring(math.random(1,2)))

	local HRPCF = HRP.CFrame
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local direction = HRPCF.LookVector
	task.wait(0.1 / speed)
	if not HRP or not HRP.Parent then return end

	local heandemit = HRP.Parent["Right Arm"].Gun.emit

	local rocket = Folder:WaitForChild("Rocket"):Clone()
	local startPos = HRP.Parent["Right Arm"].Gun.Pos.Position
	local lookAtPos = enemypos + Vector3.new(0, -1, 0)
	rocket.CFrame = CFrame.lookAt(startPos, lookAtPos)
	rocket.Parent = vfxFolder
	Debris:AddItem(rocket, 2 / speed)
	local connection = HRP.Parent.Destroying:Once(function()
		rocket:Destroy()
	end)
	task.wait(0.01 / speed)
	if not HRP or not HRP.Parent then return end

	TS:Create(rocket, TweenInfo.new(0.2 / speed, Enum.EasingStyle.Linear), {Position = lookAtPos}):Play()
	task.wait(0.04 / speed)
	if not HRP or not HRP.Parent then return end

	--VFX_Helper.OnAllParticles(rocket.FistProjecile)
	VFX_Helper.EmitAllParticles(heandemit)
	task.wait(0.05 / speed)
	if not HRP or not HRP.Parent then return end

	local Endlemit = Folder:WaitForChild("Explosion"):Clone()
	Endlemit.Position = enemypos
	Endlemit.Parent = vfxFolder
	Debris:AddItem(Endlemit, 2 / speed)
	task.wait(0.02 / speed)
	if not HRP or not HRP.Parent then return end

	UnitSoundEffectLib.playSound(HRP.Parent, 'Explosion')
	VFX_Helper.EmitAllParticles(Endlemit)
	VFX_Helper.OffAllParticles(rocket)
	rocket.Transparency = 1

	task.wait(1)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = false
	connection:Disconnect()

end

module["Alpha Strike"] = function(HRP, target)
	local Folder = VFX["Commander Codi 222th"].Second
	local speed = GameSpeed.Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	task.wait(0.65/speed)
	if not HRP or not HRP.Parent then return end
	local HRPCF = HRP.CFrame
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local direction = HRPCF.LookVector
	HRP.Parent.Attacking.Value = true
	task.wait(0.15/speed)
	VFX_Helper.SoundPlay(HRP,Folder.Sound)
	if not HRP or not HRP.Parent then return end
	local connection = nil
	for i = 1, 8 do
		if not HRP or not  HRP.Parent then return end
		local randomoffset = Vector3.new(math.random(-5.5,5.5),-1,math.random(-5.5,5.5))
		local readyrand = enemypos + randomoffset
		local Ball = Folder:WaitForChild("Part"):Clone()
		Ball.CFrame = HRP.Parent["Right Arm"].Gun.Pos.CFrame
		Ball.Position = HRP.Parent["Right Arm"].Gun.Pos.Position 
		Ball.Parent = vfxFolder
		Debris:AddItem(Ball,2/speed)
		connection = HRP.Parent.Destroying:Once(function()
			Ball:Destroy()
		end)
		UnitSoundEffectLib.playSound(HRP.Parent, 'Blaster' .. tostring(math.random(1,3)))
		task.wait(0.01/speed)
		TS:Create(Ball,TweenInfo.new(0.13/speed,Enum.EasingStyle.Linear),{Position = readyrand}):Play()
		VFX_Helper.EmitAllParticles(HRP.Parent["Right Arm"].Gun.Pos.Winnd)
		task.wait(0.1/speed)
		if not HRP or not HRP.Parent then return end
		local Endlemit = Folder:WaitForChild("Explosion"):Clone()
		Endlemit.Position = readyrand + Vector3.new(0,0.23,0)
		Endlemit.Parent = vfxFolder
		Debris:AddItem(Endlemit,2/speed)
		VFX_Helper.EmitAllParticles(Endlemit)
		VFX_Helper.OffAllParticles(Ball)
		Ball.Transparency = 1
	end

	task.wait(1/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = false
	connection:Disconnect()

end


module["High Energy Shot"] = function(HRP, target)
	local Folder = VFX["Commander Codi 222th"].Thrid
	local speed = GameSpeed.Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	task.wait(0.75/speed)
	if not HRP or not HRP.Parent then return end
	local HRPCF = HRP.CFrame
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	HRP.Parent.Attacking.Value = true
	
	local zalpNNP = Folder:WaitForChild("Startemit"):Clone()
	zalpNNP.CFrame = HRP.Parent["Right Arm"].Gun.Pos.CFrame
	zalpNNP.Parent = HRP.Parent
	Debris:AddItem(zalpNNP,2/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP.Parent["Right Arm"].Gun.Pos
	weld.Part1 = zalpNNP
	weld.Parent = zalpNNP
	VFX_Helper.OnAllParticles(zalpNNP)
	VFX_Helper.ScaleParticles(zalpNNP,2)
	task.wait(0.35/speed)
	if not HRP or not HRP.Parent then return end


	local lych = Folder:WaitForChild("Lych"):Clone()
	lych.chargegalickgun.CFrame = HRP.Parent["Right Arm"].Gun.Pos.CFrame
	lych.End.CFrame = HRP.Parent["Right Arm"].Gun.Pos.CFrame
	lych.Parent = vfxFolder
	Debris:AddItem(lych, 4/speed)
	local connection = HRP.Parent.Destroying:Once(function()
		lych:Destroy()
	end)
	local targetPosition = CFrame.new(enemypos + Vector3.new(0, -1, 0)) 
	TS:Create(lych.End, TweenInfo.new(0.25/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = targetPosition}):Play()
	VFX_Helper.OffAllParticles(zalpNNP)
	VFX_Helper.OnAllParticles(lych.chargegalickgun)
	UnitSoundEffectLib.playSound(HRP.Parent, 'LaserGun' .. tostring(math.random(1,4)))
	task.wait(0.22/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.OnAllParticles(lych.End)
	VFX_Helper.ScaleParticles(lych.End,2.2)

	task.wait(0.18/speed)
	if not HRP or not HRP.Parent then return end
	for _, v in (lych:GetChildren()) do
		if v:IsA("Beam") then 
			v.Enabled = true
		end
	end

	task.wait(0.9/speed)
	if not HRP or not HRP.Parent then return end

	for _,v in (lych:GetDescendants()) do	
		if v:IsA("Beam") then
			TS:Create(
				v,
				TweenInfo.new(0.5/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Width0 = 0,Width1 = 0}
			):Play()
		end	
	end
	VFX_Helper.OffAllParticles(lych.End)
	VFX_Helper.OffAllParticles(lych.chargegalickgun)

	task.wait(1/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = false
	connection:Disconnect()

end




return module
