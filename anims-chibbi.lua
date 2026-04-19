local ID_CONFIG = {
    Idle        = "rbxassetid://125884328313129",
    Walk        = "rbxassetid://83956889754850",
    Run         = "rbxassetid://85887415033585",
    JumpRunning = "rbxassetid://92878546218290",
    JumpStanding = "rbxassetid://132779477045913",
    CrouchIdle  = "rbxassetid://126025646410749",
    CrouchWalk  = "rbxassetid://118788948575185",
    Sit         = "rbxassetid://75243953240047",
    Lie         = "rbxassetid://89306087118726",
    IdleVariant = "rbxassetid://129026910898635"
}

local SETTINGS = {
    WalkSpeed = 14,
    RunSpeed = 16,
    JumpPower = 50,
    Enabled = true,
    CrouchEnabled = false,
    LieEnabled = false
}

local Player = game.Players.LocalPlayer
local Character, Humanoid
local originalIDs = {}
local jumpingConnection = nil
local stateConnection = nil
local activeJumpTrack = nil

local tempSeat = nil
local customSitTrack = nil
local isSitting = false

local idleVariantTrack = nil
local idleTimeout = nil
local movementConnection = nil

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local speedConnection = nil

-- ====================== FUNÇÃO CLEANUP (NOVO - EVITA ERROS NO RECARREGAMENTO/RESPAWN) ======================
local function cleanup()
    if idleTimeout then
        task.cancel(idleTimeout)
        idleTimeout = nil
    end
    if idleVariantTrack then
        pcall(function()
            if idleVariantTrack.IsPlaying then
                idleVariantTrack:Stop(0.2)
            end
        end)
        idleVariantTrack = nil
    end
    if movementConnection then
        movementConnection:Disconnect()
        movementConnection = nil
    end
    if speedConnection then
        speedConnection:Disconnect()
        speedConnection = nil
    end
    if jumpingConnection then
        jumpingConnection:Disconnect()
        jumpingConnection = nil
    end
    if stateConnection then
        stateConnection:Disconnect()
        stateConnection = nil
    end
    if customSitTrack then
        pcall(function()
            if customSitTrack.IsPlaying then
                customSitTrack:Stop(0.25)
            end
        end)
        customSitTrack = nil
    end
    if tempSeat then
        if tempSeat.Parent then
            tempSeat:Destroy()
        end
        tempSeat = nil
    end
    isSitting = false
    SETTINGS.CrouchEnabled = false
    SETTINGS.LieEnabled = false
end
-- =============================================================================================================

local function stopAllTracks(fadeTime)
    if not Humanoid then return end
    fadeTime = fadeTime or 0.25
    for _, track in ipairs(Humanoid:GetPlayingAnimationTracks()) do
        if isSitting and customSitTrack and track == customSitTrack then continue end
        track:Stop(fadeTime)
    end
end

local function forceIdleRefresh()
    if not Humanoid then return end
    local original = Humanoid.PlatformStand
    Humanoid.PlatformStand = true
    task.wait(0.025)
    Humanoid.PlatformStand = original
end

local function refreshAnims(fadeTime)
    fadeTime = fadeTime or 0.25
    if not Character or not Humanoid then return end
    
    stopAllTracks(fadeTime)
    
    local animate = Character:FindFirstChild("Animate")
    if animate then
        animate.Disabled = true
        task.wait(0.04)
        animate.Disabled = false
        task.wait(0.06)
    end
    forceIdleRefresh()
end

local function updateWalkSpeed()
    if not Humanoid then return end
    Humanoid.WalkSpeed = (SETTINGS.LieEnabled or isSitting) and 0 or SETTINGS.WalkSpeed
end

