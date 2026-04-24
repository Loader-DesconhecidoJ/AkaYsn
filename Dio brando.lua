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
local mudaComboCount = 0 -- ðŸ”¢ Combo counter
local comboDisplay = nil -- ðŸ“Š HUD do combo
local comboTweens = {} -- ðŸŽ¬ Tweens do combo

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
	-- === NOVOS ASSETS ROAD ROLLER ===
	ROAD_ROLLER_MESH = "rbxassetid://123055050240257",
	ROAD_ROLLER_TEXTURE = "rbxassetid://70977204379919",
	ROAD_ROLLER_DA = "124648495201789",
	ROAD_ROLLER_SPAWN_SFX = "rbxassetid://6273171415",        -- NOVO: som ao spawnar
	ROAD_ROLLER_IMPACT_SFX1 = "rbxassetid://122293342039104", -- NOVO: impacto 1
	ROAD_ROLLER_IMPACT_SFX2 = "rbxassetid://138680390593747", -- NOVO: impacto 2
	ROAD_ROLLER_RIDE_ANIM = "rbxassetid://140327538515031" -- <- COLOQUE AQUI O ID DA SUA ANIMAÃ‡ÃƒO
}

-- ==================== FINISHER CONFIG + NOCLIP NO ALVO ====================
local FINISHER_HEALTH_THRESHOLD = 20     -- Vida vermelha
local FINISHER_DURATION = 2              -- Segundos de fling + noclip

local isFinisherActive = false
local finisherConnection = nil
local noclipFinisherConn = nil
local finisherTargetRoot = nil

