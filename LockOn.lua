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

local CamSmooth     = 0.85       -- suavidade da câmera (padrão)
local CharSmooth    = 1          -- suavidade do character (padrão)

-- ====================== PREDICTION (NOVO) ======================
local PREDICTION_STRENGTH = 0.15  -- Força da predição (0 a 1, recomendado 0.1 - 0.2)
local lastTargetPos = nil         -- Última posição conhecida do alvo
local targetVelocity = Vector3.zero  -- Velocidade estimada do alvo

local MAX_DISTANCE  = 1000
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

-- Carrega valores salvos dos sliders
local savedCamSmooth = playerGui:FindFirstChild("SavedCamSmooth")
if savedCamSmooth then
    CamSmooth = savedCamSmooth.Value
end

local savedCharSmooth = playerGui:FindFirstChild("SavedCharSmooth")
if savedCharSmooth then
    CharSmooth = savedCharSmooth.Value
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
            lastTargetPos = nil        -- Reset prediction
            targetVelocity = Vector3.zero
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

-- ====================== FUNÇÃO DE PREDICTION (NOVO) ======================
local function updateTargetPrediction(targetPart)
    if not targetPart then
        lastTargetPos = nil
        targetVelocity = Vector3.zero
        return
    end
    
    local currentPos = getNeckPosition(targetPart)
    if not currentPos then
        lastTargetPos = nil
        targetVelocity = Vector3.zero
        return
    end
    
    if lastTargetPos then
        -- Calcula a velocidade baseado na diferença de posição
        local delta = currentPos - lastTargetPos
        
        -- Suaviza a velocidade para evitar tremores
        -- Ajuste: 0.3 = mais suave, 0.7 = mais responsivo
        targetVelocity = targetVelocity:Lerp(delta, 0.4)
    end
    
    lastTargetPos = currentPos
end

local function getPredictedPosition(targetPart)
    if not targetPart then return nil end
    
    local currentPos = getNeckPosition(targetPart)
    if not currentPos then return nil end
    
    -- Retorna posição atual + (velocidade * força de predição)
    -- Quanto maior PREDICTION_STRENGTH, mais à frente do alvo vai mirar
    return currentPos + (targetVelocity * PREDICTION_STRENGTH)
end

local toggleBtn
local billboard

-- ====================== FUNÇÃO PARA CRIAR SLIDER MINI ======================
local function createMiniSlider(parent, name, minValue, maxValue, defaultValue, yPosition, callback)
    -- Label do slider (menor)
    local sliderLabel = Instance.new("TextLabel")
    sliderLabel.Size = UDim2.new(0.85, 0, 0, 18)
    sliderLabel.Position = UDim2.new(0.075, 0, 0, yPosition)
    sliderLabel.BackgroundTransparency = 1
    sliderLabel.Text = name .. ": " .. string.format("%.2f", defaultValue)
    sliderLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    sliderLabel.TextSize = 13
    sliderLabel.Font = Enum.Font.GothamSemibold
    sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
    sliderLabel.Parent = parent

    -- Container do slider (menor)
    local sliderContainer = Instance.new("Frame")
    sliderContainer.Size = UDim2.new(0.85, 0, 0, 22)
    sliderContainer.Position = UDim2.new(0.075, 0, 0, yPosition + 20)
    sliderContainer.BackgroundTransparency = 1
    sliderContainer.Parent = parent

    -- Background do slider (mais fino)
    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, -25, 0, 5)
    sliderBg.Position = UDim2.new(0, 0, 0.5, -2)
    sliderBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    sliderBg.Parent = sliderContainer
    local bgCorner = Instance.new("UICorner"); bgCorner.CornerRadius = UDim.new(0, 3); bgCorner.Parent = sliderBg

    -- Barra preenchida
    local fillBar = Instance.new("Frame")
    local fillPercent = (defaultValue - minValue) / (maxValue - minValue)
    fillBar.Size = UDim2.new(fillPercent, 0, 1, 0)
    fillBar.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
    fillBar.Parent = sliderBg
    local fillCorner = Instance.new("UICorner"); fillCorner.CornerRadius = UDim.new(0, 3); fillCorner.Parent = fillBar

    -- Botão do slider (menor)
    local sliderBtn = Instance.new("TextButton")
    sliderBtn.Size = UDim2.new(0, 22, 0, 22)
    sliderBtn.Position = UDim2.new(fillPercent, -11, 0.5, -11)
    sliderBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
    sliderBtn.Text = ""
    sliderBtn.Parent = sliderContainer
    local btnCorner = Instance.new("UICorner"); btnCorner.CornerRadius = UDim.new(1, 0); btnCorner.Parent = sliderBtn

    -- Input do valor (menor)
    local valueInput = Instance.new("TextBox")
    valueInput.Size = UDim2.new(0, 45, 0, 20)
    valueInput.Position = UDim2.new(1, -45, 0.5, -10)
    valueInput.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    valueInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    valueInput.Text = string.format("%.2f", defaultValue)
    valueInput.TextSize = 12
    valueInput.Font = Enum.Font.GothamSemibold
    valueInput.Parent = sliderContainer
    local inputCorner = Instance.new("UICorner"); inputCorner.CornerRadius = UDim.new(0, 4); inputCorner.Parent = valueInput

    local currentValue = defaultValue

    local function updateValue(newValue)
        currentValue = math.clamp(newValue, minValue, maxValue)
        local percent = (currentValue - minValue) / (maxValue - minValue)
        
        sliderLabel.Text = name .. ": " .. string.format("%.2f", currentValue)
        valueInput.Text = string.format("%.2f", currentValue)
        fillBar.Size = UDim2.new(percent, 0, 1, 0)
        sliderBtn.Position = UDim2.new(percent, -11, 0.5, -11)
        
        if callback then
            callback(currentValue)
        end
    end

    local dragging = false

    sliderBtn.MouseButton1Down:Connect(function()
        dragging = true
    end)

    sliderBtn.MouseButton1Up:Connect(function()
        dragging = false
    end)

    sliderBtn.MouseLeave:Connect(function()
        dragging = false
    end)

    sliderContainer.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)

    sliderContainer.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    sliderContainer.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local mousePos = input.Position.X
            local sliderAbsPos = sliderBg.AbsolutePosition.X
            local sliderWidth = sliderBg.AbsoluteSize.X
            local relativeX = (mousePos - sliderAbsPos) / sliderWidth
            local newValue = minValue + (relativeX * (maxValue - minValue))
            updateValue(newValue)
        end
    end)

    valueInput.FocusLost:Connect(function(enterPressed)
        local num = tonumber(valueInput.Text)
        if num then
            updateValue(num)
        else
            valueInput.Text = string.format("%.2f", currentValue)
        end
    end)

    return updateValue, currentValue
