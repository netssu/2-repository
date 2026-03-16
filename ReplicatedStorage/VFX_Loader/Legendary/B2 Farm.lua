local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed

module["Money Reward"] = function(HRP, target)
	local Folder = VFX["B2 Farm"].First
	local speed = GameSpeed.Value

	if not HRP or not HRP.Parent then return end
	
	VFX_Helper.SoundPlay(HRP,Folder.First)
	
	local Emit = Folder:WaitForChild("Part"):Clone()
	Emit.Position = HRP.Position + Vector3.new(0,-1,0)
	Emit.Parent = vfxFolder
	Debris:AddItem(Emit,2)
	task.wait(0.1/speed)
	VFX_Helper.EmitAllParticles(Emit)
	task.wait(0.15/speed)
	if not HRP or not HRP.Parent then return end
	local emitUp = Folder:WaitForChild("GoldEmit"):Clone()
	emitUp.Position = HRP.Position
	emitUp.Parent = vfxFolder
	Debris:AddItem(emitUp,3/speed)
	VFX_Helper.EmitAllParticles(emitUp)

end

return module
