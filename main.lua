--[[ MAIN — функции, ESP, AutoFarm, вкладки ]]

local BASE_URL = "https://raw.githubusercontent.com/TPYCblSweetyFox/PizdecRust/main/"
local CACHE_BUST = "?v=" .. tostring(math.floor(tick() * 1000))
local CORE = loadstring(game:HttpGet(BASE_URL .. "core.lua" .. CACHE_BUST))()

local Players = CORE.Players
local RunService = CORE.RunService
local UserInputService = CORE.UserInputService
local TweenService = CORE.TweenService
local Lighting = CORE.Lighting
local LP = CORE.LP
local Camera = CORE.Camera
local ScreenGui = CORE.ScreenGui
local espFolder = CORE.espFolder
local NewConnBag = CORE.NewConnBag
local PlaySound = CORE.PlaySound
local PlayBeepSequence = CORE.PlayBeepSequence
local NewBox = CORE.NewBox
local KillBox = CORE.KillBox
local CreateTab = CORE.CreateTab
local CreateButton = CORE.CreateButton
local CreateToggle = CORE.CreateToggle
local CreateSlider = CORE.CreateSlider
local Sound = CORE.Sound
local Tabs = CORE.Tabs

-- ============================================================
--  МУВМЕНТ
-- ============================================================

local wsValue = 32
local wsBag = nil
local function ToggleWS(state)
    if state then
        wsBag = NewConnBag()
        wsBag:add(RunService.Stepped:Connect(function()
            local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = wsValue end
        end))
    else
        if wsBag then wsBag:destroy(); wsBag = nil end
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
end

local jpValue = 100
local jpBag = nil
local function ToggleJP(state)
    if state then
        jpBag = NewConnBag()
        jpBag:add(RunService.Stepped:Connect(function()
            local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.JumpPower = jpValue end
        end))
    else
        if jpBag then jpBag:destroy(); jpBag = nil end
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = 50 end
    end
end

local infJumpBag = nil
local function ToggleInfJump(state)
    if state then
        infJumpBag = NewConnBag()
        infJumpBag:add(UserInputService.JumpRequest:Connect(function()
            local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end))
    else
        if infJumpBag then infJumpBag:destroy(); infJumpBag = nil end
    end
end

local flyActive = false
local flyBV, flyBG, flyConn
local function ToggleFly(state)
    flyActive = state
    if state then
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        flyBV = Instance.new("BodyVelocity")
        flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        flyBV.Velocity = Vector3.zero
        flyBV.Parent = hrp
        flyBG = Instance.new("BodyGyro")
        flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
        flyBG.P = 1000
        flyBG.Parent = hrp
        flyConn = RunService.RenderStepped:Connect(function()
            if not flyActive or not hrp or not hrp.Parent then return end
            local move = Vector3.zero
            local cam = Camera.CFrame
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cam.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cam.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cam.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cam.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0,1,0) end
            if move.Magnitude > 0 then move = move.Unit end
            flyBV.Velocity = move * 60
            flyBG.CFrame = cam
        end)
    else
        if flyConn then flyConn:Disconnect(); flyConn = nil end
        if flyBV then flyBV:Destroy(); flyBV = nil end
        if flyBG then flyBG:Destroy(); flyBG = nil end
    end
end

local Noclip = { active = false, speed = 120, platform = nil, bv = nil, conns = {} }

local function CreateNoclipPlatform()
    local p = Instance.new("Part")
    p.Name = "RustedNoclipPlatform"
    p.Size = Vector3.new(4, 1, 4)
    p.Transparency = 1
    p.CanCollide = false
    p.CanQuery = false
    p.CanTouch = false
    p.Anchored = false
    p.Massless = true
    p.Parent = workspace
    return p
end

local function EnableHardNoclip()
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    Noclip.platform = CreateNoclipPlatform()
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = hrp
    weld.Part1 = Noclip.platform
    weld.Parent = Noclip.platform
    Noclip.platform.CFrame = hrp.CFrame
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            p.CanCollide = false
            p.CanQuery = false
            p.CanTouch = false
        end
    end
    local bv = Instance.new("BodyVelocity")
    bv.Name = "RustedNoclipBV"
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Velocity = Vector3.zero
    bv.Parent = hrp
    Noclip.bv = bv
    table.insert(Noclip.conns, RunService.RenderStepped:Connect(function()
        if not Noclip.active then return end
        if not Noclip.bv or not Noclip.bv.Parent then return end
        if not hrp or not hrp.Parent then return end
        local moveDir = hum.MoveDirection
        if moveDir.Magnitude > 0.1 then
            Noclip.bv.Velocity = moveDir.Unit * Noclip.speed + Vector3.new(0, 8, 0)
        else
            Noclip.bv.Velocity = Vector3.zero
        end
        if Noclip.platform and Noclip.platform.Parent then
            Noclip.platform.CFrame = hrp.CFrame
        end
    end))
    table.insert(Noclip.conns, RunService.Stepped:Connect(function()
        if not Noclip.active then return end
        local c = LP.Character
        if not c then return end
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
        end
    end))
    table.insert(Noclip.conns, LP.CharacterAdded:Connect(function()
        task.wait(0.5)
        if Noclip.active then
            Noclip.active = false
            task.wait(0.1)
            Noclip.active = true
            if Noclip.platform then Noclip.platform:Destroy() end
            if Noclip.bv then Noclip.bv:Destroy() end
            for _, c in ipairs(Noclip.conns) do c:Disconnect() end
            Noclip.conns = {}
            EnableHardNoclip()
        end
    end))
end

local function DisableHardNoclip()
    if Noclip.platform then pcall(function() Noclip.platform:Destroy() end); Noclip.platform = nil end
    if Noclip.bv then pcall(function() Noclip.bv:Destroy() end); Noclip.bv = nil end
    for _, c in ipairs(Noclip.conns) do pcall(function() c:Disconnect() end) end
    Noclip.conns = {}
end

local function ToggleHardNoclip(state)
    Noclip.active = state
    if state then EnableHardNoclip()
    else
        DisableHardNoclip()
        local char = LP.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.CanCollide = true
                    p.CanQuery = true
                    p.CanTouch = true
                end
            end
        end
    end
end

local fallDamageBag = nil
local function ToggleFallDamage(state)
    if state then
        fallDamageBag = NewConnBag()
        fallDamageBag:add(RunService.Stepped:Connect(function()
            local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if not hum then return end
            if hum:GetState() == Enum.HumanoidStateType.Freefall then
                hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
                hum:ChangeState(Enum.HumanoidStateType.Running)
                hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
            end
        end))
    else
        if fallDamageBag then fallDamageBag:destroy(); fallDamageBag = nil end
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true) end
    end
end

local WallClimb = { active = false, speed = 45, push = 5, bv = nil, conn = nil, key = Enum.KeyCode.Space }

local function WallClimbRay()
    local char = LP.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { char }
    params.IgnoreWater = true
    return workspace:Raycast(hrp.Position, Camera.CFrame.LookVector * 3, params)
end

local function ToggleWallClimb(state)
    WallClimb.active = state
    if state then
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        WallClimb.bv = Instance.new("BodyVelocity")
        WallClimb.bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        WallClimb.bv.Velocity = Vector3.zero
        WallClimb.bv.Parent = hrp
        WallClimb.conn = RunService.RenderStepped:Connect(function()
            if not WallClimb.active then return end
            if not WallClimb.bv or not WallClimb.bv.Parent then return end
            if not hrp or not hrp.Parent then return end
            if not UserInputService:IsKeyDown(WallClimb.key) then
                WallClimb.bv.Velocity = Vector3.zero
                return
            end
            local hit = WallClimbRay()
            if not hit then
                WallClimb.bv.Velocity = Vector3.zero
                return
            end
            local normal = hit.Normal
            if math.abs(normal.Y) >= 0.3 then
                WallClimb.bv.Velocity = Vector3.zero
                return
            end
            WallClimb.bv.Velocity = Vector3.new(0, WallClimb.speed, 0) + (-normal * WallClimb.push)
        end)
    else
        if WallClimb.conn then WallClimb.conn:Disconnect(); WallClimb.conn = nil end
        if WallClimb.bv then WallClimb.bv:Destroy(); WallClimb.bv = nil end
    end
end

local Freecam = { active = false, pos = Vector3.zero, rot = CFrame.new(), speed = 60, hud = nil, conn = nil }

local function ToggleFreecam(state)
    Freecam.active = state
    if state then
        local camCF = Camera.CFrame
        Freecam.pos = camCF.Position
        Freecam.rot = camCF
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = true end
        local char = LP.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.LocalTransparencyModifier = 1 end
            end
        end
        Camera.CameraType = Enum.CameraType.Scriptable
        if not Freecam.hud then
            local hud = Instance.new("TextLabel")
            hud.Size = UDim2.new(0, 300, 0, 24)
            hud.Position = UDim2.new(0, 10, 1, -40)
            hud.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            hud.BackgroundTransparency = 0.5
            hud.TextColor3 = Color3.fromRGB(200, 200, 220)
            hud.TextSize = 12
            hud.Font = Enum.Font.Code
            hud.TextXAlignment = Enum.TextXAlignment.Left
            hud.Text = " FREECAM"
            hud.Parent = ScreenGui
            Freecam.hud = hud
        end
        Freecam.hud.Visible = true
        Freecam.conn = RunService.RenderStepped:Connect(function(dt)
            if not Freecam.active then return end
            local delta = UserInputService:GetMouseDelta()
            if delta.Magnitude > 0 then
                local yaw = CFrame.Angles(0, math.rad(-delta.X * 0.35), 0)
                local pitch = CFrame.Angles(math.rad(-delta.Y * 0.35), 0, 0)
                Freecam.rot = Freecam.rot * yaw * pitch
            end
            local move = Vector3.zero
            if UserInputService.KeyboardEnabled then
                local cam = Freecam.rot
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cam.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cam.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cam.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cam.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0,1,0) end
            end
            local spd = Freecam.speed
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then spd *= 3 end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) then spd *= 0.25 end
            if move.Magnitude > 0 then move = move.Unit end
            Freecam.pos += move * spd * dt
            Camera.CFrame = CFrame.new(Freecam.pos) * (Freecam.rot - Freecam.rot.Position)
            if Freecam.hud then
                Freecam.hud.Text = string.format(
                    " FREECAM  X:%.0f Y:%.0f Z:%.0f", Freecam.pos.X, Freecam.pos.Y, Freecam.pos.Z)
            end
        end)
    else
        if Freecam.conn then Freecam.conn:Disconnect(); Freecam.conn = nil end
        Camera.CameraType = Enum.CameraType.Custom
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
        local char = LP.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.LocalTransparencyModifier = 0 end
            end
        end
        if Freecam.hud then Freecam.hud:Destroy(); Freecam.hud = nil end
    end
end

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.F then ToggleFreecam(not Freecam.active) end
end)

