-- =========================================================
-- SCRIPT ATUALIZADO v3.1: Custom Animations + NOVO Tze Music Player
-- (FIXES 3.1 - Music Player Close agora para a animação do celular + RefreshAnims chamado em TODOS os fechamentos)
-- =========================================================

-- ====================== FIXES APLICADOS ======================
-- 1. Quando o music player fecha → animação de mexer no celular PARA imediatamente
--    (agora com refreshAnims(0.25) em TODOS os caminhos de fechamento)
-- 2. Sempre lembrar de atualizar o RefreshAnims → agora chamado explicitamente após fechar o player
--    (garante que as animações padrão do Roblox voltem corretamente)
-- 3. Todos os fixes da v3.0 mantidos (Clock Slide Right + SRun PlaybackSpeed Fix + RefreshAnims otimizado)
-- =========================================================

local ID_CONFIG = {
    Idle        = "rbxassetid://72492959889389",
    Walk        = "rbxassetid://118959209918644",
    Run         = "rbxassetid://116881956670910",
    JumpRunning = "rbxassetid://82083900175742",
    JumpStanding = "rbxassetid://131814798893284",
    CrouchIdle  = "rbxassetid://104930844061263",
    CrouchWalk  = "rbxassetid://99452665172764",
    Sit         = "rbxassetid://106200020780317",
    Lie         = "rbxassetid://98220014348433",
    IdleVariant = "rbxassetid://82199315861193",
    Drink       = "rbxassetid://85688041753037",
    Fall        = "rbxassetid://122194794537519",
    SRun        = "rbxassetid://121350640829746",
    PhoneUse    = "rbxassetid://94232069437883"
}

local SETTINGS = {
    WalkSpeed        = 14,
    RunSpeed         = 18,
    JumpPower        = 50,
    Enabled          = true,
    CrouchEnabled    = false,
    LieEnabled       = false,
    DrinkDuration    = 4.5,
    BoostDuration    = 15,
    BoostSpeed       = 35,
    BoostFOV         = 90,
    BoostJump        = 17,
    FootprintInterval = 0.32,
}

local TOOL_IDS = {
    BloxyCola = { MeshId = "rbxassetid://10470609", TextureId = "rbxassetid://10470600", HandleColor = "Really red" },
    TzesPhone = { MeshId = "rbxassetid://130757014132786", TextureId = "rbxassetid://101684537135469", HandleColor = "Lime green" },
    Lanterna  = { MeshId = "rbxassetid://137073484684190", TextureId = "rbxassetid://120980688754080", HandleColor = "Bright yellow" }
}

local TOOL_CONFIGS = {
    BloxyCola = { Handle = { Size = Vector3.new(1,1,1), Material = Enum.Material.SmoothPlastic, Rotation = Vector3.new(0,0,0), Position = Vector3.new(0,0,0) }, Mesh = { Scale = Vector3.new(1.1,1.1,1.1) } },
    TzesPhone = { Handle = { Size = Vector3.new(0.4,0.8,0.2), Material = Enum.Material.SmoothPlastic, Transparency = 0, Rotation = Vector3.new(0,450,0), Position = Vector3.new(0,-0.5,-0.5) }, Mesh = { Scale = Vector3.new(1,1,1) } },
    Lanterna  = { Handle = { Size = Vector3.new(0.7,1.4,0.7), Material = Enum.Material.Neon, Transparency = 0, Rotation = Vector3.new(0,0,0), Position = Vector3.new(0,0,0) }, Mesh = { Scale = Vector3.new(1,1,1) }, LanternLight = { Brightness = 4, Range = 80, Angle = 60 } }
}

local Player = game.Players.LocalPlayer
local Character, Humanoid, Animator
local originalIDs = {}
local jumpingConnection = nil
local activeJumpTrack = nil
local isSitting = false
local customSitTrack = nil
local isDrinking = false
local drinkBoostEndTime = 0
local originalFOV = 70
local isInvis = false
local invisTimer = nil
local invisSeat = nil
local footprintConnection = nil
local lastFootprintTime = 0
local alternateFoot = true
local fadeFrame = nil
local idleVariantTrack = nil
local idleTimer = nil
local isIdle = false

-- NOVAS VARIÁVEIS (declaradas no topo para evitar scoping Lua)
local sRunTrack = nil
local lastSRunTime = 0
local phoneTrack = nil
local isMusicOpen = false

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local SOUNDS = {}
local clockFrame
local timeLabel

-- ====================== HELPER (Animator) ======================
local function loadAnim(animationId)
    if not Animator then return nil end
    local anim = Instance.new("Animation")
    anim.AnimationId = animationId
    return Animator:LoadAnimation(anim)
end
-- =========================================================

local function createSounds()
    for _, sound in pairs(Player:WaitForChild("PlayerGui"):GetChildren()) do
        if sound:IsA("Sound") and (sound.SoundId == "rbxassetid://73840813063136" or sound.SoundId == "rbxassetid://73836316475925" or sound.SoundId == "rbxassetid://138475744729338") then
            sound:Destroy()
        end
    end

    SOUNDS.Invis = Instance.new("Sound", Player:WaitForChild("PlayerGui"))
    SOUNDS.Invis.Name = "CustomInvisSound"
    SOUNDS.Invis.SoundId = "rbxassetid://73840813063136"
    SOUNDS.Invis.Volume = 1.5
    SOUNDS.Invis.PlaybackSpeed = 1
    SOUNDS.Invis.Looped = false

    SOUNDS.Deactivate = Instance.new("Sound", Player:WaitForChild("PlayerGui"))
    SOUNDS.Deactivate.Name = "CustomDeactivateSound"
    SOUNDS.Deactivate.SoundId = "rbxassetid://73836316475925"
    SOUNDS.Deactivate.Volume = 1.5
    SOUNDS.Deactivate.PlaybackSpeed = 1
    SOUNDS.Deactivate.Looped = false

    SOUNDS.Drink = Instance.new("Sound", Player:WaitForChild("PlayerGui"))
    SOUNDS.Drink.Name = "CustomDrinkSound"
    SOUNDS.Drink.SoundId = "rbxassetid://138475744729338"
    SOUNDS.Drink.Volume = 1.0
    SOUNDS.Drink.PlaybackSpeed = 1
    SOUNDS.Drink.Looped = false
