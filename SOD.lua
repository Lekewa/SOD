local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")

local parentObj = nil
pcall(function() parentObj = CoreGui end)
if not parentObj then parentObj = player:WaitForChild("PlayerGui") end

if parentObj:FindFirstChild("SOI_Final_V56") then parentObj.SOI_Final_V56:Destroy() end

local lang = "RU"
local noclip, airJumpEnabled, partJump = false, false, false
local platform = nil
local tpDistance, currentFOV = 10, 70
local fullBright, noFog, fovActive = false, false, false
local espBoxes, espTracers = false, false
local connections = {}

-- Сохраняем дефолтные настройки света
local defaultAmbient = Lighting.Ambient
local defaultBrightness = Lighting.Brightness

local translations = {
    RU = {
        main = "ГЛАВНАЯ", vision = "ВИЗУАЛЫ", esp = "ЕСП",
        speed = "Скорость", jump = "Высота прыжка",
        tp = "ТП Вперед", dist = "Расстояние",
        aj = "Аир Джамп", noclip = "Ноуклип",
        plat = "Платформа", fbright = "Яркость", nfog = "Без тумана",
        fovBtn = "ФОВ", fovInp = "Значение",
        on = "ВКЛ", off = "ВЫКЛ",
        eBox = "Квадраты", eLine = "Трейсеры"
    },
    EN = {
        main = "MAIN", vision = "VISION", esp = "ESP",
        speed = "Speed", jump = "Jump Power",
        tp = "TP forward", dist = "Distance",
        aj = "Air Jump", noclip = "Noclip",
        plat = "Platform", fbright = "FullBright", nfog = "No Fog",
        fovBtn = "FOV", fovInp = "Amount",
        on = "ON", off = "OFF",
        eBox = "Boxes", eLine = "Tracers"
    }
}

-- [ ИНТЕРФЕЙС ]
local MainGui = Instance.new("ScreenGui")
MainGui.Name = "SOI_Final_V56"
MainGui.Parent = parentObj
MainGui.IgnoreGuiInset = true

local MainFrame = Instance.new("Frame", MainGui)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.Position = UDim2.new(0.5, -155, 0.5, -170)
MainFrame.Size = UDim2.new(0, 310, 0, 340)
MainFrame.Active = true; MainFrame.Draggable = true
Instance.new("UICorner", MainFrame)
Instance.new("UIStroke", MainFrame).Color = Color3.fromRGB(0, 120, 255)

local function createBtn(txt, prnt, clr)
    local b = Instance.new("TextButton")
    b.Parent = prnt; b.BackgroundColor3 = clr or Color3.fromRGB(30, 30, 38)
    b.Text = txt; b.TextColor3 = Color3.new(1, 1, 1); b.Font = Enum.Font.GothamBold; b.TextSize = 14
    Instance.new("UICorner", b)
    return b
end

-- ВЕРХНЯЯ ПАНЕЛЬ
local TopPanel = Instance.new("Frame", MainFrame)
TopPanel.Size = UDim2.new(1, -20, 0, 45); TopPanel.Position = UDim2.new(0, 10, 0, 10); TopPanel.BackgroundTransparency = 1

local LangBtn = createBtn("RU", TopPanel, Color3.fromRGB(45, 45, 55))
LangBtn.Size = UDim2.new(0, 45, 1, 0)

local LogoLabel = Instance.new("TextLabel", TopPanel)
LogoLabel.Text = "SOI"; LogoLabel.Font = Enum.Font.GothamBlack; LogoLabel.TextSize = 24
LogoLabel.TextColor3 = Color3.new(1,1,1); LogoLabel.Position = UDim2.new(0, 50, 0, 0); LogoLabel.Size = UDim2.new(0, 50, 1, 0); LogoLabel.BackgroundTransparency = 1

local SettingsBtn = createBtn("⚙️", TopPanel, Color3.fromRGB(45, 45, 55))
SettingsBtn.Position = UDim2.new(0, 105, 0, 0); SettingsBtn.Size = UDim2.new(0, 45, 1, 0)

local ResetBtn = createBtn("R", TopPanel, Color3.fromRGB(45, 45, 55))
ResetBtn.Position = UDim2.new(0, 155, 0, 0); ResetBtn.Size = UDim2.new(0, 45, 1, 0)

local HideBtn = createBtn("-", TopPanel, Color3.fromRGB(45, 45, 55))
HideBtn.Position = UDim2.new(0, 205, 0, 0); HideBtn.Size = UDim2.new(0, 45, 1, 0)

local CloseBtn = createBtn("×", TopPanel, Color3.fromRGB(100, 35, 35))
CloseBtn.Position = UDim2.new(1, -45, 0, 0); CloseBtn.Size = UDim2.new(0, 45, 1, 0)

