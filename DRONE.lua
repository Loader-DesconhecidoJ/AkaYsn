-- FREE CAM DRONE PREMIUM v2.4 - LOOP SOUND 136704576012970 + TWEEN IMAGEM DO DRONE + MINI MAP + CHASE MODE (FIX) + HUD REPOSICIONADO + TV ANIMATION ON/OFF + OVERLAY SOMENTE NO FPV
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local playerGui = player:WaitForChild("PlayerGui")

local MOVE_SPEED = 130
local MAX_SPEED = 400
local MIN_SPEED = 60
local SENSITIVITY = 0.6

local freeCamEnabled = false
local velocity = Vector3.new()
local yaw = 0
local pitch = 0
local dronePosition = Vector3.new()

local altLock = false
local targetAltitude = 0

local moveFlags = {
	Forward = false, Back = false,
	Left = false, Right = false,
	FlyUp = false, FlyDown = false
}

local droneModel = nil
local rotors = {}
local antennas = {}
local propellerSound = nil
local colorIndex = 1
local droneColors = {
	Color3.fromRGB(0, 255, 220),
	Color3.fromRGB(255, 80, 200),
	Color3.fromRGB(100, 255, 100),
	Color3.fromRGB(255, 220, 60),
	Color3.fromRGB(180, 100, 255)
}

local chaseMode = false

-- ====================== RAGDOLL ======================
local function NoCollide(char)
	local parts = {}
	for _, v in pairs(char:GetChildren()) do
		if v:IsA("BasePart") then table.insert(parts, v) end
	end
	for i = 1, #parts do
		for j = i + 1, #parts do
			local nocollide = Instance.new("NoCollisionConstraint")
			nocollide.Name = "RD_NoCollide"
			nocollide.Part0 = parts[i]
			nocollide.Part1 = parts[j]
			nocollide.Parent = parts[i]
		end
	end
end

local function SetRagdoll(state)
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local head = char:FindFirstChild("Head")
	local root = char:FindFirstChild("HumanoidRootPart")
	
	if state then
		hum:ChangeState(Enum.HumanoidStateType.Physics)
		hum.PlatformStand = true
		hum.AutoRotate = false
		NoCollide(char)
		
		for _, obj in pairs(char:GetDescendants()) do
			if obj:IsA("Motor6D") and obj.Name ~= "Neck" then
				local p0, p1 = obj.Part0, obj.Part1
				local a0 = Instance.new("Attachment", p0)
				local a1 = Instance.new("Attachment", p1)
				a0.Name, a1.Name = "RD_At", "RD_At"
				a0.CFrame, a1.CFrame = obj.C0, obj.C1
				
				local socket = Instance.new("BallSocketConstraint", obj.Parent)
				socket.Name = "RD_Socket"
				socket.Attachment0 = a0
				socket.Attachment1 = a1
				socket.LimitsEnabled = true
				socket.UpperAngle = 30
				socket.TwistLimitsEnabled = true
				socket.TwistLowerAngle = -40
				socket.TwistUpperAngle = 40
				
				p1.CustomPhysicalProperties = PhysicalProperties.new(4, 0.3, 0.5, 10, 10)
				p1.CanCollide = true
				obj.Enabled = false
			end
		end
		
		if head then head.CanCollide = true; head.Massless = false end
		if root then root.AssemblyAngularVelocity = Vector3.new(0,0,0) end
	else
		hum.PlatformStand = false
		hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		hum.AutoRotate = true
		
		for _, obj in pairs(char:GetDescendants()) do
			if obj.Name:match("RD_") then obj:Destroy()
			elseif obj:IsA("Motor6D") then obj.Enabled = true
			elseif obj:IsA("BasePart") then obj.CustomPhysicalProperties = nil end
		end
	end
end

RunService.Stepped:Connect(function()
	if freeCamEnabled and player.Character then
		local char = player.Character
		local root = char:FindFirstChild("HumanoidRootPart")
		for _, v in pairs(char:GetChildren()) do
			if v:IsA("BasePart") then v.CanCollide = true end
		end
		if root then
			if root.Position.Y < workspace.FallenPartsDestroyHeight + 12 then
				root.Velocity = Vector3.new(root.Velocity.X, 12, root.Velocity.Z)
			end
			root.AssemblyAngularVelocity = Vector3.new(0,0,0)
		end
	end
end)