end

createSounds()

local function safeSet(animate, path, id)
    local obj = animate
    for i, key in ipairs(path) do
        local child = obj:FindFirstChild(key)
        if not child then
            if i == #path then
                child = Instance.new("Animation")
                child.Name = key
            else
                child = Instance.new("Folder")
                child.Name = key
            end
            child.Parent = obj
        end
        obj = child
    end
    if obj:IsA("Animation") then
        obj.AnimationId = id
    end
end

local function getSafeInvisPosition()
    return Vector3.new(math.random(-5000, 5000), math.random(10000, 15000), math.random(-5000, 5000))
end

local function setTransparency(character, targetTransparency, duration)
    if not character or not character.Parent then return end
    local tweenInfo = TweenInfo.new(duration or 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    for _, part in pairs(character:GetDescendants()) do
        if (part:IsA("BasePart") or part:IsA("Decal")) and part.Name ~= "HumanoidRootPart" then
            TweenService:Create(part, tweenInfo, {Transparency = targetTransparency}):Play()
        end
    end
end

local function activateInvisibility()
    SOUNDS.Invis:Play()
    local root = Character and Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local savedCFrame = root.CFrame
    task.wait()
    local invisPos = getSafeInvisPosition()
    Character:MoveTo(invisPos)
    task.wait(0.15)
    if invisSeat and invisSeat.Parent then invisSeat:Destroy() end
    invisSeat = Instance.new("Seat")
    invisSeat.Name = "invischair"
    invisSeat.Anchored = false
    invisSeat.CanCollide = false
    invisSeat.Transparency = 1
    invisSeat.Position = invisPos
    invisSeat.Parent = Workspace
    local Weld = Instance.new("Weld", invisSeat)
    Weld.Part0 = invisSeat
    Weld.Part1 = Character:FindFirstChild("Torso") or Character:FindFirstChild("UpperTorso")
    task.wait()
    invisSeat.CFrame = savedCFrame
    setTransparency(Character, 0.5, 0.5)
end

local function deactivateInvisibility()
    if invisSeat and invisSeat.Parent then 
        invisSeat:Destroy() 
        invisSeat = nil 
    end
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Seat") and obj.Name == "invischair" then obj:Destroy() end
    end
    if Character and Character.Parent then
        setTransparency(Character, 0, 0.5)
    end
end

local function playBoostFade(starting)
    if not fadeFrame then return end
    fadeFrame.BackgroundTransparency = 1
    fadeFrame.Visible = true
    local targetTrans = starting and 0.42 or 0.78
    local inDuration  = starting and 0.22 or 0.28
    local holdTime    = 0.08
    local outDuration = 0.55
    TweenService:Create(fadeFrame, TweenInfo.new(inDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { BackgroundTransparency = targetTrans }):Play()
    task.delay(inDuration + holdTime, function()
        if fadeFrame and fadeFrame.Parent then
            TweenService:Create(fadeFrame, TweenInfo.new(outDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
            task.delay(outDuration, function()
                if fadeFrame and fadeFrame.Parent then fadeFrame.Visible = false end
            end)
        end
    end)
end

local function resetIdleVariant()
    if idleVariantTrack then
        pcall(function() if idleVariantTrack.IsPlaying then idleVariantTrack:Stop(0.2) end end)
        idleVariantTrack = nil
    end
    if idleTimer then task.cancel(idleTimer) idleTimer = nil end
end

local function playIdleVariant()
    if not Humanoid or not Character or not SETTINGS.Enabled then return end
    resetIdleVariant()
    idleVariantTrack = loadAnim(ID_CONFIG.IdleVariant)
    if not idleVariantTrack then return end
    idleVariantTrack.Looped = false
    idleVariantTrack.Priority = Enum.AnimationPriority.Idle
    idleVariantTrack:Play(0.3)
    idleVariantTrack.Stopped:Once(function()
        idleVariantTrack = nil
        if isIdle then startIdleTimer() end
    end)
end

local function startIdleTimer()
    resetIdleVariant()
    idleTimer = task.delay(10, function()
        idleTimer = nil
        if isIdle and SETTINGS.Enabled and not isDrinking and not isSitting and not SETTINGS.LieEnabled and not isInvis then
            playIdleVariant()
        end
    end)
end

local function updateIdleStatus()
    if not SETTINGS.Enabled or not Humanoid or not Character then
        if isIdle then isIdle = false resetIdleVariant() end
        return
    end
    local shouldBeIdle = not (isDrinking or isSitting or SETTINGS.LieEnabled or isInvis)
    if not shouldBeIdle then
        if isIdle then isIdle = false resetIdleVariant() end
        return
    end
    local root = Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local horizSpeed = Vector3.new(root.Velocity.X, 0, root.Velocity.Z).Magnitude
    local currentlyIdle = horizSpeed < 2
    if currentlyIdle then
        if not isIdle then isIdle = true startIdleTimer() end
    else
        if isIdle then isIdle = false resetIdleVariant() end
    end
end

-- ====================== SRun (2x garantido SEM erro de PlaybackSpeed) ======================
local function updateRunAnimation()
    if not Humanoid or not Character or not SETTINGS.Enabled then
        if sRunTrack then pcall(function() sRunTrack:Stop(0.2) end) sRunTrack = nil end
        return
    end

    local root = Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local horizSpeed = Vector3.new(root.Velocity.X, 0, root.Velocity.Z).Magnitude

    if horizSpeed > 20 then
        if not sRunTrack then
            sRunTrack = loadAnim(ID_CONFIG.SRun)
            if not sRunTrack then return end
            sRunTrack.Looped = false
            sRunTrack.Priority = Enum.AnimationPriority.Movement
        end

        local now = os.clock()
        if (now - lastSRunTime >= 2) or not sRunTrack.IsPlaying then
            if sRunTrack.IsPlaying then sRunTrack:Stop(0) end
            sRunTrack:Play(0.1, 1, 2)
            lastSRunTime = now
        end
    else
        if sRunTrack then
            pcall(function() sRunTrack:Stop(0.2) end)
            sRunTrack = nil
        end
        lastSRunTime = 0
    end
end
-- =========================================================

-- ====================== Phone Animation ======================
local function updatePhoneAnimation()
    if not Humanoid or not Character or not SETTINGS.Enabled then
        if phoneTrack then pcall(function() phoneTrack:Stop(0.3) end) phoneTrack = nil end
        return
    end

    if isMusicOpen then
        if not phoneTrack or not phoneTrack.IsPlaying then
            if phoneTrack then phoneTrack:Stop(0.3) end
            phoneTrack = loadAnim(ID_CONFIG.PhoneUse)
            if not phoneTrack then return end
            phoneTrack.Looped = true
            phoneTrack.Priority = Enum.AnimationPriority.Core
            phoneTrack:Play(0.3)
        end
    else
        if phoneTrack then
            pcall(function() phoneTrack:Stop(0.3) end)
            phoneTrack = nil
        end
    end
end
-- =========================================================

local function spawnFootprint(root)
    if not root then return end
    local rayOrigin = root.Position - Vector3.new(0, 2.8, 0)
    local rayDirection = Vector3.new(0, -6, 0)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    local result = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    if not result then return end
    local hitPos = result.Position
    local hitNormal = result.Normal
    local groundColor = Color3.fromRGB(80, 80, 80)
    if result.Instance:IsA("Terrain") then
        groundColor = Workspace.Terrain:GetMaterialColor(result.Material)
    elseif result.Instance:IsA("BasePart") then
        groundColor = result.Instance.Color
    end
    local darkenedColor = Color3.new(groundColor.R * 0.65, groundColor.G * 0.65, groundColor.B * 0.65)
    local footprint = Instance.new("Part")
    local footSize = Vector3.new(1.2, 0.08, 2.2)
    if Character then
        local footPart = alternateFoot and (Character:FindFirstChild("RightFoot") or Character:FindFirstChild("Right Leg")) or (Character:FindFirstChild("LeftFoot") or Character:FindFirstChild("Left Leg"))
        if footPart and footPart:IsA("BasePart") then
            footSize = Vector3.new(footPart.Size.X * 1.1, 0.08, footPart.Size.Z * 1.15)
        end
    end
    footprint.Size = footSize
    footprint.Color = darkenedColor
    footprint.Transparency = 0
    footprint.Anchored = true
    footprint.CanCollide = false
    footprint.Material = Enum.Material.SmoothPlastic
    footprint.Parent = Workspace
    local rightVector = root.CFrame.RightVector
    local sideOffset = alternateFoot and (rightVector * 0.65) or (-rightVector * 0.65)
    footprint.CFrame = CFrame.new(hitPos + hitNormal * 0.06 + sideOffset) * CFrame.Angles(0, root.CFrame.Rotation.Y, 0)
    local fadeTween = TweenService:Create(footprint, TweenInfo.new(2.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1})
    fadeTween:Play()
    fadeTween.Completed:Connect(function() footprint:Destroy() end)
end

local function cleanup()
    resetIdleVariant()
    isIdle = false
    if invisTimer then task.cancel(invisTimer) invisTimer = nil end
    isInvis = false
    deactivateInvisibility()
    isSitting = false
    SETTINGS.CrouchEnabled = false
    SETTINGS.LieEnabled = false
    isDrinking = false
    drinkBoostEndTime = 0

    if sRunTrack then pcall(function() sRunTrack:Stop() end) sRunTrack = nil end
    if phoneTrack then pcall(function() phoneTrack:Stop() end) phoneTrack = nil end
    lastSRunTime = 0

    if footprintConnection then footprintConnection:Disconnect() footprintConnection = nil end
    lastFootprintTime = 0
    local cam = Workspace.CurrentCamera
    if cam then cam.FieldOfView = originalFOV end
    if Humanoid then Humanoid.JumpPower = SETTINGS.JumpPower end
    if fadeFrame then fadeFrame.Visible = false end
end

local function removeExtraRoots()
    if not Character then return end
    local mainRoot = Character:FindFirstChild("HumanoidRootPart")
    if not mainRoot then return end
    for _, child in pairs(Character:GetChildren()) do
        if child:IsA("BasePart") and child.Name == "HumanoidRootPart" and child ~= mainRoot then
            pcall(function() child:Destroy() end)
            if child and child.Parent then
                child.Transparency = 1
                child.CanCollide = false
                child.Anchored = false
                child.Massless = true
            end
        end
    end
end

local function stopAllTracks(fadeTime)
    if not Humanoid then return end
    fadeTime = fadeTime or 0.25
    for _, track in ipairs(Humanoid:GetPlayingAnimationTracks()) do
        if isSitting and customSitTrack and track == customSitTrack then continue end
        track:Stop(fadeTime)
    end
end

-- ====================== REFRESH ANIMS (atualizado para novas animações) ======================
local function refreshAnims(fadeTime)
    fadeTime = fadeTime or 0.25
    if not Character or not Humanoid then return end

    stopAllTracks(fadeTime)

    -- Para todas as animações customizadas novas
    if sRunTrack then pcall(function() sRunTrack:Stop(0) end) sRunTrack = nil end
    if phoneTrack then pcall(function() phoneTrack:Stop(0) end) phoneTrack = nil end
    if idleVariantTrack then pcall(function() idleVariantTrack:Stop(0) end) idleVariantTrack = nil end
    if activeJumpTrack then pcall(function() activeJumpTrack:Stop(0) end) activeJumpTrack = nil end

    local animate = Character:FindFirstChild("Animate")
    if animate then
        animate.Disabled = true
        task.wait(0.05)
        animate.Disabled = false
        task.wait(0.08)
    end
end
-- =========================================================

local function updateMovementStats()
    if not Humanoid then return end
    if isDrinking or isMusicOpen then
        Humanoid.WalkSpeed = 0
        return
    end

    local baseSpeed = (SETTINGS.LieEnabled or isSitting) and 0 or SETTINGS.WalkSpeed
    if isInvis or (os.clock() < drinkBoostEndTime) then baseSpeed = SETTINGS.BoostSpeed end
    Humanoid.WalkSpeed = baseSpeed
    local baseJump = SETTINGS.JumpPower
    if os.clock() < drinkBoostEndTime then baseJump = SETTINGS.JumpPower + SETTINGS.BoostJump end
    Humanoid.JumpPower = baseJump
end

local function updateFOV()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    cam.FieldOfView = (os.clock() < drinkBoostEndTime) and SETTINGS.BoostFOV or originalFOV
end

local function setAnims()
    if not Character then return end
    local animate = Character:FindFirstChild("Animate")
    if not animate then return end
    local ids
    if not SETTINGS.Enabled then
        ids = originalIDs
    else
        ids = {
            Idle = ID_CONFIG.Idle, Idle2 = ID_CONFIG.Idle,
            Walk = ID_CONFIG.Walk, Run = ID_CONFIG.Run,
            Sit = ID_CONFIG.Sit, Fall = ID_CONFIG.Fall
        }
        if SETTINGS.LieEnabled then
            ids.Idle = ID_CONFIG.Lie
            ids.Idle2 = ID_CONFIG.Lie
        elseif SETTINGS.CrouchEnabled then
            ids.Idle = ID_CONFIG.CrouchIdle
            ids.Idle2 = ID_CONFIG.CrouchIdle
            ids.Walk = ID_CONFIG.CrouchWalk
            ids.Run = ID_CONFIG.CrouchWalk
        end
    end
    safeSet(animate, {"idle", "Animation1"}, ids.Idle)
    safeSet(animate, {"idle", "Animation2"}, ids.Idle2 or ids.Idle)
    safeSet(animate, {"walk", "WalkAnim"}, ids.Walk)
    safeSet(animate, {"run", "RunAnim"}, ids.Run)
    safeSet(animate, {"sit", "SitAnim"}, ids.Sit)
    safeSet(animate, {"fall", "FallAnim"}, ids.Fall)
    refreshAnims(0.32)
    updateMovementStats()
end

local function toggleInvis()
    if not Character or not Humanoid then return end
    if isInvis then
        isInvis = false
        if invisTimer then task.cancel(invisTimer) invisTimer = nil end
        deactivateInvisibility()
        updateMovementStats()
        SOUNDS.Deactivate:Play()
        updateButtonVisuals()
    else
        isInvis = true
        activateInvisibility()
        updateMovementStats()
        if invisTimer then task.cancel(invisTimer) end
        invisTimer = task.delay(20, function()
            if isInvis then
                isInvis = false
                deactivateInvisibility()
                updateMovementStats()
                SOUNDS.Deactivate:Play()
                updateButtonVisuals()
                invisTimer = nil
            end
        end)
        updateButtonVisuals()
    end
end

local function applyToolConfig(tool, toolName)
    local config = TOOL_CONFIGS[toolName]
    if not config then return end
    local handle = tool:FindFirstChild("Handle")
    if not handle then return end
    if config.Handle then
        handle.Size = config.Handle.Size
        handle.Material = config.Handle.Material
        if config.Handle.Transparency ~= nil then handle.Transparency = config.Handle.Transparency end
    end
    local mesh = handle:FindFirstChildOfClass("SpecialMesh")
    if mesh and config.Mesh and config.Mesh.Scale then
        mesh.Scale = config.Mesh.Scale
    end
    if config.Handle then
        local posOffset = config.Handle.Position or Vector3.new(0,0,0)
        local rot = config.Handle.Rotation or Vector3.new(0,0,0)
        tool.Grip = CFrame.new(posOffset) * CFrame.Angles(math.rad(rot.X or 0), math.rad(rot.Y or 0), math.rad(rot.Z or 0))
    end
end

local function startClockUpdater()
    task.spawn(function()
        while true do
            if clockFrame and clockFrame.Visible and timeLabel then
                timeLabel.Text = os.date("%H:%M:%S")
            end
            task.wait(1)
        end
    end)
end

local function showPhoneClock()
    if not clockFrame or clockFrame.Visible then return end
    clockFrame.Visible = true
    clockFrame.Position = UDim2.new(1, clockFrame.Size.X.Offset + 30, 0, 20)
    local finalPosition = UDim2.new(1, -(clockFrame.Size.X.Offset + 8), 0, 20)
    TweenService:Create(clockFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = finalPosition}):Play()
end

-- ====================== RELÓGIO AGORA FECHA PARA A DIREITA ======================
local function hidePhoneClock()
    if not clockFrame or not clockFrame.Visible then return end
    local offRightPosition = UDim2.new(1, clockFrame.Size.X.Offset + 30, 0, 20)
    local tween = TweenService:Create(clockFrame, TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = offRightPosition})
    tween:Play()
    tween.Completed:Once(function() clockFrame.Visible = false end)
end
-- =========================================================

-- =========================================================
-- NOVO TZE MUSIC PLAYER (com fix de animação ao fechar)
-- =========================================================
local CoreGui = game:GetService("CoreGui")
if CoreGui:FindFirstChild("TzeMusicSystem") then CoreGui.TzeMusicSystem:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TzeMusicSystem"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local currentSound = nil
local isPaused = false
local currentMode = "File"
local mp3List = {}
local currentTrackIndex = 0
isMusicOpen = false

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 350, 0, 500)
MainFrame.Position = UDim2.new(0.5, -175, 0.5, -250)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 15)
UICorner.Parent = MainFrame

