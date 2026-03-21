local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local Workspace     = game:GetService("Workspace")
local TweenService  = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StarterGui    = game:GetService("StarterGui")

local Camera        = Workspace.CurrentCamera
local LocalPlayer   = Players.LocalPlayer

local Enabled       = false
local LockedTarget  = nil

local MAX_FOV       = 110
local CamSmooth     = 0.82
local MAX_DISTANCE  = 100

local accentColor   = Color3.fromRGB(0,206,209)

local lastSearchTime = 0
local SEARCH_RATE    = 0.05

-- ==================== NOTIFICAÇÃO ====================
StarterGui:SetCore("SendNotification", {
    Title = "Cam Lock",
    Text = "Lock On Test Recreation",
    Icon = "rbxassetid://6031094678",
    Duration = 5
})

-- ==================== INDICADOR CAMLOCK (SEMI-TRANSPARENTE) ====================
local camLockLines = {}
for _ = 1, 4 do
    local line = Drawing.new("Line")
    line.Thickness = 2.2
    line.Color = accentColor
    line.Transparency = 0.65
    line.Visible = false
    line.ZIndex = 1000
    table.insert(camLockLines, line)
end

local camLockCenterLines = {}
for _ = 1, 4 do
    local line = Drawing.new("Line")
    line.Thickness = 1.5
    line.Color = accentColor
    line.Transparency = 0.65
    line.Visible = false
    line.ZIndex = 1001
    table.insert(camLockCenterLines, line)
end

-- ==================== NOVAS FUNÇÕES (PESÇOÇO + MORTE) ====================
local function getTargetPart(character)
    return character and character:FindFirstChild("Head")
end

local function getNeckPosition(head)
    if not head then return nil end
    local char = head.Parent
    if not char then return nil end

    -- Tenta NeckAttachment (mais preciso)
    local neckAtt = head:FindFirstChild("NeckAttachment")
    if not neckAtt then
        local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
        if torso then
            neckAtt = torso:FindFirstChild("NeckAttachment")
        end
    end

    if neckAtt and neckAtt:IsA("Attachment") then
        return neckAtt.WorldPosition
    end

    -- Fallback seguro
    return (head.CFrame * CFrame.new(0, -0.5, 0)).Position
end

local function setupDeathHandler(character)
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.Died:Connect(function()
            Enabled = false
            LockedTarget = nil
            StarterGui:SetCore("SendNotification", {
                Title = "Cam Lock",
                Text = "Desativado automaticamente (você morreu)",
                Icon = "rbxassetid://6031094678",
                Duration = 3
            })
        end)
    end
end

-- ==================== INDICADOR (AGORA NO PESÇOÇO) ====================
local function updateCamLockIndicator(targetPart)
    if not Enabled or not targetPart then
        for _, v in ipairs(camLockLines) do v.Visible = false end
        for _, v in ipairs(camLockCenterLines) do v.Visible = false end
        return
    end

    local neckPos = getNeckPosition(targetPart)
    if not neckPos then
        for _, v in ipairs(camLockLines) do v.Visible = false end
        for _, v in ipairs(camLockCenterLines) do v.Visible = false end
        return
    end

    local screenPos, onScreen = Camera:WorldToViewportPoint(neckPos)
    if not onScreen then
        for _, v in ipairs(camLockLines) do v.Visible = false end
        for _, v in ipairs(camLockCenterLines) do v.Visible = false end
        return
    end

    local dist = (Camera.CFrame.Position - neckPos).Magnitude
    local charHeightStuds = 5.8
    local fovRad = math.rad(Camera.FieldOfView)
    local projectedHeight = (charHeightStuds / dist) * (Camera.ViewportSize.Y / (2 * math.tan(fovRad / 2)))

    local size = projectedHeight * 0.78
    size = math.max(18, math.min(130, size))

    local gap       = size * (8 / 30)
    local innerSize = size * (4 / 30)

    local cX, cY = screenPos.X, screenPos.Y

    -- Cantos externos
    camLockLines[1].From = Vector2.new(cX - size, cY)          camLockLines[1].To = Vector2.new(cX - gap, cY - size + gap)
    camLockLines[2].From = Vector2.new(cX + size, cY)          camLockLines[2].To = Vector2.new(cX + gap, cY - size + gap)
    camLockLines[3].From = Vector2.new(cX - size, cY)          camLockLines[3].To = Vector2.new(cX - gap, cY + size - gap)
    camLockLines[4].From = Vector2.new(cX + size, cY)          camLockLines[4].To = Vector2.new(cX + gap, cY + size - gap)

    -- Centro (X)
    camLockCenterLines[1].From = Vector2.new(cX, cY - innerSize)          camLockCenterLines[1].To = Vector2.new(cX + innerSize, cY)
    camLockCenterLines[2].From = Vector2.new(cX + innerSize, cY)          camLockCenterLines[2].To = Vector2.new(cX, cY + innerSize)
    camLockCenterLines[3].From = Vector2.new(cX, cY + innerSize)          camLockCenterLines[3].To = Vector2.new(cX - innerSize, cY)
    camLockCenterLines[4].From = Vector2.new(cX - innerSize, cY)          camLockCenterLines[4].To = Vector2.new(cX, cY - innerSize)

    for _, v in ipairs(camLockLines) do v.Visible = true end
    for _, v in ipairs(camLockCenterLines) do v.Visible = true end
