local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local Workspace     = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local StarterGui    = game:GetService("StarterGui")
local TweenService  = game:GetService("TweenService")

local Camera        = Workspace.CurrentCamera
local LocalPlayer   = Players.LocalPlayer

local Enabled       = false
local LockedTarget  = nil
local lockMode      = 0          -- 1 = Camera | 2 = Camera+Character | 3 = Character Only

local CamSmooth     = 0.85       -- suavidade da câmera (pode deixar como está)
local CharSmooth    = 0.95      -- ← NOVO: suavidade do character (Modo 2)
                                 -- Quanto MENOR o valor → mais suave / menos agressivo
                                 -- Recomendo entre 0.25 \~ 0.40

local MAX_DISTANCE  = 100
local SEARCH_DISTANCE = 55
local CAMERA_LEFT_OFFSET = -1.27

-- ====================== DISTÂNCIA PARA TROCA SUAVE (só câmera) ======================
local FULL_NECK_DISTANCE = 22
local FULL_ROOT_DISTANCE = 7

local lastSearchTime = 0
local SEARCH_RATE    = 0.25

local screenGui = Instance.new("ScreenGui")
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local playerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Carrega o modo salvo
local savedMode = playerGui:FindFirstChild("SavedLockMode")
if savedMode then
    lockMode = savedMode.Value
end

-- ====================== FLAGS ======================
local isCameraMode   = false
local isCharacterMode = false
local showBillboard  = false

local function updateModeFlags()
    isCameraMode   = (lockMode == 1 or lockMode == 2)
    isCharacterMode = (lockMode == 2 or lockMode == 3)
    showBillboard  = (lockMode ~= 3)
end

local function getTargetPart(character)
    return character and character:FindFirstChild("Head")
end

local function getNeckPosition(head)
    if not head then return nil end
    local char = head.Parent
    if not char then return nil end

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

    return (head.CFrame * CFrame.new(0, -0.5, 0)).Position
end

local function getCameraLockPosition(targetPart)
    if not targetPart or not isCameraMode then
        return getNeckPosition(targetPart)
    end

    local char = targetPart.Parent
    if not char then return getNeckPosition(targetPart) end

    local myChar = LocalPlayer.Character
    if not myChar then return getNeckPosition(targetPart) end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return getNeckPosition(targetPart) end

    local targetRoot = char:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return getNeckPosition(targetPart) end

    local neckPos = getNeckPosition(targetPart)
    local rootPos = targetRoot.Position
    local distance = (myRoot.Position - rootPos).Magnitude

    if distance >= FULL_NECK_DISTANCE then
        return neckPos
    elseif distance <= FULL_ROOT_DISTANCE then
        return rootPos
    else
        local t = (distance - FULL_ROOT_DISTANCE) / (FULL_NECK_DISTANCE - FULL_ROOT_DISTANCE)
        return rootPos:Lerp(neckPos, t)
    end
end

local function getLockAdornee(targetChar)
    if not targetChar or not showBillboard then return nil end
    return targetChar:FindFirstChild("UpperTorso") 
        or targetChar:FindFirstChild("Torso") 
        or targetChar:FindFirstChild("HumanoidRootPart")
end

local function setupDeathHandler(character)
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.Died:Connect(function()
            Enabled = false
            LockedTarget = nil
            if isCameraMode then
                forceInstantReset()
            end
        end)
    end
end

local function findClosestTarget()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local closest, minDist = nil, math.huge

    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    local overlapParams = OverlapParams.new()
    overlapParams.FilterDescendantsInstances = {LocalPlayer.Character}
    overlapParams.FilterType = Enum.RaycastFilterType.Exclude

    local nearbyParts = Workspace:GetPartBoundsInRadius(myRoot.Position, SEARCH_DISTANCE, overlapParams)

    local checkedModels = {}

    for _, part in ipairs(nearbyParts) do
        local char = part:FindFirstAncestorWhichIsA("Model")
        if char and not checkedModels[char] and char ~= LocalPlayer.Character then
            checkedModels[char] = true

            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local targetPart = getTargetPart(char)
                if targetPart then
                    local neckPos = getNeckPosition(targetPart)
                    if neckPos then
                        local screenPos, onScreen = Camera:WorldToViewportPoint(neckPos)
                        if onScreen then
                            local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                            if dist < minDist then
                                minDist = dist
                                closest = targetPart
                            end
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
    if not char or not char:IsA("Model") then return false end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    if char == LocalPlayer.Character then return false end

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

local toggleBtn
local billboard

