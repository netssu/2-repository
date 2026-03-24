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
local DEFAULT_SPAWN_SPACING = 6

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

local function getWaypointFolder(map, team)
	if not info.Versus.Value then
		return map:FindFirstChild("Waypoints")
			or map:FindFirstChild("Waypoints" .. tostring(workspace.Info.PathNumber.Value))
	end

	if not team then
		return nil
	end

	return map:FindFirstChild(team .. "Waypoints")
end

local function getStartCFrame(map, team)
	if not info.Versus.Value then
		local startPart = map:FindFirstChild("Start")
		if startPart then
			return startPart.CFrame * CFrame.new(0, 3, 0)
		end

		local altStart = map:FindFirstChild("Start" .. tostring(workspace.Info.PathNumber.Value))
		if altStart then
			return altStart.CFrame
		end
	else
		local versusStart = team and map:FindFirstChild(team .. "Start")
		if versusStart then
			return versusStart.CFrame
		end
	end

	return nil
end

local function getPathDirection(startPosition, waypoints)
	if not waypoints then
		return nil
	end

	local firstWaypoint = waypoints:FindFirstChild("1") or waypoints:GetChildren()[1]
	if not firstWaypoint then
		return nil
	end

	local flatDirection = Vector3.new(
		firstWaypoint.Position.X - startPosition.X,
		0,
		firstWaypoint.Position.Z - startPosition.Z
	)

	if flatDirection.Magnitude <= 0.01 then
		return nil
	end

	return flatDirection.Unit
end

local function getSpawnSpacing(model)
	local extents = model:GetExtentsSize()
	return math.max(DEFAULT_SPAWN_SPACING, math.max(extents.X, extents.Z) * 0.8)
end

local function countQueuedMobs(startPosition, direction, spacing, team)
	local mobFolder = team and workspace:FindFirstChild(team .. "Mobs") or workspace:FindFirstChild("Mobs")
	if not mobFolder then
		return 0
	end

	local queuedCount = 0
	local queueDepth = spacing * 8

	for _, existingMob in mobFolder:GetChildren() do
		local rootPart = existingMob:FindFirstChild("HumanoidRootPart")
		local movingTo = existingMob:FindFirstChild("MovingTo")

		if rootPart and movingTo and movingTo.Value <= 2 then
			local delta = rootPart.Position - startPosition
			local distanceAlongLane = -delta:Dot(direction)
			local lateralDistance = (delta - direction * delta:Dot(direction)).Magnitude

			if distanceAlongLane >= -spacing and distanceAlongLane <= queueDepth and lateralDistance <= spacing * 1.5 then
				queuedCount += 1
			end
		end
	end

	return queuedCount
end

local function getSpawnCFrame(newMob, map, team)
	local startCFrame = getStartCFrame(map, team)
	if not startCFrame then
		return nil
	end

	local waypoints = getWaypointFolder(map, team)
	local pathDirection = getPathDirection(startCFrame.Position, waypoints)
	if not pathDirection then
		return startCFrame
	end

	local spacing = getSpawnSpacing(newMob)
	local queuedCount = countQueuedMobs(startCFrame.Position, pathDirection, spacing, team)
	local spawnPosition = startCFrame.Position - (pathDirection * spacing * queuedCount)

	return CFrame.lookAt(spawnPosition, spawnPosition + pathDirection)
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
				local spawnCFrame = getSpawnCFrame(newMob, map, team)
				if spawnCFrame then
					newMob:PivotTo(spawnCFrame)
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