local VoidTP = {
    active = true, threshold = -80, targetY = 5,
    useSpawn = false, lastTP = 0, cooldown = 1,
    conn = nil, charConn = nil,
}

local function VoidTeleport()
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local now = tick()
    if now - VoidTP.lastTP < VoidTP.cooldown then return end
    VoidTP.lastTP = now
    local targetCF
    if VoidTP.useSpawn then
        local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
        if spawn then targetCF = spawn.CFrame + Vector3.new(0, 5, 0) end
    end
    if not targetCF then
        targetCF = CFrame.new(hrp.Position.X, VoidTP.targetY, hrp.Position.Z)
    end
    hrp.CFrame = CFrame.new(targetCF.Position) * (hrp.CFrame - hrp.CFrame.Position)
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and not hum.PlatformStand then
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
end

local function StartVoidWatcher()
    if VoidTP.conn then return end
    VoidTP.conn = RunService.Heartbeat:Connect(function()
        if not VoidTP.active then return end
        local char = LP.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        if hrp.Position.Y < VoidTP.threshold then VoidTeleport() end
    end)
    if VoidTP.charConn then VoidTP.charConn:Disconnect() end
    VoidTP.charConn = LP.CharacterAdded:Connect(function()
        task.wait(1)
        if VoidTP.active and LP.Character then
            local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
            if hrp and hrp.Position.Y < VoidTP.threshold then
                VoidTP.lastTP = 0
                VoidTeleport()
            end
        end
    end)
end

local function StopVoidWatcher()
    if VoidTP.conn then VoidTP.conn:Disconnect(); VoidTP.conn = nil end
    if VoidTP.charConn then VoidTP.charConn:Disconnect(); VoidTP.charConn = nil end
end

local function ToggleVoidTP(state)
    VoidTP.active = state
    if state then StartVoidWatcher() else StopVoidWatcher() end
end

StartVoidWatcher()

-- ============================================================
--  КОСМОС
-- ============================================================

local SPACE_FORCE = 5000
local function SendToSpace(target)
    if not target or not target.Character then return end
    local char = target.Character
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if not hrp then return end
    if hum then
        hum.PlatformStand = true
        hum:ChangeState(Enum.HumanoidStateType.Physics)
    end
    for _, v in ipairs(hrp:GetChildren()) do
        if v:IsA("BodyVelocity") or v:IsA("BodyGyro")
        or v:IsA("LinearVelocity") or v:IsA("AlignOrientation") then v:Destroy() end
    end
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Velocity = Vector3.new(math.random(-200,200), SPACE_FORCE, math.random(-200,200))
    bv.Parent = hrp
    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bg.P = 100000
    bg.CFrame = hrp.CFrame
    bg.Parent = hrp
    task.delay(2, function()
        if bv.Parent then bv:Destroy() end
        if bg.Parent then bg:Destroy() end
        if hum and hum.Parent then
            hum.PlatformStand = false
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end)
end

local function SendAllToSpace()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP then SendToSpace(plr) end
    end
end

-- ============================================================
--  AIM
-- ============================================================

local Aim = {
    silent = false, aimlock = false, fov = 150, smooth = 0.25,
    visible = true, part = "Head", key = Enum.UserInputType.MouseButton2,
    holdKey = true, locked = nil,
}

local aimActive = false

local FovGui = Instance.new("Frame")
FovGui.Name = "FovCircle"
FovGui.AnchorPoint = Vector2.new(0.5, 0.5)
FovGui.BackgroundTransparency = 1
FovGui.Size = UDim2.new(0, Aim.fov * 2, 0, Aim.fov * 2)
FovGui.Position = UDim2.new(0.5, 0, 0.5, 0)
FovGui.Visible = false
FovGui.ZIndex = 999
FovGui.Parent = ScreenGui

local FovCircle = Instance.new("UICorner")
FovCircle.CornerRadius = UDim.new(1, 0)
FovCircle.Parent = FovGui

local FovStroke = Instance.new("UIStroke")
FovStroke.Color = Color3.fromRGB(200, 60, 60)
FovStroke.Thickness = 1.5
FovStroke.Transparency = 0.3
FovStroke.Parent = FovGui

local function GetAimPart(char)
    if not char then return nil end
    return char:FindFirstChild(Aim.part) or char:FindFirstChild("HumanoidRootPart")
end

local function IsVisible(target)
    if not Aim.visible then return true end
    local myHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return false end
    local targetPart = GetAimPart(target.Character)
    if not targetPart then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { LP.Character }
    params.IgnoreWater = true
    local dir = targetPart.Position - Camera.CFrame.Position
    local result = workspace:Raycast(Camera.CFrame.Position, dir, params)
    if not result then return false end
    return result.Instance:IsDescendantOf(target.Character)
end

local function FindTarget()
    local myHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end
    local screenCenter = Camera.ViewportSize / 2
    local best, bestDist = nil, Aim.fov
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local part = GetAimPart(plr.Character)
            local hum  = plr.Character:FindFirstChildOfClass("Humanoid")
            if part and hum and hum.Health > 0 then
                local sp, onScreen = Camera:WorldToScreenPoint(part.Position)
                if onScreen then
                    local dist2D = (Vector2.new(sp.X, sp.Y) - screenCenter).Magnitude
                    if dist2D < bestDist and IsVisible(plr) then
                        bestDist = dist2D
                        best = plr
                    end
                end
            end
        end
    end
    return best
end

local function UpdateAimlock()
    if not Aim.aimlock or not aimActive then return end
    local target = Aim.locked or FindTarget()
    if not target then return end
    Aim.locked = target
    local part = GetAimPart(target.Character)
    if not part then Aim.locked = nil; return end
    local targetCF = CFrame.new(Camera.CFrame.Position, part.Position)
    if Aim.smooth <= 0 then Camera.CFrame = targetCF
    else Camera.CFrame = Camera.CFrame:Lerp(targetCF, 1 - Aim.smooth) end
end

local silentHookActive = false
local function EnableSilentHook()
    if silentHookActive then return end
    silentHookActive = true
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        if not Aim.silent then return oldNamecall(self, ...) end
        local method = getnamecallmethod()
        local args = {...}
        if aimActive and method == "FireServer" and self:IsA("RemoteEvent") then
            local target = Aim.locked or FindTarget()
            if target then
                local part = GetAimPart(target.Character)
                if part then
                    for i, arg in ipairs(args) do
                        if typeof(arg) == "Vector3" then args[i] = part.Position
                        elseif typeof(arg) == "CFrame" then
                            args[i] = CFrame.new(Camera.CFrame.Position, part.Position)
                        end
                    end
                    return oldNamecall(self, table.unpack(args))
                end
            end
        end
        return oldNamecall(self, ...)
    end)
end

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Aim.key then
        if Aim.holdKey then
            aimActive = true
            if Aim.silent then EnableSilentHook() end
        else
            aimActive = not aimActive
            if Aim.silent then EnableSilentHook() end
        end
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Aim.key and Aim.holdKey then
        aimActive = false
        Aim.locked = nil
    end
end)

local function ToggleSilentAim(state) Aim.silent = state; if state then EnableSilentHook() end end
local function ToggleAimlock(state) Aim.aimlock = state; if not state then Aim.locked = nil end end
local function ToggleFovVisible(state) FovGui.Visible = state end

local function UpdateAim(dt)
    if not aimActive then return end
    Aim.locked = FindTarget()
    UpdateAimlock()
    FovGui.Size = UDim2.new(0, Aim.fov * 2, 0, Aim.fov * 2)
end

-- ============================================================
--  ESP СИСТЕМА
-- ============================================================

local ESP = {
    players = false, rainbow = false, bots = false,
    boxes = false, ores = false, rt = false, radar = false,
    range = 500,
    maxDist = 1200,
    botMaxDist = 600,
    botLimit = 30,
}

local playerESP, botESP, boxESP, oreESP, rtESP = {}, {}, {}, {}, {}

local hueClock = 0
local function RainbowColor(offset)
    hueClock += 0.005
    if hueClock > 1 then hueClock -= 1 end
    return Color3.fromHSV((hueClock + (offset or 0)) % 1, 1, 1)
end

local VisibilityRayParams = RaycastParams.new()
VisibilityRayParams.FilterType = Enum.RaycastFilterType.Exclude
VisibilityRayParams.IgnoreWater = true

local function IsCharVisible(char)
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    VisibilityRayParams.FilterDescendantsInstances = { LP.Character, char, espFolder }
    local origin = Camera.CFrame.Position
    local dir = hrp.Position - origin
    local result = workspace:Raycast(origin, dir, VisibilityRayParams)
    if not result then return false end
    return result.Instance:IsDescendantOf(char)
end

local WEAPON_KEYWORDS = {
    "gun", "rifle", "pistol", "shotgun", "smg", "sniper", "lmg",
    "ak", "m4", "m16", "mp5", "awp", "deagle", "glock", "uzi",
    "bow", "crossbow", "launcher", "rpg", "grenade", "knife",
    "sword", "axe", "pickaxe", "hatchet", "spear", "melee",
}

local function MatchesWeapon(inst)
    local n = string.lower(inst.Name)
    for _, kw in ipairs(WEAPON_KEYWORDS) do
        if n:find(kw, 1, true) then return true end
    end
    return false
end

local function GetPlayerWeapons(plr)
    local list, seen = {}, {}
    local function add(name)
        if not name or name == "" or seen[name] then return end
        seen[name] = true
        table.insert(list, name)
    end
    local char = plr.Character
    if char then
        for _, child in ipairs(char:GetChildren()) do
            if child:IsA("Tool") then add(child.Name)
            elseif child:IsA("Model") and MatchesWeapon(child) then add(child.Name) end
        end
        for _, desc in ipairs(char:GetDescendants()) do
            if (desc:IsA("Model") or desc:IsA("BasePart")) 
            and MatchesWeapon(desc) and not desc:IsDescendantOf(espFolder) then
                add(desc.Name)
            end
        end
    end
    local bp = plr:FindFirstChildOfClass("Backpack")
    if bp then
        for _, child in ipairs(bp:GetChildren()) do
            if child:IsA("Tool") then add(child.Name) end
        end
    end
    return list
end