local function createToggleAndUI()
    updateModeFlags()

    toggleBtn = Instance.new("ImageButton")
    toggleBtn.Size = UDim2.new(0, 85, 0, 85)
    toggleBtn.Position = UDim2.new(1, -95, 0, 10)
    toggleBtn.BackgroundTransparency = 1
    toggleBtn.Image = "rbxassetid://110432273832755"
    toggleBtn.ScaleType = Enum.ScaleType.Fit
    toggleBtn.Visible = true
    toggleBtn.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = toggleBtn

    billboard = Instance.new("BillboardGui")
    billboard.Name = "LockOnIndicator"
    billboard.StudsOffset = Vector3.new(0, 0, 0)
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.Enabled = false
    billboard.Parent = screenGui

    local indImage = Instance.new("ImageLabel")
    indImage.Size = UDim2.new(1, 0, 1, 0)
    indImage.BackgroundTransparency = 1
    indImage.Image = "rbxassetid://82817965256191"
    indImage.ImageTransparency = 0.1
    indImage.ImageColor3 = Color3.fromRGB(0, 255, 255)
    indImage.Parent = billboard

    local indCorner = Instance.new("UICorner")
    indCorner.CornerRadius = UDim.new(1, 0)
    indCorner.Parent = indImage

    local dragging, dragStart, startPos

    local function handleInputBegan(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = toggleBtn.Position
        end
    end

    local function handleInputEnded(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end

    toggleBtn.InputBegan:Connect(handleInputBegan)
    toggleBtn.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - dragStart
            toggleBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    toggleBtn.InputEnded:Connect(handleInputEnded)

    local function toggleEnabled()
        Enabled = not Enabled
        if Enabled then
            LockedTarget = findClosestTarget()
        else
            LockedTarget = nil
            if isCameraMode then
                forceInstantReset()
            end
            if billboard then
                billboard.Enabled = false
            end
        end
        toggleBtn.Image = Enabled and "rbxassetid://139332620449694" or "rbxassetid://110432273832755"
    end

    toggleBtn.MouseButton1Click:Connect(toggleEnabled)

    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.L then
            toggleEnabled()
        end
    end)

    StarterGui:SetCore("SendNotification", {
        Title = "Lock On",
        Text = "Modo " .. lockMode .. " ativado (Character mais suave no Modo 2)",
        Icon = "rbxassetid://82817965256191",
        Duration = 5
    })
end

local function createLockModeMenu()
    if lockMode ~= 0 then return end

    local menuFrame = Instance.new("Frame")
    menuFrame.Name = "LockModeMenu"
    menuFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    menuFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    menuFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    menuFrame.BorderSizePixel = 0
    menuFrame.Size = UDim2.new(0, 0, 0, 0)
    menuFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 16)
    corner.Parent = menuFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 255, 255)
    stroke.Thickness = 3
    stroke.Parent = menuFrame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 50)
    title.BackgroundTransparency = 1
    title.Text = "Lock Mode"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 22
    title.Font = Enum.Font.GothamBold
    title.Parent = menuFrame

    local btn1 = Instance.new("TextButton")
    btn1.Size = UDim2.new(0.85, 0, 0, 55)
    btn1.Position = UDim2.new(0.075, 0, 0, 65)
    btn1.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    btn1.Text = "Mode 1 Camera"
    btn1.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn1.TextSize = 18
    btn1.Font = Enum.Font.GothamSemibold
    btn1.Parent = menuFrame
    local btn1Corner = Instance.new("UICorner"); btn1Corner.CornerRadius = UDim.new(0, 12); btn1Corner.Parent = btn1

    local btn2 = Instance.new("TextButton")
    btn2.Size = UDim2.new(0.85, 0, 0, 55)
    btn2.Position = UDim2.new(0.075, 0, 0, 130)
    btn2.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    btn2.Text = "Mode 2 Camera + Character"
    btn2.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn2.TextSize = 18
    btn2.Font = Enum.Font.GothamSemibold
    btn2.Parent = menuFrame
    local btn2Corner = Instance.new("UICorner"); btn2Corner.CornerRadius = UDim.new(0, 12); btn2Corner.Parent = btn2

    local btn3 = Instance.new("TextButton")
    btn3.Size = UDim2.new(0.85, 0, 0, 55)
    btn3.Position = UDim2.new(0.075, 0, 0, 195)
    btn3.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    btn3.Text = "Mode 3 Character Only"
    btn3.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn3.TextSize = 18
    btn3.Font = Enum.Font.GothamSemibold
    btn3.Parent = menuFrame
    local btn3Corner = Instance.new("UICorner"); btn3Corner.CornerRadius = UDim.new(0, 12); btn3Corner.Parent = btn3

    local tweenIn = TweenService:Create(menuFrame, TweenInfo.new(0.65, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 340, 0, 270)})
    tweenIn:Play()

    local function escolherModo(modo)
        local tweenOut = TweenService:Create(menuFrame, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)})
        tweenOut:Play()
        tweenOut.Completed:Connect(function()
            menuFrame:Destroy()
            lockMode = modo
            updateModeFlags()
            local salvar = Instance.new("IntValue")
            salvar.Name = "SavedLockMode"
            salvar.Value = modo
            salvar.Parent = playerGui
            createToggleAndUI()
        end)
    end

    btn1.MouseButton1Click:Connect(function() escolherModo(1) end)
    btn2.MouseButton1Click:Connect(function() escolherModo(2) end)
    btn3.MouseButton1Click:Connect(function() escolherModo(3) end)
