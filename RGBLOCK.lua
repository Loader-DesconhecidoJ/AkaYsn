-- =========================================================
-- CAMLOCK + AIMLOCK + NPC GLOBAL + RGB + MENU + DRAG + AURA
-- =========================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- =======================
-- ESTADO
-- =======================
local Enabled = false
local LockMode = "CAMLOCK"      -- "CAMLOCK" | "AIMLOCK"
local LockPart = "Head"         -- "Head" | "Torso" | "Foot"
local TargetMode = "PLAYERS"    -- "PLAYERS" | "NPCS"
local LockedTarget = nil
local TargetHighlight = nil

-- CONFIG
local CENTER_RADIUS = 90
local SMOOTHNESS = 1.3

-- =======================
-- SETUP PERSONAGEM (ANTI-SOLTAR)
-- =======================
local function setupCharacter(char)
    local humanoid = char:WaitForChild("Humanoid")
    humanoid.AutoRotate = false
    Camera.CameraSubject = humanoid
end
if LocalPlayer.Character then setupCharacter(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(setupCharacter)

-- =======================
-- GUI
-- =======================
local gui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
gui.ResetOnSpawn = false

-- BOTÃO PRINCIPAL
local mainBtn = Instance.new("TextButton", gui)
mainBtn.Size = UDim2.new(0, 150, 0, 48)
mainBtn.Position = UDim2.new(0.5, -75, 0.85, 0)
mainBtn.Text = "CAM LOCK OFF"
mainBtn.TextScaled = true
mainBtn.TextColor3 = Color3.new(1,1,1)
mainBtn.BackgroundColor3 = Color3.fromRGB(20,20,20)
mainBtn.BorderSizePixel = 0
Instance.new("UICorner", mainBtn).CornerRadius = UDim.new(0,14)

local stroke = Instance.new("UIStroke", mainBtn)
stroke.Thickness = 2

-- 🔄 BOTÃO MODO (CAMLOCK ↔ AIMLOCK)
local modeBtn = Instance.new("TextButton", mainBtn)
modeBtn.Size = UDim2.new(0, 28, 0, 28)
modeBtn.Position = UDim2.new(1, -32, 0, -32)
modeBtn.Text = "🔄"
modeBtn.TextScaled = true
modeBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
modeBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", modeBtn).CornerRadius = UDim.new(1,0)

-- 👾 BOTÃO NPC (PLAYERS ↔ NPCS)
local npcBtn = Instance.new("TextButton", mainBtn)
npcBtn.Size = UDim2.new(0, 28, 0, 28)
npcBtn.Position = UDim2.new(1, 4, 0.5, -14)
npcBtn.Text = "👾"
npcBtn.TextScaled = true
npcBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
npcBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", npcBtn).CornerRadius = UDim.new(1,0)

-- < > MENU
local menuBtn = Instance.new("TextButton", mainBtn)
menuBtn.Size = UDim2.new(0, 28, 0, 28)
menuBtn.Position = UDim2.new(0, -32, 0.5, -55)
menuBtn.Text = "<"
menuBtn.TextScaled = true
menuBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
menuBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", menuBtn).CornerRadius = UDim.new(1,0)

-- MENU LATERAL
local menuOpen = false
local menu = Instance.new("Frame", mainBtn)
menu.Size = UDim2.new(0, 130, 0, 120)
menu.Position = UDim2.new(0, -135, 0, 0)
menu.BackgroundColor3 = Color3.fromRGB(15,15,15)
menu.Visible = false
Instance.new("UICorner", menu).CornerRadius = UDim.new(0,12)

local function menuOption(text, y, part)
    local b = Instance.new("TextButton", menu)
    b.Size = UDim2.new(1, -10, 0, 32)
    b.Position = UDim2.new(0, 5, 0, y)
    b.Text = text
    b.TextScaled = true
    b.BackgroundColor3 = Color3.fromRGB(25,25,25)
    b.TextColor3 = Color3.new(1,1,1)
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
    b.MouseButton1Click:Connect(function()
        LockPart = part
    end)
end

menuOption("Cabeça", 5, "Head")
menuOption("Torso", 44, "Torso")
menuOption("Pé", 83, "Foot")

-- CROSSHAIR
local dot = Instance.new("Frame", gui)
dot.Size = UDim2.new(0,4,0,4)
dot.Position = UDim2.new(0.5,0,0.5,0)
dot.AnchorPoint = Vector2.new(0.5,0.5)
dot.BackgroundColor3 = Color3.new(1,1,1)
dot.BorderSizePixel = 0
Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)

-- =======================
-- RGB (BOTÃO + AURA)
-- =======================
local hue = 0
RunService.RenderStepped:Connect(function(dt)
    hue = (hue + dt * 0.25) % 1
    local c = Color3.fromHSV(hue,1,1)
    stroke.Color = c
    if TargetHighlight then
        TargetHighlight.OutlineColor = c
        TargetHighlight.FillColor = c
    end
end)

