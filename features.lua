--[[ FEATURES — все функции: движение, ESP, AutoFarm, Watcher ]]

local CORE = ...
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
local IS_MOBILE = CORE.IS_MOBILE

local F = {}

-- ============================================================
--  MOVEMENT
-- ============================================================

local wsValue = 18
local wsBag = nil
function F.ToggleWS(state)
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
function F.ToggleJP(state)
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
F.SetJPValue = function(v) jpValue = v end

local infJumpBag = nil
function F.ToggleInfJump(state)
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

-- Fly — только горизонтальный (вертикаль режется сервером)
local flyActive = false
local flyBV, flyConn
function F.ToggleFly(state)
    flyActive = state
    if state then
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if not hum then return end

        flyBV = Instance.new("BodyVelocity")
        flyBV.MaxForce = Vector3.new(5e4, 0, 5e4)
        flyBV.Velocity = Vector3.zero
        flyBV.Parent = hrp

        flyConn = RunService.RenderStepped:Connect(function()
            if not flyActive or not hrp or not hrp.Parent then return end

            local move = Vector3.zero
            local cam = Camera.CFrame
            -- На мобиле — движение только через AutoFarm или позицию камеры
            if UserInputService.KeyboardEnabled then
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cam.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cam.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cam.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cam.RightVector end
            end

            -- Убираем вертикальную составляющую (сервер режет)
            local horiz = Vector3.new(move.X, 0, move.Z)
            if horiz.Magnitude > 0 then horiz = horiz.Unit end

            -- Скорость 15 — безопасно
            flyBV.Velocity = Vector3.new(horiz.X * 15, 0, horiz.Z * 15)
        end)
    else
        if flyConn then flyConn:Disconnect(); flyConn = nil end
        if flyBV then flyBV:Destroy(); flyBV = nil end
    end
end

-- Noclip — только горизонтальный
local Noclip = { active = false, speed = 15, platform = nil, bv = nil, conns = {} }
F.Noclip = Noclip

local function CreateNoclipPlatform()
    local p = Instance.new("Part")
    p.Name = "RustedNoclipPlatform"
    p.Size = Vector3.new(6, 1, 6)
    p.Transparency = 1
    p.CanCollide = true
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
    Noclip.platform.CFrame = CFrame.new(hrp.Position - Vector3.new(0, 3, 0))

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = hrp
    weld.Part1 = Noclip.platform
    weld.Parent = Noclip.platform

    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            p.CanCollide = false
            p.CanQuery = false
            p.CanTouch = false
        end
    end

    local bv = Instance.new("BodyVelocity")
    bv.Name = "RustedNoclipBV"
    bv.MaxForce = Vector3.new(5e4, 0, 5e4)
    bv.Velocity = Vector3.zero
    bv.Parent = hrp
    Noclip.bv = bv

    table.insert(Noclip.conns, RunService.Heartbeat:Connect(function()
        if not Noclip.active then return end
        local c = LP.Character
        if not c then return end
        local myHrp = c:FindFirstChild("HumanoidRootPart")
        if not myHrp then return end
        local myHum = c:FindFirstChildOfClass("Humanoid")
        if not myHum or not Noclip.bv or not Noclip.bv.Parent then return end

        local moveDir = myHum.MoveDirection
        if moveDir.Magnitude > 0.1 then
            -- Только XZ движение, без Y (сервер режет Y)
            local horiz = Vector3.new(moveDir.X, 0, moveDir.Z).Unit
            Noclip.bv.Velocity = horiz * Noclip.speed
        else
            Noclip.bv.Velocity = Vector3.zero
        end

        if Noclip.platform and Noclip.platform.Parent then
            Noclip.platform.CFrame = CFrame.new(myHrp.Position - Vector3.new(0, 3, 0))
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

function F.ToggleHardNoclip(state)
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
                    p.Massless = false
                end
            end
        end
    end
end

-- Fall Damage
local fallDamageBag = nil
function F.ToggleFallDamage(state)
    if state then
        fallDamageBag = NewConnBag()
        fallDamageBag:add(RunService.Heartbeat:Connect(function()
            local char = LP.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local vel = hrp.AssemblyLinearVelocity
            if vel.Y < -50 then
                hrp.AssemblyLinearVelocity = Vector3.new(vel.X, -50, vel.Z)
            end
        end))

        local function hookHum(hum)
            fallDamageBag:add(hum.StateChanged:Connect(function(_, newState)
                if newState == Enum.HumanoidStateType.Freefall then
                    task.delay(0.15, function()
                        if hum.Parent and hum:GetState() == Enum.HumanoidStateType.Freefall then
                            hum:ChangeState(Enum.HumanoidStateType.Running)
                        end
                    end)
                end
            end))
        end

        if LP.Character then
            local hum = LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then hookHum(hum) end
        end
        fallDamageBag:add(LP.CharacterAdded:Connect(function(char)
            task.wait(0.3)
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hookHum(hum) end
        end))
    else
        if fallDamageBag then fallDamageBag:destroy(); fallDamageBag = nil end
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true) end
    end
end

-- Wall Climb — горизонтальный (вертикаль режется)
local WallClimb = { active = false, speed = 8, push = 3, bv = nil, conn = nil, key = Enum.KeyCode.Space }
F.WallClimb = WallClimb

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

function F.ToggleWallClimb(state)
    WallClimb.active = state
    if state then
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        WallClimb.bv = Instance.new("BodyVelocity")
        WallClimb.bv.MaxForce = Vector3.new(2e4, 0, 2e4)
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
            -- Только вверх 5 studs/sec (медленно, чтобы не резалось)
            WallClimb.bv.Velocity = Vector3.new(0, 5, 0) + (-normal * WallClimb.push)
        end)
    else
        if WallClimb.conn then WallClimb.conn:Disconnect(); WallClimb.conn = nil end
        if WallClimb.bv then WallClimb.bv:Destroy(); WallClimb.bv = nil end
    end