local function startFinisher(targetRoot)
	if isFinisherActive or not targetRoot then return end
	
	isFinisherActive = true
	finisherTargetRoot = targetRoot
	
	local myRoot = character:FindFirstChild("HumanoidRootPart")
	if not myRoot then return end
	
	-- Teleporta seu boneco PRA DENTRO do alvo
	myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 0)
	
	-- ==================== NOCLIP SÃ“ NO ALVO ====================
	noclipFinisherConn = RunService.Stepped:Connect(function()
		if not finisherTargetRoot or not finisherTargetRoot.Parent then return end
		
		for _, part in ipairs(finisherTargetRoot.Parent:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false   -- VocÃª atravessa o corpo do alvo
			end
		end
	end)
	
	-- ==================== FLING NUCLEAR ====================
	finisherConnection = RunService.Heartbeat:Connect(function()
		if not myRoot or not finisherTargetRoot or not finisherTargetRoot.Parent then return end
		
		local oldVel = myRoot.Velocity
		myRoot.Velocity = oldVel * 14800 + Vector3.new(0, 17200, 0)   -- Fling bem forte
		RunService.RenderStepped:Wait()
		myRoot.Velocity = oldVel * 0.5
	end)
	
	print(" FINISHER + NOCLIP NO ALVO ATIVADO - ELE VAI VOAR PRA CARALHO!")
	
	-- Desativa tudo automaticamente apÃ³s 2 segundos
	task.delay(FINISHER_DURATION, function()
		if isFinisherActive then
			endFinisher()
		end
	end)
end

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
	
	-- Reset seguro do seu boneco
	local myRoot = character:FindFirstChild("HumanoidRootPart")
	if myRoot then
		myRoot.Velocity = Vector3.new(0, 25, 0)
		myRoot.CFrame = myRoot.CFrame + Vector3.new(3, 6, 0)  -- sai um pouco pro lado pra nÃ£o ficar preso
	end
	
	-- Restaura colisÃ£o do alvo
	if finisherTargetRoot and finisherTargetRoot.Parent then
		for _, part in ipairs(finisherTargetRoot.Parent:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = true
			end
		end
	end
	
	print(" Finisher + NoClip finalizado")
end

local screenGui = Instance.new("ScreenGui", player.PlayerGui)
screenGui.Name = "DioStandUniversal"
screenGui.ResetOnSpawn = false

-- ====================  COMBO COUNTER EM CIMA DO BOTÃO M1 ====================
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
	billboard.Name = "JojoSpeechBubble"
	billboard.Adornee = head
	billboard.Size = UDim2.new(3.5, 0, 3.5, 0)
	billboard.StudsOffset = Vector3.new(side == "right" and 1.8 or -1.8, 1.5, 0)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.MaxDistance = 100
	billboard.Parent = head

	local imageLabel = Instance.new("ImageLabel")
	imageLabel.Name = "BubbleImage"
	imageLabel.BackgroundTransparency = 1
	imageLabel.Image = "rbxassetid://" .. imageId
	imageLabel.ImageTransparency = 1
	
	imageLabel.Size = UDim2.new(0.2, 0, 0.2, 0)
	imageLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
	imageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	
	imageLabel.Parent = billboard

	local tweenInfoIn = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local tweenIn = TweenService:Create(imageLabel, tweenInfoIn, {
		Size = UDim2.new(1, 0, 1, 0),
		ImageTransparency = 0
	})
	tweenIn:Play()

	task.delay(duration, function()
		if billboard and billboard.Parent then
			local tweenInfoOut = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			local tweenOut = TweenService:Create(imageLabel, tweenInfoOut, {
				Size = UDim2.new(0.2, 0, 0.2, 0),
				ImageTransparency = 1
			})
			
			tweenOut:Play()
			tweenOut.Completed:Connect(function(playbackState)
				if playbackState == Enum.PlaybackState.Completed then
					if billboard and billboard.Parent then
						billboard:Destroy()
					end
				end
			end)
		end
	end)
end

local screenGui = Instance.new("ScreenGui", player.PlayerGui)
screenGui.Name = "DioStandUniversal"
screenGui.ResetOnSpawn = false

local TS_POS = UDim2.new(0.4, 0, 0.78, 0)
local ROAD_POS = UDim2.new(0.3, 0, 0.79, 0)   -- NOVO: botÃ£o do Ultimate Ã  esquerda do Time Stop
local ACTIVATE_POS = UDim2.new(0.5, 0, 0.75, 0)
local M1_POS = UDim2.new(0.6, 0, 0.78, 0)
local KNIFE_POS_ON = UDim2.new(0.7, 0, 0.78, 0)
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
	btn.TextStrokeTransparency = 0
	btn.TextStrokeColor3 = Color3.new(0, 0, 0)
	btn.AutoButtonColor = false
	Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
	local stroke = Instance.new("UIStroke", btn)
	stroke.Color = color
	stroke.Thickness = 3
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	local icon = nil
	if imageId then
		icon = Instance.new("ImageLabel", btn)
		icon.Name = "Icon"
		icon.Size = UDim2.new(1, 0, 1, 0)
		icon.Position = UDim2.new(0.49, 0, 0.5, 0)
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.BackgroundTransparency = 1
		icon.Image = imageId
		icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
		icon.ScaleType = Enum.ScaleType.Fit
		icon.ZIndex = 2
		Instance.new("UICorner", icon).CornerRadius = UDim.new(1, 0)
	end
	return btn, stroke, icon
end

local tsBtn, tsStroke, tsIcon = createCircularButton("TimeStopBtn", TS_POS, "STOP", nil, ASSETS.TS_IMAGE, 80)     -- 70  80 (maior)
local roadBtn, roadStroke = createCircularButton("RoadRollerBtn", ROAD_POS, "ROAD", Color3.fromRGB(170, 0, 255), nil, 70) -- Road = 70
local activateBtn, actStroke, standIcon = createCircularButton("ActivateBtn", ACTIVATE_POS, "STAND", nil, ASSETS.STAND_IMAGE, 95) -- Stand = 95
local m1Btn, m1Stroke = createCircularButton("M1Btn", M1_POS, "M1", nil, nil, 80)          -- 70  80 (maior)
local knifeBtn, knifeStroke, knifeIcon = createCircularButton("KnifeBtn", KNIFE_POS_OFF, "KNIFE", nil, ASSETS.KNIFE_IMAGE, 80) -- 70  80 (maior)

m1Btn.Visible = false
m1Btn.Position = ACTIVATE_POS         -- ComeÃ§a na posiÃ§Ã£o do Stand
m1Btn.Size = UDim2.fromOffset(0, 0)  -- ComeÃ§a com tamanho 0
knifeBtn.Visible = true
roadBtn.Visible = false              
roadBtn.Position = TS_POS            
roadBtn.Size = UDim2.fromOffset(0, 0)

local resumeImage = Instance.new("ImageLabel", screenGui)
resumeImage.Name = "TSResumeImage"
resumeImage.Size = UDim2.fromScale(0.85, 0.85)
resumeImage.Position = UDim2.fromScale(0.5, 0.5)
resumeImage.AnchorPoint = Vector2.new(0.5, 0.5)
resumeImage.BackgroundTransparency = 1
resumeImage.Image = ASSETS.TS_RESUME_IMAGE
resumeImage.ImageTransparency = 1
resumeImage.Visible = false
resumeImage.ZIndex = 100
resumeImage.ScaleType = Enum.ScaleType.Fit

local function updateIconState(icon, isActive)
	if not icon then return end
	icon.ImageColor3 = isActive and Color3.fromRGB(128, 128, 128) or Color3.fromRGB(255, 255, 255)
end

updateIconState(tsIcon, false)
updateIconState(standIcon, false)
updateIconState(knifeIcon, false)

local function updateKnifePosition(isActive)
	if isActive then
		-- Stand ATIVO: posição normal + tamanho normal
		TweenService:Create(knifeBtn, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.7, 0, 0.79, 0), 
			Size = UDim2.fromOffset(70, 70)
		}):Play()
	else
		-- Stand DESATIVADO: posição menor + tamanho menor
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
    
    -- Define loop corretamente
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
            p.Transparency = 1 -- <--- Garante que comece invisÃ­vel
            p.CastShadow = false
        elseif p:IsA("Decal") then -- Isso remove faces/texturas extras se houver
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
		
		--  Esconde M1 de volta
		TweenService:Create(m1Btn, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = ACTIVATE_POS,
			Size = UDim2.fromOffset(0, 0)
		}):Play()
		task.delay(0.3, function() m1Btn.Visible = false end)
		
		updateKnifePosition(false)
		updateIconState(standIcon, false)
	else
		isStandActive = true
		activateBtn.Text = "OFF"
		showSpeechBubble(81663476180868, "right", 2.5)
		
		--  Mostra M1 saindo do Stand
		m1Btn.Visible = true
		TweenService:Create(m1Btn, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = M1_POS,
			Size = UDim2.fromOffset(80, 80)
		}):Play()
		
		currentStand = getStandModel()
		currentStand.Parent = workspace
		local sHum = currentStand:FindFirstChildOfClass("Humanoid")
		if sHum then
			sHum.PlatformStand = true
			sHum.AutoRotate = false
			sHum.HipHeight = 0
			local sRoot = currentStand:FindFirstChild("HumanoidRootPart")
			if sRoot then sRoot.Anchored = true end
			idleTrack = playAnim(sHum, ASSETS.STAND_IDLE, 1, true, Enum.AnimationPriority.Idle)
		end
		for _, p in ipairs(currentStand:GetDescendants()) do
    if p:IsA("BasePart") then
        p.Color = Color3.new(1,1,1)
        
        -- Se a parte for o bloco central (RootPart), ela DEVE continuar transparente
        if p.Name == "HumanoidRootPart" then
            p.Transparency = 1
        else
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
		
		TweenService:Create(roadBtn, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = TS_POS,
			Size = UDim2.fromOffset(0, 0)
		}):Play()
		task.delay(0.3, function() roadBtn.Visible = false end)
		
		local s = Instance.new("Sound", workspace) s.SoundId = ASSETS.TS_END_SFX s:Play() Debris:AddItem(s, 3)
		for part in pairs(frozenParts) do if part and part.Parent then part.Anchored = false end end
		frozenParts = {}
		task.spawn(function()
			resumeImage.Visible = true
			resumeImage.ImageTransparency = 1
			local blinkInfo = TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			for i = 1, 4 do
				TweenService:Create(resumeImage, blinkInfo, {ImageTransparency = 0.35}):Play() task.wait(0.22)
				TweenService:Create(resumeImage, blinkInfo, {ImageTransparency = 0.88}):Play() task.wait(0.22)
			end
			TweenService:Create(resumeImage, TweenInfo.new(0.45), {ImageTransparency = 1}):Play()
			task.delay(0.6, function() resumeImage.Visible = false end)
		end)
		local cc = Lighting:FindFirstChild("TS_Effect")
		if cc then
			TweenService:Create(cc, TweenInfo.new(0.4), {TintColor = Color3.fromRGB(170, 0, 255), Saturation = -1.0, Contrast = 0.7}):Play()
			task.delay(0.3, function() if not isTimeStopped then TweenService:Create(cc, TweenInfo.new(0.4), {TintColor = Color3.fromRGB(0, 180, 255), Saturation = -0.5, Contrast = 0.6}):Play() end end)
			task.delay(0.6, function() if not isTimeStopped then TweenService:Create(cc, TweenInfo.new(0.4), {TintColor = Color3.fromRGB(255, 140, 0), Saturation = 1.2, Contrast = 0.8, Brightness = 0.3}):Play() end end)
			task.delay(0.9, function() if not isTimeStopped then TweenService:Create(cc, TweenInfo.new(0.6), {Saturation = 0, Contrast = 0, Brightness = 0, TintColor = Color3.fromRGB(255,255,255)}):Play() Debris:AddItem(cc, 0.7) end end)
		end
		updateIconState(tsIcon, false)
	else
	if not canUse("TimeStop") then return end
	isTimeStopped = true
	tsBtn.Text = "RESUME"
	
	roadBtn.Visible = true
	TweenService:Create(roadBtn, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = ROAD_POS,
		Size = UDim2.fromOffset(70, 70)
	}):Play()
	
	local root = character:FindFirstChild("HumanoidRootPart")
		local s = Instance.new("Sound", workspace) s.SoundId = ASSETS.TS_START_SFX s.Volume = 2 s:Play() Debris:AddItem(s, 5)
		
		local tsTrack = playAnim(hum, ASSETS.ANIM_DIO, 2, false, Enum.AnimationPriority.Action) 
		
		if root then root.Anchored = true end
		showSpeechBubble(106366607174396, "right", 4)
		task.delay(2, function()
			if not isTimeStopped then return end
			cameraShake(0.6, 2.0)
			if root then root.Anchored = false end
			local cc = Lighting:FindFirstChild("TS_Effect") or Instance.new("ColorCorrectionEffect", Lighting)
			cc.Name = "TS_Effect"
			cc.Saturation = 0 cc.Contrast = 0 cc.Brightness = 0 cc.TintColor = Color3.fromRGB(255, 140, 0)
			TweenService:Create(cc, TweenInfo.new(0.4), {Saturation = 1.5, Contrast = 0.8, Brightness = 0.2}):Play()
			task.delay(0.1, function() if isTimeStopped then TweenService:Create(cc, TweenInfo.new(0.4), {TintColor = Color3.fromRGB(0, 180, 255), Saturation = -0.8, Contrast = 0.6, Brightness = 0}):Play() end end)
			task.delay(0.2, function() if isTimeStopped then TweenService:Create(cc, TweenInfo.new(0.4), {TintColor = Color3.fromRGB(170, 0, 255), Saturation = -1.1, Contrast = 0.7}):Play() end end)
			task.delay(0.3, function() if isTimeStopped then TweenService:Create(cc, TweenInfo.new(0.5), {Saturation = -1.2, Contrast = 0.5, Brightness = 0, TintColor = Color3.fromRGB(180, 200, 255)}):Play() end end)
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

-- ==================== TARGETING MELHORADO ====================
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

-- ==================== ROAD ROLLER (ULTIMATE) ====================
local function createExplosion(position)
	local explosionPart = Instance.new("Part")
	explosionPart.Transparency = 1
	explosionPart.Anchored = true
	explosionPart.CanCollide = false
	explosionPart.Position = position
	explosionPart.Size = Vector3.new(1,1,1)
	explosionPart.Parent = workspace

	-- Fogo roxo
	local fire = Instance.new("ParticleEmitter", explosionPart)
	fire.Texture = "rbxassetid://241650899"
	fire.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(170, 0, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120, 0, 200)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 0, 150))
	}
	fire.Lifetime = NumberRange.new(1.8, 2.5)
	fire.Rate = 350
	fire.Speed = NumberRange.new(15, 35)
	fire.Size = NumberSequence.new{NumberSequenceKeypoint.new(0, 6), NumberSequenceKeypoint.new(1, 0)}
	fire.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1)}
	fire.Acceleration = Vector3.new(0, -25, 0)
	fire.SpreadAngle = Vector2.new(30, 30)

	-- Poeira / fumaÃ§a
	local dust = Instance.new("ParticleEmitter", explosionPart)
	dust.Texture = "rbxassetid://241650899"
	dust.Color = ColorSequence.new(Color3.fromRGB(170, 170, 170))
	dust.Lifetime = NumberRange.new(2, 3.5)
	dust.Rate = 180
	dust.Speed = NumberRange.new(8, 18)
	dust.Size = NumberSequence.new{NumberSequenceKeypoint.new(0, 8), NumberSequenceKeypoint.new(1, 2)}
	dust.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1)}
	dust.Acceleration = Vector3.new(0, -10, 0)

	Debris:AddItem(explosionPart, 4)
