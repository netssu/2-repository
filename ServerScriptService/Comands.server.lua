local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("[GIVE/EQUIP] Script iniciado")

local ADMIN_USERS = {
	["kaosgamesteam1"] = true,
	["ckaosgames2"] = true
}

local MAX_SELECTED_TOWERS = 4 -- ajuste se no seu sistema real forem 6

local function dbg(player, msg)
	if player then
		print("[GIVE/EQUIP][" .. player.Name .. "] " .. msg)
	else
		print("[GIVE/EQUIP] " .. msg)
	end
end

local function findTowerName(inputName)
	local towersFolder = ReplicatedStorage:FindFirstChild("Towers")
	if not towersFolder then
		print("[GIVE/EQUIP] ERRO: ReplicatedStorage.Towers não encontrado")
		return nil
	end

	print("[GIVE/EQUIP] Procurando tower:", inputName)

	for _, folder in ipairs(towersFolder:GetChildren()) do
		print("[GIVE/EQUIP] Pasta:", folder.Name, folder.ClassName)

		if folder:IsA("Folder") then
			for _, tower in ipairs(folder:GetChildren()) do
				print("[GIVE/EQUIP]  ->", tower.Name)
				if tower.Name:lower() == inputName:lower() then
					print("[GIVE/EQUIP] MATCH:", tower.Name)
					return tower.Name
				end
			end
		end
	end

	print("[GIVE/EQUIP] Nenhuma tower encontrada para:", inputName)
	return nil
end

local function dumpOwnedTowers(player)
	local owned = player:FindFirstChild("OwnedTowers")
	if not owned then
		dbg(player, "OwnedTowers não encontrado")
		return
	end

	dbg(player, "===== DUMP OWNEDTOWERS =====")
	for i, tower in ipairs(owned:GetChildren()) do
		dbg(player,
			string.format(
				"[%d] %s | Equipped=%s | Slot=%s | Level=%s | Trait=%s | Shiny=%s | UniqueID=%s",
				i,
				tower.Name,
				tostring(tower:GetAttribute("Equipped")),
				tostring(tower:GetAttribute("EquippedSlot")),
				tostring(tower:GetAttribute("Level")),
				tostring(tower:GetAttribute("Trait")),
				tostring(tower:GetAttribute("Shiny")),
				tostring(tower:GetAttribute("UniqueID"))
			)
		)
	end
	dbg(player, "===== FIM DUMP =====")
end

local function countEquipped(player)
	local owned = player:FindFirstChild("OwnedTowers")
	if not owned then
		return 0
	end

	local total = 0
	for _, tower in ipairs(owned:GetChildren()) do
		if tower:GetAttribute("Equipped") == true then
			total += 1
		end
	end
	return total
end

local function getFreeSlot(player)
	local used = {}

	local owned = player:FindFirstChild("OwnedTowers")
	if not owned then
		return nil
	end

	for _, tower in ipairs(owned:GetChildren()) do
		if tower:GetAttribute("Equipped") == true then
			local slot = tostring(tower:GetAttribute("EquippedSlot") or "")
			if slot ~= "" then
				used[slot] = true
			end
		end
	end

	for i = 1, MAX_SELECTED_TOWERS do
		if not used[tostring(i)] then
			return tostring(i)
		end
	end

	return nil
end

local function findOwnedTowerByName(player, towerName)
	local owned = player:FindFirstChild("OwnedTowers")
	if not owned then
		return nil
	end

	for _, tower in ipairs(owned:GetChildren()) do
		if tower.Name == towerName then
			return tower
		end
	end

	return nil
end

local function unequipTowerInSameSlot(player, slot, exceptTower)
	local owned = player:FindFirstChild("OwnedTowers")
	if not owned then
		return
	end

	for _, tower in ipairs(owned:GetChildren()) do
		if tower ~= exceptTower then
			local equipped = tower:GetAttribute("Equipped")
			local equippedSlot = tostring(tower:GetAttribute("EquippedSlot") or "")

			if equipped == true and equippedSlot == tostring(slot) then
				dbg(player, "Desequipando '" .. tower.Name .. "' do slot " .. tostring(slot))
				tower:SetAttribute("Equipped", false)
				tower:SetAttribute("EquippedSlot", "")
			end
		end
	end