-- ====================== GUI + D-PAD ======================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "EliteDroneUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 240, 0, 240)
mainFrame.Position = UDim2.new(0, 18, 0, 75)
mainFrame.BackgroundColor3 = Color3.fromRGB(12,12,28)
mainFrame.BackgroundTransparency = 0.3
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0,18)

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.new(0,40,0,40)
grid.CellPadding = UDim2.new(0,10,0,10)
grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
grid.Parent = mainFrame

local function newBtn(txt, col)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0,40,0,40)
	b.BackgroundColor3 = col or Color3.fromRGB(28,28,48)
	b.Text = txt
	b.TextColor3 = Color3.new(1,1,1)
	b.TextScaled = true
	b.Font = Enum.Font.GothamBold
	b.BackgroundTransparency = 0.25
	b.Parent = mainFrame
	Instance.new("UICorner", b).CornerRadius = UDim.new(0,10)
	local s = Instance.new("UIStroke", b)
	s.Thickness = 1.8
	s.Color = Color3.fromRGB(0,255,220)
	return b
end

local toggleBtn = newBtn("🚁", Color3.fromRGB(0,200,255))
local speedUpBtn = newBtn("SPD+")
local speedDownBtn = newBtn("SPD-")
local altLockBtn = newBtn("🔒", Color3.fromRGB(255,170,50))
local colorBtn = newBtn("🎨")
local resetBtn = newBtn("🔄")
local chaseBtn = newBtn("👁️", Color3.fromRGB(100,200,255))

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1,-20,0,26)
speedLabel.Position = UDim2.new(0,10,1,-34)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "SPD: 130"
speedLabel.TextColor3 = Color3.new(1,1,1)
speedLabel.TextScaled = true
speedLabel.Font = Enum.Font.GothamBold
speedLabel.Parent = mainFrame

local hudBtn = newBtn("≡")
hudBtn.Size = UDim2.new(0,45,0,45)
hudBtn.Position = UDim2.new(0, 25, 0, 15)
hudBtn.Parent = screenGui

-- MINI MAP (Feature 9)
local miniMapContainer = Instance.new("Frame")
miniMapContainer.Size = UDim2.new(0, 130, 0, 130)
miniMapContainer.Position = UDim2.new(1, -150, 0, 20)
miniMapContainer.BackgroundColor3 = Color3.fromRGB(12,12,28)
miniMapContainer.BackgroundTransparency = 0.4
miniMapContainer.Parent = screenGui
miniMapContainer.Visible = false
Instance.new("UICorner", miniMapContainer).CornerRadius = UDim.new(0,12)
Instance.new("UIStroke", miniMapContainer).Thickness = 2
Instance.new("UIStroke", miniMapContainer).Color = Color3.fromRGB(0,255,220)

local viewport = Instance.new("ViewportFrame")
viewport.Size = UDim2.new(1,0,1,0)
viewport.BackgroundTransparency = 1
viewport.Parent = miniMapContainer

local miniCamera = Instance.new("Camera")
viewport.CurrentCamera = miniCamera

local miniDrone = nil

-- D-PAD (só aparece no modo drone)
local dpadFrame = Instance.new("Frame")
dpadFrame.Size = UDim2.new(0, 260, 0, 200)
dpadFrame.Position = UDim2.new(0, 30, 1, -240)
dpadFrame.BackgroundTransparency = 0.8
dpadFrame.BackgroundColor3 = Color3.fromRGB(10,10,25)
dpadFrame.Visible = false
dpadFrame.Parent = screenGui
Instance.new("UICorner", dpadFrame).CornerRadius = UDim.new(0,20)
Instance.new("UIStroke", dpadFrame).Thickness = 3
Instance.new("UIStroke", dpadFrame).Color = Color3.fromRGB(0,255,220)

local function createDPadButton(txt, pos, size)
	local btn = Instance.new("TextButton")
	btn.Size = size or UDim2.new(0,55,0,55)
	btn.Position = pos
	btn.BackgroundColor3 = Color3.fromRGB(0,200,255)
	btn.Text = txt
	btn.TextColor3 = Color3.new(1,1,1)
	btn.TextScaled = true
	btn.Font = Enum.Font.GothamBold
	btn.BackgroundTransparency = 0.2
	btn.Parent = dpadFrame
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0,12)
	Instance.new("UIStroke", btn).Thickness = 2
	Instance.new("UIStroke", btn).Color = Color3.fromRGB(255,255,255)
	return btn
