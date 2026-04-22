-- SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hum = character:WaitForChild("Humanoid")

--------------------------------------------------------------------------------
-- CONFIGURAÇÕES UNIVERSAIS
--------------------------------------------------------------------------------
local STAND_OFFSET = Vector3.new(3, 2.5, 2.5)
local isTimeStopped = false
local isStandActive = false
local isAttacking = false
local currentStand = nil
local idleTrack = nil
local frozenParts = {}

local COLORS = {
	Yellow = Color3.fromRGB(255, 215, 0),
	Green = Color3.fromRGB(0, 0, 0),
	Purple = Color3.fromRGB(0, 0, 0),
	Black = Color3.fromRGB(0, 0, 0)
}

local ASSETS = {
	TS_START_SFX = "rbxassetid://7514417921",
	TS_END_SFX = "rbxassetid://97139043906890",
	ANIM_DIO = "rbxassetid://108059270529140",
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
	KNIFE_IMAGE = "rbxassetid://128478684091020"
}

--------------------------------------------------------------------------------
-- NOVO: FUNÇÃO PARA CRIAR BALÕES DE TEXTO (IMAGENS PEQUENAS AO LADO DA CABEÇA)
-- ATUALIZADO: agora suporta mostrar no Stand (customHead) ou no player
--------------------------------------------------------------------------------
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
	
	local lateralDist = 1.8
	local altura = 1.5
	
	billboard.StudsOffset = Vector3.new(side == "right" and lateralDist or -lateralDist, altura, 0)
	
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.MaxDistance = 100
	billboard.Parent = head 
	
	local imageLabel = Instance.new("ImageLabel")
	imageLabel.Name = "BubbleImage"
	imageLabel.Size = UDim2.new(1, 0, 1, 0)
	imageLabel.BackgroundTransparency = 1
	imageLabel.Image = "rbxassetid://" .. imageId
	imageLabel.ImageTransparency = 1
	imageLabel.Parent = billboard
	
	TweenService:Create(imageLabel, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 0}):Play()
	
	task.delay(duration, function()
		if billboard and billboard.Parent then
			TweenService:Create(imageLabel, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {ImageTransparency = 1}):Play()
			task.delay(0.45, function()
				if billboard and billboard.Parent then
					billboard:Destroy()
				end
			end)
		end
	end)
end

--------------------------------------------------------------------------------
-- INTERFACE (UI) - FONTE JOJO STYLE
--------------------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui", player.PlayerGui)
screenGui.Name = "DioStandUniversal"
screenGui.ResetOnSpawn = false

-- ✅ POSIÇÕES DOS BOTÕES
local TS_POS       = UDim2.new(0.4, 0, 0.85, 0)
local ACTIVATE_POS = UDim2.new(0.5, 0, 0.85, 0)
local M1_POS       = UDim2.new(0.6, 0, 0.85, 0)
local KNIFE_POS_ON = UDim2.new(0.7, 0, 0.85, 0)
local KNIFE_POS_OFF = M1_POS

local function createCircularButton(name, pos, text, color, imageId)
	color = color or COLORS.Yellow
	
	local btn = Instance.new("TextButton", screenGui)
	btn.Name = name
	btn.Size = UDim2.fromOffset(85, 85)
	btn.Position = pos
	btn.AnchorPoint = Vector2.new(0.5, 0.5)
	btn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	btn.Text = text
	btn.TextColor3 = Color3.new(1, 1, 1)
	
	btn.Font = Enum.Font.Bangers
	btn.TextSize = 18
	btn.TextStrokeTransparency = 0
	btn.TextStrokeColor3 = Color3.new(0, 0, 0)
	btn.TextScaled = false
	
	btn.AutoButtonColor = false
	
	Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
	local stroke = Instance.new("UIStroke", btn)
	stroke.Color = color
	stroke.Thickness = 4
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	
	local icon = nil
	if imageId then
		icon = Instance.new("ImageLabel", btn)
		icon.Name = "Icon"
		icon.Size = UDim2.new(1, 0, 1, 0)
		icon.Position = UDim2.new(0.5, 0, 0.5, 0)
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.BackgroundTransparency = 1
		icon.Image = imageId
		icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
		icon.ScaleType = Enum.ScaleType.Fit
		icon.ZIndex = 2
	end
	
	return btn, stroke, icon