end

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
    indImage.Image = "rbxassetid://100230908593841"
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
            lastTargetPos = nil
            targetVelocity = Vector3.zero
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
end

local function createLockModeMenu()
    if lockMode ~= 0 then return end

    local menuFrame = Instance.new("Frame")
    menuFrame.Name = "LockModeMenu"
    menuFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    menuFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    menuFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    menuFrame.BackgroundTransparency = 1
    menuFrame.BorderSizePixel = 0
    menuFrame.Size = UDim2.new(0, 0, 0, 0)
    menuFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = menuFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 255, 255)
    stroke.Thickness = 2
    stroke.Transparency = 1
    stroke.Parent = menuFrame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 35)
    title.BackgroundTransparency = 1
    title.Text = "Lock Mode"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextTransparency = 1
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.Parent = menuFrame

    local function createMiniButton(parent, text, yPos)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.85, 0, 0, 38)
        btn.Position = UDim2.new(0.075, 0, 0, yPos)
        btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        btn.BackgroundTransparency = 1
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextTransparency = 1
        btn.TextSize = 14
        btn.Font = Enum.Font.GothamSemibold
        btn.Parent = parent
        local btnCorner = Instance.new("UICorner"); btnCorner.CornerRadius = UDim.new(0, 8); btnCorner.Parent = btn
        return btn
    end

    local btn1 = createMiniButton(menuFrame, "Mode 1 - Camera", 45)
    local btn2 = createMiniButton(menuFrame, "Mode 2 - Camera + Character", 88)
    local btn3 = createMiniButton(menuFrame, "Mode 3 - Character Only", 131)

    -- Variáveis temporárias para os sliders
    local tempCamSmooth = CamSmooth
    local tempCharSmooth = CharSmooth

    -- CORREÇÃO: Atualiza as variáveis temporárias quando o slider muda
    local camUpdate, camValue = createMiniSlider(menuFrame, "Cam Smooth", 0.1, 3.0, CamSmooth, 180,
        function(value)
            tempCamSmooth = value
            print("CamSmooth alterado para: " .. string.format("%.2f", value)) -- Debug
        end
    )
    
    local charUpdate, charValue = createMiniSlider(menuFrame, "Char Smooth", 0.1, 3.0, CharSmooth, 230,
        function(value)
            tempCharSmooth = value
            print("CharSmooth alterado para: " .. string.format("%.2f", value)) -- Debug
        end
    )

    -- Animação de entrada
    local tweenInSize = TweenService:Create(menuFrame, 
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), 
        {Size = UDim2.new(0, 320, 0, 280)})
    
    local tweenInBg = TweenService:Create(menuFrame, 
        TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
        {BackgroundTransparency = 0})
    
    local tweenInStroke = TweenService:Create(stroke, 
        TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
        {Transparency = 0})
    
    local tweenInTitle = TweenService:Create(title, 
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
        {TextTransparency = 0})

    local function animateButtonsIn()
        for _, btn in ipairs({btn1, btn2, btn3}) do
            TweenService:Create(btn, 
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
                {BackgroundTransparency = 0}):Play()
            TweenService:Create(btn, 
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
                {TextTransparency = 0}):Play()
        end
    end

    tweenInSize:Play()
    tweenInBg:Play()
    tweenInStroke:Play()
    tweenInTitle:Play()
    
    delay(0.15, animateButtonsIn)

    local function escolherModo(modo)
        -- CORREÇÃO: Atualiza as variáveis globais com os valores dos sliders
        CamSmooth = tempCamSmooth
        CharSmooth = tempCharSmooth
        
        print("Salvando - CamSmooth: " .. string.format("%.2f", CamSmooth) .. " | CharSmooth: " .. string.format("%.2f", CharSmooth))
        
        -- Animação de saída
        local tweenOutSize = TweenService:Create(menuFrame, 
            TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In), 
            {Size = UDim2.new(0, 0, 0, 0)})
        
        local tweenOutBg = TweenService:Create(menuFrame, 
            TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), 
            {BackgroundTransparency = 1})
        
        local tweenOutStroke = TweenService:Create(stroke, 
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), 
            {Transparency = 1})
        
        local tweenOutTitle = TweenService:Create(title, 
            TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), 
            {TextTransparency = 1})

        for _, child in ipairs(menuFrame:GetChildren()) do
            if child:IsA("TextButton") then
                TweenService:Create(child, 
                    TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), 
                    {BackgroundTransparency = 1}):Play()
                TweenService:Create(child, 
                    TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), 
                    {TextTransparency = 1}):Play()
            elseif child:IsA("TextLabel") and child ~= title then
                TweenService:Create(child, 
                    TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), 
                    {TextTransparency = 1}):Play()
            elseif child:IsA("Frame") then
                TweenService:Create(child, 
                    TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), 
                    {BackgroundTransparency = 1}):Play()
            end
        end

        tweenOutSize:Play()
        tweenOutBg:Play()
        tweenOutStroke:Play()
        tweenOutTitle:Play()
        
        tweenOutSize.Completed:Connect(function()
            menuFrame:Destroy()
            lockMode = modo
            updateModeFlags()
            
            -- Salvar modo
            local salvarModo = Instance.new("IntValue")
            salvarModo.Name = "SavedLockMode"
            salvarModo.Value = modo
            salvarModo.Parent = playerGui
            
            -- Salvar CamSmooth
            local salvarCam = Instance.new("NumberValue")
            salvarCam.Name = "SavedCamSmooth"
            salvarCam.Value = CamSmooth
            salvarCam.Parent = playerGui
            
            -- Salvar CharSmooth
            local salvarChar = Instance.new("NumberValue")
            salvarChar.Name = "SavedCharSmooth"
            salvarChar.Value = CharSmooth
            salvarChar.Parent = playerGui
            
            createToggleAndUI()
            
            -- Notificação com os valores
            StarterGui:SetCore("SendNotification", {
                Title = "Lock On Configurado",
                Text = "Discord Creator https://discord.gg/86Mmpe94cH",
                Icon = "rbxassetid://7205866966",
                Duration = 5
            })
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
                        -- ===== USA PREDICTION NO CHARACTER =====
                        local neckPos = getPredictedPosition(LockedTarget)
                        if neckPos then
                            local direction = neckPos - rootPart.Position
                            local horizontalDir = Vector3.new(direction.X, 0, direction.Z)
                            local mag = horizontalDir.Magnitude
                            if mag > 0.1 then
                                horizontalDir = horizontalDir / mag
                                local targetCFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + horizontalDir)
                                
                                -- Usa CharSmooth configurável
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
            lastTargetPos = nil
            targetVelocity = Vector3.zero
        end
        lastSearchTime = now
    end

    -- ====================== ATUALIZA PREDICTION ======================
    if LockedTarget and LockedTarget.Parent then
        updateTargetPrediction(LockedTarget)
    end

    -- ====================== CÂMERA (Modos 1 e 2) COM PREDICTION ======================
    if LockedTarget and LockedTarget.Parent and isCameraMode then
        forceInstantReset()

        -- ===== USA PREDICTION NA CÂMERA =====
        local lockPos = getPredictedPosition(LockedTarget)
        if lockPos then
            local rightVec = Camera.CFrame.RightVector
            local targetPos = lockPos - (rightVec * CAMERA_LEFT_OFFSET)
            local targetCFrame = CFrame.new(Camera.CFrame.Position, targetPos)
            -- Usa CamSmooth configurável
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