end

local function createRoadRoller()
	local model = Instance.new("Model")
	model.Name = "RoadRoller"

	local mainPart = Instance.new("Part")
	mainPart.Name = "Body"
	mainPart.Size = Vector3.new(1, 1, 1)
	mainPart.Transparency = 0
	mainPart.Color = Color3.fromRGB(80, 80, 80)
	mainPart.Anchored = true
	mainPart.CanCollide = false
	mainPart.Parent = model

	local mesh = Instance.new("SpecialMesh", mainPart)
	mesh.MeshId = ASSETS.ROAD_ROLLER_MESH
	mesh.TextureId = ASSETS.ROAD_ROLLER_TEXTURE
	mesh.Scale = Vector3.new(1.3, 1.7, 1.3)   -- Ajuste aqui se o rolo ficar pequeno/grande

	model.PrimaryPart = mainPart
	return model
end

local function createGroundCracks(position)
	-- Cria rachaduras no chÃ£o usando partes planas com decalques
	for i = 1, 8 do
		local crack = Instance.new("Part")
		crack.Size = Vector3.new(0.15, 0.01, math.random(3, 8))
		crack.Anchored = true
		crack.CanCollide = false
		crack.Color = Color3.fromRGB(25, 25, 25)
		crack.Material = Enum.Material.CrackedLava
		crack.Transparency = 0.2
		
		-- Posiciona as rachaduras em torno do ponto de impacto
		local angle = math.rad(math.random(0, 360))
		local distance = math.random(1, 6)
		local offset = Vector3.new(math.cos(angle) * distance, 0.01, math.sin(angle) * distance)
		crack.CFrame = CFrame.new(position + offset) * CFrame.Angles(0, math.rad(math.random(0, 360)), 0)
		crack.Parent = workspace
		
		-- Efeito de spawn
		crack.Transparency = 0.8
		TweenService:Create(crack, TweenInfo.new(0.3), {Transparency = 0.2}):Play()
		
		Debris:AddItem(crack, 8)
	end
	
	-- Adiciona um cÃ­rculo central de impacto
	local centerCrater = Instance.new("Part")
	centerCrater.Size = Vector3.new(4, 0.02, 4)
	centerCrater.Anchored = true
	centerCrater.CanCollide = false
	centerCrater.Color = Color3.fromRGB(30, 30, 30)
	centerCrater.Material = Enum.Material.CrackedLava
	centerCrater.Transparency = 0.4
	centerCrater.CFrame = CFrame.new(position + Vector3.new(0, 0.005, 0))
	centerCrater.Parent = workspace
	
	-- Decalque de rachadura circular
	local decal = Instance.new("Decal", centerCrater)
	decal.Texture = "rbxassetid://154292235" -- textura de rachadura genÃ©rica
	decal.Face = Enum.NormalId.Top
	decal.Transparency = 0.3
	
	Debris:AddItem(centerCrater, 8)
