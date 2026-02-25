local player = game.Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")

-- Пытаемся выбрать родителя: CoreGui (выше настроек) или PlayerGui
local parentObj = nil
local success, err = pcall(function()
    parentObj = CoreGui
end)
if not success or not parentObj then
    parentObj = player:WaitForChild("PlayerGui")
end

-- Удаление старых версий
if parentObj:FindFirstChild("SOI_Final_V37") then 
    parentObj.SOI_Final_V37:Destroy() 
end

-- Состояния
local lang = "EN"
local noclip, airJumpEnabled, partJump, antiRagdoll = false, false, false, false
local platform = nil
local tpDistance, currentFOV = 10, 70
local fullBright, noFog, thirdPerson, fovActive = false, false, false, false

-- Таблица переводов
local translations = {
    RU = {
        main = "ГЛАВНАЯ", vision = "ВИЗУАЛЫ",
        speed = "Скорость", jump = "Высота прыжка",
        tp = "ТП Вперед", dist = "Расстояние",
        aj = "Аир Джамп", noclip = "Ноуклип",
        plat = "Платформа", norag = "Анти Рэгдолл",
        fbright = "Яркость", nfog = "Без тумана",
        fovBtn = "ФОВ", fovInp = "Значение",
        tperson = "3-е лицо", on = "ВКЛ", off = "ВЫКЛ"
    },
    EN = {
        main = "MAIN", vision = "VISION",
        speed = "Speed", jump = "Jump Power",
        tp = "TP forward", dist = "Distance",
        aj = "Air Jump", noclip = "Noclip",
        plat = "Platform", norag = "Anti Ragdoll",
        fbright = "FullBright", nfog = "No Fog",
        fovBtn = "FOV", fovInp = "Amount",
        tperson = "Third Person", on = "ON", off = "OFF"
    }
}

-- [ ИНТЕРФЕЙС ]
local MainGui = Instance.new("ScreenGui")
MainGui.Name = "SOI_Final_V37"
MainGui.Parent = parentObj
MainGui.ResetOnSpawn = false
MainGui.DisplayOrder = 2147483647 -- Потолок приоритета
MainGui.IgnoreGuiInset = true 
MainGui.ZIndexBehavior = Enum.ZIndexBehavior.Global

local MainFrame = Instance.new("Frame")
MainFrame.Parent = MainGui
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.Position = UDim2.new(0.5, -130, 0.5, -140)
MainFrame.Size = UDim2.new(0, 260, 0, 280)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ZIndex = 100
Instance.new("UICorner", MainFrame)
Instance.new("UIStroke", MainFrame).Color = Color3.fromRGB(0, 120, 255)

local function createBtn(txt, prnt, clr)
    local b = Instance.new("TextButton")
    b.Parent = prnt; b.Size = UDim2.new(1, 0, 0, 35); b.BackgroundColor3 = clr or Color3.fromRGB(30, 30, 38)
    b.Text = txt; b.TextColor3 = Color3.new(1, 1, 1); b.Font = Enum.Font.GothamBold; b.TextSize = 10
    b.ZIndex = 101; b.AutoLocalize = false; Instance.new("UICorner", b)
    return b
end

local function createInp(txt, prnt)
    local i = Instance.new("TextBox")
    i.Parent = prnt; i.Size = UDim2.new(1, 0, 0, 35); i.Text = txt
    i.BackgroundColor3 = Color3.fromRGB(22, 22, 28); i.TextColor3 = Color3.new(0.7, 0.7, 0.7)
    i.Font = Enum.Font.Gotham; i.TextSize = 10; i.ZIndex = 101; i.AutoLocalize = false; Instance.new("UICorner", i)
    i.Focused:Connect(function() i.Text = ""; i.TextColor3 = Color3.new(1,1,1) end)
    return i
end

local function createRow(prnt)
    local r = Instance.new("Frame")
    r.Parent = prnt; r.Size = UDim2.new(1, 0, 0, 35); r.BackgroundTransparency = 1; r.ZIndex = 101
    return r
end

-- ВЕРХНЯЯ ПАНЕЛЬ
local LangBtn = createBtn("EN", MainFrame, Color3.fromRGB(45, 45, 55))
LangBtn.Position = UDim2.new(0, 10, 0, 10); LangBtn.Size = UDim2.new(0, 55, 0, 35)
local CloseBtn = createBtn("×", MainFrame, Color3.fromRGB(80, 30, 30))
CloseBtn.Position = UDim2.new(1, -45, 0, 10); CloseBtn.Size = UDim2.new(0, 35, 0, 35); CloseBtn.TextSize = 24
local HideBtn = createBtn("-", MainFrame, Color3.fromRGB(45, 45, 55))
HideBtn.Position = UDim2.new(1, -85, 0, 10); HideBtn.Size = UDim2.new(0, 35, 0, 35); HideBtn.TextSize = 24
local ResetBtn = createBtn("R", MainFrame, Color3.fromRGB(45, 45, 55))
ResetBtn.Position = UDim2.new(1, -125, 0, 10); ResetBtn.Size = UDim2.new(0, 35, 0, 35)

