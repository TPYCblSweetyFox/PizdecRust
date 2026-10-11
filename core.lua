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

-- ========== GUI ==========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RustedHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
protectgui(ScreenGui)
if not ScreenGui.Parent then ScreenGui.Parent = getGuiParent() end
M.ScreenGui = ScreenGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 600, 0, 420)
Main.Position = UDim2.new(0.5, -300, 0.5, -210)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = ScreenGui

local mc = Instance.new("UICorner")
mc.CornerRadius = UDim.new(0, 10)
mc.Parent = Main
local ms = Instance.new("UIStroke")
ms.Color = Color3.fromRGB(80, 80, 100)
ms.Parent = Main

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main
local tbc = Instance.new("UICorner")
tbc.CornerRadius = UDim.new(0, 10)
tbc.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -30, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Rusted Hub v2  |  RightShift — свернуть"
Title.TextColor3 = Color3.fromRGB(230, 230, 240)
Title.TextSize = 14
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(0, 130, 1, -50)
TabBar.Position = UDim2.new(0, 5, 0, 45)
TabBar.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
TabBar.BorderSizePixel = 0
TabBar.Parent = Main
local tbarc = Instance.new("UICorner")
tbarc.CornerRadius = UDim.new(0, 8)
tbarc.Parent = TabBar

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
ContentArea.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
ContentArea.BorderSizePixel = 0
ContentArea.Parent = Main
local cac = Instance.new("UICorner")
cac.CornerRadius = UDim.new(0, 8)
cac.Parent = ContentArea
local cap = Instance.new("UIPadding")
cap.PaddingTop = UDim.new(0, 10)
cap.PaddingLeft = UDim.new(0, 10)
cap.PaddingRight = UDim.new(0, 10)
cap.PaddingBottom = UDim.new(0, 10)
cap.Parent = ContentArea

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        Main.Visible = not Main.Visible
    end
end)

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

-- ========== КОМПОНЕНТЫ UI ==========
local Tabs = {}
M.Tabs = Tabs

function M.CreateTab(name)
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(1, 0, 0, 30)
    tabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
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
    page.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 100)
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
            t.btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
            t.btn.TextColor3 = Color3.fromRGB(200, 200, 210)
        end
        page.Visible = true
        tabBtn.BackgroundColor3 = Color3.fromRGB(60, 90, 180)
        tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
    return page
end

function M.CreateButton(parent, text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -8, 0, 32)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(220, 220, 230)
    btn.TextSize = 13
    btn.Font = Enum.Font.Gotham
    btn.BorderSizePixel = 0
    btn.Parent = parent
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6); c.Parent = btn

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(60, 60, 75)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(45, 45, 55)}):Play()
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
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
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
    frame.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
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
    bar.Size = UDim2.new(1, -20, 0, 6)
    bar.Position = UDim2.new(0, 10, 0, 32)
    bar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    bar.BorderSizePixel = 0
    bar.Parent = frame
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(1, 0); bc.Parent = bar

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(80, 140, 220)
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