end

-- ==================== FUNÇÕES ====================
local function findClosestTarget()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local closest, minDist = nil, math.huge

    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetPart = getTargetPart(player.Character)
            if targetPart then
                local neckPos = getNeckPosition(targetPart)
                if neckPos then
                    if myRoot and (neckPos - myRoot.Position).Magnitude > MAX_DISTANCE then
                        continue
                    end

                    local screenPos, onScreen = Camera:WorldToViewportPoint(neckPos)
                    if onScreen then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                        if dist < MAX_FOV and dist < minDist then
                            minDist = dist
                            closest = targetPart
                        end
                    end
                end
            end
        end
    end
    return closest
end

local function isValidTarget(targetPart)
    if not targetPart then return false end
    local char = targetPart.Parent
    local plr = Players:GetPlayerFromCharacter(char)
    if not plr or plr == LocalPlayer then return false end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end

    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if myRoot then
        local neckPos = getNeckPosition(targetPart)
        if neckPos and (neckPos - myRoot.Position).Magnitude > MAX_DISTANCE then
            return false
        end
    end

    return true
end

local function forceInstantReset()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        Camera.CameraType = Enum.CameraType.Fixed
        Camera.CameraSubject = char.Humanoid
        Camera.CameraType = Enum.CameraType.Custom
    end
end

-- ==================== BOTÃO + TECLA L ====================
local screenGui = Instance.new("ScreenGui")
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local toggleBtn = Instance.new("ImageButton")
toggleBtn.Size = UDim2.new(0, 85, 0, 85)
toggleBtn.Position = UDim2.new(1, -95, 0, 10)
toggleBtn.BackgroundTransparency = 1
toggleBtn.Image = "rbxassetid://73466246454364"
toggleBtn.ScaleType = Enum.ScaleType.Fit
toggleBtn.Visible = true
toggleBtn.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = toggleBtn

local function toggleEnabled()
    Enabled = not Enabled
    LockedTarget = nil
    toggleBtn.Image = Enabled and "rbxassetid://113252099863593" or "rbxassetid://73466246454364"
end

local origSize = toggleBtn.Size
local tweenInfo = TweenInfo.new(0.09, Enum.EasingStyle.Sine)

toggleBtn.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
        TweenService:Create(toggleBtn, tweenInfo, {Size = UDim2.new(origSize.X.Scale, origSize.X.Offset * 0.88, origSize.Y.Scale, origSize.Y.Offset * 0.88)}):Play()
    end
end)

toggleBtn.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
        TweenService:Create(toggleBtn, tweenInfo, {Size = origSize}):Play()
    end
end)

local dragging, dragStart, startPos
toggleBtn.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = inp.Position
        startPos = toggleBtn.Position
    end
end)

toggleBtn.InputChanged:Connect(function(inp)
    if dragging and (inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = inp.Position - dragStart
        toggleBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

toggleBtn.InputEnded:Connect(function() dragging = false end)
toggleBtn.MouseButton1Click:Connect(toggleEnabled)

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.L then
        toggleEnabled()
    end
end)

-- ==================== HANDLER DE MORTE + CHARACTER ADDED ====================
if LocalPlayer.Character then
    setupDeathHandler(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(function(character)
    forceInstantReset()
    setupDeathHandler(character)
end)

-- ==================== LOOP PRINCIPAL ====================
RunService.RenderStepped:Connect(function()
    if Enabled then
        forceInstantReset()
    end

    local now = tick()
    if now - lastSearchTime > SEARCH_RATE then
        if not isValidTarget(LockedTarget) then
            LockedTarget = findClosestTarget()
        end
        lastSearchTime = now
    end

    if Enabled and LockedTarget and LockedTarget.Parent then
        local neckPos = getNeckPosition(LockedTarget)
        if neckPos then
            local targetCFrame = CFrame.new(Camera.CFrame.Position, neckPos)
            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, CamSmooth)
            updateCamLockIndicator(LockedTarget)
        else
            updateCamLockIndicator(nil)
        end
    else
        updateCamLockIndicator(nil)
    end
end)
