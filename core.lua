--[[ CORE — сервисы, GUI, компоненты, утилиты. Оптимизировано под Arceus X ]]

-- ========== СЕРВИСЫ ==========
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local CoreGui          = game:GetService("CoreGui")
local Lighting         = game:GetService("Lighting")
local SoundService     = game:GetService("SoundService")
local HttpService      = game:GetService("HttpService")
local TeleportService  = game:GetService("TeleportService")

local LP     = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local M = {}

M.Players = Players
M.RunService = RunService
M.UserInputService = UserInputService
M.TweenService = TweenService
M.Lighting = Lighting
M.SoundService = SoundService
M.HttpService = HttpService
M.TeleportService = TeleportService
M.LP = LP
M.Camera = Camera

-- ========== ФОЛЛБЭКИ ЭКЗЕКУТОРА ==========
local HAS_GETHUI = (type(gethui) == "function")
local HAS_PROTECT_GUI = (type(protect_gui) == "function")
local HAS_SYN = (type(syn) == "table" and type(syn.protect_gui) == "function")

local function protectgui(g)
    if HAS_SYN then
        local ok = pcall(function() syn.protect_gui(g) end)
        if ok then return end
    end
    if HAS_PROTECT_GUI then
        local ok = pcall(function() protect_gui(g) end)
        if ok then return end
    end
    if HAS_GETHUI then
        local ok, parent = pcall(function() return gethui() end)
        if ok and parent then
            g.Parent = parent
            return
        end
    end
end

local function getGuiParent()
    if HAS_GETHUI then
        local ok, parent = pcall(function() return gethui() end)
        if ok and parent then return parent end
    end
    return CoreGui
end

-- ========== СИСТЕМА СОЕДИНЕНИЙ ==========
function M.NewConnBag()
    local bag = { conns = {}, instances = {} }
    function bag:add(conn) table.insert(self.conns, conn); return conn end
    function bag:keep(inst) table.insert(self.instances, inst); return inst end
    function bag:destroy()
        for _, c in ipairs(self.conns) do pcall(function() c:Disconnect() end) end
        for _, i in ipairs(self.instances) do pcall(function() i:Destroy() end) end
        self.conns = {}; self.instances = {}
    end
    return bag
end

-- ========== ЗВУКИ ==========
local Sound = { enabled = true, volume = 1, sounds = {} }
M.Sound = Sound

local SOUND_IDS = {
    farm_complete = "rbxassetid://6042053626",
    alert_player  = "rbxassetid://5157632841",
    default       = "rbxassetid://6042053626",
}

function M.PlaySound(name, volume)
    if not Sound.enabled then return end
    if not Sound.sounds[name] then
        local s = Instance.new("Sound")
        s.SoundId = SOUND_IDS[name] or SOUND_IDS.default
        s.Volume = Sound.volume
        s.Parent = SoundService
        Sound.sounds[name] = s
    end
    local s = Sound.sounds[name]
    if volume then s.Volume = volume end
    pcall(function() s:Play() end)
end

function M.PlayBeepSequence()
    if not Sound.enabled then return end
    for i = 1, 3 do
        local s = Instance.new("Sound")
        s.SoundId = SOUND_IDS.default
        s.Volume = 0.5
        s.PlaybackSpeed = 1 + (i * 0.1)
        s.Parent = SoundService
        s:Play()
        task.delay(2, function() s:Destroy() end)
        task.wait(0.15)
    end
end

-- ========== ПЛАТФОРМА ==========
local IS_MOBILE = UserInputService.TouchEnabled
M.IS_MOBILE = IS_MOBILE
M.HAS_GETHUI = HAS_GETHUI
M.HAS_PROTECT_GUI = HAS_PROTECT_GUI

-- ========== GUI ==========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RustedHub_" .. tostring(math.random(1000, 9999))
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
pcall(function() ScreenGui.IgnoreGuiInset = true end)

protectgui(ScreenGui)

if not ScreenGui.Parent then
    local parent = getGuiParent()
    if parent then
        pcall(function() ScreenGui.Parent = parent end)
    end
end

if not ScreenGui.Parent then
    pcall(function() ScreenGui.Parent = CoreGui end)
end

if not ScreenGui.Parent then
    pcall(function() ScreenGui.Parent = LP:WaitForChild("PlayerGui", 5) end)
end

if not ScreenGui.Parent then
    error("[Rusted] Не удалось создать ScreenGui. Экзекутор блокирует GUI.")
end