end

-- Freecam — с сохранением prompts
local Freecam = { active = false, pos = Vector3.zero, yaw = 0, pitch = 0, rot = CFrame.new(), speed = 40, hud = nil, conn = nil, savedPrompts = {} }
F.Freecam = Freecam

function F.ToggleFreecam(state)
    Freecam.active = state
    if state then
        local camCF = Camera.CFrame
        Freecam.pos = camCF.Position
        local lookDir = camCF.LookVector
        Freecam.yaw = math.atan2(-lookDir.X, -lookDir.Z)
        Freecam.pitch = math.asin(math.clamp(lookDir.Y, -1, 1))

        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            -- НЕ PlatformStand — иначе теряется interact
            hum.WalkSpeed = 0
            hum.JumpPower = 0
        end

        local char = LP.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.LocalTransparencyModifier = 1 end
            end
        end

        Camera.CameraType = Enum.CameraType.Scriptable

        -- Увеличиваем дистанцию всех ProximityPrompt
        Freecam.savedPrompts = {}
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then
                Freecam.savedPrompts[obj] = {
                    distance = obj.MaxActivationDistance,
                }
                pcall(function()
                    obj.MaxActivationDistance = 500
                end)
            end
        end

        if not Freecam.hud then
            local hud = Instance.new("TextLabel")
            hud.Size = UDim2.new(0, 340, 0, 24)
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
                Freecam.yaw = Freecam.yaw - math.rad(delta.X * 0.4)
                Freecam.pitch = math.clamp(
                    Freecam.pitch - math.rad(delta.Y * 0.4),
                    math.rad(-89),
                    math.rad(89)
                )
            end
            local rot = CFrame.fromEulerAnglesYXZ(Freecam.pitch, Freecam.yaw, 0)
            Freecam.rot = CFrame.new(Freecam.pos) * rot

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
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then spd *= 2 end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) then spd *= 0.3 end
            if move.Magnitude > 0 then move = move.Unit end
            Freecam.pos += move * spd * dt

            Camera.CFrame = CFrame.new(Freecam.pos) * rot
            if Freecam.hud then
                Freecam.hud.Text = string.format(
                    " FREECAM  X:%.0f Y:%.0f Z:%.0f", Freecam.pos.X, Freecam.pos.Y, Freecam.pos.Z)
            end
        end)
    else
        -- Восстанавливаем prompts
        for prompt, data in pairs(Freecam.savedPrompts) do
            if prompt and prompt.Parent then
                pcall(function()
                    prompt.MaxActivationDistance = data.distance
                end)
            end
        end
        Freecam.savedPrompts = {}

        if Freecam.conn then Freecam.conn:Disconnect(); Freecam.conn = nil end
        Camera.CameraType = Enum.CameraType.Custom

        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = 16
            hum.JumpPower = 50
        end
        local char = LP.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.LocalTransparencyModifier = 0 end
            end
        end
        if Freecam.hud then Freecam.hud:Destroy(); Freecam.hud = nil end
    end
end

-- Freecam Follow — со паузой при тапе (для interact)
local FreecamFollow = {
    enabled = false, key = Enum.KeyCode.T, tpInterval = 0.3,
    lastTP = 0, conn = nil, savedGroundPos = nil,
    pauseUntil = 0,
}
F.FreecamFollow = FreecamFollow

local function FindGroundBelow(pos)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { LP.Character }
    params.IgnoreWater = true
    local result = workspace:Raycast(pos, Vector3.new(0, -200, 0), params)
    if result then return result.Position + Vector3.new(0, 3, 0) end
    return nil
end

