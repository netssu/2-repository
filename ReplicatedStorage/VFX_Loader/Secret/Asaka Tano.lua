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
function cubicBezier(t, p0, p1, p2, p3)
	return (1 - t)^3*p0 + 3*(1 - t)^2*t*p1 + 3*(1 - t)*t^2*p2 + t^3*p3
end


module["Circle of Light"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX["Asaka Tano"].Thrid
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end

	local handleR = HRP.Parent["Right Arm"].HandleR.Trail
	local handleL = HRP.Parent["Left Arm"].HandleL.Trail
	handleL.Enabled = true
	handleR.Enabled = true
	task.wait(0.7/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true

	local Emit = Folder:WaitForChild("AOE_emit"):Clone()
	Emit.Position = HRP.Position
	Emit.Parent = vfxFolder
	Debris:AddItem(Emit,7/speed)
	local connection = HRP.Parent.Destroying:Once(function()
		Emit:Destroy()
	end)
	TS:Create(HRP,TweenInfo.new(0.15/speed, Enum.EasingStyle.Linear),{CFrame = HRP.CFrame * CFrame.new(0, 4, 0)}):Play()
	--HRP.Anchored = true
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.SoundPlay(HRP,Folder.Sound)
	UnitSoundEffectLib.playSound(HRP.Parent, 'Slices1')

	local trail = Folder:WaitForChild("emiterrrr"):Clone()
	trail.CFrame = HRP.CFrame
	trail.Parent = HRP
	Debris:AddItem(trail,2)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP
	weld.Part1 = trail
	weld.Parent = trail
	VFX_Helper.OnAllParticles(trail)
	task.wait(0.05/speed)
	if not HRP or not HRP.Parent then return end

	VFX_Helper.OnAllParticles(Emit)

	local points = {}
	local center = HRP.Position

	for i = 1, 18 do
		local angle = math.rad((360 / 18) * i)
		local radius = 15
		local x = math.cos(angle) * radius
		local z = math.sin(angle) * radius
		local y = math.random(-3, 7)
		table.insert(points, center + Vector3.new(x, y, z))
	end
	
	for i = 1, #points do
		if not HRP or not HRP.Parent then return end
		HRP.CFrame = CFrame.new(points[i])
		task.wait((1.75 / #points) / speed)
	end


	VFX_Helper.OffAllParticles(Emit)
	task.wait(0.35/speed)
	if not HRP or not HRP.Parent then return end

	VFX_Helper.OffAllParticles(trail)

	--HRP.Anchored = false

	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame
	task.wait(1/speed)
	if not HRP or not HRP.Parent then return end
	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame
	handleL.Enabled = false
	handleR.Enabled = false
	HRP.Parent.Attacking.Value = false
	connection:Disconnect()
end

module["Cross Slash"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX["Asaka Tano"].First
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	local Range = HRP.Parent.Config:WaitForChild("Range").Value

	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end

	local handleR = HRP.Parent["Right Arm"]:WaitForChild('HandleR'):WaitForChild('Trail')
	local handleL = HRP.Parent["Left Arm"]:WaitForChild('HandleL'):WaitForChild('Trail')
	handleL.Enabled = true
	handleR.Enabled = true

	local trail = Folder:WaitForChild("emiterrrr"):Clone()
	UnitSoundEffectLib.playSound(HRP.Parent, 'Slices1')
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing' .. tostring(tonumber(1,2)))
	trail.CFrame = HRP.CFrame
	trail.Parent = HRP
	Debris:AddItem(trail,1.2/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP
	weld.Part1 = trail
	weld.Parent = trail
	task.wait(0.25/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.OnAllParticles(trail)
	VFX_Helper.SoundPlay(HRP,Folder.Sound)

	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	local starsemit = Folder:WaitForChild("Burst"):Clone()
	starsemit.Position = HRP.Position
	starsemit.Parent = HRP.Parent
	VFX_Helper.EmitAllParticles(starsemit)

	Debris:AddItem(starsemit,2/speed)
	local targetCFrame = HRP.CFrame * CFrame.new(0, 0, -Range)
	TS:Create(HRP, TweenInfo.new(0.15/speed, Enum.EasingStyle.Linear), {CFrame = targetCFrame}):Play()
	task.wait(0.08/speed)
	if not HRP or not HRP.Parent then return end

	local Hit = Folder:WaitForChild("Slash"):Clone()
	Hit.CFrame = HRP.CFrame 
	Hit.Parent = HRP
	Debris:AddItem(Hit,2/speed)
	VFX_Helper.EmitAllParticles(Hit)
	VFX_Helper.EmitAllParticles(Hit.Slash)
	TS:Create(Hit, TweenInfo.new(0.05/speed, Enum.EasingStyle.Linear), {CFrame = targetCFrame}):Play()
	VFX_Helper.OffAllParticles(trail)

	task.wait(1/speed)
	if not HRP or not HRP.Parent then return end
	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame
	HRP.Parent.Attacking.Value = false
end

module["First Slash"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX["Asaka Tano"].FirstGrenn
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	local Range = HRP.Parent.Config:WaitForChild("Range").Value

	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end

	local handleR = HRP.Parent["Right Arm"].HandleR.Trail
	local handleL = HRP.Parent["Left Arm"].HandleL.Trail
	handleL.Enabled = true
	handleR.Enabled = true
	
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing' .. tostring(tonumber(1,2)))

	local trail = Folder:WaitForChild("emiterrrr"):Clone()
	trail.CFrame = HRP.CFrame
	trail.Parent = HRP
	Debris:AddItem(trail,1.2/speed)
	
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP
	weld.Part1 = trail
	weld.Parent = trail
	task.wait(0.25/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.OnAllParticles(trail)
	VFX_Helper.SoundPlay(HRP,Folder.Sound)
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	local starsemit = Folder:WaitForChild("Burst"):Clone()
	starsemit.Position = HRP.Position
	starsemit.Parent = HRP.Parent
	VFX_Helper.EmitAllParticles(starsemit)

	Debris:AddItem(starsemit,2/speed)
	local targetCFrame = HRP.CFrame * CFrame.new(0, 0, -Range)
	TS:Create(HRP, TweenInfo.new(0.15/speed, Enum.EasingStyle.Linear), {CFrame = targetCFrame}):Play()
	task.wait(0.08/speed)
	if not HRP or not HRP.Parent then return end

	local Hit = Folder:WaitForChild("Slash"):Clone()
	Hit.CFrame = HRP.CFrame 
	Hit.Parent = HRP
	Debris:AddItem(Hit,2/speed)
	VFX_Helper.EmitAllParticles(Hit)
	VFX_Helper.EmitAllParticles(Hit.Slash)
	TS:Create(Hit, TweenInfo.new(0.05/speed, Enum.EasingStyle.Linear), {CFrame = targetCFrame}):Play()
	VFX_Helper.OffAllParticles(trail)

	task.wait(1/speed)
	if not HRP or not HRP.Parent then return end
	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame
	HRP.Parent.Attacking.Value = false
end

module["Vortex Strike"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX["Asaka Tano"].Second
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	local Range = HRP.Parent.Config:WaitForChild("Range").Value

	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end

	local handleR = HRP.Parent["Right Arm"].HandleR.Trail
	local handleL = HRP.Parent["Left Arm"].HandleL.Trail
	handleL.Enabled = true
	handleR.Enabled = true

	local trail = Folder:WaitForChild("emiterrrr"):Clone()
	trail.CFrame = HRP.CFrame
	trail.Parent = HRP
	Debris:AddItem(trail,1/speed)
	UnitSoundEffectLib.playSound(HRP.Parent, 'Slices1')
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing' .. tostring(tonumber(1,2)))
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP
	weld.Part1 = trail
	weld.Parent = trail
	task.wait(0.25/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.OnAllParticles(trail)
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	VFX_Helper.SoundPlay(HRP,Folder.Sound)

	local starsemit = Folder:WaitForChild("Burst"):Clone()
	starsemit.Position = HRP.Position
	starsemit.Parent = HRP.Parent
	VFX_Helper.EmitAllParticles(starsemit)

	Debris:AddItem(starsemit,2/speed)
	local End = CFrame.new(enemypos + Vector3.new(0,0.3,0))
	local Start	= HRP.CFrame
	local Middle = CFrame.new((Start.Position + End.Position) / 2 + Vector3.new(0,5,0) )
	local Middle2 = CFrame.new((Start.Position + End.Position) / 2 + Vector3.new(0,5,0))


	for i = 1, 100, 5  do
		local t = i/100
		local NewPos = cubicBezier(t, Start.Position, Middle.Position, Middle2.Position, End.Position)
		HRP.CFrame = CFrame.new(NewPos)
		task.wait(0.014/speed)
	end

	local slash = Folder:WaitForChild("Slash"):Clone()
	slash.Position = HRP.Position
	slash.Parent = HRP
	Debris:AddItem(slash,3/speed)
	VFX_Helper.OnAllParticles(slash)
	VFX_Helper.OffAllParticles(trail)
	task.wait(0.2/speed)	
	task.spawn(function()
		local points = {}
		local center = HRP.Position

		for i = 1, 18 do
			local angle = math.rad((360 / 18) * i)
			local radius = 4
			local x = math.cos(angle) * radius
			local z = math.sin(angle) * radius
			local y = math.random(-0.5, 2)
			table.insert(points, center + Vector3.new(x, y, z))
		end

		for i = 1, #points do
			if not HRP or not HRP.Parent then return end
			HRP.CFrame = CFrame.new(points[i])
			task.wait(0.75 / #points / speed)
		end
	end)
	
	task.wait(0.8/speed)	

	if not HRP or not HRP.Parent then return end
	VFX_Helper.OffAllParticles(slash)
	task.wait(0.35/speed)
	if not HRP or not HRP.Parent then return end
	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame
	local teleposrrr = Folder:WaitForChild("teleport"):Clone()
	teleposrrr.CFrame = HRP.CFrame + Vector3.new(0,-0.5,0)
	teleposrrr.Parent = vfxFolder	
	Debris:AddItem(teleposrrr,1/speed)
	VFX_Helper.EmitAllParticles(teleposrrr)
	HRP.Parent.Attacking.Value = false
end

module["Saber Flurry"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX["Asaka Tano"].SecondGreen
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	local Range = HRP.Parent.Config:WaitForChild("Range").Value

	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end

	local handleR = HRP.Parent["Right Arm"].HandleR.Trail
	local handleL = HRP.Parent["Left Arm"].HandleL.Trail
	handleL.Enabled = true
	handleR.Enabled = true
	UnitSoundEffectLib.playSound(HRP.Parent, 'Slices1')
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing' .. tostring(tonumber(1,2)))

	local trail = Folder:WaitForChild("emiterrrr"):Clone()
	trail.CFrame = HRP.CFrame
	trail.Parent = HRP
	Debris:AddItem(trail,1/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP
	weld.Part1 = trail
	weld.Parent = trail
	task.wait(0.25/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.OnAllParticles(trail)
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	VFX_Helper.SoundPlay(HRP,Folder.Sound)

	local starsemit = Folder:WaitForChild("Burst"):Clone()
	starsemit.Position = HRP.Position
	starsemit.Parent = HRP.Parent
	VFX_Helper.EmitAllParticles(starsemit)

	Debris:AddItem(starsemit,2/speed)
	local End = CFrame.new(enemypos + Vector3.new(0,0.3,0))
	local Start	= HRP.CFrame
	local Middle = CFrame.new((Start.Position + End.Position) / 2 + Vector3.new(0,5,0) )
	local Middle2 = CFrame.new((Start.Position + End.Position) / 2 + Vector3.new(0,5,0))


	for i = 1, 100, 5  do
		local t = i/100
		local NewPos = cubicBezier(t, Start.Position, Middle.Position, Middle2.Position, End.Position)
		HRP.CFrame = CFrame.new(NewPos)
		task.wait(0.014/speed)
	end

	local slash = Folder:WaitForChild("Slash"):Clone()
	slash.Position = HRP.Position
	slash.Parent = HRP
	Debris:AddItem(slash,3/speed)
	VFX_Helper.OnAllParticles(slash)
	VFX_Helper.OffAllParticles(trail)
	task.wait(0.2/speed)	
	task.spawn(function()
		local points = {}
		local center = HRP.Position

		for i = 1, 18 do
			local angle = math.rad((360 / 18) * i)
			local radius = 4
			local x = math.cos(angle) * radius
			local z = math.sin(angle) * radius
			local y = math.random(-0.5, 2)
			table.insert(points, center + Vector3.new(x, y, z))
		end

		for i = 1, #points do
			if not HRP or not HRP.Parent then return end
			HRP.CFrame = CFrame.new(points[i])
			task.wait(0.75 / #points / speed)
		end
	end)

	task.wait(0.8/speed)	

	if not HRP or not HRP.Parent then return end
	VFX_Helper.OffAllParticles(slash)
	task.wait(0.35/speed)
	if not HRP or not HRP.Parent then return end
	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame
	local teleposrrr = Folder:WaitForChild("teleport"):Clone()
	teleposrrr.CFrame = HRP.CFrame + Vector3.new(0,-0.5,0)
	teleposrrr.Parent = vfxFolder	
	Debris:AddItem(teleposrrr,1/speed)
	VFX_Helper.EmitAllParticles(teleposrrr)
	HRP.Parent.Attacking.Value = false
end
return module