-- ВКЛАДКИ
local TabHolder = Instance.new("Frame", MainFrame)
TabHolder.Size = UDim2.new(1, -20, 0, 35); TabHolder.Position = UDim2.new(0, 10, 0, 55); TabHolder.BackgroundTransparency = 1; TabHolder.ZIndex = 101
Instance.new("UIListLayout", TabHolder).FillDirection = Enum.FillDirection.Horizontal; TabHolder.UIListLayout.Padding = UDim.new(0, 5)

local function createPage(n)
    local p = Instance.new("ScrollingFrame", MainFrame)
    p.Name = n; p.Position = UDim2.new(0, 10, 0, 100); p.Size = UDim2.new(1, -20, 1, -110); p.BackgroundTransparency = 1; p.ScrollBarThickness = 0; p.ZIndex = 101
    Instance.new("UIListLayout", p).Padding = UDim.new(0, 6); p.Visible = false
    return p
end

local PageMain = createPage("Main"); PageMain.Visible = true
local PageVision = createPage("Vision")
local Tab1 = createBtn("", TabHolder); Tab1.Size = UDim2.new(0.48, 0, 1, 0)
local Tab2 = createBtn("", TabHolder); Tab2.Size = UDim2.new(0.48, 0, 1, 0)

-- КОНТЕНТ (ГЛАВНАЯ)
local r1 = createRow(PageMain); local sInp = createInp("", r1); sInp.Size = UDim2.new(0.48,0,1,0); local jInp = createInp("", r1); jInp.Position = UDim2.new(0.52,0,0,0); jInp.Size = UDim2.new(0.48,0,1,0)
local r2 = createRow(PageMain); local tpBtn = createBtn("", r2); tpBtn.Size = UDim2.new(0.48,0,1,0); local distInp = createInp("", r2); distInp.Position = UDim2.new(0.52,0,0,0); distInp.Size = UDim2.new(0.48,0,1,0)
local r3 = createRow(PageMain); local airBtn = createBtn("", r3); airBtn.Size = UDim2.new(0.48,0,1,0); local noclipBtn = createBtn("", r3); noclipBtn.Position = UDim2.new(0.52,0,0,0); noclipBtn.Size = UDim2.new(0.48,0,1,0)
local r4 = createRow(PageMain); local platBtn = createBtn("", r4); platBtn.Size = UDim2.new(0.48,0,1,0); local ragBtn = createBtn("", r4); ragBtn.Position = UDim2.new(0.52,0,0,0); ragBtn.Size = UDim2.new(0.48,0,1,0)

-- КОНТЕНТ (ВИЗУАЛЫ)
local vr1 = createRow(PageVision); local fbBtn = createBtn("", vr1); fbBtn.Size = UDim2.new(0.48,0,1,0); local nfBtn = createBtn("", vr1); nfBtn.Position = UDim2.new(0.52,0,0,0); nfBtn.Size = UDim2.new(0.48,0,1,0)
local vr2 = createRow(PageVision); local fovBtn = createBtn("", vr2); fovBtn.Size = UDim2.new(0.48,0,1,0); local fInp = createInp("", vr2); fInp.Position = UDim2.new(0.52,0,0,0); fInp.Size = UDim2.new(0.48,0,1,0)
local vr3 = createRow(PageVision); local tpvBtn = createBtn("", vr3); tpvBtn.Size = UDim2.new(1,0,1,0)

local function updateLanguage()
    LangBtn.Text = lang; local t = translations[lang]
    Tab1.Text = t.main; Tab2.Text = t.vision; tpBtn.Text = t.tp; fovBtn.Text = t.fovBtn
    sInp.Text = t.speed; jInp.Text = t.jump; distInp.Text = t.dist; fInp.Text = t.fovInp
end

