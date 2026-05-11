------------------//VARIABLES
local CharacterSelectionController = {}

local SELECT_TEXT_COLOR = Color3.fromRGB(150, 255, 175)

local WORLD_ORDER = {
	"JJK",
	"Naruto",
	"Onepiece",
}

local WORLD_CONTENT = {
	JJK = {
		buttonText = "SELECT",
		buttonTextColor = SELECT_TEXT_COLOR,
		infoText = "World: Jujutsu\nCultivation:\nMortal IX\nPVP Battles Won: 0\nQuests Completed: 0\nWorld Souls: 0\nPlaytime: 0",
	},
	Naruto = {
		buttonText = "LOCKED",
		infoText = "World: Naruto\nCultivation:\nMortal I\nStatus: Locked\nFoundation\nBuy Slot: Later",
	},
	Onepiece = {
		buttonText = "LOCKED",
		infoText = "World: One Piece\nCultivation:\nMortal I\nStatus: Locked\nFoundation\nBuy Slot: Later",
	},
}

------------------//FUNCTIONS
local function find_gui(root, names)
	for _, name in names do
		local obj = root:FindFirstChild(name, true)
		if obj and obj:IsA("GuiObject") then
			return obj
		end
	end
	return nil
end

local function get_sort_x(gui)
	return gui.Position.X.Scale + (gui.Position.X.Offset / 10000)
end

local function reorder_cards(cards)
	local positionedCards = {}
	for _, card in cards do
		if card then
			table.insert(positionedCards, card)
		end
	end

	if #positionedCards < 3 then
		return
	end

	local parent = positionedCards[1].Parent
	for _, card in positionedCards do
		if card.Parent ~= parent then
			return
		end
	end

	table.sort(positionedCards, function(left, right)
		return get_sort_x(left) < get_sort_x(right)
	end)

	local layoutSlots = {}
	for index, card in positionedCards do
		layoutSlots[index] = {
			position = card.Position,
			size = card.Size,
		}
	end

	for index, worldId in WORLD_ORDER do
		local card = cards[worldId]
		if card then
			card.Position = layoutSlots[index].position
			card.Size = layoutSlots[index].size
			card.LayoutOrder = index
		end
	end
end

local function find_card(worldRoot)
	if not worldRoot then
		return nil
	end

	local directCard = worldRoot:FindFirstChild("card")
	if directCard and directCard:IsA("GuiObject") then
		return directCard
	end

	for _, child in worldRoot:GetChildren() do
		if child:IsA("GuiObject") then
			return child
		end
	end

	return worldRoot
end

local function set_locked(card, locked)
	if not card then
		return
	end

	card.Active = not locked
	if card:IsA("GuiButton") then
		card.AutoButtonColor = not locked
	end

	for _, child in card:GetDescendants() do
		if child:IsA("GuiButton") then
			child.Active = not locked
			child.AutoButtonColor = not locked
		end
	end
end

local function configure_card(worldRoot, worldId)
	if not worldRoot then
		return
	end

	local content = WORLD_CONTENT[worldId]
	local card = find_card(worldRoot)
	if not content or not card then
		return
	end

	for _, child in worldRoot:GetDescendants() do
		if child:IsA("GuiObject") then
			local isCardControl = child.Name:find("Button") ~= nil or child.Name:find("InfoLabel") ~= nil
			if isCardControl or child.Name == "ButtonText" then
				child.Visible = true
			end
		end

		if child:IsA("TextLabel") and child.Name:find("InfoLabel") ~= nil then
			child.Text = content.infoText
		elseif child:IsA("TextLabel") and child.Name == "ButtonText" then
			child.Text = content.buttonText
			if content.buttonTextColor then
				child.TextColor3 = content.buttonTextColor
			end
		elseif child:IsA("GuiButton") then
			if child:IsA("TextButton") then
				child.Text = content.buttonText
				if content.buttonTextColor then
					child.TextColor3 = content.buttonTextColor
				end
			end

			local buttonText = child:FindFirstChild("ButtonText", true)
			if buttonText and buttonText:IsA("TextLabel") then
				buttonText.Text = content.buttonText
				if content.buttonTextColor then
					buttonText.TextColor3 = content.buttonTextColor
				end
			end
		end
	end
end

local function find_select_buttons(worldRoot)
	local buttons = {}
	for _, child in worldRoot:GetDescendants() do
		if child:IsA("GuiButton") then
			table.insert(buttons, child)
		end
	end
	return buttons
end

local function create_fallback_select_button(worldRoot)
	local card = find_card(worldRoot) or worldRoot
	local button = Instance.new("TextButton")
	button.Name = "JJKSelectButton"
	button.AnchorPoint = Vector2.new(0.5, 1)
	button.Position = UDim2.fromScale(0.5, 0.94)
	button.Size = UDim2.fromScale(0.62, 0.12)
	button.BackgroundColor3 = Color3.fromRGB(14, 17, 24)
	button.BackgroundTransparency = 0.18
	button.BorderSizePixel = 0
	button.Font = Enum.Font.Garamond
	button.Text = "SELECT"
	button.TextColor3 = SELECT_TEXT_COLOR
	button.TextScaled = true
	button.TextWrapped = true
	button.AutoButtonColor = true
	button.ZIndex = card.ZIndex + 5
	button.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(210, 198, 176)
	stroke.Thickness = 1
	stroke.Transparency = 0.15
	stroke.Parent = button

	return button
end

local function connect_card_click(card, callback)
	local buttons = find_select_buttons(card)
	if #buttons == 0 then
		table.insert(buttons, create_fallback_select_button(card))
	end

	local clicking = false
	local function trigger()
		if clicking then
			return
		end
		clicking = true
		callback()
		task.delay(0.2, function()
			clicking = false
		end)
	end

	for _, button in buttons do
		button.Activated:Connect(trigger)
	end

	card.Active = true
	card.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			trigger()
		end
	end)
end

function CharacterSelectionController.setup(hud, onJjkSelected)
	local screen = hud:FindFirstChild("CharacterSelection")
	if not screen then
		warn("CharacterSelection screen not found.")
		return
	end

	local cards = {
		JJK = find_gui(screen, {"JJK", "Jujutsu", "JujutsuKaisen"}),
		Naruto = find_gui(screen, {"Naruto"}),
		Onepiece = find_gui(screen, {"Onepiece", "OnePiece"}),
	}

	reorder_cards(cards)
	configure_card(cards.JJK, "JJK")
	configure_card(cards.Naruto, "Naruto")
	configure_card(cards.Onepiece, "Onepiece")
	set_locked(cards.Naruto, true)
	set_locked(cards.Onepiece, true)

	if cards.JJK then
		set_locked(cards.JJK, false)
		connect_card_click(cards.JJK, onJjkSelected)
	else
		warn("JJK selection card not found.")
	end
end

------------------//INIT
return CharacterSelectionController
