-- =========================================================
-- SCRIPT ATUALIZADO: Sem Custom Anims, apenas animações das tools
-- =========================================================

local ID_CONFIG = {
    Drink       = "rbxassetid://85688041753037",
    PhoneUse    = "rbxassetid://94232069437883"
}

local SETTINGS = {
    JumpPower        = 50,
    Enabled          = true,
    DrinkDuration    = 4.5,
    BoostDuration    = 15,
    BoostSpeed       = 35,
    BoostFOV         = 90,
    BoostJump        = 17,
    FootprintInterval = 0.32
}

local TOOL_IDS = {
    BloxyCola = { MeshId = "rbxassetid://10470609", TextureId = "rbxassetid://10470600", HandleColor = "Really red" },
    TzesPhone = { MeshId = "rbxassetid://130757014132786", TextureId = "rbxassetid://101684537135469", HandleColor = "Lime green" },
    Lanterna  = { MeshId = "rbxassetid://137073484684190", TextureId = "rbxassetid://120980688754080", HandleColor = "Bright yellow" },
    SprayCan  = { MeshId = "rbxassetid://102100150193796", TextureId = "5383116479", HandleColor = "Bright green" }
}

local TOOL_CONFIGS = {
    BloxyCola = { Handle = { Size = Vector3.new(1,1,1), Material = Enum.Material.SmoothPlastic, Rotation = Vector3.new(0,0,0), Position = Vector3.new(0,0,0) }, Mesh = { Scale = Vector3.new(1.1,1.1,1.1) } },
    TzesPhone = { Handle = { Size = Vector3.new(0.4,0.8,0.2), Material = Enum.Material.SmoothPlastic, Transparency = 0, Rotation = Vector3.new(0,450,0), Position = Vector3.new(0,-0.5,-0.5) }, Mesh = { Scale = Vector3.new(1,1,1) } },
    Lanterna  = { Handle = { Size = Vector3.new(0.7,1.4,0.7), Material = Enum.Material.Neon, Transparency = 0, Rotation = Vector3.new(0,0,0), Position = Vector3.new(0,0,0) }, Mesh = { Scale = Vector3.new(1,1,1) }, LanternLight = { Brightness = 4, Range = 80, Angle = 60 } },
    SprayCan = { Handle = { Size = Vector3.new(1.2,0.6,0.6), Material = Enum.Material.SmoothPlastic, Transparency = 0, Rotation = Vector3.new(0,90,0), Position = Vector3.new(0,0,-0.3) }, Mesh = { Scale = Vector3.new(1.1,1.1,1.1) }, Nozzle = { Size = Vector3.new(0.2,0.4,0.2), Position = Vector3.new(0,0,0.5) } }
}

local Player = game.Players.LocalPlayer
local Character, Humanoid, Animator
local originalWalkSpeed = 16

local isDrinking = false
local drinkBoostEndTime = 0
local originalFOV = 70

local footprintConnection = nil
local lastFootprintTime = 0
local alternateFoot = true
local fadeFrame = nil
local phoneTrack = nil
local isMusicOpen = false
local currentPaintColor = Color3.fromRGB(255, 0, 0)
local isSpraying = false
local paintSplatsFolder = nil
local sprayConnection = nil
local maxSplats = 200

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local SOUNDS = {}
local clockFrame
local timeLabel

local function loadAnim(animationId)
    if not Animator then return nil end
    local anim = Instance.new("Animation")
    anim.AnimationId = animationId
    return Animator:LoadAnimation(anim)
end

local function createSounds()
    for _, sound in pairs(Player:WaitForChild("PlayerGui"):GetChildren()) do
        if sound:IsA("Sound") and (sound.SoundId == "rbxassetid://138475744729338") then
            sound:Destroy()
        end
    end

    SOUNDS.Drink = Instance.new("Sound", Player:WaitForChild("PlayerGui"))
    SOUNDS.Drink.Name = "CustomDrinkSound"
    SOUNDS.Drink.SoundId = "rbxassetid://138475744729338"
    SOUNDS.Drink.Volume = 1.0
    SOUNDS.Drink.PlaybackSpeed = 1
    SOUNDS.Drink.Looped = false
end

createSounds()

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
    isDrinking = false
    drinkBoostEndTime = 0

    if phoneTrack then pcall(function() phoneTrack:Stop() end) phoneTrack = nil end

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
        track:Stop(fadeTime)
    end
