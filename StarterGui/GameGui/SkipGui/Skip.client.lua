-- SERVICES
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

-- CONSTANTS

-- VARIABLES
local player = Players.LocalPlayer
local playerSettings = nil
local UIHandler = require(ReplicatedStorage.Modules.Client.UIHandler)

-- FUNCTIONS

-- INIT
repeat task.wait() until player:FindFirstChild('DataLoaded')
playerSettings = player:WaitForChild("Settings")

ReplicatedStorage.Events.SkipGui.OnClientEvent:Connect(function(visible, SecondArgument : {})

	if SecondArgument then
		if SecondArgument.Yes then
			script.Parent.PlayersVoteText.Text = `{SecondArgument.Yes}/{math.ceil(#Players:GetPlayers()) }` 
			UIHandler.PlaySound("Skip")
			return
		end

		if SecondArgument.Required then
			script.Parent.PlayersVoteText.Text = `{0}/{math.ceil(#Players:GetPlayers())}` 
		end
	end

	if visible and playerSettings.AutoSkip.Value then
		return ReplicatedStorage.Functions.VoteForSkip:InvokeServer()
	end

	script.Parent.Visible = visible

	if visible == true then
		TweenService:Create(script.Parent, TweenInfo.new(0.5, Enum.EasingStyle.Back), {Position = UDim2.new(0.786, 0, 0.34, 0)}):Play()

		if UserInputService.GamepadEnabled then
			local btnToSelect = script.Parent:IsA("GuiButton") and script.Parent or script.Parent:FindFirstChildWhichIsA("GuiButton")
			if btnToSelect then
				GuiService.SelectedObject = btnToSelect
			end
		end
	end

	if visible == true and Workspace.Info.SkipValue.Value == true then
		while (#Workspace.Mobs:GetChildren() > Workspace.Info.MobLimit.Value) and not playerSettings.AutoSkip.Value do
			task.wait(0.1)
		end

		local result = ReplicatedStorage.Functions.VoteForSkip:InvokeServer()

		if typeof(result) == "string" then
		else
			script.Parent.Visible = false
		end
	else
		script.Parent.Visible = visible
	end
end)