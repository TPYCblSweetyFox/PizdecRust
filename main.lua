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

local MainTab = CreateTab("Main")
CreateButton(MainTab, "Rejoin Server", Rejoin)

local VisualTab = CreateTab("Visual")
CreateToggle(VisualTab, "Player ESP", false, F.TogglePlayerESP)
CreateToggle(VisualTab, "Rainbow ESP", false, F.ToggleRainbow)
CreateToggle(VisualTab, "Bot ESP", false, F.ToggleBotESP)
CreateToggle(VisualTab, "Box ESP", false, F.ToggleBoxESP)
CreateToggle(VisualTab, "Ore ESP", false, F.ToggleOreESP)
CreateToggle(VisualTab, "RT ESP", false, F.ToggleRTESP)
CreateToggle(VisualTab, "Radar", false, F.ToggleRadar)
CreateToggle(VisualTab, "Look Tracer", false, F.ToggleLookTracer)
CreateSlider(VisualTab, "Player ESP Max Distance", 100, 3000, 1200, function(v) ESP.maxDist = v end)
CreateSlider(VisualTab, "Bot ESP Max Distance", 100, 2000, 600, function(v) ESP.botMaxDist = v end)
CreateSlider(VisualTab, "Bot ESP Limit", 5, 100, 30, function(v) ESP.botLimit = v end)
CreateSlider(VisualTab, "Tracer Length", 50, 1000, 500, function(v) LookTracer.length = v end)
CreateSlider(VisualTab, "Radar Range", 50, 2000, 500, function(v) ESP.range = v end)
CreateToggle(VisualTab, "Night Vision", false, F.ToggleNightVision)
CreateToggle(VisualTab, "Remove Grass & Leaves", false, F.ToggleEnvClean)

local MoveTab = CreateTab("Movement")
CreateToggle(MoveTab, "Infinite Jump", false, F.ToggleInfJump)
CreateToggle(MoveTab, "Fly (WASD + Space/Ctrl)", false, F.ToggleFly)
CreateToggle(MoveTab, "Wall Climb (Space near wall)", false, F.ToggleWallClimb)
CreateSlider(MoveTab, "Wall Climb Speed", 10, 150, 45, function(v) WallClimb.speed = v end)
CreateToggle(MoveTab, "Speed Hack (WalkSpeed = 100)", false, F.ToggleWS)
CreateToggle(MoveTab, "High Jump (JumpPower = 200)", false, function(s)
    F.SetJPValue(200)
    F.ToggleJP(s)
end)
CreateToggle(MoveTab, "Noclip (platform)", false, F.ToggleHardNoclip)
CreateSlider(MoveTab, "Noclip Speed", 30, 200, 60, function(v) Noclip.speed = v end)
CreateToggle(MoveTab, "Freecam (key F)", false, F.ToggleFreecam)
CreateSlider(MoveTab, "Freecam Speed", 10, 300, 60, function(v) Freecam.speed = v end)
CreateToggle(MoveTab, "No Fall Damage", false, F.ToggleFallDamage)
CreateToggle(MoveTab, "Void Rescue (below -80)", true, F.ToggleVoidTP)
CreateSlider(MoveTab, "Y Threshold", -500, -10, -80, function(v) VoidTP.threshold = v end)
CreateSlider(MoveTab, "Return Y", 0, 200, 5, function(v) VoidTP.targetY = v end)
CreateToggle(MoveTab, "Teleport to SpawnLocation", false, function(s) VoidTP.useSpawn = s end)

