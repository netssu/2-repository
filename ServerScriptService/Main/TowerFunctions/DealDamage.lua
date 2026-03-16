local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TowerInfo = require(ReplicatedStorage.Modules.Helpers.TowerInfo)
local Auras = require(ReplicatedStorage.Modules.Auras)
local upgradesModule = require(ReplicatedStorage.Upgrades)

return function(humanoid:Humanoid,tower:Model,damage)	
	local damage = math.round(damage or TowerInfo.GetDamage(tower)) -- fixed rounding: ace
	local upgradeStats = upgradesModule[tower.Name]["Upgrades"][tower.Config.Upgrades.Value]
	
	local enemy = humanoid.Parent

	if upgradeStats and upgradeStats.EnemyDebuffs then
		local debuffs = upgradeStats.EnemyDebuffs
		local slowData = debuffs.Slowness
		if slowData and not enemy:GetAttribute("Slowness") then
			local humanoid = enemy:FindFirstChildOfClass("Humanoid")
			if humanoid then
				local originalSpeed = enemy:GetAttribute("OriginalSpeed") or humanoid.WalkSpeed
				enemy:SetAttribute("OriginalSpeed", originalSpeed)

				Auras.AddAura(enemy, "Slowness", slowData.Duration)
				enemy:SetAttribute("Slowness", true)

				local factor = slowData.SlowFactor or 0.8
				humanoid.WalkSpeed = originalSpeed * factor

				task.delay(slowData.Duration, function()
					if humanoid and humanoid.Parent then
						humanoid.WalkSpeed = originalSpeed
						enemy:SetAttribute("Slowness", false)
					end
				end)
			end
		end
	end

	local bossDamage = math.round(damage or TowerInfo.GetDamage(tower, enemy))
	if humanoid.Parent ~= nil then
		if humanoid.Parent.PrimaryPart ~= nil then
			local healthBeforeDamageDealt = humanoid.Health
			if humanoid.Parent:FindFirstChild("Type").Value == tower.Config:FindFirstChild("Type").Value or tower.Config:FindFirstChild("Type").Value == "Hybrid" then
				if tower.Config:FindFirstChild("FreezeDuration") then
					local FreezeDamage = 0
					if tower.Config:FindFirstChild("FreezeDamage") then
						FreezeDamage = tower.Config.FreezeDamage.Value
					end
					local FreezePriority = 1
					if tower.Config:FindFirstChild("FreezePriority") then
						FreezePriority = tower.Config.FreezePriority.Value
					end
					local NoIce = false
					if tower.Config:FindFirstChild("NoIce") then
						NoIce = tower.Config.NoIce.Value
					end
					humanoid.Parent.Freeze:Fire(tower.Config.FreezeDuration.Value,FreezeDamage,FreezePriority,NoIce)
				elseif tower.Config:FindFirstChild("BurningDuration") then
					local BurningDamage = 0
					if tower.Config:FindFirstChild("BurningDamage") then
						BurningDamage = tower.Config.BurningDamage.Value
					end
					local BurningPriority = 1
					if tower.Config:FindFirstChild("BurningPriority") then
						BurningPriority = tower.Config.BurningPriority.Value
					end
					humanoid.Parent.Burn:Fire(tower.Config.BurningDuration.Value,BurningDamage,BurningPriority)
				elseif tower.Config:FindFirstChild("PoisonDuration") then
					local PoisonDamage = 0
					if tower.Config:FindFirstChild("PoisonDamage") then
						PoisonDamage = tower.Config.PoisonDamage.Value
					end
					local PoisonPriority = 1
					if tower.Config:FindFirstChild("PoisonPriority") then
						PoisonPriority = tower.Config.PoisonPriority.Value
					end
					humanoid.Parent.Poison:Fire(tower.Config.PoisonDuration.Value,PoisonDamage,PoisonPriority)
				elseif tower.Config:FindFirstChild("BleedDuration") then
					local BleedPercent = 0
					if tower.Config:FindFirstChild("BleedPercent") then
						BleedPercent = tower.Config.BleedPercent.Value
					end
					local BleedPriority = 1
					if tower.Config:FindFirstChild("PoisonPriority") then
						BleedPriority = tower.Config.BleedPriority.Value
					end
					humanoid.Parent.Poison:Fire(tower.Config.PoisonDuration.Value,BleedPercent,BleedPriority)
				elseif tower.Config:FindFirstChild("CursedPercent") then
					humanoid.Parent.Curse:Fire(tower.Config.CursedPercent.Value)
				end
			end
			if humanoid.Parent:FindFirstChild("IsBoss") then
				if tower then
					tower.Config.TotalDamage.Value += bossDamage
				end
				humanoid:TakeDamage(bossDamage)
			else
				if tower then
					tower.Config.TotalDamage.Value += damage
				end
				
				humanoid:TakeDamage(damage)
			end
			
			if tower.Config:FindFirstChild("Owner") and damage > 0 then
				--print(tower.Config)
				local player = game.Players:FindFirstChild(tower.Config.Owner.Value) or game.Players:FindFirstChildOfClass("Player")
				if humanoid.Parent:FindFirstChild("IsBoss") then
					ReplicatedStorage.Events.VFX_Remote:FireClient(player,"DamageIndicator",bossDamage,humanoid.Parent.PrimaryPart or humanoid.Parent:FindFirstChild("HumanoidRootPart"))
				else
					if player:IsA('Player') then
						ReplicatedStorage.Events.VFX_Remote:FireClient(player,"DamageIndicator",damage,humanoid.Parent.PrimaryPart or humanoid.Parent:FindFirstChild("HumanoidRootPart"))
					end
				end
				
				
				local RawDamage = player:GetAttribute("RawDamage") or 0

				
				if player then
					if humanoid.Parent:FindFirstChild("IsBoss") then
						player.Damage.Value += bossDamage
						player:SetAttribute("RawDamage", RawDamage + bossDamage)
					else
						player.Damage.Value += damage
						local RawDamage = player:GetAttribute("RawDamage") or 0
						player:SetAttribute("RawDamage", RawDamage + damage)
					end
				end

				if player then

					if healthBeforeDamageDealt > 0 and humanoid.Health <= 0 then

						local playerTower;
						for _, towerObject in player.OwnedTowers:GetChildren() do
							if towerObject.Name == tower.Name and towerObject:GetAttribute("Equipped") then
								playerTower = towerObject
								break
							end
						end
						
						
						

						if playerTower then
							local Kills = player:WaitForChild("Kills")
							Kills.Value = Kills.Value + 1

							player.Stats.Kills.Value += 1
							player:FindFirstChild("MedalKills").Value += 1
							--warn(player:FindFirstChild("MedalKills").Value)


							if workspace.Info.SpecialEvent.Value then
								player.Stats.YounglingsEnded.Value += 1
							end
						end
					end
				end
			end
		end
	end
end