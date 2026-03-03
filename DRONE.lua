-- FREE CAM DRONE PREMIUM v2.9 + ZOOM (Spawn separado de Controle)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local playerGui = player:WaitForChild("PlayerGui")

local MOVE_SPEED = 130
local MAX_SPEED = 420
local MIN_SPEED = 55
local SENSITIVITY = 0.65
local FOV = 72

local droneSpawned = false
local inControl = false
local velocity = Vector3.new()
local yaw = 0
local pitch = 0
local dronePosition = Vector3.new()
local homePosition = Vector3.new()

local altLock = false
local targetAltitude = 0

local lightsOn = true

local moveFlags = {
	Forward = false, Back = false,
	Left = false, Right = false,
	FlyUp = false, FlyDown = false
}

local droneModel = nil
local rotors = {}
local thrustEmitters = {}
local propellerSound = nil
local colorIndex = 1
local droneColors = {
	Color3.fromRGB(0, 255, 240),
	Color3.fromRGB(255, 60, 180),
	Color3.fromRGB(80, 255, 120),
	Color3.fromRGB(255, 200, 40),
	Color3.fromRGB(160, 80, 255)
}

local chaseMode = false

-- ====================== PREMIUM HUD ======================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "EliteDronePremiumUI_v2.9"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 245, 0, 325)
mainFrame.Position = UDim2.new(0, 18, 0, 70)
mainFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 18)
mainFrame.BackgroundTransparency = 0.35
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 20)

local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Thickness = 2
mainStroke.Color = Color3.fromRGB(0, 255, 200)

local titleBar = Instance.new("Frame", mainFrame)
titleBar.Size = UDim2.new(1, 0, 0, 46)
titleBar.BackgroundColor3 = Color3.fromRGB(12, 12, 26)
titleBar.Parent = mainFrame
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 20)

local titleGradient = Instance.new("UIGradient", titleBar)
titleGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(0,255,200)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(200,60,255))
}

local titleLabel = Instance.new("TextLabel", titleBar)
titleLabel.Size = UDim2.new(1,0,1,0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "ELITE DRONE"
titleLabel.TextColor3 = Color3.new(1,1,1)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBlack

local versionLabel = Instance.new("TextLabel", titleBar)
versionLabel.Size = UDim2.new(0,90,0,16)
versionLabel.Position = UDim2.new(1,-98,0.5,-8)
versionLabel.BackgroundTransparency = 1
versionLabel.Text = "v2.9 PREMIUM"
versionLabel.TextColor3 = Color3.fromRGB(0,255,200)
versionLabel.TextScaled = true
versionLabel.Font = Enum.Font.GothamBold

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.new(0, 52, 0, 52)
grid.CellPadding = UDim2.new(0, 12, 0, 12)
grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
grid.VerticalAlignment = Enum.VerticalAlignment.Top
grid.Parent = mainFrame

local function createPremiumButton(icon, col)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0,52,0,52)
	b.BackgroundColor3 = col or Color3.fromRGB(18,18,38)
	b.Text = icon
	b.TextColor3 = Color3.new(1,1,1)
	b.TextScaled = true
	b.Font = Enum.Font.GothamBold
	b.BackgroundTransparency = 0.3
	b.Parent = mainFrame
	
	Instance.new("UICorner", b).CornerRadius = UDim.new(0,16)
	local s = Instance.new("UIStroke", b)
	s.Thickness = 1.8
	s.Color = Color3.fromRGB(0,255,220)
	
	b.MouseEnter:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Size = UDim2.new(0,57,0,57), BackgroundTransparency = 0.2}):Play()
	end)
	b.MouseLeave:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Size = UDim2.new(0,52,0,52), BackgroundTransparency = 0.3}):Play()
	end)
	b.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			TweenService:Create(b, TweenInfo.new(0.09, Enum.EasingStyle.Quad), {Size = UDim2.new(0,46,0,46)}):Play()
		end
	end)
	b.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			TweenService:Create(b, TweenInfo.new(0.18, Enum.EasingStyle.Back), {Size = UDim2.new(0,52,0,52)}):Play()
		end
	end)
	return b