local function IsInventoryUIOpen()
    local pg = LP:FindFirstChildOfClass("PlayerGui")
    if not pg then return false end
    for _, gui in ipairs(pg:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled then
            local n = string.lower(gui.Name)
            if n:find("inventory") or n:find("storage") or n:find("chest")
            or n:find("container") or n:find("loot") or n:find("box")
            or n:find("craft") or n:find("shop") or n:find("dialog")
            or n:find("prompt") or n:find("interact") then
                return true
            end
        end
    end
    return false
end

local function StartFreecamFollow()
    if FreecamFollow.conn then return end
    FreecamFollow.conn = RunService.Heartbeat:Connect(function()
        if not FreecamFollow.enabled then return end
        if not Freecam.active then return end
        local char = LP.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        -- Пауза при тапе
        if tick() < FreecamFollow.pauseUntil then
            return
        end

        -- Если UI открыт — стоим
        if IsInventoryUIOpen() then
            if FreecamFollow.savedGroundPos then
                hrp.CFrame = CFrame.new(FreecamFollow.savedGroundPos)
                hrp.AssemblyLinearVelocity = Vector3.zero
            end
            return
        end

        local now = tick()
        if now - FreecamFollow.lastTP < FreecamFollow.tpInterval then return end
        FreecamFollow.lastTP = now

        local camTarget = Freecam.pos - Vector3.new(0, 3, 0)
        local groundPos = FindGroundBelow(camTarget)
        if not groundPos then
            groundPos = camTarget
        end

        if (groundPos - camTarget).Magnitude > 50 then return end

        hrp.CFrame = CFrame.new(groundPos)
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero

        FreecamFollow.savedGroundPos = groundPos
    end)
end

local function StopFreecamFollow()
    if FreecamFollow.conn then
        FreecamFollow.conn:Disconnect()
        FreecamFollow.conn = nil
    end
end

function F.ToggleFreecamFollow(state)
    FreecamFollow.enabled = state
    if state then
        if not Freecam.active then F.ToggleFreecam(true) end
        StartFreecamFollow()
        PlaySound("default")
        print("[Rusted FreecamFollow] ON")
    else
        StopFreecamFollow()
        local char = LP.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local groundPos = FindGroundBelow(hrp.Position)
                if groundPos then
                    hrp.CFrame = CFrame.new(groundPos)
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    print("[Rusted FreecamFollow] landed at Y=" .. math.floor(groundPos.Y))
                end
            end
        end
        FreecamFollow.savedGroundPos = nil
        print("[Rusted FreecamFollow] OFF")
    end
end

-- Пауза при тапе (для interact во Freecam Follow)
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if not FreecamFollow.enabled then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        FreecamFollow.pauseUntil = tick() + 1.2
        -- Принудительно возвращаем персонажа на последнюю сохранённую позицию
        if FreecamFollow.savedGroundPos then
            local char = LP.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = CFrame.new(FreecamFollow.savedGroundPos)
                    hrp.AssemblyLinearVelocity = Vector3.zero
                end
            end
        end
    end
end)

-- Хоткеи F и T
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.F then F.ToggleFreecam(not Freecam.active) end
    if input.KeyCode == Enum.KeyCode.T then F.ToggleFreecamFollow(not FreecamFollow.enabled) end
end)

-- Void TP
local VoidTP = {
    active = true, threshold = -80, targetY = 5,
    useSpawn = false, lastTP = 0, cooldown = 1,
    conn = nil, charConn = nil,
}
F.VoidTP = VoidTP

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

function F.ToggleVoidTP(state)
    VoidTP.active = state
    if state then StartVoidWatcher() else StopVoidWatcher() end
end

StartVoidWatcher()

-- ============================================================
--  SPACE (для ПК, на мобиле бесполезно)
-- ============================================================

function F.SendToSpace(target)
    -- Не работает в Rusted (сервер режет Y), оставлено для совместимости
    return
end

function F.SendAllToSpace()
    return
end

function F.TeleportTo(name)
    local target = Players:FindFirstChild(name)
    if not target or not target.Character then return end
    local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
    local myHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if tHRP and myHRP then
        -- Телепорт только по XZ (Y режется)
        myHRP.CFrame = CFrame.new(tHRP.Position.X, myHRP.Position.Y, tHRP.Position.Z) * CFrame.new(0, 0, 3)
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
F.Aim = Aim

local aimActive = false
local lmbPressed = false
local lmbPressedTime = 0

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        lmbPressed = true
        lmbPressedTime = tick()
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        lmbPressed = false
    end
end)

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
        if not lmbPressed then return oldNamecall(self, ...) end
        if tick() - lmbPressedTime > 0.3 then return oldNamecall(self, ...) end
        local method = getnamecallmethod()
        if method ~= "Raycast" then return oldNamecall(self, ...) end
        if self ~= workspace then return oldNamecall(self, ...) end

        local args = {...}
        if #args < 2 then return oldNamecall(self, ...) end
        local origin = args[1]
        local direction = args[2]
        if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" then
            return oldNamecall(self, ...)
        end
        if direction.Magnitude < 50 then return oldNamecall(self, ...) end

        local camPos = Camera.CFrame.Position
        if (origin - camPos).Magnitude > 20 then return oldNamecall(self, ...) end

        local target = Aim.locked or FindTarget()
        if not target then return oldNamecall(self, ...) end
        local part = GetAimPart(target.Character)
        if not part then return oldNamecall(self, ...) end        local toTarget = part.Position - origin
        args[2] = toTarget.Unit * direction.Magnitude
        return oldNamecall(self, table.unpack(args))
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

function F.ToggleSilentAim(state) Aim.silent = state; if state then EnableSilentHook() end end
function F.ToggleAimlock(state) Aim.aimlock = state; if not state then Aim.locked = nil end end
function F.ToggleFovVisible(state) FovGui.Visible = state end

