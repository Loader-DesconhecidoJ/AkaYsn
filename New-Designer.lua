--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LP = Players.LocalPlayer

--// STATES
local Enabled = false
local TargetType = "PLAYERS"
local Mode = "CAMLOCK"
local BodyPart = "Head"
local LockedTarget = nil
local Hue = 0

--// CONFIG
local FOVMax = 110
local FOVMin = 50
local FOV = FOVMax
local CamSmooth = 0.35  -- suavização do CAMLOCK
local MistuSmooth = 1 -- suavização do Mistu
local AimSmooth = 1
local AssistStrength = 0.96

--// RGB
local function rgb()
    Hue = (Hue + 0.003) % 1
    return Color3.fromHSV(Hue,1,1)
end

--// FOV CIRCLE
local FovCircle = Drawing.new("Circle")
FovCircle.Thickness = 2
FovCircle.NumSides = 64
FovCircle.Radius = FOV
FovCircle.Filled = false
FovCircle.Visible = false
FovCircle.Color = Color3.fromRGB(255,255,255)

--// DESENHOS CAMLOCK
local camLockLines = {}
for i=1,4 do
    local line = Drawing.new("Line")
    line.Thickness = 2
    line.Color = Color3.fromRGB(0,255,255)
    line.Visible = false
    table.insert(camLockLines, line)
end

local camLockDot = Drawing.new("Circle")
camLockDot.Thickness = 2
camLockDot.Radius = 4
camLockDot.Filled = true
camLockDot.Color = Color3.fromRGB(0,255,255)
camLockDot.Visible = false

local function drawCamLockIndicator(targetPart)
    if not Enabled or not LockedTarget then
        for _,line in pairs(camLockLines) do line.Visible = false end
        camLockDot.Visible = false
        return
    end

    local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
    if not onScreen then
        for _,line in pairs(camLockLines) do line.Visible = false end
        camLockDot.Visible = false
        return
    end

    local size = 25
    local top = Vector2.new(screenPos.X, screenPos.Y - size)
    local right = Vector2.new(screenPos.X + size, screenPos.Y)
    local bottom = Vector2.new(screenPos.X, screenPos.Y + size)
    local left = Vector2.new(screenPos.X - size, screenPos.Y)

    camLockLines[1].From = top; camLockLines[1].To = right
    camLockLines[2].From = right; camLockLines[2].To = bottom
    camLockLines[3].From = bottom; camLockLines[3].To = left
    camLockLines[4].From = left; camLockLines[4].To = top

    for _,line in pairs(camLockLines) do line.Visible = true end
    camLockDot.Position = Vector2.new(screenPos.X, screenPos.Y)
    camLockDot.Visible = true
end

--// DESENHO AIMLOCK
local aimLockArrow = Drawing.new("Triangle")
aimLockArrow.Color = Color3.fromRGB(255,0,0)
aimLockArrow.Visible = false
aimLockArrow.Thickness = 1

local function drawAimLockIndicator(targetPart)
    if not Enabled or not LockedTarget then
        aimLockArrow.Visible = false
        return
    end

    local head = targetPart.Parent:FindFirstChild("𝙃𝙚𝙖𝙙") or targetPart
    local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0,2,0))
    if not onScreen then
        aimLockArrow.Visible = false
        return
    end

    local size = 10
    local p1 = Vector2.new(screenPos.X, screenPos.Y)
    local p2 = Vector2.new(screenPos.X - size, screenPos.Y + size)
    local p3 = Vector2.new(screenPos.X + size, screenPos.Y + size)

    aimLockArrow.PointA = p1
    aimLockArrow.PointB = p2
    aimLockArrow.PointC = p3
    aimLockArrow.Visible = true
end

--// UTILS
local function getPart(char)
    if BodyPart=="𝙃𝙚𝙖𝙙" then
        return char:FindFirstChild("Head")
    elseif BodyPart=="𝙏𝙤𝙧𝙨𝙤" then
        return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    end
end