-- ВКЛАДКИ
local function createPage(n)
    local p = Instance.new("ScrollingFrame", MainFrame)
    p.Name = n; p.Position = UDim2.new(0, 10, 0, 115); p.Size = UDim2.new(1, -20, 1, -125); p.BackgroundTransparency = 1; p.ScrollBarThickness = 0
    Instance.new("UIListLayout", p).Padding = UDim.new(0, 8); p.Visible = false
    return p
end

local PageMain, PageVision, PageESP = createPage("Main"), createPage("Vision"), createPage("ESP")
PageMain.Visible = true

local TabHolder = Instance.new("Frame", MainFrame)
TabHolder.Size = UDim2.new(1, -20, 0, 40); TabHolder.Position = UDim2.new(0, 10, 0, 65); TabHolder.BackgroundTransparency = 1
Instance.new("UIListLayout", TabHolder).FillDirection = Enum.FillDirection.Horizontal; TabHolder.UIListLayout.Padding = UDim.new(0, 6)

local Tab1 = createBtn("", TabHolder); Tab1.Size = UDim2.new(0.31, 0, 1, 0)
local Tab2 = createBtn("", TabHolder); Tab2.Size = UDim2.new(0.31, 0, 1, 0)
local Tab3 = createBtn("", TabHolder); Tab3.Size = UDim2.new(0.31, 0, 1, 0)

local function createRow(prnt)
    local r = Instance.new("Frame", prnt); r.Size = UDim2.new(1, 0, 0, 42); r.BackgroundTransparency = 1
    return r
end
local function createInp(txt, prnt)
    local i = Instance.new("TextBox")
    i.Parent = prnt; i.Size = UDim2.new(1, 0, 0, 42); i.PlaceholderText = txt; i.Text = ""
    i.BackgroundColor3 = Color3.fromRGB(22, 22, 28); i.TextColor3 = Color3.new(1, 1, 1)
    i.Font = Enum.Font.Gotham; i.TextSize = 11; Instance.new("UICorner", i)
    return i
end

-- [ ГЛАВНАЯ ]
local r1 = createRow(PageMain); local sInp = createInp("Speed", r1); sInp.Size = UDim2.new(0.48,0,1,0); local jInp = createInp("Jump", r1); jInp.Position = UDim2.new(0.52,0,0,0); jInp.Size = UDim2.new(0.48,0,1,0)
local r2 = createRow(PageMain); local tpBtn = createBtn("", r2); tpBtn.Size = UDim2.new(0.48,0,1,0); local distInp = createInp("Dist", r2); distInp.Position = UDim2.new(0.52,0,0,0); distInp.Size = UDim2.new(0.48,0,1,0)
local r3 = createRow(PageMain); local airBtn = createBtn("", r3); airBtn.Size = UDim2.new(0.48,0,1,0); local noclipBtn = createBtn("", r3); noclipBtn.Position = UDim2.new(0.52,0,0,0); noclipBtn.Size = UDim2.new(0.48,0,1,0)
local r4 = createRow(PageMain); local platBtn = createBtn("", r4); platBtn.Size = UDim2.new(1, 0, 1, 0)

-- [ ВИЗУАЛЫ ]
local vr1 = createRow(PageVision); local fbBtn = createBtn("", vr1); fbBtn.Size = UDim2.new(0.48,0,1,0); local nfBtn = createBtn("", vr1); nfBtn.Position = UDim2.new(0.52,0,0,0); nfBtn.Size = UDim2.new(0.48,0,1,0)
local vr2 = createRow(PageVision); local fovBtnText = createBtn("", vr2); fovBtnText.Size = UDim2.new(0.48,0,1,0); local fInp = createInp("FOV", vr2); fInp.Position = UDim2.new(0.52,0,0,0); fInp.Size = UDim2.new(0.48,0,1,0)

-- [ ESP ]
local er1 = createRow(PageESP); local boxBtn = createBtn("", er1); boxBtn.Size = UDim2.new(0.48,0,1,0); local lineBtn = createBtn("", er1); lineBtn.Position = UDim2.new(0.52,0,0,0); lineBtn.Size = UDim2.new(0.48,0,1,0)

-- [ ЛОГИКА ]
local function totalReset()
    noclip = false; partJump = false; airJumpEnabled = false; fullBright = false; fovActive = false
    espBoxes = false; espTracers = false
    if platform then platform:Destroy(); platform = nil end
    Lighting.Ambient = defaultAmbient; Lighting.Brightness = defaultBrightness
    camera.FieldOfView = 70
end