local function setupAnimationSpeedControl()
    if speedConnection then speedConnection:Disconnect() end
    if not Humanoid then return end

    speedConnection = Humanoid.Running:Connect(function(currentSpeed)
        if not SETTINGS.Enabled or isSitting or SETTINGS.LieEnabled then return end

        for _, track in ipairs(Humanoid:GetPlayingAnimationTracks()) do
            if track.IsPlaying and track.Animation then
                local animId = track.Animation.AnimationId
                if animId == ID_CONFIG.Walk or animId == ID_CONFIG.CrouchWalk then
                    track:AdjustSpeed(currentSpeed / SETTINGS.WalkSpeed)
                elseif animId == ID_CONFIG.Run then
                    track:AdjustSpeed(currentSpeed / SETTINGS.RunSpeed)
                end
            end
        end
    end)
end

local function resetIdleVariant()
    if idleTimeout then
        task.cancel(idleTimeout)
        idleTimeout = nil
    end
    if idleVariantTrack then
        if idleVariantTrack.IsPlaying then
            idleVariantTrack:Stop(0.2)
        end
        idleVariantTrack = nil
    end
end

local function playIdleVariant()
    if not Humanoid or not SETTINGS.Enabled or isSitting or SETTINGS.LieEnabled or SETTINGS.CrouchEnabled then return end
    if Humanoid.MoveDirection.Magnitude > 0.1 then return end

    local anim = Instance.new("Animation")
    anim.AnimationId = ID_CONFIG.IdleVariant
    idleVariantTrack = Humanoid:LoadAnimation(anim)
    idleVariantTrack.Priority = Enum.AnimationPriority.Idle
    idleVariantTrack.Looped = false
    idleVariantTrack:Play(0.2)

    idleVariantTrack.Stopped:Once(function()
        idleVariantTrack = nil
        if Humanoid and Humanoid.Parent and Humanoid.Health > 0 and Humanoid.MoveDirection.Magnitude < 0.1 then
            scheduleIdleVariant()
        end
    end)
end

local function scheduleIdleVariant()
    resetIdleVariant()
    idleTimeout = task.delay(20, playIdleVariant)
end

local function setupIdleVariant()
    resetIdleVariant()
    if movementConnection then movementConnection:Disconnect() end
    if not Humanoid or not SETTINGS.Enabled then return end

    movementConnection = Humanoid.Running:Connect(function(currentSpeed)
        if not SETTINGS.Enabled or isSitting or SETTINGS.LieEnabled or SETTINGS.CrouchEnabled then
            resetIdleVariant()
            return
        end

        if currentSpeed > 2 then
            resetIdleVariant()
        elseif currentSpeed < 0.5 then
            if not idleTimeout then
                scheduleIdleVariant()
            end
        end
    end)

    task.delay(0.5, function()
        if Humanoid and Humanoid.MoveDirection.Magnitude < 0.1 then
            scheduleIdleVariant()
        end
    end)
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
            Idle = ID_CONFIG.Idle,
            Walk = ID_CONFIG.Walk,
            Run  = ID_CONFIG.Run,
            Jump = "rbxassetid://0",
            Sit  = ID_CONFIG.Sit
        }

        if SETTINGS.LieEnabled then
            ids.Idle = ID_CONFIG.Lie
        elseif SETTINGS.CrouchEnabled then
            ids.Idle = ID_CONFIG.CrouchIdle
            ids.Walk = ID_CONFIG.CrouchWalk
            ids.Run  = ID_CONFIG.CrouchWalk
        end
    end

    local function safeSet(path, id)
        local obj = animate
        for _, key in ipairs(path) do
            obj = obj:FindFirstChild(key)
            if not obj then return end
        end
        if obj then obj.AnimationId = id end
    end

    safeSet({"idle", "Animation1"}, ids.Idle)
    safeSet({"idle", "Animation2"}, ids.Idle2 or ids.Idle)

    safeSet({"walk", "WalkAnim"}, ids.Walk)
    safeSet({"run", "RunAnim"}, ids.Run)
    safeSet({"jump", "JumpAnim"}, ids.Jump)
    safeSet({"sit", "SitAnim"}, ids.Sit)

    refreshAnims(0.32)
    updateWalkSpeed()
end