local musicBorder = Instance.new("UIStroke")
musicBorder.Color = Color3.fromRGB(50, 205, 50)
musicBorder.Thickness = 4
musicBorder.Parent = MainFrame

local CameraDot = Instance.new("Frame")
CameraDot.Size = UDim2.new(0, 20, 0, 20)
CameraDot.Position = UDim2.new(0.5, -10, 0, 12)
CameraDot.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
CameraDot.BorderSizePixel = 0
CameraDot.Parent = MainFrame

local camCorner = Instance.new("UICorner", CameraDot)
camCorner.CornerRadius = UDim.new(1, 0)

local camStroke = Instance.new("UIStroke", CameraDot)
camStroke.Color = Color3.fromRGB(10, 20, 70)
camStroke.Thickness = 2.5

local lens = Instance.new("Frame", CameraDot)
lens.Size = UDim2.new(0, 9, 0, 9)
lens.Position = UDim2.new(0.5, -4.5, 0.5, -4.5)
lens.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
lens.BorderSizePixel = 0
local lensCorner = Instance.new("UICorner", lens)
lensCorner.CornerRadius = UDim.new(1, 0)

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 50)
Header.BackgroundTransparency = 1
Header.Parent = MainFrame

local ModeBtn = Instance.new("TextButton")
ModeBtn.Size = UDim2.new(0, 120, 0, 30)
ModeBtn.Position = UDim2.new(1, -130, 0.5, -15)
ModeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
ModeBtn.Text = "Modo: Arquivo"
ModeBtn.TextColor3 = Color3.new(1, 1, 1)
ModeBtn.Font = Enum.Font.GothamBold
ModeBtn.TextSize = 12
ModeBtn.Parent = Header
Instance.new("UICorner", ModeBtn)