end

local tsBtn, tsStroke, tsIcon       = createCircularButton("TimeStopBtn", TS_POS, "STOP", nil, ASSETS.TS_IMAGE)
local activateBtn, actStroke, standIcon = createCircularButton("ActivateBtn", ACTIVATE_POS, "STAND", nil, ASSETS.STAND_IMAGE)
local m1Btn, m1Stroke       = createCircularButton("M1Btn", M1_POS, "M1")
local knifeBtn, knifeStroke, knifeIcon = createCircularButton("KnifeBtn", KNIFE_POS_OFF, "KNIFE", nil, ASSETS.KNIFE_IMAGE)

m1Btn.Visible = false
knifeBtn.Visible = true

-- IMAGEM DE DESATIVAÇÃO DO TIME STOP
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
	if isActive then
		icon.ImageColor3 = Color3.fromRGB(128, 128, 128)
	else
		icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
	end
end

updateIconState(tsIcon, false)
updateIconState(standIcon, false)
updateIconState(knifeIcon, false)

--------------------------------------------------------------------------------
-- FUNÇÃO PARA MOVER O BOTÃO KNIFE COM ANIMAÇÃO
--------------------------------------------------------------------------------
local function updateKnifePosition(isActive)
	local targetPos = isActive and KNIFE_POS_ON or KNIFE_POS_OFF
	
	TweenService:Create(
		knifeBtn,
		TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{Position = targetPos}
	):Play()
end

--------------------------------------------------------------------------------
-- LÓGICA DE ANIMAÇÃO
--------------------------------------------------------------------------------
local function playAnim(target, animId, speed)
	if not target or not target.Parent then return end
	local a = Instance.new("Animation")
	a.AnimationId = animId
	local track = target:LoadAnimation(a)
	track:Play()
	if speed then track:AdjustSpeed(speed) end
	return track
end

--------------------------------------------------------------------------------
-- FUNÇÃO getStandModel
--------------------------------------------------------------------------------
local function getStandModel()
	local model
	character.Archivable = true
	model = character:Clone()
	character.Archivable = false
	
	model.Name = "Stand"

	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.CanCollide = false
			p.Transparency = 1
			p.CastShadow = false
		elseif p:IsA("LocalScript") or p:IsA("Script") then 
			p:Destroy() 
		end
	end

	return model
end

--------------------------------------------------------------------------------
-- LÓGICA DO STAND
--------------------------------------------------------------------------------
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
		
		local m1TweenBack = TweenService:Create(
			m1Btn,
			TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{Position = ACTIVATE_POS}
		)
		m1TweenBack:Play()
		m1TweenBack.Completed:Connect(function(playbackState)
			if playbackState == Enum.PlaybackState.Completed then
				m1Btn.Visible = false
			end
		end)
		
		updateKnifePosition(false)
		updateIconState(standIcon, false)
		
	else
		isStandActive = true
		
		activateBtn.Text = "OFF"
		
		showSpeechBubble(81663476180868, "right", 2.5)
		
		m1Btn.Position = ACTIVATE_POS
		m1Btn.Visible = true
		TweenService:Create(
			m1Btn,
			TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{Position = M1_POS}
		):Play()
		
		currentStand = getStandModel()
		currentStand.Parent = workspace
		
		local sHum = currentStand:FindFirstChildOfClass("Humanoid")
		if sHum then
			sHum.PlatformStand = true
			sHum.AutoRotate = false
			sHum.HipHeight = 0
			
			local sRoot = currentStand:FindFirstChild("HumanoidRootPart")
			if sRoot then sRoot.Anchored = true end
			
			idleTrack = playAnim(sHum, ASSETS.STAND_IDLE)
		end

		for _, p in ipairs(currentStand:GetDescendants()) do
			if p:IsA("BasePart") then 
				p.Color = Color3.new(1,1,1)
				p.Transparency = 1
				TweenService:Create(p, TweenInfo.new(0.4), {Transparency = 0}):Play()
			end
		end
		
		updateKnifePosition(true)
		updateIconState(standIcon, true)
	end
end

