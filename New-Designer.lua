--// Script de Aimbot / Camlock / Assist com GUI simples (Roblox)
--// Baseado no script fornecido - Versão aprimorada

--// Serviços
local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace     = game:GetService("Workspace")

local Camera        = Workspace.CurrentCamera
local LocalPlayer   = Players.LocalPlayer

--// Estados
local Enabled       = false
local TargetType    = "PLAYERS"   -- "PLAYERS" ou "NPCS"
local Mode          = "CAMLOCK"   -- "CAMLOCK", "AIMLOCK", "ASSIST", "Mistu"
local BodyPart      = "Head"      -- "Head" ou "Torso"
local LockedTarget  = nil
local Hue           = 0

--// Configurações
local FOVMax        = 110
local FOVMin        = 50
local FOV           = FOVMax
local CamSmooth     = 0.95      -- Quanto menor, mais suave (0~1)
local MistuSmooth   = 0.98
local AimSmooth     = 0.92
local AssistStrength= 0.95

--// Função RGB para cor dinâmica no toggle
local function getRainbowColor()
    Hue = (Hue + 0.004) % 1
    return Color3.fromHSV(Hue, 1, 1)
end

--// FOV Circle
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness   = 2
fovCircle.NumSides    = 64
fovCircle.Radius      = FOV
fovCircle.Filled      = false
fovCircle.Visible     = false
fovCircle.Color       = Color3.fromRGB(255, 255, 255)
fovCircle.Transparency = 1

--// Indicadores CAMLOCK
local camLockLines = {}
for _ = 1, 4 do
    local line = Drawing.new("Line")
    line.Thickness = 2
    line.Color     = Color3.fromRGB(0, 255, 255)
    line.Transparency = 1
    line.Visible   = false
    table.insert(camLockLines, line)
end

local camLockDot = Drawing.new("Circle")
camLockDot.Thickness    = 2
camLockDot.Radius       = 4
camLockDot.Filled       = true
camLockDot.Color        = Color3.fromRGB(0, 255, 255)
camLockDot.Transparency = 1
camLockDot.Visible      = false

local function updateCamLockIndicator(part)
    if not Enabled or not LockedTarget or not part then
        for _, line in ipairs(camLockLines) do line.Visible = false end
        camLockDot.Visible = false
        return
    end

    local screenPos, visible = Camera:WorldToViewportPoint(part.Position)
    if not visible then
        for _, line in ipairs(camLockLines) do line.Visible = false end
        camLockDot.Visible = false
        return
    end

    local size = 25
    local top    = Vector2.new(screenPos.X, screenPos.Y - size)
    local right  = Vector2.new(screenPos.X + size, screenPos.Y)
    local bottom = Vector2.new(screenPos.X, screenPos.Y + size)
    local left   = Vector2.new(screenPos.X - size, screenPos.Y)

    camLockLines[1].From = top    camLockLines[1].To = right
    camLockLines[2].From = right  camLockLines[2].To = bottom
    camLockLines[3].From = bottom camLockLines[3].To = left
    camLockLines[4].From = left   camLockLines[4].To = top

    for _, line in ipairs(camLockLines) do line.Visible = true end
    
    camLockDot.Position = Vector2.new(screenPos.X, screenPos.Y)
    camLockDot.Visible = true
end

--// Indicador AIMLOCK (seta)
local aimLockArrow = Drawing.new("Triangle")
aimLockArrow.Color        = Color3.fromRGB(255, 0, 0)
aimLockArrow.Thickness    = 1
aimLockArrow.Transparency = 1
aimLockArrow.Visible      = false

local function updateAimLockIndicator(part)
    if not Enabled or not LockedTarget or not part then
        aimLockArrow.Visible = false
        return
    end

    local head = part.Parent and part.Parent:FindFirstChild("Head") or part
    local screenPos, visible = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 2, 0))
    if not visible then
        aimLockArrow.Visible = false
        return
    end

    local size = 12
    aimLockArrow.PointA = Vector2.new(screenPos.X, screenPos.Y)
    aimLockArrow.PointB = Vector2.new(screenPos.X - size, screenPos.Y + size)
    aimLockArrow.PointC = Vector2.new(screenPos.X + size, screenPos.Y + size)
    aimLockArrow.Visible = true
end

