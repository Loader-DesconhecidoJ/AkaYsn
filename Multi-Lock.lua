local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local Workspace     = game:GetService("Workspace")

local Camera        = Workspace.CurrentCamera
local LocalPlayer   = Players.LocalPlayer

local Enabled       = false
local TargetType    = "PLAYERS"
local Mode          = "CAMLOCK"
local BodyPart      = "CABEÇA"
local LockedTarget  = nil
local LineboxEnabled    = false
local lineboxDrawings   = {}

local FOVMax        = 110
local FOVMin        = 50
local FOV           = FOVMax
local CamSmooth     = 0.95
local MistuSmooth   = 0.98
local AimSmooth     = 0.92
local AssistStrength= 0.95

local fovCircle = Drawing.new("Circle")
fovCircle.Thickness   = 2
fovCircle.NumSides    = 64
fovCircle.Radius      = FOV
fovCircle.Filled      = false
fovCircle.Visible     = false
fovCircle.Color       = Color3.fromRGB(255, 255, 255)
fovCircle.Transparency = 1
fovCircle.ZIndex = 999

local camLockLines = {}
for _ = 1, 4 do
    local line = Drawing.new("Line")
    line.Thickness = 2
    line.Color     = Color3.fromRGB(0, 255, 255)
    line.Transparency = 1
    line.Visible   = false
    line.ZIndex = 1000
    table.insert(camLockLines, line)
end

local camLockDot = Drawing.new("Circle")
camLockDot.Thickness    = 2
camLockDot.Radius       = 4
camLockDot.Filled       = true
camLockDot.Color        = Color3.fromRGB(0, 255, 255)
camLockDot.Transparency = 1
camLockDot.Visible      = false
camLockDot.ZIndex = 1001

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

local aimLockArrow = Drawing.new("Triangle")
aimLockArrow.Color        = Color3.fromRGB(255, 0, 0)
aimLockArrow.Thickness    = 2
aimLockArrow.Transparency = 1
aimLockArrow.Visible      = false
aimLockArrow.Filled = false
aimLockArrow.ZIndex = 1002

local function updateAimLockIndicator(part)
    if not Enabled or not LockedTarget or not part then
        aimLockArrow.Visible = false
        return
    end

    local head = part.Parent and part.Parent:FindFirstChild("Head") or part
    local screenPos, visible = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 3, 0))
    if not visible then
        aimLockArrow.Visible = false
        return
    end

    local size = 15
    aimLockArrow.PointA = Vector2.new(screenPos.X, screenPos.Y)
    aimLockArrow.PointB = Vector2.new(screenPos.X - size, screenPos.Y + size)
    aimLockArrow.PointC = Vector2.new(screenPos.X + size, screenPos.Y + size)
    aimLockArrow.Visible = true
end

local function getTargetPart(character)
    if BodyPart == "CABEÇA" then
        return character:FindFirstChild("Head")
    elseif BodyPart == "PESCOÇO" then
        return character:FindFirstChild("Neck") or character:FindFirstChild("UpperTorso") or character:FindFirstChild("Head")
    elseif BodyPart == "TORSO" then
        return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart")
    elseif BodyPart == "PÉ" then
        return character:FindFirstChild("LeftFoot") or character:FindFirstChild("RightFoot") or character:FindFirstChild("LowerTorso") or character:FindFirstChild("HumanoidRootPart")
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

local function addLinebox(player)
    if player == LocalPlayer or lineboxDrawings[player] then return end
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
    lineboxDrawings[player] = {boxLines = boxLines, tracer = tracer}
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
mainFrame.Size = UDim2.new(0, 180, 0, 52)
mainFrame.Position = UDim2.new(0.5, -90, 0.65, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(8, 3, 28)
mainFrame.BackgroundTransparency = 0.25
mainFrame.BorderSizePixel = 0
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 14)

local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Color = Color3.fromRGB(0, 255, 255)
mainStroke.Thickness = 3
mainStroke.Transparency = 0.05
mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local function createSideButton(text, yOffset)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 38, 0, 14)
    btn.Position = UDim2.new(0, 6, 0, yOffset)
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.TextColor3 = Color3.fromRGB(0, 255, 255)
    btn.BackgroundColor3 = Color3.fromRGB(15, 5, 35)
    btn.BackgroundTransparency = 0.3
    btn.BorderSizePixel = 0
    btn.Parent = mainFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = Color3.fromRGB(0, 255, 255)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.2
    return btn
end

local playerBtn   = createSideButton("P", 4)
local modeBtn     = createSideButton("CAM", 18)
local partBtn     = createSideButton("PART", 32)

local toggleBtn = Instance.new("TextButton", mainFrame)
toggleBtn.Size = UDim2.new(0, 110, 0, 34)
toggleBtn.Position = UDim2.new(0.5, -35, 0.5, -17)
toggleBtn.Text = "TOGGLE OFF"
toggleBtn.Font = Enum.Font.GothamMedium
toggleBtn.TextSize = 14
toggleBtn.TextColor3 = Color3.fromRGB(0, 255, 255)
toggleBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 50)
toggleBtn.BackgroundTransparency = 0.2
toggleBtn.BorderSizePixel = 0
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 12)

local toggleStroke = Instance.new("UIStroke", toggleBtn)
toggleStroke.Color = Color3.fromRGB(0, 255, 255)
toggleStroke.Thickness = 2.5
toggleStroke.Transparency = 0.1