--------------------------------------------------------------------------------
-- LÓGICA DO TIME STOP (sem alterações)
--------------------------------------------------------------------------------
local function toggleTime()
	if isTimeStopped then
		isTimeStopped = false
		tsBtn.Text = "STOP"
		local s = Instance.new("Sound", workspace); s.SoundId = ASSETS.TS_END_SFX; s:Play(); Debris:AddItem(s, 3)
		
		for part, _ in pairs(frozenParts) do 
			if part and part.Parent then part.Anchored = false end 
		end
		frozenParts = {}

		task.spawn(function()
			resumeImage.Visible = true
			resumeImage.ImageTransparency = 1
			
			local blinkInfo = TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			
			for i = 1, 4 do
				TweenService:Create(resumeImage, blinkInfo, {ImageTransparency = 0.35}):Play()
				task.wait(0.22)
				TweenService:Create(resumeImage, blinkInfo, {ImageTransparency = 0.88}):Play()
				task.wait(0.22)
			end
			
			TweenService:Create(resumeImage, TweenInfo.new(0.45), {ImageTransparency = 1}):Play()
			task.delay(0.6, function()
				resumeImage.Visible = false
			end)
		end)

		local cc = Lighting:FindFirstChild("TS_Effect")
		if cc then 
			TweenService:Create(cc, TweenInfo.new(0.4), {
				TintColor = Color3.fromRGB(170, 0, 255),
				Saturation = -1.0,
				Contrast = 0.7
			}):Play()

			task.delay(0.3, function()
				if isTimeStopped then return end
				TweenService:Create(cc, TweenInfo.new(0.4), {
					TintColor = Color3.fromRGB(0, 180, 255),
					Saturation = -0.5,
					Contrast = 0.6
				}):Play()
			end)

			task.delay(0.6, function()
				if isTimeStopped then return end
				TweenService:Create(cc, TweenInfo.new(0.4), {
					TintColor = Color3.fromRGB(255, 140, 0),
					Saturation = 1.2,
					Contrast = 0.8,
					Brightness = 0.3
				}):Play()
			end)

			task.delay(0.9, function()
				if isTimeStopped then return end
				TweenService:Create(cc, TweenInfo.new(0.6), {
					Saturation = 0,
					Contrast = 0,
					Brightness = 0,
					TintColor = Color3.fromRGB(255,255,255)
				}):Play()
				Debris:AddItem(cc, 0.7)
			end)
		end
		updateIconState(tsIcon, false)

	else
		isTimeStopped = true
		tsBtn.Text = "RESUME"
		
		local root = character:FindFirstChild("HumanoidRootPart")
		
		local s = Instance.new("Sound", workspace); s.SoundId = ASSETS.TS_START_SFX; s.Volume = 2; s:Play(); Debris:AddItem(s, 5)
		local tsAnimTrack = playAnim(hum, ASSETS.ANIM_DIO, 2)
		
		if root then root.Anchored = true end
		
		showSpeechBubble(106366607174396, "right", 4)
		
		task.delay(2, function()
			if not isTimeStopped then return end
			
			if root then root.Anchored = false end

			local cc = Lighting:FindFirstChild("TS_Effect") or Instance.new("ColorCorrectionEffect", Lighting)
			cc.Name = "TS_Effect"
			
			cc.Saturation = 0
			cc.Contrast = 0
			cc.Brightness = 0
			cc.TintColor = Color3.fromRGB(255, 140, 0)
			TweenService:Create(cc, TweenInfo.new(0.4), {
				Saturation = 1.5,
				Contrast = 0.8,
				Brightness = 0.2
			}):Play()

			task.delay(0.1, function()
				if not isTimeStopped then return end
				TweenService:Create(cc, TweenInfo.new(0.4), {
					TintColor = Color3.fromRGB(0, 180, 255),
					Saturation = -0.8,
					Contrast = 0.6,
					Brightness = 0
				}):Play()
			end)

			task.delay(0.2, function()
				if not isTimeStopped then return end
				TweenService:Create(cc, TweenInfo.new(0.4), {
					TintColor = Color3.fromRGB(170, 0, 255),
					Saturation = -1.1,
					Contrast = 0.7
				}):Play()
			end)

			task.delay(0.3, function()
				if not isTimeStopped then return end
				TweenService:Create(cc, TweenInfo.new(0.5), {
					Saturation = -1.2,
					Contrast = 0.5,
					Brightness = 0,
					TintColor = Color3.fromRGB(180, 200, 255)
				}):Play()
			end)

			frozenParts = {}
			for _, part in ipairs(workspace:GetDescendants()) do
				if part:IsA("BasePart") 
					and not part:IsDescendantOf(character) 
					and not (currentStand and part:IsDescendantOf(currentStand)) 
					and not part.Anchored then
					
					frozenParts[part] = true
					part.Anchored = true
				end
			end
		end)
		updateIconState(tsIcon, true)
	end