local function FormatWeaponList(weapons)
    if #weapons == 0 then return "-" end
    local names = {}
    for i, w in ipairs(weapons) do
        if i > 3 then
            table.insert(names, "+" .. (#weapons - 3))
            break
        end
        table.insert(names, w)
    end
    return table.concat(names, ", ")
end

local function CreateInfoLabel()
    local bb = Instance.new("BillboardGui")
    bb.Name = "RustedInfo"
    bb.Size = UDim2.new(0, 200, 0, 60)
    bb.StudsOffset = Vector3.new(0, 3.5, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 1500
    bb.Parent = espFolder
    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.new(1, 0, 1, 0)
    tl.BackgroundTransparency = 1
    tl.TextColor3 = Color3.fromRGB(255, 255, 255)
    tl.TextSize = 12
    tl.Font = Enum.Font.GothamBold
    tl.TextStrokeTransparency = 0
    tl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    tl.TextYAlignment = Enum.TextYAlignment.Center
    tl.TextXAlignment = Enum.TextXAlignment.Center
    tl.Text = ""
    tl.Parent = bb
    return { gui = bb, label = tl }
end

local function AddPlayerESP(plr)
    if plr == LP or playerESP[plr] then return end
    playerESP[plr] = {
        box = NewBox(),
        hue = math.random(),
        info = CreateInfoLabel(),
        visible = true,
    }
end

local function RemovePlayerESP(plr)
    local d = playerESP[plr]
    if not d then return end
    KillBox(d.box)
    if d.info and d.info.gui then d.info.gui:Destroy() end
    playerESP[plr] = nil
end

local function IsValidBot(model)
    if not model:IsA("Model") then return false end
    if Players:GetPlayerFromCharacter(model) then return false end
    if not model:FindFirstChildOfClass("Humanoid") then return false end
    if not model:FindFirstChild("HumanoidRootPart") then return false end
    return true
end

local function ScanBots()
    local found = {}
    for _, obj in ipairs(workspace:GetChildren()) do
        if IsValidBot(obj) then
            found[obj] = true
            if not botESP[obj] then
                botESP[obj] = { box = NewBox(), hue = math.random() }
            end
        end
    end
    for model, d in pairs(botESP) do
        if not found[model] or not model.Parent then
            KillBox(d.box)
            botESP[model] = nil
        end
    end
end

local BOX_KEYWORDS = {
    "crate", "smallcrate", "largecrate", "barrel", "lootbox",
    "supply", "chest", "fridge", "recycler", "furnace",
    "miraility", "miracl", "military",
}
local function IsBoxPart(inst)
    if not inst:IsA("BasePart") then return false end
    local n = string.lower(inst.Name)
    for _, k in ipairs(BOX_KEYWORDS) do
        if n:find(k, 1, true) then return true end
    end
    local parent = inst.Parent
    if parent and parent:IsA("Model") then
        local pn = string.lower(parent.Name)
        for _, k in ipairs(BOX_KEYWORDS) do
            if pn:find(k, 1, true) then return true end
        end
    end
    return false
end

local function CreateBoxLabel(part)
    local bb = Instance.new("BillboardGui")
    bb.Name = "RustedBoxLabel"
    bb.Size = UDim2.new(0, 140, 0, 20)
    bb.StudsOffset = Vector3.new(0, 2, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 800
    bb.Adornee = part
    bb.Parent = espFolder
    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.new(1, 0, 1, 0)
    tl.BackgroundTransparency = 1
    tl.TextColor3 = Color3.fromRGB(255, 220, 80)
    tl.TextSize = 12
    tl.Font = Enum.Font.GothamBold
    tl.TextStrokeTransparency = 0
    tl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    tl.Text = "[ " .. part.Name .. " ]"
    tl.Parent = bb
    return bb
end

local function ScanBoxes()
    local found = {}
    for _, inst in ipairs(workspace:GetDescendants()) do
        if IsBoxPart(inst) then
            found[inst] = true
            if not boxESP[inst] then
                local b = NewBox()
                b.Color3 = Color3.fromRGB(255, 200, 50)
                b.Size = inst.Size + Vector3.new(0.5, 0.5, 0.5)
                boxESP[inst] = { box = b, label = CreateBoxLabel(inst) }
            end
        end
    end
    for part, d in pairs(boxESP) do
        if not found[part] or not part.Parent then
            KillBox(d.box)
            if d.label then d.label:Destroy() end
            boxESP[part] = nil
        end
    end
end

local ORES = {
    metal = {
        keywords = {"metal", "metalore", "metal_ore", "ironore", "hqm", "highquality", "iron", "steel"},
        color = Color3.fromRGB(180, 180, 180),
        label = "Металл",
    },
    sulfur = {
        keywords = {"sulfur", "sulfurore", "sulfur_ore", "sulphur", "sulf"},
        color = Color3.fromRGB(255, 230, 60),
        label = "Сера",
    },
    stone = {
        keywords = {"stone", "stoneore", "stone_ore", "rock", "rockore", "ore"},
        color = Color3.fromRGB(220, 60, 60),
        label = "Камень",
    },
}

local function GetOreType(inst)
    if not inst:IsA("BasePart") and not inst:IsA("Model") then return nil end
    local names = { string.lower(inst.Name) }
    if inst.Parent then table.insert(names, string.lower(inst.Parent.Name)) end
    for _, n in ipairs(names) do
        for oreKey, data in pairs(ORES) do
            for _, kw in ipairs(data.keywords) do
                if n:find(kw, 1, true) then return oreKey end
            end
        end
    end
    return nil
end

local function CreateOreLabel(part, oreType)
    local data = ORES[oreType]
    local bb = Instance.new("BillboardGui")
    bb.Name = "RustedOreLabel"
    bb.Size = UDim2.new(0, 120, 0, 20)
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 1000
    bb.Adornee = part
    bb.Parent = espFolder
    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.new(1, 0, 1, 0)
    tl.BackgroundTransparency = 1
    tl.TextColor3 = data.color
    tl.TextSize = 12
    tl.Font = Enum.Font.GothamBold
    tl.TextStrokeTransparency = 0
    tl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    tl.Text = "[ " .. data.label .. " ]"
    tl.Parent = bb
    return bb
end

local function ScanOres()
    local found = {}
    for _, inst in ipairs(workspace:GetDescendants()) do
        local oreType = GetOreType(inst)
        if oreType then
            local part
            if inst:IsA("BasePart") then part = inst
            elseif inst:IsA("Model") then
                part = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")
            end
            if part then
                found[part] = true
                if not oreESP[part] then
                    local data = ORES[oreType]
                    local b = NewBox()
                    b.Color3 = data.color
                    b.Size = part.Size + Vector3.new(0.5, 0.5, 0.5)
                    b.Transparency = 0.6
                    oreESP[part] = { box = b, label = CreateOreLabel(part, oreType), type = oreType }
                end
            end
        end
    end
    for part, d in pairs(oreESP) do
        if not found[part] or not part.Parent then
            KillBox(d.box)
            if d.label then d.label:Destroy() end
            oreESP[part] = nil
        end
    end
end

local RT_LOCATIONS = {
    { name = "Arctic Base",  keywords = {"arctic", "arcticbase", "arctic_base", "icebase"} },
    { name = "Bunker",       keywords = {"bunker", "underground", "bunkerentrance"} },
    { name = "Military Base", keywords = {"military", "militarybase", "milbase", "military_base"} },
    { name = "Airfield",     keywords = {"airfield", "airport", "aerodrome"} },
    { name = "Oil Rig",      keywords = {"oilrig", "oil_rig", "oildrilling"} },
    { name = "Mountain Base", keywords = {"mountain", "mountainbase", "minebase"} },
    { name = "Harbor",       keywords = {"harbor", "dock", "port", "seaport"} },
    { name = "Water Treatment", keywords = {"water", "watertreatment", "water_treatment"} },
    { name = "Power Plant",  keywords = {"powerplant", "power_plant"} },
    { name = "RT",           keywords = {"rt", "lootroom", "loot_room", "raidtarget"} },
}
local RT_COLOR = Color3.fromRGB(255, 100, 255)

local function GetRTType(inst)
    if not inst:IsA("BasePart") and not inst:IsA("Model") then return nil end
    local names = { string.lower(inst.Name) }
    local p = inst.Parent
    local depth = 0
    while p and depth < 5 do
        table.insert(names, string.lower(p.Name))
        p = p.Parent
        depth += 1
    end
    for _, rt in ipairs(RT_LOCATIONS) do
        for _, kw in ipairs(rt.keywords) do
            for _, n in ipairs(names) do
                if n == kw or n:find(kw, 1, true) then return rt.name end
            end
        end
    end
    return nil
end

local function CreateRTLabel(part, rtName)
    local bb = Instance.new("BillboardGui")
    bb.Name = "RustedRTLabel"
    bb.Size = UDim2.new(0, 220, 0, 50)
    bb.StudsOffset = Vector3.new(0, 8, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 3000
    bb.Adornee = part
    bb.Parent = espFolder
    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.new(1, 0, 1, 0)
    tl.BackgroundTransparency = 0.2
    tl.BackgroundColor3 = Color3.fromRGB(30, 0, 30)
    tl.TextColor3 = RT_COLOR
    tl.TextSize = 16
    tl.Font = Enum.Font.GothamBold
    tl.TextStrokeTransparency = 0
    tl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    tl.Text = "[RT] " .. rtName
    tl.Parent = bb
    local stroke = Instance.new("UIStroke")
    stroke.Color = RT_COLOR
    stroke.Thickness = 2
    stroke.Parent = tl
    return bb
end

local function ScanRT()
    local found = {}
    for _, inst in ipairs(workspace:GetDescendants()) do
        local rtName = GetRTType(inst)
        if rtName then
            local mainPart
            if inst:IsA("BasePart") then mainPart = inst
            elseif inst:IsA("Model") then
                local biggest, biggestSize = nil, 0
                for _, p in ipairs(inst:GetDescendants()) do
                    if p:IsA("BasePart") then
                        local sz = p.Size.Magnitude
                        if sz > biggestSize then biggestSize = sz; biggest = p end
                    end
                end
                mainPart = biggest or inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")
            end
            if mainPart then
                found[inst] = true
                if not rtESP[inst] then
                    local b = NewBox()
                    b.Color3 = RT_COLOR
                    b.Size = mainPart.Size + Vector3.new(10, 10, 10)
                    b.Transparency = 0.75
                    rtESP[inst] = { box = b, label = CreateRTLabel(mainPart, rtName), part = mainPart, name = rtName }
                else
                    rtESP[inst].part = mainPart
                end
            end
        end
    end
    for inst, d in pairs(rtESP) do
        if not found[inst] or not inst.Parent then
            KillBox(d.box)
            if d.label then d.label:Destroy() end
            rtESP[inst] = nil
        end
    end
end

local RadarGui = Instance.new("Frame")
RadarGui.Name = "Radar"
RadarGui.Size = UDim2.new(0, 160, 0, 160)
RadarGui.Position = UDim2.new(0, 10, 1, -180)
RadarGui.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
RadarGui.BackgroundTransparency = 0.3
RadarGui.BorderSizePixel = 0
RadarGui.Visible = false
RadarGui.Parent = ScreenGui
local RadarCorner = Instance.new("UICorner")
RadarCorner.CornerRadius = UDim.new(0, 8)
RadarCorner.Parent = RadarGui
local RadarStroke = Instance.new("UIStroke")
RadarStroke.Color = Color3.fromRGB(80, 80, 100)
RadarStroke.Parent = RadarGui
local RadarTitle = Instance.new("TextLabel")
RadarTitle.Size = UDim2.new(1, 0, 0, 18)
RadarTitle.BackgroundTransparency = 1
RadarTitle.Text = "RADAR"
RadarTitle.TextColor3 = Color3.fromRGB(180, 180, 200)
RadarTitle.TextSize = 12
RadarTitle.Font = Enum.Font.GothamBold
RadarTitle.Parent = RadarGui
local RadarCanvas = Instance.new("Frame")
RadarCanvas.Size = UDim2.new(1, -10, 1, -24)
RadarCanvas.Position = UDim2.new(0, 5, 0, 22)
RadarCanvas.BackgroundTransparency = 1
RadarCanvas.ClipsDescendants = true
RadarCanvas.Parent = RadarGui
local RadarSelf = Instance.new("Frame")
RadarSelf.Size = UDim2.new(0, 4, 0, 4)
RadarSelf.Position = UDim2.new(0.5, -2, 0.5, -2)
RadarSelf.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
RadarSelf.BorderSizePixel = 0
RadarSelf.ZIndex = 5
RadarSelf.Parent = RadarCanvas

local radarActive = {}
local function NewRadarDot()
    local d = Instance.new("Frame")
    d.Size = UDim2.new(0, 5, 0, 5)
    d.AnchorPoint = Vector2.new(0.5, 0.5)
    d.BorderSizePixel = 0
    d.ZIndex = 3
    d.Parent = RadarCanvas
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(1, 0)
    c.Parent = d
    return d
end
local function KillRadarDot(d) if d then pcall(function() d:Destroy() end) end end

local LookTracer = {
    enabled = false, length = 500,
    color = Color3.fromRGB(255, 100, 100),
    thickness = 0.3, transparency = 0.3,
    tracers = {},
}

local function NewLookTracer(plr)
    local adorn = Instance.new("LineHandleAdornment")
    adorn.Name = "RustedLook_" .. plr.Name
    adorn.AlwaysOnTop = true
    adorn.ZIndex = 4
    adorn.Color3 = LookTracer.color
    adorn.Thickness = LookTracer.thickness
    adorn.Transparency = LookTracer.transparency
    adorn.Parent = espFolder
    return adorn
end

local function KillLookTracer(adorn)
    if adorn then pcall(function() adorn:Destroy() end) end
end

local function ToggleLookTracer(state)
    LookTracer.enabled = state
    if not state then
        for plr, ad in pairs(LookTracer.tracers) do
            KillLookTracer(ad)
            LookTracer.tracers[plr] = nil
        end
        LookTracer.tracers = {}
    end
end

local NightVision = { active = false, bag = nil, light = nil, light2 = nil, saved = nil }

local function SaveLighting()
    return {
        Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
        Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime,
        FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart,
        GlobalShadows = Lighting.GlobalShadows,
        EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
        EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
    }
end

local function RestoreLighting(saved)
    if not saved then return end
    for k, v in pairs(saved) do
        pcall(function() Lighting[k] = v end)
    end
end

local function ApplyNightVision()
    Lighting.Ambient = Color3.fromRGB(80, 120, 80)
    Lighting.OutdoorAmbient = Color3.fromRGB(60, 90, 60)
    Lighting.Brightness = 3
    Lighting.ClockTime = 14
    Lighting.FogEnd = 100000
    Lighting.FogStart = 0
    Lighting.EnvironmentDiffuseScale = 1
    Lighting.EnvironmentSpecularScale = 1
end

local function AttachLights(char)
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    NightVision.light = Instance.new("PointLight")
    NightVision.light.Range = 60
    NightVision.light.Brightness = 5
    NightVision.light.Color = Color3.fromRGB(200, 255, 200)
    NightVision.light.Shadows = false
    NightVision.light.Parent = head
    NightVision.light2 = Instance.new("SpotLight")
    NightVision.light2.Range = 60
    NightVision.light2.Angle = 90
    NightVision.light2.Brightness = 4
    NightVision.light2.Color = Color3.fromRGB(220, 255, 220)
    NightVision.light2.Face = Enum.NormalId.Front
    NightVision.light2.Shadows = false
    NightVision.light2.Parent = head
end

local function DetachLights()
    if NightVision.light then pcall(function() NightVision.light:Destroy() end); NightVision.light = nil end
    if NightVision.light2 then pcall(function() NightVision.light2:Destroy() end); NightVision.light2 = nil end
end

local function ToggleNightVision(state)
    NightVision.active = state
    if state then
        NightVision.saved = SaveLighting()
        ApplyNightVision()
        AttachLights(LP.Character)
        NightVision.bag = NewConnBag()
        NightVision.bag:add(LP.CharacterAdded:Connect(function(char)
            task.wait(0.5)
            if NightVision.active then
                ApplyNightVision()
                AttachLights(char)
            end
        end))
    else
        RestoreLighting(NightVision.saved)
        NightVision.saved = nil
        DetachLights()
        if NightVision.bag then NightVision.bag:destroy(); NightVision.bag = nil end
    end
end

local EnvCleaner = { active = false, bag = nil, hidden = {} }

local GRASS_KEYWORDS = {"grass", "foliage", "fern", "bush", "shrub", "weeds"}
local LEAF_KEYWORDS = {"leaf", "leaves", "foliage", "canopy", "treecrown"}

local function MatchesAnyKeyword(inst, keywords)
    local n = string.lower(inst.Name)
    for _, kw in ipairs(keywords) do
        if n:find(kw, 1, true) then return true end
    end
    return false
end

local function IsGrassOrLeaves(inst)
    if not inst:IsA("BasePart") and not inst:IsA("Model") then return false end
    if MatchesAnyKeyword(inst, GRASS_KEYWORDS) then return true end
    if MatchesAnyKeyword(inst, LEAF_KEYWORDS) then return true end
    if inst:IsA("BasePart") then
        local m = inst.Material
        if (m == Enum.Material.Grass or m == Enum.Material.LeafyGrass) and inst.Size.Magnitude < 30 then
            return true
        end
    end
    return false
end

local function HideInstance(inst)
    if EnvCleaner.hidden[inst] then return end
    if inst:IsA("BasePart") then
        EnvCleaner.hidden[inst] = {
            Transparency = inst.Transparency,
            CanCollide = inst.CanCollide,
            CanQuery = inst.CanQuery,
            CanTouch = inst.CanTouch,
        }
        inst.Transparency = 1
        inst.CanCollide = false
        inst.CanQuery = false
        inst.CanTouch = false
    elseif inst:IsA("Model") then
        for _, p in ipairs(inst:GetDescendants()) do
            if p:IsA("BasePart") then HideInstance(p) end
        end
    end
end

local function RestoreAll()
    for inst, saved in pairs(EnvCleaner.hidden) do
        pcall(function()
            if inst.Parent then
                inst.Transparency = saved.Transparency
                inst.CanCollide = saved.CanCollide
                inst.CanQuery = saved.CanQuery
                inst.CanTouch = saved.CanTouch
            end
        end)
    end
    EnvCleaner.hidden = {}
end

local function ScanAndClean()
    for _, inst in ipairs(workspace:GetDescendants()) do
        if IsGrassOrLeaves(inst) then HideInstance(inst) end
    end
end

local function ToggleEnvClean(state)
    EnvCleaner.active = state
    if state then
        EnvCleaner.bag = NewConnBag()
        ScanAndClean()
        EnvCleaner.bag:add(workspace.DescendantAdded:Connect(function(inst)
            if EnvCleaner.active and IsGrassOrLeaves(inst) then
                task.wait(0.1)
                HideInstance(inst)
            end
        end))
    else
        RestoreAll()
        if EnvCleaner.bag then EnvCleaner.bag:destroy(); EnvCleaner.bag = nil end
    end
end

-- ============================================================
--  AUTO-FARM
-- ============================================================

local AutoFarm = {
    active = false, mode = "walk", speed = 40, flyHeight = 5,
    reachDist = 12, mineTime = 3, scanRange = 500,
    targetTypes = { metal = true, sulfur = true, stone = true },
    bag = nil, currentTarget = nil, state = "idle",
    mineStart = 0, lastScan = 0, kills = 0,
    timeLimit = 0, killsLimit = 0, startTime = 0, stoppedBy = nil,
    playerDetect = false, playerRadius = 150, playerAction = "pause",
    playerPaused = false, playerPauseEnd = 0, playerStopDelay = 5,
    lastPlayerCheck = 0, nearbyPlayers = {},
}

local HideUnderground = {
    active = false, depthOffset = 20,
    platform = nil, bv = nil, savedPos = nil,
    state = "surface", diveStart = 0,
}

local function CreateHidePlatform()
    local p = Instance.new("Part")
    p.Name = "RustedHidePlatform"
    p.Size = Vector3.new(8, 1, 8)
    p.Transparency = 1
    p.CanCollide = true
    p.CanQuery = false
    p.CanTouch = false
    p.Anchored = true
    p.Massless = true
    p.Parent = workspace
    return p
end

local function StartDive()
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    HideUnderground.savedPos = hrp.CFrame
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
    local bv = Instance.new("BodyVelocity")
    bv.Name = "RustedHideBV"
    bv.MaxForce = Vector3.new(0, math.huge, 0)
    bv.Velocity = Vector3.new(0, -80, 0)
    bv.Parent = hrp
    HideUnderground.bv = bv
    HideUnderground.state = "diving"
    HideUnderground.diveStart = tick()
end

local function ReachedUndergroundDepth()
    local char = LP.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp or not HideUnderground.savedPos then return false end
    local targetY = HideUnderground.savedPos.Position.Y - HideUnderground.depthOffset
    return hrp.Position.Y <= targetY
end

local function AnchorUnderground()
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    HideUnderground.platform = CreateHidePlatform()
    HideUnderground.platform.CFrame = CFrame.new(hrp.Position.X, hrp.Position.Y - 4, hrp.Position.Z)
    if HideUnderground.bv then
        HideUnderground.bv.Velocity = Vector3.zero
        HideUnderground.bv.MaxForce = Vector3.new(0, math.huge, 0)
    end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = true end
    end
    HideUnderground.state = "underground"
end

local function SurfaceUp()
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if HideUnderground.platform then
        HideUnderground.platform:Destroy()
        HideUnderground.platform = nil
    end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
    if HideUnderground.bv then
        HideUnderground.bv.MaxForce = Vector3.new(0, math.huge, 0)
        HideUnderground.bv.Velocity = Vector3.new(0, 80, 0)
    else
        local bv = Instance.new("BodyVelocity")
        bv.Name = "RustedHideBV"
        bv.MaxForce = Vector3.new(0, math.huge, 0)
        bv.Velocity = Vector3.new(0, 80, 0)
        bv.Parent = hrp
        HideUnderground.bv = bv
    end
    HideUnderground.state = "surfacing"
end

local function ReachedSurface()
    local char = LP.Character
    if not char or not HideUnderground.savedPos then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    return hrp.Position.Y >= HideUnderground.savedPos.Position.Y - 2
end

local function FinishSurface()
    local char = LP.Character
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = true end
    end
    if HideUnderground.bv then
        HideUnderground.bv:Destroy()
        HideUnderground.bv = nil
    end
    HideUnderground.state = "surface"
    HideUnderground.savedPos = nil
end

local function CleanupHide()
    if HideUnderground.platform then HideUnderground.platform:Destroy(); HideUnderground.platform = nil end
    if HideUnderground.bv then HideUnderground.bv:Destroy(); HideUnderground.bv = nil end
    local char = LP.Character
    if char then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = true end
        end
    end
    HideUnderground.state = "surface"
    HideUnderground.savedPos = nil
end

local function ToggleHideUnderground(state)
    HideUnderground.active = state
    if not state and HideUnderground.state ~= "surface" then SurfaceUp() end
end

local function UpdateHideUnderground()
    if not HideUnderground.active then return end
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local playersNear = #AutoFarm.nearbyPlayers > 0
    if HideUnderground.state == "surface" and playersNear then
        StartDive()
    elseif HideUnderground.state == "diving" then
        if ReachedUndergroundDepth() or tick() - HideUnderground.diveStart > 3 then
            AnchorUnderground()
        end
    elseif HideUnderground.state == "underground" then
        if HideUnderground.platform then
            HideUnderground.platform.CFrame = CFrame.new(hrp.Position.X, hrp.Position.Y - 4, hrp.Position.Z)
        end
        if not playersNear and not AutoFarm.playerPaused then
            SurfaceUp()
        end
    elseif HideUnderground.state == "surfacing" then
        if ReachedSurface() then FinishSurface() end
    end
end

local function FindNearestOre()
    local char = LP.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local myPos = hrp.Position
    local best, bestDist = nil, math.huge
    for _, inst in ipairs(workspace:GetDescendants()) do
        if inst:IsA("BasePart") or inst:IsA("Model") then
            local oreType = GetOreType(inst)
            if oreType and AutoFarm.targetTypes[oreType] then
                local part
                if inst:IsA("BasePart") then part = inst
                elseif inst:IsA("Model") then
                    part = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")
                end
                if part then
                    local dist = (part.Position - myPos).Magnitude
                    if dist < bestDist and dist <= AutoFarm.scanRange then
                        bestDist = dist
                        best = { inst = inst, part = part, type = oreType, dist = dist }
                    end
                end
            end
        end
    end
    return best
end

local function MoveToward(targetPos, dt)
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    local current = hrp.Position
    local diff = targetPos - current
    local dist = Vector3.new(diff.X, 0, diff.Z).Magnitude
    if dist < 1 then return end
    if AutoFarm.mode == "walk" then
        hum:MoveTo(targetPos)
    elseif AutoFarm.mode == "fly" then
        if not AutoFarm._bv then
            AutoFarm._bv = Instance.new("BodyVelocity")
            AutoFarm._bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            AutoFarm._bv.Parent = hrp
        end
        local dir = diff.Unit
        local targetY = targetPos.Y + AutoFarm.flyHeight
        local yDiff = targetY - current.Y
        AutoFarm._bv.Velocity = Vector3.new(dir.X * AutoFarm.speed, yDiff * 2, dir.Z * AutoFarm.speed)
    end
end

local function StopMovement()
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum:MoveTo(char.HumanoidRootPart.Position) end
    if AutoFarm._bv then AutoFarm._bv:Destroy(); AutoFarm._bv = nil end
end

local function TryMine(oreData)
    local inst = oreData.inst
    local prompt = inst:FindFirstChildOfClass("ProximityPrompt")
    if not prompt then
        for _, d in ipairs(inst:GetDescendants()) do
            if d:IsA("ProximityPrompt") then prompt = d; break end
        end
    end
    if prompt then
        pcall(function()
            prompt:InputHoldBegin()
            task.wait(prompt.HoldDuration or AutoFarm.mineTime)
            prompt:InputHoldEnd()
        end)
        return true
    end
    local cd = inst:FindFirstChildOfClass("ClickDetector")
    if not cd then
        for _, d in ipairs(inst:GetDescendants()) do
            if d:IsA("ClickDetector") then cd = d; break end
        end
    end
    if cd then pcall(function() fireclickdetector(cd) end); return true end
    local char = LP.Character
    if char then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then pcall(function() tool:Activate() end); return true end
    end
    return false
end

local function ScanNearbyPlayers()
    local char = LP.Character
    if not char then return {} end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return {} end
    local myPos = hrp.Position
    local result = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local theirHRP = plr.Character:FindFirstChild("HumanoidRootPart")
            local theirHum = plr.Character:FindFirstChildOfClass("Humanoid")
            if theirHRP and theirHum and theirHum.Health > 0 then
                local dist = (theirHRP.Position - myPos).Magnitude
                if dist <= AutoFarm.playerRadius then
                    table.insert(result, { plr = plr, dist = dist, hp = theirHum.Health })
                end
            end
        end
    end
    table.sort(result, function(a, b) return a.dist < b.dist end)
    return result
end

local function CheckPlayers()
    if not AutoFarm.playerDetect then
        AutoFarm.nearbyPlayers = {}
        if AutoFarm.playerPaused then AutoFarm.playerPaused = false end
        return false
    end
    local players = ScanNearbyPlayers()
    AutoFarm.nearbyPlayers = players
    local hasPlayers = #players > 0
    if hasPlayers then
        local closest = players[1]
        if not AutoFarm.playerPaused then
            print(string.format("[Rusted AutoFarm] ! Игрок рядом: %s (%.0f studs, %d HP)",
                closest.plr.Name, closest.dist, math.floor(closest.hp)))
        end
        AutoFarm.playerPaused = true
        AutoFarm.playerPauseEnd = tick() + AutoFarm.playerStopDelay
        if AutoFarm.playerAction == "stop" then
            AutoFarm.stoppedBy = "players"
            PlaySound("alert_player")
            task.spawn(PlayBeepSequence)
            ToggleAutoFarm(false)
            return true
        elseif AutoFarm.playerAction == "alert" then
            if not AutoFarm._lastAlert or tick() - AutoFarm._lastAlert > 3 then
                AutoFarm._lastAlert = tick()
                PlaySound("alert_player")
            end
        end
        return true
    else
        if AutoFarm.playerPaused then
            if tick() < AutoFarm.playerPauseEnd then
                return true
            else
                AutoFarm.playerPaused = false
                print("[Rusted AutoFarm] OK Игроки ушли, продолжаю фарм")
            end
        end
    end
    return false
end

local function CheckLimits()
    if AutoFarm.timeLimit > 0 then
        local elapsed = (tick() - AutoFarm.startTime) / 60
        if elapsed >= AutoFarm.timeLimit then
            AutoFarm.stoppedBy = "time"
            PlaySound("farm_complete")
            task.spawn(PlayBeepSequence)
            print(string.format("[Rusted AutoFarm] OK Время вышло (%.1f мин). Добыто: %d",
                elapsed, AutoFarm.kills))
            ToggleAutoFarm(false)
            return true
        end
    end
    if AutoFarm.killsLimit > 0 and AutoFarm.kills >= AutoFarm.killsLimit then
        AutoFarm.stoppedBy = "kills"
        PlaySound("farm_complete")
        task.spawn(PlayBeepSequence)
        print(string.format("[Rusted AutoFarm] OK Лимит ресурсов: %d. Остановлен.", AutoFarm.kills))
        ToggleAutoFarm(false)
        return true
    end
    return false
end

local function StartAutoFarm()
    if AutoFarm.bag then return end
    AutoFarm.bag = NewConnBag()
    AutoFarm.startTime = tick()
    AutoFarm.stoppedBy = nil
    AutoFarm.bag:add(RunService.Heartbeat:Connect(function(dt)
        if not AutoFarm.active then return end
        local char = LP.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        if tick() - AutoFarm.lastScan > 1 then
            if CheckLimits() then return end
        end
        if tick() - AutoFarm.lastPlayerCheck > 0.5 then
            AutoFarm.lastPlayerCheck = tick()
            local playersNear = CheckPlayers()
            if playersNear then
                StopMovement()
                UpdateHideUnderground()
                return
            end
        end
        UpdateHideUnderground()
        if AutoFarm.state == "idle" then
            local now = tick()
            if now - AutoFarm.lastScan < 1 then return end
            AutoFarm.lastScan = now
            local target = FindNearestOre()
            if target then
                AutoFarm.currentTarget = target
                AutoFarm.state = "moving"
            else
                StopMovement()
            end
        elseif AutoFarm.state == "moving" then
            local t = AutoFarm.currentTarget
            if not t or not t.part or not t.part.Parent then
                AutoFarm.state = "idle"; StopMovement(); return
            end
            local dist = (t.part.Position - hrp.Position).Magnitude
            if dist <= AutoFarm.reachDist then
                StopMovement()
                AutoFarm.state = "mining"
                AutoFarm.mineStart = tick()
            else
                MoveToward(t.part.Position, dt)
            end
        elseif AutoFarm.state == "mining" then
            if tick() - AutoFarm.mineStart >= AutoFarm.mineTime then
                TryMine(AutoFarm.currentTarget)
                AutoFarm.kills += 1
                AutoFarm.currentTarget = nil
                AutoFarm.state = "idle"
                StopMovement()
            end
        end
    end))
end

local function StopAutoFarm()
    if AutoFarm.bag then AutoFarm.bag:destroy(); AutoFarm.bag = nil end
    StopMovement()
    AutoFarm.state = "idle"
    AutoFarm.currentTarget = nil
    AutoFarm.playerPaused = false
    CleanupHide()
end

local function ToggleAutoFarm(state)
    AutoFarm.active = state
    if state then
        AutoFarm.kills = 0
        AutoFarm.stoppedBy = nil
        StartAutoFarm()
        print("[Rusted AutoFarm] Запущен. Режим: " .. AutoFarm.mode)
    else
        StopAutoFarm()
        if not AutoFarm.stoppedBy then
            print("[Rusted AutoFarm] Остановлен вручную. Добыто: " .. AutoFarm.kills)
        end
    end
end

local WallLoot = { active = false, maxDist = 500, autoLoot = false, lootDelay = 0.15, conn = nil, lastLoot = 0 }

local REMOTE_KEYWORDS = {"loot", "pickup", "grab", "take", "collect", "interact", "open", "chest", "crate", "container", "storage"}
local CONTAINER_KEYWORDS = {"crate", "box", "chest", "loot", "supply", "barrel", "storage", "container", "cabinet", "locker", "safe", "fridge", "rt", "terminal", "computer", "recycler", "furnace"}

local lootRemotes = nil
local function FindLootRemotes()
    if lootRemotes then return lootRemotes end
    lootRemotes = {}
    for _, obj in ipairs(game:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local n = string.lower(obj.Name)
            for _, kw in ipairs(REMOTE_KEYWORDS) do
                if n:find(kw, 1, true) then
                    table.insert(lootRemotes, obj); break
                end
            end
        end
    end
    return lootRemotes
end

local function FireLootRemotes(targetPart)
    for _, remote in ipairs(FindLootRemotes()) do
        pcall(function()
            if remote:IsA("RemoteEvent") then remote:FireServer(targetPart)
            else remote:InvokeServer(targetPart) end
        end)
    end
end

local function IsContainer(inst)
    if not inst:IsA("BasePart") and not inst:IsA("Model") then return false end
    local name = string.lower(inst.Name)
    for _, kw in ipairs(CONTAINER_KEYWORDS) do
        if name:find(kw, 1, true) then return true end
    end
    if inst:IsA("BasePart") then
        if inst:FindFirstChildOfClass("ProximityPrompt") then return true end
        if inst:FindFirstChildOfClass("ClickDetector") then return true end
    end
    return false
end

local function GetParts(inst)
    if inst:IsA("BasePart") then return { inst } end
    if inst:IsA("Model") then
        local parts = {}
        for _, p in ipairs(inst:GetDescendants()) do
            if p:IsA("BasePart") then table.insert(parts, p) end
        end
        return parts
    end
    return {}
end

local function LootEverything()
    local myHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return 0 end
    local myPos = myHRP.Position
    local count = 0
    for _, inst in ipairs(workspace:GetDescendants()) do
        if IsContainer(inst) then
            local parts = GetParts(inst)
            local mainPart = parts[1]
            if mainPart then
                local dist = (mainPart.Position - myPos).Magnitude
                if dist <= WallLoot.maxDist then
                    local prompt = inst:FindFirstChildOfClass("ProximityPrompt")
                    if prompt then
                        pcall(function()
                            prompt:InputHoldBegin()
                            task.wait(prompt.HoldDuration or 0)
                            prompt:InputHoldEnd()
                        end)
                        count += 1
                    end
                    local cd = inst:FindFirstChildOfClass("ClickDetector")
                    if cd then
                        pcall(function() fireclickdetector(cd) end)
                        count += 1
                    end
                    FireLootRemotes(mainPart)
                end
            end
        end
    end
    return count
end

local function StartWallLoot()
    if WallLoot.conn then return end
    WallLoot.conn = RunService.Heartbeat:Connect(function()
        if not WallLoot.active or not WallLoot.autoLoot then return end
        local now = tick()
        if now - WallLoot.lastLoot < WallLoot.lootDelay then return end
        WallLoot.lastLoot = now
        pcall(LootEverything)
    end)
end

local function ToggleWallLoot(state)
    WallLoot.active = state
    if state then StartWallLoot()
    else
        if WallLoot.conn then WallLoot.conn:Disconnect(); WallLoot.conn = nil end
        lootRemotes = nil
    end
end

local function ToggleAutoLoot(state) WallLoot.autoLoot = state end

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.L then
        local n = LootEverything()
        print("[Rusted] Собрано контейнеров: " .. tostring(n))
    end
end)

local CodeLock = { active = false, showHud = true, radius = 300, conn = nil, found = {} }

local CODE_KEYWORDS = {"code", "password", "pass", "pin", "combination", "combo", "key"}
local LOCK_KEYWORDS = {"codelock", "code_lock", "keypad", "door", "gate", "lock", "code"}

local function HasKeyword(str, list)
    local s = string.lower(str)
    for _, k in ipairs(list) do
        if s:find(k, 1, true) then return true end
    end
    return false
end

local function ExtractCode(inst)
    for attrName, attrVal in pairs(inst:GetAttributes()) do
        if HasKeyword(attrName, CODE_KEYWORDS) then
            if type(attrVal) == "string" or type(attrVal) == "number" then
                return tostring(attrVal), "attribute:" .. attrName
            end
        end
    end
    for _, child in ipairs(inst:GetDescendants()) do
        if child:IsA("StringValue") or child:IsA("NumberValue") or child:IsA("IntValue") then
            if HasKeyword(child.Name, CODE_KEYWORDS) then
                return tostring(child.Value), "value:" .. child.Name
            end
        end
    end
    for _, child in ipairs(inst:GetDescendants()) do
        if child:IsA("TextLabel") or child:IsA("TextBox") then
            if HasKeyword(child.Name, CODE_KEYWORDS) and child.Text ~= "" then
                return child.Text, "text:" .. child.Name
            end
        end
    end
    local parent = inst.Parent
    if parent then
        for _, gui in ipairs(parent:GetDescendants()) do
            if gui:IsA("SurfaceGui") or gui:IsA("BillboardGui") then
                for _, txt in ipairs(gui:GetDescendants()) do
                    if txt:IsA("TextLabel") and txt.Text ~= "" then
                        local t = txt.Text
                        if #t <= 12 and t:match("^%d+$") then
                            return t, "surfacegui:" .. txt.Name
                        end
                    end
                end
            end
        end
    end
    return nil, nil
end

local function IsCodeLock(inst)
    if not inst:IsA("BasePart") and not inst:IsA("Model") then return false end
    return HasKeyword(inst.Name, LOCK_KEYWORDS)
end

local function CreateCodeLabel(part, code)
    local bb = Instance.new("BillboardGui")
    bb.Name = "RustedCodeLabel"
    bb.Size = UDim2.new(0, 200, 0, 40)
    bb.StudsOffset = Vector3.new(0, 4, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 500
    bb.Adornee = part
    bb.Parent = espFolder
    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.new(1, 0, 1, 0)
    tl.BackgroundTransparency = 0.3
    tl.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    tl.TextColor3 = Color3.fromRGB(80, 255, 120)
    tl.TextSize = 16
    tl.Font = Enum.Font.Code
    tl.TextStrokeTransparency = 0
    tl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    tl.Text = "[CODE] " .. code
    tl.Parent = bb
    return bb
end

local function ScanCodeLocks()
    local myHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end
    local myPos = myHRP.Position
    local found = {}
    for _, inst in ipairs(workspace:GetDescendants()) do
        if IsCodeLock(inst) then
            local mainPart
            if inst:IsA("BasePart") then mainPart = inst
            elseif inst:IsA("Model") then
                mainPart = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")
            end
            if mainPart then
                local dist = (mainPart.Position - myPos).Magnitude
                if dist <= CodeLock.radius then
                    local code, source = ExtractCode(inst)
                    if code then
                        found[inst] = true
                        if not CodeLock.found[inst] then
                            CodeLock.found[inst] = {
                                part = mainPart, code = code, source = source,
                                label = CodeLock.showHud and CreateCodeLabel(mainPart, code) or nil,
                            }
                            print(string.format("[Rusted CodeLock] %s -> %s (%s)",
                                inst:GetFullName(), code, source))
                        else
                            local d = CodeLock.found[inst]
                            if d.code ~= code and d.label then
                                d.code = code
                                d.label:FindFirstChildOfClass("TextLabel").Text = "[CODE] " .. code
                            end
                            d.part = mainPart
                        end
                    end
                end
            end
        end
    end
    for inst, d in pairs(CodeLock.found) do
        if not found[inst] or not inst.Parent then
            if d.label then d.label:Destroy() end
            CodeLock.found[inst] = nil
        end
    end
end

local function StartCodeLockScanner()
    if CodeLock.conn then return end
    local frame = 0
    CodeLock.conn = RunService.Heartbeat:Connect(function()
        if not CodeLock.active then return end
        frame += 1
        if frame % 90 == 0 then pcall(ScanCodeLocks) end
    end)
end

local function ToggleCodeLock(state)
    CodeLock.active = state
    if state then StartCodeLockScanner()
    else
        if CodeLock.conn then CodeLock.conn:Disconnect(); CodeLock.conn = nil end
        for inst, d in pairs(CodeLock.found) do
            if d.label then d.label:Destroy() end
        end
        CodeLock.found = {}
    end
end

local function DumpAllCodes()
    print("[Rusted] === Все кодовые замки ===")
    local count = 0
    for _, inst in ipairs(workspace:GetDescendants()) do
        if IsCodeLock(inst) then
            local code, source = ExtractCode(inst)
            if code then
                count += 1
                print(string.format("  [%d] %s -> %s  (%s)",
                    count, inst:GetFullName(), code, source))
            else
                print(string.format("  [!] %s - код не найден", inst:GetFullName()))
            end
        end
    end
    print(string.format("[Rusted] Всего: %d", count))
end

local codeHookActive = false
local function EnableCodeHook()
    if codeHookActive then return end
    codeHookActive = true
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        if method == "FireServer" and self:IsA("RemoteEvent") then
            local n = string.lower(self.Name)
            if HasKeyword(n, {"code", "pin", "pass", "key", "submit", "enter", "unlock"}) then
                for _, arg in ipairs(args) do
                    if type(arg) == "string" and #arg <= 16 then
                        print(string.format("[Rusted CodeHook] %s -> %s", self:GetFullName(), arg))
                    elseif type(arg) == "number" and arg < 1e7 then
                        print(string.format("[Rusted CodeHook] %s -> %d", self:GetFullName(), arg))
                    end
                end
            end
        end
        return oldNamecall(self, ...)
    end)
end

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.K then DumpAllCodes() end
end)

local Watcher = {
    enabled = false, minDot = 0.7, minMoveDot = 0.4,
    triggerTime = 5, useVisibility = true, showName = true, sound = true,
    trackers = {}, activeWarnings = {},
}

local WarningContainer = Instance.new("Frame")
WarningContainer.Name = "RustedWarnings"
WarningContainer.Size = UDim2.new(1, 0, 0, 200)
WarningContainer.Position = UDim2.new(0, 0, 0, 60)
WarningContainer.BackgroundTransparency = 1
WarningContainer.Parent = ScreenGui

local WarnLayout = Instance.new("UIListLayout")
WarnLayout.Padding = UDim.new(0, 6)
WarnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
WarnLayout.SortOrder = Enum.SortOrder.LayoutOrder
WarnLayout.Parent = WarningContainer

local function ShowWarning(plr, text)
    if Watcher.activeWarnings[plr] then
        Watcher.activeWarnings[plr].label.Text = text
        Watcher.activeWarnings[plr].expire = tick() + 3
        return
    end
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 400, 0, 44)
    frame.BackgroundColor3 = Color3.fromRGB(180, 20, 20)
    frame.BackgroundTransparency = 0.15
    frame.BorderSizePixel = 0
    frame.Parent = WarningContainer
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 80, 80)
    stroke.Thickness = 2
    stroke.Parent = frame
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 16
    label.Font = Enum.Font.GothamBold
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.Parent = frame
    frame.label = label
    frame.expire = tick() + 3
    frame.LayoutOrder = math.floor(tick() * 1000) % 1000
    Watcher.activeWarnings[plr] = frame
    frame.Size = UDim2.new(0, 0, 0, 44)
    TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 400, 0, 44)
    }):Play()
    if Watcher.sound then PlaySound("alert_player", 0.7) end