end

local function giveAndEquipTower(player, towerName, forcedSlot)
	dbg(player, "giveAndEquipTower iniciado com towerName = " .. tostring(towerName) .. " | forcedSlot = " .. tostring(forcedSlot))

	if not player:FindFirstChild("DataLoaded") then
		dbg(player, "ERRO: DataLoaded ainda não existe")
		return false, "Data ainda não carregada"
	end

	if typeof(_G.createTower) ~= "function" then
		dbg(player, "ERRO: _G.createTower não está disponível")
		return false, "_G.createTower não disponível"
	end

	local owned = player:FindFirstChild("OwnedTowers")
	if not owned then
		dbg(player, "ERRO: OwnedTowers não encontrado")
		return false, "OwnedTowers não encontrado"
	end

	local realTowerName = findTowerName(towerName)
	if not realTowerName then
		dbg(player, "ERRO: tower não existe")
		return false, "Tower não existe"
	end

	dbg(player, "Nome resolvido: " .. realTowerName)

	local existing = findOwnedTowerByName(player, realTowerName)
	if existing then
		dbg(player, "Player já possui essa tower. Vai reutilizar a existente.")
	else
		dbg(player, "Player não possui essa tower. Criando via _G.createTower...")
		existing = _G.createTower(owned, realTowerName, "", {Shiny = false})
		dbg(player, "Tower criada: " .. tostring(existing))
	end

	if not existing then
		dbg(player, "ERRO: falha ao criar/obter tower")
		return false, "Falha ao criar tower"
	end

	local slotToUse = forcedSlot and tostring(forcedSlot) or getFreeSlot(player)
	dbg(player, "Slot escolhido = " .. tostring(slotToUse))

	if not slotToUse or slotToUse == "" then
		dbg(player, "ERRO: nenhum slot livre encontrado")
		return false, "Nenhum slot livre"
	end

	local equippedCount = countEquipped(player)
	dbg(player, "Equipped count atual = " .. tostring(equippedCount))

	unequipTowerInSameSlot(player, slotToUse, existing)

	dbg(player, "Setando Equipped = true")
	existing:SetAttribute("Equipped", true)

	dbg(player, "Setando EquippedSlot = " .. tostring(slotToUse))
	existing:SetAttribute("EquippedSlot", tostring(slotToUse))

	dbg(player, "Estado final da tower:")
	dbg(player,
		string.format(
			"%s | Equipped=%s | EquippedSlot=%s | Level=%s | Exp=%s | Trait=%s | Locked=%s | UniqueID=%s | Shiny=%s",
			existing.Name,
			tostring(existing:GetAttribute("Equipped")),
			tostring(existing:GetAttribute("EquippedSlot")),
			tostring(existing:GetAttribute("Level")),
			tostring(existing:GetAttribute("Exp")),
			tostring(existing:GetAttribute("Trait")),
			tostring(existing:GetAttribute("Locked")),
			tostring(existing:GetAttribute("UniqueID")),
			tostring(existing:GetAttribute("Shiny"))
		)
	)

	dumpOwnedTowers(player)

	return true, "Tower dada e equipada no slot " .. tostring(slotToUse)
end

Players.PlayerAdded:Connect(function(player)
	dbg(player, "PlayerAdded")

	player.Chatted:Connect(function(message)
		dbg(player, "Chat recebido: " .. tostring(message))

		if not ADMIN_USERS[player.Name] then
			dbg(player, "Sem permissão")
			return
		end

		local cmd, arg1, arg2 = message:match("^(%S+)%s+([^,]+)%s*,?%s*(.*)$")
		dbg(player, "Parser => cmd=" .. tostring(cmd) .. " arg1=" .. tostring(arg1) .. " arg2=" .. tostring(arg2))

		if not cmd then
			return
		end

		cmd = cmd:lower()

		if cmd == "!giveequip" then
			local success, response = giveAndEquipTower(player, arg1, arg2 ~= "" and arg2 or nil)
			dbg(player, "Resultado => " .. tostring(success) .. " | " .. tostring(response))

		elseif cmd == "!dumpunits" then
			dumpOwnedTowers(player)
		end
	end)
end)