-- ЛОГИКА
LangBtn.MouseButton1Click:Connect(function() lang = (lang == "RU") and "EN" or "RU"; updateLanguage() end)
Tab1.MouseButton1Click:Connect(function() PageMain.Visible = true; PageVision.Visible = false end)
Tab2.MouseButton1Click:Connect(function() PageMain.Visible = false; PageVision.Visible = true end)
ResetBtn.MouseButton1Click:Connect(function() if player.Character and player.Character:FindFirstChild("Humanoid") then player.Character.Humanoid.WalkSpeed = 16; player.Character.Humanoid.JumpPower = 50 end end)
sInp.FocusLost:Connect(function() if player.Character and player.Character:FindFirstChild("Humanoid") then player.Character.Humanoid.WalkSpeed = tonumber(sInp.Text) or 16 end end)
jInp.FocusLost:Connect(function() if player.Character and player.Character:FindFirstChild("Humanoid") then player.Character.Humanoid.JumpPower = tonumber(jInp.Text) or 50 end end)
distInp.FocusLost:Connect(function() tpDistance = tonumber(distInp.Text) or 10 end)
fInp.FocusLost:Connect(function() currentFOV = tonumber(fInp.Text) or 70 end)
tpBtn.MouseButton1Click:Connect(function() if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then player.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -tpDistance) end end)
airBtn.MouseButton1Click:Connect(function() airJumpEnabled = not airJumpEnabled end)
noclipBtn.MouseButton1Click:Connect(function() noclip = not noclip end)
platBtn.MouseButton1Click:Connect(function() partJump = not partJump end)
ragBtn.MouseButton1Click:Connect(function() antiRagdoll = not antiRagdoll end)
fbBtn.MouseButton1Click:Connect(function() fullBright = not fullBright end)
nfBtn.MouseButton1Click:Connect(function() noFog = not noFog end)
fovBtn.MouseButton1Click:Connect(function() fovActive = not fovActive end)
tpvBtn.MouseButton1Click:Connect(function() thirdPerson = not thirdPerson end)

RunService.RenderStepped:Connect(function()
    local t = translations[lang]; local s = (function(v) return v and t.on or t.off end)
    airBtn.Text = t.aj..": "..s(airJumpEnabled); airBtn.BackgroundColor3 = airJumpEnabled and Color3.fromRGB(0,120,255) or Color3.fromRGB(30,30,38)
    noclipBtn.Text = t.noclip..": "..s(noclip); noclipBtn.BackgroundColor3 = noclip and Color3.fromRGB(0,120,255) or Color3.fromRGB(30,30,38)
    platBtn.Text = t.plat..": "..s(partJump); platBtn.BackgroundColor3 = partJump and Color3.fromRGB(0,120,255) or Color3.fromRGB(30,30,38)
    ragBtn.Text = t.norag..": "..s(antiRagdoll); ragBtn.BackgroundColor3 = antiRagdoll and Color3.fromRGB(0,120,255) or Color3.fromRGB(30,30,38)
    fbBtn.Text = t.fbright..": "..s(fullBright); fbBtn.BackgroundColor3 = fullBright and Color3.fromRGB(0,120,255) or Color3.fromRGB(30,30,38)
    nfBtn.Text = t.nfog..": "..s(noFog); nfBtn.BackgroundColor3 = noFog and Color3.fromRGB(0,120,255) or Color3.fromRGB(30,30,38)
    fovBtn.Text = t.fovBtn..": "..s(fovActive); fovBtn.BackgroundColor3 = fovActive and Color3.fromRGB(0,120,255) or Color3.fromRGB(30,30,38)
    tpvBtn.Text = t.tperson..": "..s(thirdPerson); tpvBtn.BackgroundColor3 = thirdPerson and Color3.fromRGB(0,120,255) or Color3.fromRGB(30,30,38)
    if fullBright then Lighting.Ambient = Color3.new(1,1,1); Lighting.Brightness = 2; Lighting.ClockTime = 14 end
    if noFog then Lighting.FogEnd = 1000000; Lighting.GlobalShadows = false end
    if fovActive then workspace.CurrentCamera.FieldOfView = currentFOV end
    if thirdPerson then player.CameraMaxZoomDistance = 100; player.CameraMinZoomDistance = 0.5 else player.CameraMaxZoomDistance = 12.5 end
end)

RunService.Stepped:Connect(function()
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        if noclip then for _,v in pairs(player.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end end
        if partJump then 
            if not platform then platform = Instance.new("Part", workspace); platform.Size = Vector3.new(10, 1, 10); platform.Anchored = true; platform.Transparency = 0.5; platform.Color = Color3.fromRGB(0, 120, 255) end
            platform.CFrame = player.Character.HumanoidRootPart.CFrame * CFrame.new(0, -3.1, 0)
        elseif platform then platform:Destroy(); platform = nil end
    end
end)

UIS.JumpRequest:Connect(function() if airJumpEnabled and player.Character:FindFirstChildOfClass("Humanoid") then player.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping) end end)
CloseBtn.MouseButton1Click:Connect(function() MainGui:Destroy() end)
HideBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false; local mf = Instance.new("Frame", MainGui); mf.Size = UDim2.new(0,40,0,40); mf.Position = UDim2.new(0.5,-20,0.05,0); mf.BackgroundColor3 = Color3.fromRGB(15,15,20); Instance.new("UICorner", mf); Instance.new("UIStroke", mf).Color = Color3.fromRGB(0,120,255); local b = createBtn("+", mf); b.MouseButton1Click:Connect(function() mf:Destroy(); MainFrame.Visible = true end) end)

updateLanguage()
