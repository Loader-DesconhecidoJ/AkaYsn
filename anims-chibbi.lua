local ID_CONFIG = {
    Idle        = "rbxassetid://125884328313129",
    Walk        = "rbxassetid://83956889754850",
    Run         = "rbxassetid://85887415033585",
    JumpRunning = "rbxassetid://122785576025483",
    JumpStanding = "rbxassetid://132779477045913",
    CrouchIdle  = "rbxassetid://126025646410749",
    CrouchWalk  = "rbxassetid://118788948575185",
    Sit         = "rbxassetid://75243953240047",
    Lie         = "rbxassetid://98220014348433",
    IdleVariant = "rbxassetid://129026910898635",
    Drink       = "rbxassetid://85688041753037",
    Fall        = "rbxassetid://132779477045913"
}

local SETTINGS = {
    WalkSpeed        = 14,
    RunSpeed         = 16,
    JumpPower        = 50,
    Enabled          = true,
    CrouchEnabled    = false,
    LieEnabled       = false,

    DrinkDuration    = 4.5,
    BoostDuration    = 10,
    BoostSpeed       = 23,
    BoostFOV         = 90,
    BoostJump        = 17,

    FootprintInterval = 0.32,
}

local Player = game.Players.LocalPlayer
local Character, Humanoid
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

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local SOUNDS = {}

local function createSounds()
    for _, sound in pairs(Player:WaitForChild("PlayerGui"):GetChildren()) do
        if sound:IsA("Sound") and (
            sound.SoundId == "rbxassetid://73840813063136" or
            sound.SoundId == "rbxassetid://73836316475925" or
            sound.SoundId == "rbxassetid://138475744729338"
        ) then
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
    
    TweenService:Create(fadeFrame, TweenInfo.new(inDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
        BackgroundTransparency = targetTrans
    }):Play()
    
    task.delay(inDuration + holdTime, function()
        if fadeFrame and fadeFrame.Parent then
            TweenService:Create(fadeFrame, TweenInfo.new(outDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = 1
            }):Play()
            
            task.delay(outDuration, function()
                if fadeFrame and fadeFrame.Parent then
                    fadeFrame.Visible = false
                end
            end)
        end
    end)
end

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

    local darkenedColor = Color3.new(
        groundColor.R * 0.65,
        groundColor.G * 0.65,
        groundColor.B * 0.65
    )

    local footprint = Instance.new("Part")
    
    local footSize = Vector3.new(1.2, 0.08, 2.2)
    if Character then
        local footPart = alternateFoot 
            and (Character:FindFirstChild("RightFoot") or Character:FindFirstChild("Right Leg"))
            or  (Character:FindFirstChild("LeftFoot") or Character:FindFirstChild("Left Leg"))
        
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
    footprint.CFrame = CFrame.new(hitPos + hitNormal * 0.06 + sideOffset) 
        * CFrame.Angles(0, root.CFrame.Rotation.Y, 0)

    local fadeTween = TweenService:Create(footprint, TweenInfo.new(2.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1})
    fadeTween:Play()
    fadeTween.Completed:Connect(function()
        footprint:Destroy()
    end)
end

local function cleanup()
    if invisTimer then task.cancel(invisTimer) invisTimer = nil end
    isInvis = false
    deactivateInvisibility()

    isSitting = false
    SETTINGS.CrouchEnabled = false
    SETTINGS.LieEnabled = false

    isDrinking = false
    drinkBoostEndTime = 0

    if footprintConnection then
        footprintConnection:Disconnect()
        footprintConnection = nil
    end
    lastFootprintTime = 0

    local cam = Workspace.CurrentCamera
    if cam then cam.FieldOfView = originalFOV end
    
    if Humanoid then 
        Humanoid.JumpPower = SETTINGS.JumpPower 
    end
    
    if fadeFrame then 
        fadeFrame.Visible = false 
    end
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

local function refreshAnims(fadeTime)
    fadeTime = fadeTime or 0.25
    if not Character or not Humanoid then return end
    stopAllTracks(fadeTime)
    local animate = Character:FindFirstChild("Animate")
    if animate then
        animate.Disabled = true
        task.wait(0.05)
        animate.Disabled = false
        task.wait(0.08)
    end
end

local function updateMovementStats()
    if not Humanoid then return end
    if isDrinking then
        Humanoid.WalkSpeed = 0
        return
    end
    
    local baseSpeed = (SETTINGS.LieEnabled or isSitting) and 0 or SETTINGS.WalkSpeed
    if isInvis or (os.clock() < drinkBoostEndTime) then
        baseSpeed = SETTINGS.BoostSpeed
    end
    Humanoid.WalkSpeed = baseSpeed
    
    local baseJump = SETTINGS.JumpPower
    if os.clock() < drinkBoostEndTime then
        baseJump = SETTINGS.JumpPower + SETTINGS.BoostJump
    end
    Humanoid.JumpPower = baseJump
end