local AimTab = CreateTab("Aim")
CreateToggle(AimTab, "Silent Aim (RMB)", false, F.ToggleSilentAim)
CreateToggle(AimTab, "Aimlock (RMB)", false, F.ToggleAimlock)
CreateToggle(AimTab, "Show FOV Circle", false, F.ToggleFovVisible)
local PartBtn = CreateButton(AimTab, "Target: Head", function() end)
local partIndex = 1
local partsList = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}
PartBtn.MouseButton1Click:Connect(function()
    partIndex = (partIndex % #partsList) + 1
    Aim.part = partsList[partIndex]
    PartBtn.Text = "Target: " .. Aim.part
end)
CreateSlider(AimTab, "FOV", 30, 500, 150, function(v) Aim.fov = v end)
CreateSlider(AimTab, "Aimlock Smoothness", 0, 95, 25, function(v) Aim.smooth = v / 100 end)
CreateToggle(AimTab, "Hold Mode", true, function(s) Aim.holdKey = s end)
CreateToggle(AimTab, "Visibility Check", true, function(s) Aim.visible = s end)

local PlayerTab = CreateTab("Players")
local massFrame = Instance.new("Frame")
massFrame.Size = UDim2.new(1, -8, 0, 32)
massFrame.BackgroundTransparency = 1
massFrame.Parent = PlayerTab
CreateButton(massFrame, "SEND ALL TO SPACE", F.SendAllToSpace)

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
            spaceBtn.Text = "TO SPACE >> " .. plr.Name
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

local FarmTab = CreateTab("Farm")
CreateToggle(FarmTab, "Auto Farm (ores)", false, F.ToggleAutoFarm)

local ModeBtn = CreateButton(FarmTab, "Mode: Walk", function() end)
local modes = {"walk", "fly"}
local modeLabels = {walk = "Walk", fly = "Fly"}
local modeIdx = 1
ModeBtn.MouseButton1Click:Connect(function()
    modeIdx = (modeIdx % #modes) + 1
    AutoFarm.mode = modes[modeIdx]
    ModeBtn.Text = "Mode: " .. modeLabels[AutoFarm.mode]
end)

CreateSlider(FarmTab, "Speed", 10, 200, 40, function(v) AutoFarm.speed = v end)
CreateSlider(FarmTab, "Fly Height", 2, 50, 5, function(v) AutoFarm.flyHeight = v end)
CreateSlider(FarmTab, "Mine Distance", 5, 30, 12, function(v) AutoFarm.reachDist = v end)
CreateSlider(FarmTab, "Mine Time", 1, 15, 3, function(v) AutoFarm.mineTime = v end)
CreateSlider(FarmTab, "Search Radius", 100, 2000, 300, function(v) AutoFarm.scanRange = v end)
CreateToggle(FarmTab, "Mine: Metal", true, function(s) AutoFarm.targetTypes.metal = s end)
CreateToggle(FarmTab, "Mine: Sulfur", true, function(s) AutoFarm.targetTypes.sulfur = s end)
CreateToggle(FarmTab, "Mine: Stone", true, function(s) AutoFarm.targetTypes.stone = s end)

local timeLimitBtn = CreateButton(FarmTab, "Time Limit: OFF", function() end)
local timeOptions = {0, 5, 10, 15, 30, 60}
local timeIdx = 1
timeLimitBtn.MouseButton1Click:Connect(function()
    timeIdx = (timeIdx % #timeOptions) + 1
    local v = timeOptions[timeIdx]
    AutoFarm.timeLimit = v
    timeLimitBtn.Text = v > 0 and ("Time Limit: " .. v .. " min") or "Time Limit: OFF"
end)

local killsLimitBtn = CreateButton(FarmTab, "Resource Limit: OFF", function() end)
local killsOptions = {0, 50, 100, 200, 500, 1000}
local killsIdx = 1
killsLimitBtn.MouseButton1Click:Connect(function()
    killsIdx = (killsIdx % #killsOptions) + 1
    local v = killsOptions[killsIdx]
    AutoFarm.killsLimit = v
    killsLimitBtn.Text = v > 0 and ("Resource Limit: " .. v .. " pcs") or "Resource Limit: OFF"
end)

CreateSlider(FarmTab, "Custom Time Limit", 0, 240, 0, function(v)
    if v > 0 then
        AutoFarm.timeLimit = v
        timeLimitBtn.Text = "Time Limit: " .. v .. " min"
    end
end)
CreateSlider(FarmTab, "Custom Resource Limit", 0, 5000, 0, function(v)
    if v > 0 then
        AutoFarm.killsLimit = v
        killsLimitBtn.Text = "Resource Limit: " .. v .. " pcs"
    end
end)

CreateToggle(FarmTab, "Player Detector", false, function(s)
    AutoFarm.playerDetect = s
    print("[Rusted AutoFarm] Player detector: " .. (s and "ON" or "OFF"))
end)

local playerActionBtn = CreateButton(FarmTab, "Action: Pause", function() end)
local playerActions = {"pause", "stop", "alert"}
local playerActionLabels = {pause = "Pause", stop = "Stop", alert = "Alert"}
local playerActionIdx = 1
playerActionBtn.MouseButton1Click:Connect(function()
    playerActionIdx = (playerActionIdx % #playerActions) + 1
    AutoFarm.playerAction = playerActions[playerActionIdx]
    playerActionBtn.Text = "Action: " .. playerActionLabels[AutoFarm.playerAction]
end)

CreateSlider(FarmTab, "Detector Radius", 30, 500, 150, function(v) AutoFarm.playerRadius = v end)
CreateSlider(FarmTab, "Pause After Leave", 1, 60, 5, function(v) AutoFarm.playerStopDelay = v end)
CreateToggle(FarmTab, "Hide Underground", false, F.ToggleHideUnderground)

CreateButton(FarmTab, "Farm Status", function()
    local elapsed = AutoFarm.active and ((tick() - AutoFarm.startTime) / 60) or 0
    print("=== AutoFarm Status ===")
    print("Active:", AutoFarm.active)
    print("State:", AutoFarm.state)
    print("Mined:", AutoFarm.kills)
    print("Elapsed:", string.format("%.1f min", elapsed))
    print("Players nearby:", #AutoFarm.nearbyPlayers)
    print("Dive state:", HideUnderground.state)
end)

local LootTab = CreateTab("Loot")
CreateToggle(LootTab, "Wall Loot", false, F.ToggleWallLoot)
CreateToggle(LootTab, "Auto Mode", false, F.ToggleAutoLoot)
CreateSlider(LootTab, "Loot Distance", 50, 2000, 500, function(v) WallLoot.maxDist = v end)
CreateSlider(LootTab, "Loot Delay (ms)", 50, 1000, 150, function(v) WallLoot.lootDelay = v / 1000 end)
CreateButton(LootTab, "Loot All Now (key L)", function()
    local n = F.LootEverything()
    print("[Rusted] Collected: " .. tostring(n))
end)

local CodesTab = CreateTab("Codes")
CreateToggle(CodesTab, "Show Codes", false, F.ToggleCodeLock)
CreateSlider(CodesTab, "Scan Radius", 50, 2000, 300, function(v) CodeLock.radius = v end)
CreateToggle(CodesTab, "Code Input Hook", false, function(s)
    if s then
        F.EnableCodeHook()
    else
        if F.DisableCodeHook then F.DisableCodeHook() end
    end
end)
CreateButton(CodesTab, "Dump Codes (key K)", F.DumpAllCodes)

local ProtectTab = CreateTab("Protection")
CreateToggle(ProtectTab, "Look Detector (red alert)", false, F.ToggleWatcher)
CreateSlider(ProtectTab, "Look Precision", 50, 95, 70, function(v) Watcher.minDot = v / 100 end)
CreateSlider(ProtectTab, "Movement to You", 0, 90, 40, function(v) Watcher.minMoveDot = v / 100 end)
CreateSlider(ProtectTab, "Seconds to Trigger", 1, 15, 5, function(v) Watcher.triggerTime = v end)
CreateToggle(ProtectTab, "Require Line of Sight", true, function(s) Watcher.useVisibility = s end)
CreateToggle(ProtectTab, "Show Name", true, function(s) Watcher.showName = s end)
CreateToggle(ProtectTab, "Sound Alert", true, function(s) Watcher.sound = s end)
CreateToggle(ProtectTab, "All Sounds", true, function(s) Sound.enabled = s end)

if Tabs["Main"] then
    for _, t in pairs(Tabs) do
        t.page.Visible = false
        t.btn.BackgroundColor3 = Color3.fromRGB(45, 32, 68)
        t.btn.TextColor3 = Color3.fromRGB(200, 200, 210)
    end
    Tabs["Main"].page.Visible = true
    Tabs["Main"].btn.BackgroundColor3 = Color3.fromRGB(138, 79, 255)
    Tabs["Main"].btn.TextColor3 = Color3.fromRGB(255, 255, 255)
end

print("[Rusted] Loaded v3.")
print("[Rusted] Hotkeys: RightShift - menu, L - loot, K - dump, F - freecam")
