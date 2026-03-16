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
local RocksModule = require(rs.Modules.RocksModule)

module["Ki Mundi Attack"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX.LEGA["Ki Mundi"].First
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X,HRP.Position.Y,target.HumanoidRootPart.Position.Z)
	task.wait(0.1/speed)
	if not HRP or not HRP.Parent then return end
	local handleR = HRP.Parent["Right Arm"].Handle.Trail
	handleR.Enabled = true

	task.wait(0.75/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	
	local Emit = Folder:WaitForChild("Slashes"):Clone()
	Emit.CFrame = HRP.CFrame
	Emit.Parent = HRP
	Debris:AddItem(Emit,4/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP
	weld.Part1 = Emit
	weld.Parent = Emit

	local connection = HRP.Parent.Destroying:Once(function()
		Emit:Destroy()
	end)
	
	local targetCFrame = HRP.CFrame * CFrame.new(0, 0, -(Range - 2))
	TS:Create(HRP, TweenInfo.new(0.15/speed, Enum.EasingStyle.Linear), {CFrame = targetCFrame}):Play()
	local trail = Folder:WaitForChild("emiterrrr"):Clone()
	trail.CFrame = HRP.CFrame
	trail.Parent = HRP
	Debris:AddItem(trail,1/speed)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = HRP
	weld.Part1 = trail
	weld.Parent = trail
	VFX_Helper.OnAllParticles(trail)
	task.wait(0.09/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.EmitAllParticles(Emit)
	UnitSoundEffectLib.playSound(HRP.Parent, 'SaberSwing' .. tostring(math.random(1,2)))
	task.wait(0.05/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.OffAllParticles(trail)

	task.wait(1/speed)
	if not HRP or not HRP.Parent then return end
	local teleposr = Folder:WaitForChild("teleport"):Clone()
	teleposr.CFrame = HRP.CFrame + Vector3.new(0, -0.5, 0)
	teleposr.Parent = vfxFolder	
	Debris:AddItem(teleposr, 1/speed)
	VFX_Helper.EmitAllParticles(teleposr)
	HRP.CFrame = HRP.Parent:WaitForChild("TowerBasePart").CFrame
	local teleposttt = Folder:WaitForChild("teleport"):Clone()
	teleposttt.CFrame = HRP.CFrame + Vector3.new(0, -0.5, 0)
	teleposttt.Parent = vfxFolder	
	Debris:AddItem(teleposttt, 1/speed)
	VFX_Helper.EmitAllParticles(teleposttt)
	handleR.Enabled = false
	HRP.Parent.Attacking.Value = false
	connection:Disconnect()
end


return module