end

--------------------------------------------------------------------------------
-- ATAQUE M1 (MODIFICADO)
-- Agora: se não tiver alvo → mostra balão novo (102362181377695) e NÃO ataca
-- Se tiver alvo → mostra balão MUDA MUDA no STAND (não no player) e ataca
--------------------------------------------------------------------------------
local function performM1()
	if not isStandActive or not currentStand or isAttacking then return end
	
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	
	local closest = nil
	local minDist = 12
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
			local d = (p.Character.HumanoidRootPart.Position - root.Position).Magnitude
			if d < minDist then 
				minDist = d
				closest = p.Character
			end
		end
	end
	
	if not closest then 
		showSpeechBubble(102362181377695, "right", 2.5)
		return 
	end
	
	isAttacking = true
	
	-- Balão MUDA MUDA agora aparece NO STAND (com o mesmo offset lateral)
	local standHead = currentStand:FindFirstChild("Head")
	showSpeechBubble(82682258182370, "left", 4, standHead)
	
	local targetRoot = closest:FindFirstChild("HumanoidRootPart")
	local targetHum = closest:FindFirstChildOfClass("Humanoid")
	
	if not targetRoot or not targetHum then 
		isAttacking = false
		return 
	end
	
	local sRoot = currentStand:FindFirstChild("HumanoidRootPart")
	local sHum = currentStand:FindFirstChildOfClass("Humanoid")
	
	if sRoot then
		local basePos = targetRoot.CFrame * CFrame.new(0, 2, -4)
		local attackCFrame = CFrame.lookAt(basePos.Position, targetRoot.Position)
		TweenService:Create(sRoot, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {CFrame = attackCFrame}):Play()
	end
	
	local barrageTrack = nil
	local playerBarrageTrack = nil
	
	if sHum then
		if idleTrack and idleTrack.IsPlaying then idleTrack:Stop() end
		barrageTrack = playAnim(sHum, ASSETS.BARRAGE_ANIM, 2.5)
	end
	
	if hum and ASSETS.PLAYER_BARRAGE and ASSETS.PLAYER_BARRAGE ~= "" then
		playerBarrageTrack = playAnim(hum, ASSETS.PLAYER_BARRAGE, 1)
	end
	
	local mudaSound = Instance.new("Sound", workspace)
	mudaSound.SoundId = ASSETS.MUDA_SOUND
	mudaSound.Volume = 1.2
	mudaSound:Play()
	Debris:AddItem(mudaSound, 6)
	
	local NUM_HITS = 46
	for i = 1, NUM_HITS do
		if targetRoot and targetRoot.Parent and targetHum and targetHum.Parent then
			targetHum:TakeDamage(1)
			targetRoot:ApplyImpulse((targetRoot.Position - root.Position).Unit * 12000 + Vector3.new(0, 8000, 0))
			
			local hit = Instance.new("Part")
			hit.Size = Vector3.new(1,1,1)
			hit.Color = Color3.fromRGB(255, 0, 100)
			hit.Transparency = 0.3
			hit.Anchored = true
			hit.CanCollide = false
			hit.CFrame = targetRoot.CFrame
			hit.Parent = workspace
			TweenService:Create(hit, TweenInfo.new(0.4), {Transparency = 1, Size = Vector3.new(4,4,4)}):Play()
			Debris:AddItem(hit, 0.5)
		end
		task.wait(0.065)
	end
	
	if barrageTrack then barrageTrack:Stop() end
	if playerBarrageTrack then playerBarrageTrack:Stop() end
	
	if sHum then
		idleTrack = playAnim(sHum, ASSETS.STAND_IDLE)
	end
	
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
	
	task.delay(0.5, function()
		if currentStand then
			local sRoot2 = currentStand:FindFirstChild("HumanoidRootPart")
			local root2 = character:FindFirstChild("HumanoidRootPart")
			if sRoot2 and root2 then
				local normalPos = root2.CFrame * CFrame.new(STAND_OFFSET)
				TweenService:Create(sRoot2, TweenInfo.new(0.4), {CFrame = normalPos}):Play()
			end
		end
		isAttacking = false
	end)
