local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local Workspace     = game:GetService("Workspace")
local TweenService  = game:GetService("TweenService")

local Camera        = Workspace.CurrentCamera
local LocalPlayer   = Players.LocalPlayer

local Enabled       = false
local TargetType    = "PLAYERS"
local Mode          = "CAMLOCK"
local BodyPart      = "CABEÇA"
local LockedTarget  = nil
local LineboxEnabled    = false
local lineboxDrawings   = {}
local npcLineboxDrawings = {}

local FOVMax        = 110
local FOVMin        = 50
local FOV           = FOVMax
local CamSmooth     = 0.95
local MistuSmooth   = 0.98
local AimSmooth     = 0.92
local AssistStrength= 0.95

local lastSearchTime = 0
local SEARCH_RATE    = 0.08

local lastNPCUpdate  = 0
local NPC_UPDATE_RATE = 0.5

local accentColor = Color3.fromRGB(180, 20, 20)

-- ==================== ANIMAÇÕES ====================
local menuTweenInfo = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local clickTweenInfo = TweenInfo.new(0.09, Enum.EasingStyle.Sine, Enum.EasingDirection.Out) -- mais rápido

local function addClickAnimation(btn)
    if not btn then return end
    
    -- FIX DO BUG: centraliza o botão para o encolher não tirar o mouse de cima
    local originalSize = btn.Size
    local halfW = originalSize.X.Offset / 2
    local halfH = originalSize.Y.Offset / 2
    
    btn.AnchorPoint = Vector2.new(0.5, 0.5)
    btn.Position = UDim2.new(
        btn.Position.X.Scale,
        btn.Position.X.Offset + halfW,
        btn.Position.Y.Scale,
        btn.Position.Y.Offset + halfH
    )
    
    local originalPos = btn.Position -- salva posição centralizada
    
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            TweenService:Create(btn, clickTweenInfo, {
                Size = UDim2.new(
                    originalSize.X.Scale,
                    originalSize.X.Offset * 0.88,
                    originalSize.Y.Scale,
                    originalSize.Y.Offset * 0.88
                )
            }):Play()
        end
    end)
    
    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            TweenService:Create(btn, clickTweenInfo, {Size = originalSize}):Play()
        end
    end)
end
-- ===================================================

local fovOutline = Drawing.new("Circle")
fovOutline.Thickness   = 4
fovOutline.NumSides    = 100
fovOutline.Radius      = FOV
fovOutline.Filled      = false
fovOutline.Visible     = false
fovOutline.Color       = Color3.fromRGB(0, 0, 0)
fovOutline.Transparency = 0.75
fovOutline.ZIndex      = 998

local fovCircle = Drawing.new("Circle")
fovCircle.Thickness   = 2.5
fovCircle.NumSides    = 100
fovCircle.Radius      = FOV
fovCircle.Filled      = false
fovCircle.Visible     = false
fovCircle.Color       = Color3.fromRGB(255, 255, 255)
fovCircle.Transparency = 1
fovCircle.ZIndex      = 999

local fovCenterDot = Drawing.new("Circle")
fovCenterDot.Thickness    = 1
fovCenterDot.Radius       = 3.5
fovCenterDot.Filled       = true
fovCenterDot.Color        = Color3.fromRGB(255, 255, 255)
fovCenterDot.Transparency = 1
fovCenterDot.Visible      = false
fovCenterDot.ZIndex       = 1000

local cuidadoText = Drawing.new("Text")
cuidadoText.Text          = "CUIDADO"
cuidadoText.Size          = 15
cuidadoText.Font          = 2
cuidadoText.Color         = Color3.fromRGB(255, 0, 0)
cuidadoText.Transparency  = 1
cuidadoText.Outline       = true
cuidadoText.OutlineColor  = Color3.fromRGB(0, 0, 0)
cuidadoText.Center        = true
cuidadoText.Visible       = false
cuidadoText.ZIndex        = 1005

local camLockLines = {}
for _ = 1, 4 do
    local line = Drawing.new("Line")
    line.Thickness = 2.2
    line.Color     = accentColor
    line.Transparency = 1
    line.Visible   = false
    line.ZIndex    = 1000
    table.insert(camLockLines, line)
end

local camLockCenterLines = {}
for _ = 1, 4 do
    local line = Drawing.new("Line")
    line.Thickness = 1.5
    line.Color     = accentColor
    line.Transparency = 1
    line.Visible   = false
    line.ZIndex    = 1001
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