end

-- ====================== INÍCIO ======================
if lockMode == 0 then
    createLockModeMenu()
else
    createToggleAndUI()
end

if LocalPlayer.Character then setupDeathHandler(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(setupDeathHandler)

RunService.RenderStepped:Connect(function()
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local isLocking = LockedTarget and LockedTarget.Parent

            if isCharacterMode then
                if isLocking then
                    humanoid.AutoRotate = false
                    local rootPart = character:FindFirstChild("HumanoidRootPart")
                    if rootPart then
                        local neckPos = getNeckPosition(LockedTarget)
                        if neckPos then
                            local direction = neckPos - rootPart.Position
                            local horizontalDir = Vector3.new(direction.X, 0, direction.Z)
                            local mag = horizontalDir.Magnitude
                            if mag > 0.1 then
                                horizontalDir = horizontalDir / mag
                                local targetCFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + horizontalDir)
                                
                                -- AQUI está a mudança: agora usa CharSmooth (muito mais suave)
                                rootPart.CFrame = rootPart.CFrame:Lerp(targetCFrame, CharSmooth)
                            end
                        end
                    end
                else
                    humanoid.AutoRotate = true
                end
            else
                humanoid.AutoRotate = true
            end
        end
    end

    if not Enabled then
        if billboard then billboard.Enabled = false end
        return
    end

    -- Atualiza alvo
    local now = tick()
    if now - lastSearchTime > SEARCH_RATE then
        if not isValidTarget(LockedTarget) then
            LockedTarget = findClosestTarget()
        end
        lastSearchTime = now
    end

    -- ====================== CÂMERA (Modos 1 e 2) ======================
    if LockedTarget and LockedTarget.Parent and isCameraMode then
        forceInstantReset()

        local lockPos = getCameraLockPosition(LockedTarget)
        if lockPos then
            local rightVec = Camera.CFrame.RightVector
            local targetPos = lockPos - (rightVec * CAMERA_LEFT_OFFSET)
            local targetCFrame = CFrame.new(Camera.CFrame.Position, targetPos)
            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, CamSmooth)
        end
    end

    -- ====================== BILLBOARD ======================
    if LockedTarget and LockedTarget.Parent and showBillboard then
        local characterTarget = LockedTarget.Parent
        local adorneePart = getLockAdornee(characterTarget)

        if adorneePart then
            billboard.Adornee = adorneePart
            billboard.Enabled = true

            local scaleFactor = 5.0
            local humanoid = characterTarget:FindFirstChildOfClass("Humanoid")
            local headPart = LockedTarget

            if humanoid and headPart and characterTarget:FindFirstChild("HumanoidRootPart") then
                local rootPart = characterTarget:FindFirstChild("HumanoidRootPart")
                local feetY = rootPart.Position.Y - humanoid.HipHeight
                local headTopY = headPart.Position.Y + (headPart.Size.Y / 2)
                scaleFactor = headTopY - feetY
            elseif adorneePart then
                scaleFactor = adorneePart.Size.Y * 2.5
            end
            scaleFactor = math.clamp(scaleFactor, 3.0, 10.0)

            local distance = (Camera.CFrame.Position - adorneePart.Position).Magnitude
            local distanceMultiplier = 1400 / (distance + 8)
            local finalSize = distanceMultiplier * scaleFactor

            billboard.Size = UDim2.new(0, finalSize, 0, finalSize)
        else
            billboard.Enabled = false
        end
    else
        if billboard then billboard.Enabled = false end
    end
end)