end

local fwdBtn    = createDPadButton("↑",   UDim2.new(0.5, -27, 0, 10))
local backBtn   = createDPadButton("↓",   UDim2.new(0.5, -27, 1, -65))
local leftBtn   = createDPadButton("←",   UDim2.new(0, 10, 0.5, -27))
local rightBtn  = createDPadButton("→",   UDim2.new(1, -65, 0.5, -27))
local flyUpBtn  = createDPadButton("🡅",   UDim2.new(1, 10, 0, 30), UDim2.new(0,48,0,48))
local flyDownBtn= createDPadButton("🡇",   UDim2.new(1, 10, 1, -78), UDim2.new(0,48,0,48))

local function holdButton(btn, flag)
	btn.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
			moveFlags[flag] = true
		end
	end)
	btn.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
			moveFlags[flag] = false
		end
	end)
end

holdButton(fwdBtn, "Forward")
holdButton(backBtn, "Back")
holdButton(leftBtn, "Left")
holdButton(rightBtn, "Right")
holdButton(flyUpBtn, "FlyUp")
holdButton(flyDownBtn, "FlyDown")

-- ====================== FPV OVERLAY ======================
local overlay = Instance.new("ScreenGui")
overlay.Name = "DroneFPV"
overlay.ResetOnSpawn = false
overlay.Enabled = false
overlay.Parent = playerGui

local vignette = Instance.new("ImageLabel", overlay)
vignette.Size = UDim2.new(1,0,1,0)
vignette.BackgroundTransparency = 1
vignette.Image = "rbxassetid://4576475446"
vignette.ImageColor3 = Color3.new(0,0,0)
vignette.ImageTransparency = 0.35

local scanlines = Instance.new("ImageLabel", overlay)
scanlines.Size = UDim2.new(1,0,1,0)
scanlines.BackgroundTransparency = 1
scanlines.Image = "rbxassetid://5105159194"
scanlines.ImageTransparency = 0.8

local crosshair = Instance.new("ImageLabel", overlay)
crosshair.Size = UDim2.new(0,68,0,68)
crosshair.Position = UDim2.new(0.5,-34,0.5,-34)
crosshair.BackgroundTransparency = 1
crosshair.Image = "rbxassetid://318389430"
crosshair.ImageColor3 = Color3.fromRGB(0,255,200)
crosshair.ImageTransparency = 0.5

local infoBar = Instance.new("Frame", overlay)
infoBar.Size = UDim2.new(1,0,0,42)
infoBar.BackgroundColor3 = Color3.new(0,0,0)
infoBar.BackgroundTransparency = 0.65

local recLabel = Instance.new("TextLabel", infoBar)
recLabel.Size = UDim2.new(0,110,1,0)
recLabel.Position = UDim2.new(0,25,0,0)
recLabel.BackgroundTransparency = 1
recLabel.Text = "● REC"
recLabel.TextColor3 = Color3.fromRGB(255,70,70)
recLabel.TextScaled = true
recLabel.Font = Enum.Font.GothamBlack

local altLabel = Instance.new("TextLabel", infoBar)
altLabel.Size = UDim2.new(0,180,1,0)
altLabel.Position = UDim2.new(0.5,-90,0,0)
altLabel.BackgroundTransparency = 1
altLabel.Text = "ALT: 000m"
altLabel.TextColor3 = Color3.new(1,1,1)
altLabel.TextScaled = true
altLabel.Font = Enum.Font.Code

local spdLabel = Instance.new("TextLabel", infoBar)
spdLabel.Size = UDim2.new(0,150,1,0)
spdLabel.Position = UDim2.new(1,-165,0,0)
spdLabel.BackgroundTransparency = 1
spdLabel.Text = "SPD: 130"
spdLabel.TextColor3 = Color3.new(1,1,1)
spdLabel.TextScaled = true
spdLabel.Font = Enum.Font.Code