end

local function HideWarning(plr)
    local frame = Watcher.activeWarnings[plr]
    if not frame then return end
    Watcher.activeWarnings[plr] = nil
    TweenService:Create(frame, TweenInfo.new(0.3), {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 0, 0, 44)
    }):Play()
    task.delay(0.3, function() frame:Destroy() end)
end

local WatchRayParams = RaycastParams.new()
WatchRayParams.FilterType = Enum.RaycastFilterType.Exclude
WatchRayParams.IgnoreWater = true

local function CanSeeMe(theirChar)
    if not Watcher.useVisibility then return true end
    local myChar = LP.Character
    if not myChar then return false end
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    local theirHRP = theirChar:FindFirstChild("HumanoidRootPart")
    if not myHRP or not theirHRP then return false end
    WatchRayParams.FilterDescendantsInstances = { theirChar, myChar, espFolder }
    local dir = myHRP.Position - theirHRP.Position
    local result = workspace:Raycast(theirHRP.Position, dir, WatchRayParams)
    if not result then return false end
    return result.Instance:IsDescendantOf(myChar)
end

local function UpdateWatchers(dt)
    if not Watcher.enabled then return end
    local myChar = LP.Character
    if not myChar then return end
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end
    local myPos = myHRP.Position
    local now = tick()
    local currentSeen = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local theirChar = plr.Character
            local theirHRP = theirChar:FindFirstChild("HumanoidRootPart")
            local theirHum = theirChar:FindFirstChildOfClass("Humanoid")
            if theirHRP and theirHum and theirHum.Health > 0 then
                currentSeen[plr] = true
                local tracker = Watcher.trackers[plr]
                if not tracker then
                    tracker = { time = 0, lastUpdate = now }
                    Watcher.trackers[plr] = tracker
                end
                local toMe = myPos - theirHRP.Position
                local dist = toMe.Magnitude
                local toMeUnit = toMe.Unit
                local lookDot = theirHRP.CFrame.LookVector:Dot(toMeUnit)
                local lookingAtMe = lookDot >= Watcher.minDot
                local vel = theirHRP.AssemblyLinearVelocity
                local moveSpeed = Vector3.new(vel.X, 0, vel.Z).Magnitude
                local movingToMe = false
                if moveSpeed > 5 then
                    local moveDir = Vector3.new(vel.X, 0, vel.Z).Unit
                    local horizToMe = Vector3.new(toMeUnit.X, 0, toMeUnit.Z).Unit
                    movingToMe = moveDir:Dot(horizToMe) >= Watcher.minMoveDot
                end
                local sees = CanSeeMe(theirChar)
                local allMatch = lookingAtMe and movingToMe and sees and dist < 500
                if allMatch then
                    tracker.time += dt
                    tracker.lastSeen = now
                else
                    tracker.time = math.max(0, tracker.time - dt * 2)
                end
                if tracker.time >= Watcher.triggerTime then
                    local text = Watcher.showName
                        and ("!! " .. plr.Name .. " смотрит на тебя!")
                        or "!! ОБНАРУЖЕН!"
                    ShowWarning(plr, text)
                    tracker.time = 0
                end
                local w = Watcher.activeWarnings[plr]
                if w then
                    if dist > 600 or not sees then HideWarning(plr)
                    elseif now > w.expire then HideWarning(plr) end
                end
            end
        end
    end
    for plr, _ in pairs(Watcher.trackers) do
        if not currentSeen[plr] then
            Watcher.trackers[plr] = nil
            HideWarning(plr)
        end
    end
