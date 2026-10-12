--[[ CORE — сервисы, GUI, компоненты, утилиты ]]

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

local function protectgui(g)
    if syn and syn.protect_gui then syn.protect_gui(g)
    elseif protect_gui then protect_gui(g)
    elseif gethui then g.Parent = gethui() end
end

local function getGuiParent()
    if gethui then return gethui() end
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

-- ========== ОПРЕДЕЛЕНИЕ МОБИЛЬНОГО ==========
local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
M.IS_MOBILE = IS_MOBILE

-- ========== GUI ==========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RustedHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
ScreenGui.IgnoreGuiInset = true
protectgui(ScreenGui)
if not ScreenGui.Parent then ScreenGui.Parent = getGuiParent() end
M.ScreenGui = ScreenGui

-- Размер меню — адаптивный под мобилу
local MENU_W, MENU_H
if IS_MOBILE then
    MENU_W = math.min(500, workspace.CurrentCamera.ViewportSize.X * 0.95)
    MENU_H = math.min(400, workspace.CurrentCamera.ViewportSize.Y * 0.7)
else
    MENU_W = 600
    MENU_H = 420
end

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, MENU_W, 0, MENU_H)
Main.Position = UDim2.new(0.5, -MENU_W / 2, 0.5, -MENU_H / 2)
Main.BackgroundColor3 = Color3.fromRGB(28, 20, 45)
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = ScreenGui
M.Main = Main

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(138, 79, 255)
MainStroke.Parent = Main

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
Title.Text = "Rusted Hub  |  Menu"
Title.TextColor3 = Color3.fromRGB(230, 230, 240)
Title.TextSize = 14
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

-- Кнопка сворачивания (крестик в углу)
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
MinimizeBtn.Position = UDim2.new(1, -40, 0, 5)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(138, 79, 255)
MinimizeBtn.Text = "─"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.TextSize = 18
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.Parent = TitleBar

local MinimizeCorner = Instance.new("UICorner")
MinimizeCorner.CornerRadius = UDim.new(0, 6)
MinimizeCorner.Parent = MinimizeBtn

local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(0, 130, 1, -50)
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
ContentArea.Size = UDim2.new(1, -150, 1, -50)
ContentArea.Position = UDim2.new(0, 140, 0, 45)
ContentArea.BackgroundColor3 = Color3.fromRGB(32, 22, 50)
ContentArea.BorderSizePixel = 0
ContentArea.Parent = Main

local ContentCorner = Instance.new("UICorner")
ContentCorner.CornerRadius = UDim.new(0, 8)
ContentCorner.Parent = ContentArea

local ContentPad = Instance.new("UIPadding")
ContentPad.PaddingTop = UDim.new(0, 10)
ContentPad.PaddingLeft = UDim.new(0, 10)
ContentPad.PaddingRight = UDim.new(0, 10)
ContentPad.PaddingBottom = UDim.new(0, 10)
ContentPad.Parent = ContentArea

-- ========== ПЛАВАЮЩАЯ КНОПКА-КРУЖОК ==========
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

-- ========== ПЕРЕТАСКИВАНИЕ ОКНА ==========
local dragging, dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = Main.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)

-- ========== ПЕРЕТАСКИВАНИЕ КРУЖКА ==========
local toggleDrag = false
local toggleDragStart = nil
local toggleStartPos = nil

ToggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        toggleDrag = false
        toggleDragStart = input.Position
        toggleStartPos = ToggleButton.Position
    end
end)

ToggleButton.InputChanged:Connect(function(input)
    if toggleDragStart and (input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - toggleDragStart
        if delta.Magnitude > 5 then
            toggleDrag = true
            ToggleButton.Position = UDim2.new(
                toggleStartPos.X.Scale, toggleStartPos.X.Offset + delta.X,
                toggleStartPos.Y.Scale, toggleStartPos.Y.Offset + delta.Y)
        end
    end
end)

ToggleButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        -- Если не перетаскивали — это клик
        if not toggleDrag then
            Main.Visible = true
            ToggleButton.Visible = false
        end
        toggleDragStart = nil
    end
end)

-- Кнопка сворачивания
MinimizeBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
    ToggleButton.Visible = true
end)

-- Хоткей RightShift (ПК)
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
    end
end)

-- ========== КОМПОНЕНТЫ UI ==========
local Tabs = {}
M.Tabs = Tabs

function M.CreateTab(name)
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(1, 0, 0, 30)
    tabBtn.BackgroundColor3 = Color3.fromRGB(45, 32, 68)
    tabBtn.Text = name
    tabBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
    tabBtn.TextSize = 13
    tabBtn.Font = Enum.Font.Gotham
    tabBtn.BorderSizePixel = 0
    tabBtn.Parent = TabBar
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6); c.Parent = tabBtn

    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 4
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
    btn.Size = UDim2.new(1, -8, 0, 32)
    btn.BackgroundColor3 = Color3.fromRGB(45, 32, 68)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(220, 220, 230)
    btn.TextSize = 13
    btn.Font = Enum.Font.Gotham
    btn.BorderSizePixel = 0
    btn.Parent = parent
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6); c.Parent = btn

    btn.MouseEnter:Connect(function()
        if not IS_MOBILE then
            TweenService:Create(btn, TweenInfo.new(0.15), {
                BackgroundColor3 = Color3.fromRGB(65, 45, 95)}):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if not IS_MOBILE then
            TweenService:Create(btn, TweenInfo.new(0.15), {
                BackgroundColor3 = Color3.fromRGB(45, 32, 68)}):Play()
        end
    end)
    btn.MouseButton1Click:Connect(function()
        local ok, err = pcall(callback)
        if not ok then warn("[Rusted] Button error: " .. tostring(err)) end
    end)
    return btn
end

function M.CreateToggle(parent, text, default, callback)
    local state = default or false
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -8, 0, 32)
    btn.BackgroundColor3 = Color3.fromRGB(45, 32, 68)
    btn.Text = text .. "  [" .. (state and "ON" or "OFF") .. "]"
    btn.TextColor3 = state and Color3.fromRGB(100, 200, 120) or Color3.fromRGB(180, 180, 190)
    btn.TextSize = 12
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
    frame.Size = UDim2.new(1, -8, 0, 50)
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
    label.TextSize = 12
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -20, 0, 8)
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

    local dragging = false
    local function Update(input)
        local rel = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (max - min) * rel)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        label.Text = text .. ": " .. val
        pcall(callback, val)
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; Update(input)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then Update(input) end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
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

return M
