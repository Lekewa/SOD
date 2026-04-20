-- СЕРВИСЫ
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

-- ПЕРЕМЕННЫЕ
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local playerGui = player:WaitForChild("PlayerGui")
local noclipEnabled = false
local infJumpEnabled = false
local platformsEnabled = false
local fullbrightEnabled = false
local isMinimized = false

-- СОХРАНЕНИЕ СТАНДАРТНОГО ОСВЕЩЕНИЯ
local origBrightness = Lighting.Brightness
local origClockTime = Lighting.ClockTime
local origAmbient = Lighting.Ambient

-- КОРНЕВОЙ ИНТЕРФЕЙС
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SOD_Menu"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 300, 0, 400)
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 15)
local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Color = Color3.fromRGB(0, 255, 0); mainStroke.Thickness = 6

-- ВЕРХНЯЯ ПАНЕЛЬ
local logo = Instance.new("TextLabel", mainFrame)
logo.Text = "SOD"; logo.Size = UDim2.new(0, 180, 0, 30); logo.Position = UDim2.new(0, 15, 0, 5)
logo.BackgroundTransparency = 1; logo.TextColor3 = Color3.fromRGB(255, 255, 255)
logo.Font = Enum.Font.GothamBold; logo.TextSize = 22; logo.TextXAlignment = Enum.TextXAlignment.Left

local controlHolder = Instance.new("Frame", mainFrame)
controlHolder.Size = UDim2.new(0, 100, 0, 30); controlHolder.Position = UDim2.new(1, -105, 0, 5); controlHolder.BackgroundTransparency = 1
local controlLayout = Instance.new("UIListLayout", controlHolder)
controlLayout.FillDirection = Enum.FillDirection.Horizontal; controlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right; controlLayout.Padding = UDim.new(0, 10)

local function createTopBtn(txt, color)
	local b = Instance.new("TextButton", controlHolder)
	b.Size = UDim2.new(0, 20, 0, 30); b.BackgroundTransparency = 1; b.Text = txt; b.TextColor3 = color; b.Font = Enum.Font.GothamBold; b.TextSize = 20
	return b
end

local resetBtn = createTopBtn("R", Color3.fromRGB(255, 200, 0))
local hideBtn = createTopBtn("-", Color3.fromRGB(255, 255, 255))
local closeBtn = createTopBtn("X", Color3.fromRGB(255, 50, 50))

-- ВКЛАДКИ
local tabButtonsFrame = Instance.new("Frame", mainFrame)
tabButtonsFrame.Size = UDim2.new(1, -20, 0, 30); tabButtonsFrame.Position = UDim2.new(0, 10, 0, 40); tabButtonsFrame.BackgroundTransparency = 1
local tabLayout = Instance.new("UIListLayout", tabButtonsFrame)
tabLayout.FillDirection = Enum.FillDirection.Horizontal; tabLayout.SortOrder = Enum.SortOrder.LayoutOrder; tabLayout.Padding = UDim.new(0, 5)

local pages = {}
local function createTabBtn(name, order)
	local b = Instance.new("TextButton", tabButtonsFrame)
	b.Size = UDim2.new(0.31, 0, 1, 0); b.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	b.Text = name; b.TextColor3 = Color3.fromRGB(180, 180, 180); b.Font = Enum.Font.GothamMedium; b.TextSize = 12; b.LayoutOrder = order
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
	
	local page = Instance.new("ScrollingFrame", mainFrame)
	page.Size = UDim2.new(1, -40, 1, -85); page.Position = UDim2.new(0, 20, 0, 80); page.BackgroundTransparency = 1
	page.Visible = (name == "Главная"); page.ScrollBarThickness = 0
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	page.CanvasSize = UDim2.new(0, 0, 0, 0)
	
	local layout = Instance.new("UIListLayout", page)
	layout.Padding = UDim.new(0, 12); layout.SortOrder = Enum.SortOrder.LayoutOrder
	
	pages[name] = {btn = b, page = page}
	b.MouseButton1Click:Connect(function()
		for n, p in pairs(pages) do
			p.page.Visible = (n == name)
			p.btn.TextColor3 = (n == name) and Color3.new(1,1,1) or Color3.fromRGB(180, 180, 180)
		end
	end)
	return page
end

local mainPage = createTabBtn("Главная", 1)
local tpPage = createTabBtn("ТП", 2)
local settingsPage = createTabBtn("Настройки", 3)
pages["Главная"].btn.TextColor3 = Color3.new(1,1,1)