-- ====================== ANIMAÇÃO TWEEN DA IMAGEM DO DRONE ======================
local function showDroneActivationImage()
	local img = Instance.new("ImageLabel")
	img.Size = UDim2.new(0, 0, 0, 0)
	img.Position = UDim2.new(0.5, 0, 0.5, 0)
	img.AnchorPoint = Vector2.new(0.5, 0.5)
	img.BackgroundTransparency = 1
	img.Image = "rbxassetid://PUT_YOUR_DRONE_IMAGE_ID_HERE"
	img.ImageTransparency = 1
	img.Parent = screenGui
	img.ZIndex = 100

	local tweenIn = TweenService:Create(img, TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 420, 0, 280),
		ImageTransparency = 0.12
	})
	tweenIn:Play()

	task.delay(1.8, function()
		local tweenOut = TweenService:Create(img, TweenInfo.new(0.65, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 180, 0, 120),
			ImageTransparency = 1
		})
		tweenOut:Play()
		tweenOut.Completed:Connect(function() img:Destroy() end)
	end)
end

-- ====================== ANIMAÇÃO TV LIGANDO/DESLIGANDO (FPV OVERLAY) ======================
local function animateOverlay(enable)
	if enable then
		overlay.Enabled = true
		
		-- Começa desligado
		vignette.ImageTransparency = 1
		scanlines.ImageTransparency = 1
		crosshair.ImageTransparency = 1
		infoBar.BackgroundTransparency = 1
		recLabel.TextTransparency = 1
		altLabel.TextTransparency = 1
		spdLabel.TextTransparency = 1

		-- Animação de ligar TV
		TweenService:Create(vignette, TweenInfo.new(0.65, Enum.EasingStyle.Quint), {ImageTransparency = 0.35}):Play()
		TweenService:Create(scanlines, TweenInfo.new(0.75, Enum.EasingStyle.Quint), {ImageTransparency = 0.8}):Play()
		TweenService:Create(crosshair, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {ImageTransparency = 0.5}):Play()
		TweenService:Create(infoBar, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.65}):Play()
		TweenService:Create(recLabel, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
		TweenService:Create(altLabel, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
		TweenService:Create(spdLabel, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
	else
		-- Animação de desligar TV
		local tweenVig = TweenService:Create(vignette, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {ImageTransparency = 1})
		local tweenScan = TweenService:Create(scanlines, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {ImageTransparency = 1})
		local tweenCross = TweenService:Create(crosshair, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {ImageTransparency = 1})
		local tweenInfo = TweenService:Create(infoBar, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {BackgroundTransparency = 1})
		local tweenRec = TweenService:Create(recLabel, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {TextTransparency = 1})
		local tweenAlt = TweenService:Create(altLabel, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {TextTransparency = 1})
		local tweenSpd = TweenService:Create(spdLabel, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {TextTransparency = 1})

		tweenVig:Play()
		tweenScan:Play()
		tweenCross:Play()
		tweenInfo:Play()
		tweenRec:Play()
		tweenAlt:Play()
		tweenSpd:Play()

		tweenVig.Completed:Connect(function()
			overlay.Enabled = false
		end)
	end
end

-- ====================== DRONE MODEL + LOOP SOUND ======================
local function createDroneModel()
	if droneModel then droneModel:Destroy() end
	droneModel = Instance.new("Model")
	droneModel.Name = "EliteDrone"

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(3,1,3)
	body.Color = droneColors[colorIndex]
	body.Material = Enum.Material.ForceField
	body.Anchored = true
	body.CanCollide = false
	body.Parent = droneModel

	local light = Instance.new("PointLight", body)
	light.Color = droneColors[colorIndex]
	light.Brightness = 2.8
	light.Range = 12

	local armPos = {Vector3.new(2.2,0,2.2), Vector3.new(2.2,0,-2.2), Vector3.new(-2.2,0,2.2), Vector3.new(-2.2,0,-2.2)}
	for i = 1,4 do
		local arm = Instance.new("Part")
		arm.Size = Vector3.new(3.5,0.4,0.4)
		arm.Color = Color3.fromRGB(25,25,40)
		arm.Material = Enum.Material.Metal
		arm.Anchored = true
		arm.CanCollide = false
		arm.CFrame = CFrame.new(armPos[i])
		arm.Parent = droneModel
	end

	rotors = {}
	for i = 1,4 do
		local r = Instance.new("Part")
		r.Size = Vector3.new(0.25,0.12,2.8)
		r.Color = Color3.fromRGB(200,220,255)
		r.Material = Enum.Material.Neon
		r.Anchored = true
		r.CanCollide = false
		r.Parent = droneModel
		rotors[i] = r
	end

	antennas = {}
	local ant1 = Instance.new("Part", droneModel)
	ant1.Size = Vector3.new(0.15,0.15,3.5)
	ant1.Color = Color3.fromRGB(190,190,210)
	ant1.Material = Enum.Material.Metal
	ant1.Anchored = true
	antennas[1] = ant1

	local ant2 = Instance.new("Part", droneModel)
	ant2.Size = Vector3.new(0.15,2.2,0.15)
	ant2.Color = Color3.fromRGB(0,255,200)
	ant2.Material = Enum.Material.Neon
	ant2.Anchored = true
	antennas[2] = ant2

	droneModel.PrimaryPart = body
	droneModel.Parent = workspace

	propellerSound = Instance.new("Sound")
	propellerSound.SoundId = "rbxassetid://136704576012970"
	propellerSound.Volume = 0.65
	propellerSound.Looped = true
	propellerSound.Parent = body

	if miniDrone then miniDrone:Destroy() end
	miniDrone = droneModel:Clone()
	miniDrone.Parent = viewport
end

local function updateDroneColor()
	if droneModel and droneModel.PrimaryPart then
		local c = droneColors[colorIndex]
		droneModel.PrimaryPart.Color = c
		droneModel.PrimaryPart.PointLight.Color = c
	end
end

-- ====================== CONTROLES ======================
local function toggleFreeCam()
	freeCamEnabled = not freeCamEnabled
	if freeCamEnabled then
		camera.CameraType = Enum.CameraType.Scriptable
		local y,p = camera.CFrame:ToEulerAnglesYXZ()
		yaw = math.deg(y)
		pitch = math.deg(p)
		dronePosition = camera.CFrame.Position

		toggleBtn.BackgroundColor3 = Color3.fromRGB(0,255,120)
		createDroneModel()
		SetRagdoll(true)
		dpadFrame.Visible = true
		miniMapContainer.Visible = true
		propellerSound:Play()

		showDroneActivationImage()
		animateOverlay(true) -- TV LIGANDO

		chaseMode = false
		chaseBtn.BackgroundColor3 = Color3.fromRGB(100,200,255)
	else
		camera.CameraType = Enum.CameraType.Custom
		velocity = Vector3.new()
		dronePosition = Vector3.new()
		toggleBtn.BackgroundColor3 = Color3.fromRGB(0,200,255)
		if droneModel then droneModel:Destroy(); droneModel = nil end
		if miniDrone then miniDrone:Destroy(); miniDrone = nil end
		if propellerSound then propellerSound:Stop() end
		dpadFrame.Visible = false
		miniMapContainer.Visible = false
		SetRagdoll(false)
		altLock = false
		chaseMode = false
		animateOverlay(false) -- TV DESLIGANDO
	end
end
toggleBtn.Activated:Connect(toggleFreeCam)

speedUpBtn.Activated:Connect(function()
	MOVE_SPEED = math.min(MOVE_SPEED + 30, MAX_SPEED)
	speedLabel.Text = "SPD: "..math.floor(MOVE_SPEED)
end)
speedDownBtn.Activated:Connect(function()
	MOVE_SPEED = math.max(MOVE_SPEED - 30, MIN_SPEED)
	speedLabel.Text = "SPD: "..math.floor(MOVE_SPEED)
end)

altLockBtn.Activated:Connect(function()
	altLock = not altLock
	altLockBtn.Text = altLock and "🔓" or "🔒"
	altLockBtn.BackgroundColor3 = altLock and Color3.fromRGB(80,255,140) or Color3.fromRGB(255,170,50)
	if altLock then targetAltitude = dronePosition.Y end
end)

colorBtn.Activated:Connect(function()
	colorIndex = (colorIndex % #droneColors) + 1
	updateDroneColor()
end)

local function resetCamera()
	if not freeCamEnabled or not player.Character then return end
	local hrp = player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("Head")
	if hrp then
		local target = hrp.CFrame * CFrame.new(0,8,-15) * CFrame.Angles(math.rad(-20),0,0)
		local tween = TweenService:Create(camera, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {CFrame = target})
		tween:Play()
	end
end
resetBtn.Activated:Connect(resetCamera)

chaseBtn.Activated:Connect(function()
	if not freeCamEnabled then return end
	chaseMode = not chaseMode
	chaseBtn.BackgroundColor3 = chaseMode and Color3.fromRGB(255,100,100) or Color3.fromRGB(100,200,255)
	animateOverlay(not chaseMode) -- TV liga/desliga conforme o modo
end)

local hudVisible = true
hudBtn.Activated:Connect(function()
	hudVisible = not hudVisible
	local pos = hudVisible and UDim2.new(0, 18, 0, 75) or UDim2.new(0, -300, 0, 75)
	TweenService:Create(mainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quint), {Position = pos}):Play()
end)

-- ====================== UPDATE ======================
local function update(dt)
	if not freeCamEnabled then return end

	local dir = Vector3.new()
	local controlRotation = CFrame.fromEulerAnglesYXZ(math.rad(pitch), math.rad(yaw), 0)
	local controlLook = controlRotation.LookVector
	local controlRight = controlRotation.RightVector

	if moveFlags.Forward then dir += controlLook end
	if moveFlags.Back    then dir -= controlLook end
	if moveFlags.Left    then dir -= controlRight end
	if moveFlags.Right   then dir += controlRight end
	if moveFlags.FlyUp   then dir += Vector3.new(0,1,0) end
	if moveFlags.FlyDown then dir -= Vector3.new(0,1,0) end

	if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += controlLook end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= controlLook end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= controlRight end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += controlRight end
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0,1,0) end

	if dir.Magnitude > 0 then dir = dir.Unit end

	velocity = velocity:Lerp(dir * MOVE_SPEED, 17 * dt)
	local newPos = dronePosition + velocity * dt
	if altLock then newPos = Vector3.new(newPos.X, targetAltitude, newPos.Z) end

	local virtualCFrame = CFrame.new(newPos) * controlRotation
	dronePosition = newPos

	if droneModel then
		local droneCF = virtualCFrame * CFrame.new(0, -2.7, 0)
		droneModel:SetPrimaryPartCFrame(droneCF)

		for i, r in ipairs(rotors) do
			local offX = (i==1 or i==3) and 2.15 or -2.15
			local offZ = (i==1 or i==2) and 2.15 or -2.15
			r.CFrame = droneCF * CFrame.new(offX, 0.85, offZ) * CFrame.Angles(0, tick()*48*(i%2==0 and 1 or -1), 0)
		end
	end

	if chaseMode and droneModel then
		local droneCF = virtualCFrame * CFrame.new(0, -2.7, 0)
		camera.CFrame = droneCF * CFrame.new(0, 8, 20) * CFrame.Angles(math.rad(-18), 0, 0)
	else
		camera.CFrame = virtualCFrame
	end

	if droneModel and propellerSound then
		propellerSound.PlaybackSpeed = 0.85 + (velocity.Magnitude / MOVE_SPEED) * 1.65
	end

	if miniDrone and droneModel then
		local topCF = CFrame.new(droneModel.PrimaryPart.Position.X, droneModel.PrimaryPart.Position.Y + 80, droneModel.PrimaryPart.Position.Z) * CFrame.Angles(math.rad(-90), math.rad(yaw), 0)
		miniCamera.CFrame = topCF
		miniDrone:SetPrimaryPartCFrame(CFrame.new(droneModel.PrimaryPart.Position.X, 0, droneModel.PrimaryPart.Position.Z) * CFrame.Angles(0, math.rad(yaw), 0))
	end

	if overlay.Enabled then
		altLabel.Text = string.format("ALT: %03dm", math.floor(camera.CFrame.Position.Y))
		spdLabel.Text = "SPD: "..math.floor(velocity.Magnitude)
		recLabel.TextTransparency = (math.sin(tick()*10) + 1) * 0.3 + 0.2
	end
end

RunService.RenderStepped:Connect(update)

UserInputService.InputChanged:Connect(function(i, proc)
	if proc or not freeCamEnabled then return end
	if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
		yaw = yaw - i.Delta.X * SENSITIVITY
		pitch = math.clamp(pitch - i.Delta.Y * SENSITIVITY, -89, 89)
	end
end)

print("✅ ELITE DRONE v2.4 CARREGADO! Loop sound + Animação Tween + Mini Map + Chase Mode (corrigido) + HUD reposicionado + TV Animation + Overlay só no FPV!")