local function isNPC(m)
    return m:IsA("Model") and m:FindFirstChildOfClass("Humanoid")
        and not Players:GetPlayerFromCharacter(m)
end

--// RAY
local RayParams = RaycastParams.new()
RayParams.FilterType = Enum.RaycastFilterType.Blacklist
RayParams.IgnoreWater = true

local function wallCheck(part)
    RayParams.FilterDescendantsInstances = {LP.Character}
    local r = workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, RayParams)
    return not r or r.Instance:IsDescendantOf(part.Parent)
end

--// TARGET
local function getTarget()
    local center = Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
    local best,dist=nil,math.huge

    local function check(char)
        local part=getPart(char)
        if not part then return end
        local pos,on=Camera:WorldToViewportPoint(part.Position)
        if not on then return end
        local d=(Vector2.new(pos.X,pos.Y)-center).Magnitude
        if d<FOV and d<dist then best,dist=part,d end
    end

    if TargetType=="𝙋𝙇𝘼𝙔𝙀𝙍𝙎" then
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=LP and p.Character then check(p.Character) end
        end
    else
        for _,m in ipairs(workspace:GetDescendants()) do
            if isNPC(m) then check(m) end
        end
    end
    return best
end

--// GUI
local gui = Instance.new("ScreenGui",LP.PlayerGui)
gui.ResetOnSpawn=false

--// MAIN MENU
local main = Instance.new("Frame",gui)
main.Size = UDim2.new(0,180,0,52)
main.Position = UDim2.new(0.5,-90,0.65,0)
main.BackgroundColor3 = Color3.fromRGB(18,18,18)
main.BorderSizePixel = 0
Instance.new("UICorner",main).CornerRadius = UDim.new(0,14)

--// SIDE BUTTONS
local function sideBtn(txt,y)
    local b=Instance.new("TextButton",main)
    b.Size=UDim2.new(0,38,0,14)
    b.Position=UDim2.new(0,6,0,y)
    b.Text=txt
    b.Font=Enum.Font.GothamBold
    b.TextSize=11
    b.TextColor3=Color3.new(1,1,1)
    b.BackgroundColor3 = Color3.fromRGB(32,32,32)
    b.BorderSizePixel = 0
    Instance.new("UICorner",b).CornerRadius = UDim.new(0,6)
    return b
end

local pBtn = sideBtn("𝙋",4)
local camBtn = sideBtn("𝘾𝘼𝙈",18)
local partBtn = sideBtn("𝙋𝘼𝙍𝙏",32)

--// TOGGLE
local toggle = Instance.new("TextButton",main)
toggle.Size = UDim2.new(0,110,0,34)
toggle.Position = UDim2.new(0.5,-36,0.5,-17)
toggle.Text="𝙏𝙊𝙂𝙂𝙇𝙀 𝙊𝙁𝙁"
toggle.Font=Enum.Font.GothamMedium
toggle.TextSize = 14
toggle.TextColor3 = Color3.new(1,1,1)
toggle.BorderSizePixel = 0
Instance.new("UICorner",toggle).CornerRadius = UDim.new(0,12)

--// DRAG BUTTON
local dragBtn = Instance.new("TextButton",gui)
dragBtn.Size = UDim2.new(0,32,0,20)
dragBtn.Text = "🔄"
dragBtn.Font = Enum.Font.GothamBold
dragBtn.TextSize = 14
dragBtn.TextColor3 = Color3.new(1,1,1)
dragBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
dragBtn.BorderSizePixel = 0
Instance.new("UICorner",dragBtn).CornerRadius = UDim.new(0,8)

--// PART MENU
local partMenu=Instance.new("Frame",gui)
partMenu.Size=UDim2.new(0,110,0,44)
partMenu.BackgroundColor3=Color3.fromRGB(22,22,22)
partMenu.BorderSizePixel=0
partMenu.Visible=false
Instance.new("UICorner",partMenu).CornerRadius = UDim.new(0,8)