local function UpdateAim(dt)
    if not aimActive then return end
    Aim.locked = FindTarget()
    UpdateAimlock()
    FovGui.Size = UDim2.new(0, Aim.fov * 2, 0, Aim.fov * 2)
end

-- ============================================================
--  ESP
-- ============================================================

local ESP = {
    players = false, rainbow = false, bots = false,
    boxes = false, ores = false, rt = false, radar = false,
    range = 500, maxDist = 1200, botMaxDist = 600, botLimit = 30,
    mode = "highlight",
}
F.ESP = ESP

local playerESP, botESP, boxESP, oreESP, rtESP = {}, {}, {}, {}, {}

local hueClock = 0
local function RainbowColor(offset)
    hueClock += 0.0015
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
    local name = inst
    if typeof(inst) == "Instance" then name = inst.Name end
    if not name or type(name) ~= "string" then return false end
    local n = string.lower(name)
    for _, kw in ipairs(WEAPON_KEYWORDS) do
        if n:find(kw, 1, true) then return true end
    end
    return false
end

local lastWeapons = {}

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
    end
    local bp = plr:FindFirstChildOfClass("Backpack")
    if bp then
        for _, child in ipairs(bp:GetChildren()) do
            if child:IsA("Tool") then add(child.Name)
            elseif child:IsA("Model") and MatchesWeapon(child) then add(child.Name) end
        end
    end
    if #list == 0 and lastWeapons[plr] then
        local cached = lastWeapons[plr]
        if tick() - cached.time < 30 then
            table.insert(list, cached.name .. " (last)")
        end
    end
    if #list > 0 then
        lastWeapons[plr] = { name = list[1], time = tick() }
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

local function CreateHighlight(plr)
    local hl = Instance.new("Highlight")
    hl.Name = "RustedHL_" .. plr.Name
    hl.FillTransparency = 1
    hl.OutlineTransparency = 0.1
    hl.OutlineColor = Color3.fromRGB(255, 80, 80)
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = espFolder
    return hl
end

local function CreatePlayerBox()
    local b = Instance.new("BoxHandleAdornment")
    b.Name = "RustedPlayerBox"
    b.Size = Vector3.new(4, 5, 4)
    b.AlwaysOnTop = true
    b.ZIndex = 5
    b.Transparency = 0.5
    b.Adornee = nil
    b.Parent = espFolder
    return b
end

local function CreateInfoLabel()
    local bb = Instance.new("BillboardGui")
    bb.Name = "RustedInfo"
    bb.Size = UDim2.new(0, 220, 0, 70)
    bb.StudsOffset = Vector3.new(0, 4, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 1500
    bb.Parent = espFolder
    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.new(1, 0, 1, 0)
    tl.BackgroundTransparency = 1
    tl.TextColor3 = Color3.fromRGB(255, 255, 255)
    tl.TextSize = 14
    tl.Font = Enum.Font.GothamBold
    tl.TextStrokeTransparency = 0
    tl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    tl.TextYAlignment = Enum.TextYAlignment.Center
    tl.TextXAlignment = Enum.TextXAlignment.Center
    tl.Text = ""
    tl.Parent = bb
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 1
    stroke.Parent = tl
    return { gui = bb, label = tl, stroke = stroke }
end

local function AddPlayerESP(plr)
    if plr == LP or playerESP[plr] then return end
    playerESP[plr] = {
        highlight = CreateHighlight(plr),
        box = CreatePlayerBox(),
        hue = math.random(),
        info = CreateInfoLabel(),
        visible = true,
    }
end

local function RemovePlayerESP(plr)
    local d = playerESP[plr]
    if not d then return end
    if d.highlight then pcall(function() d.highlight:Destroy() end) end
    if d.box then pcall(function() d.box:Destroy() end) end
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
    "smallcrate", "largecrate", "lootcrate", "loot_crate",
    "woodencrate", "foodcrate", "medcrate", "medicalcrate",
    "militarycrate", "supplycrate",
    "supplydrop", "airdrop", "airdrops",
    "basicchest", "goldchest", "largechest",
    "storagebox", "lootbox", "medbox",
    "recycler", "furnace", "fridge",
}

