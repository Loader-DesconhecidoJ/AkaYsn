local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hum = character:WaitForChild("Humanoid")

local STAND_OFFSET = Vector3.new(3, 2.5, 2.5)
local isTimeStopped = false
local isStandActive = false
local isAttacking = false
local currentStand = nil
local idleTrack = nil
local frozenParts = {}
local mudaComboCount = 0 
local comboDisplay = nil 
local comboTweens = {} 

local COLORS = {
	Yellow = Color3.fromRGB(255, 215, 0),
	Green = Color3.fromRGB(0, 0, 0),
	Purple = Color3.fromRGB(0, 0, 0),
	Black = Color3.fromRGB(0, 0, 0)
}

local ASSETS = {
	TS_START_SFX = "rbxassetid://7514417921",
	TS_END_SFX = "rbxassetid://97139043906890",
	ANIM_DIO = "rbxassetid://84289147684815",
	STAND_IDLE = "rbxassetid://123349905320515",
	TS_RESUME_IMAGE = "rbxassetid://106168449328933",
	MUDA_SOUND = "rbxassetid://616593932",
	KNIFE_THROW_SOUND = "rbxassetid://4415007771",
	KNIFE_HIT_SOUND = "rbxassetid://743521337",
	BARRAGE_ANIM = "rbxassetid://90073013818806",
	KNIFE_THROW_ANIM = "rbxassetid://109638015126982",
	PLAYER_BARRAGE = "rbxassetid://105746954691593",
	TS_IMAGE = "rbxassetid://107526909795121",
	STAND_IMAGE = "rbxassetid://71063600838165",
	KNIFE_IMAGE = "rbxassetid://128478684091020",
	ROAD_ROLLER_MESH = "rbxassetid://123055050240257",
	ROAD_ROLLER_TEXTURE = "rbxassetid://70977204379919",
	ROAD_ROLLER_DA = "124648495201789",
	ROAD_ROLLER_SPAWN_SFX = "rbxassetid://6273171415",        
	ROAD_ROLLER_IMPACT_SFX1 = "rbxassetid://122293342039104", 
	ROAD_ROLLER_IMPACT_SFX2 = "rbxassetid://138680390593747", 
	ROAD_ROLLER_RIDE_ANIM = "rbxassetid://140327538515031" 
}

local FINISHER_HEALTH_THRESHOLD = 20     
local FINISHER_DURATION = 2              

local isFinisherActive = false
local finisherConnection = nil
local noclipFinisherConn = nil
local finisherTargetRoot = nil