end

local function performRoadRoller()
	if not isTimeStopped then
		showSpeechBubble(102362181377695, "right", 2.5)
		return
	end
	if not canUse("RoadRoller") then return end
	
	-- ===== FLASH PRETO NA ATIVAÃ‡ÃƒO (0.1s fade in, 0.1s fade out) =====
local activationFlash = Instance.new("Frame")
activationFlash.Name = "RoadRollerActivationFlash"
activationFlash.Size = UDim2.fromScale(2, 2)
activationFlash.Position = UDim2.fromScale(-0.5, -0.5)
activationFlash.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
activationFlash.BackgroundTransparency = 1
activationFlash.ZIndex = 100
activationFlash.Parent = screenGui

-- Fade in rÃ¡pido: 0.1s
TweenService:Create(activationFlash, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
	BackgroundTransparency = 0
}):Play()

-- Fade out apÃ³s 0.1s
task.delay(0.1, function()
	if activationFlash.Parent then
		TweenService:Create(activationFlash, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1
		}):Play()
		task.delay(0.15, function() 
			if activationFlash.Parent then 
				activationFlash:Destroy() 
			end 
		end)
	end
end)

	local targetRoot = getClosestTarget(100)
	if not targetRoot then return end

	showSpeechBubble(ASSETS.ROAD_ROLLER_DA, "right", 2.5)
	cameraShake(4.5, 2.5)

	local rollerModel = createRoadRoller()
	local rollerRoot = rollerModel.PrimaryPart

	-- Spawn ALTÃSSIMO (500 studs)
	local startHeight = 500
	local startPos = targetRoot.Position + Vector3.new(0, startHeight, 0)
	rollerRoot.CFrame = CFrame.new(startPos) * CFrame.Angles(math.rad(85), 0, 90)
	rollerRoot.Anchored = false
	rollerModel.Parent = workspace

	-- Remove do frozenParts
	for _, part in ipairs(rollerModel:GetDescendants()) do
		if part:IsA("BasePart") then
			frozenParts[part] = nil
			part.Anchored = false
		end
	end

	-- SOM DE SPAWN
	local spawnSound = Instance.new("Sound")
	spawnSound.SoundId = ASSETS.ROAD_ROLLER_SPAWN_SFX
	spawnSound.Volume = 2.5
	spawnSound.Parent = rollerRoot
	spawnSound:Play()
	Debris:AddItem(spawnSound, 5)

	-- ===== SEU PERSONAGEM SOBE EM CIMA (CORRIGIDO - OLHANDO PRA FRENTE) =====