local function unsit()
    isSitting = false
    if customSitTrack then
        customSitTrack:Stop(0.25)
        customSitTrack = nil
    end
    if tempSeat then
        tempSeat:Destroy()
        tempSeat = nil
    end
    if Humanoid then
        Humanoid.Sit = false
    end
    updateWalkSpeed()
    refreshAnims(0.25)
    setupIdleVariant()
end

local function sit()
    isSitting = true
    if not Character or not Humanoid then return end

    local root = Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    if tempSeat then
        tempSeat:Destroy()
        tempSeat = nil
    end

    tempSeat = Instance.new("Seat")
    tempSeat.Name = "TempCustomSit"
    tempSeat.Transparency = 1
    tempSeat.CanCollide = true
    tempSeat.Anchored = true
    tempSeat.Size = Vector3.new(3, 0.2, 3)

    local rayOrigin = root.Position + Vector3.new(0, 8, 0)
    local rayDirection = Vector3.new(0, -100, 0)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

    local seatY = raycastResult and (raycastResult.Position.Y + 0.15) or (root.Position.Y - Humanoid.HipHeight - 1.2)

    tempSeat.CFrame = CFrame.new(root.Position.X, seatY, root.Position.Z) * root.CFrame.Rotation
    tempSeat.Parent = workspace

    task.spawn(function()
        task.wait(0.05)
        if Humanoid and tempSeat and tempSeat.Parent then
            tempSeat:Sit(Humanoid)

            if customSitTrack then customSitTrack:Stop() end
            local anim = Instance.new("Animation")
            anim.AnimationId = ID_CONFIG.Sit
            customSitTrack = Humanoid:LoadAnimation(anim)
            customSitTrack.Priority = Enum.AnimationPriority.Action4
            customSitTrack.Looped = true
            customSitTrack:Play(0.3)
        end
    end)

    updateWalkSpeed()
    setupIdleVariant()
end

local function toggleSit()
    if isSitting then unsit() else sit() end
end

local function setupJumpVariants()
    if not Humanoid then return end

    local jumpRunningAnimation = Instance.new("Animation")
    jumpRunningAnimation.AnimationId = ID_CONFIG.JumpRunning

    local jumpStandingAnimation = Instance.new("Animation")
    jumpStandingAnimation.AnimationId = ID_CONFIG.JumpStanding

    activeJumpTrack = nil

    if jumpingConnection then jumpingConnection:Disconnect() end
    if stateConnection then stateConnection:Disconnect() end

    jumpingConnection = Humanoid.Jumping:Connect(function()
        if not SETTINGS.Enabled or SETTINGS.LieEnabled or isSitting then return end

        local root = Character:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local horizSpeed = Vector3.new(root.Velocity.X, 0, root.Velocity.Z).Magnitude
        local isRunningJump = horizSpeed >= 8

        local selectedAnim = isRunningJump and jumpRunningAnimation or jumpStandingAnimation

        if activeJumpTrack and activeJumpTrack.IsPlaying then
            activeJumpTrack:Stop(0.2)
        end

        activeJumpTrack = Humanoid:LoadAnimation(selectedAnim)
        activeJumpTrack.Looped = false
        activeJumpTrack.Priority = Enum.AnimationPriority.Movement
        activeJumpTrack:Play(0.3)

        activeJumpTrack.Stopped:Once(function()
            activeJumpTrack = nil
        end)
    end)

    stateConnection = Humanoid.StateChanged:Connect(function(_, newState)
        if isSitting and newState == Enum.HumanoidStateType.Jumping then
            unsit()
        end
        if activeJumpTrack and activeJumpTrack.IsPlaying then
            if newState == Enum.HumanoidStateType.Running or 
               newState == Enum.HumanoidStateType.Landed or 
               newState == Enum.HumanoidStateType.GettingUp then
                activeJumpTrack:Stop(0.2)
                activeJumpTrack = nil
            end
        end
    end)
end

