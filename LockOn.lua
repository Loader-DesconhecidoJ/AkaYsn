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
local lockMode      = 0

local CamSmooth     = 0.82
local MAX_DISTANCE  = 100
local SEARCH_DISTANCE = 55
local CAMERA_LEFT_OFFSET = -1.25

local lastSearchTime = 0
local SEARCH_RATE    = 0.25

local screenGui = Instance.new("ScreenGui")
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local playerGui = LocalPlayer:WaitForChild("PlayerGui")

local savedMode = playerGui:FindFirstChild("SavedLockMode")
if savedMode then
    lockMode = savedMode.Value
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

local function setupDeathHandler(character)
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.Died:Connect(function()
            Enabled = false
            LockedTarget = nil
            if lockMode == 1 or lockMode == 2 then
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
            if lockMode == 1 or lockMode == 2 then
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
        Text = "Lock On Test Recreation",
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

    local btn1Corner = Instance.new("UICorner")
    btn1Corner.CornerRadius = UDim.new(0, 12)
    btn1Corner.Parent = btn1

    local btn2 = Instance.new("TextButton")
    btn2.Size = UDim2.new(0.85, 0, 0, 55)
    btn2.Position = UDim2.new(0.075, 0, 0, 130)
    btn2.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    btn2.Text = "Mode 2 Camera + Character"
    btn2.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn2.TextSize = 18
    btn2.Font = Enum.Font.GothamSemibold
    btn2.Parent = menuFrame

    local btn2Corner = Instance.new("UICorner")
    btn2Corner.CornerRadius = UDim.new(0, 12)
    btn2Corner.Parent = btn2

    local btn3 = Instance.new("TextButton")
    btn3.Size = UDim2.new(0.85, 0, 0, 55)
    btn3.Position = UDim2.new(0.075, 0, 0, 195)
    btn3.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    btn3.Text = "Mode 3 Character Only"
    btn3.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn3.TextSize = 18
    btn3.Font = Enum.Font.GothamSemibold
    btn3.Parent = menuFrame

    local btn3Corner = Instance.new("UICorner")
    btn3Corner.CornerRadius = UDim.new(0, 12)
    btn3Corner.Parent = btn3

    local tweenIn = TweenService:Create(menuFrame, TweenInfo.new(0.65, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 340, 0, 270)
    })
    tweenIn:Play()

    local function escolherModo(modo)
        local tweenOut = TweenService:Create(menuFrame, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0)
        })
        tweenOut:Play()

        tweenOut.Completed:Connect(function()
            menuFrame:Destroy()

            local salvar = Instance.new("IntValue")
            salvar.Name = "SavedLockMode"
            salvar.Value = modo
            salvar.Parent = playerGui

            lockMode = modo
            createToggleAndUI()
        end)
    end

    btn1.MouseButton1Click:Connect(function() escolherModo(1) end)
    btn2.MouseButton1Click:Connect(function() escolherModo(2) end)
    btn3.MouseButton1Click:Connect(function() escolherModo(3) end)
end

if lockMode == 0 then
    createLockModeMenu()
else
    createToggleAndUI()
end

if LocalPlayer.Character then
    setupDeathHandler(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(function(character)
    setupDeathHandler(character)
end)

RunService.RenderStepped:Connect(function()
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local isLocking = LockedTarget and LockedTarget.Parent
            if lockMode == 2 or lockMode == 3 then
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
                                rootPart.CFrame = rootPart.CFrame:Lerp(targetCFrame, CamSmooth)
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

    local now = tick()
    if now - lastSearchTime > SEARCH_RATE then
        if not isValidTarget(LockedTarget) then
            LockedTarget = findClosestTarget()
        end
        lastSearchTime = now
    end

    if LockedTarget and LockedTarget.Parent and (lockMode == 1 or lockMode == 2) then
        forceInstantReset()

        local neckPos = getNeckPosition(LockedTarget)
        if neckPos then
            local rightVec = Camera.CFrame.RightVector
            local targetPos = neckPos - (rightVec * CAMERA_LEFT_OFFSET)
            local targetCFrame = CFrame.new(Camera.CFrame.Position, targetPos)
            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, CamSmooth)
        end
    end

    if LockedTarget and LockedTarget.Parent and lockMode ~= 3 then
        local character = LockedTarget.Parent
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
        
        if rootPart then
            local adorneePart = torso or rootPart
            billboard.Adornee = adorneePart
            billboard.Enabled = true
            
            local scaleFactor = 5.0
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local headPart = LockedTarget
            
            if humanoid and headPart and rootPart then
                local feetY = rootPart.Position.Y - humanoid.HipHeight
                local headTopY = headPart.Position.Y + (headPart.Size.Y / 2)
                scaleFactor = headTopY - feetY
            elseif torso then
                scaleFactor = torso.Size.Y * 2.5
            elseif rootPart then
                scaleFactor = rootPart.Size.Y * 3.0
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
