-- =========================================================
-- CAMLOCK / AIMLOCK / AIMBOT AUTO
-- NPC GLOBAL + TEAM/WALL CHECK
-- UI MOBILE + RGB + MENU + DRAG + AURA + CROSSHAIR
-- =========================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- =======================
-- ESTADO
-- =======================
local Enabled = false
local Modes = {"CAMLOCK","AIMLOCK","AIMBOT"}
local CurrentModeIndex = 1
local LockMode = Modes[CurrentModeIndex]
local LockPart = "Head"                 -- Head | Torso | Foot
local TargetMode = "PLAYERS"            -- PLAYERS | NPCS
local LockedTarget = nil
local TargetHighlight = nil

-- =======================
-- CONFIG
-- =======================
local CENTER_RADIUS = 90
local SMOOTHNESS = 1.1
local AimStrength = 0.1               -- aimbot mais rápido
local TeamCheck = true
local WallCheck = true

-- =======================
-- SETUP PERSONAGEM
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

local mainBtn = Instance.new("TextButton", gui)
mainBtn.Size = UDim2.new(0,150,0,48)
mainBtn.Position = UDim2.new(0.5,-75,0.85,0)
mainBtn.Text = "CAM LOCK OFF"
mainBtn.TextScaled = true
mainBtn.TextColor3 = Color3.new(1,1,1)
mainBtn.BackgroundColor3 = Color3.fromRGB(20,20,20)
mainBtn.BorderSizePixel = 0
Instance.new("UICorner", mainBtn).CornerRadius = UDim.new(0,14)
local stroke = Instance.new("UIStroke", mainBtn); stroke.Thickness = 2

-- 🔄 BOTÃO MODO
local modeBtn = Instance.new("TextButton", mainBtn)
modeBtn.Size = UDim2.new(0,28,0,28)
modeBtn.Position = UDim2.new(1,-32,0,-32)
modeBtn.Text = "🔄"
modeBtn.TextScaled = true
modeBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
modeBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", modeBtn).CornerRadius = UDim.new(1,0)

-- 👾 BOTÃO NPC
local npcBtn = Instance.new("TextButton", mainBtn)
npcBtn.Size = UDim2.new(0,28,0,28)
npcBtn.Position = UDim2.new(1,4,0.5,-14)
npcBtn.Text = "👾"
npcBtn.TextScaled = true
npcBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
npcBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", npcBtn).CornerRadius = UDim.new(1,0)

-- < > MENU
local menuBtn = Instance.new("TextButton", mainBtn)
menuBtn.Size = UDim2.new(0,28,0,28)
menuBtn.Position = UDim2.new(0,-32,0.5,-55)
menuBtn.Text = "<"
menuBtn.TextScaled = true
menuBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
menuBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", menuBtn).CornerRadius = UDim.new(1,0)

-- MENU LATERAL
local menuOpen = false
local menu = Instance.new("Frame", mainBtn)
menu.Size = UDim2.new(0,130,0,120)
menu.Position = UDim2.new(0,-135,0,0)
menu.BackgroundColor3 = Color3.fromRGB(15,15,15)
menu.Visible = false
Instance.new("UICorner", menu).CornerRadius = UDim.new(0,12)

local function menuOption(text, y, part)
    local b = Instance.new("TextButton", menu)
    b.Size = UDim2.new(1,-10,0,32)
    b.Position = UDim2.new(0,5,0,y)
    b.Text = text
    b.TextScaled = true
    b.BackgroundColor3 = Color3.fromRGB(25,25,25)
    b.TextColor3 = Color3.new(1,1,1)
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
    b.MouseButton1Click:Connect(function() LockPart = part end)
end
menuOption("Cabeça",5,"Head")
menuOption("Torso",44,"Torso")
menuOption("Pé",83,"Foot")

-- CROSSHAIR (mais alta)
local dot = Instance.new("Frame", gui)
dot.Size = UDim2.new(0,4,0,4)
dot.Position = UDim2.new(0.5,0,0.46,0) -- ↑ mais pra cima
dot.AnchorPoint = Vector2.new(0.5,0.5)
dot.BackgroundColor3 = Color3.new(1,1,1)
dot.BorderSizePixel = 0
Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)

-- =======================
-- RGB
-- =======================
local hue = 0
RunService.RenderStepped:Connect(function(dt)
    hue = (hue + dt*0.25) % 1
    local c = Color3.fromHSV(hue,1,1)
    stroke.Color = c
    if TargetHighlight then
        TargetHighlight.OutlineColor = c
        TargetHighlight.FillColor = c
    end
end)

-- =======================
-- DRAG
-- =======================
do
    local dragging, dragStart, startPos
    local function update(input)
        local d = input.Position - dragStart
        mainBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
    end
    mainBtn.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true; dragStart=i.Position; startPos=mainBtn.Position
            i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then dragging=false end end)
        end
    end)
    mainBtn.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseMovement) then
            update(i)
        end
    end)