local charRoot = character:FindFirstChild("HumanoidRootPart")
local rideTrack = nil
local weld = nil

if charRoot then
	charRoot.Anchored = false
	frozenParts[charRoot] = nil
	
	-- Posiciona em cima do rolo
	charRoot.CFrame = rollerRoot.CFrame * CFrame.new(0, -2.5, -17)
	
	-- FAZ O PERSONAGEM OLHAR PARA O ALVO (FRENTE)
	charRoot.CFrame = CFrame.lookAt(charRoot.Position, targetRoot.Position) * CFrame.Angles(math.rad(90), 0, 0)
	
	if hum and ASSETS.ROAD_ROLLER_RIDE_ANIM ~= "" then
		rideTrack = playAnim(hum, ASSETS.ROAD_ROLLER_RIDE_ANIM, 1.5, true, Enum.AnimationPriority.Action)
		
		weld = Instance.new("WeldConstraint")
		weld.Part0 = charRoot
		weld.Part1 = rollerRoot
		weld.Parent = charRoot
	end
end

	-- ===== FORÃ‡A DE QUEDA VIOLENTA =====
	-- Usa BodyVelocity para queda ultra rÃ¡pida em vez de Tween
	local bodyVel = Instance.new("BodyVelocity")
	bodyVel.Velocity = Vector3.new(0, -450, 0) -- Velocidade de queda MUITO alta
	bodyVel.MaxForce = Vector3.new(1, 1, 1) * math.huge
	bodyVel.Parent = rollerRoot
	
	-- ForÃ§a extra pra baixo
	local bodyForce = Instance.new("BodyForce")
	bodyForce.Force = Vector3.new(0, -rollerRoot:GetMass() * 500, 0)
	bodyForce.Parent = rollerRoot
	
	-- Rastreia a distÃ¢ncia para detectar quando chegar ao chÃ£o
	local impactTriggered = false
	local checkConnection
	checkConnection = RunService.RenderStepped:Connect(function()
		if not rollerRoot or not rollerRoot.Parent then
			checkConnection:Disconnect()
			return
		end
		
		local currentY = rollerRoot.Position.Y
		local groundY = targetRoot.Position.Y - 3 -- PosiÃ§Ã£o do chÃ£o (enterrado)
		
		-- Verifica se chegou ao chÃ£o ou passou
		if currentY <= groundY + 5 and not impactTriggered then
			impactTriggered = true
			checkConnection:Disconnect()
			
			-- Para as forÃ§as
			bodyVel:Destroy()
			bodyForce:Destroy()
			
			-- ===== IMPACTO =====
			rollerRoot.Anchored = true
			rollerRoot.CFrame = CFrame.new(targetRoot.Position + Vector3.new(0, -3, 0)) * CFrame.Angles(math.rad(-80), math.rad(180), 0)
			
			-- SONS DE IMPACTO
			local impactSound1 = Instance.new("Sound")
			impactSound1.SoundId = ASSETS.ROAD_ROLLER_IMPACT_SFX1
			impactSound1.Volume = 3
			impactSound1.Parent = rollerRoot
			impactSound1:Play()
			Debris:AddItem(impactSound1, 5)
			
			task.delay(0.15, function()
				local impactSound2 = Instance.new("Sound")
				impactSound2.SoundId = ASSETS.ROAD_ROLLER_IMPACT_SFX2
				impactSound2.Volume = 3
				impactSound2.Parent = rollerRoot
				impactSound2:Play()
				Debris:AddItem(impactSound2, 5)
			end)
			
			-- CÃ¢mera shake BRUTAL
			cameraShake(1.5, 5.0)
			
			-- ===== PERSONAGEM SAI DE CIMA =====
			if charRoot and charRoot.Parent then
				if weld then weld:Destroy() end
				if rideTrack then rideTrack:Stop() end
				
				charRoot.Anchored = false
				
				local exitPos = rollerRoot.CFrame * CFrame.new(8, 6, 0)
				TweenService:Create(charRoot, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					CFrame = exitPos
				}):Play()
				
				task.delay(0.5, function()
					if charRoot and charRoot.Parent then
						local exitVel = Instance.new("BodyVelocity")
						exitVel.Velocity = Vector3.new(20, 30, 0)
						exitVel.MaxForce = Vector3.new(1, 1, 1) * 100000
						exitVel.Parent = charRoot
						Debris:AddItem(exitVel, 0.5)
					end
				end)
			end
			
			-- Dano no alvo
			local targetHum = targetRoot.Parent:FindFirstChildOfClass("Humanoid")
			if targetHum then
				targetHum:TakeDamage(95)
			end

			-- Rachaduras
			createGroundCracks(targetRoot.Position)

			-- ExplosÃ£o
			createExplosion(targetRoot.Position)

			-- Knockback
			if targetRoot and targetRoot.Parent then
				local knockbackDir = (targetRoot.Position - character.HumanoidRootPart.Position).Unit
				targetRoot:ApplyImpulse(Vector3.new(0, 80000, 0) + knockbackDir * 50000)
			end

			-- ===== DESINTEGRAÃ‡ÃƒO =====
			local disintegrationDelay = COOLDOWNS.RoadRoller - 4
			
			task.delay(disintegrationDelay, function()
				if rollerModel and rollerModel.Parent then
					local disintegratePart = Instance.new("Part")
					disintegratePart.Transparency = 1
					disintegratePart.Anchored = true
					disintegratePart.CanCollide = false
					disintegratePart.Position = rollerRoot.Position
					disintegratePart.Size = Vector3.new(1,1,1)
					disintegratePart.Parent = workspace
					
					local particles = Instance.new("ParticleEmitter", disintegratePart)
					particles.Texture = "rbxassetid://241650899"
					particles.Color = ColorSequence.new{
						ColorSequenceKeypoint.new(0, Color3.fromRGB(170, 0, 255)),
						ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 0, 200)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 0, 150))
					}
					particles.Lifetime = NumberRange.new(1, 2)
					particles.Rate = 200
					particles.Speed = NumberRange.new(3, 8)
					particles.Size = NumberSequence.new{NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 0)}
					particles.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1)}
					particles.Acceleration = Vector3.new(0, 2, 0)
					particles.SpreadAngle = Vector2.new(360, 360)
					
					Debris:AddItem(disintegratePart, 3)
					
					for _, part in ipairs(rollerModel:GetDescendants()) do
						if part:IsA("BasePart") and part ~= rollerRoot then
							TweenService:Create(part, TweenInfo.new(2.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
								Transparency = 1
							}):Play()
						end
					end
					
					TweenService:Create(rollerRoot, TweenInfo.new(2.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
						Transparency = 1
					}):Play()
					
					Debris:AddItem(rollerModel, 2.7)
				end
			end)
			
			Debris:AddItem(rollerModel, COOLDOWNS.RoadRoller)
		end
	end)