local function partOption(txt,y)
    local b=Instance.new("TextButton",partMenu)
    b.Size=UDim2.new(1,-10,0,18)
    b.Position=UDim2.new(0,5,0,y)
    b.Text=txt
    b.Font=Enum.Font.Gotham
    b.TextSize = 11
    b.TextColor3 = Color3.new(1,1,1)
    b.BackgroundColor3 = Color3.fromRGB(32,32,32)
    b.BorderSizePixel = 0
    Instance.new("UICorner",b).CornerRadius = UDim.new(0,6)
    return b
end

local h=partOption("𝙃𝙀𝘼𝘿",4)
local t=partOption("𝙏𝙊𝙍𝙎𝙊",24)

--// BUTTON LOGIC
toggle.MouseButton1Click:Connect(function()
    Enabled=not Enabled
    LockedTarget=nil
    toggle.Text=Enabled and "𝙏𝙊𝙂𝙂𝙇𝙀 𝙊𝙉" or "𝙏𝙊𝙂𝙂𝙇𝙀 𝙊𝙁𝙁"
end)

pBtn.MouseButton1Click:Connect(function()
    TargetType = TargetType=="𝙋𝙇𝘼𝙔𝙀𝙍𝙎" and "𝙉𝙋𝘾𝙎" or "𝙋𝙇𝘼𝙔𝙀𝙍𝙎"
    pBtn.Text = TargetType=="𝙋𝙇𝘼𝙔𝙀𝙍𝙎" and "𝙋" or "𝙉"
    LockedTarget=nil
end)

camBtn.MouseButton1Click:Connect(function()
    if Mode=="𝘾𝘼𝙈𝙇𝙊𝘾𝙆" then Mode="𝘼𝙄𝙈𝙇𝙊𝘾𝙆"
    elseif Mode=="𝘼𝙄𝙈𝙇𝙊𝘾𝙆" then Mode="𝘼𝙎𝙎𝙄𝙎𝙏"
    elseif Mode=="𝘼𝙎𝙎𝙄𝙎𝙏" then Mode="𝙈𝙞𝙨𝙩𝙪"
    elseif Mode=="𝙈𝙞𝙨𝙩𝙪" then Mode="𝘾𝘼𝙈𝙇𝙊𝘾𝙆"
    else Mode="𝘾𝘼𝙈𝙇𝙊𝘾𝙆" end

    camBtn.Text = Mode=="𝘾𝘼𝙈𝙇𝙊𝘾𝙆" and "𝘾𝘼𝙈"
    or Mode=="𝘼𝙄𝙈𝙇𝙊𝘾𝙆" and "𝘼𝙄𝙈"
    or Mode=="𝘼𝙎𝙎𝙄𝙎𝙏" and "𝘼𝙎𝙏"
    or Mode=="𝙈𝙞𝙨𝙩𝙪" and "𝙈𝙨𝙩"
    LockedTarget=nil
end)

partBtn.MouseButton1Click:Connect(function()
    partMenu.Visible = not partMenu.Visible
end)

h.MouseButton1Click:Connect(function() BodyPart="𝙃𝙚𝙖𝙙" partMenu.Visible=false end)
t.MouseButton1Click:Connect(function() BodyPart="𝙏𝙤𝙧𝙨𝙤" partMenu.Visible=false end)

--// DRAG LOGIC
local dragging=false
local dragInput
local dragStart
local startPos

local function updateDrag(input)
    local delta=input.Position-dragStart
    main.Position=UDim2.new(
        startPos.X.Scale,startPos.X.Offset+delta.X,
        startPos.Y.Scale,startPos.Y.Offset+delta.Y
    )
end

dragBtn.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1
    or input.UserInputType==Enum.UserInputType.Touch then
        dragging=true
        dragStart=input.Position
        startPos=main.Position

        input.Changed:Connect(function()
            if input.UserInputState==Enum.UserInputState.End then
                dragging=false
            end
        end)
    end
end)

dragBtn.InputChanged:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseMovement
    or input.UserInputType==Enum.UserInputType.Touch then
        dragInput=input
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and input==dragInput then
        updateDrag(input)
    end
