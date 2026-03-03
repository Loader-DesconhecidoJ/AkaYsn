-- FREE CAM DRONE PREMIUM v2.7 + ZOOM (SÓ ZOOM - FUNCIONA SÓ NO DRONE ATIVO)
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
local FOV = 70  -- ZOOM PADRÃO

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
local thrustEmitters = {}
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
local miniDrone = nil

-- ====================== GUI + MINI MAP + D-PAD + OVERLAY ======================
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
	Instance.new("UIStroke", b).Thickness = 1.8
	Instance.new("UIStroke", b).Color = Color3.fromRGB(0,255,220)
	return b
end

local toggleBtn = newBtn("🚁", Color3.fromRGB(0,200,255))
local speedUpBtn = newBtn("SPD+")
local speedDownBtn = newBtn("SPD-")
local altLockBtn = newBtn("🔒", Color3.fromRGB(255,170,50))
local colorBtn = newBtn("🎨")
local resetBtn = newBtn("🔄")
local chaseBtn = newBtn("👁️", Color3.fromRGB(100,200,255))
local zoomInBtn  = newBtn("🔎+", Color3.fromRGB(0,255,180))   -- NOVO BOTÃO ZOOM +
local zoomOutBtn = newBtn("🔎-", Color3.fromRGB(0,255,180))   -- NOVO BOTÃO ZOOM -

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

-- MINI MAP (mantido igual)
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

-- D-PAD (mantido igual)
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

-- FPV OVERLAY + ANIMAÇÕES (igual)
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

