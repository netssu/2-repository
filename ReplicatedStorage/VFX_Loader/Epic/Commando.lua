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

module["Commando Attack"] = function(HRP, target)
	local Folder = VFX.Epic.Commando
	local speed = GameSpeed.Value
	local enemypos = Vector3.new(target.HumanoidRootPart.Position.X, HRP.Position.Y, target.HumanoidRootPart.Position.Z)

	task.wait(0.98/speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = true
	VFX_Helper.SoundPlay(HRP,Folder.Sound)

	local HRPCF = HRP.CFrame
	local Range = HRP.Parent.Config:WaitForChild("Range").Value
	local direction = HRPCF.LookVector

	local connection = nil

	for i = 1, 12 do
		if not HRP or not HRP.Parent then return end

		local startPos = HRP.Parent["Right Arm"].Gunn.Pos.Position
		local scatterOffset = Vector3.new(math.random(-3, 3), math.random(-1, 1), math.random(-3, 3))
		local endPos = startPos + (direction * Range) + scatterOffset

		local Ball = Folder:WaitForChild("Part"):Clone()
		Ball.CFrame = HRP.Parent["Right Arm"].Gunn.Pos.CFrame
		Ball.Position = startPos
		Ball.Parent = vfxFolder
		Ball.Transparency = 0
		Debris:AddItem(Ball, 2 / speed)
		
		UnitSoundEffectLib.playSound(HRP.Parent, 'Blaster2')

		connection = HRP.Parent.Destroying:Once(function()
			Ball:Destroy()
		end)

		--VFX_Helper.EmitAllParticles(HRP.Parent["Right Arm"].Gunn.Pos)

		task.delay(0.02 / speed, function()
			if Ball and Ball.Parent then
				local tween = TS:Create(Ball, TweenInfo.new(0.1 / speed, Enum.EasingStyle.Linear), {Position = endPos})
				tween:Play()
				tween.Completed:Connect(function()
					if Ball and Ball.Parent then
						Ball.Transparency = 1
						local Endlemit = Folder:WaitForChild("EndlEmit"):Clone()
						Endlemit.Position = endPos
						Endlemit.Parent = vfxFolder
						Debris:AddItem(Endlemit, 2 / speed)
						VFX_Helper.EmitAllParticles(Endlemit)
						--VFX_Helper.OffAllParticles(Ball)

					end
				end)
			end
		end)
	end

	task.wait(1.5 / speed)
	if not HRP or not HRP.Parent then return end
	HRP.Parent.Attacking.Value = false
	connection:Disconnect()

end

return module
