local existingGui = game:GetService("CoreGui"):FindFirstChild("SOD_Ultra_SyncSync") or game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("SOD_Ultra_SyncSync")
if existingGui then
    existingGui:Destroy()
end

-- СЕРВИСЫ
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

-- ПЕРЕМЕННЫЕ
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local noclipEnabled = false
local infJumpEnabled = false
local platformsEnabled = false
local fullbrightEnabled = false
local isMinimized = false
local currentTempChain = {}
local selPlayer = ""
local selMode = "Место"

-- ПЕРЕМЕННЫЕ ДЛЯ БИНДОВ
local keybinds = {
    Noclip = Enum.KeyCode.Unknown,
    InfJump = Enum.KeyCode.Unknown,
    Fullbright = Enum.KeyCode.Unknown,
    Platforms = Enum.KeyCode.Unknown
}
local listeningFor = nil

-- СОХРАНЕНИЕ СТАНДАРТНОГО ОСВЕЩЕНИЯ
local origBrightness = Lighting.Brightness
local origClockTime = Lighting.ClockTime
local origAmbient = Lighting.Ambient

-- КОРНЕВОЙ ИНТЕРФЕЙС
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SOD_Ultra_FullVersion"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 2147483647 
screenGui.IgnoreGuiInset = true

local success, target = pcall(function() return gethui() or CoreGui end)
screenGui.Parent = success and target or player:WaitForChild("PlayerGui")

-- ФУНКЦИЯ ПЕРЕМЕЩЕНИЯ
local function makeDraggable(frame)
    local dragging, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- ГЛАВНОЕ ОКНО
local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 300, 0, 400)
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
mainFrame.BorderSizePixel = 0
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 15)
local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Color = Color3.fromRGB(0, 255, 0)
mainStroke.Thickness = 6
makeDraggable(mainFrame)

-- ОКНО ТЕЛЕПОРТОВ (НЕЗАВИСИМОЕ)
local tpCreatorFrame = Instance.new("Frame", screenGui)
tpCreatorFrame.Name = "TPCreatorFrame"
tpCreatorFrame.Size = UDim2.new(0, 220, 0, 360)
tpCreatorFrame.Position = UDim2.new(0.5, 160, 0.5, -180)
tpCreatorFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
tpCreatorFrame.Visible = false
Instance.new("UICorner", tpCreatorFrame)
local tpStroke = Instance.new("UIStroke", tpCreatorFrame)
tpStroke.Color = mainStroke.Color
tpStroke.Thickness = 4
makeDraggable(tpCreatorFrame)

-- ОКНО БИНДОВ (НЕЗАВИСИМОЕ)
local bindsFrame = Instance.new("Frame", screenGui)
bindsFrame.Name = "BindsFrame"
bindsFrame.Size = UDim2.new(0, 200, 0, 280)
bindsFrame.Position = UDim2.new(0.5, -360, 0.5, -140)
bindsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
bindsFrame.Visible = false
Instance.new("UICorner", bindsFrame)
local bindsStroke = Instance.new("UIStroke", bindsFrame)
bindsStroke.Color = mainStroke.Color
bindsStroke.Thickness = 4
makeDraggable(bindsFrame)

-- ВСПОМОГАТЕЛЬНЫЕ ЭЛЕМЕНТЫ GUI
local function setupInput(placeholder, parent, order)
    local box = Instance.new("TextBox", parent)
    box.Size = UDim2.new(1, 0, 0, 35)
    box.PlaceholderText = placeholder
    box.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    box.TextColor3 = Color3.new(1, 1, 1)
    box.Font = Enum.Font.Gotham
    box.TextSize = 14
    box.LayoutOrder = order
    Instance.new("UICorner", box)
    return box
end

local function createCheatBtn(text, parent, order)
    local b = Instance.new("TextButton", parent)
    b.Size = UDim2.new(1, 0, 0, 45)
    b.Text = text
    b.TextColor3 = Color3.fromRGB(255, 80, 80)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 18
    b.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    b.LayoutOrder = order
    Instance.new("UICorner", b)
    return b
end

-- ВЕРХНЯЯ ПАНЕЛЬ (ЛОГО И КНОПКИ)
local logo = Instance.new("TextLabel", mainFrame)
logo.Text = "SOD"
logo.Size = UDim2.new(0, 180, 0, 30)
logo.Position = UDim2.new(0, 15, 0, 5)
logo.BackgroundTransparency = 1
logo.TextColor3 = Color3.fromRGB(255, 255, 255)
logo.Font = Enum.Font.GothamBold
logo.TextSize = 22
logo.TextXAlignment = Enum.TextXAlignment.Left