-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
local function setupInput(placeholder, parent, order)
	local box = Instance.new("TextBox", parent)
	box.Size = UDim2.new(1, 0, 0, 35); box.PlaceholderText = placeholder; box.BackgroundColor3 = Color3.fromRGB(45, 45, 45); box.TextColor3 = Color3.new(1,1,1)
	box.LayoutOrder = order; Instance.new("UICorner", box)
	return box
end

local function createCheatBtn(text, parent, order)
	local b = Instance.new("TextButton", parent)
	b.Size = UDim2.new(1, 0, 0, 45); b.Text = text; b.TextColor3 = Color3.fromRGB(255, 80, 80); b.Font = Enum.Font.GothamBold; b.TextSize = 18; b.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	b.LayoutOrder = order; Instance.new("UICorner", b)
	return b
end

-- КОНТЕНТ: ГЛАВНАЯ
local speedInput = setupInput("Скорость", mainPage, 1)
local jumpInput = setupInput("Высота прыжка", mainPage, 2)
local fovInput = setupInput("FOV (Поле зрения)", mainPage, 3)
local noclipBtn = createCheatBtn("Ноуклип: Выкл", mainPage, 4)
local infJumpBtn = createCheatBtn("Инф. Прыжок: Выкл", mainPage, 5)
local fullbrightBtn = createCheatBtn("Фулбрайт: Выкл", mainPage, 6)
local platformBtn = createCheatBtn("Платформы: Выкл", mainPage, 7)
local serverHopBtn = createCheatBtn("Сменить сервер", mainPage, 8)
serverHopBtn.TextColor3 = Color3.fromRGB(120, 120, 255)

-- КОНТЕНТ: ТП
local addTpBtn = createCheatBtn("+", tpPage, 0)
addTpBtn.TextColor3 = Color3.fromRGB(0, 255, 0)

-- МЕНЮ СОЗДАНИЯ ТП
local tpCreateFrame = Instance.new("Frame", mainFrame)
tpCreateFrame.Size = UDim2.new(0, 260, 0, 240); tpCreateFrame.Position = UDim2.new(0.5, -130, 0.5, -120)
tpCreateFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40); tpCreateFrame.Visible = false; tpCreateFrame.ZIndex = 20
Instance.new("UICorner", tpCreateFrame)
Instance.new("UIStroke", tpCreateFrame).Color = Color3.fromRGB(0, 255, 0)

local createLayout = Instance.new("UIListLayout", tpCreateFrame)
createLayout.Padding = UDim.new(0, 10); createLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; createLayout.SortOrder = Enum.SortOrder.LayoutOrder

local typeSelector = Instance.new("Frame", tpCreateFrame)
typeSelector.Size = UDim2.new(0.9, 0, 0, 40); typeSelector.BackgroundTransparency = 1; typeSelector.LayoutOrder = 1
local typeLayout = Instance.new("UIListLayout", typeSelector); typeLayout.FillDirection = Enum.FillDirection.Horizontal; typeLayout.Padding = UDim.new(0, 10)

local selectedType = "Место"
local targetInput = setupInput("Ник игрока", tpCreateFrame, 2)
targetInput.Visible = false -- По умолчанию скрыто

local function createTypeBtn(name)
	local b = Instance.new("TextButton", typeSelector)
	b.Size = UDim2.new(0.46, 0, 1, 0); b.Text = name; b.BackgroundColor3 = Color3.fromRGB(60, 60, 60); b.TextColor3 = Color3.new(1,1,1); b.Font = Enum.Font.GothamBold
	Instance.new("UICorner", b)
	return b
end

local typePlaceBtn = createTypeBtn("Место")
local typePlayerBtn = createTypeBtn("Игрок")

local function updateSelector()
	typePlaceBtn.BackgroundColor3 = (selectedType == "Место") and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(60, 60, 60)
	typePlayerBtn.BackgroundColor3 = (selectedType == "Игрок") and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(60, 60, 60)
	targetInput.Visible = (selectedType == "Игрок")
end
updateSelector()

typePlaceBtn.MouseButton1Click:Connect(function() selectedType = "Место"; updateSelector() end)
typePlayerBtn.MouseButton1Click:Connect(function() selectedType = "Игрок"; updateSelector() end)

local titleInput = setupInput("Название кнопки", tpCreateFrame, 3)
local doneBtn = createCheatBtn("Готово", tpCreateFrame, 4)
doneBtn.Size = UDim2.new(0.9, 0, 0, 40)

addTpBtn.MouseButton1Click:Connect(function() tpCreateFrame.Visible = not tpCreateFrame.Visible end)