end

local watcherFrame = 0
RunService.Heartbeat:Connect(function(dt)
    if not Watcher.enabled then return end
    watcherFrame += 1
    if watcherFrame % 3 == 0 then pcall(UpdateWatchers, dt * 3) end
end)

local function ToggleWatcher(state)
    Watcher.enabled = state
    if not state then
        for plr, _ in pairs(Watcher.activeWarnings) do HideWarning(plr) end
        Watcher.trackers = {}
    end
end

local frameCounter = 0
RunService.RenderStepped:Connect(function(dt)
    frameCounter += 1
    local anyActive = ESP.players or ESP.bots or ESP.boxes or ESP.ores or ESP.rt or ESP.radar
    if not anyActive then
        UpdateAim(dt)
        return
    end
    if ESP.players then
        for plr, d in pairs(playerESP) do
            local char = plr.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hrp and hum then
                local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
                if dist <= ESP.maxDist then
                    d.box.Adornee = hrp
                    d.box.Visible = true
                    if ESP.rainbow then d.box.Color3 = RainbowColor(d.hue)
                    else d.box.Color3 = Color3.fromRGB(255, 80, 80) end
                    if frameCounter % 8 == 0 then
                        d.visible = IsCharVisible(char)
                    end
                    if d.visible then d.box.Transparency = 0.4
                    else d.box.Transparency = 0.75 end
                    if frameCounter % 4 == 0 and d.info then
                        local distM = math.floor(dist / 3)
                        local hp = math.floor(hum.Health)
                        local maxHp = math.floor(hum.MaxHealth)
                        local weapons = GetPlayerWeapons(plr)
                        local weaponText = FormatWeaponList(weapons)
                        if d.visible then
                            d.info.gui.Enabled = true
                            d.info.label.Text = string.format("%s\nHP %d/%d | %.0f | %s",
                                plr.Name, hp, maxHp, distM, weaponText)
                            d.info.gui.Adornee = hrp
                            local hpRatio = hum.Health / math.max(hum.MaxHealth, 1)
                            d.info.label.TextColor3 = Color3.fromRGB(255,
                                math.floor(100 + 155 * hpRatio), math.floor(100 * hpRatio))
                        else
                            d.info.gui.Enabled = false
                        end
                    end
                    if LookTracer.enabled then
                        local head = char:FindFirstChild("Head") or hrp
                        local adorn = LookTracer.tracers[plr]
                        if not adorn then
                            adorn = NewLookTracer(plr)
                            LookTracer.tracers[plr] = adorn
                        end
                        adorn.Adornee = head
                        adorn.CFrame = head.CFrame
                        adorn.Length = LookTracer.length
                        adorn.Transparency = LookTracer.transparency
                    elseif LookTracer.tracers[plr] then
                        KillLookTracer(LookTracer.tracers[plr])
                        LookTracer.tracers[plr] = nil
                    end
                else
                    d.box.Visible = false
                    if d.info then d.info.gui.Enabled = false end
                    if LookTracer.tracers[plr] then
                        LookTracer.tracers[plr].Transparency = 1
                    end
                end
            else
                d.box.Visible = false
                if d.info then d.info.gui.Adornee = nil end
                if LookTracer.tracers[plr] then
                    KillLookTracer(LookTracer.tracers[plr])
                    LookTracer.tracers[plr] = nil
                end
            end
        end
    end
    if ESP.bots and frameCounter % 180 == 0 then ScanBots() end
    if ESP.bots and frameCounter % 10 == 0 then
        local camPos = Camera.CFrame.Position
        local alive = {}
        for model, d in pairs(botESP) do
            local hrp = model:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (camPos - hrp.Position).Magnitude
                if dist <= ESP.botMaxDist then
                    table.insert(alive, { model = model, data = d, hrp = hrp, dist = dist })
                end
            end
        end
        table.sort(alive, function(a, b) return a.dist < b.dist end)
        for model, d in pairs(botESP) do d.box.Visible = false end
        for i, entry in ipairs(alive) do
            if i <= ESP.botLimit then
                entry.data.box.Adornee = entry.hrp
                entry.data.box.Visible = true
                if ESP.rainbow then entry.data.box.Color3 = RainbowColor(entry.data.hue)
                else entry.data.box.Color3 = Color3.fromRGB(255, 200, 60) end
            end
        end
    end
    if ESP.boxes and frameCounter % 240 == 0 then ScanBoxes() end
    if ESP.boxes then
        for part, d in pairs(boxESP) do
            if part.Parent then
                d.box.Adornee = part
                d.box.Visible = true
                if d.label then d.label.Adornee = part end
            else
                KillBox(d.box)
                if d.label then d.label:Destroy() end
                boxESP[part] = nil
            end
        end
    end
    if ESP.ores and frameCounter % 180 == 0 then ScanOres() end
    if ESP.ores then
        for part, d in pairs(oreESP) do
            if part.Parent then
                d.box.Adornee = part
                d.box.Visible = true
                if d.label then d.label.Adornee = part end
            else
                KillBox(d.box)
                if d.label then d.label:Destroy() end
                oreESP[part] = nil
            end
        end
    end
    if ESP.rt and frameCounter % 240 == 0 then ScanRT() end
    if ESP.rt then
        for inst, d in pairs(rtESP) do
            if d.part and d.part.Parent then
                d.box.Adornee = d.part
                d.box.Visible = true
                if d.label then d.label.Adornee = d.part end
            else
                KillBox(d.box)
                if d.label then d.label:Destroy() end
                rtESP[inst] = nil
            end
        end
    end
    if ESP.radar and frameCounter % 3 == 0 then
        local myHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if myHRP then
            local myPos = myHRP.Position
            local myLook = Camera.CFrame.LookVector
            local angle = math.atan2(myLook.X, myLook.Z)
            for _, d in pairs(radarActive) do KillRadarDot(d) end
            radarActive = {}
            for plr, _ in pairs(playerESP) do
                local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local delta = hrp.Position - myPos
                    local dist = Vector3.new(delta.X, 0, delta.Z).Magnitude
                    if dist <= ESP.range then
                        local rel = Vector3.new(
                            delta.X * math.cos(-angle) - delta.Z * math.sin(-angle), 0,
                            delta.X * math.sin(-angle) + delta.Z * math.cos(-angle))
                        local nx = 0.5 + (rel.X / ESP.range) * 0.5
                        local ny = 0.5 - (rel.Z / ESP.range) * 0.5
                        local dot = NewRadarDot()
                        dot.Position = UDim2.new(nx, 0, ny, 0)
                        dot.BackgroundColor3 = ESP.rainbow
                            and RainbowColor(plr.UserId % 100 / 100)
                            or Color3.fromRGB(255, 80, 80)
                        radarActive[plr] = dot
                    end
                end
            end
        end
    end
    UpdateAim(dt)
end)

