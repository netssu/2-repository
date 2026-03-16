local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules.UnitSoundEffectLib)

local module = {}
local rs = game:GetService("ReplicatedStorage")
local VFX = rs.VFX
local GameSpeed = workspace.Info.GameSpeed
local RunService = game:GetService("RunService")
local TS = game:GetService("TweenService")
local function getMag(pos1, pos2)
	return (pos1 - pos2).Magnitude
end

local function tween(obj, length, details)
	TS:Create(obj, TweenInfo.new(length, Enum.EasingStyle.Linear), details):Play()
end


module["Beatdown"] = function(HRP, target)
	local speed = GameSpeed.Value
	local Folder = VFX["Armored Commando"].Second
	local characterModel = HRP.Parent
	local Range = characterModel.Config:WaitForChild("Range").Value
	local enemyPos = target:GetPivot().Position

	local originalCFrame = characterModel:GetPivot()

	task.wait(0.78 / speed)
	if not HRP or not HRP.Parent then return end

	characterModel.Attacking.Value = true

	
	local SaberDash = Folder["run and punch"]:Clone()
	SaberDash.Parent = workspace.VFX
	SaberDash.CFrame = HRP.CFrame

	local distance = (HRP.Position - enemyPos).Magnitude
	local timeToTravel = distance / speed

	TS:Create(SaberDash, TweenInfo.new(timeToTravel, Enum.EasingStyle.Linear), {Position = enemyPos}):Play()

	task.delay(timeToTravel, function()
		if SaberDash and SaberDash.Parent then
			SaberDash:Destroy()
		end
	end)

	for _, v in pairs(SaberDash:GetChildren()) do
		if v:IsA("ParticleEmitter") or v:IsA("Beam") then
			v.Enabled = true
		elseif v:IsA("Attachment") then
			for _, child in pairs(v:GetChildren()) do
				if child:IsA("ParticleEmitter") or child:IsA("Beam") then
					child.Enabled = true
				end
			end
		end
	end


	local targetCFrame = HRP.CFrame * CFrame.new(0, 0, -Range)
	TS:Create(HRP, TweenInfo.new(0.15/speed, Enum.EasingStyle.Linear), {CFrame = targetCFrame}):Play()
	
	local cancel = false
	task.spawn(function()
		while task.wait(0.2) do
			if cancel then break end
			UnitSoundEffectLib.playSound(HRP.Parent, "Punch" .. tostring(math.random(1,3)))
		end
	end)

	task.wait(1 / speed)
	cancel = true
	if not HRP or not HRP.Parent then return end
	characterModel:PivotTo(originalCFrame)

	characterModel.Attacking.Value = false
end



module["Death Slam"] = function(HRP, target)
	local Model = HRP.Parent
	local speed = GameSpeed.Value
	local Folder = VFX["Armored Commando"].First
	local Range = Model.Config:WaitForChild("Range").Value
	local enemyHRP = target:FindFirstChild("HumanoidRootPart")
	if not enemyHRP then return end

	local originalCFrame = Model:FindFirstChild("TowerPart") and Model.TowerPart.CFrame or Model:GetPivot()
	local enemyPos = enemyHRP.Position

	task.wait(0.2 / speed)
	if not HRP or not HRP.Parent then return end
	Model.Attacking.Value = true

	local JumpVFX = Folder["death slam"]
	for _, attachment in JumpVFX:GetChildren() do
		if attachment:IsA("Attachment") then
			for _, emitter in attachment:GetChildren() do
				if emitter:IsA("ParticleEmitter") then
					emitter:Emit(emitter.Rate > 0 and emitter.Rate or 30)
				end
			end
		end
	end

	local jumpHeight = 25
	local jumpTime = 0.35 / speed
	local slamTime = 0.2 / speed

	UnitSoundEffectLib.playSound(HRP.Parent, "Blaster" .. tostring(math.random(1,3)))
	local jumpTween = TS:Create(Model.PrimaryPart, TweenInfo.new(jumpTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		CFrame = HRP.CFrame * CFrame.new(0, jumpHeight, 0)
	})
	jumpTween:Play()
	jumpTween.Completed:Wait()

	local slamCFrame = CFrame.new(enemyPos + Vector3.new(0, 4, 0)) -- Slam just above enemy
	local slamTween = TS:Create(Model.PrimaryPart, TweenInfo.new(slamTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		CFrame = slamCFrame
	})
	slamTween:Play()
	slamTween.Completed:Wait()

	
	task.wait(0.15 / speed)

	
	local returnTween = TS:Create(Model.PrimaryPart, TweenInfo.new(0.3 / speed, Enum.EasingStyle.Linear), {
		CFrame = originalCFrame
	})
	returnTween:Play()
	returnTween.Completed:Wait()

	Model.Attacking.Value = false
end



return module