end

local function refreshAnims(fadeTime)
    fadeTime = fadeTime or 0.25
    if not Character or not Humanoid then return end

    stopAllTracks(0)

    if phoneTrack then pcall(function() phoneTrack:Stop(0) end) phoneTrack = nil end

    local animate = Character:FindFirstChild("Animate")
    if animate then
        animate.Disabled = true
        task.wait(0.08)
        animate.Disabled = false
        task.wait(0.12)
    end
end

local function updateMovementStats()
    if not Humanoid then return end
    
    local baseSpeed = originalWalkSpeed
    if isDrinking then
        baseSpeed = originalWalkSpeed * 16
    elseif os.clock() < drinkBoostEndTime then 
        baseSpeed = SETTINGS.BoostSpeed 
    end
    
    Humanoid.WalkSpeed = baseSpeed  -- ← LINHA CRÍTICA
    
    local baseJump = SETTINGS.JumpPower
    if os.clock() < drinkBoostEndTime then 
        baseJump = SETTINGS.JumpPower + SETTINGS.BoostJump 
    end
    Humanoid.JumpPower = baseJump
end

local function updateFOV()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    cam.FieldOfView = (os.clock() < drinkBoostEndTime) and SETTINGS.BoostFOV or originalFOV
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

local function hidePhoneClock()
    if not clockFrame or not clockFrame.Visible then return end
    local offRightPosition = UDim2.new(1, clockFrame.Size.X.Offset + 30, 0, 20)
    local tween = TweenService:Create(clockFrame, TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = offRightPosition})
    tween:Play()
    tween.Completed:Once(function() clockFrame.Visible = false end)
end

-- =========================================================
-- TZE MUSIC PLAYER v4.8
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
local shuffleMode = false
local repeatMode = false
isMusicOpen = false

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 260, 0, 400)
MainFrame.Position = UDim2.new(0.5, -130, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 28)
UICorner.Parent = MainFrame

local bezelStroke = Instance.new("UIStroke")
bezelStroke.Color = Color3.fromRGB(50, 205, 50)
bezelStroke.Thickness = 6
bezelStroke.Parent = MainFrame

local earsImage = Instance.new("ImageLabel")
earsImage.Name = "EarsDecoration"
earsImage.Size = UDim2.new(0, 320, 0, 95)
earsImage.Position = UDim2.new(0.5, -160, 0, -48)
earsImage.BackgroundTransparency = 1
earsImage.Image = "rbxassetid://108135642658853"
earsImage.ImageColor3 = Color3.fromRGB(50, 205, 50)
earsImage.ZIndex = MainFrame.ZIndex + 2
earsImage.Parent = MainFrame

local notch = Instance.new("Frame")
notch.Size = UDim2.new(0, 82, 0, 24)
notch.Position = UDim2.new(0.5, -41, 0, 9)
notch.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
notch.BorderSizePixel = 0
notch.Parent = MainFrame
local notchCorner = Instance.new("UICorner", notch)
notchCorner.CornerRadius = UDim.new(1, 0)

local cameraDot = Instance.new("Frame")
cameraDot.Size = UDim2.new(0, 10, 0, 10)
cameraDot.Position = UDim2.new(0.5, -55, 0, 13)
cameraDot.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
cameraDot.BorderSizePixel = 0
cameraDot.Parent = MainFrame
local camCorner = Instance.new("UICorner", cameraDot)
camCorner.CornerRadius = UDim.new(1, 0)

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 50)
Header.BackgroundTransparency = 1
Header.Parent = MainFrame

local ModeBtn = Instance.new("TextButton")
ModeBtn.Size = UDim2.new(0, 115, 0, 30)
ModeBtn.Position = UDim2.new(1, -130, 0.5, -15)
ModeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
ModeBtn.Text = "Modo: Arquivo"
ModeBtn.TextColor3 = Color3.new(1, 1, 1)
ModeBtn.Font = Enum.Font.GothamBold
ModeBtn.TextSize = 13
ModeBtn.Parent = Header
Instance.new("UICorner", ModeBtn).CornerRadius = UDim.new(0, 12)