-- =======================
-- BOTÃO ARRASTÁVEL
-- =======================
do
    local dragging, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        mainBtn.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
    mainBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainBtn.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    mainBtn.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseMovement) then
            update(input)
        end
    end)
end

-- =======================
-- FUNÇÕES DE ALVO
-- =======================
local function resolvePart(char)
    if LockPart == "Head" then
        return char:FindFirstChild("Head")
    elseif LockPart == "Torso" then
        return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    else
        return char:FindFirstChild("RightFoot") or char:FindFirstChild("LeftFoot")
    end
end

-- NPC GLOBAL = qualquer Model com Humanoid que NÃO seja Player
local function isNPC(model)
    if not model:IsA("Model") then return false end
    if not model:FindFirstChildOfClass("Humanoid") then return false end
    return Players:GetPlayerFromCharacter(model) == nil
end

local function findTarget()
    local closest, shortest = nil, math.huge
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

    if TargetMode == "PLAYERS" then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local part = resolvePart(plr.Character)
                if part then
                    local pos, vis = Camera:WorldToViewportPoint(part.Position)
                    if vis then
                        local d = (Vector2.new(pos.X,pos.Y) - center).Magnitude
                        if d < CENTER_RADIUS and d < shortest then
                            shortest, closest = d, part
                        end
                    end
                end
            end
        end
    else
        -- TODOS OS NPCs DO SERVIDOR (descendants)
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and isNPC(obj) then
                local part = resolvePart(obj)
                if part then
                    local pos, vis = Camera:WorldToViewportPoint(part.Position)
                    if vis then
                        local d = (Vector2.new(pos.X,pos.Y) - center).Magnitude
                        if d < CENTER_RADIUS and d < shortest then
                            shortest, closest = d, part
                        end
                    end
                end
            end
        end
    end
    return closest
end

local function applyAura(part)
    if TargetHighlight then TargetHighlight:Destroy() end
    local hl = Instance.new("Highlight")
    hl.Adornee = part.Parent
    hl.FillTransparency = 0.7
    hl.OutlineTransparency = 0
    hl.Parent = part.Parent
    TargetHighlight = hl
end

-- =======================
-- LOOP PRINCIPAL
-- =======================
RunService.RenderStepped:Connect(function()
    if not Enabled or not LockedTarget or not LockedTarget.Parent then return end
    local char = LocalPlayer.Character
    if not char then return end

    -- gira o boneco (AimLock)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = CFrame.new(
            hrp.Position,
            Vector3.new(LockedTarget.Position.X, hrp.Position.Y, LockedTarget.Position.Z)
        )
    end

    -- ajuda a câmera (CamLock)
    if LockMode == "CAMLOCK" then
        local camPos = Camera.CFrame.Position
        local dir = (LockedTarget.Position - camPos).Unit
        local look = Camera.CFrame.LookVector:Lerp(dir, SMOOTHNESS)
        Camera.CFrame = CFrame.new(camPos, camPos + look)
    end
end)

-- =======================
-- CONTROLES
-- =======================
mainBtn.MouseButton1Click:Connect(function()
    Enabled = not Enabled
    if Enabled then
        LockedTarget = findTarget()
        if LockedTarget then
            applyAura(LockedTarget)
            mainBtn.Text = (LockMode == "CAMLOCK") and "CAM LOCK ON" or "AIM LOCK ON"
            dot.BackgroundColor3 = Color3.fromRGB(255,80,80)
        else
            Enabled = false
        end
    else
        LockedTarget = nil
        if TargetHighlight then TargetHighlight:Destroy() TargetHighlight=nil end
        mainBtn.Text = "CAM LOCK OFF"
        dot.BackgroundColor3 = Color3.new(1,1,1)
    end
end)

modeBtn.MouseButton1Click:Connect(function()
    LockMode = (LockMode == "CAMLOCK") and "AIMLOCK" or "CAMLOCK"
    modeBtn.Text = (LockMode == "CAMLOCK") and "🔄" or "🎯"
    if Enabled then
        mainBtn.Text = (LockMode == "CAMLOCK") and "CAM LOCK ON" or "AIM LOCK ON"
    end
end)

npcBtn.MouseButton1Click:Connect(function()
    TargetMode = (TargetMode == "PLAYERS") and "NPCS" or "PLAYERS"
    npcBtn.BackgroundColor3 = (TargetMode == "NPCS")
        and Color3.fromRGB(80,30,30)
        or Color3.fromRGB(30,30,30)
    LockedTarget = nil
end)

menuBtn.MouseButton1Click:Connect(function()
    menuOpen = not menuOpen
    menu.Visible = menuOpen
    menuBtn.Text = menuOpen and ">" or "<"
end)