local controlHolder = Instance.new("Frame", mainFrame)
controlHolder.Size = UDim2.new(0, 100, 0, 30)
controlHolder.Position = UDim2.new(1, -105, 0, 5)
controlHolder.BackgroundTransparency = 1
local controlLayout = Instance.new("UIListLayout", controlHolder)
controlLayout.FillDirection = Enum.FillDirection.Horizontal
controlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
controlLayout.Padding = UDim.new(0, 10)

local resetBtn = createCheatBtn("R", controlHolder, 0)
resetBtn.Size = UDim2.new(0, 20, 0, 30)
resetBtn.BackgroundTransparency = 1
resetBtn.TextColor3 = Color3.fromRGB(255, 200, 0)

local hideBtn = createCheatBtn("-", controlHolder, 1)
hideBtn.Size = UDim2.new(0, 20, 0, 30)
hideBtn.BackgroundTransparency = 1
hideBtn.TextColor3 = Color3.new(1,1,1)

local closeBtn = createCheatBtn("X", controlHolder, 2)
closeBtn.Size = UDim2.new(0, 20, 0, 30)
closeBtn.BackgroundTransparency = 1
closeBtn.TextColor3 = Color3.fromRGB(255, 50, 50)

-- ВКЛАДКИ
local tabButtonsFrame = Instance.new("Frame", mainFrame)
tabButtonsFrame.Size = UDim2.new(1, -20, 0, 30)
tabButtonsFrame.Position = UDim2.new(0, 10, 0, 40)
tabButtonsFrame.BackgroundTransparency = 1
local tabLayout = Instance.new("UIListLayout", tabButtonsFrame)
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 5)

local pages = {}
local function createTabBtn(name, order)
    local b = Instance.new("TextButton", tabButtonsFrame)
    b.Size = UDim2.new(0.31, 0, 1, 0)
    b.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    b.Text = name
    b.TextColor3 = Color3.fromRGB(180, 180, 180)
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 12
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    
    local page = Instance.new("ScrollingFrame", mainFrame)
    page.Size = UDim2.new(1, -40, 1, -85)
    page.Position = UDim2.new(0, 20, 0, 80)
    page.BackgroundTransparency = 1
    page.Visible = (name == "Главная")
    page.ScrollBarThickness = 0
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    
    local layout = Instance.new("UIListLayout", page)
    layout.Padding = UDim.new(0, 12)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    
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

-- ЛОГИКА ФУНКЦИЙ
local function toggleNoclip()
    noclipEnabled = not noclipEnabled
    noclipBtn.Text = noclipEnabled and "Ноуклип: Вкл" or "Ноуклип: Выкл"
    noclipBtn.TextColor3 = noclipEnabled and Color3.fromRGB(80, 255, 80) or Color3.fromRGB(255, 80, 80)
    if not noclipEnabled and player.Character then
        for _, v in pairs(player.Character:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = true end
        end
    end
end

local function toggleInfJump()
    infJumpEnabled = not infJumpEnabled
    infJumpBtn.Text = infJumpEnabled and "Инф. Прыжок: Вкл" or "Инф. Прыжок: Выкл"
    infJumpBtn.TextColor3 = infJumpEnabled and Color3.fromRGB(80, 255, 80) or Color3.fromRGB(255, 80, 80)
end

local function toggleFullbright()
    fullbrightEnabled = not fullbrightEnabled
    fullbrightBtn.Text = fullbrightEnabled and "Фулбрайт: Вкл" or "Фулбрайт: Выкл"
    fullbrightBtn.TextColor3 = fullbrightEnabled and Color3.fromRGB(80, 255, 80) or Color3.fromRGB(255, 80, 80)
    if fullbrightEnabled then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.Ambient = Color3.new(1, 1, 1)
    else
        Lighting.Brightness = origBrightness
        Lighting.ClockTime = origClockTime
        Lighting.Ambient = origAmbient
    end
end

local function togglePlatforms()
    platformsEnabled = not platformsEnabled
    platformBtn.Text = platformsEnabled and "Платформы: Вкл" or "Платформы: Выкл"
    platformBtn.TextColor3 = platformsEnabled and Color3.fromRGB(80, 255, 80) or Color3.fromRGB(255, 80, 80)
end

-- КОНТЕНТ: ГЛАВНАЯ
local function runServerHop()
    local success, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Desc&limit=100"))
    end)
    if success and result and result.data then
        for _, v in pairs(result.data) do
            if v.playing < v.maxPlayers and v.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, v.id, player)
                break
            end
        end
    end