Players.PlayerAdded:Connect(function(plr)
    if ESP.players then AddPlayerESP(plr) end
    plr.CharacterAdded:Connect(function()
        if ESP.players then AddPlayerESP(plr) end
    end)
end)
Players.PlayerRemoving:Connect(RemovePlayerESP)

local function TogglePlayerESP(state)
    ESP.players = state
    if state then
        for _, plr in ipairs(Players:GetPlayers()) do AddPlayerESP(plr) end
    else
        for plr, d in pairs(playerESP) do
            KillBox(d.box)
            if d.info and d.info.gui then d.info.gui:Destroy() end
            playerESP[plr] = nil
        end
        playerESP = {}
        for plr, ad in pairs(LookTracer.tracers) do
            KillLookTracer(ad)
        end
        LookTracer.tracers = {}
    end
end

local function ToggleRainbow(state) ESP.rainbow = state end

local function ToggleBotESP(state)
    ESP.bots = state
    if state then ScanBots()
    else
        for m, d in pairs(botESP) do KillBox(d.box); botESP[m] = nil end
        botESP = {}
    end
end

local function ToggleBoxESP(state)
    ESP.boxes = state
    if state then ScanBoxes()
    else
        for p, d in pairs(boxESP) do
            KillBox(d.box); if d.label then d.label:Destroy() end
            boxESP[p] = nil
        end
        boxESP = {}
    end
