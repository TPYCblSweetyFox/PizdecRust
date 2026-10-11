--[[ MAIN — вкладки ]]

local BASE_URL = "https://raw.githubusercontent.com/TPYCblSweetyFox/PizdecRust/main/"
local CACHE_BUST = "?v=" .. tostring(math.floor(tick() * 1000))

local CORE = loadstring(game:HttpGet(BASE_URL .. "core.lua" .. CACHE_BUST))()
local F = loadstring(game:HttpGet(BASE_URL .. "features.lua" .. CACHE_BUST))(CORE)

local Sound = CORE.Sound
local CreateTab = CORE.CreateTab
local CreateButton = CORE.CreateButton
local CreateToggle = CORE.CreateToggle
local CreateSlider = CORE.CreateSlider
local Tabs = CORE.Tabs
local LP = CORE.LP
local Players = CORE.Players
local TeleportService = CORE.TeleportService
local ESP = F.ESP
local Aim = F.Aim
local AutoFarm = F.AutoFarm
local WallLoot = F.WallLoot
local CodeLock = F.CodeLock
local Watcher = F.Watcher
local LookTracer = F.LookTracer
local Noclip = F.Noclip
local WallClimb = F.WallClimb
local Freecam = F.Freecam
local VoidTP = F.VoidTP
local HideUnderground = F.HideUnderground

local function Rejoin()
    if queue_on_teleport then
        queue_on_teleport([[
            loadstring(game:HttpGet("https://raw.githubusercontent.com/TPYCblSweetyFox/PizdecRust/main/main.lua?v=" .. tostring(math.floor(tick() * 1000))))()
        ]])
    end
    TeleportService:Teleport(game.PlaceId, LP)
end

local MainTab = CreateTab("Главное")
CreateButton(MainTab, "Переподключиться (Rejoin)", Rejoin)

local VisualTab = CreateTab("Визуал")
CreateToggle(VisualTab, "ESP игроков", false, F.TogglePlayerESP)
CreateToggle(VisualTab, "Радужный ESP", false, F.ToggleRainbow)
CreateToggle(VisualTab, "ESP ботов", false, F.ToggleBotESP)
CreateToggle(VisualTab, "ESP ящиков", false, F.ToggleBoxESP)
CreateToggle(VisualTab, "ESP руд", false, F.ToggleOreESP)
CreateToggle(VisualTab, "ESP RT", false, F.ToggleRTESP)
CreateToggle(VisualTab, "Радар", false, F.ToggleRadar)
CreateToggle(VisualTab, "Трейсер взгляда игроков", false, F.ToggleLookTracer)
CreateSlider(VisualTab, "ESP игроков макс дистанция", 100, 3000, 1200, function(v) ESP.maxDist = v end)
CreateSlider(VisualTab, "ESP ботов макс дистанция", 100, 2000, 600, function(v) ESP.botMaxDist = v end)
CreateSlider(VisualTab, "ESP ботов лимит", 5, 100, 30, function(v) ESP.botLimit = v end)
CreateSlider(VisualTab, "Трейсер длина", 50, 1000, 500, function(v) LookTracer.length = v end)
CreateSlider(VisualTab, "Радар дальность", 50, 2000, 500, function(v) ESP.range = v end)
CreateToggle(VisualTab, "Ночное видение", false, F.ToggleNightVision)
CreateToggle(VisualTab, "Убрать траву и листву", false, F.ToggleEnvClean)

local MoveTab = CreateTab("Мувмент")
CreateToggle(MoveTab, "Бесконечный прыжок", false, F.ToggleInfJump)
CreateToggle(MoveTab, "Полёт (WASD + Space/Ctrl)", false, F.ToggleFly)
CreateToggle(MoveTab, "Wall Climb (пробел у стены)", false, F.ToggleWallClimb)
CreateSlider(MoveTab, "Wall Climb скорость", 10, 150, 45, function(v) WallClimb.speed = v end)
CreateToggle(MoveTab, "Ускорение (WalkSpeed = 100)", false, F.ToggleWS)
CreateToggle(MoveTab, "Высокий прыжок (JumpPower = 200)", false, function(s)
    F.SetJPValue(200)
    F.ToggleJP(s)
end)
CreateToggle(MoveTab, "Noclip (платформа)", false, F.ToggleHardNoclip)
CreateSlider(MoveTab, "Скорость ноклипа", 30, 400, 120, function(v) Noclip.speed = v end)
CreateToggle(MoveTab, "Freecam (клавиша F)", false, F.ToggleFreecam)
CreateSlider(MoveTab, "Скорость Freecam", 10, 300, 60, function(v) Freecam.speed = v end)
CreateToggle(MoveTab, "Убрать урон от падения", false, F.ToggleFallDamage)
CreateToggle(MoveTab, "Спасение из-под карты", true, F.ToggleVoidTP)
CreateSlider(MoveTab, "Порог Y", -500, -10, -80, function(v) VoidTP.threshold = v end)
CreateSlider(MoveTab, "Высота возврата", 0, 200, 5, function(v) VoidTP.targetY = v end)
CreateToggle(MoveTab, "Кидать на SpawnLocation", false, function(s) VoidTP.useSpawn = s end)