local function IsBoxPart(inst)
    if not inst:IsA("BasePart") then return false end
    local n = string.lower(inst.Name):gsub("[%s_%-%.]", "")
    for _, k in ipairs(BOX_KEYWORDS) do
        local kk = string.lower(k):gsub("[%s_%-%.]", "")
        if n == kk then return true end
    end
    local parent = inst.Parent
    if parent and parent:IsA("Model") then
        local pn = string.lower(parent.Name):gsub("[%s_%-%.]", "")
        for _, k in ipairs(BOX_KEYWORDS) do
            local kk = string.lower(k):gsub("[%s_%-%.]", "")
            if pn == kk then return true end
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
        keywords = { "metalore", "metal_ore", "metalore1", "metalore2", "ironore", "iron_ore", "hqmnode", "hqm_node", "hqm_ore", "highqualitynode" },
        exactNames = { "MetalOre", "Metal Ore", "IronOre" },
        color = Color3.fromRGB(180, 180, 180),
        label = "Metal",
    },
    sulfur = {
        keywords = { "sulfurore", "sulfur_ore", "sulfurnode", "sulfur_node", "sulphur", "sulphurore" },
        exactNames = { "SulfurOre", "Sulfur Ore", "Sulphur" },
        color = Color3.fromRGB(255, 230, 60),
        label = "Sulfur",
    },
    stone = {
        keywords = { "stoneore", "stone_ore", "stonenode", "stone_node", "rocknode", "rock_node", "orespawn" },
        exactNames = { "StoneOre", "Stone Ore", "RockNode" },
        color = Color3.fromRGB(220, 60, 60),
        label = "Stone",
    },
}
F.ORES = ORES

local function GetOreType(inst)
    if not inst:IsA("BasePart") and not inst:IsA("Model") then return nil end

    local fullName = ""
    local p = inst
    local depth = 0
    while p and depth < 4 do
        fullName = fullName .. " " .. string.lower(p.Name)
        p = p.Parent
        depth += 1
    end
    if fullName:find("door") or fullName:find("doorframe")
    or fullName:find("wall") or fullName:find("building")
    or fullName:find("structure") or fullName:find("gate")
    or fullName:find("fence") or fullName:find("ladder") then
        return nil
    end

    local names = { inst.Name }
    if inst.Parent then table.insert(names, inst.Parent.Name) end
    for _, rawName in ipairs(names) do
        local n = string.lower(rawName):gsub("[%s_%-%.]", "")
        for oreKey, data in pairs(ORES) do
            for _, exact in ipairs(data.exactNames) do
                local e = string.lower(exact):gsub("[%s_%-%.]", "")
                if n == e then return oreKey end
            end
            for _, kw in ipairs(data.keywords) do
                local k = string.lower(kw):gsub("[%s_%-%.]", "")
                if n == k then return oreKey end
            end
            if inst:IsA("BasePart") then
                local rt = inst:GetAttribute("ResourceType") or inst:GetAttribute("OreType") or inst:GetAttribute("Type")
                if type(rt) == "string" then
                    local rtN = string.lower(rt):gsub("[%s_%-%.]", "")
                    for _, kw in ipairs(data.keywords) do
                        local k = string.lower(kw):gsub("[%s_%-%.]", "")
                        if rtN == k or rtN:find(k, 1, true) then return oreKey end
                    end
                end
            end
        end
    end
    return nil
end
F.GetOreType = GetOreType

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
    { name = "Arctic Base",     keywords = {"arcticbase", "arctic_base", "arcticresearch"} },
    { name = "Bunker",          keywords = {"bunkerentrance", "bunker_entrance", "undergroundbunker"} },
    { name = "Military Base",   keywords = {"militarybase", "military_base", "militarytunnel"} },
    { name = "Airfield",        keywords = {"airfield", "airport_hangar"} },
    { name = "Oil Rig",         keywords = {"oilrig", "oil_rig"} },
    { name = "Mountain Base",   keywords = {"mountainbase", "mountain_base"} },
    { name = "Harbor",          keywords = {"harbor", "seaport"} },
    { name = "Water Treatment", keywords = {"watertreatment", "water_treatment"} },
    { name = "Power Plant",     keywords = {"powerplant", "power_plant"} },
    { name = "Launch Site",     keywords = {"launchsite", "launch_site"} },
    { name = "Excavator",       keywords = {"excavator"} },
    { name = "Train Yard",      keywords = {"trainyard", "train_yard"} },
    { name = "Gas Station",     keywords = {"gasstation"} },
    { name = "Dome",            keywords = {"dome"} },
    { name = "RT",              keywords = {"lootroom", "loot_room", "raidtarget"} },
}
local RT_COLOR = Color3.fromRGB(255, 100, 255)

local function GetRTType(inst)
    if not inst:IsA("BasePart") and not inst:IsA("Model") then return nil end
    local names = { inst.Name }
    local p = inst.Parent
    local depth = 0
    while p and depth < 5 do
        table.insert(names, p.Name)
        p = p.Parent
        depth += 1
    end
    for _, rt in ipairs(RT_LOCATIONS) do
        for _, kw in ipairs(rt.keywords) do
            local kk = string.lower(kw):gsub("[%s_%-%.]", "")
            for _, rawName in ipairs(names) do
                local n = string.lower(rawName):gsub("[%s_%-%.]", "")
                if n == kk then return rt.name end
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
RadarStroke.Color = Color3.fromRGB(138, 79, 255)
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
F.RadarGui = RadarGui

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
F.LookTracer = LookTracer

local function NewLookTracer(plr)
    local adorn = Instance.new("LineHandleAdornment")
    adorn.Name = "RustedLook_" .. plr.Name
    adorn.AlwaysOnTop = true
    adorn.ZIndex = 4
    adorn.Color3 = LookTracer.color
    adorn.Thickness = 0.5
    adorn.Transparency = LookTracer.transparency
    adorn.Parent = espFolder
    return adorn