local TrackName = Instance.new("TextLabel")
TrackName.Size = UDim2.new(1, -30, 0, 28)
TrackName.Position = UDim2.new(0, 15, 0, 55)
TrackName.BackgroundTransparency = 1
TrackName.Text = "Nenhuma música tocando"
TrackName.TextColor3 = Color3.new(1, 1, 1)
TrackName.Font = Enum.Font.GothamBold
TrackName.TextSize = 14
TrackName.TextTruncate = Enum.TextTruncate.AtEnd
TrackName.Parent = MainFrame

local TimeBarBG = Instance.new("Frame")
TimeBarBG.Size = UDim2.new(1, -30, 0, 5)
TimeBarBG.Position = UDim2.new(0, 15, 0, 88)
TimeBarBG.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
TimeBarBG.Parent = MainFrame
local TimeBarFill = Instance.new("Frame")
TimeBarFill.Size = UDim2.new(0, 0, 1, 0)
TimeBarFill.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
TimeBarFill.BorderSizePixel = 0
TimeBarFill.Parent = TimeBarBG

local TimeLabel = Instance.new("TextLabel")
TimeLabel.Size = UDim2.new(1, 0, 0, 16)
TimeLabel.Position = UDim2.new(0, 0, 1, 2)
TimeLabel.BackgroundTransparency = 1
TimeLabel.Text = "00:00 / 00:00"
TimeLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
TimeLabel.Font = Enum.Font.Code
TimeLabel.TextSize = 11
TimeLabel.Parent = TimeBarBG

local ScrollList = Instance.new("ScrollingFrame")
ScrollList.Size = UDim2.new(1, -30, 1, -255)
ScrollList.Position = UDim2.new(0, 15, 0, 112)
ScrollList.BackgroundTransparency = 1
ScrollList.ScrollBarThickness = 4
ScrollList.Parent = MainFrame
local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 5)
UIListLayout.Parent = ScrollList

local IDInput = Instance.new("TextBox")
IDInput.Size = UDim2.new(1, -30, 0, 38)
IDInput.Position = UDim2.new(0, 15, 1, -102)
IDInput.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
IDInput.PlaceholderText = "Digite o Sound ID aqui..."
IDInput.Text = ""
IDInput.TextColor3 = Color3.new(1, 1, 1)
IDInput.Visible = false
IDInput.Parent = MainFrame
Instance.new("UICorner", IDInput).CornerRadius = UDim.new(0, 12)

local Controls = Instance.new("Frame")
Controls.Size = UDim2.new(1, 0, 0, 65)
Controls.Position = UDim2.new(0, 0, 1, -65)
Controls.BackgroundTransparency = 1
Controls.Parent = MainFrame

local function createBtn(text, pos, size)
    local btn = Instance.new("TextButton")
    btn.Size = size
    btn.Position = pos
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    btn.Text = text
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.Parent = Controls
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)
    return btn
end

local PrevBtn = createBtn("<<", UDim2.new(0.12, -20, 0.5, -18), UDim2.new(0, 42, 0, 36))
local PlayBtn = createBtn("PLAY", UDim2.new(0.5, -31, 0.5, -22), UDim2.new(0, 62, 0, 44))
local NextBtn = createBtn(">>", UDim2.new(0.88, -22, 0.5, -18), UDim2.new(0, 42, 0, 36))
local ShuffleBtn = createBtn("🔀", UDim2.new(0.04, 0, 0.5, -18), UDim2.new(0, 36, 0, 36))
local RepeatBtn = createBtn("🔁", UDim2.new(0.96, -36, 0.5, -18), UDim2.new(0, 36, 0, 36))

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

    currentSound.Ended:Connect(function()
        if not currentSound then return end
        if repeatMode then
            currentSound.TimePosition = 0
            currentSound:Play()
        elseif currentMode == "File" and #mp3List > 0 then
            local nextIdx = shuffleMode and math.random(1, #mp3List) or ((currentTrackIndex % #mp3List) + 1)
            play(getcustomasset(mp3List[nextIdx].path), mp3List[nextIdx].name, nextIdx)
        end
    end)
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
                btnFrame.Size = UDim2.new(1, 0, 0, 38)
                btnFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
                btnFrame.Parent = ScrollList
                Instance.new("UICorner", btnFrame).CornerRadius = UDim.new(0, 10)
                
                local t = Instance.new("TextButton")
                t.Size = UDim2.new(1, 0, 1, 0)
                t.BackgroundTransparency = 1
                t.Text = "  " .. name
                t.TextColor3 = Color3.new(1,1,1)
                t.TextXAlignment = Enum.TextXAlignment.Left
                t.TextSize = 13
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
        local target = UDim2.new(0.5, -130, 1, 80)
        local tween = TweenService:Create(MainFrame, TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = target})
        tween:Play()
        tween.Completed:Once(function()
            MainFrame.Visible = false
            isMusicOpen = false
            updateMovementStats()
            updatePhoneAnimation()
            refreshAnims(0.25)
        end)
    else
        MainFrame.Visible = true
        MainFrame.Position = UDim2.new(0.5, -130, 1, 80)
        local target = UDim2.new(0.5, -130, 0.5, -200)
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
        local nextIdx = shuffleMode and math.random(1, #mp3List) or ((currentTrackIndex % #mp3List) + 1)
        play(getcustomasset(mp3List[nextIdx].path), mp3List[nextIdx].name, nextIdx)
    end
end)