local function endFinisher()
	if finisherConnection then
		finisherConnection:Disconnect()
		finisherConnection = nil
	end
	if noclipFinisherConn then
		noclipFinisherConn:Disconnect()
		noclipFinisherConn = nil
	end
	
	isFinisherActive = false
	finisherTargetRoot = nil
	
	local myRoot = character:FindFirstChild("HumanoidRootPart")
	if myRoot then
		myRoot.Velocity = Vector3.new(0, 0, 0)
		myRoot.CFrame = myRoot.CFrame + Vector3.new(3, 6, 0)  
	end
	
	if finisherTargetRoot and finisherTargetRoot.Parent then
		for _, part in ipairs(finisherTargetRoot.Parent:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = true
			end
		end
	end
end

local function startFinisher(targetRoot)
	if isFinisherActive or not targetRoot then return end
	
	isFinisherActive = true
	finisherTargetRoot = targetRoot
	
	local myRoot = character:FindFirstChild("HumanoidRootPart")
	if not myRoot then return end
	
	myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 0)
	
	noclipFinisherConn = RunService.Stepped:Connect(function()
		if not finisherTargetRoot or not finisherTargetRoot.Parent then return end
		for _, part in ipairs(finisherTargetRoot.Parent:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false   
			end
		end
	end)
	
	finisherConnection = RunService.Heartbeat:Connect(function()
		if not myRoot or not finisherTargetRoot or not finisherTargetRoot.Parent then return end
		local oldVel = myRoot.Velocity
		myRoot.Velocity = oldVel * 14800 + Vector3.new(0, 17200, 0)   
		RunService.RenderStepped:Wait()
		myRoot.Velocity = oldVel * 0.5
	end)
	
	task.delay(FINISHER_DURATION, function()
		if isFinisherActive then
			endFinisher()
		end
	end)
end

local screenGui = Instance.new("ScreenGui", player.PlayerGui)
screenGui.Name = "DioStandUniversal"
screenGui.ResetOnSpawn = false

local function showComboCounter()
	for _, tween in ipairs(comboTweens) do
		if tween then tween:Cancel() end
	end
	comboTweens = {}
	
	if comboDisplay then
		comboDisplay:Destroy()
	end
	
	comboDisplay = Instance.new("TextLabel")
	comboDisplay.Name = "MudaComboHUD"
	comboDisplay.Size = UDim2.new(0, 60, 0, 25)
	comboDisplay.Position = UDim2.new(0.6, -30, 0.70, 0)
	comboDisplay.AnchorPoint = Vector2.new(0.5, 1)
	comboDisplay.BackgroundTransparency = 1
	comboDisplay.Text = "x" .. mudaComboCount
	comboDisplay.TextColor3 = Color3.fromRGB(255, 215, 0)
	comboDisplay.TextStrokeTransparency = 0
	comboDisplay.TextStrokeColor3 = Color3.fromRGB(180, 0, 0)
	comboDisplay.Font = Enum.Font.Bangers
	comboDisplay.TextSize = 20
	comboDisplay.ZIndex = 100
	comboDisplay.Parent = screenGui
	
	comboDisplay.TextTransparency = 1
	local tweenIn = TweenService:Create(comboDisplay, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextTransparency = 0,
		TextSize = 26
	})
	tweenIn:Play()
	table.insert(comboTweens, tweenIn)
	
	task.delay(0.15, function()
		if comboDisplay and comboDisplay.Parent then
			local tweenBack = TweenService:Create(comboDisplay, TweenInfo.new(0.15), {
				TextSize = 20
			})
			tweenBack:Play()
		end
	end)
	
	task.delay(1.5, function()
		if comboDisplay and comboDisplay.Parent then
			local tweenOut = TweenService:Create(comboDisplay, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				TextTransparency = 1
			})
			tweenOut:Play()
			tweenOut.Completed:Connect(function()
				if comboDisplay and comboDisplay.Parent then
					comboDisplay:Destroy()
					comboDisplay = nil
				end
			end)
		end
	end)
end

local function cameraShake(duration, intensity)
	if not hum then return end
	local start = tick()
	local connection
	connection = RunService.RenderStepped:Connect(function()
		local elapsed = tick() - start
		if elapsed < duration then
			local currentIntensity = intensity * (1 - (elapsed / duration))
			local rx = (math.random() - 0.5) * currentIntensity
			local ry = (math.random() - 0.5) * currentIntensity
			local rz = (math.random() - 0.5) * currentIntensity
			hum.CameraOffset = Vector3.new(rx, ry, rz)
		else
			hum.CameraOffset = Vector3.new(0, 0, 0)
			connection:Disconnect()
		end
	end)
end

local function cinematicZoom(duration, targetFOV)
	local camera = workspace.CurrentCamera
	if not camera then return end
	local originalFOV = camera.FieldOfView
	TweenService:Create(camera, TweenInfo.new(duration * 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		FieldOfView = targetFOV
	}):Play()
	task.delay(duration * 0.6, function()
		TweenService:Create(camera, TweenInfo.new(duration * 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			FieldOfView = originalFOV
		}):Play()
	end)
end

local COOLDOWNS = {M1 = 0.8, Knife = 1, TimeStop = 3, RoadRoller = 15}
local lastUsed = {M1 = 0, Knife = 0, TimeStop = 0, RoadRoller = 0}

local function canUse(abilityName)
	local currentTime = tick()
	if currentTime - lastUsed[abilityName] >= COOLDOWNS[abilityName] then
		lastUsed[abilityName] = currentTime
		return true
	end
	return false
end