-- NOCLIP ЦИКЛ
table.insert(connections, RunService.Stepped:Connect(function()
    if noclip and player.Character then
        for _, part in pairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
    if partJump and player.Character then
        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            if not platform then 
                platform = Instance.new("Part", workspace)
                platform.Size = Vector3.new(10, 1, 10); platform.Anchored = true; platform.Transparency = 0.5; platform.Color = Color3.fromRGB(0, 120, 255) 
            end
            platform.CFrame = hrp.CFrame * CFrame.new(0, -3.5, 0)
        end
    elseif platform then platform:Destroy(); platform = nil end
end))

-- РЕНДЕР ЦИКЛ (Текст и Свет)
table.insert(connections, RunService.RenderStepped:Connect(function()
    local t = translations[lang]; local s = (function(v) return v and t.on or t.off end)
    airBtn.Text = t.aj..": "..s(airJumpEnabled); noclipBtn.Text = t.noclip..": "..s(noclip)
    platBtn.Text = t.plat..": "..s(partJump); fbBtn.Text = t.fbright..": "..s(fullBright)
    nfBtn.Text = t.nfog..": "..s(noFog); fovBtnText.Text = t.fovBtn..": "..s(fovActive)
    boxBtn.Text = t.eBox..": "..s(espBoxes); lineBtn.Text = t.eLine..": "..s(espTracers)
    
    if fovActive then camera.FieldOfView = currentFOV end
    if fullBright then Lighting.Ambient = Color3.new(1,1,1); Lighting.Brightness = 2 end
end))

-- ОБРАБОТКА КНОПОК
fbBtn.MouseButton1Click:Connect(function() 
    fullBright = not fullBright 
    if not fullBright then Lighting.Ambient = defaultAmbient; Lighting.Brightness = defaultBrightness end 
end)
noclipBtn.MouseButton1Click:Connect(function() 
    noclip = not noclip 
    if not noclip and player.Character then
        for _, part in pairs(player.Character:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = true end end
    end
end)
boxBtn.MouseButton1Click:Connect(function() espBoxes = not espBoxes end)
lineBtn.MouseButton1Click:Connect(function() espTracers = not espTracers end)
platBtn.MouseButton1Click:Connect(function() partJump = not partJump end)
airBtn.MouseButton1Click:Connect(function() airJumpEnabled = not airJumpEnabled end)
fovBtnText.MouseButton1Click:Connect(function() fovActive = not fovActive; if not fovActive then camera.FieldOfView = 70 end end)
tpBtn.MouseButton1Click:Connect(function() 
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then 
        player.Character.HumanoidRootPart.CFrame += (player.Character.HumanoidRootPart.CFrame.LookVector * tpDistance) 
    end 
end)

-- AIRJUMP
table.insert(connections, UIS.JumpRequest:Connect(function() 
    if airJumpEnabled and player.Character and player.Character:FindFirstChildOfClass("Humanoid") then 
        player.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping) 
    end 
end))

-- НАВИГАЦИЯ
local function updateLanguage()
    local t = translations[lang]
    Tab1.Text = t.main; Tab2.Text = t.vision; Tab3.Text = t.esp
    tpBtn.Text = t.tp; LangBtn.Text = lang
    sInp.PlaceholderText = t.speed; jInp.PlaceholderText = t.jump
end

LangBtn.MouseButton1Click:Connect(function() lang = (lang == "RU") and "EN" or "RU"; updateLanguage() end)
Tab1.MouseButton1Click:Connect(function() PageMain.Visible = true; PageVision.Visible = false; PageESP.Visible = false end)
Tab2.MouseButton1Click:Connect(function() PageMain.Visible = false; PageVision.Visible = true; PageESP.Visible = false end)
Tab3.MouseButton1Click:Connect(function() PageMain.Visible = false; PageVision.Visible = false; PageESP.Visible = true end)
ResetBtn.MouseButton1Click:Connect(totalReset)
CloseBtn.MouseButton1Click:Connect(function() totalReset(); MainGui:Destroy() end)

-- ИНПУТЫ
sInp:GetPropertyChangedSignal("Text"):Connect(function() if player.Character and player.Character:FindFirstChild("Humanoid") then player.Character.Humanoid.WalkSpeed = tonumber(sInp.Text) or 16 end end)
jInp:GetPropertyChangedSignal("Text"):Connect(function() if player.Character and player.Character:FindFirstChild("Humanoid") then player.Character.Humanoid.JumpPower = tonumber(jInp.Text) or 50 end end)
fInp:GetPropertyChangedSignal("Text"):Connect(function() currentFOV = tonumber(fInp.Text) or 70 end)
distInp:GetPropertyChangedSignal("Text"):Connect(function() tpDistance = tonumber(distInp.Text) or 10 end)

updateLanguage()