PrevBtn.MouseButton1Click:Connect(function()
    if currentMode == "File" and #mp3List > 0 then
        local prevIdx = shuffleMode and math.random(1, #mp3List) or (currentTrackIndex - 1)
        if prevIdx < 1 then prevIdx = #mp3List end
        play(getcustomasset(mp3List[prevIdx].path), mp3List[prevIdx].name, prevIdx)
    end
end)

ShuffleBtn.MouseButton1Click:Connect(function()
    shuffleMode = not shuffleMode
    ShuffleBtn.Text = shuffleMode and "🔀" or "➡️"
end)

RepeatBtn.MouseButton1Click:Connect(function()
    repeatMode = not repeatMode
    RepeatBtn.Text = repeatMode and "🔁" or "🔂"
end)

RunService.RenderStepped:Connect(function()
    if currentSound and (currentSound.IsPlaying or isPaused) then
        local duration = currentSound.TimeLength
        local current = currentSound.TimePosition
        if duration > 0 then
            local progress = current / duration
            TimeBarFill.Size = UDim2.new(progress, 0, 1, 0)
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
        if SOUNDS.Drink then SOUNDS.Drink:Play() end
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
            local target = UDim2.new(0.5, -130, 1, 100)
            local tweenPos = TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = target})
            tweenPos:Play()
            tweenPos.Completed:Once(function()
                MainFrame.Visible = false
                isMusicOpen = false
                updateMovementStats()
                updatePhoneAnimation()
                refreshAnims(0.25)
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

local function createSprayTool()
    local toolName = "TzeSprayCan"
    if Player.Backpack:FindFirstChild(toolName) then return end
    
    local tool = Instance.new("Tool")
    tool.Name = toolName
    tool.RequiresHandle = true
    tool.CanBeDropped = true
    tool.Parent = Player.Backpack

    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.BrickColor = BrickColor.new(TOOL_IDS.SprayCan.HandleColor)
    handle.Parent = tool
    local mesh = Instance.new("SpecialMesh")
    mesh.MeshId = TOOL_IDS.SprayCan.MeshId
    mesh.Scale = TOOL_CONFIGS.SprayCan.Mesh.Scale
    mesh.Parent = handle
    applyToolConfig(tool, toolName)

    local nozzle = Instance.new("Part")
    nozzle.Name = "Nozzle"
    nozzle.Size = TOOL_CONFIGS.SprayCan.Nozzle.Size
    nozzle.Material = Enum.Material.Neon
    nozzle.Color = Color3.fromRGB(255, 255, 255)
    nozzle.Transparency = 0.3
    nozzle.Parent = handle
    local weld = Instance.new("Weld")
    weld.Part0 = handle
    weld.Part1 = nozzle
    weld.C0 = CFrame.new(0, 0, 0.5)
    weld.Parent = handle

    local sprayParticles = Instance.new("ParticleEmitter")
    sprayParticles.Name = "SprayParticles"
    sprayParticles.Texture = "rbxassetid://241650885"
    sprayParticles.Color = ColorSequence.new(currentPaintColor)
    sprayParticles.LightEmission = 0.8
    sprayParticles.Rate = 0
    sprayParticles.Lifetime = NumberRange.new(0.3, 0.6)
    sprayParticles.Speed = NumberRange.new(60, 90)
    sprayParticles.SpreadAngle = Vector2.new(15, 15)
    sprayParticles.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0.1)})
    sprayParticles.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
    sprayParticles.Parent = nozzle

    local spraySound = Instance.new("Sound")
    spraySound.Name = "SpraySound"
    spraySound.SoundId = "rbxassetid://135953747985183"
    spraySound.Volume = 0.85
    spraySound.Looped = true
    spraySound.Parent = nozzle

    local sprayGui = nil
    local crosshair = nil
    local sprayBtn = nil
    local colorBtn = nil
    local clearBtn = nil

    tool.Equipped:Connect(function()
        sprayGui = Instance.new("ScreenGui")
        sprayGui.Name = "SprayGui"
        sprayGui.ResetOnSpawn = false
        sprayGui.Parent = Player.PlayerGui

        crosshair = Instance.new("TextLabel")
        crosshair.Size = UDim2.new(0, 42, 0, 42)
        crosshair.Position = UDim2.new(0.5, -21, 0.5, -21)
        crosshair.BackgroundTransparency = 1
        crosshair.Text = "✚"
        crosshair.TextColor3 = Color3.new(1,1,1)
        crosshair.TextSize = 42
        crosshair.Font = Enum.Font.GothamBold
        crosshair.Parent = sprayGui

        sprayBtn = Instance.new("TextButton")
        sprayBtn.Size = UDim2.new(0, 130, 0, 130)
        sprayBtn.Position = UDim2.new(0.5, 210, 0.8, -65)
        sprayBtn.BackgroundColor3 = Color3.fromRGB(255, 40, 40)
        sprayBtn.Text = "SEGURAR\nSPRAY"
        sprayBtn.TextColor3 = Color3.new(1,1,1)
        sprayBtn.Font = Enum.Font.GothamBold
        sprayBtn.TextSize = 19
        sprayBtn.Parent = sprayGui
        Instance.new("UICorner", sprayBtn).CornerRadius = UDim.new(1,0)

        colorBtn = Instance.new("TextButton")
        colorBtn.Size = UDim2.new(0, 64, 0, 64)
        colorBtn.Position = UDim2.new(0.5, 360, 0.8, -32)
        colorBtn.BackgroundColor3 = currentPaintColor
        colorBtn.Text = "🎨"
        colorBtn.TextSize = 32
        colorBtn.Parent = sprayGui
        Instance.new("UICorner", colorBtn).CornerRadius = UDim.new(1,0)

        clearBtn = Instance.new("TextButton")
        clearBtn.Size = UDim2.new(0, 64, 0, 64)
        clearBtn.Position = UDim2.new(0.5, 360, 0.8, -110)
        clearBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        clearBtn.Text = "🗑️"
        clearBtn.TextSize = 32
        clearBtn.Parent = sprayGui
        Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(1,0)

        local lastSplatTime = 0

        local function startSpraying()
            isSpraying = true
            sprayParticles.Rate = 140
            spraySound:Play()
            if sprayConnection then sprayConnection:Disconnect() end
            sprayConnection = RunService.Heartbeat:Connect(function()
                if not isSpraying or not Character then return end
                
                local now = os.clock()
                if now - lastSplatTime < 0.06 then return end
                lastSplatTime = now

                local camera = Workspace.CurrentCamera
                local ray = camera:ViewportPointToRay(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
                
                local raycastParams = RaycastParams.new()
                raycastParams.FilterDescendantsInstances = {Character}
                if paintSplatsFolder then table.insert(raycastParams.FilterDescendantsInstances, paintSplatsFolder) end
                raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                
                local result = Workspace:Raycast(ray.Origin, ray.Direction * 300, raycastParams)
                if result and result.Instance then
                    if not paintSplatsFolder then
                        paintSplatsFolder = Instance.new("Folder")
                        paintSplatsFolder.Name = "TzePaintSplats"
                        paintSplatsFolder.Parent = Workspace
                    end
                    if #paintSplatsFolder:GetChildren() > maxSplats then
                        paintSplatsFolder:GetChildren()[1]:Destroy()
                    end

                    local hitPos = result.Position + result.Normal * 0.06
                    local normal = result.Normal

                    local right = normal:Cross(Vector3.new(0,1,0))
                    if right.Magnitude < 0.01 then right = normal:Cross(Vector3.new(1,0,0)) end
                    right = right.Unit

                    local splat = Instance.new("Part")
                    splat.Size = Vector3.new(0.7 + math.random(), 0.08, 0.7 + math.random())
                    splat.Color = currentPaintColor
                    splat.Material = Enum.Material.SmoothPlastic
                    splat.Anchored = true
                    splat.CanCollide = false
                    splat.CFrame = CFrame.new(hitPos) * CFrame.fromMatrix(Vector3.new(0,0,0), right, normal) * CFrame.Angles(0, math.random() * math.pi * 2, 0)
                    splat.Parent = paintSplatsFolder

                    local hitParticle = Instance.new("ParticleEmitter")
                    hitParticle.Texture = "rbxassetid://241650885"
                    hitParticle.Color = ColorSequence.new(currentPaintColor)
                    hitParticle.Lifetime = NumberRange.new(0.4, 0.8)
                    hitParticle.Rate = 35
                    hitParticle.Speed = NumberRange.new(3, 10)
                    hitParticle.Parent = splat
                    game.Debris:AddItem(hitParticle, 1)
                end
            end)
        end

        sprayBtn.MouseButton1Down:Connect(startSpraying)
        sprayBtn.MouseButton1Up:Connect(function()
            isSpraying = false
            sprayParticles.Rate = 0
            spraySound:Stop()
            if sprayConnection then sprayConnection:Disconnect() sprayConnection = nil end
        end)

        colorBtn.MouseButton1Click:Connect(function()
            local picker = Instance.new("Frame")
            picker.Size = UDim2.new(0, 280, 0, 340)
            picker.Position = UDim2.new(0.5, 260, 0.5, -170)
            picker.BackgroundColor3 = Color3.fromRGB(25,25,30)
            picker.Parent = sprayGui
            Instance.new("UICorner", picker).CornerRadius = UDim.new(0, 16)

            local title = Instance.new("TextLabel")
            title.Size = UDim2.new(1, 0, 0, 40)
            title.BackgroundTransparency = 1
            title.Text = "🎨 Escolha a Cor"
            title.TextColor3 = Color3.new(1,1,1)
            title.Font = Enum.Font.GothamBold
            title.TextSize = 18
            title.Parent = picker

            local scroll = Instance.new("ScrollingFrame")
            scroll.Size = UDim2.new(1, -20, 1, -60)
            scroll.Position = UDim2.new(0, 10, 0, 45)
            scroll.BackgroundTransparency = 1
            scroll.ScrollBarThickness = 6
            scroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
            scroll.Parent = picker

            local gridLayout = Instance.new("UIGridLayout")
            gridLayout.CellSize = UDim2.new(0, 52, 0, 52)
            gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
            gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            gridLayout.Parent = scroll

            local colors = {
                Color3.fromRGB(255,0,0), Color3.fromRGB(220,20,60), Color3.fromRGB(255,69,0),
                Color3.fromRGB(255,140,0), Color3.fromRGB(255,165,0), Color3.fromRGB(255,215,0),
                Color3.fromRGB(255,255,0), Color3.fromRGB(173,255,47), Color3.fromRGB(0,255,0),
                Color3.fromRGB(0,128,0), Color3.fromRGB(0,255,127), Color3.fromRGB(0,206,209),
                Color3.fromRGB(0,191,255), Color3.fromRGB(30,144,255), Color3.fromRGB(0,0,255),
                Color3.fromRGB(75,0,130), Color3.fromRGB(138,43,226), Color3.fromRGB(128,0,128),
                Color3.fromRGB(255,0,255), Color3.fromRGB(255,20,147), Color3.fromRGB(255,105,180),
                Color3.fromRGB(219,112,147), Color3.fromRGB(165,42,42), Color3.fromRGB(139,69,19),
                Color3.fromRGB(128,128,128), Color3.fromRGB(169,169,169), Color3.fromRGB(211,211,211),
                Color3.fromRGB(255,255,255), Color3.fromRGB(0,0,0), Color3.fromRGB(105,105,105),
                Color3.fromRGB(255,182,193), Color3.fromRGB(255,192,203), Color3.fromRGB(144,238,144)
            }

            for _, col in ipairs(colors) do
                local cBtn = Instance.new("TextButton")
                cBtn.BackgroundColor3 = col
                cBtn.Text = ""
                cBtn.Parent = scroll
                Instance.new("UICorner", cBtn).CornerRadius = UDim.new(1, 0)
                local cStroke = Instance.new("UIStroke")
                cStroke.Thickness = 3
                cStroke.Color = Color3.fromRGB(40,40,40)
                cStroke.Parent = cBtn

                cBtn.MouseButton1Click:Connect(function()
                    currentPaintColor = col
                    sprayParticles.Color = ColorSequence.new(col)
                    colorBtn.BackgroundColor3 = col
                    picker:Destroy()
                end)
            end

            local function updateCanvas()
                scroll.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 20)
            end
            gridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)
            updateCanvas()
        end)

        clearBtn.MouseButton1Click:Connect(function()
            if paintSplatsFolder then
                paintSplatsFolder:ClearAllChildren()
            end
        end)
    end)

    tool.Unequipped:Connect(function()
        isSpraying = false
        spraySound:Stop()
        if sprayConnection then sprayConnection:Disconnect() sprayConnection = nil end
        if sprayGui then sprayGui:Destroy() end
    end)