local function showSpeechBubble(imageId, side, duration, customHead)
	if not customHead then
		if not character or not character:FindFirstChild("Head") then return end
		customHead = character.Head
	end
	local head = customHead
	if not head or not head.Parent then return end

	local billboard = Instance.new("BillboardGui")
	billboard.Adornee = head
	billboard.Size = UDim2.new(3.5, 0, 3.5, 0)
	billboard.StudsOffset = Vector3.new(side == "right" and 1.8 or -1.8, 1.5, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = head

	local imageLabel = Instance.new("ImageLabel")
	imageLabel.BackgroundTransparency = 1
	imageLabel.Image = "rbxassetid://" .. imageId
	imageLabel.ImageTransparency = 1
	imageLabel.Size = UDim2.new(0.2, 0, 0.2, 0)
	imageLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
	imageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	imageLabel.Parent = billboard

	TweenService:Create(imageLabel, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(1, 0, 1, 0),
		ImageTransparency = 0
	}):Play()

	task.delay(duration, function()
		if billboard and billboard.Parent then
			local tweenOut = TweenService:Create(imageLabel, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Size = UDim2.new(0.2, 0, 0.2, 0),
				ImageTransparency = 1
			})
			tweenOut:Play()
			tweenOut.Completed:Connect(function()
				if billboard and billboard.Parent then billboard:Destroy() end
			end)
		end
	end)
end

local TS_POS = UDim2.new(0.4, 0, 0.78, 0)
local ROAD_POS = UDim2.new(0.3, 0, 0.79, 0)   
local ACTIVATE_POS = UDim2.new(0.5, 0, 0.75, 0)
local M1_POS = UDim2.new(0.6, 0, 0.78, 0)
local KNIFE_POS_OFF = M1_POS

local function createCircularButton(name, pos, text, color, imageId, sizeOffset)
	sizeOffset = sizeOffset or 70
	color = color or COLORS.Yellow
	local btn = Instance.new("TextButton", screenGui)
	btn.Name = name
	btn.Size = UDim2.fromOffset(sizeOffset, sizeOffset)
	btn.Position = pos
	btn.AnchorPoint = Vector2.new(0.5, 0.5)
	btn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	btn.Text = text
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.Bangers
	btn.TextSize = 14
	btn.AutoButtonColor = false
	Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
	local stroke = Instance.new("UIStroke", btn)
	stroke.Color = color
	stroke.Thickness = 3
	local icon = nil
	if imageId then
		icon = Instance.new("ImageLabel", btn)
		icon.Size = UDim2.new(1, 0, 1, 0)
		icon.Position = UDim2.new(0.49, 0, 0.5, 0)
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.BackgroundTransparency = 1
		icon.Image = imageId
		icon.ScaleType = Enum.ScaleType.Fit
		icon.ZIndex = 2
		Instance.new("UICorner", icon).CornerRadius = UDim.new(1, 0)
	end
	return btn, stroke, icon
end

local tsBtn, tsStroke, tsIcon = createCircularButton("TimeStopBtn", TS_POS, "STOP", nil, ASSETS.TS_IMAGE, 80)     
local roadBtn, roadStroke = createCircularButton("RoadRollerBtn", ROAD_POS, "ROAD", Color3.fromRGB(170, 0, 255), nil, 70) 
local activateBtn, actStroke, standIcon = createCircularButton("ActivateBtn", ACTIVATE_POS, "STAND", nil, ASSETS.STAND_IMAGE, 95) 
local m1Btn, m1Stroke = createCircularButton("M1Btn", M1_POS, "M1", nil, nil, 80)          
local knifeBtn, knifeStroke, knifeIcon = createCircularButton("KnifeBtn", KNIFE_POS_OFF, "KNIFE", nil, ASSETS.KNIFE_IMAGE, 80) 

m1Btn.Visible = false
m1Btn.Position = ACTIVATE_POS         
m1Btn.Size = UDim2.fromOffset(0, 0)  
roadBtn.Visible = false              
roadBtn.Position = TS_POS            
roadBtn.Size = UDim2.fromOffset(0, 0)

local resumeImage = Instance.new("ImageLabel", screenGui)
resumeImage.Size = UDim2.fromScale(0.85, 0.85)
resumeImage.Position = UDim2.fromScale(0.5, 0.5)
resumeImage.AnchorPoint = Vector2.new(0.5, 0.5)
resumeImage.BackgroundTransparency = 1
resumeImage.Image = ASSETS.TS_RESUME_IMAGE
resumeImage.ImageTransparency = 1
resumeImage.Visible = false
resumeImage.ScaleType = Enum.ScaleType.Fit

