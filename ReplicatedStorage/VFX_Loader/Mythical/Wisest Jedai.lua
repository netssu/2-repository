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
local RocksModule = require(rs.Modules.RocksModule)


module["Wisest Jedai first attack"] = function(HRP, target)
	local Folder = VFX.Wisest_Jedi.First
	local speed = GameSpeed.Value
	VFX_Helper.SoundPlay(HRP,Folder.First)
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	local Teleport = Folder:WaitForChild("Startemit"):Clone()
	Teleport.Position = HRP.Parent:WaitForChild("TowerBasePart").Position + Vector3.new(0,-0.5,0)
	Teleport.Parent = HRP.Parent
	Debris:AddItem(Teleport,2/speed)
	
	local trail = Folder:WaitForChild("Trail"):Clone()
	trail.CFrame = HRP.Parent["Right Arm"].O.CFrame * CFrame.Angles(0,math.rad(90),0)
	trail.Parent = vfxFolder
	Debris:AddItem(trail,1/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP.Parent["Right Arm"].O
	weld.Part1 = trail
	weld.Parent = trail
	task.wait(0.08/speed)
	HRP.Parent.Attacking.Value = true

	if not HRP or not HRP.Parent then return end
	local enemyCFrame = CFrame.new(enemypos) * CFrame.Angles(HRP.CFrame:ToEulerAnglesXYZ())
	TS:Create(HRP, TweenInfo.new(0.05/speed, Enum.EasingStyle.Linear), {CFrame = enemyCFrame + enemyCFrame.LookVector * -0.5}):Play()
	VFX_Helper.EmitAllParticles(Teleport)
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing' .. tostring(math.random(1,2)))
	task.wait(0.05/speed)
	local Hit = Folder:WaitForChild("Emit"):Clone()
	Hit.Position = enemypos + Vector3.new(0,-1,0)
	Hit.Parent = vfxFolder
	Debris:AddItem(Hit,3/speed)
	
	task.spawn(function()
		task.wait(0.05/speed)
		VFX_Helper.EmitAllParticles(Hit)
	end)
	if not HRP or not HRP.Parent then return end
	task.wait(0.6/speed)
	TS:Create(Hit.PointLight, TweenInfo.new(0.7/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Brightness = 0}):Play()
	if not HRP or not HRP.Parent then return end
	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame
	HRP.Parent.Attacking.Value = false
end


module["Stone Throw"] = function(HRP, target)
	local Folder = VFX.Wisest_Jedi.Second
	local speed = GameSpeed.Value

	local startCFrame = HRP.CFrame
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)
	VFX_Helper.SoundPlay(HRP,Folder.Seconddd)
	task.wait(0.12/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	local rockemit = Folder:WaitForChild("Rockemit"):Clone()
	rockemit.CFrame = startCFrame * CFrame.new(0, -0.7, -2)  * CFrame.Angles(math.rad(90),0,0)
	rockemit.Parent = vfxFolder
	Debris:AddItem(rockemit, 2/speed)
	UnitSoundEffectLib.playSound(HRP.Parent, 'Force1')
	local rock = Folder:WaitForChild("Rock"):Clone()
	rock.CFrame = startCFrame * CFrame.new(0, -5, -2) 
	rock.Parent = vfxFolder
	Debris:AddItem(rock, 1.5/speed)
	local connection = HRP.Parent.Destroying:Once(function()
		rock:Destroy()
	end)
	local rockUpCFrame = rock.CFrame * CFrame.new(0, 10, 0)
	local tweenUp = TS:Create(rock, TweenInfo.new(1/speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = rockUpCFrame})
	VFX_Helper.EmitAllParticles(rockemit)
	tweenUp:Play()
	task.wait(1.2/speed)
	local enemyCFrame = CFrame.new(enemypos) * CFrame.Angles(HRP.CFrame:ToEulerAnglesXYZ())
	local tweenToEnemy = TS:Create(rock, TweenInfo.new(0.18/speed, Enum.EasingStyle.Linear), {CFrame = enemyCFrame + Vector3.new(0,-1,0)})
	tweenToEnemy:Play()
	local groundemit =Folder:WaitForChild("GroundVfx"):Clone()
	groundemit.CFrame = enemyCFrame + Vector3.new(0,-1,0)
	groundemit.Parent = vfxFolder
	Debris:AddItem(groundemit,3/speed)
	UnitSoundEffectLib.playSound(HRP.Parent, 'Explosion')
	task.wait(0.18/speed)
	VFX_Helper.EmitAllParticles(groundemit)
	connection:Disconnect()

end

module["Force Palm"] = function(HRP, target)
	local Folder = VFX.Wisest_Jedi.Thrid
	local speed = GameSpeed.Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	local trail = Folder:WaitForChild("Trail"):Clone()
	trail.CFrame = HRP.Parent["Right Arm"].O.CFrame * CFrame.Angles(0,math.rad(90),0)
	trail.Parent = vfxFolder
	Debris:AddItem(trail,1.4/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP.Parent["Right Arm"].O
	weld.Part1 = trail
	weld.Parent = trail
	UnitSoundEffectLib.playSound(HRP.Parent, 'Force1')
	task.wait(1/speed)
	if not HRP or not HRP.Parent then return end

	HRP.Parent.Attacking.Value = true
	local HRPCF = HRP.CFrame
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local targetPosition = (HRPCF * CFrame.new(0, 0, -Range)).Position

	local Fire = Folder:WaitForChild("YodaEmit"):Clone()
	Fire.CFrame = HRP.CFrame
	Fire.Position = HRP.Parent["Left Arm"].Position 
	Fire.Parent = HRP
	Debris:AddItem(Fire,4/speed)
	VFX_Helper.EmitAllParticles(Fire)
	RocksModule.Trail(HRP.CFrame,HRP.CFrame.LookVector,Range - 2.5,3,Vector3.new(0.5,0.5,0.5),0.02,0.05,0.4,true,6,3)
	UnitSoundEffectLib.playSound(HRP.Parent, 'Explosion')
	task.wait(1/speed)
	HRP.Parent.Attacking.Value = false
end

return module