local aimLockArrowLines = {}
for _ = 1, 3 do
    local line = Drawing.new("Line")
    line.Thickness = 2.8
    line.Color     = Color3.fromRGB(255, 0, 0)
    line.Transparency = 1
    line.Visible   = false
    line.ZIndex    = 1004
    table.insert(aimLockArrowLines, line)
end

local function updateAimLockIndicator(part)
    if not Enabled or not LockedTarget or not part then
        for _, line in ipairs(aimLockArrowLines) do line.Visible = false end
        return
    end

    local head = part.Parent and part.Parent:FindFirstChild("Head") or part
    local screenPos, visible = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1.5, 0))
    if not visible then
        for _, line in ipairs(aimLockArrowLines) do line.Visible = false end
        return
    end

    local cX = screenPos.X
    local cY = screenPos.Y

    local arrowShaftY = cY - 32
    local arrowTipY   = cY - 12

    aimLockArrowLines[1].From = Vector2.new(cX, arrowShaftY)
    aimLockArrowLines[1].To   = Vector2.new(cX, arrowTipY)

    aimLockArrowLines[2].From = Vector2.new(cX, arrowTipY)
    aimLockArrowLines[2].To   = Vector2.new(cX - 9, arrowTipY - 8)

    aimLockArrowLines[3].From = Vector2.new(cX, arrowTipY)
    aimLockArrowLines[3].To   = Vector2.new(cX + 9, arrowTipY - 8)

    for _, line in ipairs(aimLockArrowLines) do line.Visible = true end
end

local function getTargetPart(character)
    if BodyPart == "CABEÇA" then 
        return character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
    elseif BodyPart == "TORSO" then 
        return character:FindFirstChild("UpperTorso") or 
               character:FindFirstChild("Torso") or 
               character:FindFirstChild("HumanoidRootPart")
    elseif BodyPart == "PÉ" then 
        return character:FindFirstChild("LeftFoot") or 
               character:FindFirstChild("RightFoot") or 
               character:FindFirstChild("Left Leg") or 
               character:FindFirstChild("Right Leg") or 
               character:FindFirstChild("LowerTorso") or 
               character:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

local function isValidNPC(model)
    return model:IsA("Model") and model:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(model)
end

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
    else
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if isValidNPC(obj) then
                checkTarget(obj)
            end
        end
    end
    return closest
end

local function isValidLockedTarget(part)
    if not part then return false end
    local model = part.Parent
    if not model then return false end
    if TargetType == "PLAYERS" then
        local plr = Players:GetPlayerFromCharacter(model)
        return plr and plr ~= LocalPlayer and model:FindFirstChildOfClass("Humanoid") and model:FindFirstChildOfClass("Humanoid").Health > 0
    else
        return isValidNPC(model) and model:FindFirstChildOfClass("Humanoid") and model:FindFirstChildOfClass("Humanoid").Health > 0
    end
end

local function createDrawings()
    local boxLines = {}
    for i = 1, 4 do
        local line = Drawing.new("Line")
        line.Thickness = 2
        line.Color = Color3.fromRGB(255, 255, 255)
        line.Visible = false
        line.ZIndex = 998
        table.insert(boxLines, line)
    end
    local tracer = Drawing.new("Line")
    tracer.Thickness = 2
    tracer.Color = Color3.fromRGB(255, 255, 255)
    tracer.Visible = false
    tracer.ZIndex = 998
    return {boxLines = boxLines, tracer = tracer}
end

local function addLinebox(player)
    if player == LocalPlayer or lineboxDrawings[player] then return end
    lineboxDrawings[player] = createDrawings()
end

local function forceInstantReset()
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("Humanoid") then
        Camera.CameraType = Enum.CameraType.Fixed
        Camera.CameraSubject = character.Humanoid
        Camera.CameraType = Enum.CameraType.Custom
    end
end

LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    local humanoid = newCharacter:WaitForChild("Humanoid")
    Camera.CameraType = Enum.CameraType.Custom
    Camera.CameraSubject = humanoid
end)

