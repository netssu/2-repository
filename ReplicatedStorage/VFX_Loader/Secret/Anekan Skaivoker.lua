-- SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

-- CONSTANTS

-- VARIABLES
local VFX = ReplicatedStorage:WaitForChild("VFX")
local vfxFolder = workspace:FindFirstChild("VFX") or workspace
local VFX_Helper = require(ReplicatedStorage.Modules:WaitForChild("VFX_Helper"))
local UnitSoundEffectLib = require(ReplicatedStorage.VFXModules:WaitForChild("UnitSoundEffectLib"))
local GameSpeed = workspace.Info:WaitForChild("GameSpeed")

-- FUNCTIONS
local module = {}

-- Função isolada para ancoragem limpa e profissional
local function setupAndAnchorVFX(vfxInstance)
	if not vfxInstance then return end

	local parts = vfxInstance:IsA("BasePart") and {vfxInstance} or {}
	for _, desc in vfxInstance:GetDescendants() do
		if desc:IsA("BasePart") then
			table.insert(parts, desc)
		end
	end

	for _, part in ipairs(parts) do
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
	end
end

local function playSimpleSkill(HRP, target, rootFolderName, folderName, visualName, getCFrame, lifeTime, attackTime, preDelay, soundName)
	if not HRP or not HRP.Parent then return end
	if not target or not target:FindFirstChild("HumanoidRootPart") then return end

	local unit = HRP.Parent
	local speed = GameSpeed.Value

	-- 1. Foca no inimigo imediatamente
	local enemyPos = VFX_Helper.getEnemyPos(target, HRP.Position)
	local lookAtPos = Vector3.new(enemyPos.X, HRP.Position.Y, enemyPos.Z)
	HRP.CFrame = CFrame.lookAt(HRP.Position, lookAtPos)

	if unit:FindFirstChild("Attacking") then
		unit.Attacking.Value = true
	end

	-- 2. Aguarda o tempo da animação (sincronização)
	if preDelay and preDelay > 0 then
		task.wait(preDelay / speed)
	end

	-- Verifica se o personagem ainda existe após o delay
	if not HRP or not HRP.Parent then return end

	-- 3. Toca o efeito sonoro do SoundEffectLib (se fornecido)
	if soundName then
		UnitSoundEffectLib.playSound(unit, soundName)
	end

	-- Busca a pasta e os assets de VFX
	local folder = VFX:WaitForChild(rootFolderName):FindFirstChild(folderName)
	if not folder then return end

	-- Toca som nativo da pasta (se existir)
	local folderSound = folder:FindFirstChildWhichIsA("Sound")
	if folderSound then
		VFX_Helper.SoundPlay(HRP, folderSound)
	end

	local template = folder:FindFirstChild(visualName)
	if template then
		-- Spawna e ancora o VFX
		local spawnCFrame = getCFrame(HRP, target)
		local vfx = VFX_Helper.CloneObject(template, spawnCFrame, vfxFolder, (lifeTime or 3) / speed, true)
		setupAndAnchorVFX(vfx)
	end

	-- 4. Finaliza o estado de ataque
	task.delay((attackTime or 0.4) / speed, function()
		if unit and unit.Parent and unit:FindFirstChild("Attacking") then
			unit.Attacking.Value = false
		end
	end)
end

module["Dart Wader attack"] = function(HRP, target)
	-- Adicionado delay de 0.2s e o som 'SaberSwing1'
	playSimpleSkill(HRP, target, "Dart Wader", "First", "First", function(HRP)
		local range = HRP.Parent.Config.Range.Value
		return HRP.CFrame * CFrame.new(0, 0, -math.clamp(range * 0.5, 4, 12))
	end, 3, 0.45, 0.2, "SaberSwing1")
end

module["Anekan Skaivoker"] = function(HRP, target)
	-- Adicionado delay de 0.2s e o som 'SaberSwing1'
	playSimpleSkill(HRP, target, "Anekan Skaivoker", "First", "First", function(HRP)
		local range = HRP.Parent.Config.Range.Value
		return HRP.CFrame * CFrame.new(0, 0, -math.clamp(range * 0.5, 4, 12))
	end, 3, 0.45, 0.2, "SaberSwing1")
end

module["Stone Rain attack"] = function(HRP, target)
	-- Adicionado delay de 0.3s e o som 'Force1'
	playSimpleSkill(HRP, target, "Dart Wader", "Second", "Second", function(HRP, target)
		local pos = VFX_Helper.getEnemyPos(target, HRP.Position)
		return CFrame.new(pos)
	end, 3, 0.6, 0.3, "Force1")
end

module["Stone Rain"] = function(HRP, target)
	-- Adicionado delay de 0.3s e o som 'Force1'
	playSimpleSkill(HRP, target, "Anekan Skaivoker", "Second", "Second", function(HRP, target)
		local pos = VFX_Helper.getEnemyPos(target, HRP.Position)
		return CFrame.new(pos)
	end, 3, 0.6, 0.3, "Force1")
end

module["Death Star"] = function(HRP, target)
	-- Adicionado delay de 0.4s e o som 'Explosion'
	playSimpleSkill(HRP, target, "Anekan Skaivoker", "Third", "Third", function(HRP, target)
		local pos = VFX_Helper.getEnemyPos(target, HRP.Position)
		return CFrame.lookAt(pos + Vector3.new(0, 10, 0), pos)
	end, 4, 1, 0.4, "Explosion")
end

-- INIT
return module