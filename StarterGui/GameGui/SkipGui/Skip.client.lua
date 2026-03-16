local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = game.Players.LocalPlayer
repeat task.wait() until player:FindFirstChild('DataLoaded')

local playerSettings = player:WaitForChild("Settings")
local UIHandler = require(game.ReplicatedStorage.Modules.Client.UIHandler)

game.ReplicatedStorage.Events.SkipGui.OnClientEvent:Connect(function(visible, SecondArgument : {})

	if SecondArgument then
		if SecondArgument.Yes then
			--script.Parent.PlayersVoteText.Text = `{SecondArgument.Yes}/{math.ceil(#Players:GetPlayers() * 0.5) }` 
			script.Parent.PlayersVoteText.Text = `{SecondArgument.Yes}/{math.ceil(#Players:GetPlayers()) }` 
			UIHandler.PlaySound("Skip")
			return
		end

		if SecondArgument.Required then
			--// 0.5 for reference incase they want to revert back.
			script.Parent.PlayersVoteText.Text = `{0}/{math.ceil(#Players:GetPlayers())}` 
		end
	end
	
	if visible and playerSettings.AutoSkip.Value then
		return game.ReplicatedStorage.Functions.VoteForSkip:InvokeServer()
	end
	script.Parent.Visible = visible
	if visible == true then
		TweenService:Create(script.Parent,TweenInfo.new(0.5,Enum.EasingStyle.Back),{Position = UDim2.new(0.786, 0,0.34, 0)}):Play()
	end
	
	if visible == true and workspace.Info.SkipValue.Value == true then
		while (#game.Workspace.Mobs:GetChildren() > game.Workspace.Info.MobLimit.Value) and not playerSettings.AutoSkip.Value do
			task.wait(0.1)
		end
		local result = game.ReplicatedStorage.Functions.VoteForSkip:InvokeServer()
		if typeof(result) == "string" then
			
		else
			script.Parent.Visible = false
		end
	else
		script.Parent.Visible = visible
	end
end)