-- ====================== DRONE MODEL PREMIUM v2.7 ======================
local function createDroneModel()
	if droneModel then droneModel:Destroy() end
	droneModel = Instance.new("Model")
	droneModel.Name = "EliteDronePremium_v2.7"

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(4.2, 1.35, 4.2)
	body.Color = Color3.fromRGB(18, 20, 28)
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.Parent = droneModel

	local topPlate = Instance.new("Part")
	topPlate.Size = Vector3.new(3.8, 0.25, 3.8)
	topPlate.Color = droneColors[colorIndex]
	topPlate.Material = Enum.Material.Neon
	topPlate.Anchored = true
	topPlate.CanCollide = false
	topPlate.CFrame = body.CFrame * CFrame.new(0, 0.85, 0)
	topPlate.Parent = droneModel

	rotors = {}
	thrustEmitters = {}
	local armOffsets = {Vector3.new(2.4,0,2.4), Vector3.new(2.4,0,-2.4), Vector3.new(-2.4,0,2.4), Vector3.new(-2.4,0,-2.4)}

	for i = 1,4 do
		local offset = armOffsets[i]
		local angle = (i-1)*90

		local arm = Instance.new("Part")
		arm.Size = Vector3.new(5.2, 0.55, 1.15)
		arm.Color = Color3.fromRGB(22,24,32)
		arm.Material = Enum.Material.SmoothPlastic
		arm.Anchored = true
		arm.CanCollide = false
		arm.CFrame = body.CFrame * CFrame.new(offset) * CFrame.Angles(0, math.rad(angle + 45), 0) * CFrame.new(2.6, 0, 0)
		arm.Parent = droneModel

		local ledStrip = Instance.new("Part")
		ledStrip.Size = Vector3.new(4.8, 0.12, 0.12)
		ledStrip.Color = droneColors[colorIndex]
		ledStrip.Material = Enum.Material.Neon
		ledStrip.Anchored = true
		ledStrip.CanCollide = false
		ledStrip.CFrame = arm.CFrame * CFrame.new(0, 0.4, 0)
		ledStrip.Parent = droneModel

		local motor = Instance.new("Part")
		motor.Size = Vector3.new(1.35, 0.95, 1.35)
		motor.Color = Color3.fromRGB(30,32,40)
		motor.Material = Enum.Material.Metal
		motor.Anchored = true
		motor.CanCollide = false
		motor.CFrame = arm.CFrame * CFrame.new(3.1, 0.45, 0)
		motor.Parent = droneModel

		for a = -1,1 do
			local fin = Instance.new("Part")
			fin.Size = Vector3.new(0.1, 0.7, 1.4)
			fin.Color = Color3.fromRGB(45,45,55)
			fin.Material = Enum.Material.Metal
			fin.Anchored = true
			fin.CanCollide = false
			fin.CFrame = motor.CFrame * CFrame.new(0, 0.3, a*0.45)
			fin.Parent = droneModel
		end

		local blades = {}
		for b = 1,3 do
			local blade = Instance.new("Part")
			blade.Size = Vector3.new(0.22, 0.09, 6.8)
			blade.Color = Color3.fromRGB(235, 245, 255)
			blade.Material = Enum.Material.Neon
			blade.Anchored = true
			blade.CanCollide = false
			blade.Parent = droneModel
			table.insert(blades, blade)
		end

		local guard = Instance.new("Part")
		guard.Shape = Enum.PartType.Cylinder
		guard.Size = Vector3.new(7.8, 0.35, 7.8)
		guard.Color = Color3.fromRGB(40,42,50)
		guard.Material = Enum.Material.Metal
		guard.Anchored = true
		guard.CanCollide = false
		guard.CFrame = motor.CFrame * CFrame.new(0,0.6,0) * CFrame.Angles(math.rad(90),0,0)
		guard.Parent = droneModel

		local attach = Instance.new("Attachment", motor)
		attach.Position = Vector3.new(0, -0.8, 0)

		local thrust = Instance.new("ParticleEmitter", attach)
		thrust.Texture = "rbxassetid://243660364"
		thrust.Color = ColorSequence.new(Color3.fromRGB(180,230,255))
		thrust.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.8), NumberSequenceKeypoint.new(1,0.1)})
		thrust.Transparency = NumberSequence.new(0.4,1)
		thrust.Lifetime = NumberRange.new(0.2,0.4)
		thrust.Rate = 0
		thrust.Speed = NumberRange.new(20,40)
		thrust.SpreadAngle = Vector2.new(30,30)
		thrust.Acceleration = Vector3.new(0,-25,0)
		thrust.Enabled = true

		table.insert(thrustEmitters, thrust)
		rotors[i] = {blades = blades, motor = motor}
	end

	local gimbalBase = Instance.new("Part")
	gimbalBase.Size = Vector3.new(1.6, 1.1, 1.8)
	gimbalBase.Color = Color3.fromRGB(22,22,28)
	gimbalBase.Material = Enum.Material.Metal
	gimbalBase.Anchored = true
	gimbalBase.CanCollide = false
	gimbalBase.CFrame = body.CFrame * CFrame.new(0, -1.3, 0)
	gimbalBase.Parent = droneModel

	local cameraMount = Instance.new("Part")
	cameraMount.Size = Vector3.new(1.1, 0.95, 1.3)
	cameraMount.Color = Color3.fromRGB(15,15,22)
	cameraMount.Material = Enum.Material.Metal
	cameraMount.Anchored = true
	cameraMount.CanCollide = false
	cameraMount.CFrame = gimbalBase.CFrame * CFrame.new(0, -0.85, 0)
	cameraMount.Parent = droneModel

	local lens = Instance.new("Part")
	lens.Size = Vector3.new(0.85, 0.85, 0.4)
	lens.Color = Color3.fromRGB(8,8,12)
	lens.Material = Enum.Material.Glass
	lens.Transparency = 0.25
	lens.Anchored = true
	lens.CanCollide = false
	lens.CFrame = cameraMount.CFrame * CFrame.new(0, 0, -0.95)
	lens.Parent = droneModel

	for side = -1,1,2 do
		local skid = Instance.new("Part")
		skid.Size = Vector3.new(0.5, 0.35, 5.5)
		skid.Color = Color3.fromRGB(28,30,38)
		skid.Material = Enum.Material.Metal
		skid.Anchored = true
		skid.CanCollide = false
		skid.CFrame = body.CFrame * CFrame.new(side*1.85, -1.85, 0) * CFrame.Angles(math.rad(6),0,0)
		skid.Parent = droneModel
	end

	local mainLight = Instance.new("PointLight", body)
	mainLight.Color = droneColors[colorIndex]
	mainLight.Brightness = 4.8
	mainLight.Range = 24

	droneModel.PrimaryPart = body
	droneModel.Parent = workspace

	if propellerSound then propellerSound:Destroy() end
	propellerSound = Instance.new("Sound")
	propellerSound.SoundId = "rbxassetid://136704576012970"
	propellerSound.Volume = 0.88
	propellerSound.Looped = true
	propellerSound.Parent = body
