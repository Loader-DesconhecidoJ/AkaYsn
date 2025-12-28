--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LP = Players.LocalPlayer

--// STATES
local Enabled = false
local TargetType = "PLAYERS"
local Mode = "CAMLOCK" -- CAMLOCK / AIMLOCK / ASSIST
local BodyPart = "Head"
local LockedTarget = nil
local PartMenuOpen = false
local Hue = 0

--// CONFIG
local FOV = 120
local CamSmooth = 0.98
local AimSmooth = 1
local AssistStrength = 0.96

--// FOV CIRCLE (AIM ASSIST)
local FovCircle = Drawing.new("Circle")
FovCircle.Visible = false
FovCircle.Thickness = 2
FovCircle.NumSides = 64
FovCircle.Radius = FOV
FovCircle.Filled = false

--// UTILS
local function getRGB()
	Hue = (Hue + 0.002) % 1
	return Color3.fromHSV(Hue,1,1)
end

local function getPart(char)
	if BodyPart == "Head" then
		return char:FindFirstChild("Head")
	elseif BodyPart == "Torso" then
		return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
	else
		return char:FindFirstChild("LeftFoot") or char:FindFirstChild("RightFoot")
	end
end

local function isNPC(m)
	return m:IsA("Model")
		and m:FindFirstChildOfClass("Humanoid")
		and not Players:GetPlayerFromCharacter(m)
end

--// WALL CHECK (AIM ASSIST)
local RayParams = RaycastParams.new()
RayParams.FilterType = Enum.RaycastFilterType.Blacklist
RayParams.IgnoreWater = true

local function wallCheck(part)
	RayParams.FilterDescendantsInstances = {LP.Character}
	local r = workspace:Raycast(
		Camera.CFrame.Position,
		part.Position - Camera.CFrame.Position,
		RayParams
	)
	return not r or r.Instance:IsDescendantOf(part.Parent)
end

--// TEAM CHECK (AIM ASSIST)
local function teamCheck(part)
	if TargetType ~= "PLAYERS" then return false end
	local p = Players:GetPlayerFromCharacter(part.Parent)
	return p and LP.Team and p.Team == LP.Team
end

--// TARGET FINDER
local function getTarget()
	local center = Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
	local best,dist = nil,math.huge

	local function check(char)
		local part = getPart(char)
		if not part then return end
		local pos,on = Camera:WorldToViewportPoint(part.Position)
		if not on then return end
		local d = (Vector2.new(pos.X,pos.Y)-center).Magnitude
		if d < FOV and d < dist then
			best,dist = part,d
		end
	end

	if TargetType=="PLAYERS" then
		for _,p in pairs(Players:GetPlayers()) do
			if p~=LP and p.Character then
				check(p.Character)
			end
		end
	else
		for _,m in pairs(workspace:GetDescendants()) do
			if isNPC(m) then check(m) end
		end
	end
	return best
end

--// GUI
local gui = Instance.new("ScreenGui",LP.PlayerGui)
gui.ResetOnSpawn = false

local main = Instance.new("Frame",gui)
main.Size = UDim2.new(0,260,0,140)
main.Position = UDim2.new(0.5,-130,0.6,0)
main.BackgroundColor3 = Color3.fromRGB(20,20,20)
main.BorderSizePixel = 0
Instance.new("UICorner",main).CornerRadius = UDim.new(0,12)

-- DRAG
local drag,start,origin
main.InputBegan:Connect(function(i)
	if i.UserInputType==Enum.UserInputType.MouseButton1 then
		drag=true
		start=i.Position
		origin=main.Position
	end
end)
main.InputChanged:Connect(function(i)
	if drag then
		local d=i.Position-start
		main.Position=UDim2.new(origin.X.Scale,origin.X.Offset+d.X,origin.Y.Scale,origin.Y.Offset+d.Y)
	end
end)
UIS.InputEnded:Connect(function(i)
	if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
end)

-- BUTTON CREATOR
local function button(text,y)
	local b=Instance.new("TextButton",main)
	b.Size=UDim2.new(0,230,0,26)
	b.Position=UDim2.new(0,15,0,y)
	b.Text=text
	b.Font=Enum.Font.GothamBold
	b.TextSize=13
	b.TextColor3=Color3.new(1,1,1)
	b.BackgroundColor3=Color3.fromRGB(30,30,30)
	b.BorderSizePixel=0
	Instance.new("UICorner",b).CornerRadius=UDim.new(0,8)
	return b