end

-- =======================
-- FUNÇÕES DE ALVO
-- =======================
local function resolvePart(char)
    if LockPart=="Head" then return char:FindFirstChild("Head")
    elseif LockPart=="Torso" then return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    else return char:FindFirstChild("RightFoot") or char:FindFirstChild("LeftFoot") end
end

local function isNPC(model)
    return model:IsA("Model") and model:FindFirstChildOfClass("Humanoid")
        and Players:GetPlayerFromCharacter(model)==nil
end

local function isEnemy(character)
    local plr = Players:GetPlayerFromCharacter(character)
    if not plr then return true end
    if not TeamCheck then return true end
    if plr.Team and LocalPlayer.Team then return plr.Team ~= LocalPlayer.Team end
    return true
end

local function hasLineOfSight(part)
    if not WallCheck then return true end
    local origin = Camera.CFrame.Position
    local dir = part.Position - origin
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {LocalPlayer.Character, part.Parent}
    return workspace:Raycast(origin, dir, params) == nil
end

local function findTarget()
    local closest, shortest = nil, math.huge
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

    if TargetMode=="PLAYERS" then
        for _,plr in ipairs(Players:GetPlayers()) do
            if plr~=LocalPlayer and plr.Character then
                local part = resolvePart(plr.Character)
                if part then
                    local p,v = Camera:WorldToViewportPoint(part.Position)
                    if v then
                        local d = (Vector2.new(p.X,p.Y)-center).Magnitude
                        if d<CENTER_RADIUS and d<shortest and isEnemy(part.Parent) and hasLineOfSight(part) then
                            shortest,closest = d,part
                        end
                    end
                end
            end
        end
    else
        for _,obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and isNPC(obj) then
                local part = resolvePart(obj)
                if part then
                    local p,v = Camera:WorldToViewportPoint(part.Position)
                    if v then
                        local d = (Vector2.new(p.X,p.Y)-center).Magnitude
                        if d<CENTER_RADIUS and d<shortest and hasLineOfSight(part) then
                            shortest,closest = d,part
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
    local char = LocalPlayer.Character
    if not char then return end

    -- AIMBOT AUTO (não precisa ativar)
    if LockMode=="AIMBOT" then
        if not LockedTarget or not LockedTarget.Parent or not hasLineOfSight(LockedTarget) then
            LockedTarget = findTarget()
            if LockedTarget then applyAura(LockedTarget) end
        end
        if LockedTarget then
            local camPos = Camera.CFrame.Position
            local desired = (LockedTarget.Position - camPos).Unit
            Camera.CFrame = CFrame.new(camPos, camPos + Camera.CFrame.LookVector:Lerp(desired, AimStrength))
        end
        return
    end

    -- CAMLOCK / AIMLOCK (precisa ativar)
    if not Enabled or not LockedTarget or not LockedTarget.Parent then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = CFrame.new(hrp.Position,
            Vector3.new(LockedTarget.Position.X, hrp.Position.Y, LockedTarget.Position.Z))
    end

    if LockMode=="CAMLOCK" then
        local camPos = Camera.CFrame.Position
        local dir = (LockedTarget.Position - camPos).Unit
        Camera.CFrame = CFrame.new(camPos, camPos + Camera.CFrame.LookVector:Lerp(dir, SMOOTHNESS))
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
            mainBtn.Text = LockMode.." ON"
            dot.BackgroundColor3 = Color3.fromRGB(255,80,80)
        else Enabled=false end
    else
        LockedTarget=nil
        if TargetHighlight then TargetHighlight:Destroy(); TargetHighlight=nil end
        mainBtn.Text="CAM LOCK OFF"
        dot.BackgroundColor3 = Color3.new(1,1,1)
    end
end)

modeBtn.MouseButton1Click:Connect(function()
    CurrentModeIndex += 1; if CurrentModeIndex>#Modes then CurrentModeIndex=1 end
    LockMode = Modes[CurrentModeIndex]
    modeBtn.Text = (LockMode=="CAMLOCK" and "🔄") or (LockMode=="AIMLOCK" and "🎯") or "🤖"
    if LockMode=="AIMBOT" then mainBtn.Text="AIMBOT AUTO" end
end)

npcBtn.MouseButton1Click:Connect(function()
    TargetMode = (TargetMode=="PLAYERS") and "NPCS" or "PLAYERS"
    npcBtn.BackgroundColor3 = (TargetMode=="NPCS") and Color3.fromRGB(80,30,30) or Color3.fromRGB(30,30,30)
    LockedTarget=nil
end)

menuBtn.MouseButton1Click:Connect(function()
    menuOpen = not menuOpen
    menu.Visible = menuOpen
    menuBtn.Text = menuOpen and ">" or "<"
end)