local function onCharacterAdded(char)
    cleanup()  -- limpeza extra de segurança no respawn

    Character = char
    Humanoid = char:WaitForChild("Humanoid")

    local animate = char:WaitForChild("Animate")
    
    local anim2Id = animate.idle.Animation1.AnimationId
    if animate.idle:FindFirstChild("Animation2") then
        anim2Id = animate.idle.Animation2.AnimationId
    end

    local sitId = ""
    local sitFolder = animate:FindFirstChild("sit")
    if sitFolder and sitFolder:FindFirstChild("SitAnim") then
        sitId = sitFolder.SitAnim.AnimationId
    end

    originalIDs = {
        Idle  = animate.idle.Animation1.AnimationId,
        Idle2 = anim2Id,
        Walk  = animate.walk.WalkAnim.AnimationId,
        Run   = animate.run.RunAnim.AnimationId,
        Jump  = animate.jump.JumpAnim.AnimationId,
        Sit   = sitId
    }

    Humanoid.JumpPower = SETTINGS.JumpPower

    setupJumpVariants()
    setAnims()
    setupAnimationSpeedControl()
    setupIdleVariant()
end

-- Conexões principais
Player.CharacterRemoving:Connect(cleanup)
Player.CharacterAdded:Connect(onCharacterAdded)
if Player.Character then onCharacterAdded(Player.Character) end

-- ====================== NOVOS BOTÕES MOBILE ======================
local ScreenGui = game.CoreGui:FindFirstChild("CustomAnimGui")
if ScreenGui then ScreenGui:Destroy() end

ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CustomAnimGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.CoreGui

local ButtonsFrame = Instance.new("Frame")
ButtonsFrame.Size = UDim2.new(0, 80, 0, 225)
ButtonsFrame.Position = UDim2.new(1, -85, 0, 80)
ButtonsFrame.BackgroundTransparency = 1
ButtonsFrame.Parent = ScreenGui

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 12)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ListLayout.Parent = ButtonsFrame

local function createActionButton(imageAssetId)
    local button = Instance.new("ImageButton")
    button.Size = UDim2.new(0, 60, 0, 60)
    button.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    button.Image = "rbxassetid://" .. imageAssetId
    button.Parent = ButtonsFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = button

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 4
    stroke.Color = Color3.fromRGB(110, 90, 255)
    stroke.Parent = button

    local hoverTween = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    button.MouseEnter:Connect(function()
        TweenService:Create(button, hoverTween, {Size = UDim2.new(0, 65, 0, 65)}):Play()
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(button, hoverTween, {Size = UDim2.new(0, 60, 0, 60)}):Play()
    end)

    return button
end

local crouchButton = createActionButton("14594862556")
local sitButton    = createActionButton("94572819761865")
local lieButton    = createActionButton("99462728922874")

local function updateButtonVisuals()
    if crouchButton then
        crouchButton.UIStroke.Color = SETTINGS.CrouchEnabled and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(110, 90, 255)
    end
    if sitButton then
        sitButton.UIStroke.Color = isSitting and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(110, 90, 255)
    end
    if lieButton then
        lieButton.UIStroke.Color = SETTINGS.LieEnabled and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(110, 90, 255)
    end
end

crouchButton.MouseButton1Click:Connect(function()
    if not SETTINGS.Enabled then return end
    SETTINGS.CrouchEnabled = not SETTINGS.CrouchEnabled
    if isSitting then unsit() end
    SETTINGS.LieEnabled = false
    setAnims()
    setupIdleVariant()
    updateButtonVisuals()
end)

sitButton.MouseButton1Click:Connect(function()
    if not SETTINGS.Enabled then return end
    toggleSit()
    updateButtonVisuals()
end)

lieButton.MouseButton1Click:Connect(function()
    if not SETTINGS.Enabled then return end
    SETTINGS.LieEnabled = not SETTINGS.LieEnabled
    if isSitting then unsit() end
    SETTINGS.CrouchEnabled = false
    setAnims()
    setupIdleVariant()
    updateButtonVisuals()
end)

updateButtonVisuals()