local function updateFOV()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    if os.clock() < drinkBoostEndTime then
        cam.FieldOfView = SETTINGS.BoostFOV
    else
        cam.FieldOfView = originalFOV
    end
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
            Sit  = ID_CONFIG.Sit,
            Fall = ID_CONFIG.Fall
        }

        if SETTINGS.LieEnabled then
            ids.Idle = ID_CONFIG.Lie
        elseif SETTINGS.CrouchEnabled then
            ids.Idle = ID_CONFIG.CrouchIdle
            ids.Walk = ID_CONFIG.CrouchWalk
            ids.Run  = ID_CONFIG.CrouchWalk
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

local bloxyColaTool = nil

local function createBloxyColaTool()
    if Player.Backpack:FindFirstChild("Bloxy Cola") then return end

    bloxyColaTool = Instance.new("Tool")
    bloxyColaTool.Name = "Bloxy Cola"
    bloxyColaTool.RequiresHandle = true
    bloxyColaTool.CanBeDropped = false
    bloxyColaTool.Parent = Player.Backpack

    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(1, 1, 1)
    handle.BrickColor = BrickColor.new("Really red")
    handle.Material = Enum.Material.SmoothPlastic
    handle.Parent = bloxyColaTool

    local mesh = Instance.new("SpecialMesh")
    mesh.MeshId = "rbxassetid://10470609"
    mesh.TextureId = "rbxassetid://10470600"
    mesh.Scale = Vector3.new(1.1, 1.1, 1.1)
    mesh.Parent = handle

    bloxyColaTool.Activated:Connect(function()
        if isDrinking or (os.clock() < drinkBoostEndTime) or not Humanoid or not Character then return end
        
        isDrinking = true
        updateMovementStats()

        stopAllTracks(0.2)
        SOUNDS.Drink:Play()

        local drinkAnim = Instance.new("Animation")
        drinkAnim.AnimationId = ID_CONFIG.Drink
        local drinkTrack = Humanoid:LoadAnimation(drinkAnim)
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

local function onCharacterAdded(char)
    cleanup()
    Character = char
    Humanoid = char:WaitForChild("Humanoid")

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

    local jumpRunning = Instance.new("Animation") jumpRunning.AnimationId = ID_CONFIG.JumpRunning
    local jumpStanding = Instance.new("Animation") jumpStanding.AnimationId = ID_CONFIG.JumpStanding

    if jumpingConnection then jumpingConnection:Disconnect() end
    jumpingConnection = Humanoid.Jumping:Connect(function()
        if not SETTINGS.Enabled or SETTINGS.LieEnabled or isSitting then return end
        local root = Character:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local speed = Vector3.new(root.Velocity.X, 0, root.Velocity.Z).Magnitude
        local anim = speed >= 8 and jumpRunning or jumpStanding

        if activeJumpTrack and activeJumpTrack.IsPlaying then activeJumpTrack:Stop(0.2) end
        activeJumpTrack = Humanoid:LoadAnimation(anim)
        activeJumpTrack.Looped = false
        activeJumpTrack.Priority = Enum.AnimationPriority.Movement
        activeJumpTrack:Play(0.3)

        activeJumpTrack.Stopped:Once(function() activeJumpTrack = nil end)
    end)

    if footprintConnection then footprintConnection:Disconnect() end
    footprintConnection = RunService.Heartbeat:Connect(function()
        if not Character or not Humanoid or isDrinking or isSitting or SETTINGS.LieEnabled or isInvis then return end
        local root = Character:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local horizSpeed = Vector3.new(root.Velocity.X, 0, root.Velocity.Z).Magnitude
        if horizSpeed >= 15 and (os.clock() - lastFootprintTime >= SETTINGS.FootprintInterval) then
            spawnFootprint(root)
            lastFootprintTime = os.clock()
            alternateFoot = not alternateFoot
        end
    end)

    createBloxyColaTool()
end

Player.CharacterRemoving:Connect(cleanup)
Player.CharacterAdded:Connect(onCharacterAdded)
if Player.Character then onCharacterAdded(Player.Character) end

local ScreenGui = game.CoreGui:FindFirstChild("CustomAnimGui")
if ScreenGui then ScreenGui:Destroy() end

ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CustomAnimGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
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

fadeFrame = Instance.new("Frame")
fadeFrame.Name = "BoostFade"
fadeFrame.Size = UDim2.new(1, 0, 1, 0)
fadeFrame.BackgroundColor3 = Color3.fromRGB(255, 140, 30)
fadeFrame.BackgroundTransparency = 1
fadeFrame.BorderSizePixel = 0
fadeFrame.ZIndex = 999
fadeFrame.Visible = false
fadeFrame.Parent = ScreenGui

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
    if invisButton then 
        invisButton.UIStroke.Color = isInvis and Color3.fromRGB(0,200,80) or Color3.fromRGB(110,90,255)
    end
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

        local sitAnim = Instance.new("Animation")
        sitAnim.AnimationId = ID_CONFIG.Sit
        customSitTrack = Humanoid:LoadAnimation(sitAnim)
        customSitTrack.Looped = true
        customSitTrack.Priority = Enum.AnimationPriority.Core
        customSitTrack:Play(0.3)
    else
        if customSitTrack then
            pcall(function() customSitTrack:Stop(0.25) end)
            customSitTrack = nil
        end
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

createBloxyColaTool()
updateButtonVisuals()