local screenGui = Instance.new("ScreenGui")
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 165, 0, 62)
mainFrame.Position = UDim2.new(0.5, -82, 0.65, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(8, 3, 28)
mainFrame.BackgroundTransparency = 0.25
mainFrame.BorderSizePixel = 0
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Color = accentColor
mainStroke.Thickness = 2.5
mainStroke.Transparency = 0.05
mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local function createSideButton(text, yOffset)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 35, 0, 16)
    btn.Position = UDim2.new(0, 5, 0, yOffset)
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.TextColor3 = accentColor
    btn.BackgroundColor3 = Color3.fromRGB(15, 5, 35)
    btn.BackgroundTransparency = 0.3
    btn.BorderSizePixel = 0
    btn.Parent = mainFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

local playerBtn   = createSideButton("P", 5)
local modeBtn     = createSideButton("CAM", 23)
local partBtn     = createSideButton("PART", 41)

local toggleBtn = Instance.new("TextButton", mainFrame)
toggleBtn.Size = UDim2.new(0, 80, 0, 28)
toggleBtn.Position = UDim2.new(0.5, -40, 0.5, -14)
toggleBtn.Text = "TOGGLE OFF"
toggleBtn.Font = Enum.Font.GothamMedium
toggleBtn.TextSize = 13
toggleBtn.TextColor3 = accentColor
toggleBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 50)
toggleBtn.BackgroundTransparency = 0.2
toggleBtn.BorderSizePixel = 0
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 10)

local dragButton = Instance.new("TextButton", mainFrame)
dragButton.Size = UDim2.new(0, 24, 0, 19)
dragButton.Position = UDim2.new(1, -29, 0, 5)
dragButton.Text = "⇄"
dragButton.Font = Enum.Font.GothamBold
dragButton.TextSize = 15
dragButton.TextColor3 = accentColor
dragButton.BackgroundColor3 = Color3.fromRGB(15, 5, 35)
dragButton.BackgroundTransparency = 0.4
dragButton.BorderSizePixel = 0
Instance.new("UICorner", dragButton).CornerRadius = UDim.new(0, 6)

local lineboxBtn = Instance.new("TextButton", mainFrame)
lineboxBtn.Size = UDim2.new(0, 24, 0, 19)
lineboxBtn.Position = UDim2.new(1, -29, 0, 27)
lineboxBtn.Text = "LB"
lineboxBtn.Font = Enum.Font.GothamBold
lineboxBtn.TextSize = 13
lineboxBtn.TextColor3 = accentColor
lineboxBtn.BackgroundColor3 = Color3.fromRGB(15, 5, 35)
lineboxBtn.BackgroundTransparency = 0.4
lineboxBtn.BorderSizePixel = 0
Instance.new("UICorner", lineboxBtn).CornerRadius = UDim.new(0, 6)
lineboxBtn.Visible = false

local partMenu = Instance.new("Frame", screenGui)
partMenu.Size = UDim2.new(0, 95, 0, 55)
partMenu.BackgroundColor3 = Color3.fromRGB(8, 3, 28)
partMenu.BackgroundTransparency = 0.25
partMenu.BorderSizePixel = 0
partMenu.Visible = false
Instance.new("UICorner", partMenu).CornerRadius = UDim.new(0, 8)

-- ==================== BORDA IGUAL AO MENU PRINCIPAL ====================
local partStroke = Instance.new("UIStroke", partMenu)
partStroke.Color = accentColor
partStroke.Thickness = 2.5
partStroke.Transparency = 0.05
partStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
-- ===================================================================

local function createPartOption(text, y)
    local btn = Instance.new("TextButton", partMenu)
    btn.Size = UDim2.new(1, -8, 0, 15)
    btn.Position = UDim2.new(0, 4, 0, y)
    btn.Text = text
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 10
    btn.TextColor3 = accentColor
    btn.BackgroundColor3 = Color3.fromRGB(15, 5, 35)
    btn.BackgroundTransparency = 0.3
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

local headOption  = createPartOption("CABEÇA", 3)
local torsoOption = createPartOption("TORSO", 19)
local peOption    = createPartOption("PÉ", 35)

for _, player in ipairs(Players:GetPlayers()) do addLinebox(player) end
Players.PlayerAdded:Connect(addLinebox)
Players.PlayerRemoving:Connect(function(player)
    if lineboxDrawings[player] then
        for _, line in ipairs(lineboxDrawings[player].boxLines) do line:Remove() end
        lineboxDrawings[player].tracer:Remove()
        lineboxDrawings[player] = nil
    end
end)