local function updateIconState(icon, isActive)
	if not icon then return end
	icon.ImageColor3 = isActive and Color3.fromRGB(128, 128, 128) or Color3.fromRGB(255, 255, 255)
end

local function updateKnifePosition(isActive)
	if isActive then
		TweenService:Create(knifeBtn, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.7, 0, 0.79, 0), 
			Size = UDim2.fromOffset(70, 70)
		}):Play()
	else
		TweenService:Create(knifeBtn, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		    Position = KNIFE_POS_OFF, 
			Size = UDim2.fromOffset(80, 80)
		}):Play()
	end
end

local function playAnim(target, animId, speed, looped, priority)
    if not target or not target.Parent then return end
    local a = Instance.new("Animation")
    a.AnimationId = animId
    local track = target:LoadAnimation(a)
    track.Looped = (looped == true)
    if priority then track.Priority = priority end
    track:Play()
    if speed then track:AdjustSpeed(speed) end
    return track
end

local function getStandModel()
    character.Archivable = true
    local model = character:Clone()
    character.Archivable = false
    model.Name = "Stand"
    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") then
            p.CanCollide = false
            p.Transparency = 1  
            p.CastShadow = false
        elseif p:IsA("Decal") then
            p.Transparency = 1
        elseif p:IsA("LocalScript") or p:IsA("Script") then
            p:Destroy()
        end
    end
    return model
end

local function toggleStand()
	if isStandActive then
		isStandActive = false
		isAttacking = false
		activateBtn.Text = "STAND"
		if idleTrack then idleTrack:Stop() end
		if currentStand then
			local root = currentStand:FindFirstChild("HumanoidRootPart")
			if root then
				root.Anchored = false
				TweenService:Create(root, TweenInfo.new(0.5), {CFrame = character.HumanoidRootPart.CFrame}):Play()
			end
			for _, p in ipairs(currentStand:GetDescendants()) do
				if p:IsA("BasePart") then TweenService:Create(p, TweenInfo.new(0.5), {Transparency = 1}):Play() end
			end
			Debris:AddItem(currentStand, 0.5)
			currentStand = nil
		end
		TweenService:Create(m1Btn, TweenInfo.new(0.3), {Position = ACTIVATE_POS, Size = UDim2.fromOffset(0, 0)}):Play()
		task.delay(0.3, function() m1Btn.Visible = false end)
		updateKnifePosition(false)
		updateIconState(standIcon, false)
	else
		isStandActive = true
		activateBtn.Text = "OFF"
		showSpeechBubble(81663476180868, "right", 2.5)
		m1Btn.Visible = true
		TweenService:Create(m1Btn, TweenInfo.new(0.4, Enum.EasingStyle.Back), {Position = M1_POS, Size = UDim2.fromOffset(80, 80)}):Play()
		currentStand = getStandModel()
		currentStand.Parent = workspace
		local sHum = currentStand:FindFirstChildOfClass("Humanoid")
		if sHum then
			sHum.PlatformStand = true
			sHum.AutoRotate = false
			local sRoot = currentStand:FindFirstChild("HumanoidRootPart")
			if sRoot then sRoot.Anchored = true end
			idleTrack = playAnim(sHum, ASSETS.STAND_IDLE, 1, true, Enum.AnimationPriority.Idle)
		end
		for _, p in ipairs(currentStand:GetDescendants()) do
            if p:IsA("BasePart") then
                p.Color = Color3.new(1,1,1)
                if p.Name == "HumanoidRootPart" then p.Transparency = 1 else
                    TweenService:Create(p, TweenInfo.new(0.4), {Transparency = 0}):Play()
                end
            end
        end
		updateKnifePosition(true)
		updateIconState(standIcon, true)
	end
end