end

local function performM1()
	if not canUse("M1") then return end
	if not isStandActive or not currentStand or isAttacking then return end
	
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	
	local targetRoot = getClosestTarget(12)
	if not targetRoot then 
		showSpeechBubble(102362181377695, "right", 2.5) 
		return 
	end
	
	local targetHum = targetRoot.Parent:FindFirstChildOfClass("Humanoid")
	if not targetHum then 
		isAttacking = false 
		return 
	end
	
	isAttacking = true
	cameraShake(3, 0.5)
	showSpeechBubble(82682258182370, "left", 4, currentStand:FindFirstChild("Head"))
	
	local sRoot = currentStand:FindFirstChild("HumanoidRootPart")
	local sHum = currentStand:FindFirstChildOfClass("Humanoid")
	
	local barrageTrack, playerBarrageTrack
	if sHum then 
		if idleTrack and idleTrack.IsPlaying then idleTrack:Stop() end 
		barrageTrack = playAnim(sHum, ASSETS.BARRAGE_ANIM, 2.5, true, Enum.AnimationPriority.Action) 
	end
	if hum then 
		playerBarrageTrack = playAnim(hum, ASSETS.PLAYER_BARRAGE, 1, true, Enum.AnimationPriority.Action) 
	end

	local mudaSound = Instance.new("Sound", workspace) 
	mudaSound.SoundId = ASSETS.MUDA_SOUND 
	mudaSound.Volume = 1.2 
	mudaSound:Play() 
	Debris:AddItem(mudaSound, 6)
	
	for i = 1, 46 do
		if targetRoot and targetRoot.Parent and targetHum and targetHum.Parent then
			
			targetHum:TakeDamage(1)
			
			-- Hit visual
			local hit = Instance.new("Part") 
			hit.Size = Vector3.new(1,1,1) 
			hit.Color = Color3.fromRGB(255,0,100) 
			hit.Transparency = 0.3 
			hit.Anchored = true 
			hit.CanCollide = false 
			hit.CFrame = targetRoot.CFrame 
			hit.Parent = workspace
			TweenService:Create(hit, TweenInfo.new(0.4), {Transparency = 1, Size = Vector3.new(4,4,4)}):Play() 
			Debris:AddItem(hit, 0.5)
			
			-- Atualiza combo counter
mudaComboCount = mudaComboCount + 1
if mudaComboCount % 5 == 0 then -- Mostra a cada 5 hits
	showComboCounter()
end
			
			--  FINISHER: Vida vermelha  Teleport + Fling
			if targetHum.Health <= FINISHER_HEALTH_THRESHOLD and not isFinisherActive then
				startFinisher(targetRoot)
			end
			
			-- Stand positioning
			if sRoot and sRoot.Parent then
				local basePos = targetRoot.CFrame * CFrame.new(0, 2, -4)
				local targetCF = CFrame.lookAt(basePos.Position, targetRoot.Position)
				sRoot.CFrame = sRoot.CFrame:Lerp(targetCF, 0.35)
			end
			
			if root and targetRoot and targetRoot.Parent then
				local dir = (targetRoot.Position - root.Position)
				local flatDir = Vector3.new(dir.X, 0, dir.Z)
				if flatDir.Magnitude > 0.1 then
					flatDir = flatDir.Unit
					local targetLookCF = CFrame.lookAt(root.Position, root.Position + flatDir)
					root.CFrame = root.CFrame:Lerp(targetLookCF, 0.25)
				end
			end
		end
		task.wait(0.065)
	end
	
	-- Knockback final
	if targetRoot and targetRoot.Parent then
		local att = Instance.new("Attachment", targetRoot)
		local vel = Instance.new("LinearVelocity", att) 
		vel.MaxForce = math.huge 
		vel.VectorVelocity = (targetRoot.Position - root.Position).Unit * 650 + Vector3.new(0, 220, 0)
		local rot = Instance.new("AngularVelocity", att) 
		rot.MaxTorque = math.huge 
		rot.AngularVelocity = Vector3.new(800, 1200, 800)
		Debris:AddItem(att, 0.8)
	end
	
	-- Garante que o finisher termine
	task.delay(3, function()
		if isFinisherActive then
			endFinisher()
		end
	end)
	
	if barrageTrack then barrageTrack:Stop() end
	if playerBarrageTrack then playerBarrageTrack:Stop() end
	if sHum then idleTrack = playAnim(sHum, ASSETS.STAND_IDLE, 1, true, Enum.AnimationPriority.Idle) end
	
	-- Reset do combo apÃ³s a barrage