end

local function onCharacterAdded(char)
    cleanup()
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    Animator = Humanoid:WaitForChild("Animator")
    
    originalWalkSpeed = Humanoid.WalkSpeed

    removeExtraRoots()
    createSounds()
    local camera = Workspace.CurrentCamera
    if camera then originalFOV = camera.FieldOfView end

    Humanoid.JumpPower = SETTINGS.JumpPower

    if footprintConnection then footprintConnection:Disconnect() end
    footprintConnection = RunService.Heartbeat:Connect(function()
        updatePhoneAnimation()
        if not Character or not Humanoid or isDrinking or isMusicOpen then return end
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
    createSprayTool()
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

local Camera = Workspace.CurrentCamera

local blurEffect = Instance.new("BlurEffect")
blurEffect.Name = "TzeMotionBlur"
blurEffect.Size = 0
blurEffect.Parent = game.Lighting

local windAttachment = nil
local windEmitter = nil

local function createWindParticles()
    if windEmitter then return end
    windAttachment = Instance.new("Attachment")
    windAttachment.Parent = Camera
    windEmitter = Instance.new("ParticleEmitter")
    windEmitter.Name = "TzeWindParticles"
    windEmitter.Texture = "rbxassetid://241650885"
    windEmitter.Color = ColorSequence.new(Color3.fromRGB(200, 230, 255))
    windEmitter.LightEmission = 0.7
    windEmitter.Rate = 0
    windEmitter.Lifetime = NumberRange.new(0.45, 0.9)
    windEmitter.Speed = NumberRange.new(110, 160)
    windEmitter.SpreadAngle = Vector2.new(35, 35)
    windEmitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(0.4, 0.07), NumberSequenceKeypoint.new(1, 0.01)})
    windEmitter.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1)})
    windEmitter.Rotation = NumberRange.new(-120, 120)
    windEmitter.Acceleration = Vector3.new(0, -12, 0)
    windEmitter.Parent = windAttachment