M.ScreenGui = ScreenGui

-- Защита GUI от удаления
task.spawn(function()
    while true do
        task.wait(5)
        if ScreenGui and not ScreenGui.Parent then
            local parent = getGuiParent()
            if parent then
                pcall(function() ScreenGui.Parent = parent end)
            end
        end
    end
end)

-- ========== РАЗМЕРЫ ==========
local viewportX = Camera.ViewportSize.X
local viewportY = Camera.ViewportSize.Y

local MENU_W, MENU_H
if IS_MOBILE then
    MENU_W = math.clamp(viewportX * 0.95, 320, 480)
    MENU_H = math.clamp(viewportY * 0.7, 300, 450)
else
    MENU_W = math.min(600, viewportX * 0.9)
    MENU_H = math.min(420, viewportY * 0.8)
end

M.MENU_W = MENU_W
M.MENU_H = MENU_H

-- ========== ГЛАВНОЕ ОКНО ==========
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, MENU_W, 0, MENU_H)
Main.Position = UDim2.new(0.5, -MENU_W / 2, 0.5, -MENU_H / 2)
Main.BackgroundColor3 = Color3.fromRGB(28, 20, 45)
Main.BorderSizePixel = 0
Main.Active = true
Main.Visible = true
Main.Parent = ScreenGui
M.Main = Main

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(138, 79, 255)
MainStroke.Thickness = 1
MainStroke.Parent = Main

-- Заголовок
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Color3.fromRGB(38, 26, 58)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -60, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Rusted Hub"
Title.TextColor3 = Color3.fromRGB(230, 230, 240)
Title.TextSize = 14
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

-- Кнопка сворачивания
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 34, 0, 34)
MinimizeBtn.Position = UDim2.new(1, -42, 0, 3)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(138, 79, 255)
MinimizeBtn.Text = "—"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.TextSize = 20
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.Parent = TitleBar

local MinimizeCorner = Instance.new("UICorner")
MinimizeCorner.CornerRadius = UDim.new(0, 8)
MinimizeCorner.Parent = MinimizeBtn

-- ========== ВКЛАДКИ ==========
local TAB_BAR_W = IS_MOBILE and 90 or 130
local CONTENT_X_OFFSET = TAB_BAR_W + 10

local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(0, TAB_BAR_W, 1, -50)
TabBar.Position = UDim2.new(0, 5, 0, 45)
TabBar.BackgroundColor3 = Color3.fromRGB(32, 22, 50)
TabBar.BorderSizePixel = 0
TabBar.Parent = Main

local TabBarCorner = Instance.new("UICorner")
TabBarCorner.CornerRadius = UDim.new(0, 8)
TabBarCorner.Parent = TabBar

local TabLayout = Instance.new("UIListLayout")
TabLayout.Padding = UDim.new(0, 5)
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Parent = TabBar

local TabPad = Instance.new("UIPadding")
TabPad.PaddingTop = UDim.new(0, 8)
TabPad.PaddingLeft = UDim.new(0, 5)
TabPad.PaddingRight = UDim.new(0, 5)
TabPad.Parent = TabBar

local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -(CONTENT_X_OFFSET + 5), 1, -50)
ContentArea.Position = UDim2.new(0, CONTENT_X_OFFSET, 0, 45)
ContentArea.BackgroundColor3 = Color3.fromRGB(32, 22, 50)
ContentArea.BorderSizePixel = 0
ContentArea.Parent = Main

local ContentCorner = Instance.new("UICorner")
ContentCorner.CornerRadius = UDim.new(0, 8)
ContentCorner.Parent = ContentArea

local ContentPad = Instance.new("UIPadding")
ContentPad.PaddingTop = UDim.new(0, 8)
ContentPad.PaddingLeft = UDim.new(0, 8)
ContentPad.PaddingRight = UDim.new(0, 8)
ContentPad.PaddingBottom = UDim.new(0, 8)
ContentPad.Parent = ContentArea

-- ========== ПЛАВАЮЩАЯ КНОПКА R ==========
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "RustedToggle"
ToggleButton.Size = UDim2.new(0, 55, 0, 55)
ToggleButton.Position = UDim2.new(0, 15, 0.5, -27)
ToggleButton.BackgroundColor3 = Color3.fromRGB(138, 79, 255)
ToggleButton.Text = "R"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 24
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.BorderSizePixel = 0
ToggleButton.Active = true
ToggleButton.Visible = false
ToggleButton.Parent = ScreenGui
M.ToggleButton = ToggleButton

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(1, 0)
ToggleCorner.Parent = ToggleButton