local dragButton = Instance.new("TextButton", screenGui)
dragButton.Size = UDim2.new(0, 32, 0, 20)
dragButton.Text = "🔄"
dragButton.Font = Enum.Font.GothamBold
dragButton.TextSize = 14
dragButton.TextColor3 = Color3.fromRGB(0, 255, 255)
dragButton.BackgroundColor3 = Color3.fromRGB(15, 5, 35)
dragButton.BackgroundTransparency = 0.4
dragButton.BorderSizePixel = 0
Instance.new("UICorner", dragButton).CornerRadius = UDim.new(0, 8)

local lineboxBtn = Instance.new("TextButton", screenGui)
lineboxBtn.Size = UDim2.new(0, 32, 0, 20)
lineboxBtn.Text = "LB"
lineboxBtn.Font = Enum.Font.GothamBold
lineboxBtn.TextSize = 14
lineboxBtn.TextColor3 = Color3.fromRGB(0, 255, 255)
lineboxBtn.BackgroundColor3 = Color3.fromRGB(15, 5, 35)
lineboxBtn.BackgroundTransparency = 0.4
lineboxBtn.BorderSizePixel = 0
Instance.new("UICorner", lineboxBtn).CornerRadius = UDim.new(0, 8)
lineboxBtn.Visible = false

local partMenu = Instance.new("Frame", screenGui)
partMenu.Size = UDim2.new(0, 110, 0, 88)
partMenu.BackgroundColor3 = Color3.fromRGB(8, 3, 28)
partMenu.BackgroundTransparency = 0.25
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
    btn.TextColor3 = Color3.fromRGB(0, 255, 255)
    btn.BackgroundColor3 = Color3.fromRGB(15, 5, 35)
    btn.BackgroundTransparency = 0.3
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = Color3.fromRGB(0, 255, 255)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.2
    return btn
end

local headOption  = createPartOption("CABEÇA", 4)
local neckOption  = createPartOption("PESCOÇO", 24)
local torsoOption = createPartOption("TORSO", 44)
local peOption    = createPartOption("PÉ", 64)

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

partBtn.MouseButton1Click:Connect(function() partMenu.Visible = not partMenu.Visible end)
headOption.MouseButton1Click:Connect(function() BodyPart = "CABEÇA" partMenu.Visible = false end)
neckOption.MouseButton1Click:Connect(function() BodyPart = "PESCOÇO" partMenu.Visible = false end)
torsoOption.MouseButton1Click:Connect(function() BodyPart = "TORSO" partMenu.Visible = false end)
peOption.MouseButton1Click:Connect(function() BodyPart = "PÉ" partMenu.Visible = false end)
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

RunService.RenderStepped:Connect(function()
    if Enabled and (Mode == "CAMLOCK" or Mode == "Mistu") then
        forceInstantReset()
    end

    toggleBtn.BackgroundColor3 = Enabled and Color3.fromRGB(0, 255, 255) or Color3.fromRGB(20, 20, 50)
    toggleBtn.TextColor3 = Enabled and Color3.fromRGB(5, 5, 15) or Color3.fromRGB(0, 255, 255)

    dragButton.Position = UDim2.fromOffset(mainFrame.AbsolutePosition.X + mainFrame.AbsoluteSize.X / 2 - 16, mainFrame.AbsolutePosition.Y + mainFrame.AbsoluteSize.Y + 6)
    lineboxBtn.Position = UDim2.fromOffset(dragButton.AbsolutePosition.X - 38, dragButton.AbsolutePosition.Y)
    
    if partMenu.Visible then
        partMenu.Position = UDim2.fromOffset(mainFrame.AbsolutePosition.X, dragButton.AbsolutePosition.Y + dragButton.AbsoluteSize.Y + 4)
    end

    if Mode ~= "CAMLOCK" or not Enabled or not LockedTarget then
        for _, line in ipairs(camLockLines) do line.Visible = false end
        camLockDot.Visible = false
    end
    if Mode ~= "AIMLOCK" or not Enabled or not LockedTarget then
        aimLockArrow.Visible = false
    end

    fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    fovCircle.Visible = Enabled and Mode == "ASSIST" and not LineboxEnabled
    lineboxBtn.Visible = (Mode == "ASSIST")

    if Enabled and LineboxEnabled and Mode == "ASSIST" then
        local localHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        for player, drawings in pairs(lineboxDrawings) do
            local char = player.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                local root = char:FindFirstChild("HumanoidRootPart")
                local head = char:FindFirstChild("Head")
                if humanoid and humanoid.Health > 0 and root and head and localHrp then
                    local distance = (root.Position - localHrp.Position).Magnitude
                    local ratio = math.clamp(distance / 100, 0, 1)
                    local dynamicColor = ratio < 0.33 and Color3.fromRGB(255,0,0) or ratio < 0.66 and Color3.fromRGB(255,255,0) or Color3.fromRGB(0,255,0)

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
        for _, drawings in pairs(lineboxDrawings) do
            for _, line in ipairs(drawings.boxLines) do line.Visible = false end
            drawings.tracer.Visible = false
        end
    end

    if not Enabled then
        fovCircle.Visible = false
        return
    end

    if Mode ~= "ASSIST" then
        if not isValidLockedTarget(LockedTarget) then
            LockedTarget = findClosestTarget()
        end
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
                local ratio = math.clamp(distance / 100, 0, 1)
                FOV = FOVMax - (FOVMax - FOVMin) * ratio
                fovCircle.Radius = FOV
                fovCircle.Color = ratio < 0.33 and Color3.fromRGB(255,0,0) or ratio < 0.66 and Color3.fromRGB(255,255,0) or Color3.fromRGB(0,255,0)
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