--// Utilitários
local function getTargetPart(character)
    if BodyPart == "Head" then
        return character:FindFirstChild("Head")
    elseif BodyPart == "Torso" then
        return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

local function isValidNPC(model)
    return model:IsA("Model") and model:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(model)
end

--// Wall Check (Raycast)
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

local function canSeeTarget(targetPart)
    if not LocalPlayer.Character then return false end
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
    local direction = targetPart.Position - Camera.CFrame.Position
    local result = Workspace:Raycast(Camera.CFrame.Position, direction, rayParams)
    return not result or result.Instance:IsDescendantOf(targetPart.Parent)
end

--// Encontrar alvo mais próximo no FOV
local function findClosestTarget()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local closest, minDist = nil, math.huge

    local function checkTarget(charOrModel)
        local part = getTargetPart(charOrModel)
        if not part then return end
        
        local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then return end
        
        local distance = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
        if distance < FOV and distance < minDist then
            minDist = distance
            closest = part
        end
    end

    if TargetType == "PLAYERS" then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                checkTarget(player.Character)
            end
        end
    else  -- NPCS
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if isValidNPC(obj) then
                checkTarget(obj)
            end
        end
    end

    return closest
end

--// Criação da GUI
local screenGui = Instance.new("ScreenGui")
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Frame principal
local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 180, 0, 52)
mainFrame.Position = UDim2.new(0.5, -90, 0.65, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
mainFrame.BorderSizePixel = 0
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 14)

-- Botões laterais
local function createSideButton(text, yOffset)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 38, 0, 14)
    btn.Position = UDim2.new(0, 6, 0, yOffset)
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.TextColor3 = Color3.new(1,1,1)
    btn.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
    btn.BorderSizePixel = 0
    btn.Parent = mainFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

local playerBtn   = createSideButton("P", 4)
local modeBtn     = createSideButton("CAM", 18)
local partBtn     = createSideButton("PART", 32)

-- Botão Toggle principal
local toggleBtn = Instance.new("TextButton", mainFrame)
toggleBtn.Size = UDim2.new(0, 110, 0, 34)
toggleBtn.Position = UDim2.new(0.5, -35, 0.5, -17)
toggleBtn.Text = "TOGGLE OFF"
toggleBtn.Font = Enum.Font.GothamMedium
toggleBtn.TextSize = 14
toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
toggleBtn.BorderSizePixel = 0
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 12)

-- Botão de arrastar
local dragButton = Instance.new("TextButton", screenGui)
dragButton.Size = UDim2.new(0, 32, 0, 20)
dragButton.Text = "🔄"
dragButton.Font = Enum.Font.GothamBold
dragButton.TextSize = 14
dragButton.TextColor3 = Color3.new(1,1,1)
dragButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
dragButton.BorderSizePixel = 0
Instance.new("UICorner", dragButton).CornerRadius = UDim.new(0, 8)

-- Menu de partes do corpo
local partMenu = Instance.new("Frame", screenGui)
partMenu.Size = UDim2.new(0, 110, 0, 44)
partMenu.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
partMenu.BorderSizePixel = 0
partMenu.Visible = false
Instance.new("UICorner", partMenu).CornerRadius = UDim.new(0, 8)

local function createPartOption(text, y)
    local btn = Instance.new("TextButton", partMenu)
    btn.Size = UDim2.new(1, -10, 0, 18)
    btn.Position = UDim2.new(0, 5, 0, y)
    btn.Text = text
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 11
    btn.TextColor3 = Color3.new(1,1,1)
    btn.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

local headOption = createPartOption("HEAD", 4)
local torsoOption = createPartOption("TORSO", 24)

--// Lógica dos botões
toggleBtn.MouseButton1Click:Connect(function()
    Enabled = not Enabled
    LockedTarget = nil
    toggleBtn.Text = Enabled and "TOGGLE ON" or "TOGGLE OFF"
end)

playerBtn.MouseButton1Click:Connect(function()
    TargetType = TargetType == "PLAYERS" and "NPCS" or "PLAYERS"
    playerBtn.Text = TargetType == "PLAYERS" and "P" or "N"
    LockedTarget = nil
end)

modeBtn.MouseButton1Click:Connect(function()
    if Mode == "CAMLOCK" then Mode = "AIMLOCK"
    elseif Mode == "AIMLOCK" then Mode = "ASSIST"
    elseif Mode == "ASSIST" then Mode = "Mistu"
    else Mode = "CAMLOCK" end
    
    modeBtn.Text = Mode == "CAMLOCK" and "CAM"
                      or Mode == "AIMLOCK" and "AIM"
                      or Mode == "ASSIST" and "AST"
                      or "Mst"
    LockedTarget = nil
end)