end

--------------------------------------------------------------------------------
-- KNIFE THROW HÍBRIDO (MODIFICADO)
-- Agora: se estiver com Stand ativo e NÃO tiver alvo na área (50 studs) → 
-- mostra balão novo (102362181377695) e NÃO ativa o throw
-- Se tiver alvo → mostra balão HMPH e atira normalmente
--------------------------------------------------------------------------------
local function getClosestTarget(maxDist)
    local closest = nil
    local minDist = maxDist
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Humanoid") and obj.Parent ~= character and (not currentStand or obj.Parent ~= currentStand) then
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

local function performKnifeThrow()
	local isStandAttacking = (isStandActive and currentStand ~= nil)
	local attackerModel = isStandAttacking and currentStand or character
	local attackerRoot = attackerModel:FindFirstChild("HumanoidRootPart")
	local attackerHum = attackerModel:FindFirstChildOfClass("Humanoid")
	local charRoot = character:FindFirstChild("HumanoidRootPart")
	local camera = workspace.CurrentCamera
	
	if not attackerRoot or not attackerHum or not charRoot then return end

	-- NOVO: verificação de alvo ANTES de ativar o ataque (só para Stand)
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
		local targetRotation = CFrame.lookAt(charRoot.Position, lookTarget)
		
		TweenService:Create(charRoot, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {CFrame = targetRotation}):Play()
	end

	if isStandAttacking then
		local goalCF
		if target then
			local directionToTarget = (target.Position - charRoot.Position).Unit
			local spawnPos = charRoot.Position + (directionToTarget * 3.5)
			goalCF = CFrame.lookAt(spawnPos, target.Position)
		else
			goalCF = charRoot.CFrame * CFrame.new(0, 0, -3.5)
		end

		local tweenMove = TweenService:Create(attackerRoot, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {CFrame = goalCF})
		tweenMove:Play()
		tweenMove.Completed:Wait()
	end

	local throwTrack = nil
	if ASSETS.KNIFE_THROW_ANIM ~= "" then
		if isStandAttacking and idleTrack then idleTrack:Stop() end
		throwTrack = playAnim(attackerHum, ASSETS.KNIFE_THROW_ANIM, 2) 
		if throwTrack then throwTrack.Looped = false end
	end

	local throwSound = Instance.new("Sound", workspace)
	throwSound.SoundId = ASSETS.KNIFE_THROW_SOUND
	throwSound:Play()
	Debris:AddItem(throwSound, 3)

	-- Balão HMPH agora só aparece se tiver alvo (já garantido pelo check acima)
	if isStandAttacking then
		showSpeechBubble(92536008979873, "right", 1.5)
	end

	for i = 1, 5 do
		local knife = Instance.new("Part")
		knife.Name = "DioKnife"
		knife.Size = Vector3.new(1, 1, 1)
		
		knife.CFrame = attackerRoot.CFrame * CFrame.new((i-3)*0.8, 0.5, -1.5)
		local baseCFrame = CFrame.lookAt(knife.Position, knife.Position + shootDir)

-- Use math.rad() para converter graus em radianos
-- Teste mudar os valores de 90 em 90 graus em X, Y ou Z
local rotacaoAjustada = CFrame.Angles(math.rad(10), math.rad(-180), math.rad(0)) 