local TrackName = Instance.new("TextLabel")
TrackName.Size = UDim2.new(1, -40, 0, 30)
TrackName.Position = UDim2.new(0, 20, 0, 60)
TrackName.BackgroundTransparency = 1
TrackName.Text = "Nenhuma música tocando"
TrackName.TextColor3 = Color3.new(1, 1, 1)
TrackName.Font = Enum.Font.GothamBold
TrackName.TextSize = 16
TrackName.TextTruncate = Enum.TextTruncate.AtEnd
TrackName.Parent = MainFrame

local TimeBarBG = Instance.new("Frame")
TimeBarBG.Size = UDim2.new(1, -40, 0, 6)
TimeBarBG.Position = UDim2.new(0, 20, 0, 100)
TimeBarBG.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
TimeBarBG.Parent = MainFrame

local TimeBarFill = Instance.new("Frame")
TimeBarFill.Size = UDim2.new(0, 0, 1, 0)
TimeBarFill.BackgroundColor3 = Color3.fromRGB(80, 150, 255)
TimeBarFill.BorderSizePixel = 0
TimeBarFill.Parent = TimeBarBG

local TimeLabel = Instance.new("TextLabel")
TimeLabel.Size = UDim2.new(1, 0, 0, 20)
TimeLabel.Position = UDim2.new(0, 0, 1, 5)
TimeLabel.BackgroundTransparency = 1
TimeLabel.Text = "00:00 / 00:00"
TimeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
TimeLabel.Font = Enum.Font.Code
TimeLabel.TextSize = 12
TimeLabel.Parent = TimeBarBG