local AimTab = CreateTab("Аим")
CreateToggle(AimTab, "Silent Aim (ПКМ)", false, F.ToggleSilentAim)
CreateToggle(AimTab, "Aimlock (ПКМ)", false, F.ToggleAimlock)
CreateToggle(AimTab, "Показывать FOV круг", false, F.ToggleFovVisible)
local PartBtn = CreateButton(AimTab, "Цель: Head", function() end)
local partIndex = 1
local partsList = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}
PartBtn.MouseButton1Click:Connect(function()
    partIndex = (partIndex % #partsList) + 1
    Aim.part = partsList[partIndex]
    PartBtn.Text = "Цель: " .. Aim.part
end)
CreateSlider(AimTab, "FOV", 30, 500, 150, function(v) Aim.fov = v end)
CreateSlider(AimTab, "Плавность аимлока", 0, 95, 25, function(v) Aim.smooth = v / 100 end)
CreateToggle(AimTab, "Режим удержания", true, function(s) Aim.holdKey = s end)
CreateToggle(AimTab, "Проверка видимости", true, function(s) Aim.visible = s end)

local PlayerTab = CreateTab("Игроки")
local massFrame = Instance.new("Frame")
massFrame.Size = UDim2.new(1, -8, 0, 32)
massFrame.BackgroundTransparency = 1
massFrame.Parent = PlayerTab
CreateButton(massFrame, "ОТПРАВИТЬ ВСЕХ В КОСМОС", F.SendAllToSpace)

local listFrame = Instance.new("Frame")
listFrame.Size = UDim2.new(1, -8, 0, 0)
listFrame.AutomaticSize = Enum.AutomaticSize.Y
listFrame.BackgroundTransparency = 1
listFrame.Parent = PlayerTab
local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 4)
listLayout.Parent = listFrame

local function RefreshPlayerList()
    for _, c in ipairs(listFrame:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP then
            CreateButton(listFrame, "TP -> " .. plr.Name, function() F.TeleportTo(plr.Name) end)
            local spaceBtn = Instance.new("TextButton")
            spaceBtn.Size = UDim2.new(1, -8, 0, 28)
            spaceBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 140)
            spaceBtn.Text = "В КОСМОС >> " .. plr.Name
            spaceBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            spaceBtn.TextSize = 13
            spaceBtn.Font = Enum.Font.GothamBold
            spaceBtn.BorderSizePixel = 0
            spaceBtn.Parent = listFrame
            local sc = Instance.new("UICorner")
            sc.CornerRadius = UDim.new(0, 6)
            sc.Parent = spaceBtn
            spaceBtn.MouseButton1Click:Connect(function() F.SendToSpace(plr) end)
        end
    end
end

RefreshPlayerList()
Players.PlayerAdded:Connect(function() task.wait(0.5) RefreshPlayerList() end)
Players.PlayerRemoving:Connect(function() task.wait(0.5) RefreshPlayerList() end)

local FarmTab = CreateTab("Фарм")
CreateToggle(FarmTab, "Автофарм (руды)", false, F.ToggleAutoFarm)