toggleBtn.MouseButton1Click:Connect(function()
    Enabled = not Enabled
    LockedTarget = nil
    if not Enabled then LineboxEnabled = false end
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
    modeBtn.Text = Mode == "CAMLOCK" and "CAM" or Mode == "AIMLOCK" and "AIM" or Mode == "ASSIST" and "AST" or "Mst"
    LockedTarget = nil
end)

local isPartMenuOpen = false
partBtn.MouseButton1Click:Connect(function()
    isPartMenuOpen = not isPartMenuOpen
    
    if isPartMenuOpen then
        partMenu.Visible = true
        partMenu.Size = UDim2.new(0, 0, 0, 0)
        TweenService:Create(partMenu, menuTweenInfo, {Size = UDim2.new(0, 95, 0, 55)}):Play()
    else
        local tween = TweenService:Create(partMenu, menuTweenInfo, {Size = UDim2.new(0, 0, 0, 0)})
        tween:Play()
        tween.Completed:Connect(function(playback)
            if playback == Enum.PlaybackState.Completed then
                partMenu.Visible = false
            end
        end)
    end
end)

headOption.MouseButton1Click:Connect(function() 
    BodyPart = "CABEÇA" 
    isPartMenuOpen = false 
    local tween = TweenService:Create(partMenu, menuTweenInfo, {Size = UDim2.new(0, 0, 0, 0)})
    tween:Play()
    tween.Completed:Connect(function() partMenu.Visible = false end)
end)

torsoOption.MouseButton1Click:Connect(function() 
    BodyPart = "TORSO" 
    isPartMenuOpen = false 
    local tween = TweenService:Create(partMenu, menuTweenInfo, {Size = UDim2.new(0, 0, 0, 0)})
    tween:Play()
    tween.Completed:Connect(function() partMenu.Visible = false end)
end)

peOption.MouseButton1Click:Connect(function() 
    BodyPart = "PÉ" 
    isPartMenuOpen = false 
    local tween = TweenService:Create(partMenu, menuTweenInfo, {Size = UDim2.new(0, 0, 0, 0)})
    tween:Play()
    tween.Completed:Connect(function() partMenu.Visible = false end)
end)

lineboxBtn.MouseButton1Click:Connect(function() LineboxEnabled = not LineboxEnabled end)

local dragging, dragStart, startPos = false, nil, nil
dragButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        local conn
        conn = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                conn:Disconnect()
            end
        end)
    end
end)
dragButton.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- ==================== APLICAR ANIMAÇÃO DE CLIQUE ====================
addClickAnimation(playerBtn)
addClickAnimation(modeBtn)
addClickAnimation(partBtn)
addClickAnimation(toggleBtn)
addClickAnimation(dragButton)
addClickAnimation(lineboxBtn)
addClickAnimation(headOption)
addClickAnimation(torsoOption)
addClickAnimation(peOption)
-- =================================================================