mudaComboCount = 0
if comboDisplay then
	comboDisplay:Destroy()
	comboDisplay = nil
end
	
	task.delay(0.6, function()
		if currentStand then
			local sRoot2 = currentStand:FindFirstChild("HumanoidRootPart")
			local root2 = character:FindFirstChild("HumanoidRootPart")
			if sRoot2 and root2 then 
				TweenService:Create(sRoot2, TweenInfo.new(0.4), {CFrame = root2.CFrame * CFrame.new(STAND_OFFSET)}):Play() 
			end
		end
		isAttacking = false
	end)
end

local function performKnifeThrow()
	if not canUse("Knife") then return end
	local isStandAttacking = (isStandActive and currentStand ~= nil)
	local attackerModel = isStandAttacking and currentStand or character
	local attackerRoot = attackerModel:FindFirstChild("HumanoidRootPart")
	local attackerHum = attackerModel:FindFirstChildOfClass("Humanoid")
	local charRoot = character:FindFirstChild("HumanoidRootPart")
	local camera = workspace.CurrentCamera
	if not attackerRoot or not attackerHum or not charRoot then return end
	
	local target = nil
	if isStandAttacking then 
		target = getClosestTarget(50) 
		if not target then 
			showSpeechBubble(102362181377695, "right", 2.5) 
			return 
		end 
	end
	
	isAttacking = true
	local shootDir = (isStandAttacking and target) and (target.Position - attackerRoot.Position).Unit or camera.CFrame.LookVector
	
	if not isStandAttacking then
		local lookTarget = charRoot.Position + Vector3.new(shootDir.X, 0, shootDir.Z)
		TweenService:Create(charRoot, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {CFrame = CFrame.lookAt(charRoot.Position, lookTarget)}):Play()
	end
	
	if isStandAttacking then
		local goalCF = target and CFrame.lookAt(charRoot.Position + (target.Position - charRoot.Position).Unit * 3.5, target.Position) or charRoot.CFrame * CFrame.new(0,0,-3.5)
		local tweenMove = TweenService:Create(attackerRoot, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {CFrame = goalCF})
		tweenMove:Play() 
		tweenMove.Completed:Wait()
	end
	
	local throwTrack
	if ASSETS.KNIFE_THROW_ANIM ~= "" then 
		if isStandAttacking and idleTrack then idleTrack:Stop() end 
		throwTrack = playAnim(attackerHum, ASSETS.KNIFE_THROW_ANIM, 3, false, Enum.AnimationPriority.Action)
		if throwTrack then throwTrack.Looped = false end 
	end
	
	local throwSound = Instance.new("Sound", workspace) 
	throwSound.SoundId = ASSETS.KNIFE_THROW_SOUND 
	throwSound:Play() 
	Debris:AddItem(throwSound, 3)
	
	local knifeCount = isStandAttacking and 2 or 1  -- Stand = 2 facas, DIO = 1 faca
for i = 1, knifeCount do
		if isStandAttacking and target and target.Parent and attackerRoot then
			shootDir = (target.Position - attackerRoot.Position).Unit
			local lookCF = CFrame.lookAt(attackerRoot.Position, target.Position)
			attackerRoot.CFrame = attackerRoot.CFrame:Lerp(lookCF, 0.5)
		end
		
		local knife = Instance.new("Part") 
		knife.Name = "DioKnife" 
		knife.Size = Vector3.new(1,1,1) 
		knife.CanCollide = false 
		knife.Parent = workspace
		
		local baseCFrame = CFrame.lookAt(attackerRoot.Position + Vector3.new((i-3)*0.8, 0.5, -1.5), attackerRoot.Position + Vector3.new((i-3)*0.8, 0.5, -1.5) + shootDir)
		knife.CFrame = baseCFrame * CFrame.Angles(math.rad(10), math.rad(-180), 0)
		
		local mesh = Instance.new("SpecialMesh", knife) 
		mesh.MeshId = "rbxassetid://15945983658" 
		mesh.TextureId = "rbxassetid://15946012483" 
		mesh.Scale = Vector3.new(1.2,1.2,1.8)
		
		local vel = Instance.new("LinearVelocity", knife) 
		vel.Attachment0 = Instance.new("Attachment", knife) 
		vel.MaxForce = math.huge 
		vel.VectorVelocity = shootDir * 280
		
		knife.Touched:Connect(function(hitPart)
    local hitHum = hitPart.Parent:FindFirstChildOfClass("Humanoid")
    if hitHum and hitHum.Parent ~= character and hitHum.Parent ~= currentStand then
        hitHum:TakeDamage(18)
        local hitSound = Instance.new("Sound", workspace) 
        hitSound.SoundId = ASSETS.KNIFE_HIT_SOUND 
        hitSound:Play() 
        Debris:AddItem(hitSound, 2)
        
        -- Remove a velocidade da faca
        if knife:FindFirstChild("LinearVelocity") then
            knife.LinearVelocity:Destroy()
        end
        
        --- FACA "CRAVADA" (cria uma faca decorativa IGUAL a original)
local stuckKnife = Instance.new("Part", workspace)
stuckKnife.Name = "StuckKnife"
stuckKnife.Size = Vector3.new(1, 1, 1) -- Tamanho base igual ao original
stuckKnife.CanCollide = false
stuckKnife.Anchored = false
stuckKnife.CFrame = knife.CFrame
stuckKnife.Transparency = 0
stuckKnife.Color = Color3.fromRGB(255, 255, 255) -- Cor branca pra não interferir na textura

--  MESMA MESH DA FACA ORIGINAL
local stuckMesh = Instance.new("SpecialMesh", stuckKnife)
stuckMesh.MeshId = "rbxassetid://15945983658"
stuckMesh.TextureId = "rbxassetid://15946012483"
stuckMesh.Scale = Vector3.new(1.2, 1.2, 1.8) -- Mesma escala

-- Faz a faca decorativa grudar no alvo
local stickWeld = Instance.new("WeldConstraint")
stickWeld.Part0 = stuckKnife
stickWeld.Part1 = hitPart
stickWeld.Parent = stuckKnife

Debris:AddItem(stuckKnife, 3)
        
        --  FINISHER: Matou com faca
        if hitHum.Health <= 0 and knife:GetAttribute("Finished") ~= true then
            knife:SetAttribute("Finished", true)
            
            showSpeechBubble("92536008979873", "right", 3, character.Head)
            
            local dioSound = Instance.new("Sound", workspace)
            dioSound.SoundId = "rbxassetid://110578259527952"
            dioSound.Volume = 1.5
            dioSound:Play()
            Debris:AddItem(dioSound, 3)
        end
        
        -- Destroi a faca original
        knife:Destroy()
    end
end)
		
		Debris:AddItem(knife, 4) 
		task.wait(0.06)
	end
	
	task.wait(0.2)
	if throwTrack then throwTrack:Stop() end
	if isStandAttacking and attackerHum then idleTrack = playAnim(attackerHum, ASSETS.STAND_IDLE, 1, true, Enum.AnimationPriority.Idle) end
	isAttacking = false