end)

--// MAIN LOOP
RunService.RenderStepped:Connect(function()
    toggle.BackgroundColor3 = rgb()

    -- atualizar drag
    dragBtn.Position = UDim2.fromOffset(
        main.AbsolutePosition.X + main.AbsoluteSize.X/2 - 16,
        main.AbsolutePosition.Y + main.AbsoluteSize.Y + 6
    )

    if partMenu.Visible then
        partMenu.Position = UDim2.fromOffset(
            main.AbsolutePosition.X,
            dragBtn.AbsolutePosition.Y + dragBtn.AbsoluteSize.Y + 4
        )
    end

    -- limpeza automática de indicadores se não estiver no modo correto
    if Mode ~= "𝘾𝘼𝙈𝙇𝙊𝘾𝙆" or not Enabled or not LockedTarget then
        for _,line in pairs(camLockLines) do line.Visible = false end
        camLockDot.Visible = false
    end

    if Mode ~= "𝘼𝙄𝙈𝙇𝙊𝘾𝙆" or not Enabled or not LockedTarget then
        aimLockArrow.Visible = false
    end

    -- centraliza FOV apenas para AIM ASSIST
    FovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    FovCircle.Visible = Enabled and Mode=="𝘼𝙎𝙎𝙄𝙎𝙏"

    local t = getTarget()
    if not Enabled or not t then
        FOV = FOVMax
        FovCircle.Radius = FOV
        FovCircle.Color = Color3.fromRGB(255,255,255)
    end

    if not Enabled then
        for _,line in pairs(camLockLines) do line.Visible = false end
        camLockDot.Visible = false
        aimLockArrow.Visible = false
        FovCircle.Visible = false
        return
    end

    if Mode~="𝘼𝙎𝙎𝙄𝙎𝙏" then
        if not LockedTarget or not LockedTarget.Parent then
            LockedTarget = getTarget()
        end
    end

    --// MODOS
    if Mode=="𝘾𝘼𝙈𝙇𝙊𝘾𝙆" and LockedTarget then
        local targetPart = LockedTarget.Parent:FindFirstChild("HumanoidRootPart") or LockedTarget
        if targetPart then
            local camCFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
            Camera.CFrame = Camera.CFrame:Lerp(camCFrame, CamSmooth)
            drawCamLockIndicator(targetPart)
        end

    elseif Mode=="𝘼𝙄𝙈𝙇𝙊𝘾𝙆" and LockedTarget then
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local look = Vector3.new(LockedTarget.Position.X, hrp.Position.Y, LockedTarget.Position.Z)
            hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(hrp.Position, look), AimSmooth)
        end
        drawAimLockIndicator(LockedTarget)

    elseif Mode=="𝘼𝙎𝙎𝙄𝙎𝙏" and t and wallCheck(t) then
        local cam = Camera.CFrame
        local dir = (t.Position - cam.Position).Unit
        Camera.CFrame = CFrame.new(cam.Position, cam.Position + cam.LookVector:Lerp(dir, AssistStrength))

        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")    
        if hrp then    
            local distance = (t.Position - hrp.Position).Magnitude    
            local ratio = math.clamp(distance / 100, 0, 1)    
            FOV = FOVMax - ((FOVMax - FOVMin) * ratio)    
            FovCircle.Radius = FOV    
            if ratio < 0.33 then    
                FovCircle.Color = Color3.fromRGB(255,0,0)    
            elseif ratio < 0.66 then    
                FovCircle.Color = Color3.fromRGB(255,255,0)    
            else    
                FovCircle.Color = Color3.fromRGB(0,255,0)    
            end    
        end

    elseif Mode=="𝙈𝙞𝙨𝙩𝙪" and LockedTarget then
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local look = Vector3.new(LockedTarget.Position.X, hrp.Position.Y, LockedTarget.Position.Z)
            hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(hrp.Position, look), MistuSmooth)
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, look), MistuSmooth)
        end
    end
end)