local ScrollList = Instance.new("ScrollingFrame")
ScrollList.Size = UDim2.new(1, -20, 1, -260)
ScrollList.Position = UDim2.new(0, 10, 0, 140)
ScrollList.BackgroundTransparency = 1
ScrollList.ScrollBarThickness = 4
ScrollList.Parent = MainFrame
local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 5)
UIListLayout.Parent = ScrollList

local IDInput = Instance.new("TextBox")
IDInput.Size = UDim2.new(1, -40, 0, 40)
IDInput.Position = UDim2.new(0, 20, 1, -110)
IDInput.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
IDInput.PlaceholderText = "Digite o Sound ID aqui..."
IDInput.Text = ""
IDInput.TextColor3 = Color3.new(1, 1, 1)
IDInput.Visible = false
IDInput.Parent = MainFrame
Instance.new("UICorner", IDInput)

local Controls = Instance.new("Frame")
Controls.Size = UDim2.new(1, 0, 0, 60)
Controls.Position = UDim2.new(0, 0, 1, -60)
Controls.BackgroundTransparency = 1
Controls.Parent = MainFrame

local function createBtn(text, pos, size)
    local btn = Instance.new("TextButton")
    btn.Size = size
    btn.Position = pos
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
    btn.Text = text
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.Parent = Controls
    Instance.new("UICorner", btn)
    return btn
end

local PrevBtn = createBtn("<<", UDim2.new(0.2, -25, 0.5, -20), UDim2.new(0, 50, 0, 40))
local PlayBtn = createBtn("PLAY", UDim2.new(0.5, -35, 0.5, -25), UDim2.new(0, 70, 0, 50))
local NextBtn = createBtn(">>", UDim2.new(0.8, -25, 0.5, -20), UDim2.new(0, 50, 0, 40))

local function formatTime(seconds)
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d", mins, secs)
end

local function stopSound()
    if currentSound then
        currentSound:Stop()
        currentSound:Destroy()
        currentSound = nil
    end
end

local function play(id, name, index)
    stopSound()
    currentTrackIndex = index or 0
    currentSound = Instance.new("Sound", MainFrame)
    currentSound.SoundId = id
    currentSound.Volume = 1
    currentSound:Play()
    TrackName.Text = name
    PlayBtn.Text = "PAUSE"
    isPaused = false
end