end

local mainHop = createCheatBtn("Сменить сервер", mainPage, 0)
mainHop.TextColor3 = Color3.fromRGB(120, 180, 255)
mainHop.MouseButton1Click:Connect(runServerHop)

local speedInput = setupInput("Скорость", mainPage, 1)
local jumpInput = setupInput("Высота прыжка", mainPage, 2)
local fovInput = setupInput("FOV", mainPage, 3)

noclipBtn = createCheatBtn("Ноуклип: Выкл", mainPage, 4)
noclipBtn.MouseButton1Click:Connect(toggleNoclip)

infJumpBtn = createCheatBtn("Инф. Прыжок: Выкл", mainPage, 5)
infJumpBtn.MouseButton1Click:Connect(toggleInfJump)

fullbrightBtn = createCheatBtn("Фулбрайт: Выкл", mainPage, 6)
fullbrightBtn.MouseButton1Click:Connect(toggleFullbright)

platformBtn = createCheatBtn("Платформы: Выкл", mainPage, 7)
platformBtn.MouseButton1Click:Connect(togglePlatforms)

-- КОНТЕНТ: ТП
local tpLayout = Instance.new("UIListLayout", tpCreatorFrame)
tpLayout.Padding = UDim.new(0, 8)
tpLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local modeH = Instance.new("Frame", tpCreatorFrame)
modeH.Size = UDim2.new(0.9, 0, 0, 30)
modeH.BackgroundTransparency = 1
local m1 = Instance.new("TextButton", modeH)
m1.Size = UDim2.new(0.48, 0, 1, 0)
m1.Text = "Место"
m1.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
m1.TextColor3 = Color3.new(1, 1, 1)
local m2 = Instance.new("TextButton", modeH)
m2.Size = UDim2.new(0.48, 0, 1, 0)
m2.Position = UDim2.new(0.52, 0, 0, 0)
m2.Text = "Игрок"
m2.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
m2.TextColor3 = Color3.fromRGB(200, 200, 200)
Instance.new("UICorner", m1)
Instance.new("UICorner", m2)

local pList = Instance.new("ScrollingFrame", tpCreatorFrame)
pList.Size = UDim2.new(0.9, 0, 0, 100)
pList.Visible = false
pList.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
pList.ScrollBarThickness = 2
Instance.new("UIListLayout", pList)

local delayInp = setupInput("Задержка", tpCreatorFrame, 3)
local nameInp = setupInput("Название", tpCreatorFrame, 4)
local addStepBtn = createCheatBtn("Добавить точку", tpCreatorFrame, 5)
addStepBtn.Size = UDim2.new(0.9, 0, 0, 35)
addStepBtn.TextSize = 14
addStepBtn.TextColor3 = Color3.new(1, 1, 0)

local counterLbl = Instance.new("TextLabel", tpCreatorFrame)
counterLbl.Size = UDim2.new(0.9, 0, 0, 20)
counterLbl.Text = "Точек: 0"
counterLbl.BackgroundTransparency = 1
counterLbl.TextColor3 = Color3.new(1, 1, 1)

local doneTpBtn = createCheatBtn("ГОТОВО", tpCreatorFrame, 7)
doneTpBtn.Size = UDim2.new(0.9, 0, 0, 40)
doneTpBtn.TextColor3 = Color3.new(1, 1, 1)

