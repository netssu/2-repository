local TweenService = game:GetService("TweenService")
local player = game.Players.LocalPlayer

script.Parent.MouseButton1Click:Connect(function()
	local result = game.ReplicatedStorage.Functions.VoteForSkip:InvokeServer()
	if typeof(result) == "string" then
		if result == "Cannot skip on the final wave!" then
			script.Parent.Visible = false
		end
		_G.Message(result,Color3.new(0.831373, 0, 0))
	else
		TweenService:Create(script.Parent.Parent,TweenInfo.new(0.5,Enum.EasingStyle.Back),{Position = UDim2.new(1.2, 0,0.34, 0)}):Play()
		task.wait(0.25)
		script.Parent.Parent.Visible = false
	end
end)