end

local spawnBtn     = createPremiumButton("🚁", Color3.fromRGB(0,220,255))
local controlBtn   = createPremiumButton("🕹️", Color3.fromRGB(255,70,100))
local speedUpBtn   = createPremiumButton("SPD+", Color3.fromRGB(50,50,80))
local speedDownBtn = createPremiumButton("SPD-", Color3.fromRGB(50,50,80))
local altLockBtn   = createPremiumButton("🔒", Color3.fromRGB(255,160,40))
local colorBtn     = createPremiumButton("🎨")
local chaseBtn     = createPremiumButton("👁️", Color3.fromRGB(140,80,255))
local zoomInBtn    = createPremiumButton("🔎+", Color3.fromRGB(0,255,180))
local zoomOutBtn   = createPremiumButton("🔎-", Color3.fromRGB(0,255,180))
local lightsBtn    = createPremiumButton("💡", Color3.fromRGB(255,200,60))
local homeBtn      = createPremiumButton("🏠", Color3.fromRGB(80,220,255))

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1,-24,0,30)
speedLabel.Position = UDim2.new(0,12,1,-42)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "SPEED: 130"
speedLabel.TextColor3 = Color3.fromRGB(0,255,200)
speedLabel.TextScaled = true
speedLabel.Font = Enum.Font.GothamBlack
speedLabel.Parent = mainFrame

local hudBtn = createPremiumButton("≡", Color3.fromRGB(30,30,55))
hudBtn.Size = UDim2.new(0,48,0,48)
hudBtn.Position = UDim2.new(0, 24, 0, 14)
hudBtn.Parent = screenGui

-- ====================== D-PAD PREMIUM (Glassmorphism + Neon Cyber) ======================
local dpadFrame = Instance.new("Frame")
dpadFrame.Size = UDim2.new(0, 255, 0, 235)
dpadFrame.Position = UDim2.new(0, 22, 1, -270)
dpadFrame.BackgroundColor3 = Color3.fromRGB(9,9,22)
dpadFrame.BackgroundTransparency = 0.45
dpadFrame.Visible = false
dpadFrame.Parent = screenGui
Instance.new("UICorner", dpadFrame).CornerRadius = UDim.new(0,24)
local dpadStroke = Instance.new("UIStroke", dpadFrame)
dpadStroke.Thickness = 2.4
dpadStroke.Color = Color3.fromRGB(0,255,220)

-- Header Premium
local dpadHeader = Instance.new("Frame", dpadFrame)
dpadHeader.Size = UDim2.new(1,0,0,38)
dpadHeader.BackgroundColor3 = Color3.fromRGB(12,12,28)
dpadHeader.BackgroundTransparency = 0.3
dpadHeader.Parent = dpadFrame
Instance.new("UICorner", dpadHeader).CornerRadius = UDim.new(0,20)

local dpadTitle = Instance.new("TextLabel", dpadHeader)
dpadTitle.Size = UDim2.new(1,0,1,0)
dpadTitle.BackgroundTransparency = 1
dpadTitle.Text = "FLIGHT CONTROLS"
dpadTitle.TextColor3 = Color3.fromRGB(0,255,200)
dpadTitle.TextScaled = true
dpadTitle.Font = Enum.Font.GothamBlack
local dpadTitleGrad = Instance.new("UIGradient", dpadTitle)
dpadTitleGrad.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(0,255,240)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(100,220,255))
}