end

local function KillLookTracer(adorn)
    if adorn then pcall(function() adorn:Destroy() end) end
end

function F.ToggleLookTracer(state)
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

function F.ToggleNightVision(state)
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

function F.ToggleEnvClean(state)
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
--  DANGER SCANNER
-- ============================================================

local DangerScanner = {
    knownDangers = {},
    knownDangersSet = {},
    lastScanPos = Vector3.zero,
    scanDistance = 30,
    scanRadius = 200,
    lastCleanup = 0,
}

local DAMAGE_KEYWORDS = {
    "spike", "trap", "damage", "hurt", "kill", "lava", "fire",
    "poison", "toxic", "barb", "razor", "saw", "blade",
    "thorn", "cactus", "nettle", "turret", "mine", "radiation",
    "barbs", "trapdoor", "bear",
}

function DangerScanner.Refresh()
    local count = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not DangerScanner.knownDangersSet[obj] then
            local n = string.lower(obj.Name)
            local dangerous = false
            for _, kw in ipairs(DAMAGE_KEYWORDS) do
                if n:find(kw, 1, true) then dangerous = true; break end
            end
            if not dangerous then
                if obj:GetAttribute("Damage") or obj:GetAttribute("TrapType")
                or obj:GetAttribute("Hurt") then
                    dangerous = true
                end
            end
            if dangerous then
                table.insert(DangerScanner.knownDangers, obj)
                DangerScanner.knownDangersSet[obj] = true
                count += 1
            end
        end
    end
    if count > 0 then
        print(string.format("[Rusted DangerScanner] +%d опасных объектов", count))
    end
end

function DangerScanner.IsDangerous(pos, radius)
    radius = radius or 15
    for i = #DangerScanner.knownDangers, 1, -1 do
        local obj = DangerScanner.knownDangers[i]
        if not obj.Parent then
            table.remove(DangerScanner.knownDangers, i)
            DangerScanner.knownDangersSet[obj] = nil
        elseif (obj.Position - pos).Magnitude <= radius then
            return true
        end
    end
    return false
end

function DangerScanner.Update()
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local distFromLastScan = (hrp.Position - DangerScanner.lastScanPos).Magnitude
    if distFromLastScan >= DangerScanner.scanDistance then
        DangerScanner.Refresh()
        DangerScanner.lastScanPos = hrp.Position
    end
    if tick() - DangerScanner.lastCleanup > 30 then
        DangerScanner.lastCleanup = tick()
        for i = #DangerScanner.knownDangers, 1, -1 do
            if not DangerScanner.knownDangers[i].Parent then
                local obj = DangerScanner.knownDangers[i]
                table.remove(DangerScanner.knownDangers, i)
                DangerScanner.knownDangersSet[obj] = nil
            end
        end
    end
end

-- ============================================================
--  AUTO-FARM v2
-- ============================================================

local AutoFarm = {
    active = false, mode = "walk", speed = 15, flyHeight = 5,
    reachDist = 12, mineTime = 3, scanRange = 300,
    targetTypes = { metal = true, sulfur = true, stone = true },
    bag = nil, route = {}, routeIndex = 1,
    lastRouteScan = 0, routeScanInterval = 10,
    currentTarget = nil, state = "idle",
    mineStart = 0, kills = 0,
    timeLimit = 0, killsLimit = 0, startTime = 0, stoppedBy = nil,
    playerDetect = false, playerRadius = 150, playerAction = "pause",
    playerPaused = false, playerPauseEnd = 0, playerStopDelay = 5,
    lastPlayerCheck = 0, nearbyPlayers = {}, moveStart = nil,
    damageDetect = true,
}
F.AutoFarm = AutoFarm

