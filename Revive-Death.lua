local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local permanentAutoRespawn = false
local permanentMode = nil          -- 1 = where I died | 2 = edge/checkpoint
local lastDeathPos = nil
local edgeCheckpointPos = nil      -- checkpoint saved automatically when near an edge
local lastRespawnPos = nil         -- added for safety (was missing)

local VOID_Y_THRESHOLD = -100      -- no longer used (mode 2 decides now)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DeathRespawnGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = game:GetService("CoreGui")

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 290, 0, 255)
mainFrame.Position = UDim2.new(0, 30, 0.5, -127)
mainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = mainFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(180, 0, 0)
stroke.Thickness = 3
stroke.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 45)
title.BackgroundTransparency = 1
title.Text = "DEATH RESPAWN"
title.TextColor3 = Color3.fromRGB(200, 20, 20)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Parent = mainFrame

-- ==================== MODE SELECTOR ====================
local modeLabel = Instance.new("TextLabel")
modeLabel.Size = UDim2.new(0.9, 0, 0, 25)
modeLabel.Position = UDim2.new(0.05, 0, 0, 53)
modeLabel.BackgroundTransparency = 1
modeLabel.Text = "Choose the mode:"
modeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
modeLabel.TextScaled = true
modeLabel.Font = Enum.Font.Gotham
modeLabel.Parent = mainFrame

local mode1Btn = Instance.new("TextButton")
mode1Btn.Size = UDim2.new(0.9, 0, 0, 32)
mode1Btn.Position = UDim2.new(0.05, 0, 0, 83)
mode1Btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mode1Btn.Text = "1️⃣ Teleport to where I died"
mode1Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
mode1Btn.TextScaled = true
mode1Btn.Font = Enum.Font.Gotham
mode1Btn.Parent = mainFrame
local mode1Corner = Instance.new("UICorner", mode1Btn)

local mode2Btn = Instance.new("TextButton")
mode2Btn.Size = UDim2.new(0.9, 0, 0, 32)
mode2Btn.Position = UDim2.new(0.05, 0, 0, 120)
mode2Btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mode2Btn.Text = "2️⃣ Teleport to edge/checkpoint"
mode2Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
mode2Btn.TextScaled = true
mode2Btn.Font = Enum.Font.Gotham
mode2Btn.Parent = mainFrame
local mode2Corner = Instance.new("UICorner", mode2Btn)

local currentSelectedMode = 1

local function updateModeButtons()
    if currentSelectedMode == 1 then
        mode1Btn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
        mode2Btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    else
        mode1Btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        mode2Btn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
    end
end

mode1Btn.MouseButton1Click:Connect(function()
    currentSelectedMode = 1
    updateModeButtons()
end)

mode2Btn.MouseButton1Click:Connect(function()
    currentSelectedMode = 2
    updateModeButtons()
end)
-- ========================================================

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0.9, 0, 0, 32)
toggleBtn.Position = UDim2.new(0.05, 0, 0, 162)
toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
toggleBtn.Text = "☐ Don't show again"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.TextScaled = true
toggleBtn.Font = Enum.Font.Gotham
toggleBtn.Parent = mainFrame
local toggleCorner = Instance.new("UICorner", toggleBtn)

local confirmBtn = Instance.new("TextButton")
confirmBtn.Size = UDim2.new(0.9, 0, 0, 45)
confirmBtn.Position = UDim2.new(0.05, 0, 0, 200)
confirmBtn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
confirmBtn.Text = "✅ CONFIRM AND TELEPORT"
confirmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
confirmBtn.TextScaled = true
confirmBtn.Font = Enum.Font.GothamBold
confirmBtn.Parent = mainFrame
local confirmCorner = Instance.new("UICorner", confirmBtn)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 35, 0, 35)
closeBtn.Position = UDim2.new(1, -40, 0, 5)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 60, 60)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = mainFrame

local closeCorner = Instance.new("UICorner", closeBtn)
closeCorner.CornerRadius = UDim.new(1, 0)

local function tweenShow()
    mainFrame.Visible = true
    mainFrame.Size = UDim2.new(0, 240, 0, 210)
    mainFrame.BackgroundTransparency = 1
    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    TweenService:Create(mainFrame, tweenInfo, {Size = UDim2.new(0, 290, 0, 255), BackgroundTransparency = 0}):Play()
    updateModeButtons()
end

local function tweenHide()
    local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
    local tween = TweenService:Create(mainFrame, tweenInfo, {Size = UDim2.new(0, 240, 0, 210), BackgroundTransparency = 1})
    tween:Play()
    tween.Completed:Connect(function() mainFrame.Visible = false end)
end

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude

-- ==================== AUTO EDGE DETECTOR (saves checkpoint) ====================
local function getClosestEdgeInfo(startPos)
    if not startPos then return nil, math.huge end

    local char = player.Character
    if char then
        raycastParams.FilterDescendantsInstances = {char}
    end

    local downResult = workspace:Raycast(startPos + Vector3.new(0, 5, 0), Vector3.new(0, -100, 0), raycastParams)
    if not downResult then return nil, math.huge end

    local surfacePos = downResult.Position
    local heightOffset = startPos.Y - surfacePos.Y

    local directions = {
        Vector3.new(1, 0, 0),
        Vector3.new(-1, 0, 0),
        Vector3.new(0, 0, 1),
        Vector3.new(0, 0, -1),
        Vector3.new(1, 0, 1).Unit,
        Vector3.new(1, 0, -1).Unit,
        Vector3.new(-1, 0, 1).Unit,
        Vector3.new(-1, 0, -1).Unit,
    }

    local closestEdge = nil
    local minDistToEdge = math.huge
    local stepSize = 0.5
    local maxSearch = 50

    for _, dir in ipairs(directions) do
        local dist = 0
        local lastOnSurfacePos = surfacePos
        local foundEdge = false

        while dist < maxSearch do
            local testPos = surfacePos + dir * dist
            local testDown = workspace:Raycast(testPos + Vector3.new(0, 5, 0), Vector3.new(0, -20, 0), raycastParams)

            if not testDown then
                foundEdge = true
                break
            end

            lastOnSurfacePos = testPos
            dist += stepSize
        end

        if foundEdge then
            local edgeCandidate = lastOnSurfacePos + Vector3.new(0, heightOffset, 0)
            local distToThisEdge = (startPos - edgeCandidate).Magnitude

            if distToThisEdge < minDistToEdge then
                minDistToEdge = distToThisEdge
                closestEdge = edgeCandidate
            end
        end
    end

    if closestEdge then
        return closestEdge, minDistToEdge
    else
        return nil, math.huge
    end
end
-- =================================================================================

RunService.Heartbeat:Connect(function()
    local char = player.Character
    if char then
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            raycastParams.FilterDescendantsInstances = {char}

            local safe = false
            local checkPoints = {
                root.Position,
                root.Position + Vector3.new(3, 0, 0),
                root.Position + Vector3.new(-3, 0, 0),
                root.Position + Vector3.new(0, 0, 3),
                root.Position + Vector3.new(0, 0, -3)
            }

            for _, pos in checkPoints do
                local result = workspace:Raycast(pos, Vector3.new(0, -45, 0), raycastParams)
                if result then
                    safe = true
                    break
                end
            end

            if safe then
                -- AUTO SAVE CHECKPOINT when \~4-5 meters from an edge
                local edgePos, distToEdge = getClosestEdgeInfo(root.Position)
                if edgePos and distToEdge <= 5 then
                    edgeCheckpointPos = edgePos
                end
            end
        end
    end
end)

local function teleportToRespawnPos()
    if not lastRespawnPos then return end
    local char = player.Character
    if char then
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            root.CFrame = CFrame.new(lastRespawnPos)
            root.Velocity = Vector3.new(0, 0, 0)
        end
    end
end

local function onCharacterAdded(char)
    task.wait(0.4)
    
    if permanentAutoRespawn and permanentMode then
        -- PERMANENT MODE
        if permanentMode == 1 then
            lastRespawnPos = lastDeathPos
        else
            lastRespawnPos = edgeCheckpointPos or lastDeathPos
        end
        teleportToRespawnPos()
        return
    end

    -- Menu only appears on spawn
    tweenShow()
end

local function onDied()
    local char = player.Character
    if char then
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            lastDeathPos = root.Position
        end
    end
end

local dontShowToggle = false

toggleBtn.MouseButton1Click:Connect(function()
    dontShowToggle = not dontShowToggle
    toggleBtn.Text = dontShowToggle and "☑ Don't show again" or "☐ Don't show again"
end)

confirmBtn.MouseButton1Click:Connect(function()
    -- Set respawn location according to the selected mode
    if currentSelectedMode == 1 then
        lastRespawnPos = lastDeathPos
    else
        lastRespawnPos = edgeCheckpointPos or lastDeathPos
    end

    if dontShowToggle then
        permanentAutoRespawn = true
        permanentMode = currentSelectedMode
    end

    tweenHide()
    teleportToRespawnPos()
end)

closeBtn.MouseButton1Click:Connect(function()
    tweenHide()
end)

-- Connections
player.CharacterAdded:Connect(onCharacterAdded)

if player.Character then
    local hum = player.Character:WaitForChild("Humanoid", 10)
    if hum then
        hum.Died:Connect(onDied)
    end
end

player.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 10)
    if hum then
        hum.Died:Connect(onDied)
    end
end)