local ModeBtn = CreateButton(FarmTab, "Режим: Пешком", function() end)
local modes = {"walk", "fly"}
local modeLabels = {walk = "Пешком", fly = "Полёт"}
local modeIdx = 1
ModeBtn.MouseButton1Click:Connect(function()
    modeIdx = (modeIdx % #modes) + 1
    AutoFarm.mode = modes[modeIdx]
    ModeBtn.Text = "Режим: " .. modeLabels[AutoFarm.mode]
end)

CreateSlider(FarmTab, "Скорость", 10, 200, 40, function(v) AutoFarm.speed = v end)
CreateSlider(FarmTab, "Высота полёта", 2, 50, 5, function(v) AutoFarm.flyHeight = v end)
CreateSlider(FarmTab, "Дистанция добычи", 5, 30, 12, function(v) AutoFarm.reachDist = v end)
CreateSlider(FarmTab, "Время добычи", 1, 15, 3, function(v) AutoFarm.mineTime = v end)
CreateSlider(FarmTab, "Радиус поиска", 100, 2000, 500, function(v) AutoFarm.scanRange = v end)
CreateToggle(FarmTab, "Копать: Металл", true, function(s) AutoFarm.targetTypes.metal = s end)
CreateToggle(FarmTab, "Копать: Сера", true, function(s) AutoFarm.targetTypes.sulfur = s end)
CreateToggle(FarmTab, "Копать: Камень", true, function(s) AutoFarm.targetTypes.stone = s end)

local timeLimitBtn = CreateButton(FarmTab, "Лимит времени: выкл", function() end)
local timeOptions = {0, 5, 10, 15, 30, 60}
local timeIdx = 1
timeLimitBtn.MouseButton1Click:Connect(function()
    timeIdx = (timeIdx % #timeOptions) + 1
    local v = timeOptions[timeIdx]
    AutoFarm.timeLimit = v
    timeLimitBtn.Text = v > 0 and ("Лимит времени: " .. v .. " мин") or "Лимит времени: выкл"
end)

local killsLimitBtn = CreateButton(FarmTab, "Лимит ресурсов: выкл", function() end)
local killsOptions = {0, 50, 100, 200, 500, 1000}
local killsIdx = 1
killsLimitBtn.MouseButton1Click:Connect(function()
    killsIdx = (killsIdx % #killsOptions) + 1
    local v = killsOptions[killsIdx]
    AutoFarm.killsLimit = v
    killsLimitBtn.Text = v > 0 and ("Лимит ресурсов: " .. v .. " шт") or "Лимит ресурсов: выкл"
end)

CreateSlider(FarmTab, "Кастомный лимит времени", 0, 240, 0, function(v)
    if v > 0 then
        AutoFarm.timeLimit = v
        timeLimitBtn.Text = "Лимит времени: " .. v .. " мин"
    end
end)
CreateSlider(FarmTab, "Кастомный лимит ресурсов", 0, 5000, 0, function(v)
    if v > 0 then
        AutoFarm.killsLimit = v
        killsLimitBtn.Text = "Лимит ресурсов: " .. v .. " шт"
    end
end)

CreateToggle(FarmTab, "Детектор игроков", false, function(s)
    AutoFarm.playerDetect = s
    print("[Rusted AutoFarm] Детектор игроков: " .. (s and "вкл" or "выкл"))
end)

local playerActionBtn = CreateButton(FarmTab, "Действие: Пауза", function() end)
local playerActions = {"pause", "stop", "alert"}
local playerActionLabels = {pause = "Пауза", stop = "Стоп", alert = "Тревога"}
local playerActionIdx = 1
playerActionBtn.MouseButton1Click:Connect(function()
    playerActionIdx = (playerActionIdx % #playerActions) + 1
    AutoFarm.playerAction = playerActions[playerActionIdx]
    playerActionBtn.Text = "Действие: " .. playerActionLabels[AutoFarm.playerAction]
end)

CreateSlider(FarmTab, "Радиус детектора", 30, 500, 150, function(v) AutoFarm.playerRadius = v end)
CreateSlider(FarmTab, "Пауза после ухода", 1, 60, 5, function(v) AutoFarm.playerStopDelay = v end)
CreateToggle(FarmTab, "Нырок под землю", false, F.ToggleHideUnderground)

CreateButton(FarmTab, "Статус фарма", function()
    local elapsed = AutoFarm.active and ((tick() - AutoFarm.startTime) / 60) or 0
    print("=== AutoFarm Status ===")
    print("Активен:", AutoFarm.active)
    print("Состояние:", AutoFarm.state)
    print("Добыто:", AutoFarm.kills)
    print("Прошло:", string.format("%.1f мин", elapsed))
    print("Игроков рядом:", #AutoFarm.nearbyPlayers)
    print("Нырок:", HideUnderground.state)
end)

local LootTab = CreateTab("Лут")
CreateToggle(LootTab, "Лут через стены", false, F.ToggleWallLoot)
CreateToggle(LootTab, "Авто-режим", false, F.ToggleAutoLoot)
CreateSlider(LootTab, "Дистанция лута", 50, 2000, 500, function(v) WallLoot.maxDist = v end)
CreateSlider(LootTab, "Задержка лута мс", 50, 1000, 150, function(v) WallLoot.lootDelay = v / 1000 end)
CreateButton(LootTab, "Собрать все (клавиша L)", function()
    local n = F.LootEverything()
    print("[Rusted] Собрано: " .. tostring(n))
end)

local CodesTab = CreateTab("Коды")
CreateToggle(CodesTab, "Показывать коды", false, F.ToggleCodeLock)
CreateSlider(CodesTab, "Радиус скана", 50, 2000, 300, function(v) CodeLock.radius = v end)
CreateToggle(CodesTab, "Хук ввода паролей", false, function(s) if s then F.EnableCodeHook() end end)
CreateButton(CodesTab, "Dump кодов (клавиша K)", F.DumpAllCodes)

local ProtectTab = CreateTab("Защита")
CreateToggle(ProtectTab, "Детектор взгляда", false, F.ToggleWatcher)
CreateSlider(ProtectTab, "Точность взгляда", 50, 95, 70, function(v) Watcher.minDot = v / 100 end)
CreateSlider(ProtectTab, "Движение к тебе", 0, 90, 40, function(v) Watcher.minMoveDot = v / 100 end)
CreateSlider(ProtectTab, "Секунд до срабатывания", 1, 15, 5, function(v) Watcher.triggerTime = v end)
CreateToggle(ProtectTab, "Требовать видимость", true, function(s) Watcher.useVisibility = s end)
CreateToggle(ProtectTab, "Показывать имя", true, function(s) Watcher.showName = s end)
CreateToggle(ProtectTab, "Звук", true, function(s) Watcher.sound = s end)
CreateToggle(ProtectTab, "Звуки вообще", true, function(s) Sound.enabled = s end)

if Tabs["Главное"] then Tabs["Главное"].btn.MouseButton1Click:Fire() end

print("[Rusted] Загружен успешно v3.")
 
print("[Rusted] Хоткеи: RightShift - меню, L - лут, K - dump, F - freecam")