local function createDPadButton(txt, pos, size)
	local btn = Instance.new("TextButton")
	btn.Size = size or UDim2.new(0,54,0,54)
	btn.Position = pos
	btn.BackgroundColor3 = Color3.fromRGB(14,18,36)
	btn.Text = txt
	btn.TextColor3 = Color3.new(1,1,1)
	btn.TextScaled = true
	btn.Font = Enum.Font.GothamBold
	btn.BackgroundTransparency = 0.25
	btn.Parent = dpadFrame
	
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0,16)
	local s = Instance.new("UIStroke", btn)
	s.Thickness = 2.2
	s.Color = Color3.fromRGB(0,255,255)
	
	local grad = Instance.new("UIGradient", btn)
	grad.Color = ColorSequence.new(Color3.fromRGB(0,255,255), Color3.fromRGB(80,220,255))
	grad.Rotation = 90
	
	btn.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			TweenService:Create(btn, TweenInfo.new(0.08), {BackgroundTransparency = 0.1, Size = UDim2.new(0,48,0,48)}):Play()
		end
	end)
	btn.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			TweenService:Create(btn, TweenInfo.new(0.22, Enum.EasingStyle.Back), {BackgroundTransparency = 0.25, Size = UDim2.new(0,54,0,54)}):Play()
		end
	end)
	return btn
end

local fwdBtn    = createDPadButton("↑",   UDim2.new(0.5, -27, 0, 48))
local backBtn   = createDPadButton("↓",   UDim2.new(0.5, -27, 1, -68))
local leftBtn   = createDPadButton("←",   UDim2.new(0, 10, 0.5, -27))
local rightBtn  = createDPadButton("→",   UDim2.new(1, -66, 0.5, -27))
local flyUpBtn  = createDPadButton("🡅",   UDim2.new(1, 8, 0, 46), UDim2.new(0,48,0,48))
local flyDownBtn= createDPadButton("🡇",   UDim2.new(1, 8, 1, -82), UDim2.new(0,48,0,48))

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

-- FPV OVERLAY (mantido)
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

	local tweenIn = TweenService:Create(img, TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 420, 0, 280), ImageTransparency = 0.12})
	tweenIn:Play()

	task.delay(1.8, function()
		local tweenOut = TweenService:Create(img, TweenInfo.new(0.65, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Size = UDim2.new(0, 180, 0, 120), ImageTransparency = 1})
		tweenOut:Play()
		tweenOut.Completed:Connect(function() img:Destroy() end)
	end)
end