doneBtn.MouseButton1Click:Connect(function()
	local name = titleInput.Text ~= "" and titleInput.Text or (selectedType == "Место" and "Точка" or targetInput.Text)
	local tpBtn = createCheatBtn(name, tpPage, 10)
	tpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	
	local savedType = selectedType
	local targetData = (savedType == "Место") and player.Character.HumanoidRootPart.CFrame or targetInput.Text
	
	tpBtn.MouseButton1Click:Connect(function()
		if savedType == "Место" then
			player.Character:SetPrimaryPartCFrame(targetData)
		else
			local target = Players:FindFirstChild(targetData)
			if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
				player.Character:SetPrimaryPartCFrame(target.Character.HumanoidRootPart.CFrame)
			end
		end
	end)
	
	tpCreateFrame.Visible = false
	titleInput.Text = ""; targetInput.Text = ""
end)

-- ЛОГИКА ГЛАВНОЙ
speedInput.FocusLost:Connect(function() if player.Character and player.Character:FindFirstChild("Humanoid") then player.Character.Humanoid.WalkSpeed = tonumber(speedInput.Text) or 16 end end)
jumpInput.FocusLost:Connect(function() if player.Character and player.Character:FindFirstChild("Humanoid") then player.Character.Humanoid.JumpPower = tonumber(jumpInput.Text) or 50 end end)
fovInput.FocusLost:Connect(function() camera.FieldOfView = tonumber(fovInput.Text) or 70 end)

noclipBtn.MouseButton1Click:Connect(function()
	noclipEnabled = not noclipEnabled
	noclipBtn.Text = noclipEnabled and "Ноуклип: Вкл" or "Ноуклип: Выкл"
	noclipBtn.TextColor3 = noclipEnabled and Color3.fromRGB(80, 255, 80) or Color3.fromRGB(255, 80, 80)
	if not noclipEnabled and player.Character then
		for _, v in pairs(player.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = true end end
	end
end)

infJumpBtn.MouseButton1Click:Connect(function()
	infJumpEnabled = not infJumpEnabled
	infJumpBtn.Text = infJumpEnabled and "Инф. Прыжок: Вкл" or "Инф. Прыжок: Выкл"
	infJumpBtn.TextColor3 = infJumpEnabled and Color3.fromRGB(80, 255, 80) or Color3.fromRGB(255, 80, 80)
end)

platformBtn.MouseButton1Click:Connect(function()
	platformsEnabled = not platformsEnabled
	platformBtn.Text = platformsEnabled and "Платформы: Вкл" or "Платформы: Выкл"
	platformBtn.TextColor3 = platformsEnabled and Color3.fromRGB(80, 255, 80) or Color3.fromRGB(255, 80, 80)
end)

serverHopBtn.MouseButton1Click:Connect(function()
	serverHopBtn.Text = "Поиск..."
	local x = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
	for i,v in pairs(x.data) do
		if v.playing < v.maxPlayers and v.id ~= game.JobId then
			TeleportService:TeleportToPlaceInstance(game.PlaceId, v.id, player)
			break
		end
	end
	task.wait(2); serverHopBtn.Text = "Сменить сервер"
end)

-- ЛОГИКА НАСТРОЕК
local nameInput = setupInput("Название чита", settingsPage, 1)
nameInput.FocusLost:Connect(function() if #nameInput.Text >= 1 then logo.Text = nameInput.Text end end)

-- ЦИКЛЫ И ПЕРЕТАСКИВАНИЕ
RunService.Stepped:Connect(function()
	if noclipEnabled and player.Character then
		for _, v in pairs(player.Character:GetChildren()) do if v:IsA("BasePart") then v.CanCollide = false end end
	end
end)

UserInputService.JumpRequest:Connect(function()
	if infJumpEnabled and player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
		player.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
	end
end)

task.spawn(function()
	while true do
		task.wait(0.05)
		if platformsEnabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local root = player.Character.HumanoidRootPart
			if math.abs(root.Velocity.Y) > 1 or UserInputService:IsKeyDown(Enum.KeyCode.Space) then
				local p = Instance.new("Part")
				p.Size = Vector3.new(5, 0.5, 5); p.Position = root.Position - Vector3.new(0, 3.1, 0)
				p.Anchored = true; p.Color = mainStroke.Color; p.Material = Enum.Material.Neon; p.Parent = workspace
				Debris:AddItem(p, 1)
			end
		end
	end
end)

local dragging, dragStart, startPos
mainFrame.InputBegan:Connect(function(input)
	if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2) then
		dragging = true; dragStart = input.Position; startPos = mainFrame.Position
		input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy() end)