end

local isSRunning = false
local lastCameraCFrame = Camera.CFrame

RunService.RenderStepped:Connect(function(dt)
    if not Camera then return end
    local currentCFrame = Camera.CFrame
    local rotDiff = lastCameraCFrame.Rotation:Inverse() * currentCFrame.Rotation
    local _, yaw, _ = rotDiff:ToEulerAnglesYXZ()
    local turnSpeed = math.abs(yaw) / dt
    if turnSpeed > 3.5 then
        blurEffect.Size = math.clamp(turnSpeed * 1.2, 0, 9)
    else
        blurEffect.Size = math.max(blurEffect.Size - 45 * dt, 0)
    end
    lastCameraCFrame = currentCFrame

    local speed = 0
    local root = Character and Character:FindFirstChild("HumanoidRootPart")
    if root then
        local vel = root.Velocity
        speed = Vector3.new(vel.X, 0, vel.Z).Magnitude
    end

    isSRunning = (speed > 18.5 and SETTINGS.Enabled and not isDrinking and not isMusicOpen)

    if isSRunning then
        if not windEmitter then createWindParticles() end
        windEmitter.Rate = 380
        local shakeIntensity = 0.045 + (speed - 20) * 0.0022
        local shakeX = math.sin(os.clock() * 28) * shakeIntensity
        local shakeY = math.sin(os.clock() * 19) * shakeIntensity * 0.7
        Camera.CFrame *= CFrame.new(shakeX, shakeY, 0)
    else
        if windEmitter then
            windEmitter.Rate = 0
        end
    end
end)

if Character then
    createWindParticles()
end