end

local function ToggleOreESP(state)
    ESP.ores = state
    if state then ScanOres()
    else
        for p, d in pairs(oreESP) do
            KillBox(d.box); if d.label then d.label:Destroy() end
            oreESP[p] = nil
        end
        oreESP = {}
    end
end

local function ToggleRTESP(state)
    ESP.rt = state
    if state then ScanRT()
    else
        for inst, d in pairs(rtESP) do
            KillBox(d.box); if d.label then d.label:Destroy() end
            rtESP[inst] = nil
        end
        rtESP = {}
    end
end

local function ToggleRadar(state)
    ESP.radar = state
    RadarGui.Visible = state
    if not state then
        for _, d in pairs(radarActive) do KillRadarDot(d) end
        radarActive = {}
    end
end

local function TeleportTo(name)
    local target = Players:FindFirstChild(name)
    if not target or not target.Character then return end
    local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
    local myHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if tHRP and myHRP then myHRP.CFrame = tHRP.CFrame * CFrame.new(0, 0, 3) end
end

local function Rejoin()
    if queue_on_teleport then
        queue_on_teleport([[
            loadstring(game:HttpGet("https://raw.githubusercontent.com/TPYCblSweetyFox/PizdecRust/main/main.lua"))()
        ]])
    end
    TeleportService:Teleport(game.PlaceId, LP)