local function BuildRoute()
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local myPos = hrp.Position

    local candidates = {}
    for _, inst in ipairs(workspace:GetDescendants()) do
        if inst:IsA("BasePart") or inst:IsA("Model") then
            local oreType = GetOreType(inst)
            if oreType and AutoFarm.targetTypes[oreType] then
                local part
                if inst:IsA("BasePart") then part = inst
                elseif inst:IsA("Model") then
                    part = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")
                end
                if part and part.Parent then
                    local dist = (part.Position - myPos).Magnitude
                    if dist <= AutoFarm.scanRange then
                        if not AutoFarm.damageDetect or not DangerScanner.IsDangerous(part.Position, 15) then
                            table.insert(candidates, { inst = inst, part = part, type = oreType, dist = dist })
                        end
                    end
                end
            end
        end
    end

    table.sort(candidates, function(a, b) return a.dist < b.dist end)
    AutoFarm.route = candidates
    AutoFarm.routeIndex = 1
    AutoFarm.lastRouteScan = tick()
    print(string.format("[Rusted AutoFarm] Маршрут: %d целей", #candidates))
end

local function GetNextTarget()
    if tick() - AutoFarm.lastRouteScan > AutoFarm.routeScanInterval then
        BuildRoute()
    end
    while AutoFarm.routeIndex <= #AutoFarm.route do
        local target = AutoFarm.route[AutoFarm.routeIndex]
        AutoFarm.routeIndex += 1
        if target.part and target.part.Parent then return target end
    end
    BuildRoute()
    if #AutoFarm.route > 0 then
        AutoFarm.routeIndex = 2
        return AutoFarm.route[1]
    end
    return nil
end

local function MoveToward(targetPos, dt)
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    local current = hrp.Position
    local diff = targetPos - current
    local horizDiff = Vector3.new(diff.X, 0, diff.Z)
    local horizDist = horizDiff.Magnitude
    if horizDist < 1 then return end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { char }
    params.IgnoreWater = true
    local ahead = horizDiff.Unit * 5
    local hit = workspace:Raycast(current + Vector3.new(0, 2, 0), ahead, params)

    local moveDir = horizDiff.Unit
    if hit then
        local leftDir = CFrame.Angles(0, math.rad(45), 0) * horizDiff.Unit
        local rightDir = CFrame.Angles(0, math.rad(-45), 0) * horizDiff.Unit
        local leftHit = workspace:Raycast(current + Vector3.new(0, 2, 0), leftDir * 5, params)
        local rightHit = workspace:Raycast(current + Vector3.new(0, 2, 0), rightDir * 5, params)
        if not leftHit then moveDir = leftDir
        elseif not rightHit then moveDir = rightDir
        else
            if AutoFarm._bv then AutoFarm._bv.Velocity = Vector3.zero end
            return
        end
    end

    if not AutoFarm._bv then
        AutoFarm._bv = Instance.new("BodyVelocity")
        AutoFarm._bv.Name = "RustedFarmBV"
        AutoFarm._bv.MaxForce = Vector3.new(3e4, 0, 3e4)
        AutoFarm._bv.P = 2000
        AutoFarm._bv.Parent = hrp
    end

    -- Только горизонтальное движение, Y режется сервером
    AutoFarm._bv.Velocity = Vector3.new(moveDir.X * AutoFarm.speed, 0, moveDir.Z * AutoFarm.speed)
    hrp.CFrame = CFrame.new(current, Vector3.new(targetPos.X, current.Y, targetPos.Z))
end

local function StopMovement()
    if AutoFarm._bv then AutoFarm._bv:Destroy(); AutoFarm._bv = nil end
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum:MoveTo(char.HumanoidRootPart.Position) end
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
            F.ToggleAutoFarm(false)
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
                print("[Rusted AutoFarm] OK Игроки ушли")
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
            print(string.format("[Rusted AutoFarm] OK Время вышло"))
            F.ToggleAutoFarm(false)
            return true
        end
    end
    if AutoFarm.killsLimit > 0 and AutoFarm.kills >= AutoFarm.killsLimit then
        AutoFarm.stoppedBy = "kills"
        PlaySound("farm_complete")
        task.spawn(PlayBeepSequence)
        print(string.format("[Rusted AutoFarm] OK Лимит ресурсов"))
        F.ToggleAutoFarm(false)
        return true
    end
    return false
end

local function StartAutoFarm()
    if AutoFarm.bag then return end
    AutoFarm.bag = NewConnBag()
    AutoFarm.startTime = tick()
    AutoFarm.stoppedBy = nil
    AutoFarm.route = {}
    AutoFarm.routeIndex = 1
    AutoFarm.lastRouteScan = 0
    BuildRoute()

    AutoFarm.bag:add(RunService.Heartbeat:Connect(function(dt)
        if not AutoFarm.active then return end
        local char = LP.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        DangerScanner.Update()

        if tick() - AutoFarm.lastPlayerCheck > 0.5 then
            AutoFarm.lastPlayerCheck = tick()
            local playersNear = CheckPlayers()
            if playersNear then
                StopMovement()
                return
            end
        end
        if tick() - AutoFarm.lastScan > 1 then
            AutoFarm.lastScan = tick()
            if CheckLimits() then return end
        end

        if AutoFarm.state == "idle" then
            local target = GetNextTarget()
            if target then
                AutoFarm.currentTarget = target
                AutoFarm.state = "moving"
                AutoFarm.moveStart = tick()
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
                AutoFarm.moveStart = AutoFarm.moveStart or tick()
                if tick() - AutoFarm.moveStart > 15 then
                    print("[Rusted AutoFarm] Таймаут, следующая цель")
                    AutoFarm.moveStart = nil
                    AutoFarm.currentTarget = nil
                    AutoFarm.state = "idle"
                    StopMovement()
                    return
                end
                MoveToward(t.part.Position, dt)
            end
        elseif AutoFarm.state == "mining" then
            if tick() - AutoFarm.mineStart >= AutoFarm.mineTime then
                TryMine(AutoFarm.currentTarget)
                AutoFarm.kills += 1
                AutoFarm.currentTarget = nil
                AutoFarm.moveStart = nil
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
    AutoFarm.moveStart = nil
    AutoFarm.route = {}
end

function F.ToggleAutoFarm(state)
    AutoFarm.active = state
    if state then
        AutoFarm.kills = 0
        AutoFarm.stoppedBy = nil
        StartAutoFarm()
        print("[Rusted AutoFarm] Запущен. Режим: " .. AutoFarm.mode)
    else
        StopAutoFarm()
        if not AutoFarm.stoppedBy then
            print("[Rusted AutoFarm] Остановлен. Добыто: " .. AutoFarm.kills)
        end
    end
end

-- ============================================================
--  WATCHER
-- ============================================================

local Watcher = {
    enabled = false, minDot = 0.7, minMoveDot = 0.4,
    triggerTime = 5, useVisibility = true, showName = true, sound = true,
    trackers = {}, activeWarnings = {},
}
F.Watcher = Watcher

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
                        and ("!! " .. plr.Name .. " is watching you!")
                        or "!! DETECTED!"
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

function F.ToggleWatcher(state)
    Watcher.enabled = state
    if not state then
        for plr, _ in pairs(Watcher.activeWarnings) do HideWarning(plr) end
        Watcher.trackers = {}
    end
end

-- ============================================================
--  ESP MAIN LOOP
-- ============================================================

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
                    local showHL = ESP.mode == "highlight" or ESP.mode == "both"
                    local showBox = ESP.mode == "box" or ESP.mode == "both"

                    if d.highlight then
                        if showHL then
                            d.highlight.Adornee = char
                            if ESP.rainbow then
                                d.highlight.OutlineColor = RainbowColor(d.hue)
                            else
                                d.highlight.OutlineColor = Color3.fromRGB(255, 80, 80)
                            end
                        else
                            d.highlight.Adornee = nil
                        end
                    end

                    if d.box then
                        if showBox then
                            d.box.Adornee = hrp
                            d.box.Visible = true
                            if ESP.rainbow then d.box.Color3 = RainbowColor(d.hue)
                            else d.box.Color3 = Color3.fromRGB(255, 80, 80) end
                        else
                            d.box.Visible = false
                        end
                    end

                    if frameCounter % 8 == 0 then
                        d.visible = IsCharVisible(char)
                    end

                    if frameCounter % 4 == 0 and d.info then
                        local distM = math.floor(dist / 3)
                        local hp = math.floor(hum.Health)
                        local maxHp = math.floor(hum.MaxHealth)
                        local weapons = GetPlayerWeapons(plr)
                        local weaponText = FormatWeaponList(weapons)
                        if d.visible then
                            d.info.gui.Enabled = true
                            d.info.label.Text = string.format("%s\nHP %d/%d | %dm | %s",
                                plr.Name, hp, maxHp, distM, weaponText)
                            d.info.gui.Adornee = hrp
                            if ESP.rainbow then
                                local col = RainbowColor(d.hue + 0.3)
                                d.info.label.TextColor3 = col
                                if d.info.stroke then d.info.stroke.Color = col end
                            else
                                local hpRatio = hum.Health / math.max(hum.MaxHealth, 1)
                                d.info.label.TextColor3 = Color3.fromRGB(255,
                                    math.floor(100 + 155 * hpRatio), math.floor(100 * hpRatio))
                            end
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
                        adorn.Transparency = LookTracer.transparency
                    elseif LookTracer.tracers[plr] then
                        KillLookTracer(LookTracer.tracers[plr])
                        LookTracer.tracers[plr] = nil
                    end
                else
                    if d.highlight then d.highlight.Adornee = nil end
                    if d.box then d.box.Visible = false end
                    if d.info then d.info.gui.Enabled = false end
                    if LookTracer.tracers[plr] then
                        LookTracer.tracers[plr].Transparency = 1
                    end
                end
            else
                if d.highlight then d.highlight.Adornee = nil end
                if d.box then d.box.Visible = false end
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

    if ESP.boxes and frameCounter % 600 == 0 then ScanBoxes() end
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

    if ESP.ores and frameCounter % 600 == 0 then ScanOres() end
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

    if ESP.rt and frameCounter % 900 == 0 then ScanRT() end
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

function F.TogglePlayerESP(state)
    ESP.players = state
    if state then
        for _, plr in ipairs(Players:GetPlayers()) do AddPlayerESP(plr) end
    else
        for plr, d in pairs(playerESP) do
            if d.highlight then pcall(function() d.highlight:Destroy() end) end
            if d.box then pcall(function() d.box:Destroy() end) end
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

function F.ToggleRainbow(state) ESP.rainbow = state end

function F.ToggleBotESP(state)
    ESP.bots = state
    if state then ScanBots()
    else
        for m, d in pairs(botESP) do KillBox(d.box); botESP[m] = nil end
        botESP = {}
    end
end

function F.ToggleBoxESP(state)
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

function F.ToggleOreESP(state)
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

function F.ToggleRTESP(state)
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

function F.ToggleRadar(state)
    ESP.radar = state
    RadarGui.Visible = state
    if not state then
        for _, d in pairs(radarActive) do KillRadarDot(d) end
        radarActive = {}
    end
end

-- ============================================================
--  ЭКСПОРТ для мобильной кнопки
-- ============================================================

_G.RustedToggleFollow = function()
    F.ToggleFreecamFollow(not FreecamFollow.enabled)
end

_G.RustedFeatures = F

return F