RunService.RenderStepped:Connect(function()
    if Enabled and (Mode == "CAMLOCK" or Mode == "Mistu") then
        forceInstantReset()
    end

    toggleBtn.BackgroundColor3 = Enabled and accentColor or Color3.fromRGB(20, 20, 50)
    toggleBtn.TextColor3 = Enabled and Color3.fromRGB(10, 10, 10) or accentColor

    if partMenu.Visible then
        partMenu.Position = UDim2.fromOffset(mainFrame.AbsolutePosition.X, mainFrame.AbsolutePosition.Y + mainFrame.AbsoluteSize.Y + 4)
    end

    if Mode ~= "CAMLOCK" or not Enabled or not LockedTarget then
        for _, line in ipairs(camLockLines) do line.Visible = false end
        for _, line in ipairs(camLockCenterLines) do line.Visible = false end
    end
    if Mode ~= "AIMLOCK" or not Enabled or not LockedTarget then
        for _, line in ipairs(aimLockArrowLines) do line.Visible = false end
    end

    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    fovCircle.Position = center
    fovOutline.Position = center
    fovCenterDot.Position = center
    fovCircle.Radius = FOV
    fovOutline.Radius = FOV + 1.8

    fovCircle.Visible   = false
    fovOutline.Visible  = false
    fovCenterDot.Visible = Enabled and Mode == "ASSIST"
    lineboxBtn.Visible = (Mode == "ASSIST")

    if Enabled and LineboxEnabled and Mode == "ASSIST" then
        local localHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not localHrp then
            for _, drawings in pairs(lineboxDrawings) do
                for _, line in ipairs(drawings.boxLines) do line.Visible = false end
                drawings.tracer.Visible = false
            end
            for _, drawings in pairs(npcLineboxDrawings) do
                for _, line in ipairs(drawings.boxLines) do line.Visible = false end
                drawings.tracer.Visible = false
            end
        else
            if TargetType == "PLAYERS" then
                for player, drawings in pairs(lineboxDrawings) do
                    local char = player.Character
                    if char then
                        local humanoid = char:FindFirstChildOfClass("Humanoid")
                        local root = char:FindFirstChild("HumanoidRootPart")
                        local head = char:FindFirstChild("Head")
                        if humanoid and humanoid.Health > 0 and root and head then
                            local distance = (root.Position - localHrp.Position).Magnitude
                            if distance > 500 then
                                for _, line in ipairs(drawings.boxLines) do line.Visible = false end
                                drawings.tracer.Visible = false
                            else
                                local ratio = math.clamp(distance / 200, 0, 1)
                                local dynamicColor = ratio < 0.25 and Color3.fromRGB(255,0,0) or ratio < 0.75 and Color3.fromRGB(255,255,0) or Color3.fromRGB(0,255,0)

                                local headPos, headOn = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                                local legPos, legOn = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
                                if headOn and legOn then
                                    local sizeY = (headPos.Y - legPos.Y) * 1.2
                                    local sizeX = sizeY / 2
                                    local posX = (headPos.X + legPos.X) / 2
                                    local posY = (headPos.Y + legPos.Y) / 2

                                    local topLeft = Vector2.new(math.floor(posX - sizeX/2), math.floor(posY - sizeY/2))
                                    local topRight = Vector2.new(math.floor(posX + sizeX/2), math.floor(posY - sizeY/2))
                                    local bottomLeft = Vector2.new(math.floor(posX - sizeX/2), math.floor(posY + sizeY/2))
                                    local bottomRight = Vector2.new(math.floor(posX + sizeX/2), math.floor(posY + sizeY/2))

                                    drawings.boxLines[1].From = topLeft; drawings.boxLines[1].To = topRight
                                    drawings.boxLines[2].From = topRight; drawings.boxLines[2].To = bottomRight
                                    drawings.boxLines[3].From = bottomRight; drawings.boxLines[3].To = bottomLeft
                                    drawings.boxLines[4].From = bottomLeft; drawings.boxLines[4].To = topLeft

                                    for _, line in ipairs(drawings.boxLines) do 
                                        line.Color = dynamicColor
                                        line.Visible = true 
                                    end

                                    drawings.tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                                    drawings.tracer.To = Vector2.new(legPos.X, legPos.Y)
                                    drawings.tracer.Color = dynamicColor
                                    drawings.tracer.Visible = true
                                else
                                    for _, line in ipairs(drawings.boxLines) do line.Visible = false end
                                    drawings.tracer.Visible = false
                                end
                            end
                        else
                            for _, line in ipairs(drawings.boxLines) do line.Visible = false end
                            drawings.tracer.Visible = false
                        end
                    else
                        for _, line in ipairs(drawings.boxLines) do line.Visible = false end
                        drawings.tracer.Visible = false
                    end
                end
            else
                local now = tick()
                if now - lastNPCUpdate > NPC_UPDATE_RATE then
                    lastNPCUpdate = now

                    for model, drawings in pairs(npcLineboxDrawings) do
                        if not model.Parent or not isValidNPC(model) then
                            for _, line in ipairs(drawings.boxLines) do line:Remove() end
                            drawings.tracer:Remove()
                            npcLineboxDrawings[model] = nil
                        else
                            local root = model:FindFirstChild("HumanoidRootPart")
                            if not root or (root.Position - localHrp.Position).Magnitude > 500 then
                                for _, line in ipairs(drawings.boxLines) do line.Visible = false end
                                drawings.tracer.Visible = false
                            end
                        end
                    end

                    for _, obj in ipairs(Workspace:GetDescendants()) do
                        if isValidNPC(obj) and not npcLineboxDrawings[obj] then
                            local root = obj:FindFirstChild("HumanoidRootPart")
                            if root and (root.Position - localHrp.Position).Magnitude <= 500 then
                                npcLineboxDrawings[obj] = createDrawings()
                            end
                        end
                    end
                end

                for model, drawings in pairs(npcLineboxDrawings) do
                    if model and model.Parent then
                        local humanoid = model:FindFirstChildOfClass("Humanoid")
                        local root = model:FindFirstChild("HumanoidRootPart")
                        local head = model:FindFirstChild("Head")
                        if humanoid and humanoid.Health > 0 and root and head then
                            local distance = (root.Position - localHrp.Position).Magnitude
                            if distance > 500 then
                                for _, line in ipairs(drawings.boxLines) do line.Visible = false end
                                drawings.tracer.Visible = false
                            else
                                local ratio = math.clamp(distance / 200, 0, 1)
                                local dynamicColor = ratio < 0.25 and Color3.fromRGB(255,0,0) or ratio < 0.75 and Color3.fromRGB(255,255,0) or Color3.fromRGB(0,255,0)

                                local headPos, headOn = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                                local legPos, legOn = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
                                if headOn and legOn then
                                    local sizeY = (headPos.Y - legPos.Y) * 1.2
                                    local sizeX = sizeY / 2
                                    local posX = (headPos.X + legPos.X) / 2
                                    local posY = (headPos.Y + legPos.Y) / 2

                                    local topLeft = Vector2.new(math.floor(posX - sizeX/2), math.floor(posY - sizeY/2))
                                    local topRight = Vector2.new(math.floor(posX + sizeX/2), math.floor(posY - sizeY/2))
                                    local bottomLeft = Vector2.new(math.floor(posX - sizeX/2), math.floor(posY + sizeY/2))
                                    local bottomRight = Vector2.new(math.floor(posX + sizeX/2), math.floor(posY + sizeY/2))

                                    drawings.boxLines[1].From = topLeft; drawings.boxLines[1].To = topRight
                                    drawings.boxLines[2].From = topRight; drawings.boxLines[2].To = bottomRight
                                    drawings.boxLines[3].From = bottomRight; drawings.boxLines[3].To = bottomLeft
                                    drawings.boxLines[4].From = bottomLeft; drawings.boxLines[4].To = topLeft

                                    for _, line in ipairs(drawings.boxLines) do 
                                        line.Color = dynamicColor
                                        line.Visible = true 
                                    end

                                    drawings.tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                                    drawings.tracer.To = Vector2.new(legPos.X, legPos.Y)
                                    drawings.tracer.Color = dynamicColor
                                    drawings.tracer.Visible = true
                                else
                                    for _, line in ipairs(drawings.boxLines) do line.Visible = false end
                                    drawings.tracer.Visible = false
                                end
                            end
                        else
                            for _, line in ipairs(drawings.boxLines) do line.Visible = false end
                            drawings.tracer.Visible = false
                        end
                    end
                end
            end
        end
    else
        for _, drawings in pairs(lineboxDrawings) do
            for _, line in ipairs(drawings.boxLines) do line.Visible = false end
            drawings.tracer.Visible = false
        end
        for _, drawings in pairs(npcLineboxDrawings) do
            for _, line in ipairs(drawings.boxLines) do line.Visible = false end
            drawings.tracer.Visible = false
        end
    end

    if not Enabled then
        fovCenterDot.Visible = false
        cuidadoText.Visible = false
        return
    end

    local now = tick()
    if now - lastSearchTime > SEARCH_RATE then
        if Mode ~= "ASSIST" then
            if not isValidLockedTarget(LockedTarget) then
                LockedTarget = findClosestTarget()
            end
        end
        lastSearchTime = now
    end

    local targetPart = LockedTarget and getTargetPart(LockedTarget.Parent or LockedTarget) or nil

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
                local ratio = math.clamp(distance / 200, 0, 1)

                local dynamicColor = ratio < 0.25 and Color3.fromRGB(255,0,0) 
                                   or ratio < 0.75 and Color3.fromRGB(255,255,0) 
                                   or Color3.fromRGB(0,255,0)
                fovCenterDot.Color = dynamicColor

                if ratio < 0.25 then
                    cuidadoText.Position = Vector2.new(center.X, center.Y + 32)
                    local blinkAlpha = (math.sin(tick() * 8) + 1) / 2
                    cuidadoText.Transparency = 0.2 + 0.8 * blinkAlpha
                    cuidadoText.Visible = true
                else
                    cuidadoText.Visible = false
                end

                FOV = FOVMax - (FOVMax - FOVMin) * ratio
            end
        else
            fovCenterDot.Color = Color3.fromRGB(255, 255, 255)
            cuidadoText.Visible = false
            FOV = FOVMax
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