end

local toggleBtn = button("OFF",10)
local targetBtn = button("TARGET: PLAYER",42)
local modeBtn = button("MODE: CAMLOCK",74)
local partBtn = button("PART: HEAD",106)

-- PART MENU
local partMenu = Instance.new("Frame",main)
partMenu.Size=UDim2.new(0,230,0,78)
partMenu.Position=UDim2.new(0,15,0,136)
partMenu.Visible=false
partMenu.BackgroundColor3=Color3.fromRGB(25,25,25)
partMenu.BorderSizePixel=0
Instance.new("UICorner",partMenu).CornerRadius=UDim.new(0,8)

local function partButton(txt,y)
	local b=Instance.new("TextButton",partMenu)
	b.Size=UDim2.new(1,-10,0,22)
	b.Position=UDim2.new(0,5,0,y)
	b.Text=txt
	b.Font=Enum.Font.Gotham
	b.TextSize=12
	b.TextColor3=Color3.new(1,1,1)
	b.BackgroundColor3=Color3.fromRGB(35,35,35)
	b.BorderSizePixel=0
	Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
	return b
end

local headBtn = partButton("HEAD",5)
local torsoBtn = partButton("TORSO",28)
local footBtn = partButton("FOOT",51)

-- BUTTON LOGIC
toggleBtn.MouseButton1Click:Connect(function()
	Enabled=not Enabled
	LockedTarget=nil
	toggleBtn.Text=Enabled and "ON" or "OFF"
end)

targetBtn.MouseButton1Click:Connect(function()
	TargetType = TargetType=="PLAYERS" and "NPCS" or "PLAYERS"
	targetBtn.Text="TARGET: "..TargetType
	LockedTarget=nil
end)

modeBtn.MouseButton1Click:Connect(function()
	if Mode=="CAMLOCK" then Mode="AIMLOCK"
	elseif Mode=="AIMLOCK" then Mode="ASSIST"
	else Mode="CAMLOCK" end
	modeBtn.Text="MODE: "..Mode
	LockedTarget=nil
end)

partBtn.MouseButton1Click:Connect(function()
	PartMenuOpen=not PartMenuOpen
	partMenu.Visible=PartMenuOpen
end)

headBtn.MouseButton1Click:Connect(function()
	BodyPart="Head"
	partBtn.Text="PART: HEAD"
end)
torsoBtn.MouseButton1Click:Connect(function()
	BodyPart="Torso"
	partBtn.Text="PART: TORSO"
end)
footBtn.MouseButton1Click:Connect(function()
	BodyPart="Foot"
	partBtn.Text="PART: FOOT"
end)

--// LOOP
RunService.RenderStepped:Connect(function()
	local rgb=getRGB()
	for _,b in pairs(main:GetChildren()) do
		if b:IsA("TextButton") then
			b.BackgroundColor3=rgb:Lerp(Color3.fromRGB(30,30,30),0.6)
		end
	end

	FovCircle.Visible = Enabled and Mode=="ASSIST"
	FovCircle.Position = Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
	FovCircle.Color = rgb

	if not Enabled then return end

	if Mode~="ASSIST" then
		if not LockedTarget or not LockedTarget.Parent then
			LockedTarget=getTarget()
		end
	end

	if Mode=="CAMLOCK" and LockedTarget then
		Camera.CFrame=Camera.CFrame:Lerp(
			CFrame.new(Camera.CFrame.Position,LockedTarget.Position),
			CamSmooth
		)

	elseif Mode=="AIMLOCK" and LockedTarget then
		local hrp=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			local look=Vector3.new(LockedTarget.Position.X,hrp.Position.Y,LockedTarget.Position.Z)
			hrp.CFrame=hrp.CFrame:Lerp(CFrame.new(hrp.Position,look),AimSmooth)
		end

	elseif Mode=="ASSIST" then
		local t=getTarget()
		if t and wallCheck(t) and not teamCheck(t) then
			local cam=Camera.CFrame
			local dir=(t.Position-cam.Position).Unit
			Camera.CFrame=CFrame.new(
				cam.Position,
				cam.Position+cam.LookVector:Lerp(dir,AssistStrength)
			)
		end
	end
end)