end

local function freezeCharacterOnSpawn(plr, char)
	if not isTimeStopped or plr == player then return end
	task.delay(0.2, function()
		if not char or not char.Parent then return end
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") and not part.Anchored and not (currentStand and part:IsDescendantOf(currentStand)) then
				frozenParts[part] = true 
				part.Anchored = true
			end
		end
	end)
end

for _, plr in ipairs(Players:GetPlayers()) do
	if plr ~= player then
		if plr.Character then freezeCharacterOnSpawn(plr, plr.Character) end
		plr.CharacterAdded:Connect(function(char) freezeCharacterOnSpawn(plr, char) end)
	end
end
Players.PlayerAdded:Connect(function(plr)
	if plr ~= player then plr.CharacterAdded:Connect(function(char) freezeCharacterOnSpawn(plr, char) end) end
end)

RunService.RenderStepped:Connect(function()
	if isStandActive and currentStand and not isAttacking then
		local root = character:FindFirstChild("HumanoidRootPart")
		local sRoot = currentStand:FindFirstChild("HumanoidRootPart")
		if root and sRoot then 
			sRoot.CFrame = sRoot.CFrame:Lerp(root.CFrame * CFrame.new(STAND_OFFSET), 0.1) 
		end
	end
end)

-- ==================== CONEXÃ•ES DOS BOTÃ•ES ====================
tsBtn.MouseButton1Click:Connect(toggleTime)
activateBtn.MouseButton1Click:Connect(toggleStand)
m1Btn.MouseButton1Click:Connect(performM1)
knifeBtn.MouseButton1Click:Connect(performKnifeThrow)
roadBtn.MouseButton1Click:Connect(performRoadRoller)   -- NOVO BOTÃƒO

task.spawn(function()
	local sequence = {COLORS.Yellow, COLORS.Black, COLORS.Green, COLORS.Black, COLORS.Purple, COLORS.Black}
	local i = 1
	while true do
		TweenService:Create(tsStroke, TweenInfo.new(0.7), {Color = sequence[i]}):Play()
		i = i % #sequence + 1 
		task.wait(0.7)
	end
end)

local function applyClickEffect(b, baseSize)
	b.MouseButton1Down:Connect(function() 
		TweenService:Create(b, TweenInfo.new(0.1), {Size = UDim2.fromOffset(baseSize - 8, baseSize - 8)}):Play() 
	end)
	b.MouseButton1Up:Connect(function() 
		TweenService:Create(b, TweenInfo.new(0.1), {Size = UDim2.fromOffset(baseSize, baseSize)}):Play() 
	end)
end

applyClickEffect(tsBtn, 80)       -- Time Stop = 80
applyClickEffect(roadBtn, 70)     -- Road Roller = 70
applyClickEffect(activateBtn, 95) -- Stand = 95
applyClickEffect(m1Btn, 80)       -- M1 = 80
-- Efeito de clique personalizado para o Knife (tamanho dinâmico)
knifeBtn.MouseButton1Down:Connect(function()
	local currentSize = knifeBtn.Size.X.Offset -- Pega o tamanho atual
	TweenService:Create(knifeBtn, TweenInfo.new(0.1), {
		Size = UDim2.fromOffset(currentSize - 8, currentSize - 8)
	}):Play()
end)

knifeBtn.MouseButton1Up:Connect(function()
	local isActive = isStandActive -- Stand ativo ou não
	local targetSize = isActive and 70 or 80 -- 70 se ativo, 80 se desativado
	TweenService:Create(knifeBtn, TweenInfo.new(0.1), {
		Size = UDim2.fromOffset(targetSize, targetSize)
	}):Play()
end)

updateKnifePosition(false)

player.CharacterAdded:Connect(function(newChar) 
	character = newChar 
	hum = newChar:WaitForChild("Humanoid") 
end)