local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Color = Color3.fromRGB(255, 255, 255)
ToggleStroke.Thickness = 2
ToggleStroke.Transparency = 0.5
ToggleStroke.Parent = ToggleButton

-- ========== КНОПКА E (INTERACT) ==========
local EBtn = Instance.new("TextButton")
EBtn.Name = "InteractBtn"
EBtn.Size = UDim2.new(0, 55, 0, 55)
EBtn.Position = UDim2.new(0, 15, 0.5, 40)
EBtn.BackgroundColor3 = Color3.fromRGB(60, 130, 60)
EBtn.Text = "E"
EBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
EBtn.TextSize = 24
EBtn.Font = Enum.Font.GothamBold
EBtn.BorderSizePixel = 0
EBtn.Active = true
EBtn.Visible = false
EBtn.Parent = ScreenGui
M.EBtn = EBtn

local ECorner = Instance.new("UICorner")
ECorner.CornerRadius = UDim.new(1, 0)
ECorner.Parent = EBtn

local EStroke = Instance.new("UIStroke")
EStroke.Color = Color3.fromRGB(255, 255, 255)
EStroke.Thickness = 2
EStroke.Transparency = 0.5
EStroke.Parent = EBtn

-- Синхронизация видимости E кнопки
local function SyncEBtn()
    local followActive = _G.RustedFollowActive == true
    EBtn.Visible = (not Main.Visible) and followActive
end

Main:GetPropertyChangedSignal("Visible"):Connect(SyncEBtn)

EBtn.MouseButton1Click:Connect(function()
    if _G.RustedOpenCrate then
        _G.RustedOpenCrate()
    end
end)

-- ========== ПЕРЕТАСКИВАНИЕ ОКНА ==========
local windowDragging = false
local windowDragStart = nil
local windowStartPos = nil

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        windowDragging = true
        windowDragStart = input.Position
        windowStartPos = Main.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if windowDragging and (input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - windowDragStart
        Main.Position = UDim2.new(
            windowStartPos.X.Scale, windowStartPos.X.Offset + delta.X,
            windowStartPos.Y.Scale, windowStartPos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        windowDragging = false
    end
end)

-- ========== КНОПКА R: ПЕРЕТАСКИВАНИЕ И ТАП ==========
local toggleDragging = false
local toggleMoved = false
local toggleDragStart = nil
local toggleStartPos = nil

ToggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        toggleDragging = true
        toggleMoved = false
        toggleDragStart = input.Position
        toggleStartPos = ToggleButton.Position
    end
end)

ToggleButton.InputChanged:Connect(function(input)
    if not toggleDragging or not toggleDragStart then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement
    and input.UserInputType ~= Enum.UserInputType.Touch then return end

    local delta = input.Position - toggleDragStart
    if delta.Magnitude > 8 then
        toggleMoved = true
        ToggleButton.Position = UDim2.new(
            toggleStartPos.X.Scale, toggleStartPos.X.Offset + delta.X,
            toggleStartPos.Y.Scale, toggleStartPos.Y.Offset + delta.Y
        )
    end
end)

ToggleButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        if not toggleMoved then
            Main.Visible = true
            ToggleButton.Visible = false
            SyncEBtn()
        end
        toggleDragging = false
        toggleDragStart = nil
    end
end)

MinimizeBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
    ToggleButton.Visible = true
    SyncEBtn()
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        if Main.Visible then
            Main.Visible = false
            ToggleButton.Visible = true
        else
            Main.Visible = true
            ToggleButton.Visible = false
        end
        SyncEBtn()
    end
end)

-- ========== КОМПОНЕНТЫ ==========
local Tabs = {}
M.Tabs = Tabs

