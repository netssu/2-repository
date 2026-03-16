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

module["Dart Mol Attack"] = function(HRP, target)
	local Folder = VFX["Dart Mol"].First
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local speed = GameSpeed.Value

	task.wait(0.78/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	
	local handlePos = HRP.Parent["Right Arm"].FakeHandle
	local HRPCF = HRP.CFrame
	local startPosition = handlePos.Position 
	local targetPosition = HRPCF * CFrame.new(0, 0, -Range)

	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing' .. tostring(math.random(1,2)))

	VFX_Helper.Transparency(handlePos, 1)
	local emit = Folder:WaitForChild("Winnd"):Clone()
	emit.CFrame = HRP.CFrame * CFrame.new(0.5,0.8,-1.4)
	emit.Parent = vfxFolder
	Debris:AddItem(emit,3/speed)
	VFX_Helper.EmitAllParticles(emit)
	
	local Handle: BasePart = handlePos:Clone()
	Handle.Anchored = true
	Handle.Parent = vfxFolder
	Debris:AddItem(Handle, 2.5/speed)
	VFX_Helper.OffAllParticles(handlePos)
	Handle.HandleM.Trail.Enabled = true
	Handle.HandleM.Trail2.Enabled = true
	for _, part in handlePos:GetDescendants() do
		if part:IsA("BasePart") then
			part.Transparency = 1
		end
	end
	VFX_Helper.OnAllParticles(Handle.HandleM.Part)
	VFX_Helper.OnAllParticles(Handle.HandleM.Part2)
	Handle.CFrame = HRPCF * CFrame.Angles(math.rad(90), 0, 0)
	local connection = HRP.Parent.Destroying:Once(function()
		Handle:Destroy()
	end)
	local fakeHandle = Handle:FindFirstChild("FakeHandleMotor")
	local function rotateChildren()
		for i = 1, 360, 10 do 
			if not HRP or not HRP.Parent then return end
			fakeHandle.Transform = CFrame.Angles(math.rad(i), math.rad(i), math.rad(i))
			task.wait(0.02/speed)
		end
		for i = 1, 360, 10 do 
			if not HRP or not HRP.Parent then return end
			fakeHandle.Transform = CFrame.Angles(math.rad(i), math.rad(i), math.rad(i))
			task.wait(0.02/speed)
		end
	end
	
	task.spawn(function()
		if not HRP or not HRP.Parent then return end
		rotateChildren()
	end)
	
	local tween = TS:Create(Handle, TweenInfo.new(0.65/speed, Enum.EasingStyle.Linear), {CFrame = targetPosition}):Play()
	task.wait(0.65/speed)
	if not HRP or not HRP.Parent then return end
	TS:Create(Handle, TweenInfo.new(0.65/speed, Enum.EasingStyle.Linear), {CFrame = handlePos.CFrame}):Play()
	task.wait(0.65/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.OffAllParticles(Handle.HandleM.Part)
	VFX_Helper.OffAllParticles(Handle.HandleM.Part2)
	
	Handle.HandleM.Trail.Enabled = false
	Handle.HandleM.Trail2.Enabled = false
	
	Handle.HandleM.Part.Transparency = 1
	Handle.HandleM.Part2.Transparency = 1

	handlePos.HandleM.Transparency = 0
	for _, part in handlePos:GetDescendants() do
		if part:IsA("BasePart") then
			part.Transparency = 0
		end
	end

	HRP.Parent.Attacking.Value = false
	connection:Disconnect()
end


module["Blades of Darkness"] = function(HRP, target)
	local Folder = VFX["Dart Mol"].Second
	local speed = GameSpeed.Value

	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	VFX_Helper.SoundPlay(HRP,Folder.Second)
	task.wait(0.5/speed)
	if not HRP or not HRP.Parent then return end

	HRP.Parent.Attacking.Value = true
	local starsemit = Folder:WaitForChild("Startemit"):Clone()
	starsemit.Position = HRP.Position + Vector3.new(0,-1.2,0)
	starsemit.Parent = HRP.Parent
	Debris:AddItem(starsemit,2/speed)
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing' .. tostring(math.random(1,2)))
	local enemyCFrame = CFrame.new(enemypos) * CFrame.Angles(HRP.CFrame:ToEulerAnglesXYZ())
	TS:Create(HRP, TweenInfo.new(0.1/speed, Enum.EasingStyle.Linear), {CFrame = enemyCFrame + enemyCFrame.LookVector}):Play()
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.EmitAllParticles(starsemit)
	local slash = Folder:WaitForChild("Slash"):Clone()
	slash.Position = enemypos 
	slash.Parent = vfxFolder
	Debris:AddItem(slash,4/speed)
	VFX_Helper.OnAllParticles(slash)
	
	local connection = HRP.Parent.Destroying:Once(function()
		slash:Destroy()
	end)
	if not HRP or not HRP.Parent then return end
	
	for i = 1, 10 do
		if not HRP or not HRP.Parent then return end
		local randomOffset = Vector3.new(math.random(-5, 5), 0, math.random(-5, 5))
		local randomPos = enemypos + randomOffset
		HRP.CFrame = CFrame.new(randomPos)
		task.wait(1.55 / 10/speed) 
	end
	HRP.CFrame = CFrame.new(enemypos)
	task.wait(0.15/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.OffAllParticles(slash)
	task.wait(0.6/speed)
	if not HRP or not HRP.Parent then return end

	local ganblaster = Folder:WaitForChild("Endlemit"):Clone()
	ganblaster.Position = HRP.Position + Vector3.new(0,-0.95,0)
	ganblaster.Parent = vfxFolder
	Debris:AddItem(ganblaster,2/speed)
	VFX_Helper.EmitAllParticles(ganblaster)

	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame
	local teleposr = Folder:WaitForChild("Teleportbls"):Clone()
	teleposr.CFrame = HRP.CFrame
	teleposr.Parent = vfxFolder	
	Debris:AddItem(teleposr,1/speed)
	VFX_Helper.EmitAllParticles(teleposr)
	HRP.Parent.Attacking.Value = false
	connection:Disconnect()

end

module["Ship Crash"] = function(HRP, target)
	local Folder = VFX["Dart Mol"].Thrid
	local speed = GameSpeed.Value

	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)
	VFX_Helper.SoundPlay(HRP,Folder.Third)
	task.wait(0.4/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true

	local shipStartPos = HRP.Position - HRP.CFrame.LookVector * 20 + Vector3.new(0, 90, 0)
	local shipEndPos = enemypos + Vector3.new(0, -10, 0)
	local shipStartCFrame = CFrame.new(shipStartPos, shipEndPos) 
	local shipEndCFrame = CFrame.new(shipEndPos, shipEndPos + (shipEndPos - shipStartPos).unit * 20) 

	local Ship = Folder:WaitForChild("Look"):Clone()
	Ship.CFrame = shipStartCFrame 
	Ship.Parent = vfxFolder 
	Debris:AddItem(Ship, 2/speed)
	local connection = HRP.Parent.Destroying:Once(function()
		Ship:Destroy()
	end)
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing' .. tostring(math.random(1,2)))
	TS:Create(Ship, TweenInfo.new(1/speed, Enum.EasingStyle.Linear), {CFrame = shipEndCFrame}):Play()
	task.wait(0.85/speed)
	UnitSoundEffectLib.playSound(HRP.Parent, 'Explosion')
	if not HRP or not HRP.Parent then return end

	local explosion = Folder:WaitForChild("Explosion"):Clone()
	explosion.Position = enemypos + Vector3.new(0,0.35,0)
	explosion.Parent = vfxFolder
	Debris:AddItem(explosion,4/speed)	
	VFX_Helper.EmitAllParticles(explosion)
	task.wait(0.15/speed)
	if not HRP or not HRP.Parent then return end

	HRP.Parent.Attacking.Value = false
	connection:Disconnect()

end


return module