local function refreshFiles()
    for _, v in pairs(ScrollList:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
    mp3List = {}
    
    local success, files = pcall(function() return listfiles("") end)
    if success then
        local count = 0
        for _, file in ipairs(files) do
            if file:lower():match("%.mp3$") then
                count = count + 1
                local name = file:match("([^/\\]+)$") or file
                table.insert(mp3List, {name = name, path = file})
                
                local btnFrame = Instance.new("Frame")
                btnFrame.Size = UDim2.new(1, 0, 0, 40)
                btnFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
                btnFrame.Parent = ScrollList
                Instance.new("UICorner", btnFrame)
                
                local t = Instance.new("TextButton")
                t.Size = UDim2.new(1, 0, 1, 0)
                t.BackgroundTransparency = 1
                t.Text = "  " .. name
                t.TextColor3 = Color3.new(1,1,1)
                t.TextXAlignment = Enum.TextXAlignment.Left
                t.Parent = btnFrame
                
                local idx = count
                t.MouseButton1Click:Connect(function()
                    play(getcustomasset(file), name, idx)
                end)
            end
        end
    end
    ScrollList.CanvasSize = UDim2.new(0,0,0, UIListLayout.AbsoluteContentSize.Y)
end

local function toggleMusicPlayer()
    if isMusicOpen then
        -- FECHANDO O MUSIC PLAYER → animação do celular PARA + refresh
        local target = UDim2.new(0.5, -175, 1, 50)
        local tween = TweenService:Create(MainFrame, TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = target})
        tween:Play()
        tween.Completed:Once(function()
            MainFrame.Visible = false
            isMusicOpen = false
            updateMovementStats()
            updatePhoneAnimation()
            refreshAnims(0.25) -- FIX: sempre atualiza RefreshAnims ao fechar
        end)
    else
        -- ABRINDO
        MainFrame.Visible = true
        MainFrame.Position = UDim2.new(0.5, -175, 1, 50)
        local target = UDim2.new(0.5, -175, 0.5, -250)
        local tween = TweenService:Create(MainFrame, TweenInfo.new(0.65, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = target})
        tween:Play()
        isMusicOpen = true
        updateMovementStats()
        stopAllTracks(0.2)
        updatePhoneAnimation()
        if currentMode == "File" then
            refreshFiles()
        end
    end
end

ModeBtn.MouseButton1Click:Connect(function()
    if currentMode == "File" then
        currentMode = "ID"
        ModeBtn.Text = "Modo: Sound ID"
        ScrollList.Visible = false
        IDInput.Visible = true
    else
        currentMode = "File"
        ModeBtn.Text = "Modo: Arquivo"
        ScrollList.Visible = true
        IDInput.Visible = false
        refreshFiles()
    end
end)

IDInput.FocusLost:Connect(function(enter)
    if enter and IDInput.Text ~= "" then
        local id = "rbxassetid://" .. IDInput.Text:gsub("%D", "")
        play(id, "ID: " .. IDInput.Text, 0)
    end
end)

PlayBtn.MouseButton1Click:Connect(function()
    if not currentSound then return end
    if isPaused then
        currentSound:Resume()
        PlayBtn.Text = "PAUSE"
    else
        currentSound:Pause()
        PlayBtn.Text = "PLAY"
    end
    isPaused = not isPaused
end)

NextBtn.MouseButton1Click:Connect(function()
    if currentMode == "File" and #mp3List > 0 then
        local nextIdx = (currentTrackIndex % #mp3List) + 1
        play(getcustomasset(mp3List[nextIdx].path), mp3List[nextIdx].name, nextIdx)
    end
end)

PrevBtn.MouseButton1Click:Connect(function()
    if currentMode == "File" and #mp3List > 0 then
        local prevIdx = currentTrackIndex - 1
        if prevIdx < 1 then prevIdx = #mp3List end
        play(getcustomasset(mp3List[prevIdx].path), mp3List[prevIdx].name, prevIdx)
    end
end)

RunService.RenderStepped:Connect(function()
    if currentSound and (currentSound.IsPlaying or isPaused) then
        local duration = currentSound.TimeLength
        local current = currentSound.TimePosition
        if duration > 0 then
            TimeBarFill.Size = UDim2.new(current/duration, 0, 1, 0)
            TimeLabel.Text = formatTime(current) .. " / " .. formatTime(duration)
        end
    end
end)

MainFrame.Visible = false
refreshFiles()

-- =========================================================
-- FIM DO MUSIC PLAYER
-- =========================================================

local function createBoostTool()
    local toolName = "BloxyCola"
    if Player.Backpack:FindFirstChild(toolName) then return end
    local tool = Instance.new("Tool")
    tool.Name = toolName
    tool.RequiresHandle = true
    tool.CanBeDropped = false
    tool.Parent = Player.Backpack
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.BrickColor = BrickColor.new(TOOL_IDS.BloxyCola.HandleColor)
    handle.Parent = tool
    local mesh = Instance.new("SpecialMesh")
    mesh.MeshId = TOOL_IDS.BloxyCola.MeshId
    mesh.TextureId = TOOL_IDS.BloxyCola.TextureId
    mesh.Parent = handle
    applyToolConfig(tool, toolName)
    tool.Activated:Connect(function()
        if isDrinking or (os.clock() < drinkBoostEndTime) or not Humanoid or not Character then return end
        isDrinking = true
        updateMovementStats()
        stopAllTracks(0.2)
        SOUNDS.Drink:Play()
        local drinkTrack = loadAnim(ID_CONFIG.Drink)
        if not drinkTrack then isDrinking = false return end
        drinkTrack.Looped = false
        drinkTrack:Play(0.3)
        task.delay(SETTINGS.DrinkDuration, function()
            if drinkTrack then drinkTrack:Stop(0.5) end
            isDrinking = false
            drinkBoostEndTime = os.clock() + SETTINGS.BoostDuration
            updateMovementStats()
            updateFOV()
            playBoostFade(true)
            task.delay(SETTINGS.BoostDuration, function()
                if os.clock() >= drinkBoostEndTime then
                    drinkBoostEndTime = 0
                    updateMovementStats()
                    updateFOV()
                    playBoostFade(false)
                end
            end)
            refreshAnims(0.3)
        end)
    end)
end

local function createPhoneTool()
    local toolName = "TzesPhone"
    if Player.Backpack:FindFirstChild(toolName) then return end
    local tool = Instance.new("Tool")
    tool.Name = toolName
    tool.RequiresHandle = true
    tool.CanBeDropped = true
    tool.Parent = Player.Backpack
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.BrickColor = BrickColor.new(TOOL_IDS.TzesPhone.HandleColor)
    handle.Parent = tool
    local mesh = Instance.new("SpecialMesh")
    mesh.MeshId = TOOL_IDS.TzesPhone.MeshId
    mesh.TextureId = TOOL_IDS.TzesPhone.TextureId
    mesh.Parent = handle
    local equipSound = Instance.new("Sound")
    equipSound.SoundId = "rbxassetid://140691817123595"
    equipSound.Volume = 0.6
    equipSound.Parent = handle
    applyToolConfig(tool, toolName)
    tool.Equipped:Connect(function()
        equipSound:Play()
        showPhoneClock()
    end)
    tool.Unequipped:Connect(function()
        hidePhoneClock()
        if isMusicOpen then
            local target = UDim2.new(0.5, -175, 1, 100)
            local tweenPos = TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = target})
            local tweenFade = TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {BackgroundTransparency = 1})
            tweenPos:Play()
            tweenFade:Play()
            tweenPos.Completed:Once(function()
                MainFrame.Visible = false
                MainFrame.BackgroundTransparency = 0
                isMusicOpen = false
                updateMovementStats()
                updatePhoneAnimation()
                refreshAnims(0.25) -- FIX: sempre atualiza RefreshAnims ao fechar via unequip
            end)
        end
    end)
    tool.Activated:Connect(function()
        toggleMusicPlayer()
    end)