function M.CreateTab(name)
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(1, 0, 0, 32)
    tabBtn.BackgroundColor3 = Color3.fromRGB(45, 32, 68)
    tabBtn.Text = name
    tabBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
    tabBtn.TextSize = IS_MOBILE and 11 or 13
    tabBtn.Font = Enum.Font.Gotham
    tabBtn.BorderSizePixel = 0
    tabBtn.Parent = TabBar
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6); c.Parent = tabBtn

    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 6
    page.ScrollBarImageColor3 = Color3.fromRGB(138, 79, 255)
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.Parent = ContentArea

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = page

    Tabs[name] = { btn = tabBtn, page = page }

    tabBtn.MouseButton1Click:Connect(function()
        for _, t in pairs(Tabs) do
            t.page.Visible = false
            t.btn.BackgroundColor3 = Color3.fromRGB(45, 32, 68)
            t.btn.TextColor3 = Color3.fromRGB(200, 200, 210)
        end
        page.Visible = true
        tabBtn.BackgroundColor3 = Color3.fromRGB(138, 79, 255)
        tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
    return page
end

function M.CreateButton(parent, text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -4, 0, IS_MOBILE and 34 or 32)
    btn.BackgroundColor3 = Color3.fromRGB(45, 32, 68)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(220, 220, 230)
    btn.TextSize = IS_MOBILE and 11 or 13
    btn.Font = Enum.Font.Gotham
    btn.BorderSizePixel = 0
    btn.Parent = parent
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6); c.Parent = btn

    btn.MouseButton1Click:Connect(function()
        local ok, err = pcall(callback)
        if not ok then warn("[Rusted] Button error: " .. tostring(err)) end
    end)
    return btn
end

function M.CreateToggle(parent, text, default, callback)
    local state = default or false
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -4, 0, IS_MOBILE and 34 or 32)
    btn.BackgroundColor3 = Color3.fromRGB(45, 32, 68)
    btn.Text = text .. "  [" .. (state and "ON" or "OFF") .. "]"
    btn.TextColor3 = state and Color3.fromRGB(100, 200, 120) or Color3.fromRGB(180, 180, 190)
    btn.TextSize = IS_MOBILE and 11 or 12
    btn.Font = Enum.Font.Gotham
    btn.BorderSizePixel = 0
    btn.Parent = parent
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6); c.Parent = btn

    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = text .. "  [" .. (state and "ON" or "OFF") .. "]"
        btn.TextColor3 = state and Color3.fromRGB(100, 200, 120) or Color3.fromRGB(180, 180, 190)
        local ok, err = pcall(callback, state)
        if not ok then warn("[Rusted] Toggle error: " .. tostring(err)) end
    end)
    return btn
end

function M.CreateSlider(parent, text, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -4, 0, 50)
    frame.BackgroundColor3 = Color3.fromRGB(45, 32, 68)
    frame.BorderSizePixel = 0
    frame.Parent = parent
    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(0, 6); fc.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, 22)
    label.Position = UDim2.new(0, 10, 0, 2)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. default
    label.TextColor3 = Color3.fromRGB(220, 220, 230)
    label.TextSize = IS_MOBILE and 11 or 12
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -20, 0, 10)
    bar.Position = UDim2.new(0, 10, 0, 32)
    bar.BackgroundColor3 = Color3.fromRGB(30, 20, 48)
    bar.BorderSizePixel = 0
    bar.Parent = frame
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(1, 0); bc.Parent = bar

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(138, 79, 255)
    fill.BorderSizePixel = 0
    fill.Parent = bar
    local fillc = Instance.new("UICorner")
    fillc.CornerRadius = UDim.new(1, 0); fillc.Parent = fill

    local handle = Instance.new("Frame")
    handle.Size = UDim2.new(0, 18, 0, 18)
    handle.AnchorPoint = Vector2.new(0.5, 0.5)
    handle.Position = UDim2.new((default - min) / (max - min), 0, 0.5, 0)
    handle.BackgroundColor3 = Color3.fromRGB(200, 180, 255)
    handle.BorderSizePixel = 0
    handle.Parent = bar
    local hc = Instance.new("UICorner")
    hc.CornerRadius = UDim.new(1, 0); hc.Parent = handle

    local dragging = false
    local function Update(input)
        local rel = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (max - min) * rel)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        handle.Position = UDim2.new(rel, 0, 0.5, 0)
        label.Text = text .. ": " .. val
        pcall(callback, val)
    end

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            Update(input)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            Update(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- ESP folder
local espFolder = Instance.new("Folder")
espFolder.Name = "RustedESP"
espFolder.Parent = ScreenGui
M.espFolder = espFolder

function M.NewBox()
    local b = Instance.new("BoxHandleAdornment")
    b.Size = Vector3.new(4, 5, 4)
    b.AlwaysOnTop = true
    b.ZIndex = 5
    b.Transparency = 0.5
    b.Parent = espFolder
    return b
end

function M.KillBox(b)
    if b then pcall(function() b:Destroy() end) end
end

print("[Rusted Core] Загружен. Mobile:", IS_MOBILE, "| gethui:", HAS_GETHUI)

return M
