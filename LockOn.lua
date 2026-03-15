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

local MAX_FOV       = 120
local CamSmooth     = 0.85

local accentColor   = Color3.fromRGB(0, 255, 255)  -- Ciano (muda se quiser roxo)

local lastSearchTime = 0
local SEARCH_RATE    = 0.05

-- ==================== DETECÇÃO DE DISPOSITIVO ====================
local isMobile = UserInputService.TouchEnabled

StarterGui:SetCore("SendNotification", {
    Title = "🔥 Jujutsu Shenanigans Lock On",
    Text = "💻Pc Key L\Mobile📱",
    Icon = "rbxassetid://262619584",
    Duration = 6
})

-- ==================== INDICADOR DIAMOND (IGUAL DA FOTO) ====================
local outerDiamondLines = {}
for _ = 1, 4 do
    local line = Drawing.new("Line")
    line.Thickness = 3.8
    line.Color = accentColor
    line.Transparency = 1
    line.Visible = false
    line.ZIndex = 1000
    table.insert(outerDiamondLines, line)
end

local centerDiamondLines = {}
for _ = 1, 4 do
    local line = Drawing.new("Line")
    line.Thickness = 2.2
    line.Color = accentColor
    line.Transparency = 1
    line.Visible = false
    line.ZIndex = 1001
    table.insert(centerDiamondLines, line)
end

local function updateDiamondIndicator(part)
    if not Enabled or not LockedTarget or not part then
        for _, line in ipairs(outerDiamondLines) do line.Visible = false end
        for _, line in ipairs(centerDiamondLines) do line.Visible = false end
        return
    end

    local screenPos, visible = Camera:WorldToViewportPoint(part.Position)
    if not visible then
        for _, line in ipairs(outerDiamondLines) do line.Visible = false end
        for _, line in ipairs(centerDiamondLines) do line.Visible = false end
        return
    end

    local cX = screenPos.X
    local cY = screenPos.Y

    local size = 35          -- tamanho do diamond externo
    local shorten = 0.18     -- quanto abre as pontas (0.18 = bem aberto)
    local smallSize = 5      -- diamond do centro

    local top    = Vector2.new(cX, cY - size)
    local right  = Vector2.new(cX + size, cY)
    local bottom = Vector2.new(cX, cY + size)
    local left   = Vector2.new(cX - size, cY)

    -- Linhas externas (pontas abertas)
    local vecTR = right - top
    outerDiamondLines[1].From = top + vecTR * shorten
    outerDiamondLines[1].To   = top + vecTR * (1 - shorten)

    local vecRB = bottom - right
    outerDiamondLines[2].From = right + vecRB * shorten
    outerDiamondLines[2].To   = right + vecRB * (1 - shorten)

    local vecBL = left - bottom
    outerDiamondLines[3].From = bottom + vecBL * shorten
    outerDiamondLines[3].To   = bottom + vecBL * (1 - shorten)

    local vecLT = top - left
    outerDiamondLines[4].From = left + vecLT * shorten
    outerDiamondLines[4].To   = left + vecLT * (1 - shorten)

    -- Pequeno diamond no centro (fechado)
    local sTop    = Vector2.new(cX, cY - smallSize)
    local sRight  = Vector2.new(cX + smallSize, cY)
    local sBottom = Vector2.new(cX, cY + smallSize)
    local sLeft   = Vector2.new(cX - smallSize, cY)

    centerDiamondLines[1].From = sTop    centerDiamondLines[1].To = sRight
    centerDiamondLines[2].From = sRight  centerDiamondLines[2].To = sBottom
    centerDiamondLines[3].From = sBottom centerDiamondLines[3].To = sLeft
    centerDiamondLines[4].From = sLeft   centerDiamondLines[4].To = sTop

    -- Ativa tudo
    for _, line in ipairs(outerDiamondLines) do line.Visible = true end
    for _, line in ipairs(centerDiamondLines) do line.Visible = true end
end

-- ==================== FUNÇÕES (mesmas) ====================
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
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if dist < MAX_FOV and dist < minDist then
                        minDist = dist
                        closest = part
                    end
                end
            end
        end
    end
    return closest
end

local function isValidTarget(part)
    if not part then return false end
    local char = part.Parent
    local hum = char:FindFirstChildOfClass("Humanoid")
    local plr = Players:GetPlayerFromCharacter(char)
    return plr and plr ~= LocalPlayer and hum and hum.Health > 0
end

local function forceCameraReset()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        Camera.CameraType = Enum.CameraType.Fixed
        Camera.CameraSubject = char.Humanoid
        Camera.CameraType = Enum.CameraType.Custom
    end
end

-- ==================== BOTÃO MOBILE + TECLA L (igual) ====================
local screenGui = Instance.new("ScreenGui")
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local toggleBtn = Instance.new("ImageButton")
toggleBtn.Size = UDim2.new(0, 80, 0, 80)
toggleBtn.Position = UDim2.new(1, -95, 0, 20)
toggleBtn.BackgroundTransparency = 1
toggleBtn.Image = "rbxassetid://73466246454364"
toggleBtn.ScaleType = Enum.ScaleType.Fit
toggleBtn.Visible = isMobile
toggleBtn.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = toggleBtn

if isMobile then
    toggleBtn.MouseButton1Click:Connect(function()
        Enabled = not Enabled
        LockedTarget = nil
        toggleBtn.Image = Enabled and "rbxassetid://113252099863593" or "rbxassetid://73466246454364"
    end)
end

if not isMobile then
    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.L then
            Enabled = not Enabled
            LockedTarget = nil
        end
    end)
end

-- ==================== LOOP ====================
LocalPlayer.CharacterAdded:Connect(forceCameraReset)

RunService.RenderStepped:Connect(function()
    if Enabled then
        forceCameraReset()
    end

    local now = tick()
    if now - lastSearchTime > SEARCH_RATE then
        if not isValidTarget(LockedTarget) then
            LockedTarget = findClosestTarget()
        end
        lastSearchTime = now
    end

    local targetPart = LockedTarget and getTargetPart(LockedTarget.Parent or LockedTarget) or nil

    if Enabled and targetPart then
        local root = LockedTarget.Parent:FindFirstChild("HumanoidRootPart") or targetPart
        local targetCFrame = CFrame.new(Camera.CFrame.Position, root.Position)
        Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, CamSmooth)
        updateDiamondIndicator(root)
    else
        updateDiamondIndicator(nil)
    end
end)
