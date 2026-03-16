local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local towerModule = require(script.Parent.Tower)
local QuestHandler = require(game.ReplicatedStorage.Configs.QuestConfig)
local XPHandler = require( ReplicatedStorage:WaitForChild('EpisodeConfig').XPHandler )
local ClanQuestProgressScheduler = require(ServerScriptService.ClanService.ClanQuestsLib.ClanQuestProgressScheduler)
local info = workspace.Info

local mob = {}

function incrementpercentage(n, t, p) 
	local r = n 
	for _ = 1, t do 
		r+=(r*p) 
	end 
	return r 
end

function mob.Move(newMob, map, team)
	local humanoid = newMob:WaitForChild("Humanoid")
	local waypoints
	
	
	if not info.Versus.Value then
		waypoints = map:FindFirstChild("Waypoints")
	else
		waypoints = map[team .. 'Waypoints']
	end
	

	if not waypoints then -- probs wont use
		waypoints = map:FindFirstChild("Waypoints"..tostring(game.Workspace.Info.PathNumber.Value))
	end

	for waypoint=newMob.MovingTo.Value, #waypoints:GetChildren()do
		newMob.MovingTo.Value = waypoint
		repeat 
			humanoid:MoveTo(waypoints[waypoint].Position)
		until humanoid.MoveToFinished:Wait()
	end

	newMob:Destroy()

	if not info.Versus.Value then
		map.Base.Humanoid:TakeDamage(math.min(humanoid.Health, map.Base.Humanoid.Health))
	else
		map[team .. 'Base'].Humanoid:TakeDamage(math.min(humanoid.Health, map[team .. 'Base'].Humanoid.Health))
	end
end

local function cloneScript(mobType, parent)
	if not mobType then return end

	if script:FindFirstChild(mobType) then
		local scriptToCopy = script[mobType]:Clone()
		scriptToCopy.Parent = parent
		scriptToCopy.Enabled = true
	end
end

function mob.Spawn(name, quantity, map, old, health, money, speed,isBoss,unitStats, isbossrush, team)
	local mobExists = ReplicatedStorage.Enemies:FindFirstChild(name) -- [map.name]
	local ogspeed = if workspace.Info.TestingMode.Value then 1 else unitStats.speed

	if mobExists then
		for i=1, quantity do

			local mvt = 1

			if old then
				if old:FindFirstChild("MovingTo") then mvt = old.MovingTo.Value end
			end

			local newMob = mobExists:Clone()

			if not newMob:FindFirstChild('Type') then -- omd wallahi this is gonna save everyone
				local val = Instance.new('StringValue', newMob)
				val.Name = 'Type'
				val.Value = 'Ground'
			end

			if team then
				newMob:SetAttribute('Team', team)
			end


			local mobType = newMob:GetAttribute("Type")
			task.spawn(cloneScript, mobType, newMob)

			newMob.Humanoid.MaxHealth = health or newMob.Humanoid.MaxHealth
			newMob.Humanoid.Health = newMob.Humanoid.MaxHealth
			newMob.Humanoid.WalkSpeed = speed or newMob.Humanoid.WalkSpeed

			if old then
				newMob.HumanoidRootPart.CFrame = old.HumanoidRootPart.CFrame
			else
				if not info.Versus.Value then
					if map:FindFirstChild("Start") then 
						newMob:PivotTo(map.Start.CFrame * CFrame.new(Vector3.new(0,3,0)))
						--newMob.HumanoidRootPart.CFrame = map.Start.CFrame

					else
						newMob:PivotTo(map["Start"..tostring(game.Workspace.Info.PathNumber.Value)].CFrame)
						--newMob.HumanoidRootPart.CFrame = 
					end
				else
					-- versus
					newMob:PivotTo(map[team .. 'Start'].CFrame)
				end

			end


			if team then
				newMob.Parent = workspace[team .. 'Mobs']
			else
				newMob.Parent = workspace.Mobs
			end

			newMob.HumanoidRootPart:SetNetworkOwner(nil)

			if not newMob:FindFirstChild("MovingTo") then
				local movingTo = Instance.new("IntValue")
				movingTo.Name = "MovingTo"
				movingTo.Value = mvt
				movingTo.Parent = newMob
			end


			local PathNumber = Instance.new("IntValue")
			PathNumber.Name = "PathNumber"
			PathNumber.Value = info.PathNumber.Value
			PathNumber.Parent = newMob

			local OriginalSpeed = Instance.new("NumberValue")
			OriginalSpeed.Name = "OriginalSpeed"
			OriginalSpeed.Value = ogspeed
			OriginalSpeed.Parent = newMob

			if isBoss or isbossrush then
				local isBossBool = Instance.new("BoolValue")
				isBossBool.Name = "IsBoss"
				isBossBool.Value = true
				isBossBool.Parent = newMob
			end

			for i, object in newMob:GetDescendants() do
				if object:IsA("BasePart") then
					PhysicsService:SetPartCollisionGroup(object, "Mob")
				end
			end

			if not mobExists:GetAttribute("OriginalHealth") then mobExists:SetAttribute("OriginalHealth", mobExists.Humanoid.MaxHealth) end

			local OriginalHealth = mobExists:GetAttribute("OriginalHealth") 
			local HealthMultiplier = script.Parent:GetAttribute("EnemyHealthMultiplier")
			local info = workspace.Info

			newMob.Humanoid.Died:Connect(function()
				if typeof(money) == "number" then
					for _, player in game.Players:GetPlayers() do
						local bypass = not info.Versus.Value

						if bypass or (player.Team and player.Team.Name == team) then

							player.Money.Value += money

							task.spawn(function()
								QuestHandler.UpdateProgressAll(player, "KillEnemies", 1)
								ClanQuestProgressScheduler.addToQueue(player, "Kills", 1)

								if isBoss or isbossrush then
									ClanQuestProgressScheduler.addToQueue(player, "Kills:Bosses", 1)
								end
							end)


							if isBoss then
								if not info.Infinity.Value and not info.Raid.Value and not isbossrush then
									QuestHandler.UpdateProgressAll(player, "KillStoryBosses", 1)
								end
							end
						end
					end
				end
				task.wait(0.2)
				newMob:Destroy()
			end)

			task.spawn(function()
				local function SelfDeleteOnEmptyBody()
					local countPart = 0
					for _, object : Part in newMob:GetChildren() do
						if object:IsA("BasePart") then
							countPart += 1
						end
					end
					if countPart == 0 and newMob:FindFirstChild("Humanoid") and newMob.Humanoid.Health > 0 then
						newMob:Destroy()
					end
				end

				newMob.ChildRemoved:Connect(function()
					SelfDeleteOnEmptyBody()
				end)
			end)

			coroutine.wrap(mob.Move)(newMob, map, team)

			--mob.Parent = workspace.Mobs

			return newMob
		end
	else
		warn("Requested mob does not exist:", name)
	end
end







return mob