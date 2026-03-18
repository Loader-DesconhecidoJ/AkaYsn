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
local CharSmooth    = 0.35   -- suavidade do boneco (pode mudar aqui)
local MAX_DISTANCE  = 100

local accentColor   = Color3.fromRGB(0, 206, 209)

local lastSearchTime = 0
local SEARCH_RATE    = 0.05

-- ==================== NOTIFICAÇÃO ====================
StarterGui:SetCore("SendNotification", {
    Title = "Cam Lock + Boneco Lock",
    Text = "Lock On Test Recreation (com boneco olhando)",
    Icon = "rbxassetid://6031094678",
    Duration = 5
})

-- ==================== INDICADOR CAMLOCK ====================
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

local function updateCamLockIndicator(rootPart)
    if not Enabled or not rootPart then
        for _, v in ipairs(camLockLines) do v.Visible = false end
        for _, v in ipairs(camLockCenterLines) do v.Visible = false end
        return
    end

    local screenPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
    if not onScreen then
        for _, v in ipairs(camLockLines) do v.Visible = false end
        for _, v in ipairs(camLockCenterLines) do v.Visible = false end
        return
    end

    local dist = (Camera.CFrame.Position - rootPart.Position).Magnitude
    local charHeightStuds = 5.8
    local fovRad = math.rad(Camera.FieldOfView)
    local projectedHeight = (charHeightStuds / dist) * (Camera.ViewportSize.Y / (2 * math.tan(fovRad / 2)))

    local size = projectedHeight * 0.78
    size = math.max(18, math.min(130, size))

    local gap       = size * (8 / 30)
    local innerSize = size * (4 / 30)

    local cX, cY = screenPos.X, screenPos.Y

    camLockLines[1].From = Vector2.new(cX - size, cY)          camLockLines[1].To = Vector2.new(cX - gap, cY - size + gap)
    camLockLines[2].From = Vector2.new(cX + size, cY)          camLockLines[2].To = Vector2.new(cX + gap, cY - size + gap)
    camLockLines[3].From = Vector2.new(cX - size, cY)          camLockLines[3].To = Vector2.new(cX - gap, cY + size - gap)
    camLockLines[4].From = Vector2.new(cX + size, cY)          camLockLines[4].To = Vector2.new(cX + gap, cY + size - gap)

    camLockCenterLines[1].From = Vector2.new(cX, cY - innerSize)          camLockCenterLines[1].To = Vector2.new(cX + innerSize, cY)
    camLockCenterLines[2].From = Vector2.new(cX + innerSize, cY)          camLockCenterLines[2].To = Vector2.new(cX, cY + innerSize)
    camLockCenterLines[3].From = Vector2.new(cX, cY + innerSize)          camLockCenterLines[3].To = Vector2.new(cX - innerSize, cY)
    camLockCenterLines[4].From = Vector2.new(cX - innerSize, cY)          camLockCenterLines[4].To = Vector2.new(cX, cY - innerSize)

    for _, v in ipairs(camLockLines) do v.Visible = true end
    for _, v in ipairs(camLockCenterLines) do v.Visible = true end
end

-- ==================== FUNÇÕES ====================
local function getRootPart(character)
    return character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head"))
end

local function findClosestTarget()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local closest, minDist = nil, math.huge

    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local myChar = LocalPlayer.Character

    for _, char in ipairs(Workspace:GetDescendants()) do
        if char:IsA("Model") 
           and char:FindFirstChildOfClass("Humanoid") 
           and char ~= myChar then

            local root = getRootPart(char)
            if root then
                local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
                if onScreen then
                    if myRoot and (root.Position - myRoot.Position).Magnitude > MAX_DISTANCE then 
                        continue 
                    end

                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if dist < MAX_FOV and dist < minDist then
                        minDist = dist
                        closest = root
                    end
                end
            end
        end
    end
    return closest
end

local function isValidTarget(rootPart)
    if not rootPart then return false end
    local char = rootPart.Parent
    if not char then return false end

    if LocalPlayer.Character and char == LocalPlayer.Character then return false end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end

    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if myRoot and (rootPart.Position - myRoot.Position).Magnitude > MAX_DISTANCE then
        return false
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

-- ==================== NOVO: CONTROLE DO BONECO (AutoRotate + olhar) ====================
local function setAutoRotate(state)
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.AutoRotate = state
        end
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
    
    if Enabled then
        lastSearchTime = 0
        setAutoRotate(false)   -- desliga AutoRotate pra boneco olhar pro alvo
    else
        setAutoRotate(true)    -- volta ao normal
    end
    
    toggleBtn.Image = Enabled and "rbxassetid://113252099863593" or "rbxassetid://73466246454364"
end

-- Animação do botão
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

-- Arrastar botão
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

-- ==================== CHARACTER ADDED ====================
LocalPlayer.CharacterAdded:Connect(function()
    if Enabled then
        forceInstantReset()
        setAutoRotate(false)
    else
        setAutoRotate(true)
    end
end)

-- ==================== LOOP PRINCIPAL (CAM + BONECO) ====================
RunService.RenderStepped:Connect(function()
    if Enabled then
        forceInstantReset()

        local now = tick()
        if now - lastSearchTime > SEARCH_RATE then
            if not isValidTarget(LockedTarget) then
                LockedTarget = findClosestTarget()
            end
            lastSearchTime = now
        end

        if LockedTarget and LockedTarget.Parent then
            local root = LockedTarget

            -- === CAMERA LOCK ===
            local targetCFrame = CFrame.new(Camera.CFrame.Position, root.Position)
            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, CamSmooth)

            -- === BONECO LOCK (olhar pro alvo) ===
            local myChar = LocalPlayer.Character
            if myChar then
                local myRoot = myChar:FindFirstChild("HumanoidRootPart")
                local hum = myChar:FindFirstChildOfClass("Humanoid")
                
                if hum then hum.AutoRotate = false end
                
                if myRoot then
                    -- Olha apenas na horizontal (não fica torto pra cima/baixo)
                    local lookPos = Vector3.new(root.Position.X, myRoot.Position.Y, root.Position.Z)
                    local bonecoCFrame = CFrame.new(myRoot.Position, lookPos)
                    myRoot.CFrame = myRoot.CFrame:Lerp(bonecoCFrame, CharSmooth)
                end
            end

            updateCamLockIndicator(root)
        else
            updateCamLockIndicator(nil)
        end
    else
        updateCamLockIndicator(nil)
    end
end)
