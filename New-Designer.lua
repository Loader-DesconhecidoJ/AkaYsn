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
local FOVMin = 50 -- FOV mínimo dinâmico
local FOV = FOVMax
local CamSmooth = 0.35
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
FovCircle.Color = Color3.fromRGB(255,255,255) -- cor neutra inicial

--// UTILS
local function getPart(char)
    if BodyPart=="Head" then
        return char:FindFirstChild("Head")
    elseif BodyPart=="Torso" then
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

    if TargetType=="PLAYERS" then  
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
    b.BackgroundColor3=Color3.fromRGB(32,32,32)
    b.BorderSizePixel = 0
    Instance.new("UICorner",b).CornerRadius = UDim.new(0,6)
    return b
end

local pBtn = sideBtn("P",4)
local camBtn = sideBtn("CAM",18)
local partBtn = sideBtn("PART",32)

--// TOGGLE
local toggle = Instance.new("TextButton",main)
toggle.Size = UDim2.new(0,110,0,34)
toggle.Position = UDim2.new(0.5,-36,0.5,-17)
toggle.Text="TOGGLE OFF"
toggle.Font=Enum.Font.GothamMedium
toggle.TextSize=14
toggle.TextColor3=Color3.new(1,1,1)
toggle.BorderSizePixel=0
Instance.new("UICorner",toggle).CornerRadius = UDim.new(0,12)

--// DRAG BUTTON 🔄
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
    b.TextSize=11
    b.TextColor3=Color3.new(1,1,1)
    b.BackgroundColor3=Color3.fromRGB(32,32,32)
    b.BorderSizePixel=0
    Instance.new("UICorner",b).CornerRadius = UDim.new(0,6)
    return b
end

local h=partOption("HEAD",4)
local t=partOption("TORSO",24)

--// BUTTON LOGIC
toggle.MouseButton1Click:Connect(function()
    Enabled=not Enabled
    LockedTarget=nil
    toggle.Text=Enabled and "TOGGLE ON" or "TOGGLE OFF"
end)

pBtn.MouseButton1Click:Connect(function()
    TargetType = TargetType=="PLAYERS" and "NPCS" or "PLAYERS"
    pBtn.Text = TargetType=="PLAYERS" and "P" or "N"
    LockedTarget=nil
end)

camBtn.MouseButton1Click:Connect(function()
    if Mode=="CAMLOCK" then Mode="AIMLOCK"
    elseif Mode=="AIMLOCK" then Mode="ASSIST"
    elseif Mode=="ASSIST" then Mode="LOCKON"
    else Mode="CAMLOCK" end
    camBtn.Text = Mode=="CAMLOCK" and "CAM" or Mode=="AIMLOCK" and "AIM" or Mode=="ASSIST" and "AST" or "LOCKON"
    LockedTarget=nil
end)

partBtn.MouseButton1Click:Connect(function()
    partMenu.Visible = not partMenu.Visible
end)

h.MouseButton1Click:Connect(function() BodyPart="Head" partMenu.Visible=false end)
t.MouseButton1Click:Connect(function() BodyPart="Torso" partMenu.Visible=false end)

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

--// LOOP
RunService.RenderStepped:Connect(function()
    toggle.BackgroundColor3 = rgb()

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

    -- centraliza sempre
    FovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    FovCircle.Visible = Enabled and Mode=="ASSIST"

    -- se não tiver alvo dentro do FOV, retorna neutro
    local t = getTarget()
    if not Enabled or not t then
        FOV = FOVMax
        FovCircle.Radius = FOV
        FovCircle.Color = Color3.fromRGB(255,255,255) -- cor neutra
    end

    if not Enabled then return end  

    if Mode~="ASSIST" then  
        if not LockedTarget or not LockedTarget.Parent then  
            LockedTarget=getTarget()  
        end  
    end  

    if Mode=="CAMLOCK" and LockedTarget then  
        local targetPart = LockedTarget.Parent:FindFirstChild("HumanoidRootPart") or LockedTarget  
        if targetPart then  
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)  
        end  
          
    elseif Mode=="AIMLOCK" and LockedTarget then  
        local hrp=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")  
        if hrp then  
            local look=Vector3.new(LockedTarget.Position.X,hrp.Position.Y,LockedTarget.Position.Z)  
            hrp.CFrame=hrp.CFrame:Lerp(CFrame.new(hrp.Position,look),AimSmooth)  
        end  

    elseif Mode=="ASSIST" and t and wallCheck(t) then  
        local cam=Camera.CFrame  
        local dir=(t.Position-cam.Position).Unit  
        Camera.CFrame=CFrame.new(cam.Position,cam.Position+cam.LookVector:Lerp(dir,AssistStrength))  

        -- FOV dinâmico com cor
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local distance = (t.Position - hrp.Position).Magnitude
            local maxDistance = 100 -- ajuste conforme necessário
            local ratio = math.clamp(distance / maxDistance, 0, 1)

            -- FOV dinâmico
            FOV = FOVMax - ((FOVMax - FOVMin) * ratio)
            FovCircle.Radius = FOV

            -- COR DINÂMICA: verde (longe) → amarelo (médio) → vermelho (perto)
            if ratio < 0.33 then
                FovCircle.Color = Color3.fromRGB(255,0,0) -- vermelho perto
            elseif ratio < 0.66 then
                FovCircle.Color = Color3.fromRGB(255,255,0) -- amarelo médio
            else
                FovCircle.Color = Color3.fromRGB(0,255,0) -- verde longe
            end
        end
    end  

    if Mode=="LOCKON" and LockedTarget then  
        local hrp=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")  
        if hrp then  
            local look=Vector3.new(LockedTarget.Position.X,hrp.Position.Y,LockedTarget.Position.Z)  
            hrp.CFrame = CFrame.new(hrp.Position, look)  
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, look)  
        end  
    end
end)