end

local function updateDroneColor()
	if not droneModel then return end
	local c = droneColors[colorIndex]
	droneModel.Body.PointLight.Color = c
	for _, desc in pairs(droneModel:GetDescendants()) do
		if desc:IsA("Part") and (desc.Material == Enum.Material.Neon or desc.Name:find("Neon")) then
			desc.Color = c
		end
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
		dpadFrame.Visible = true
		miniMapContainer.Visible = true
		propellerSound:Play()

		showDroneActivationImage()
		animateOverlay(true)
		chaseMode = false
		chaseBtn.BackgroundColor3 = Color3.fromRGB(100,200,255)
	else
		camera.CameraType = Enum.CameraType.Custom
		velocity = Vector3.new()
		dronePosition = Vector3.new()
		FOV = 70
		camera.FieldOfView = 70  -- ZOOM VOLTA AO NORMAL
		toggleBtn.BackgroundColor3 = Color3.fromRGB(0,200,255)

		if droneModel then droneModel:Destroy() droneModel = nil end
		if miniDrone then miniDrone:Destroy() miniDrone = nil end
		if propellerSound then propellerSound:Stop() end

		dpadFrame.Visible = false
		miniMapContainer.Visible = false
		altLock = false
		chaseMode = false
		animateOverlay(false)
	end
end
toggleBtn.Activated:Connect(toggleFreeCam)

-- ZOOM SÓ FUNCIONA NO DRONE ATIVO
zoomInBtn.Activated:Connect(function()
	if not freeCamEnabled then return end
	FOV = math.max(20, FOV - 12)
	camera.FieldOfView = FOV
end)

zoomOutBtn.Activated:Connect(function()
	if not freeCamEnabled then return end
	FOV = math.min(110, FOV + 12)
	camera.FieldOfView = FOV
end)

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
		TweenService:Create(camera, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {CFrame = target}):Play()
	end
end
resetBtn.Activated:Connect(resetCamera)

chaseBtn.Activated:Connect(function()
	if not freeCamEnabled then return end
	chaseMode = not chaseMode
	chaseBtn.BackgroundColor3 = chaseMode and Color3.fromRGB(255,100,100) or Color3.fromRGB(100,200,255)
	animateOverlay(not chaseMode)
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

	camera.FieldOfView = FOV  -- mantem o zoom enquanto drone ativo

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
		local droneCF = virtualCFrame * CFrame.new(0, -2.8, 0)
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
		local droneCF = virtualCFrame * CFrame.new(0, -2.8, 0)
		camera.CFrame = droneCF * CFrame.new(0, 9, 22) * CFrame.Angles(math.rad(-18), 0, 0)
	else
		camera.CFrame = virtualCFrame
	end

	if droneModel and propellerSound then
		propellerSound.PlaybackSpeed = 0.85 + (velocity.Magnitude / MOVE_SPEED) * 1.7
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

print("✅ ELITE DRONE v2.7 + ZOOM CARREGADO! (Zoom só no drone + reseta automático)")