end

local function createLanternTool()
    local toolName = "Lanterna"
    if Player.Backpack:FindFirstChild(toolName) then return end
    local tool = Instance.new("Tool")
    tool.Name = toolName
    tool.RequiresHandle = true
    tool.CanBeDropped = true
    tool.Parent = Player.Backpack
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.BrickColor = BrickColor.new(TOOL_IDS.Lanterna.HandleColor)
    handle.Parent = tool
    local mesh = Instance.new("SpecialMesh")
    mesh.MeshId = TOOL_IDS.Lanterna.MeshId
    mesh.TextureId = TOOL_IDS.Lanterna.TextureId
    mesh.Parent = handle
    local lanternLight = Instance.new("SpotLight")
    lanternLight.Name = "LanternLight"
    lanternLight.Brightness = TOOL_CONFIGS.Lanterna.LanternLight.Brightness
    lanternLight.Range = TOOL_CONFIGS.Lanterna.LanternLight.Range
    lanternLight.Angle = TOOL_CONFIGS.Lanterna.LanternLight.Angle
    lanternLight.Enabled = false
    lanternLight.Parent = handle
    local clickSound = Instance.new("Sound")
    clickSound.SoundId = "rbxassetid://135865643321210"
    clickSound.Volume = 0.5
    clickSound.Parent = handle
    local isLightOn = false
    applyToolConfig(tool, toolName)
    tool.Activated:Connect(function()
        isLightOn = not isLightOn
        lanternLight.Enabled = isLightOn
        clickSound:Play()
    end)
end

local function onCharacterAdded(char)
    cleanup()
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    Animator = Humanoid:WaitForChild("Animator")
    removeExtraRoots()
    createSounds()
    local camera = Workspace.CurrentCamera
    if camera then originalFOV = camera.FieldOfView end

    local animate = char:WaitForChild("Animate")
    local anim2Id = animate.idle.Animation1.AnimationId
    if animate.idle:FindFirstChild("Animation2") then anim2Id = animate.idle.Animation2.AnimationId end
    local sitId = ""
    local sitFolder = animate:FindFirstChild("sit")
    if sitFolder and sitFolder:FindFirstChild("SitAnim") then sitId = sitFolder.SitAnim.AnimationId end
    local fallId = ""
    local fallFolder = animate:FindFirstChild("fall")
    if fallFolder and fallFolder:FindFirstChild("FallAnim") then fallId = fallFolder.FallAnim.AnimationId end
    originalIDs = {
        Idle  = animate.idle.Animation1.AnimationId,
        Idle2 = anim2Id,
        Walk  = animate.walk.WalkAnim.AnimationId,
        Run   = animate.run.RunAnim.AnimationId,
        Sit   = sitId,
        Fall  = fallId
    }

    Humanoid.JumpPower = SETTINGS.JumpPower
    setAnims()

    if jumpingConnection then jumpingConnection:Disconnect() end
    jumpingConnection = Humanoid.Jumping:Connect(function()
        if not SETTINGS.Enabled or SETTINGS.LieEnabled or isSitting then return end
        local root = Character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local speed = Vector3.new(root.Velocity.X, 0, root.Velocity.Z).Magnitude
        local animId = speed >= 8 and ID_CONFIG.JumpRunning or ID_CONFIG.JumpStanding
        if activeJumpTrack and activeJumpTrack.IsPlaying then activeJumpTrack:Stop(0.2) end
        activeJumpTrack = loadAnim(animId)
        if not activeJumpTrack then return end
        activeJumpTrack.Looped = false
        activeJumpTrack.Priority = Enum.AnimationPriority.Movement
        activeJumpTrack:Play(0.3)
        activeJumpTrack.Stopped:Once(function() activeJumpTrack = nil end)
    end)

    if footprintConnection then footprintConnection:Disconnect() end
    footprintConnection = RunService.Heartbeat:Connect(function()
        updateIdleStatus()
        updateRunAnimation()
        updatePhoneAnimation()
        if not Character or not Humanoid or isDrinking or isSitting or SETTINGS.LieEnabled or isInvis or isMusicOpen then return end
        local root = Character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local horizSpeed = Vector3.new(root.Velocity.X, 0, root.Velocity.Z).Magnitude
        if horizSpeed >= 15 and (os.clock() - lastFootprintTime >= SETTINGS.FootprintInterval) then
            spawnFootprint(root)
            lastFootprintTime = os.clock()
            alternateFoot = not alternateFoot
        end
    end)

    createBoostTool()
    createPhoneTool()
    createLanternTool()
end