partBtn.MouseButton1Click:Connect(function()
    partMenu.Visible = not partMenu.Visible
end)

headOption.MouseButton1Click:Connect(function()
    BodyPart = "Head"
    partMenu.Visible = false
end)

torsoOption.MouseButton1Click:Connect(function()
    BodyPart = "Torso"
    partMenu.Visible = false
end)

--// Sistema de Drag
local dragging, dragStart, startPos = false, nil, nil

dragButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

dragButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        if dragging then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end
end)

--// Loop principal
RunService.RenderStepped:Connect(function()
    toggleBtn.BackgroundColor3 = getRainbowColor()

    -- Posiciona o botão de drag e menu de partes
    dragButton.Position = UDim2.fromOffset(
        mainFrame.AbsolutePosition.X + mainFrame.AbsoluteSize.X / 2 - 16,
        mainFrame.AbsolutePosition.Y + mainFrame.AbsoluteSize.Y + 6
    )
    
    if partMenu.Visible then
        partMenu.Position = UDim2.fromOffset(
            mainFrame.AbsolutePosition.X,
            dragButton.AbsolutePosition.Y + dragButton.AbsoluteSize.Y + 4
        )
    end

    -- Limpa indicadores se não estiver no modo correto
    if Mode ~= "CAMLOCK" or not Enabled or not LockedTarget then
        for _, line in ipairs(camLockLines) do line.Visible = false end
        camLockDot.Visible = false
    end
    if Mode ~= "AIMLOCK" or not Enabled or not LockedTarget then
        aimLockArrow.Visible = false
    end

    -- FOV Circle apenas no modo ASSIST
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    fovCircle.Visible = Enabled and Mode == "ASSIST"

    if not Enabled then
        fovCircle.Visible = false
        return
    end

    -- Atualiza alvo
    if Mode ~= "ASSIST" then
        if not LockedTarget or not LockedTarget.Parent or not LockedTarget.Parent.Parent then
            LockedTarget = findClosestTarget()
        end
    end

    local targetPart = LockedTarget and getTargetPart(LockedTarget.Parent or LockedTarget) or nil

    -- Modos de funcionamento
    if Mode == "CAMLOCK" and targetPart then
        local root = LockedTarget.Parent:FindFirstChild("HumanoidRootPart") or targetPart
        local targetCFrame = CFrame.new(Camera.CFrame.Position, root.Position)
        Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, CamSmooth)
        updateCamLockIndicator(root)

    elseif Mode == "AIMLOCK" and targetPart then
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local lookAt = Vector3.new(targetPart.Position.X, hrp.Position.Y, targetPart.Position.Z)
            hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(hrp.Position, lookAt), AimSmooth)
        end
        updateAimLockIndicator(targetPart)

    elseif Mode == "ASSIST" then
        local closest = findClosestTarget()
        if closest and canSeeTarget(closest) then
            local cam = Camera.CFrame
            local direction = (closest.Position - cam.Position).Unit
            Camera.CFrame = CFrame.new(cam.Position, cam.Position + cam.LookVector:Lerp(direction, AssistStrength))

            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local distance = (closest.Position - hrp.Position).Magnitude
                local ratio = math.clamp(distance / 100, 0, 1)
                FOV = FOVMax - (FOVMax - FOVMin) * ratio
                fovCircle.Radius = FOV

                if ratio < 0.33 then
                    fovCircle.Color = Color3.fromRGB(255, 0, 0)
                elseif ratio < 0.66 then
                    fovCircle.Color = Color3.fromRGB(255, 255, 0)
                else
                    fovCircle.Color = Color3.fromRGB(0, 255, 0)
                end
            end
        else
            FOV = FOVMax
            fovCircle.Radius = FOV
            fovCircle.Color = Color3.fromRGB(255, 255, 255)
        end

    elseif Mode == "Mistu" and targetPart then
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local lookAt = Vector3.new(targetPart.Position.X, hrp.Position.Y, targetPart.Position.Z)
            hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(hrp.Position, lookAt), MistuSmooth)
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, lookAt), MistuSmooth)
        end
    end
end)