local addTpBtn = createCheatBtn("+", tpPage, 1)
addTpBtn.TextColor3 = Color3.fromRGB(0, 255, 0)
addTpBtn.MouseButton1Click:Connect(function()
    tpCreatorFrame.Visible = not tpCreatorFrame.Visible
    currentTempChain = {}
    counterLbl.Text = "Точек: 0"
    for _, v in pairs(pList:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player then
            local b = Instance.new("TextButton", pList)
            b.Size = UDim2.new(1, -5, 0, 25)
            b.Text = p.Name
            b.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            b.TextColor3 = Color3.new(1, 1, 1)
            b.MouseButton1Click:Connect(function()
                selPlayer = p.Name
                for _, x in pairs(pList:GetChildren()) do if x:IsA("TextButton") then x.BackgroundColor3 = Color3.fromRGB(45, 45, 45) end end
                b.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
            end)
        end
    end
end)

m1.MouseButton1Click:Connect(function() selMode = "Место" m1.BackgroundColor3 = Color3.fromRGB(0, 150, 0) m1.TextColor3 = Color3.new(1,1,1) m2.BackgroundColor3 = Color3.fromRGB(60, 60, 60) m2.TextColor3 = Color3.fromRGB(200,200,200) pList.Visible = false end)
m2.MouseButton1Click:Connect(function() selMode = "Игрок" m2.BackgroundColor3 = Color3.fromRGB(0, 150, 0) m2.TextColor3 = Color3.new(1,1,1) m1.BackgroundColor3 = Color3.fromRGB(60, 60, 60) m1.TextColor3 = Color3.fromRGB(200,200,200) pList.Visible = true end)

-- КОНТЕНТ: НАСТРОЙКИ
local nameInput = setupInput("Название чита", settingsPage, 1)
local colorInputTitle = setupInput("HEX названия", settingsPage, 2)

local function createPalette(parent, callback, inputField, order)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, 0, 0, 175)
    container.BackgroundTransparency = 1
    container.LayoutOrder = order
    local grid = Instance.new("UIGridLayout", container)
    grid.CellSize = UDim2.new(0, 44, 0, 28)
    grid.CellPadding = UDim2.new(0, 6, 0, 6)
    grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
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
        cBtn.Text = ""
        cBtn.BackgroundColor3 = color
        Instance.new("UICorner", cBtn).CornerRadius = UDim.new(0, 4)
        cBtn.MouseButton1Click:Connect(function()
            callback(color)
            if inputField then inputField.Text = "#" .. color:ToHex():upper() end
        end)
    end
    return container
end

createPalette(settingsPage, function(c) logo.TextColor3 = c end, colorInputTitle, 3)
local colorInputStroke = setupInput("HEX обводки", settingsPage, 4)
createPalette(settingsPage, function(c) 
    mainStroke.Color = c
    tpStroke.Color = c
    bindsStroke.Color = c
end, colorInputStroke, 5)

local openBindsBtn = createCheatBtn("Настроить бинды", settingsPage, 6)
openBindsBtn.TextColor3 = Color3.new(1, 1, 0)
openBindsBtn.MouseButton1Click:Connect(function() bindsFrame.Visible = not bindsFrame.Visible end)

-- КОНТЕНТ: БИНДЫ
local bindsTitle = Instance.new("TextLabel", bindsFrame)
bindsTitle.Text = "БИНДЫ"
bindsTitle.Size = UDim2.new(1, 0, 0, 30)
bindsTitle.BackgroundTransparency = 1
bindsTitle.TextColor3 = Color3.new(1, 1, 1)
bindsTitle.Font = Enum.Font.GothamBold

local bindsList = Instance.new("Frame", bindsFrame)
bindsList.Size = UDim2.new(1, -20, 1, -40)
bindsList.Position = UDim2.new(0, 10, 0, 35)
bindsList.BackgroundTransparency = 1
Instance.new("UIListLayout", bindsList).Padding = UDim.new(0, 5)

local function createBindRow(name, keyIndex)
    local f = Instance.new("Frame", bindsList)
    f.Size = UDim2.new(1, 0, 0, 35)
    f.BackgroundTransparency = 1
    local l = Instance.new("TextLabel", f)
    l.Size = UDim2.new(0.6, 0, 1, 0)
    l.Text = name
    l.TextColor3 = Color3.new(1, 1, 1)
    l.BackgroundTransparency = 1
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Font = Enum.Font.Gotham
    local b = Instance.new("TextButton", f)
    b.Size = UDim2.new(0.35, 0, 0.8, 0)
    b.Position = UDim2.new(0.65, 0, 0.1, 0)
    b.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    b.Text = "None"
    b.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", b)
    b.MouseButton1Click:Connect(function() b.Text = "..." listeningFor = keyIndex end)
    UserInputService.InputBegan:Connect(function(input)
        if listeningFor == keyIndex and input.UserInputType == Enum.UserInputType.Keyboard then
            keybinds[keyIndex] = input.KeyCode
            b.Text = input.KeyCode.Name
            listeningFor = nil
        end
    end)
end

createBindRow("Ноуклип", "Noclip")
createBindRow("Инф. Прыжок", "InfJump")
createBindRow("Фулбрайт", "Fullbright")
createBindRow("Платформы", "Platforms")