local function toggleTime()
	if isTimeStopped then
		isTimeStopped = false
		tsBtn.Text = "STOP"
        local bloom = Lighting:FindFirstChild("TS_Bloom")
        if bloom then TweenService:Create(bloom, TweenInfo.new(0.5), {Intensity = 0}):Play() task.delay(0.5, function() if bloom then bloom:Destroy() end end) end
		TweenService:Create(roadBtn, TweenInfo.new(0.3), {Position = TS_POS, Size = UDim2.fromOffset(0, 0)}):Play()
		task.delay(0.3, function() roadBtn.Visible = false end)
		local s = Instance.new("Sound", workspace) s.SoundId = ASSETS.TS_END_SFX s:Play() Debris:AddItem(s, 3)
		for part in pairs(frozenParts) do if part and part.Parent then part.Anchored = false end end
		frozenParts = {}
		task.spawn(function()
			resumeImage.Visible = true
			for i = 1, 4 do
				TweenService:Create(resumeImage, TweenInfo.new(0.18), {ImageTransparency = 0.35}):Play() task.wait(0.22)
				TweenService:Create(resumeImage, TweenInfo.new(0.18), {ImageTransparency = 0.88}):Play() task.wait(0.22)
			end
			TweenService:Create(resumeImage, TweenInfo.new(0.45), {ImageTransparency = 1}):Play()
		end)
		local cc = Lighting:FindFirstChild("TS_Effect")
		if cc then
			TweenService:Create(cc, TweenInfo.new(0.4), {TintColor = Color3.fromRGB(255,255,255), Saturation = 0, Contrast = 0}):Play()
			Debris:AddItem(cc, 0.5)
		end
		updateIconState(tsIcon, false)
	else
        if not canUse("TimeStop") then return end
        isTimeStopped = true
        tsBtn.Text = "RESUME"
        roadBtn.Visible = true
        TweenService:Create(roadBtn, TweenInfo.new(0.4, Enum.EasingStyle.Back), {Position = ROAD_POS, Size = UDim2.fromOffset(70, 70)}):Play()
        local root = character:FindFirstChild("HumanoidRootPart")
        local s = Instance.new("Sound", workspace) s.SoundId = ASSETS.TS_START_SFX s.Volume = 2 s:Play() Debris:AddItem(s, 5)
        playAnim(hum, ASSETS.ANIM_DIO, 2, false, Enum.AnimationPriority.Action) 
        if root then root.Anchored = true end
        showSpeechBubble(106366607174396, "right", 4)
        task.delay(1.9, function()
            if not isTimeStopped then return end
            cinematicZoom(1, 40)
            task.delay(0.1, function() cameraShake(2, 3) end)
            if root then root.Anchored = false end
            local cc = Lighting:FindFirstChild("TS_Effect") or Instance.new("ColorCorrectionEffect", Lighting)
            cc.Name = "TS_Effect"
            TweenService:Create(cc, TweenInfo.new(0.4), {Saturation = -1.2, Contrast = 0.5, TintColor = Color3.fromRGB(180, 200, 255)}):Play()
            frozenParts = {}
            for _, part in ipairs(workspace:GetDescendants()) do
                if part:IsA("BasePart") and not part:IsDescendantOf(character) and not (currentStand and part:IsDescendantOf(currentStand)) and not part.Anchored then
                    frozenParts[part] = true
                    part.Anchored = true
                end
            end
        end)
        updateIconState(tsIcon, true)
	end	
end

local function getClosestTarget(maxDist)
	local closest, minDist = nil, maxDist
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return nil end
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Humanoid") and obj ~= hum and (not currentStand or obj.Parent ~= currentStand) then
			local targetRoot = obj.Parent:FindFirstChild("HumanoidRootPart")
			if targetRoot then
				local dist = (targetRoot.Position - root.Position).Magnitude
				if dist < minDist then
					minDist = dist
					closest = targetRoot
				end
			end
		end
	end
	return closest
end