local function animateOverlay(enable)
	if enable then
		overlay.Enabled = true
		vignette.ImageTransparency = 1
		scanlines.ImageTransparency = 1
		crosshair.ImageTransparency = 1
		infoBar.BackgroundTransparency = 1
		recLabel.TextTransparency = 1
		altLabel.TextTransparency = 1
		spdLabel.TextTransparency = 1

		TweenService:Create(vignette, TweenInfo.new(0.65, Enum.EasingStyle.Quint), {ImageTransparency = 0.35}):Play()
		TweenService:Create(scanlines, TweenInfo.new(0.75, Enum.EasingStyle.Quint), {ImageTransparency = 0.8}):Play()
		TweenService:Create(crosshair, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {ImageTransparency = 0.5}):Play()
		TweenService:Create(infoBar, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.65}):Play()
		TweenService:Create(recLabel, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
		TweenService:Create(altLabel, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
		TweenService:Create(spdLabel, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
	else
		local tVig = TweenService:Create(vignette, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {ImageTransparency = 1})
		local tScan = TweenService:Create(scanlines, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {ImageTransparency = 1})
		local tCross = TweenService:Create(crosshair, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {ImageTransparency = 1})
		local tInfo = TweenService:Create(infoBar, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {BackgroundTransparency = 1})
		local tRec = TweenService:Create(recLabel, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {TextTransparency = 1})
		local tAlt = TweenService:Create(altLabel, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {TextTransparency = 1})
		local tSpd = TweenService:Create(spdLabel, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {TextTransparency = 1})

		tVig:Play() tScan:Play() tCross:Play() tInfo:Play() tRec:Play() tAlt:Play() tSpd:Play()
		tVig.Completed:Connect(function() overlay.Enabled = false end)
	end
end

-- ====================== DRONE MODEL PREMIUM ======================
local function createDroneModel()
	if droneModel then droneModel:Destroy() end
	droneModel = Instance.new("Model")
	droneModel.Name = "EliteFPV_Premium_v2.9"

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(3.85, 1.15, 3.85)
	body.Color = Color3.fromRGB(14,16,22)
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.Parent = droneModel

	local topPlate = Instance.new("Part")
	topPlate.Size = Vector3.new(3.5, 0.25, 3.5)
	topPlate.Color = droneColors[colorIndex]
	topPlate.Material = Enum.Material.Neon
	topPlate.Anchored = true
	topPlate.CFrame = body.CFrame * CFrame.new(0, 0.75, 0)
	topPlate.Parent = droneModel

	rotors = {}
	thrustEmitters = {}
	local armAngles = {45, 135, 225, 315}

	for i, ang in ipairs(armAngles) do
		local arm = Instance.new("Part")
		arm.Size = Vector3.new(7.2, 0.68, 1.55)
		arm.Color = Color3.fromRGB(18,20,26)
		arm.Material = Enum.Material.SmoothPlastic
		arm.Anchored = true
		arm.CFrame = body.CFrame * CFrame.Angles(0, math.rad(ang), 0) * CFrame.new(3.4, 0.15, 0)
		arm.Parent = droneModel

		local motor = Instance.new("Part")
		motor.Size = Vector3.new(1.75, 1.35, 1.75)
		motor.Color = Color3.fromRGB(26,28,36)
		motor.Material = Enum.Material.Metal
		motor.Anchored = true
		motor.CFrame = arm.CFrame * CFrame.new(3.6, 0.5, 0)
		motor.Parent = droneModel

		local guard = Instance.new("Part")
		guard.Shape = Enum.PartType.Cylinder
		guard.Size = Vector3.new(8.8, 0.5, 8.8)
		guard.Color = Color3.fromRGB(32,34,42)
		guard.Material = Enum.Material.Metal
		guard.Anchored = true
		guard.CFrame = motor.CFrame * CFrame.new(0,0.85,0) * CFrame.Angles(math.rad(90),0,0)
		guard.Parent = droneModel

		local blades = {}
		for b = 1,3 do
			local blade = Instance.new("Part")
			blade.Size = Vector3.new(0.32, 0.11, 8.1)
			blade.Color = Color3.fromRGB(225,240,255)
			blade.Material = Enum.Material.Neon
			blade.Anchored = true
			blade.Parent = droneModel
			table.insert(blades, blade)
		end

		local attach = Instance.new("Attachment", motor)
		attach.Position = Vector3.new(0,-0.95,0)

		local thrust = Instance.new("ParticleEmitter", attach)
		thrust.Texture = "rbxassetid://243660364"
		thrust.Color = ColorSequence.new(Color3.fromRGB(120,255,255))
		thrust.Size = NumberSequence.new(1.4, 0.25)
		thrust.Transparency = NumberSequence.new(0.2,1)
		thrust.Lifetime = NumberRange.new(0.3,0.55)
		thrust.Rate = 0
		thrust.Speed = NumberRange.new(28,62)
		thrust.Acceleration = Vector3.new(0,-32,0)
		thrust.Enabled = true
		table.insert(thrustEmitters, thrust)

		rotors[i] = {blades = blades, motor = motor}
	end

	local gimbal = Instance.new("Part")
	gimbal.Size = Vector3.new(1.95, 1.55, 2.3)
	gimbal.Color = Color3.fromRGB(22,22,29)
	gimbal.Material = Enum.Material.Metal
	gimbal.Anchored = true
	gimbal.CFrame = body.CFrame * CFrame.new(0, -1.45, 0)
	gimbal.Parent = droneModel

	local lens = Instance.new("Part")
	lens.Size = Vector3.new(1.25, 1.25, 0.75)
	lens.Color = Color3.fromRGB(6,6,10)
	lens.Material = Enum.Material.Glass
	lens.Transparency = 0.18
	lens.Anchored = true
	lens.CFrame = gimbal.CFrame * CFrame.new(0, -0.95, -1.25)
	lens.Parent = droneModel

	local antenna = Instance.new("Part")
	antenna.Size = Vector3.new(0.18, 3.1, 0.18)
	antenna.Color = Color3.fromRGB(210,210,210)
	antenna.Material = Enum.Material.Metal
	antenna.CFrame = body.CFrame * CFrame.new(0, 2.1, 0)
	antenna.Parent = droneModel

	local mainLight = Instance.new("PointLight", body)
	mainLight.Color = droneColors[colorIndex]
	mainLight.Brightness = 6
	mainLight.Range = 32

	droneModel.PrimaryPart = body
	droneModel.Parent = workspace

	if propellerSound then propellerSound:Destroy() end
	propellerSound = Instance.new("Sound")
	propellerSound.SoundId = "rbxassetid://136704576012970"
	propellerSound.Volume = 0.93
	propellerSound.Looped = true
	propellerSound.Parent = body
end

local function updateDroneColor()
	if not droneModel then return end
	local c = droneColors[colorIndex]
	for _, p in pairs(droneModel:GetDescendants()) do
		if p:IsA("PointLight") or (p:IsA("Part") and p.Material == Enum.Material.Neon) then
			p.Color = c
		end
	end
end

local function resetToPlayerCamera()
	camera.CameraType = Enum.CameraType.Custom
	task.wait(0.04)
	if player.Character and player.Character:FindFirstChild("Humanoid") then
		camera.CameraSubject = player.Character.Humanoid
	end
	camera.FieldOfView = 70
end

-- ====================== CONTROLES ======================
local function toggleDroneSpawn()
	droneSpawned = not droneSpawned
	if droneSpawned then
		createDroneModel()
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		dronePosition = (hrp and hrp.Position or camera.CFrame.Position) + Vector3.new(0,9,15)
		homePosition = dronePosition
		yaw = 0
		pitch = 0
		droneModel:SetPrimaryPartCFrame(CFrame.new(dronePosition) * CFrame.Angles(0, math.rad(yaw), 0) * CFrame.new(0,-2.4,0))
		
		spawnBtn.BackgroundColor3 = Color3.fromRGB(0,255,140)
		if propellerSound then propellerSound:Play() end
		showDroneActivationImage()
	else
		if inControl then toggleControl() end
		if droneModel then droneModel:Destroy() droneModel = nil end
		if propellerSound then propellerSound:Stop() end
		resetToPlayerCamera()
		spawnBtn.BackgroundColor3 = Color3.fromRGB(0,220,255)
	end
end

local function toggleControl()
	if not droneSpawned or not droneModel then return end
	inControl = not inControl
	
	if inControl then
		camera.CameraType = Enum.CameraType.Scriptable
		local body = droneModel:FindFirstChild("Body")
		if body then
			dronePosition = body.Position + Vector3.new(0, 3, 0)
		end
		local yRad, pRad = droneModel.PrimaryPart.CFrame:ToEulerAnglesYXZ()
		yaw = math.deg(yRad)
		pitch = math.deg(pRad)
		
		dpadFrame.Visible = true
		animateOverlay(true)
		controlBtn.BackgroundColor3 = Color3.fromRGB(0,255,140)
	else
		resetToPlayerCamera()
		velocity = Vector3.new()
		dpadFrame.Visible = false
		animateOverlay(false)
		controlBtn.BackgroundColor3 = Color3.fromRGB(255,70,100)
	end
end

spawnBtn.Activated:Connect(toggleDroneSpawn)
controlBtn.Activated:Connect(toggleControl)
speedUpBtn.Activated:Connect(function() if not inControl then return end MOVE_SPEED = math.min(MOVE_SPEED + 30, MAX_SPEED) speedLabel.Text = "SPEED: "..math.floor(MOVE_SPEED) end)
speedDownBtn.Activated:Connect(function() if not inControl then return end MOVE_SPEED = math.max(MOVE_SPEED - 30, MIN_SPEED) speedLabel.Text = "SPEED: "..math.floor(MOVE_SPEED) end)
altLockBtn.Activated:Connect(function() 
	if not inControl then return end 
	altLock = not altLock 
	altLockBtn.Text = altLock and "🔓" or "🔒" 
	altLockBtn.BackgroundColor3 = altLock and Color3.fromRGB(80,255,140) or Color3.fromRGB(255,160,40)
	if altLock then targetAltitude = dronePosition.Y end 
end)
colorBtn.Activated:Connect(function() if not inControl then return end colorIndex = (colorIndex % #droneColors) + 1 updateDroneColor() end)
chaseBtn.Activated:Connect(function() 
	if not inControl then return end 
	chaseMode = not chaseMode 
	chaseBtn.BackgroundColor3 = chaseMode and Color3.fromRGB(255,70,100) or Color3.fromRGB(140,80,255) 
	animateOverlay(not chaseMode) 
end)
zoomInBtn.Activated:Connect(function() if not inControl then return end FOV = math.max(20, FOV - 12) camera.FieldOfView = FOV end)
zoomOutBtn.Activated:Connect(function() if not inControl then return end FOV = math.min(110, FOV + 12) camera.FieldOfView = FOV end)

lightsBtn.Activated:Connect(function()
	if not inControl or not droneModel then return end
	lightsOn = not lightsOn
	for _, desc in pairs(droneModel:GetDescendants()) do
		if desc:IsA("PointLight") then
			desc.Brightness = lightsOn and 6 or 0
		end
	end
end)

homeBtn.Activated:Connect(function()
	if not inControl then return end
	dronePosition = homePosition + Vector3.new(0, 6, 0)
	velocity = Vector3.new()
end)

local hudVisible = true
hudBtn.Activated:Connect(function()
	hudVisible = not hudVisible
	local pos = hudVisible and UDim2.new(0, 18, 0, 70) or UDim2.new(0, -300, 0, 70)
	TweenService:Create(mainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quint), {Position = pos}):Play()
end)

-- ====================== UPDATE ======================
local function update(dt)
	if not inControl then return end

	camera.FieldOfView = FOV

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
		local droneCF = virtualCFrame * CFrame.new(0, -2.4, 0)
		droneModel:SetPrimaryPartCFrame(droneCF)

		local finalSpeed = MOVE_SPEED
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
			finalSpeed = MOVE_SPEED * 1.85
		end

		local spinSpeed = 52 + (velocity.Magnitude / finalSpeed) * 92
		for _, data in ipairs(rotors) do
			local blades = data.blades
			local motor = data.motor
			local rotorCF = motor.CFrame
			local spin = tick() * spinSpeed * (math.random(1,2) == 1 and 1 or -1)

			for b, blade in ipairs(blades) do
				local offset = (b-1) * math.rad(120)
				blade.CFrame = rotorCF * CFrame.Angles(0, spin + offset, math.rad(6))
			end
		end

		local thrustPower = math.clamp(velocity.Magnitude / finalSpeed * 210 + 35, 35, 320)
		for _, emitter in ipairs(thrustEmitters) do
			emitter.Rate = thrustPower
			emitter.Speed = NumberRange.new(thrustPower/9, thrustPower/5.5)
		end
	end

	if chaseMode and droneModel then
		camera.CFrame = droneModel.PrimaryPart.CFrame * CFrame.new(0, 9, 22) * CFrame.Angles(math.rad(-18), 0, 0)
	else
		camera.CFrame = virtualCFrame
	end

	if propellerSound then
		propellerSound.PlaybackSpeed = 0.85 + (velocity.Magnitude / MOVE_SPEED) * 1.7
	end

	if overlay.Enabled then
		altLabel.Text = string.format("ALT: %03dm", math.floor(camera.CFrame.Position.Y))
		spdLabel.Text = "SPD: "..math.floor(velocity.Magnitude)
		recLabel.TextTransparency = (math.sin(tick()*10) + 1) * 0.3 + 0.2
	end
end

RunService.RenderStepped:Connect(update)

UserInputService.InputChanged:Connect(function(i, proc)
	if proc or not inControl then return end
	if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
		yaw = yaw - i.Delta.X * SENSITIVITY
		pitch = math.clamp(pitch - i.Delta.Y * SENSITIVITY, -89, 89)
	end
end)

print("✅ ELITE DRONE PREMIUM v2.9 CARREGADO COM SUCESSO!")
