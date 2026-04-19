-- СЕРВИСЫ
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")

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
	b.Size = UDim2.new(0.48, 0, 1, 0); b.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	b.Text = name; b.TextColor3 = Color3.fromRGB(180, 180, 180); b.Font = Enum.Font.GothamMedium; b.TextSize = 14; b.LayoutOrder = order
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
local settingsPage = createTabBtn("Настройки", 2)
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

local function createPalette(parent, callback, inputField, order)
	local container = Instance.new("Frame", parent)
	container.Size = UDim2.new(1, 0, 0, 175); container.BackgroundTransparency = 1
	container.LayoutOrder = order
	local grid = Instance.new("UIGridLayout", container)
	grid.CellSize = UDim2.new(0, 44, 0, 28); grid.HorizontalAlignment = Enum.HorizontalAlignment.Center; grid.CellPadding = UDim2.new(0,6,0,6)
	
	local colors = {
		Color3.fromRGB(255, 120, 120), Color3.fromRGB(255, 0, 0), Color3.fromRGB(140, 0, 0),
		Color3.fromRGB(120, 255, 120), Color3.fromRGB(0, 255, 0), Color3.fromRGB(0, 140, 0),
		Color3.fromRGB(120, 120, 255), Color3.fromRGB(0, 0, 255), Color3.fromRGB(0, 0, 140),
		Color3.fromRGB(255, 255, 120), Color3.fromRGB(255, 255, 0), Color3.fromRGB(140, 140, 0),
		Color3.fromRGB(255, 120, 255), Color3.fromRGB(255, 0, 255), Color3.fromRGB(140, 0, 140),
		Color3.fromRGB(120, 255, 255), Color3.fromRGB(0, 255, 255), Color3.fromRGB(0, 140, 140),
		Color3.fromRGB(255, 190, 120), Color3.fromRGB(255, 140, 0), Color3.fromRGB(140, 70, 0),
		Color3.fromRGB(255, 255, 255), Color3.fromRGB(140, 140, 140), Color3.fromRGB(70, 70, 70), Color3.fromRGB(0, 0, 0)
	}
	
	for _, color in pairs(colors) do
		local cBtn = Instance.new("TextButton", container)
		cBtn.Text = ""; cBtn.BackgroundColor3 = color; Instance.new("UICorner", cBtn).CornerRadius = UDim.new(0, 4)
		local bStroke = Instance.new("UIStroke", cBtn)
		bStroke.Color = Color3.fromRGB(90, 90, 90); bStroke.Thickness = 1
		
		cBtn.MouseButton1Click:Connect(function()
			callback(color)
			if inputField then inputField.Text = "#" .. color:ToHex():upper() end
		end)
	end
	return container
end

-- КОНТЕНТ: ГЛАВНАЯ
local speedInput = setupInput("Скорость", mainPage, 1)
local jumpInput = setupInput("Высота прыжка", mainPage, 2)
local fovInput = setupInput("FOV (Поле зрения)", mainPage, 3)
local noclipBtn = createCheatBtn("Ноуклип: Выкл", mainPage, 4)
local infJumpBtn = createCheatBtn("Инф. Прыжок: Выкл", mainPage, 5)
local fullbrightBtn = createCheatBtn("Фулбрайт: Выкл", mainPage, 6)
local platformBtn = createCheatBtn("Платформы: Выкл", mainPage, 7)

-- КОНТЕНТ: НАСТРОЙКИ
local nameInput = setupInput("Название чита", settingsPage, 1)

local titleLab = Instance.new("TextLabel", settingsPage)
titleLab.Text = "Цвет названия:"; titleLab.Size = UDim2.new(1,0,0,20); titleLab.BackgroundTransparency = 1; titleLab.TextColor3 = Color3.new(0.8,0.8,0.8); titleLab.LayoutOrder = 2
local colorInputTitle = setupInput("HEX названия", settingsPage, 3)
createPalette(settingsPage, function(c) logo.TextColor3 = c end, colorInputTitle, 4)

local strokeLab = Instance.new("TextLabel", settingsPage)
strokeLab.Text = "Цвет обводки:"; strokeLab.Size = UDim2.new(1,0,0,20); strokeLab.BackgroundTransparency = 1; strokeLab.TextColor3 = Color3.new(0.8,0.8,0.8); strokeLab.LayoutOrder = 5
local colorInputStroke = setupInput("HEX обводки", settingsPage, 6)
createPalette(settingsPage, function(c) mainStroke.Color = c end, colorInputStroke, 7)

-- ЛОГИКА ГЛАВНОЙ
speedInput.FocusLost:Connect(function() 
	if player.Character and player.Character:FindFirstChild("Humanoid") then 
		player.Character.Humanoid.WalkSpeed = tonumber(speedInput.Text) or 16 
	end 
end)

jumpInput.FocusLost:Connect(function() 
	if player.Character and player.Character:FindFirstChild("Humanoid") then 
		player.Character.Humanoid.JumpPower = tonumber(jumpInput.Text) or 50 
	end 
end)

fovInput.FocusLost:Connect(function() camera.FieldOfView = tonumber(fovInput.Text) or 70 end)