Player.CharacterRemoving:Connect(cleanup)
Player.CharacterAdded:Connect(onCharacterAdded)
if Player.Character then onCharacterAdded(Player.Character) end

local ScreenGuiAnim = game.CoreGui:FindFirstChild("CustomAnimGui")
if ScreenGuiAnim then ScreenGuiAnim:Destroy() end

ScreenGuiAnim = Instance.new("ScreenGui")
ScreenGuiAnim.Name = "CustomAnimGui"
ScreenGuiAnim.ResetOnSpawn = false
ScreenGuiAnim.IgnoreGuiInset = true
ScreenGuiAnim.Parent = game.CoreGui

local ButtonsFrame = Instance.new("Frame")
ButtonsFrame.Size = UDim2.new(0, 80, 0, 225)
ButtonsFrame.Position = UDim2.new(1, -85, 0, 80)
ButtonsFrame.BackgroundTransparency = 1
ButtonsFrame.Parent = ScreenGuiAnim

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 12)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ListLayout.Parent = ButtonsFrame

fadeFrame = Instance.new("Frame")
fadeFrame.Name = "BoostFade"
fadeFrame.Size = UDim2.new(1, 0, 1, 0)
fadeFrame.BackgroundColor3 = Color3.fromRGB(255, 140, 30)
fadeFrame.BackgroundTransparency = 1
fadeFrame.BorderSizePixel = 0
fadeFrame.ZIndex = 999
fadeFrame.Visible = false
fadeFrame.Parent = ScreenGuiAnim

clockFrame = Instance.new("Frame")
clockFrame.Name = "TzePhoneClock"
clockFrame.Size = UDim2.new(0, 210, 0, 65)
clockFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
clockFrame.BackgroundTransparency = 0.25
clockFrame.BorderSizePixel = 0
clockFrame.Visible = false
clockFrame.Parent = ScreenGuiAnim

local clockCorner = Instance.new("UICorner")
clockCorner.CornerRadius = UDim.new(0, 16)
clockCorner.Parent = clockFrame

local clockStroke = Instance.new("UIStroke")
clockStroke.Color = Color3.fromRGB(100, 80, 255)
clockStroke.Thickness = 3
clockStroke.Parent = clockFrame

timeLabel = Instance.new("TextLabel")
timeLabel.Size = UDim2.new(1, -20, 1, -10)
timeLabel.Position = UDim2.new(0, 10, 0, 5)
timeLabel.BackgroundTransparency = 1
timeLabel.Text = "88:88:88"
timeLabel.TextColor3 = Color3.fromRGB(220, 220, 255)
timeLabel.TextScaled = true
timeLabel.Font = Enum.Font.GothamBold
timeLabel.TextStrokeTransparency = 0.8
timeLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
timeLabel.Parent = clockFrame

startClockUpdater()
createBoostTool()
createPhoneTool()
createLanternTool()

local function createActionButton(imageAssetId)
    local button = Instance.new("ImageButton")
    button.Size = UDim2.new(0, 60, 0, 60)
    button.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    button.Image = "rbxassetid://" .. imageAssetId
    button.Parent = ButtonsFrame
    local corner = Instance.new("UICorner") corner.CornerRadius = UDim.new(1, 0) corner.Parent = button
    local stroke = Instance.new("UIStroke") stroke.Thickness = 4 stroke.Color = Color3.fromRGB(110, 90, 255) stroke.Parent = button
    local hover = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    button.MouseEnter:Connect(function() TweenService:Create(button, hover, {Size = UDim2.new(0,65,0,65)}):Play() end)
    button.MouseLeave:Connect(function() TweenService:Create(button, hover, {Size = UDim2.new(0,60,0,60)}):Play() end)
    return button
end

local invisButton  = createActionButton("139318375061911")
local crouchButton = createActionButton("14594862556")
local sitButton    = createActionButton("94572819761865")
local lieButton    = createActionButton("99462728922874")

local function updateButtonVisuals()
    if crouchButton then crouchButton.UIStroke.Color = SETTINGS.CrouchEnabled and Color3.fromRGB(0,200,80) or Color3.fromRGB(110,90,255) end
    if sitButton then sitButton.UIStroke.Color = isSitting and Color3.fromRGB(0,200,80) or Color3.fromRGB(110,90,255) end
    if lieButton then lieButton.UIStroke.Color = SETTINGS.LieEnabled and Color3.fromRGB(0,200,80) or Color3.fromRGB(110,90,255) end
    if invisButton then invisButton.UIStroke.Color = isInvis and Color3.fromRGB(0,200,80) or Color3.fromRGB(110,90,255) end
end

crouchButton.MouseButton1Click:Connect(function()
    if not SETTINGS.Enabled then return end
    SETTINGS.CrouchEnabled = not SETTINGS.CrouchEnabled
    if isSitting then isSitting = false end
    SETTINGS.LieEnabled = false
    setAnims()
    updateButtonVisuals()
end)

sitButton.MouseButton1Click:Connect(function()
    if not SETTINGS.Enabled or not Humanoid then return end
    isSitting = not isSitting
    if isSitting then
        stopAllTracks(0.25)
        if customSitTrack then pcall(function() customSitTrack:Stop() end) customSitTrack = nil end
        customSitTrack = loadAnim(ID_CONFIG.Sit)
        if not customSitTrack then return end
        customSitTrack.Looped = true
        customSitTrack.Priority = Enum.AnimationPriority.Core
        customSitTrack:Play(0.3)
    else
        if customSitTrack then pcall(function() customSitTrack:Stop(0.25) end) customSitTrack = nil end
        refreshAnims(0.3)
    end
    updateMovementStats()
    updateButtonVisuals()
end)

lieButton.MouseButton1Click:Connect(function()
    if not SETTINGS.Enabled then return end
    SETTINGS.LieEnabled = not SETTINGS.LieEnabled
    if isSitting then isSitting = false end
    SETTINGS.CrouchEnabled = false
    setAnims()
    updateButtonVisuals()
end)

invisButton.MouseButton1Click:Connect(toggleInvis)

updateButtonVisuals()
