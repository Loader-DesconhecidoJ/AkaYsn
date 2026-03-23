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

local MAX_FOV       = 90
local CamSmooth     = 0.82
local MAX_DISTANCE  = 100
local SEARCH_DISTANCE = 55

local CAMERA_LEFT_OFFSET = -1.25

local lastSearchTime = 0
local SEARCH_RATE    = 0.25

StarterGui:SetCore("SendNotification", {
    Title = "Lock On",
    Text = "Lock On Test Recreation",
    Icon = "rbxassetid://82817965256191",
    Duration = 5
})

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
            forceInstantReset()
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
                            if dist < MAX_FOV and dist < minDist then
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

-- ====================== UI ======================
local screenGui = Instance.new("ScreenGui")
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local toggleBtn = Instance.new("ImageButton")
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

-- ================= INDICADOR NO TORSO =================
local billboard = Instance.new("BillboardGui")
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

local function toggleEnabled()
    Enabled = not Enabled
    
    if Enabled then
        LockedTarget = findClosestTarget()
    else
        LockedTarget = nil
        forceInstantReset()
    end
    
    if not Enabled then
        billboard.Enabled = false
    end
    
    toggleBtn.Image = Enabled and "rbxassetid://139332620449694" or "rbxassetid://110432273832755"
end

-- ================= ANIMAÇÃO DO BOTÃO + DRAG (otimizado) =================
local origSize = toggleBtn.Size
local tweenInfo = TweenInfo.new(0.09, Enum.EasingStyle.Sine)

local dragging, dragStart, startPos

local function handleInputBegan(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        TweenService:Create(toggleBtn, tweenInfo, {
            Size = UDim2.new(origSize.X.Scale, origSize.X.Offset * 0.88, origSize.Y.Scale, origSize.Y.Offset * 0.88)
        }):Play()
        
        dragging = true
        dragStart = input.Position
        startPos = toggleBtn.Position
    end
end

local function handleInputEnded(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        TweenService:Create(toggleBtn, tweenInfo, {Size = origSize}):Play()
    end
    dragging = false
end

toggleBtn.InputBegan:Connect(handleInputBegan)
toggleBtn.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        toggleBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
toggleBtn.InputEnded:Connect(handleInputEnded)

toggleBtn.MouseButton1Click:Connect(toggleEnabled)

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.L then
        toggleEnabled()
    end
end)

if LocalPlayer.Character then
    setupDeathHandler(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(function(character)
    setupDeathHandler(character)
end)

RunService.RenderStepped:Connect(function()
    if not Enabled then return end

    local now = tick()
    if now - lastSearchTime > SEARCH_RATE then
        if not isValidTarget(LockedTarget) then
            LockedTarget = findClosestTarget()
        end
        lastSearchTime = now
    end

    if LockedTarget and LockedTarget.Parent then
        forceInstantReset()

        local neckPos = getNeckPosition(LockedTarget)
        if neckPos then
            local rightVec = Camera.CFrame.RightVector
            local targetPos = neckPos - (rightVec * CAMERA_LEFT_OFFSET)

            local targetCFrame = CFrame.new(Camera.CFrame.Position, targetPos)
            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, CamSmooth)
        end
    end

    -- ================= ATUALIZA INDICADOR =================
    if LockedTarget and LockedTarget.Parent then
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
        billboard.Enabled = false
    end
end)
