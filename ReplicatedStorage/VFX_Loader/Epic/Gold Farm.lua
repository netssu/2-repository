local module = {}
local rs = game:GetService("ReplicatedStorage")
local Effects = rs.VFX
local vfxFolder = workspace.VFX
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local VFX = rs.VFX
local VFX_Helper = require(rs.Modules.VFX_Helper)
local GameSpeed = workspace.Info.GameSpeed

module["C-3PO Farm Reward"] = function(HRP, target)
	local Folder = VFX.LEGA["C-3PO Farm"]
	local speed = GameSpeed.Value

	
	--VFX_Helper.SoundPlay(HRP,Folder.First)
	
	task.wait(0.7/speed)
	if not HRP or not HRP.Parent then return end
	
	local Emit = Folder:WaitForChild("GoldEmit"):Clone()
	Emit.Position = HRP.Position
	Emit.Parent = vfxFolder
	Debris:AddItem(Emit,3/speed)
	task.wait(0.05/speed)
	if not HRP or not HRP.Parent then return end
	VFX_Helper.EmitAllParticles(Emit)
	

end

return module
