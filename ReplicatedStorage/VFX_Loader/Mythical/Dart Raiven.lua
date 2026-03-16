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

module["Whirlwind of Darkness"] = function(HRP, target)
	local Folder = VFX["Dart Raiven"].Firsrt
	local speed = GameSpeed.Value

	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	--VFX_Helper.SoundPlay(HRP,Folder.Second)
	local trailemit = Folder:WaitForChild("Trailemit"):Clone()
	trailemit.CFrame = HRP.CFrame
	trailemit.Parent = HRP
	Debris:AddItem(trailemit,2/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP
	weld.Part1 = trailemit
	weld.Parent = trailemit
	
	local trail = Folder:WaitForChild("Trail"):Clone()
	trail.CFrame = HRP.Parent["Right Arm"].Handle.CFrame * CFrame.Angles(0,math.rad(90),0)
	trail.Parent = vfxFolder
	Debris:AddItem(trail,2/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP.Parent["Right Arm"].Handle
	weld.Part1 = trail
	weld.Parent = trail
	local trail2 = Folder:WaitForChild("Trail2"):Clone()
	trail2.CFrame = HRP.Parent["Left Arm"].Handle2.CFrame * CFrame.Angles(0,math.rad(90),0)
	trail2.Parent = vfxFolder
	Debris:AddItem(trail2,2/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP.Parent["Left Arm"].Handle2
	weld.Part1 = trail2
	weld.Parent = trail2
	
	task.wait(0.45/speed)
	if not HRP or not HRP.Parent then return end

	HRP.Parent.Attacking.Value = true
	local starsemit = Folder:WaitForChild("Endlemit"):Clone()
	starsemit.Position = HRP.Position + Vector3.new(0,-1.2,0)
	starsemit.Parent = HRP.Parent
	Debris:AddItem(starsemit,2/speed)
	VFX_Helper.OnAllParticles(trailemit)
	task.wait(0.05/speed)
	local enemyCFrame = CFrame.new(enemypos) * CFrame.Angles(HRP.CFrame:ToEulerAnglesXYZ())
	TS:Create(HRP, TweenInfo.new(0.1/speed, Enum.EasingStyle.Linear), {CFrame = enemyCFrame + enemyCFrame.LookVector}):Play()
	task.wait(0.1/speed)
	VFX_Helper.OffAllParticles(trailemit)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.EmitAllParticles(starsemit)
	local slash = Folder:WaitForChild("ExplosionSlash"):Clone()
	slash.Position = enemypos 
	slash.Parent = vfxFolder
	Debris:AddItem(slash,4/speed)
	VFX_Helper.OnAllParticles(slash)
	
	local connection = HRP.Parent.Destroying:Once(function()
		slash:Destroy()
	end)
	if not HRP or not HRP.Parent then return end
	
	for i = 1, 11 do
		if not HRP or not HRP.Parent then return end
		local randomOffset = Vector3.new(math.random(-6, 6), math.random(-1, 1), math.random(-6, 6))
		local randomPos = enemypos + randomOffset
		HRP.CFrame = CFrame.new(randomPos)
		task.wait(1.5 /10/speed) 
	end
	HRP.CFrame = CFrame.new(enemypos + Vector3.new(0,0,-2))
	task.wait(0.15/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.OffAllParticles(slash)
	task.wait(0.6/speed)
	if not HRP or not HRP.Parent then return end
	local ganblaster = Folder:WaitForChild("Teleportbls"):Clone()
	ganblaster.Position = HRP.Position + Vector3.new(0,-1,0)
	ganblaster.Parent = vfxFolder
	Debris:AddItem(ganblaster,2/speed)
	VFX_Helper.EmitAllParticles(ganblaster)


	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame
	local teleposr = Folder:WaitForChild("Teleportbls"):Clone()
	teleposr.CFrame = HRP.CFrame + Vector3.new(0,-0.5,0)
	teleposr.Parent = vfxFolder	
	Debris:AddItem(teleposr,1/speed)
	VFX_Helper.EmitAllParticles(teleposr)
	HRP.Parent.Attacking.Value = false
	connection:Disconnect()

end

module["Double Slash"] = function(HRP, target)
	local Folder = VFX["Dart Raiven"].Second
	local speed = GameSpeed.Value
	local Range = HRP.Parent.Config:WaitForChild("Range").Value

	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	--VFX_Helper.SoundPlay(HRP,Folder.Second)
	local trail = Folder:WaitForChild("Trail"):Clone()
	trail.CFrame = HRP.Parent["Right Arm"].Handle.CFrame * CFrame.Angles(0,math.rad(90),0)
	trail.Parent = vfxFolder
	Debris:AddItem(trail,2/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP.Parent["Right Arm"].Handle
	weld.Part1 = trail
	weld.Parent = trail
	local trail2 = Folder:WaitForChild("Trail2"):Clone()
	trail2.CFrame = HRP.Parent["Left Arm"].Handle2.CFrame * CFrame.Angles(0,math.rad(90),0)
	trail2.Parent = vfxFolder
	Debris:AddItem(trail2,2/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP.Parent["Left Arm"].Handle2
	weld.Part1 = trail2
	weld.Parent = trail2
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing1')
	task.wait(0.8/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	
	local slash = Folder:WaitForChild("Positions"):Clone()
	slash.CFrame = HRP.CFrame 
	slash.Parent = vfxFolder
	Debris:AddItem(slash,3/speed)
	local connection = HRP.Parent.Destroying:Once(function()
		slash:Destroy()
	end)
	
	task.wait(0.1/speed)
	local decal = Folder:WaitForChild("Dacals"):Clone()
	decal.CFrame = HRP.CFrame 
	decal.Parent = vfxFolder
	Debris:AddItem(decal,3/speed)
	local connection = HRP.Parent.Destroying:Once(function()
		decal:Destroy()
	end)
	if not HRP or not HRP.Parent then return end
	local targetPosition = ( HRP.CFrame * CFrame.new(0, -1, -Range))
	TS:Create(slash, TweenInfo.new(0.2/speed, Enum.EasingStyle.Linear), {CFrame = targetPosition}):Play()
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.EmitAllParticles(decal)
	task.wait(0.06/speed)
	if not HRP or not HRP.Parent then return end

	VFX_Helper.OffAllParticles(slash)
	for _,v in (slash:GetDescendants()) do	
		if v:IsA("Beam") then
			TS:Create(
				v,
				TweenInfo.new(0.65/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Width0 = 0,Width1 = 0}
			):Play()
		end	
	end
	if not HRP or not HRP.Parent then return end
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing2')
	task.wait(1.2/speed)
	if not HRP or not HRP.Parent then return end
	for _,v in (decal:GetDescendants()) do	
		if v:IsA('Decal') then
			TS:Create(
				v,
				TweenInfo.new(1/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Transparency = 1}
			):Play()
		end
	end
	connection:Disconnect()
	HRP.Parent.Attacking.Value = false

end

module["Doom Leap"] = function(HRP, target)
	local Folder = VFX["Dart Raiven"].thrid
	local speed = GameSpeed.Value
	local Range = HRP.Parent.Config:WaitForChild("Range").Value

	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	--VFX_Helper.SoundPlay(HRP,Folder.Second)
	local trail = Folder:WaitForChild("Trail"):Clone()
	trail.CFrame = HRP.Parent["Right Arm"].Handle.CFrame * CFrame.Angles(0,math.rad(90),0)
	trail.Parent = vfxFolder
	Debris:AddItem(trail,2/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP.Parent["Right Arm"].Handle
	weld.Part1 = trail
	weld.Parent = trail
	local trail2 = Folder:WaitForChild("Trail2"):Clone()
	trail2.CFrame = HRP.Parent["Left Arm"].Handle2.CFrame * CFrame.Angles(0,math.rad(90),0)
	trail2.Parent = vfxFolder
	Debris:AddItem(trail2,2/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP.Parent["Left Arm"].Handle2
	weld.Part1 = trail2
	weld.Parent = trail2
	task.wait(0.45/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing1')
	local startemit = Folder:WaitForChild("Endlemit"):Clone()
	startemit.Position = HRP.Position
	startemit.Parent = vfxFolder
	Debris:AddItem(startemit,2/speed)
	VFX_Helper.EmitAllParticles(startemit)
	
	local End = CFrame.new(enemypos + Vector3.new(0,2,0))
	local Start	= HRP.CFrame
	local Middle = CFrame.new((Start.Position + End.Position) / 2 + Vector3.new(0,5,0) )
	local Middle2 = CFrame.new((Start.Position + End.Position) / 2 + Vector3.new(0,5,0))

	task.spawn(function()
		task.wait(0.5/speed)

		local Emit = Folder:WaitForChild("main"):Clone()
		Emit.Position = enemypos + Vector3.new(0,-0.5,0)
		Emit.Parent = vfxFolder
		Debris:AddItem(Emit,2/speed)
		VFX_Helper.EmitAllParticles(Emit)

	end)

	for i = 1, 100, 5  do
		local t = i/100
		local NewPos = cubicBezier(t, Start.Position, Middle.Position, Middle2.Position, End.Position)
		HRP.CFrame = CFrame.new(NewPos)
		task.wait(0.014/speed)
	end
	TS:Create(HRP, TweenInfo.new(0.1/speed, Enum.EasingStyle.Linear), {CFrame = CFrame.new(enemypos) }):Play()
	task.wait(1.2/speed)
	local teleposrSE = Folder:WaitForChild("Teleportbls"):Clone()
	teleposrSE.CFrame = HRP.CFrame + Vector3.new(0,-0.5,0)
	teleposrSE.Parent = vfxFolder	
	Debris:AddItem(teleposrSE,1/speed)
	VFX_Helper.EmitAllParticles(teleposrSE)
	
	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame
	local teleposr = Folder:WaitForChild("Teleportbls"):Clone()
	teleposr.CFrame = HRP.CFrame + Vector3.new(0,-0.5,0)
	teleposr.Parent = vfxFolder	
	Debris:AddItem(teleposr,1/speed)
	VFX_Helper.EmitAllParticles(teleposr)

	HRP.Parent.Attacking.Value = false

end





return module