noclipBtn.MouseButton1Click:Connect(function()
	noclipEnabled = not noclipEnabled
	noclipBtn.Text = noclipEnabled and "Ноуклип: Вкл" or "Ноуклип: Выкл"
	noclipBtn.TextColor3 = noclipEnabled and Color3.fromRGB(80, 255, 80) or Color3.fromRGB(255, 80, 80)
end)

infJumpBtn.MouseButton1Click:Connect(function()
	infJumpEnabled = not infJumpEnabled
	infJumpBtn.Text = infJumpEnabled and "Инф. Прыжок: Вкл" or "Инф. Прыжок: Выкл"
	infJumpBtn.TextColor3 = infJumpEnabled and Color3.fromRGB(80, 255, 80) or Color3.fromRGB(255, 80, 80)
end)

fullbrightBtn.MouseButton1Click:Connect(function()
	fullbrightEnabled = not fullbrightEnabled
	fullbrightBtn.Text = fullbrightEnabled and "Фулбрайт: Вкл" or "Фулбрайт: Выкл"
	fullbrightBtn.TextColor3 = fullbrightEnabled and Color3.fromRGB(80, 255, 80) or Color3.fromRGB(255, 80, 80)
	if fullbrightEnabled then
		Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.Ambient = Color3.new(1,1,1)
	else
		Lighting.Brightness = origBrightness; Lighting.ClockTime = origClockTime; Lighting.Ambient = origAmbient
	end
end)

platformBtn.MouseButton1Click:Connect(function()
	platformsEnabled = not platformsEnabled
	platformBtn.Text = platformsEnabled and "Платформы: Вкл" or "Платформы: Выкл"
	platformBtn.TextColor3 = platformsEnabled and Color3.fromRGB(80, 255, 80) or Color3.fromRGB(255, 80, 80)
end)

-- ЛОГИКА НАСТРОЕК
nameInput.FocusLost:Connect(function() if #nameInput.Text >= 1 then logo.Text = nameInput.Text end end)
colorInputStroke.FocusLost:Connect(function() local success, result = pcall(function() return Color3.fromHex(colorInputStroke.Text) end) if success then mainStroke.Color = result end end)
colorInputTitle.FocusLost:Connect(function() local success, result = pcall(function() return Color3.fromHex(colorInputTitle.Text) end) if success then logo.TextColor3 = result end end)

-- ОКНО
hideBtn.MouseButton1Click:Connect(function()
	isMinimized = not isMinimized
	local targetSize = isMinimized and UDim2.new(0, 300, 0, 40) or UDim2.new(0, 300, 0, 400)
	TweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart), {Size = targetSize}):Play()
	tabButtonsFrame.Visible = not isMinimized
	for _, p in pairs(pages) do p.page.Visible = (not isMinimized and p.btn.TextColor3 == Color3.new(1,1,1)) end
end)

resetBtn.MouseButton1Click:Connect(function()
	-- Сбрасываем только читы
	noclipEnabled = false; infJumpEnabled = false; platformsEnabled = false; fullbrightEnabled = false
	if player.Character and player.Character:FindFirstChild("Humanoid") then
		player.Character.Humanoid.WalkSpeed = 16; player.Character.Humanoid.JumpPower = 50
	end
	
	-- Сброс FOV и Света
	camera.FieldOfView = 70; fovInput.Text = "70"
	Lighting.Brightness = origBrightness; Lighting.ClockTime = origClockTime; Lighting.Ambient = origAmbient
	
	-- Сброс текста в полях главной
	speedInput.Text = "16"; jumpInput.Text = "50"
	
	-- Обновление кнопок
	noclipBtn.Text = "Ноуклип: Выкл"; noclipBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
	infJumpBtn.Text = "Инф. Прыжок: Выкл"; infJumpBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
	fullbrightBtn.Text = "Фулбрайт: Выкл"; fullbrightBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
	platformBtn.Text = "Платформы: Выкл"; platformBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
	
	-- НАСТРОЙКИ (логотип, цвета) НЕ ТРОГАЕМ
end)

closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy() end)

-- ЦИКЛЫ
RunService.Stepped:Connect(function()
	if noclipEnabled and player.Character then
		for _, v in pairs(player.Character:GetChildren()) do 
			if v:IsA("BasePart") then 
				v.CanCollide = false 
			end 
		end
	end
end)

UserInputService.JumpRequest:Connect(function()
	if infJumpEnabled and player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
		player.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
	end
end)

task.spawn(function()
	while true do
		task.wait(0.1)
		if platformsEnabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local hum = player.Character:FindFirstChild("Humanoid")
			-- Платформа создается только если мы в воздухе
			if hum and hum.FloorMaterial == Enum.Material.Air then
				local p = Instance.new("Part")
				p.Size = Vector3.new(5, 0.5, 5)
				p.Position = player.Character.HumanoidRootPart.Position - Vector3.new(0, 3.2, 0)
				p.Anchored = true; p.Color = mainStroke.Color; p.Material = Enum.Material.Neon; p.Parent = workspace
				Debris:AddItem(p, 2)
			end
		end
	end
end)

-- ПЕРЕТАСКИВАНИЕ
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
