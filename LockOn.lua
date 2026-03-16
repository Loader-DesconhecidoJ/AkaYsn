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
local CamSmooth     = 0.83

local accentColor   = Color3.fromRGB(0, 255, 255)  -- CIANO

local lastSearchTime = 0
local SEARCH_RATE    = 0.08

-- ==================== DETECÇÃO DE DISPOSITIVO ====================
local isMobile = UserInputService.TouchEnabled

-- Notification no início
StarterGui:SetCore("SendNotification", {
    Title = "Cam Lock",
    Text = "Dispositivo detectado: " .. (isMobile and "📱 MOBILE" or "💻 PC Press the L key"),
    Icon = "rbxassetid://6031094678",
    Duration = 5
})

-- ==================== INDICADOR CAMLOCK ====================
local camLockLines = {}
for _ = 1, 4 do
    local line = Drawing.new("Line")
    line.Thickness = 2.2
    line.Color = accentColor
    line.Transparency = 1
    line.Visible = false
    line.ZIndex = 1000
    table.insert(camLockLines, line)
end

local camLockCenterLines = {}
for _ = 1, 4 do
    local line = Drawing.new("Line")
    line.Thickness = 1.5
    line.Color = accentColor
    line.Transparency = 1
    line.Visible = false
    line.ZIndex = 1001
    table.insert(camLockCenterLines, line)
end

local function updateCamLockIndicator(part)
    if not Enabled or not LockedTarget or not part then
        for _, line in ipairs(camLockLines) do line.Visible = false end
        for _, line in ipairs(camLockCenterLines) do line.Visible = false end
        return
    end

    local screenPos, visible = Camera:WorldToViewportPoint(part.Position)
    if not visible then
        for _, line in ipairs(camLockLines) do line.Visible = false end
        for _, line in ipairs(camLockCenterLines) do line.Visible = false end
        return
    end

    local size = 30
    local gap  = 8
    local cX = screenPos.X
    local cY = screenPos.Y

    camLockLines[1].From = Vector2.new(cX - size, cY)          camLockLines[1].To = Vector2.new(cX - gap, cY - size + gap)
    camLockLines[2].From = Vector2.new(cX + size, cY)          camLockLines[2].To = Vector2.new(cX + gap, cY - size + gap)
    camLockLines[3].From = Vector2.new(cX - size, cY)          camLockLines[3].To = Vector2.new(cX - gap, cY + size - gap)
    camLockLines[4].From = Vector2.new(cX + size, cY)          camLockLines[4].To = Vector2.new(cX + gap, cY + size - gap)

    local innerSize = 4
    camLockCenterLines[1].From = Vector2.new(cX, cY - innerSize)          camLockCenterLines[1].To = Vector2.new(cX + innerSize, cY)
    camLockCenterLines[2].From = Vector2.new(cX + innerSize, cY)          camLockCenterLines[2].To = Vector2.new(cX, cY + innerSize)
    camLockCenterLines[3].From = Vector2.new(cX, cY + innerSize)          camLockCenterLines[3].To = Vector2.new(cX - innerSize, cY)
    camLockCenterLines[4].From = Vector2.new(cX - innerSize, cY)          camLockCenterLines[4].To = Vector2.new(cX, cY - innerSize)

    for _, line in ipairs(camLockLines) do line.Visible = true end
    for _, line in ipairs(camLockCenterLines) do line.Visible = true end
end

-- ==================== FUNÇÕES ====================
local function getTargetPart(character)
    return character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
end

local function findClosestTarget()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local closest, minDist = nil, math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local part = getTargetPart(player.Character)
            if part then
                local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if distance < MAX_FOV and distance < minDist then
                        minDist = distance
                        closest = part
                    end
                end
            end
        end
    end
    return closest
end

local function isValidLockedTarget(part)
    if not part then return false end
    local model = part.Parent
    local plr = Players:GetPlayerFromCharacter(model)
    return plr and plr ~= LocalPlayer and model:FindFirstChildOfClass("Humanoid") and model:FindFirstChildOfClass("Humanoid").Health > 0
end

local function forceInstantReset()
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("Humanoid") then
        Camera.CameraType = Enum.CameraType.Fixed
        Camera.CameraSubject = character.Humanoid
        Camera.CameraType = Enum.CameraType.Custom
    end
end

-- ==================== BOTÃO (SÓ APARECE NO MOBILE) ====================
local screenGui = Instance.new("ScreenGui")
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local toggleBtn = Instance.new("ImageButton")
toggleBtn.Size = UDim2.new(0, 85, 0, 85)
toggleBtn.Position = UDim2.new(1, -85, 0, 0)
toggleBtn.BackgroundTransparency = 1
toggleBtn.Image = "rbxassetid://73466246454364"  -- OFF
toggleBtn.ScaleType = Enum.ScaleType.Fit
toggleBtn.Visible = isMobile  -- ← SÓ MOSTRA NO MOBILE
toggleBtn.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = toggleBtn

-- ANIMAÇÃO DE TOQUE + DRAG (só no mobile)
if isMobile then
    local clickTweenInfo = TweenInfo.new(0.09, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    local originalSize = toggleBtn.Size

    toggleBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            TweenService:Create(toggleBtn, clickTweenInfo, {
                Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset * 0.88, originalSize.Y.Scale, originalSize.Y.Offset * 0.88)
            }):Play()
        end
    end)

    toggleBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            TweenService:Create(toggleBtn, clickTweenInfo, {Size = originalSize}):Play()
        end
    end)

    -- DRAG
    local dragging = false
    local dragStart = nil
    local startPos = nil

    toggleBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = toggleBtn.Position
        end
    end)

    toggleBtn.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            toggleBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    toggleBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- TOGGLE COM BOTÃO (mobile)
    toggleBtn.MouseButton1Click:Connect(function()
        Enabled = not Enabled
        LockedTarget = nil
        toggleBtn.Image = Enabled and "rbxassetid://113252099863593" or "rbxassetid://73466246454364"
    end)
end

-- ==================== TECLA L (só no PC) ====================
if not isMobile then
    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.L then
            Enabled = not Enabled
            LockedTarget = nil
        end
    end)
end

-- ==================== LOOP ====================
LocalPlayer.CharacterAdded:Connect(forceInstantReset)

RunService.RenderStepped:Connect(function()
    if Enabled then
        forceInstantReset()
    end

    local now = tick()
    if now - lastSearchTime > SEARCH_RATE then
        if not isValidLockedTarget(LockedTarget) then
            LockedTarget = findClosestTarget()
        end
        lastSearchTime = now
    end

    local targetPart = LockedTarget and getTargetPart(LockedTarget.Parent or LockedTarget) or nil

    if Enabled and targetPart then
        local root = LockedTarget.Parent:FindFirstChild("HumanoidRootPart") or targetPart
        local targetCFrame = CFrame.new(Camera.CFrame.Position, root.Position)
        Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, CamSmooth)
        updateCamLockIndicator(root)
    else
        updateCamLockIndicator(nil)
    end
end)