knife.CFrame = baseCFrame * rotacaoAjustada
		knife.CanCollide = false
		knife.Parent = workspace
		
		local mesh = Instance.new("SpecialMesh", knife)
		mesh.MeshId = "rbxassetid://15945983658"
		mesh.TextureId = "rbxassetid://15946012483"
		mesh.Scale = Vector3.new(1.2, 1.2, 1.8)
		
		local vel = Instance.new("LinearVelocity", knife)
		vel.Attachment0 = Instance.new("Attachment", knife)
		vel.MaxForce = math.huge
		vel.VectorVelocity = shootDir * 280
		
		local hitConnection
		hitConnection = knife.Touched:Connect(function(hitPart)
			local hitHum = hitPart.Parent:FindFirstChildOfClass("Humanoid")
			if hitHum and hitHum.Parent ~= character and hitHum.Parent ~= currentStand then
				hitHum:TakeDamage(18)
				local hitSound = Instance.new("Sound", workspace)
				hitSound.SoundId = ASSETS.KNIFE_HIT_SOUND
				hitSound:Play()
				Debris:AddItem(hitSound, 2)
				knife:Destroy()
				hitConnection:Disconnect()
			end
		end)
		
		Debris:AddItem(knife, 4)
		task.wait(0.06)
	end

	task.wait(0.2)
	if throwTrack then throwTrack:Stop() end
	if isStandAttacking and attackerHum then 
		idleTrack = playAnim(attackerHum, ASSETS.STAND_IDLE)
	end
	
	isAttacking = false 
end

--------------------------------------------------------------------------------
-- LÓGICA DE CONGELAMENTO PARA PLAYERS QUE RESPAWNAM
--------------------------------------------------------------------------------
local function freezeCharacterOnSpawn(plr, char)
	if not isTimeStopped or plr == player then return end
	
	task.delay(0.2, function()
		if not char or not char.Parent then return end
		
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") 
				and not part.Anchored 
				and not (currentStand and part:IsDescendantOf(currentStand)) then
				
				frozenParts[part] = true
				part.Anchored = true
			end
		end
	end)
end

local function setupRespawnFreezing()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player then
			if plr.Character then
				freezeCharacterOnSpawn(plr, plr.Character)
			end
			plr.CharacterAdded:Connect(function(char)
				freezeCharacterOnSpawn(plr, char)
			end)
		end
	end
	
	Players.PlayerAdded:Connect(function(plr)
		if plr ~= player then
			plr.CharacterAdded:Connect(function(char)
				freezeCharacterOnSpawn(plr, char)
			end)
			if plr.Character then
				freezeCharacterOnSpawn(plr, plr.Character)
			end
		end
	end)
end

setupRespawnFreezing()

--------------------------------------------------------------------------------
-- CONEXÕES E LOOPS
--------------------------------------------------------------------------------
RunService.RenderStepped:Connect(function()
	if isStandActive and currentStand and not isAttacking then
		local root = character:FindFirstChild("HumanoidRootPart")
		local sRoot = currentStand:FindFirstChild("HumanoidRootPart")
		if root and sRoot then
			local targetCF = root.CFrame * CFrame.new(STAND_OFFSET)
			sRoot.CFrame = sRoot.CFrame:Lerp(targetCF, 0.1)
		end
	end
end)

tsBtn.MouseButton1Click:Connect(toggleTime)
activateBtn.MouseButton1Click:Connect(toggleStand)
m1Btn.MouseButton1Click:Connect(performM1)
knifeBtn.MouseButton1Click:Connect(performKnifeThrow)

task.spawn(function()
	local sequence = {COLORS.Yellow, COLORS.Black, COLORS.Green, COLORS.Black, COLORS.Purple, COLORS.Black}
	local i = 1
	while true do
		TweenService:Create(tsStroke, TweenInfo.new(0.7), {Color = sequence[i]}):Play()
		i = i % #sequence + 1
		task.wait(0.7)
	end
end)

local function applyClickEffect(b)
	b.MouseButton1Down:Connect(function() TweenService:Create(b, TweenInfo.new(0.1), {Size = UDim2.fromOffset(75, 75)}):Play() end)
	b.MouseButton1Up:Connect(function() TweenService:Create(b, TweenInfo.new(0.1), {Size = UDim2.fromOffset(85, 85)}):Play() end)
end
applyClickEffect(tsBtn)
applyClickEffect(activateBtn)
applyClickEffect(m1Btn)
applyClickEffect(knifeBtn)

updateKnifePosition(false)

player.CharacterAdded:Connect(function(newChar)
	character = newChar
	hum = newChar:WaitForChild("Humanoid")
end)