-- ОБРАБОТКА НАЖАТИЙ
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == keybinds.Noclip then toggleNoclip()
    elseif input.KeyCode == keybinds.InfJump then toggleInfJump()
    elseif input.KeyCode == keybinds.Fullbright then toggleFullbright()
    elseif input.KeyCode == keybinds.Platforms then togglePlatforms() end
end)

-- ФУНКЦИОНАЛ ПЕРСОНАЖА
jumpInput.FocusLost:Connect(function()
    if player.Character then
        local hum = player.Character:FindFirstChild("Humanoid")
        if hum then
            hum.UseJumpPower = true
            hum.JumpPower = tonumber(jumpInput.Text) or 50
            hum.JumpHeight = tonumber(jumpInput.Text) or 50
        end
    end
end)
speedInput.FocusLost:Connect(function() if player.Character then player.Character.Humanoid.WalkSpeed = tonumber(speedInput.Text) or 16 end end)
fovInput.FocusLost:Connect(function() camera.FieldOfView = tonumber(fovInput.Text) or 70 end)
nameInput.FocusLost:Connect(function() if #nameInput.Text >= 1 then logo.Text = nameInput.Text end end)

RunService.Stepped:Connect(function() if noclipEnabled and player.Character then for _, v in pairs(player.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end end end)
UserInputService.JumpRequest:Connect(function() if infJumpEnabled and player.Character then player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end end)

task.spawn(function()
    while true do task.wait(0.05)
        if platformsEnabled and player.Character then
            local r = player.Character.HumanoidRootPart
            if math.abs(r.Velocity.Y) > 1 or UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                local p = Instance.new("Part")
                p.Size = Vector3.new(5, 0.5, 5)
                p.Position = r.Position - Vector3.new(0, 3.1, 0)
                p.Anchored = true
                p.Color = mainStroke.Color
                p.Material = Enum.Material.Neon
                p.Parent = workspace
                Debris:AddItem(p, 1)
            end
        end
    end
end)

-- ЛОГИКА ТЕЛЕПОРТОВ (ФИНАЛИЗАЦИЯ)
addStepBtn.MouseButton1Click:Connect(function()
    local d = tonumber(delayInp.Text) or 0
    local target = (selMode == "Место") and player.Character.HumanoidRootPart.CFrame or selPlayer
    table.insert(currentTempChain, {Target = target, Wait = d, Type = selMode})
    counterLbl.Text = "Точек: " .. #currentTempChain
end)

doneTpBtn.MouseButton1Click:Connect(function()
    if #currentTempChain == 0 then table.insert(currentTempChain, {Target = (selMode == "Место") and player.Character.HumanoidRootPart.CFrame or selPlayer, Wait = tonumber(delayInp.Text) or 0, Type = selMode}) end
    local finalChain = currentTempChain
    local f = Instance.new("Frame", tpPage)
    f.Size = UDim2.new(1, 0, 0, 40)
    f.BackgroundTransparency = 1
    local mainB = createCheatBtn(nameInp.Text ~= "" and nameInp.Text or "ТП", f, 1)
    mainB.Size = UDim2.new(0.85, 0, 1, 0)
    mainB.TextColor3 = Color3.new(1, 1, 1)
    local delB = createCheatBtn("X", f, 2)
    delB.Size = UDim2.new(0.12, 0, 1, 0)
    delB.Position = UDim2.new(0.88, 0, 0, 0)
    delB.TextColor3 = Color3.new(1, 0, 0)
    mainB.MouseButton1Click:Connect(function()
        for _, step in ipairs(finalChain) do
            if step.Type == "Место" then player.Character:SetPrimaryPartCFrame(step.Target)
            else local t = Players:FindFirstChild(step.Target) if t and t.Character then player.Character:SetPrimaryPartCFrame(t.Character.HumanoidRootPart.CFrame) end end
            task.wait(step.Wait)
        end
    end)
    delB.MouseButton1Click:Connect(function() f:Destroy() end)
    tpCreatorFrame.Visible = false
    currentTempChain = {}
end)

hideBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    local targetSize = isMinimized and UDim2.new(0, 300, 0, 40) or UDim2.new(0, 300, 0, 400)
    TweenService:Create(mainFrame, TweenInfo.new(0.4), {Size = targetSize}):Play()
    tabButtonsFrame.Visible = not isMinimized
    for _, p in pairs(pages) do p.page.Visible = (not isMinimized and p.btn.TextColor3 == Color3.new(1,1,1)) end 
end)

closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy() end)