end

local MainTab = CreateTab("Главное")
CreateButton(MainTab, "Переподключиться (Rejoin)", Rejoin)

local VisualTab = CreateTab("Визуал")
CreateToggle(VisualTab, "ESP игроков", false, TogglePlayerESP)
CreateToggle(VisualTab, "Радужный ESP", false, ToggleRainbow)
CreateToggle(VisualTab, "ESP ботов", false, ToggleBotESP)
CreateToggle(VisualTab, "ESP ящиков", false, ToggleBoxESP)
CreateToggle(VisualTab, "ESP руд", false, ToggleOreESP)
CreateToggle(VisualTab, "ESP RT", false, ToggleRTESP)
CreateToggle(VisualTab, "Радар", false, ToggleRadar)
CreateToggle(VisualTab, "Трейсер взгляда игроков", false, ToggleLookTracer)
CreateSlider(VisualTab, "ESP игроков — макс. дистанция", 100, 3000, 1200, function(v) ESP.maxDist = v end)
CreateSlider(VisualTab, "ESP ботов — макс. дистанция", 100, 2000, 600, function(v) ESP.botMaxDist = v end)
CreateSlider(VisualTab, "ESP ботов — лимит штук", 5, 100, 30, function(v) ESP.botLimit = v end)
CreateSlider(VisualTab, "Трейсер — длина линии", 50, 1000, 500, function(v) LookTracer.length = v end)
CreateSlider(VisualTab, "Радар — дальность", 50, 2000, 500, function(v) ESP.range = v end)
CreateToggle(VisualTab, "Ночное видение", false, ToggleNightVision)
CreateToggle(VisualTab, "Убрать траву и листву", false, ToggleEnvClean)

local MoveTab = CreateTab("Мувмент")
CreateToggle(MoveTab, "Бесконечный прыжок", false, ToggleInfJump)
CreateToggle(MoveTab, "Полёт (WASD + Space/Ctrl)", false, ToggleFly)
CreateToggle(MoveTab, "Wall Climb (пробел у стены)", false, ToggleWallClimb)
CreateSlider(MoveTab, "Wall Climb — скорость", 10, 150, 45, function(v) WallClimb.speed = v end)
CreateToggle(MoveTab, "Ускорение (WalkSpeed = 100)", false, ToggleWS)
CreateToggle(MoveTab, "Высокий прыжок (JumpPower = 200)", false, function(s)
    jpValue = 200
    ToggleJP(s)
end)
CreateToggle(MoveTab, "Noclip (платформа-толкач)", false, ToggleHardNoclip)
CreateSlider(MoveTab, "Скорость ноклипа", 30, 400, 120, function(v) Noclip.speed = v end)
CreateToggle(MoveTab, "Freecam (клавиша F)", false, ToggleFreecam)
CreateSlider(MoveTab, "Скорость Freecam", 10, 300, 60, function(v) Freecam.speed = v end)
CreateToggle(MoveTab, "Убрать урон от падения", false, ToggleFallDamage)
CreateToggle(MoveTab, "Спасение из-под карты (< -80)", true, ToggleVoidTP)
CreateSlider(MoveTab, "Порог Y", -500, -10, -80, function(v) VoidTP.threshold = v end)
CreateSlider(MoveTab, "Высота возврата", 0, 200, 5, function(v) VoidTP.targetY = v end)
CreateToggle(MoveTab, "Кидать на SpawnLocation", false, function(s) VoidTP.useSpawn = s end)

local AimTab = CreateTab("Аим")
CreateToggle(AimTab, "Silent Aim (ПКМ)", false, ToggleSilentAim)
CreateToggle(AimTab, "Aimlock (ПКМ)", false, ToggleAimlock)
CreateToggle(AimTab, "Показывать FOV круг", false, ToggleFovVisible)
local PartBtn = CreateButton(AimTab, "Цель: Head", function() end)
local partIndex = 1
local parts = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}
PartBtn.MouseButton1Click:Connect(function()
    partIndex = (partIndex % #parts) + 1
    Aim.part = parts[partIndex]
    PartBtn.Text = "Цель: " .. Aim.part
end)
CreateSlider(AimTab, "FOV (радиус)", 30, 500, 150, function(v) Aim.fov = v end)
CreateSlider(AimTab, "Плавность аимлока", 0, 95, 25, function(v) Aim.smooth = v / 100 end)
CreateToggle(AimTab, "Режим удержания", true, function(s) Aim.holdKey = s end)
CreateToggle(AimTab, "Проверка на видимость", true, function(s) Aim.visible = s end)

local PlayerTab = CreateTab("Игроки")
local massFrame = Instance.new("Frame")
massFrame.Size = UDim2.new(1, -8, 0, 32)
massFrame.BackgroundTransparency = 1
massFrame.Parent = PlayerTab
CreateButton(massFrame, "ОТПРАВИТЬ ВСЕХ В КОСМОС", SendAllToSpace)

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
            CreateButton(listFrame, "TP -> " .. plr.Name, function() TeleportTo(plr.Name) end)
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
            spaceBtn.MouseButton1Click:Connect(function() SendToSpace(plr) end)
        end
    end
end

RefreshPlayerList()
Players.PlayerAdded:Connect(function() task.wait(0.5) RefreshPlayerList() end)
Players.PlayerRemoving:Connect(function() task.wait(0.5) RefreshPlayerList() end)

local FarmTab = CreateTab("Фарм")
CreateToggle(FarmTab, "Автофарм (по рудам)", false, ToggleAutoFarm)

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
CreateSlider(FarmTab, "Время добычи (сек)", 1, 15, 3, function(v) AutoFarm.mineTime = v end)
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

CreateSlider(FarmTab, "Кастомный лимит времени (мин)", 0, 240, 0, function(v)
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

CreateSlider(FarmTab, "Радиус детектора (studs)", 30, 500, 150, function(v) AutoFarm.playerRadius = v end)
CreateSlider(FarmTab, "Пауза после ухода (сек)", 1, 60, 5, function(v) AutoFarm.playerStopDelay = v end)

CreateToggle(FarmTab, "Нырок под землю при игроке", false, ToggleHideUnderground)

CreateButton(FarmTab, "Статус фарма", function()
    local elapsed = AutoFarm.active and ((tick() - AutoFarm.startTime) / 60) or 0
    print("=== AutoFarm Status ===")
    print("Активен:", AutoFarm.active)
    print("Состояние:", AutoFarm.state)
    print("Добыто:", AutoFarm.kills)
    print("Прошло:", string.format("%.1f мин", elapsed))
    print("Игроков рядом:", #AutoFarm.nearbyPlayers)
    for _, p in ipairs(AutoFarm.nearbyPlayers) do
        print(string.format("  %s - %.0f studs, %d HP", p.plr.Name, p.dist, math.floor(p.hp)))
    end
    print("Нырок:", HideUnderground.state)
end)

local LootTab = CreateTab("Лут")
CreateToggle(LootTab, "Лут через стены", false, ToggleWallLoot)
CreateToggle(LootTab, "Авто-режим (цикл)", false, ToggleAutoLoot)
CreateSlider(LootTab, "Дистанция лута", 50, 2000, 500, function(v) WallLoot.maxDist = v end)
CreateSlider(LootTab, "Задержка лута (мс)", 50, 1000, 150, function(v) WallLoot.lootDelay = v / 1000 end)
CreateButton(LootTab, "Собрать всё сейчас (клавиша L)", function()
    local n = LootEverything()
    print("[Rusted] Собрано: " .. tostring(n))
end)

local CodesTab = CreateTab("Коды")
CreateToggle(CodesTab, "Показывать коды над дверями", false, ToggleCodeLock)
CreateSlider(CodesTab, "Радиус скана кодов", 50, 2000, 300, function(v) CodeLock.radius = v end)
CreateToggle(CodesTab, "Хук ввода паролей", false, function(s) if s then EnableCodeHook() end end)
CreateButton(CodesTab, "Dump всех кодов (клавиша K)", DumpAllCodes)

local ProtectTab = CreateTab("Защита")
CreateToggle(ProtectTab, "Детектор взгляда (красная надпись)", false, ToggleWatcher)
CreateSlider(ProtectTab, "Точность взгляда", 50, 95, 70, function(v) Watcher.minDot = v / 100 end)
CreateSlider(ProtectTab, "Требование движения к тебе", 0, 90, 40, function(v) Watcher.minMoveDot = v / 100 end)
CreateSlider(ProtectTab, "Секунд до срабатывания", 1, 15, 5, function(v) Watcher.triggerTime = v end)
CreateToggle(ProtectTab, "Требовать прямую видимость", true, function(s) Watcher.useVisibility = s end)
CreateToggle(ProtectTab, "Показывать имя игрока", true, function(s) Watcher.showName = s end)
CreateToggle(ProtectTab, "Звук при срабатывании", true, function(s) Watcher.sound = s end)
CreateToggle(ProtectTab, "Звуки вообще", true, function(s) Sound.enabled = s end)

if Tabs["Главное"] then Tabs["Главное"].btn.MouseButton1Click:Fire() end

print("[Rusted] Загружен успешно v2.")
print("[Rusted] Хоткеи: RightShift - меню, L - лут, K - dump кодов, F - freecam")