local function performRoadRoller()
	if not isTimeStopped or not canUse("RoadRoller") then return end
	local targetRoot = getClosestTarget(100)
	if not targetRoot then return end

	showSpeechBubble(ASSETS.ROAD_ROLLER_DA, "right", 2.5)
	cameraShake(4.5, 2.5)

	local model = Instance.new("Model", workspace)
	local roller = Instance.new("Part", model)
	roller.Size = Vector3.new(1, 1, 1)
	roller.Anchored = true
	local mesh = Instance.new("SpecialMesh", roller)
	mesh.MeshId = ASSETS.ROAD_ROLLER_MESH
	mesh.TextureId = ASSETS.ROAD_ROLLER_TEXTURE
	mesh.Scale = Vector3.new(1.3, 1.7, 1.3)
	model.PrimaryPart = roller

	roller.CFrame = CFrame.new(targetRoot.Position + Vector3.new(0, 500, 0)) * CFrame.Angles(math.rad(85), 0, 90)
	roller.Anchored = false
    
	local spawnSound = Instance.new("Sound", roller)
	spawnSound.SoundId = ASSETS.ROAD_ROLLER_SPAWN_SFX
	spawnSound:Play()

    local charRoot = character:FindFirstChild("HumanoidRootPart")
    if charRoot then
        charRoot.CFrame = roller.CFrame * CFrame.new(0, -2.5, -17)
        local w = Instance.new("WeldConstraint", charRoot)
        w.Part0 = charRoot; w.Part1 = roller
        task.delay(1.5, function() w:Destroy() end)
    end

	local bodyVel = Instance.new("BodyVelocity", roller)
	bodyVel.Velocity = Vector3.new(0, -450, 0)
	bodyVel.MaxForce = Vector3.new(1, 1, 1) * math.huge

	local impact = false
	RunService.Heartbeat:Connect(function()
		if not impact and roller.Position.Y <= targetRoot.Position.Y + 5 then
			impact = true
			roller.Anchored = true
			bodyVel:Destroy()
			cameraShake(1.5, 5)
			local targetHum = targetRoot.Parent:FindFirstChildOfClass("Humanoid")
			if targetHum then targetHum:TakeDamage(95) end
			Debris:AddItem(model, 5)
		end
	end)
end

local function performM1()
	if not canUse("M1") or not isStandActive or isAttacking then return end
	local targetRoot = getClosestTarget(12)
	if not targetRoot then return end
	local targetHum = targetRoot.Parent:FindFirstChildOfClass("Humanoid")
	
	isAttacking = true
	cameraShake(3, 0.5)
	local sRoot = currentStand:FindFirstChild("HumanoidRootPart")
	local sHum = currentStand:FindFirstChildOfClass("Humanoid")
	
	playAnim(sHum, ASSETS.BARRAGE_ANIM, 2.5, true) 
	playAnim(hum, ASSETS.PLAYER_BARRAGE, 1, true) 

	local s = Instance.new("Sound", workspace) s.SoundId = ASSETS.MUDA_SOUND; s:Play()
	
	for i = 1, 46 do
		if targetHum then
			targetHum:TakeDamage(1)
			mudaComboCount = mudaComboCount + 1
			if mudaComboCount % 5 == 0 then showComboCounter() end
			if targetHum.Health <= FINISHER_HEALTH_THRESHOLD then startFinisher(targetRoot) end
		end
		task.wait(0.065)
	end
	
	mudaComboCount = 0
	isAttacking = false
end

local function performKnifeThrow()
	if not canUse("Knife") or isAttacking then return end
	isAttacking = true
	local target = getClosestTarget(50)
	local throwSound = Instance.new("Sound", workspace)
	throwSound.SoundId = ASSETS.KNIFE_THROW_SOUND; throwSound:Play()

	local knife = Instance.new("Part", workspace)
	knife.Size = Vector3.new(1,1,1)
	knife.CFrame = character.HumanoidRootPart.CFrame * CFrame.new(0,0,-2)
    local mesh = Instance.new("SpecialMesh", knife)
    mesh.MeshId = "rbxassetid://15945983658"
    mesh.TextureId = "rbxassetid://15946012483"
    
	local vel = Instance.new("LinearVelocity", knife)
	vel.MaxForce = math.huge
	vel.VectorVelocity = (target and (target.Position - knife.Position).Unit or character.HumanoidRootPart.CFrame.LookVector) * 280
    vel.Attachment0 = Instance.new("Attachment", knife)

	knife.Touched:Connect(function(hit)
		local h = hit.Parent:FindFirstChildOfClass("Humanoid")
		if h and h.Parent ~= character then
			h:TakeDamage(18)
			knife:Destroy()
		end
	end)
	Debris:AddItem(knife, 3)
	isAttacking = false
end

tsBtn.MouseButton1Click:Connect(toggleTime)
activateBtn.MouseButton1Click:Connect(toggleStand)
m1Btn.MouseButton1Click:Connect(performM1)
knifeBtn.MouseButton1Click:Connect(performKnifeThrow)
roadBtn.MouseButton1Click:Connect(performRoadRoller)

updateKnifePosition(false)
