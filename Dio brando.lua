local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hum = character:WaitForChild("Humanoid")

local ACCESSORY_TAG = "DioAccessory"

local httpService = game:GetService("HttpService")

-- ============================================================
-- SISTEMA DE SALVAMENTO JSON MELHORADO (Corrigido)
-- ============================================================

local ARQUIVO_CONFIG = "dio_stand_config.json"

-- Função para salvar o ID (versão mais confiável)
local function salvarStandId(userId)
    userId = tonumber(userId) or 0
    
    local config = {
        lastUserId = userId,
        lastUsed = os.time()
    }
    
    local sucesso, erro = pcall(function()
        local jsonData = httpService:JSONEncode(config)
        writefile(ARQUIVO_CONFIG, jsonData)
    end)
    
    if sucesso then
        print("💾 ID do Stand salvo com sucesso: " .. tostring(userId))
        customStandUserId = userId > 0 and userId or nil
    else
        warn("❌ Erro ao salvar JSON: " .. tostring(erro))
        -- Tentativa de fallback
        pcall(function()
            writefile(ARQUIVO_CONFIG, '{"lastUserId":' .. userId .. ',"lastUsed":' .. os.time() .. '}')
        end)
    end
end

-- Função para carregar o ID
local function carregarStandId()
    if not isfile(ARQUIVO_CONFIG) then
        print("📄 Nenhum arquivo de configuração encontrado. Usando padrão.")
        return nil
    end
    
    local sucesso, conteudo = pcall(function()
        return readfile(ARQUIVO_CONFIG)
    end)
    
    if not sucesso or not conteudo then
        warn("⚠️ Erro ao ler o arquivo JSON")
        return nil
    end
    
    local sucesso2, config = pcall(function()
        return httpService:JSONDecode(conteudo)
    end)
    
    if sucesso2 and config and config.lastUserId ~= nil then
        print("📂 ID do Stand carregado: " .. tostring(config.lastUserId))
        return tonumber(config.lastUserId)
    else
        warn("⚠️ JSON inválido ou corrompido. Usando padrão.")
        return nil
    end
end

-- Função para deletar o arquivo (usada no RESET)
local function deletarArquivoConfig()
    if isfile(ARQUIVO_CONFIG) then
        local sucesso = pcall(function()
            delfile(ARQUIVO_CONFIG)
        end)
        if sucesso then
            print("🗑️ Arquivo de configuração deletado com sucesso!")
        else
            warn("⚠️ Não foi possível deletar o arquivo JSON")
        end
    end
end

-- =========================================================
-- SISTEMA DE ANIMAÇÕES CUSTOMIZADAS (CORRIGIDO E MELHORADO)
-- =========================================================

local CUSTOM_ANIMS = {
    Idle         = "rbxassetid://101516194765447",
    Walk         = "rbxassetid://89251806503217",
    Run          = "rbxassetid://101871663749983",
    JumpRunning  = "rbxassetid://131814798893284",
    JumpStanding = "rbxassetid://131814798893284",
    IdleVariant  = "rbxassetid://133201196209194",
    Fall         = "rbxassetid://122194794537519",
    SRun         = "rbxassetid://121350640829746",
}

local SETTINGS = {
    JumpPower          = 50,
    Enabled            = true,
    FootprintInterval  = 0.32,
    RunAnimSpeed       = 1.5,
    SRunAnimSpeed      = 3,
    SRunRestartInterval = 1.3
}

local originalIDs_anim = {}
local originalWalkSpeed_anim = 16
local jumpingConnection_anim = nil
local activeJumpTrack_anim = nil
local jumpStateConnection_anim = nil
local footprintConnection_anim = nil
local lastFootprintTime_anim = 0
local alternateFoot_anim = true
local idleVariantTrack_anim = nil
local idleTimer_anim = nil
local isIdle_anim = false
local sRunTrack_anim = nil
local lastSRunTime_anim = 0

local function loadCustomAnim(animationId)
    if not hum or not hum:FindFirstChild("Animator") then return nil end
    local anim = Instance.new("Animation")
    anim.AnimationId = animationId
    return hum.Animator:LoadAnimation(anim)
end

local function safeSetAnim(animate, path, id)
    local obj = animate
    for i, key in ipairs(path) do
        local child = obj:FindFirstChild(key)
        if not child then
            if i == #path then
                child = Instance.new("Animation")
                child.Name = key
            else
                child = Instance.new("Folder")
                child.Name = key
            end
            child.Parent = obj
        end
        obj = child
    end
    if obj:IsA("Animation") then
        obj.AnimationId = id
    end
end

-- =========================================================
-- SISTEMA IDLE VARIANT - VERSÃO LIMPA E CORRIGIDA
-- =========================================================

-- CONFIGURAÇÕES (troque os IDs pelos seus)
local IDLE_VARIANT_SETTINGS = {
    AnimId = "rbxassetid://133201196209194",      -- Animação
    SoundId = "rbxassetid://119056579190272",     -- Som
    SpeechId = "107413276128350",                 -- Imagem do balão
    WaitTime = 10,                                 -- Segundos parado
    SoundVolume = 1.8,
    SpeechDuration = 3,
    SpeechSide = "right"
}

-- VARIÁVEIS INTERNAS
local idleVariant_Track = nil
local idleVariant_Timer = 0
local idleVariant_Active = false

-- ==================== FUNÇÃO PRINCIPAL ====================
local function playIdleVariant()
    if not hum or not character then return end
    
    -- Para animação anterior se existir
    if idleVariant_Track then
        pcall(function() idleVariant_Track:Stop() end)
        idleVariant_Track = nil
    end
    
    -- Toca a animação
local anim = Instance.new("Animation")
anim.AnimationId = IDLE_VARIANT_SETTINGS.AnimId
idleVariant_Track = hum:LoadAnimation(anim)

if idleVariant_Track then
    idleVariant_Track.Looped = false      
    idleVariant_Track.Priority = Enum.AnimationPriority.Idle
    idleVariant_Track:Play(0.3)
    idleVariant_Track:AdjustSpeed(1.4)      
end
    
    -- 🔊 SOM
    local head = character:FindFirstChild("Head")
    local sound = Instance.new("Sound")
    sound.SoundId = IDLE_VARIANT_SETTINGS.SoundId
    sound.Volume = IDLE_VARIANT_SETTINGS.SoundVolume
    sound.Parent = head or character:FindFirstChild("HumanoidRootPart") or workspace
    sound:Play()
    game.Debris:AddItem(sound, 6)
    
    -- 💬 BALÃO DE FALA COM ANIMAÇÃO
if head then
    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = head
    billboard.Size = UDim2.new(3.5, 0, 3.5, 0)
    billboard.StudsOffset = Vector3.new(
        IDLE_VARIANT_SETTINGS.SpeechSide == "right" and 1.8 or -1.8,
        1.5,
        0
    )
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.MaxDistance = 100
    billboard.Parent = head

    local imageLabel = Instance.new("ImageLabel")
    imageLabel.BackgroundTransparency = 1
    imageLabel.Image = "rbxassetid://" .. IDLE_VARIANT_SETTINGS.SpeechId
    imageLabel.Size = UDim2.new(0.1, 0, 0.1, 0)  -- Começa pequeno
    imageLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
    imageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    imageLabel.ImageTransparency = 1  -- Começa invisível
    imageLabel.Rotation = -15  -- Começa levemente inclinado
    imageLabel.Parent = billboard
    
    -- ANIMAÇÃO DE ENTRADA: cresce, aparece, gira e balança
    TweenService:Create(imageLabel, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(1.1, 0, 1.1, 0),  -- Cresce um pouco maior
        ImageTransparency = 0,
        Rotation = 0
    }):Play()
    
    -- Depois de crescer, volta ao tamanho normal (efeito de "pop")
    task.delay(0.4, function()
        if imageLabel and imageLabel.Parent then
            TweenService:Create(imageLabel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(1, 0, 1, 0)  -- Volta ao normal
            }):Play()
        end
    end)
    
    -- Efeito de pulsar suave enquanto está visível
    task.delay(0.6, function()
        if imageLabel and imageLabel.Parent then
            -- Pulsa 3 vezes
            for i = 1, 3 do
                TweenService:Create(imageLabel, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    Size = UDim2.new(1.05, 0, 1.05, 0)
                }):Play()
                task.wait(0.3)
                TweenService:Create(imageLabel, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    Size = UDim2.new(1, 0, 1, 0)
                }):Play()
                task.wait(0.3)
            end
        end
    end)

    -- Remove o balão com animação de saída
    task.delay(IDLE_VARIANT_SETTINGS.SpeechDuration - 0.4, function()
        if billboard and billboard.Parent then
            TweenService:Create(imageLabel, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Size = UDim2.new(0.1, 0, 0.1, 0),  -- Encolhe
                ImageTransparency = 1,  -- Desaparece
                Rotation = 15  -- Gira ao sair
            }):Play()
            
            task.delay(0.4, function()
                if billboard and billboard.Parent then
                    billboard:Destroy()
                end
            end)
        end
    end)
end
    
    -- Quando a animação terminar, avisa que pode resetar
    if idleVariant_Track then
        idleVariant_Track.Stopped:Once(function()
            idleVariant_Track = nil
            -- Se ainda estiver parado, reseta o timer para tocar de novo
            if idleVariant_Active then
                idleVariant_Timer = 0
            end
        end)
    end
end

-- ==================== VERIFICAÇÃO DE IDLE ====================
local function checkIdleStatus(deltaTime)
    if not hum or not character then return end
    
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    -- Velocidade horizontal
    local speed = Vector3.new(root.Velocity.X, 0, root.Velocity.Z).Magnitude
    
    -- Se estiver se movendo, reseta TUDO
    if speed > 2 then
        idleVariant_Timer = 0
        idleVariant_Active = false
        
        -- Para a animação se estiver tocando
        if idleVariant_Track then
            pcall(function() idleVariant_Track:Stop() end)
            idleVariant_Track = nil
        end
        return
    end
    
    -- Se está parado, acumula tempo
    idleVariant_Timer = idleVariant_Timer + deltaTime
    
    -- Se atingiu o tempo e não está ativo
    if idleVariant_Timer >= IDLE_VARIANT_SETTINGS.WaitTime and not idleVariant_Active then
        idleVariant_Active = true
        playIdleVariant()
    end
    
    -- Se a animação já terminou e ainda está parado, permite tocar de novo
    if idleVariant_Timer >= IDLE_VARIANT_SETTINGS.WaitTime and idleVariant_Active and not idleVariant_Track then
        idleVariant_Active = false
        idleVariant_Timer = 0
    end
end

-- ==================== CONECTAR AO LOOP ====================
RunService.Heartbeat:Connect(function(deltaTime)
    checkIdleStatus(deltaTime)
end)

-- ==================== RESETAR AO MORRER ====================
player.CharacterAdded:Connect(function(newChar)
    idleVariant_Timer = 0
    idleVariant_Active = false
    if idleVariant_Track then
        pcall(function() idleVariant_Track:Stop() end)
        idleVariant_Track = nil
    end
end)

-- ====================== OUTRAS FUNÇÕES DE ANIMAÇÃO ======================

local function updateNormalRunSpeed_anim()
    if not hum or not SETTINGS.Enabled then return end
    for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
        if track and track.Animation and track.Animation.AnimationId == CUSTOM_ANIMS.Run then
            pcall(function()
                track.Speed = SETTINGS.RunAnimSpeed
            end)
        end
    end
end

local function updateRunAnimation_anim()
    if not hum or not character or not SETTINGS.Enabled then
        if sRunTrack_anim then 
            pcall(function() sRunTrack_anim:Stop(0.2) end) 
            sRunTrack_anim = nil 
        end
        return
    end

    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local horizSpeed = Vector3.new(root.Velocity.X, 0, root.Velocity.Z).Magnitude

    if horizSpeed > 20 then
        if not sRunTrack_anim then
            sRunTrack_anim = loadCustomAnim(CUSTOM_ANIMS.SRun)
            if not sRunTrack_anim then return end
            sRunTrack_anim.Looped = false
            sRunTrack_anim.Priority = Enum.AnimationPriority.Movement
        end

        local now = os.clock()
        if (now - lastSRunTime_anim >= SETTINGS.SRunRestartInterval) or not sRunTrack_anim.IsPlaying then
            if sRunTrack_anim.IsPlaying then sRunTrack_anim:Stop(0) end
            sRunTrack_anim:Play(0.1, 1, SETTINGS.SRunAnimSpeed)
            lastSRunTime_anim = now
        end
    else
        if sRunTrack_anim then
            pcall(function() sRunTrack_anim:Stop(0.2) end)
            sRunTrack_anim = nil
        end
        lastSRunTime_anim = 0
    end
end

local function spawnFootprint_anim(root)
    if not root then return end
    local rayOrigin = root.Position - Vector3.new(0, 2.8, 0)
    local rayDirection = Vector3.new(0, -6, 0)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {character}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    if not result then return end

    local hitPos = result.Position
    local hitNormal = result.Normal
    local groundColor = Color3.fromRGB(80, 80, 80)
    if result.Instance:IsA("Terrain") then
        groundColor = workspace.Terrain:GetMaterialColor(result.Material)
    elseif result.Instance:IsA("BasePart") then
        groundColor = result.Instance.Color
    end

    local darkenedColor = Color3.new(groundColor.R * 0.65, groundColor.G * 0.65, groundColor.B * 0.65)
    local footprint = Instance.new("Part")
    local footSize = Vector3.new(1.2, 0.08, 2.2)

    if character then
        local footPart = alternateFoot_anim and (character:FindFirstChild("RightFoot") or character:FindFirstChild("Right Leg")) 
                        or (character:FindFirstChild("LeftFoot") or character:FindFirstChild("Left Leg"))
        if footPart and footPart:IsA("BasePart") then
            footSize = Vector3.new(footPart.Size.X * 1.1, 0.08, footPart.Size.Z * 1.15)
        end
    end

    footprint.Size = footSize
    footprint.Color = darkenedColor
    footprint.Transparency = 0
    footprint.Anchored = true
    footprint.CanCollide = false
    footprint.Material = Enum.Material.SmoothPlastic
    footprint.Parent = workspace

    local rightVector = root.CFrame.RightVector
    local sideOffset = alternateFoot_anim and (rightVector * 0.65) or (-rightVector * 0.65)
    footprint.CFrame = CFrame.new(hitPos + hitNormal * 0.06 + sideOffset) * CFrame.Angles(0, root.CFrame.Rotation.Y, 0)

    local fadeTween = TweenService:Create(footprint, TweenInfo.new(2.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1})
    fadeTween:Play()
    fadeTween.Completed:Connect(function() footprint:Destroy() end)
end

local function cleanupCustomAnims()
    -- Reseta o IdleVariant
    idleVariant_Timer = 0
    idleVariant_Active = false
    if idleVariant_Track then
        pcall(function() idleVariant_Track:Stop() end)
        idleVariant_Track = nil
    end

    if sRunTrack_anim then 
        pcall(function() sRunTrack_anim:Stop() end) 
        sRunTrack_anim = nil 
    end
    lastSRunTime_anim = 0

    if footprintConnection_anim then footprintConnection_anim:Disconnect() footprintConnection_anim = nil end
    if jumpingConnection_anim then jumpingConnection_anim:Disconnect() jumpingConnection_anim = nil end
    if jumpStateConnection_anim then jumpStateConnection_anim:Disconnect() jumpStateConnection_anim = nil end

    lastFootprintTime_anim = 0
    if hum then hum.JumpPower = SETTINGS.JumpPower end
end

local function setCustomAnims()
    if not character then return end
    local animate = character:FindFirstChild("Animate")
    if not animate then return end

    local ids
    if not SETTINGS.Enabled then
        ids = originalIDs_anim
    else
        ids = {
            Idle = CUSTOM_ANIMS.Idle, 
            Idle2 = CUSTOM_ANIMS.Idle,
            Walk = CUSTOM_ANIMS.Walk, 
            Run = CUSTOM_ANIMS.Run,
            Fall = CUSTOM_ANIMS.Fall
        }
    end

    safeSetAnim(animate, {"idle", "Animation1"}, ids.Idle)
    safeSetAnim(animate, {"idle", "Animation2"}, ids.Idle2 or ids.Idle)
    safeSetAnim(animate, {"walk", "WalkAnim"}, ids.Walk)
    safeSetAnim(animate, {"run", "RunAnim"}, ids.Run)
    safeSetAnim(animate, {"fall", "FallAnim"}, ids.Fall)
    
    -- Refresh animations
    if character and hum then
        for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
            track:Stop(0)
        end
        local animate2 = character:FindFirstChild("Animate")
        if animate2 then
            animate2.Disabled = true
            task.wait(0.08)
            animate2.Disabled = false
        end
    end
    
    if hum then hum.WalkSpeed = originalWalkSpeed_anim end
end

local function onCharacterAddedCustomAnims(char)
    cleanupCustomAnims()
    character = char
    hum = char:WaitForChild("Humanoid")
    
    originalWalkSpeed_anim = hum.WalkSpeed

    local animate = char:WaitForChild("Animate", 5)  -- espera no máximo 5 segundos

if animate then
    animate:WaitForChild("idle", 3)
    animate:WaitForChild("walk", 3)
    animate:WaitForChild("run", 3)
    animate:WaitForChild("fall", 3)
else
    warn("[DioStand] Animate não encontrado no personagem!")
end
    
    local anim2Id = animate.idle.Animation1.AnimationId
    if animate.idle:FindFirstChild("Animation2") then 
        anim2Id = animate.idle.Animation2.AnimationId 
    end
    
    local fallId = ""
    if animate.fall and animate.fall:FindFirstChild("FallAnim") then 
        fallId = animate.fall.FallAnim.AnimationId 
    end
    
    originalIDs_anim = {
        Idle  = animate.idle.Animation1.AnimationId,
        Idle2 = anim2Id,
        Walk  = animate.walk.WalkAnim.AnimationId,
        Run   = animate.run.RunAnim.AnimationId,
        Fall  = fallId
    }

    hum.JumpPower = SETTINGS.JumpPower
    setCustomAnims()

    -- Conexões de Jumping
    if jumpingConnection_anim then jumpingConnection_anim:Disconnect() end
    jumpingConnection_anim = hum.Jumping:Connect(function()
        if not SETTINGS.Enabled then return end
        local root = character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local speed = Vector3.new(root.Velocity.X, 0, root.Velocity.Z).Magnitude
        local animId = speed >= 8 and CUSTOM_ANIMS.JumpRunning or CUSTOM_ANIMS.JumpStanding
        
        if activeJumpTrack_anim and activeJumpTrack_anim.IsPlaying then 
            activeJumpTrack_anim:Stop(0.2) 
        end
        
        activeJumpTrack_anim = loadCustomAnim(animId)
        if not activeJumpTrack_anim then return end
        activeJumpTrack_anim.Looped = false
        activeJumpTrack_anim.Priority = Enum.AnimationPriority.Movement
        activeJumpTrack_anim:Play(0.3)
        activeJumpTrack_anim.Stopped:Once(function() activeJumpTrack_anim = nil end)
    end)

    if jumpStateConnection_anim then jumpStateConnection_anim:Disconnect() end
    jumpStateConnection_anim = hum.StateChanged:Connect(function(oldState, newState)
        if activeJumpTrack_anim and activeJumpTrack_anim.IsPlaying then
            if newState ~= Enum.HumanoidStateType.Jumping and newState ~= Enum.HumanoidStateType.Freefall then
                activeJumpTrack_anim:Stop(0.15)
            end
        end
    end)

    -- Heartbeat para pegadas e animações
    if footprintConnection_anim then footprintConnection_anim:Disconnect() end
    footprintConnection_anim = RunService.Heartbeat:Connect(function()
        updateRunAnimation_anim()
        updateNormalRunSpeed_anim()
        
        if not character or not hum then return end
        local root = character:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local horizSpeed = Vector3.new(root.Velocity.X, 0, root.Velocity.Z).Magnitude
        if horizSpeed >= 15 and (os.clock() - lastFootprintTime_anim >= SETTINGS.FootprintInterval) then
            spawnFootprint_anim(root)
            lastFootprintTime_anim = os.clock()
            alternateFoot_anim = not alternateFoot_anim
        end
    end)
end

player.CharacterRemoving:Connect(cleanupCustomAnims)
player.CharacterAdded:Connect(onCharacterAddedCustomAnims)
if player.Character then onCharacterAddedCustomAnims(player.Character) end

-- Motion Blur e Vento
local Camera = workspace.CurrentCamera
local blurEffect = Instance.new("BlurEffect")
blurEffect.Name = "TzeMotionBlur"
blurEffect.Size = 0
blurEffect.Parent = Lighting

local windAttachment = nil
local windEmitter = nil

local function createWindParticles()
    if windEmitter then return end
    windAttachment = Instance.new("Attachment")
    windAttachment.Parent = Camera
    windEmitter = Instance.new("ParticleEmitter")
    windEmitter.Name = "TzeWindParticles"
    windEmitter.Texture = "rbxassetid://241650885"
    windEmitter.Color = ColorSequence.new(Color3.fromRGB(200, 230, 255))
    windEmitter.LightEmission = 0.7
    windEmitter.Rate = 0
    windEmitter.Lifetime = NumberRange.new(0.45, 0.9)
    windEmitter.Speed = NumberRange.new(110, 160)
    windEmitter.SpreadAngle = Vector2.new(35, 35)
    windEmitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(0.4, 0.07), NumberSequenceKeypoint.new(1, 0.01)})
    windEmitter.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1)})
    windEmitter.Rotation = NumberRange.new(-120, 120)
    windEmitter.Acceleration = Vector3.new(0, -12, 0)
    windEmitter.Parent = windAttachment
end

local isSRunning_wind = false
local lastCameraCFrame_wind = Camera.CFrame

RunService.RenderStepped:Connect(function(dt)
    if not Camera then return end
    local currentCFrame = Camera.CFrame
    local rotDiff = lastCameraCFrame_wind.Rotation:Inverse() * currentCFrame.Rotation
    local _, yaw, _ = rotDiff:ToEulerAnglesYXZ()
    local turnSpeed = math.abs(yaw) / dt
    if turnSpeed > 3.5 then
        blurEffect.Size = math.clamp(turnSpeed * 1.2, 0, 9)
    else
        blurEffect.Size = math.max(blurEffect.Size - 45 * dt, 0)
    end
    lastCameraCFrame_wind = currentCFrame

    local speed = 0
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root then
        local vel = root.Velocity
        speed = Vector3.new(vel.X, 0, vel.Z).Magnitude
    end

    isSRunning_wind = (speed > 18.5 and SETTINGS.Enabled)

    if isSRunning_wind then
        if not windEmitter then createWindParticles() end
        windEmitter.Rate = 380
        local shakeIntensity = 0.045 + (speed - 20) * 0.0022
        local shakeX = math.sin(os.clock() * 28) * shakeIntensity
        local shakeY = math.sin(os.clock() * 19) * shakeIntensity * 0.7
        Camera.CFrame *= CFrame.new(shakeX, shakeY, 0)
    else
        if windEmitter then
            windEmitter.Rate = 0
        end
    end
end)

if character then
    createWindParticles()
end

local STAND_OFFSET = Vector3.new(3, 2.5, 2.5)
local isTimeStopped = false
local isStandActive = false
local isAttacking = false
local currentStand = nil
local idleTrack = nil
local walkTrack = nil
local frozenParts = {}
local frozenKnives = {} -- Lista de facas congeladas
local mudaComboCount = 0
local comboDisplay = nil
local comboTweens = {}
local standChangerGui = nil    
local lastKillConfirmTime = 0
local KILL_CONFIRM_COOLDOWN = 1

-- ============================================================
local idSalvo = carregarStandId()
local customStandUserId = nil
if idSalvo and idSalvo > 0 then
    customStandUserId = idSalvo
    print("🎮 Stand carregado automaticamente do arquivo!")
else
    print("👤 Nenhum ID salvo. Usando stand padrão.")
end
-- ============================================================

local COLORS = {
    Yellow      = Color3.fromRGB(255, 215, 0),
    Gold        = Color3.fromRGB(255, 235, 100),
    Purple      = Color3.fromRGB(170, 0, 255),
    DeepPurple  = Color3.fromRGB(100, 0, 180),
    Black       = Color3.fromRGB(10, 10, 15),
    DarkGray    = Color3.fromRGB(25, 25, 35),
    BloodRed    = Color3.fromRGB(180, 0, 20),
    White       = Color3.fromRGB(255, 255, 255),
    Green       = Color3.fromRGB(0, 255, 100),  
}

local ASSETS = {
	TS_START_SFX = "rbxassetid://7514417921",
	TS_END_SFX = "rbxassetid://97139043906890",
	ANIM_DIO = "rbxassetid://84289147684815",
	STAND_IDLE = "rbxassetid://133330377145015",
	TS_RESUME_IMAGE = "rbxassetid://106168449328933",
	MUDA_SOUND = "rbxassetid://616593932",
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
	ROAD_ROLLER_RIDE_ANIM = "rbxassetid://140327538515031",
	STAND_WALK = "rbxassetid://123349905320515",
	KNIFE_THROW_DIO_SFX = "rbxassetid://4415007771", 
KNIFE_THROW_STAND_SFX = "rbxassetid://118093612783120"
}

-- ==================== FINISHER VARIABLES ====================
local FINISHER_HEALTH_THRESHOLD = 25
local FINISHER_DURATION = 1.5

local isFinisherActive = false
local finisherConnection = nil
local noclipFinisherConn = nil
local finisherTargetRoot = nil

-- ==================== NaN FLING SYSTEM ====================
local function startFinisher(targetRoot)
	if isFinisherActive or not targetRoot then return end
	
	isFinisherActive = true
	finisherTargetRoot = targetRoot
	
	local myRoot = character:FindFirstChild("HumanoidRootPart")
	if not myRoot then return end
	
	-- CRIA PISO INVISÍVEL PRO NaN FLING
	local floorPart = Instance.new("Part")
	floorPart.Size = Vector3.new(8, 0.2, 8)
	floorPart.Transparency = 1
	floorPart.CanCollide = true
	floorPart.Name = "NaN_Floor"
	floorPart.Parent = workspace
	
	-- NOCLIP NO SEU PERSONAGEM (atravessa tudo)
	noclipFinisherConn = RunService.Stepped:Connect(function()
		if not character or not character.Parent then return end
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
			end
		end
		-- Também tira colisão do alvo
		if finisherTargetRoot and finisherTargetRoot.Parent then
			for _, part in ipairs(finisherTargetRoot.Parent:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = false
				end
			end
		end
	end)
	
	-- NaN FLING (substitui o fling nuclear antigo)
	finisherConnection = RunService.Stepped:Connect(function()
		if not myRoot or not finisherTargetRoot or not finisherTargetRoot.Parent then return end
		
		local Nan = 0/0
		local NanVec = Vector3.new(Nan, Nan, Nan)
		
		-- Posiciona o piso embaixo do alvo
		floorPart.Anchored = false
		floorPart.CFrame = finisherTargetRoot.CFrame * CFrame.new(0, -3.2, 0)
		
		-- Aplica NaN physics (faz o alvo flutuar/voar loucamente)
		sethiddenproperty(myRoot, "PhysicsRepRootPart", finisherTargetRoot)
		sethiddenproperty(hum, "MoveDirectionInternal", NanVec)
		
		myRoot.AssemblyLinearVelocity = NanVec
		myRoot.AssemblyAngularVelocity = NanVec
		if floorPart then
			floorPart.AssemblyLinearVelocity = NanVec
		end
	end)
	
	-- Limpeza após a duração
	task.delay(FINISHER_DURATION, function()
		if isFinisherActive then
			-- Destrói o piso antes de chamar endFinisher
			if floorPart and floorPart.Parent then
				floorPart:Destroy()
			end
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
	
	local myRoot = character:FindFirstChild("HumanoidRootPart")
	if myRoot and hum then
		-- Reseta PhysicsRepRootPart (IMPORTANTE!)
		sethiddenproperty(myRoot, "PhysicsRepRootPart", nil)
		sethiddenproperty(hum, "MoveDirectionInternal", Vector3.zero)
		
		-- Zera velocidades
		myRoot.Velocity = Vector3.zero
		myRoot.RotVelocity = Vector3.zero
		myRoot.AssemblyLinearVelocity = Vector3.zero
		myRoot.AssemblyAngularVelocity = Vector3.zero
		
		-- Ancora rapidamente pra estabilizar
		myRoot.Anchored = true
		task.wait(0.08)
		myRoot.Anchored = false
		
		-- Zera de novo após desancorar
		myRoot.Velocity = Vector3.zero
		myRoot.RotVelocity = Vector3.zero
		myRoot.AssemblyLinearVelocity = Vector3.zero
		myRoot.AssemblyAngularVelocity = Vector3.zero
	end
	
	-- Restaura colisão do seu personagem
	if character and character.Parent then
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = true
			end
		end
	end
	
	-- Restaura colisão do alvo
	if finisherTargetRoot and finisherTargetRoot.Parent then
		for _, part in ipairs(finisherTargetRoot.Parent:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = true
			end
		end
	end
	
	finisherTargetRoot = nil
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
	comboDisplay.Position = UDim2.new(0.6, -30, 0.68, 0)
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

local COOLDOWNS = {M1 = 3.5, Knife = 1, TimeStop = 10, RoadRoller = 15}
local lastUsed = {M1 = 0, Knife = 0, TimeStop = 0, RoadRoller = 0}

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

local TS_POS = UDim2.new(0.4, 0, 0.78, 0)
local ROAD_POS = UDim2.new(0.3, 0, 0.79, 0)
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

local tsBtn, tsStroke, tsIcon = createCircularButton("TimeStopBtn", TS_POS, "STOP", nil, ASSETS.TS_IMAGE, 80)
local roadBtn, roadStroke = createCircularButton("RoadRollerBtn", ROAD_POS, "ROAD", Color3.fromRGB(170, 0, 255), nil, 70)
local activateBtn, actStroke, standIcon = createCircularButton("ActivateBtn", ACTIVATE_POS, "STAND", nil, ASSETS.STAND_IMAGE, 95)
local m1Btn, m1Stroke = createCircularButton("M1Btn", M1_POS, "M1", nil, nil, 80)
local knifeBtn, knifeStroke, knifeIcon = createCircularButton("KnifeBtn", KNIFE_POS_OFF, "KNIFE", nil, ASSETS.KNIFE_IMAGE, 80)

m1Btn.Visible = false
m1Btn.Position = ACTIVATE_POS
m1Btn.Size = UDim2.fromOffset(0, 0)
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

-- ==================== NOVA FUNÇÃO GET STAND MODEL (IGNORA APENAS ACESSÓRIOS DO SCRIPT) ====================
local ACCESSORY_TAG = "DioAccessory"  -- Mesma tag do script de acessórios

local function getStandModel()
    local targetUserId = customStandUserId or player.UserId

    local success, model = pcall(function()
        local description = Players:GetHumanoidDescriptionFromUserId(targetUserId)
        local standModel = Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
        return standModel
    end)

    if not success or not model then
        warn("❌ Falha ao criar Stand R15 para UserId: " .. targetUserId .. " | Usando fallback...")
        customStandUserId = nil
        return getStandModel()
    end

    model.Name = "Stand"
    model.Archivable = true

    -- 🚫 REMOVE APENAS OS ACESSÓRIOS COM A TAG "DioAccessory"
    -- (Remove do MODELO antes de remover scripts)
    for _, child in ipairs(model:GetChildren()) do
        if child:GetAttribute(ACCESSORY_TAG) then
            child:Destroy()
        end
    end
    
    -- 🚫 Remove também acessórios que estão DENTRO de partes do corpo
    for _, obj in ipairs(model:GetDescendants()) do
        if obj:GetAttribute(ACCESSORY_TAG) then
            obj:Destroy()
        end
    end

    -- Agora remove scripts, colisão e sombras do RESTO do modelo
    for _, obj in ipairs(model:GetDescendants()) do
        if obj:IsA("BasePart") then
            obj.CanCollide = false
            obj.CastShadow = false
            if obj.Name ~= "HumanoidRootPart" then
                obj.Transparency = 1
            else
                obj.Transparency = 1
            end
        elseif obj:IsA("Decal") then
            obj.Transparency = 1
        elseif obj:IsA("LocalScript") or obj:IsA("Script") or obj:IsA("ModuleScript") then
            obj:Destroy()
        end
    end

    -- Configurações do Humanoid
    local sHum = model:FindFirstChildOfClass("Humanoid")
    if sHum then
        sHum.RigType = Enum.HumanoidRigType.R15
        sHum.PlatformStand = true
        sHum.AutoRotate = false
        sHum.HipHeight = 0
    end

    if model:FindFirstChild("Torso") then
        warn("⚠️ Stand gerou como R6! Recriando...")
        model:Destroy()
        return getStandModel()
    end

    return model
end

-- ============================================================
-- 🔴 SUBSTITUA TODA A FUNÇÃO createStandChangerGui POR ISSO:
-- ============================================================
local function createStandChangerGui()
    if standChangerGui and standChangerGui.Parent then
        standChangerGui:Destroy()
        standChangerGui = nil
        return
    end
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "StandChangerGUI"
    gui.ResetOnSpawn = false
    gui.Parent = player.PlayerGui
    
    -- Container principal
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.fromOffset(400, 320)  -- Aumentado para caber o botão SALVAR
    mainFrame.Position = UDim2.fromScale(0.5, 0.45)
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = gui
    
    -- Borda dourada
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 215, 0)
    stroke.Thickness = 4
    stroke.Parent = mainFrame
    
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 16)
    
    -- Título
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 50)
    title.BackgroundTransparency = 1
    title.Text = "🌟 STAND CHANGER 🌟"
    title.TextColor3 = Color3.fromRGB(255, 215, 0)
    title.Font = Enum.Font.Bangers
    title.TextSize = 28
    title.TextStrokeTransparency = 0
    title.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    title.Parent = mainFrame
    
    -- 🔴 NOVO: Status do ID salvo
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(0.85, 0, 0, 25)
    statusLabel.Position = UDim2.new(0.075, 0, 0.2, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = customStandUserId and "⚡ Stand Customizado Ativo" or "👤 Stand Padrão"
    statusLabel.TextColor3 = customStandUserId and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(150, 150, 150)
    statusLabel.Font = Enum.Font.SourceSansBold
    statusLabel.TextSize = 16
    statusLabel.Parent = mainFrame
    
    -- Caixa de ID
    local idBox = Instance.new("TextBox")
    idBox.Size = UDim2.new(0.85, 0, 0, 45)
    idBox.Position = UDim2.new(0.075, 0, 0.33, 0)
    idBox.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    idBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    idBox.PlaceholderText = "Cole o User ID aqui..."
    idBox.PlaceholderColor3 = Color3.fromRGB(140, 140, 160)
    idBox.Text = customStandUserId and tostring(customStandUserId) or ""
    idBox.Font = Enum.Font.SourceSans
    idBox.TextSize = 18
    idBox.Parent = mainFrame
    Instance.new("UICorner", idBox).CornerRadius = UDim.new(0, 10)
    
    local idStroke = Instance.new("UIStroke")
    idStroke.Color = Color3.fromRGB(255, 215, 0)
    idStroke.Thickness = 2
    idStroke.Parent = idBox
    
    -- Botão ADD
    local addBtn = Instance.new("TextButton")
    addBtn.Size = UDim2.new(0.4, 0, 0, 50)
    addBtn.Position = UDim2.new(0.075, 0, 0.6, 0)
    addBtn.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
    addBtn.Text = "ADD STAND"
    addBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    addBtn.Font = Enum.Font.Bangers
    addBtn.TextSize = 22
    addBtn.Parent = mainFrame
    Instance.new("UICorner", addBtn).CornerRadius = UDim.new(0, 10)
    
    -- Botão RESET
    local resetBtn = Instance.new("TextButton")
    resetBtn.Size = UDim2.new(0.4, 0, 0, 50)
    resetBtn.Position = UDim2.new(0.525, 0, 0.6, 0)
    resetBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    resetBtn.Text = "RESET"
    resetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    resetBtn.Font = Enum.Font.Bangers
    resetBtn.TextSize = 22
    resetBtn.Parent = mainFrame
    Instance.new("UICorner", resetBtn).CornerRadius = UDim.new(0, 10)
    
    -- 🔴 NOVO: Botão SALVAR
    local saveBtn = Instance.new("TextButton")
    saveBtn.Size = UDim2.new(0.85, 0, 0, 35)
    saveBtn.Position = UDim2.new(0.075, 0, 0.78, 0)
    saveBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 80)
    saveBtn.Text = "💾 SALVAR ID ATUAL"
    saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    saveBtn.Font = Enum.Font.Bangers
    saveBtn.TextSize = 18
    saveBtn.Parent = mainFrame
    Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 10)
    
    -- Hover effects
    addBtn.MouseEnter:Connect(function()
        TweenService:Create(addBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 230, 80)}):Play()
    end)
    addBtn.MouseLeave:Connect(function()
        TweenService:Create(addBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 180, 0)}):Play()
    end)
    
    resetBtn.MouseEnter:Connect(function()
        TweenService:Create(resetBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 60, 60)}):Play()
    end)
    resetBtn.MouseLeave:Connect(function()
        TweenService:Create(resetBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(200, 40, 40)}):Play()
    end)
    
    saveBtn.MouseEnter:Connect(function()
        TweenService:Create(saveBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 220, 110)}):Play()
    end)
    saveBtn.MouseLeave:Connect(function()
        TweenService:Create(saveBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 180, 80)}):Play()
    end)
    
    addBtn.MouseButton1Click:Connect(function()
    local input = idBox.Text:match("%d+")
    local inputId = tonumber(input)
    
    if inputId and inputId > 0 then
        customStandUserId = inputId
        print("✅ Stand alterado para UserId: " .. inputId)
        
        statusLabel.Text = "⚡ Stand Customizado Ativo"
        statusLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
        
        -- Salva o ID
        salvarStandId(inputId)
        
        if isStandActive then
            toggleStand()
            task.wait(0.25)
            toggleStand()
        end
        
        gui:Destroy()
        standChangerGui = nil
    else
        idBox.Text = ""
        idBox.PlaceholderText = "ID inválido! Use apenas números."
    end
end)
    
    -- Dentro da função createStandChangerGui(), substitua o botão RESET por isso:
resetBtn.MouseButton1Click:Connect(function()
    customStandUserId = nil
    print("✅ Stand resetado para o padrão!")
    
    statusLabel.Text = "👤 Stand Padrão"
    statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    
    -- Deleta o arquivo físico
    deletarArquivoConfig()
    
    if isStandActive then
        toggleStand()
        task.wait(0.3)
        toggleStand()
    end
    
    gui:Destroy()
    standChangerGui = nil
end)
    
    -- 🔴 NOVO: Função do botão SALVAR
    saveBtn.MouseButton1Click:Connect(function()
        if customStandUserId then
            salvarStandId(customStandUserId)
            saveBtn.Text = "✅ SALVO!"
            saveBtn.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
            task.delay(1.5, function()
                if saveBtn and saveBtn.Parent then
                    saveBtn.Text = "💾 SALVAR ID ATUAL"
                    saveBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 80)
                end
            end)
        else
            salvarStandId(player.UserId)
            saveBtn.Text = "✅ PADRÃO SALVO!"
            saveBtn.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
            task.delay(1.5, function()
                if saveBtn and saveBtn.Parent then
                    saveBtn.Text = "💾 SALVAR ID ATUAL"
                    saveBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 80)
                end
            end)
        end
    end)
    
    -- ==================== FECHAR AO CLICAR FORA (CORRIGIDO) ====================
local userInputService = game:GetService("UserInputService")

local function onInputBegan(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    
    if not gui or not gui.Parent then
        userInputService.InputBegan:Disconnect(onInputBegan)
        return
    end
    
    if not mainFrame or not mainFrame.Parent then return end
    
    local mousePos = userInputService:GetMouseLocation()
    local framePos = mainFrame.AbsolutePosition
    local frameSize = mainFrame.AbsoluteSize
    
    local isInsideX = mousePos.X >= framePos.X and mousePos.X <= framePos.X + frameSize.X
    local isInsideY = mousePos.Y >= framePos.Y and mousePos.Y <= framePos.Y + frameSize.Y
    
    if not (isInsideX and isInsideY) then
        userInputService.InputBegan:Disconnect(onInputBegan)
        gui:Destroy()
        standChangerGui = nil
    end
end

-- Aguarda um frame para não detectar o clique que abriu a GUI
task.delay(0.2, function()
    if gui and gui.Parent then
        userInputService.InputBegan:Connect(onInputBegan)
    end
end)
    
    standChangerGui = gui
end

local function toggleStand()
	if isStandActive then
		-- === DESATIVAR STAND ===
		isStandActive = false
		isAttacking = false
		activateBtn.Text = "STAND"

		if idleTrack then idleTrack:Stop(0.1) end
		if walkTrack then walkTrack:Stop(0.1) end

		if currentStand then
			local root = currentStand:FindFirstChild("HumanoidRootPart")
			if root then
				root.Anchored = false
				TweenService:Create(root, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {CFrame = character.HumanoidRootPart.CFrame}):Play()
			end
			for _, p in ipairs(currentStand:GetDescendants()) do
				if p:IsA("BasePart") then
					TweenService:Create(p, TweenInfo.new(0.4), {Transparency = 1}):Play()
				end
			end
			Debris:AddItem(currentStand, 0.6)
			currentStand = nil
		end

		-- Animação do botão M1 saindo
		TweenService:Create(m1Btn, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = ACTIVATE_POS,
			Size = UDim2.fromOffset(0, 0)
		}):Play()
		task.delay(0.3, function() m1Btn.Visible = false end)

		updateKnifePosition(false)
		updateIconState(standIcon, false)

	else
		-- === ATIVAR STAND (otimizado) ===
		isStandActive = true
		activateBtn.Text = "OFF"

		-- Som e speech bubble primeiro (não bloqueia nada)
		showSpeechBubble(81663476180868, "right", 2.5)
		local standActivateSound = Instance.new("Sound", workspace)
		standActivateSound.SoundId = "rbxassetid://15081418558"
		standActivateSound.Volume = 2
		standActivateSound:Play()
		Debris:AddItem(standActivateSound, 5)

		-- Animação dos botões (M1 e Knife) em paralelo
		m1Btn.Visible = true
		TweenService:Create(m1Btn, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = M1_POS,
			Size = UDim2.fromOffset(80, 80)
		}):Play()

		updateKnifePosition(true)
		updateIconState(standIcon, true)

		-- Cria o Stand com task.spawn para NÃO travar o clique
		task.spawn(function()
			currentStand = getStandModel()
			if not currentStand then return end

			currentStand.Parent = workspace

			local sHum = currentStand:FindFirstChildOfClass("Humanoid")
			local sRoot = currentStand:FindFirstChild("HumanoidRootPart")

			if sHum then
				sHum.PlatformStand = true
				sHum.AutoRotate = false
				sHum.HipHeight = 0
			end
			if sRoot then
				sRoot.Anchored = true
				sRoot.CFrame = character.HumanoidRootPart.CFrame * CFrame.new(STAND_OFFSET)
			end

			-- === REVELA O STAND MANTENDO AS CORES ORIGINAIS ===
			for _, p in ipairs(currentStand:GetDescendants()) do
				if p:IsA("BasePart") then
					-- NÃO força branco! Mantém a cor original do avatar
					if p.Name == "HumanoidRootPart" then
						p.Transparency = 1
						p.CastShadow = false
					else
						p.Transparency = 1  -- Começa invisível
						-- Tween suave para aparecer mantendo cor original
						TweenService:Create(p, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
							Transparency = 0
						}):Play()
					end
				elseif p:IsA("Decal") then
					p.Transparency = 1
					TweenService:Create(p, TweenInfo.new(0.45), {Transparency = 0}):Play()
				end
			end

			-- Idle animation
			if sHum then
				idleTrack = playAnim(sHum, ASSETS.STAND_IDLE, 1, true, Enum.AnimationPriority.Idle)
			end
		end)
	end
end

-- ==================== VFX SYSTEM ====================
local function createParticle(parent, props)
	local emitter = Instance.new("ParticleEmitter")
	for property, value in pairs(props) do
		emitter[property] = value
	end
	emitter.Parent = parent
	return emitter
end

local function EmitTimeStopVFX()
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	if not torso then return end

	local vfxAttachment = Instance.new("Attachment")
	vfxAttachment.Parent = torso
	vfxAttachment.Position = Vector3.new(0, 0, 0)

	-- Emissor 1
	local emitter1 = createParticle(vfxAttachment, {
		Texture = "rbxassetid://17391818367",
		Color = ColorSequence.new(Color3.fromRGB(255, 215, 0)),
		Lifetime = NumberRange.new(0.1, 0.3),
		Rate = 0,
		Rotation = NumberRange.new(0),
		RotSpeed = NumberRange.new(0),
		EmissionDirection = Enum.NormalId.Top,
		Speed = NumberRange.new(8),
		Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 6),
			NumberSequenceKeypoint.new(0.2, 6.5),
			NumberSequenceKeypoint.new(0.75, 2.5),
			NumberSequenceKeypoint.new(1, 0)
		}),
		LightEmission = 1,
		Orientation = Enum.ParticleOrientation.FacingCamera,
		SpreadAngle = Vector2.new(360, 360),
		Shape = Enum.ParticleEmitterShape.Box,
		ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward,
		Brightness = 5,
		ZOffset = 0.05,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.95, 0),
			NumberSequenceKeypoint.new(1, 1)
		}),
		VelocityInheritance = 0,
		LockedToPart = false,
		Enabled = false
	})
	emitter1:Emit(10)

	-- Emissor 2
	local emitter2 = createParticle(vfxAttachment, {
		Texture = "rbxassetid://16511964424",
		Color = ColorSequence.new(Color3.fromRGB(255, 215, 0)),
		Lifetime = NumberRange.new(0.1, 0.3),
		Rate = 0,
		Rotation = NumberRange.new(0),
		RotSpeed = NumberRange.new(0),
		EmissionDirection = Enum.NormalId.Top,
		Speed = NumberRange.new(8),
		Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 6),
			NumberSequenceKeypoint.new(0.2, 6.5),
			NumberSequenceKeypoint.new(0.75, 2.5),
			NumberSequenceKeypoint.new(1, 0)
		}),
		LightEmission = 1,
		Orientation = Enum.ParticleOrientation.FacingCamera,
		SpreadAngle = Vector2.new(360, 360),
		Shape = Enum.ParticleEmitterShape.Box,
		ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward,
		Brightness = 5,
		ZOffset = 0.05,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.95, 0),
			NumberSequenceKeypoint.new(1, 1)
		}),
		VelocityInheritance = 0,
		LockedToPart = false,
		Enabled = false
	})
	emitter2:Emit(10)

	task.wait(0.25)

	-- Emissor 3 (explosÃ£o dourada)
	local emitter3 = createParticle(vfxAttachment, {
		Texture = "rbxassetid://13161986324",
		Color = ColorSequence.new(Color3.fromRGB(255, 215, 0)),
		Lifetime = NumberRange.new(0.5, 1.5),
		Rate = 0,
		Speed = NumberRange.new(30, 50),
		Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 5),
			NumberSequenceKeypoint.new(0.1, 6),
			NumberSequenceKeypoint.new(0.3, 3),
			NumberSequenceKeypoint.new(1, 0)
		}),
		LightEmission = 1,
		SpreadAngle = Vector2.new(360, 360),
		Shape = Enum.ParticleEmitterShape.Box,
		Brightness = 10,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(0.5, 0.5),
			NumberSequenceKeypoint.new(1, 1)
		}),
		VelocityInheritance = 0,
		Enabled = false
	})
	emitter3:Emit(60)

	-- Emissor 4 (raio de luz subindo)
	local emitter4 = createParticle(vfxAttachment, {
		Texture = "rbxassetid://10335418884",
		Color = ColorSequence.new(Color3.fromRGB(255, 200, 0)),
		Lifetime = NumberRange.new(0.8, 2),
		Rate = 0,
		EmissionDirection = Enum.NormalId.Top,
		Speed = NumberRange.new(20, 35),
		Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 4),
			NumberSequenceKeypoint.new(0.08, 5),
			NumberSequenceKeypoint.new(0.1, 3),
			NumberSequenceKeypoint.new(0.75, 2),
			NumberSequenceKeypoint.new(1, 0)
		}),
		LightEmission = 0.9,
		SpreadAngle = Vector2.new(360, 360),
		Shape = Enum.ParticleEmitterShape.Box,
		Brightness = 15,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(0.5, 0.5),
			NumberSequenceKeypoint.new(1, 1)
		}),
		VelocityInheritance = 0,
		Enabled = false
	})
	emitter4:Emit(80)

	-- Emissor 5 (brilho final)
	local emitter5 = createParticle(vfxAttachment, {
		Texture = "rbxassetid://13161986324",
		Color = ColorSequence.new(Color3.fromRGB(255, 220, 50)),
		Lifetime = NumberRange.new(0.3, 1),
		Rate = 0,
		Speed = NumberRange.new(25, 45),
		Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.1, 5),
			NumberSequenceKeypoint.new(0.35, 4),
			NumberSequenceKeypoint.new(0.75, 3),
			NumberSequenceKeypoint.new(1, 0)
		}),
		LightEmission = 0.9,
		SpreadAngle = Vector2.new(360, 360),
		Shape = Enum.ParticleEmitterShape.Box,
		Brightness = 15,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 0)
		}),
		VelocityInheritance = 0,
		Enabled = false
	})
	emitter5:Emit(40)

	task.delay(2, function()
		if vfxAttachment then vfxAttachment:Destroy() end
	end)
end

-- ==================== VFX COMPLETO DE SANGUE NO ALVO (18 EMISSORES - COMPLETO) ====================
local function EmitBloodVFX(character)
	if not character then return end
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	if not torso then return end

	local vfxAttachment = Instance.new("Attachment")
	vfxAttachment.Parent = torso
	vfxAttachment.Position = Vector3.new(0, 0, 0)

	local emitter1 = createParticle(vfxAttachment, {
		Texture = "rbxassetid://72464786650138", Color = ColorSequence.new(Color3.fromRGB(116, 0, 0)),
		Lifetime = NumberRange.new(0.5, 1), Rate = 0, Rotation = NumberRange.new(90), RotSpeed = NumberRange.new(0),
		EmissionDirection = Enum.NormalId.Top, Speed = NumberRange.new(12),
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.819672), NumberSequenceKeypoint.new(1, 0)}),
		LightEmission = 0, Orientation = Enum.ParticleOrientation.VelocityParallel,
		SpreadAngle = Vector2.new(90, 90), Shape = Enum.ParticleEmitterShape.Box,
		ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward, Brightness = 1, ZOffset = 0,
		Squash = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0)}),
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0)}),
		FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4, FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
		VelocityInheritance = 0, LockedToPart = false, Enabled = false
	})
	emitter1:Emit(3)

	local emitter2 = createParticle(vfxAttachment, {
		Texture = "http://www.roblox.com/asset/?id=13975880803", Color = ColorSequence.new(Color3.fromRGB(116, 0, 0)),
		Lifetime = NumberRange.new(0.5, 1), Rate = 0, Rotation = NumberRange.new(90), RotSpeed = NumberRange.new(0),
		EmissionDirection = Enum.NormalId.Top, Speed = NumberRange.new(12),
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.819672), NumberSequenceKeypoint.new(1, 0)}),
		LightEmission = 0, Orientation = Enum.ParticleOrientation.VelocityParallel,
		SpreadAngle = Vector2.new(90, 90), Shape = Enum.ParticleEmitterShape.Box,
		ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward, Brightness = 1, ZOffset = 0,
		Squash = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0)}),
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0)}),
		FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4, FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
		VelocityInheritance = 0, LockedToPart = false, Enabled = false
	})
	emitter2:Emit(3)

	local emitter3 = createParticle(vfxAttachment, {
		Texture = "rbxassetid://11362424823", Color = ColorSequence.new(Color3.fromRGB(116, 0, 0)),
		Lifetime = NumberRange.new(0.5, 1), Rate = 0, Rotation = NumberRange.new(90), RotSpeed = NumberRange.new(0),
		EmissionDirection = Enum.NormalId.Top, Speed = NumberRange.new(12),
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.819672), NumberSequenceKeypoint.new(1, 0)}),
		LightEmission = -1, Orientation = Enum.ParticleOrientation.VelocityParallel,
		SpreadAngle = Vector2.new(90, 90), Shape = Enum.ParticleEmitterShape.Box,
		ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward, Brightness = 1, ZOffset = 0,
		Squash = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0)}),
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0)}),
		FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4, FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
		VelocityInheritance = 0, LockedToPart = false, Enabled = false
	})
	emitter3:Emit(3)

	local emitter4 = createParticle(vfxAttachment, {
		Texture = "rbxassetid://75151371642650", Color = ColorSequence.new(Color3.fromRGB(116, 0, 0)),
		Lifetime = NumberRange.new(1, 2), Rate = 0, Rotation = NumberRange.new(0), RotSpeed = NumberRange.new(0),
		EmissionDirection = Enum.NormalId.Top, Speed = NumberRange.new(3, 5),
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 2.45902), NumberSequenceKeypoint.new(1, 2.73224)}),
		LightEmission = 0, Orientation = Enum.ParticleOrientation.VelocityParallel,
		SpreadAngle = Vector2.new(90, 90), Shape = Enum.ParticleEmitterShape.Box,
		ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward, Brightness = 2, ZOffset = 0,
		Squash = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0)}),
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.192383, 0.448087), NumberSequenceKeypoint.new(1, 1)}),
		FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4, FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
		VelocityInheritance = 0, LockedToPart = false, Enabled = false
	})
	emitter4:Emit(3)

	local emitter5 = createParticle(vfxAttachment, {
		Texture = "rbxassetid://16924746286", Color = ColorSequence.new(Color3.fromRGB(116, 0, 0)),
		Lifetime = NumberRange.new(1, 2), Rate = 0, Rotation = NumberRange.new(-360, 360), RotSpeed = NumberRange.new(0),
		EmissionDirection = Enum.NormalId.Top, Speed = NumberRange.new(1, 3),
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 2.45902), NumberSequenceKeypoint.new(1, 2.73224)}),
		LightEmission = 0, Orientation = Enum.ParticleOrientation.FacingCamera,
		SpreadAngle = Vector2.new(90, 90), Shape = Enum.ParticleEmitterShape.Box,
		ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward, Brightness = 2, ZOffset = 0,
		Squash = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0)}),
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.192383, 0.448087), NumberSequenceKeypoint.new(1, 1)}),
		FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4, FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
		VelocityInheritance = 0, LockedToPart = false, Enabled = false
	})
	emitter5:Emit(3)

	local emitter6 = createParticle(vfxAttachment, {
		Texture = "rbxassetid://132510741799481", Color = ColorSequence.new(Color3.fromRGB(116, 0, 0)),
		Lifetime = NumberRange.new(1, 2), Rate = 0, Rotation = NumberRange.new(-360, 360), RotSpeed = NumberRange.new(0),
		EmissionDirection = Enum.NormalId.Top, Speed = NumberRange.new(3, 6),
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 2.45902), NumberSequenceKeypoint.new(1, 2.73224)}),
		LightEmission = -1, Orientation = Enum.ParticleOrientation.FacingCamera,
		SpreadAngle = Vector2.new(90, 90), Shape = Enum.ParticleEmitterShape.Box,
		ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward, Brightness = 2, ZOffset = 0,
		Squash = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0)}),
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.192383, 0.448087), NumberSequenceKeypoint.new(1, 1)}),
		FlipbookLayout = Enum.ParticleFlipbookLayout.None, FlipbookMode = Enum.ParticleFlipbookMode.Loop,
		VelocityInheritance = 0, LockedToPart = false, Enabled = false
	})
	emitter6:Emit(3)

	local emitter7 = createParticle(vfxAttachment, {
		Texture = "rbxassetid://18707464177", Color = ColorSequence.new(Color3.fromRGB(85, 0, 0)),
		Lifetime = NumberRange.new(0.5), Rate = 0, Rotation = NumberRange.new(-360, 360), RotSpeed = NumberRange.new(0),
		EmissionDirection = Enum.NormalId.Top, Speed = NumberRange.new(0.01),
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 2.89617), NumberSequenceKeypoint.new(1, 4.37158)}),
		LightEmission = 0, Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		SpreadAngle = Vector2.new(1000, -1000), Shape = Enum.ParticleEmitterShape.Box,
		ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward, Brightness = 2, ZOffset = 0,
		Squash = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0)}),
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0)}),
		FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4, FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
		VelocityInheritance = 0, LockedToPart = false, Enabled = false
	})
	emitter7:Emit(3)

	local emitter8 = createParticle(vfxAttachment, {
		Texture = "rbxassetid://15694384576", Color = ColorSequence.new(Color3.fromRGB(255, 255, 255)),
		Lifetime = NumberRange.new(0.25), Rate = 0, Rotation = NumberRange.new(-360, 360), RotSpeed = NumberRange.new(0),
		EmissionDirection = Enum.NormalId.Top, Speed = NumberRange.new(0.01),
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 2.51366), NumberSequenceKeypoint.new(1, 6.72131)}),
		LightEmission = -2, Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		SpreadAngle = Vector2.new(1000, -1000), Shape = Enum.ParticleEmitterShape.Box,
		ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward, Brightness = 0, ZOffset = -2,
		Squash = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0)}),
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}),
		FlipbookLayout = Enum.ParticleFlipbookLayout.None, FlipbookMode = Enum.ParticleFlipbookMode.Loop,
		VelocityInheritance = 0, LockedToPart = false, Enabled = false
	})
	emitter8:Emit(3)

	local emitter9 = createParticle(vfxAttachment, {
		Texture = "rbxassetid://16892272385", Color = ColorSequence.new(Color3.fromRGB(255, 255, 255)),
		Lifetime = NumberRange.new(0.25), Rate = 0, Rotation = NumberRange.new(-360, 360), RotSpeed = NumberRange.new(0),
		EmissionDirection = Enum.NormalId.Top, Speed = NumberRange.new(0.01),
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 2.51366), NumberSequenceKeypoint.new(1, 6.72131)}),
		LightEmission = -2, Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		SpreadAngle = Vector2.new(1000, -1000), Shape = Enum.ParticleEmitterShape.Box,
		ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward, Brightness = 0, ZOffset = -2,
		Squash = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0)}),
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}),
		FlipbookLayout = Enum.ParticleFlipbookLayout.None, FlipbookMode = Enum.ParticleFlipbookMode.Loop,
		VelocityInheritance = 0, LockedToPart = false, Enabled = false
	})
	emitter9:Emit(3)

	local emitter10 = createParticle(vfxAttachment, {
		Texture = "rbxassetid://15694384576", Color = ColorSequence.new(Color3.fromRGB(255, 255, 255)),
		Lifetime = NumberRange.new(0.25), Rate = 0, Rotation = NumberRange.new(-360, 360), RotSpeed = NumberRange.new(0),
		EmissionDirection = Enum.NormalId.Top, Speed = NumberRange.new(0.01),
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 2.51366), NumberSequenceKeypoint.new(1, 6.72131)}),
		LightEmission = 1, Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		SpreadAngle = Vector2.new(1000, -1000), Shape = Enum.ParticleEmitterShape.Box,
		ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward, Brightness = 1, ZOffset = -2,
		Squash = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0)}),
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}),
		FlipbookLayout = Enum.ParticleFlipbookLayout.None, FlipbookMode = Enum.ParticleFlipbookMode.Loop,
		VelocityInheritance = 0, LockedToPart = false, Enabled = false
	})
	emitter10:Emit(3)

	local emitter11 = createParticle(vfxAttachment, {
		Texture = "rbxassetid://16892272385", Color = ColorSequence.new(Color3.fromRGB(255, 255, 255)),
		Lifetime = NumberRange.new(0.25), Rate = 0, Rotation = NumberRange.new(-360, 360), RotSpeed = NumberRange.new(0),
		EmissionDirection = Enum.NormalId.Top, Speed = NumberRange.new(0.01),
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 2.51366), NumberSequenceKeypoint.new(1, 6.72131)}),
		LightEmission = 1, Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		SpreadAngle = Vector2.new(1000, -1000), Shape = Enum.ParticleEmitterShape.Box,
		ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward, Brightness = 1, ZOffset = -2,
		Squash = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0)}),
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}),
		FlipbookLayout = Enum.ParticleFlipbookLayout.None, FlipbookMode = Enum.ParticleFlipbookMode.Loop,
		VelocityInheritance = 0, LockedToPart = false, Enabled = false
	})
	emitter11:Emit(3)

	local emitter12 = createParticle(vfxAttachment, {
		Texture = "rbxassetid://14850595833", Color = ColorSequence.new(Color3.fromRGB(255, 255, 255)),
		Lifetime = NumberRange.new(0.25, 2), Rate = 0, Rotation = NumberRange.new(-360, 360), RotSpeed = NumberRange.new(25),
		EmissionDirection = Enum.NormalId.Top, Speed = NumberRange.new(0.01),
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 4.42623), NumberSequenceKeypoint.new(1, 5.68306)}),
		LightEmission = 0, Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		SpreadAngle = Vector2.new(1000, -1000), Shape = Enum.ParticleEmitterShape.Box,
		ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward, Brightness = 1, ZOffset = 0,
		Squash = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0)}),
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.304005, 0.661202), NumberSequenceKeypoint.new(1, 1)}),
		FlipbookLayout = Enum.ParticleFlipbookLayout.None, FlipbookMode = Enum.ParticleFlipbookMode.Loop,
		VelocityInheritance = 0, LockedToPart = false, Enabled = false
	})
	emitter12:Emit(3)

	local emitter13 = createParticle(vfxAttachment, {
		Texture = "rbxassetid://16034294138", Color = ColorSequence.new(Color3.fromRGB(255, 255, 255)),
		Lifetime = NumberRange.new(1, 2), Rate = 0, Rotation = NumberRange.new(-360, 360), RotSpeed = NumberRange.new(25),
		EmissionDirection = Enum.NormalId.Top, Speed = NumberRange.new(0.01),
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 4.42623), NumberSequenceKeypoint.new(1, 5.68306)}),
		LightEmission = 0, Orientation = Enum.ParticleOrientation.VelocityParallel,
		SpreadAngle = Vector2.new(1000, -1000), Shape = Enum.ParticleEmitterShape.Box,
		ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward, Brightness = 1, ZOffset = 0,
		Squash = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0)}),
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.301379, 0.863388), NumberSequenceKeypoint.new(1, 1)}),
		FlipbookLayout = Enum.ParticleFlipbookLayout.None, FlipbookMode = Enum.ParticleFlipbookMode.Loop,
		VelocityInheritance = 0, LockedToPart = false, Enabled = false
	})
	emitter13:Emit(3)

	local emitter14 = createParticle(vfxAttachment, {
		Texture = "rbxassetid://14850595833", Color = ColorSequence.new(Color3.fromRGB(255, 255, 255)),
		Lifetime = NumberRange.new(0.25, 2), Rate = 0, Rotation = NumberRange.new(-360, 360), RotSpeed = NumberRange.new(25),
		EmissionDirection = Enum.NormalId.Top, Speed = NumberRange.new(0.01),
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 4.42623), NumberSequenceKeypoint.new(1, 5.68306)}),
		LightEmission = 0, Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		SpreadAngle = Vector2.new(1000, -1000), Shape = Enum.ParticleEmitterShape.Box,
		ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward, Brightness = 0, ZOffset = 0,
		Squash = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0)}),
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.304005, 0.661202), NumberSequenceKeypoint.new(1, 1)}),
		FlipbookLayout = Enum.ParticleFlipbookLayout.None, FlipbookMode = Enum.ParticleFlipbookMode.Loop,
		VelocityInheritance = 0, LockedToPart = false, Enabled = false
	})
	emitter14:Emit(3)

	local emitter15 = createParticle(vfxAttachment, {
		Texture = "rbxassetid://108577877866926", Color = ColorSequence.new(Color3.fromRGB(255, 255, 255)),
		Lifetime = NumberRange.new(2.25, 3), Rate = 0, Rotation = NumberRange.new(-360, 360), RotSpeed = NumberRange.new(25),
		EmissionDirection = Enum.NormalId.Top, Speed = NumberRange.new(0.01),
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 4.42623), NumberSequenceKeypoint.new(1, 5.68306)}),
		LightEmission = 0, Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		SpreadAngle = Vector2.new(1000, -1000), Shape = Enum.ParticleEmitterShape.Box,
		ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward, Brightness = 0, ZOffset = 0,
		Squash = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0)}),
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.302035, 0.814208), NumberSequenceKeypoint.new(1, 1)}),
		FlipbookLayout = Enum.ParticleFlipbookLayout.None, FlipbookMode = Enum.ParticleFlipbookMode.Loop,
		VelocityInheritance = 0, LockedToPart = false, Enabled = false
	})
	emitter15:Emit(3)

	local emitter16 = createParticle(vfxAttachment, {
		Texture = "rbxassetid://108577877866926", Color = ColorSequence.new(Color3.fromRGB(255, 255, 255)),
		Lifetime = NumberRange.new(2.25, 3), Rate = 0, Rotation = NumberRange.new(-360, 360), RotSpeed = NumberRange.new(25),
		EmissionDirection = Enum.NormalId.Top, Speed = NumberRange.new(0.01),
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 4.42623), NumberSequenceKeypoint.new(1, 5.68306)}),
		LightEmission = 0, Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		SpreadAngle = Vector2.new(1000, -1000), Shape = Enum.ParticleEmitterShape.Box,
		ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward, Brightness = 1, ZOffset = 0,
		Squash = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0)}),
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.302035, 0.814208), NumberSequenceKeypoint.new(1, 1)}),
		FlipbookLayout = Enum.ParticleFlipbookLayout.None, FlipbookMode = Enum.ParticleFlipbookMode.Loop,
		VelocityInheritance = 0, LockedToPart = false, Enabled = false
	})
	emitter16:Emit(3)

	local emitter17 = createParticle(vfxAttachment, {
		Texture = "rbxassetid://14550142746", Color = ColorSequence.new(Color3.fromRGB(116, 0, 0)),
		Lifetime = NumberRange.new(0.5, 1), Rate = 0, Rotation = NumberRange.new(-360, 360), RotSpeed = NumberRange.new(0),
		EmissionDirection = Enum.NormalId.Top, Speed = NumberRange.new(3, 6),
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 2.45902), NumberSequenceKeypoint.new(1, 2.73224)}),
		LightEmission = -2, Orientation = Enum.ParticleOrientation.FacingCamera,
		SpreadAngle = Vector2.new(90, 90), Shape = Enum.ParticleEmitterShape.Box,
		ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward, Brightness = 3, ZOffset = 0,
		Squash = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0)}),
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.192383, 0.448087), NumberSequenceKeypoint.new(1, 1)}),
		FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4, FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
		VelocityInheritance = 0, LockedToPart = false, Enabled = false
	})
	emitter17:Emit(3)

	local emitter18 = createParticle(vfxAttachment, {
		Texture = "rbxassetid://135489336329641", Color = ColorSequence.new(Color3.fromRGB(116, 0, 0)),
		Lifetime = NumberRange.new(1, 2), Rate = 0, Rotation = NumberRange.new(-360, 360), RotSpeed = NumberRange.new(0),
		EmissionDirection = Enum.NormalId.Top, Speed = NumberRange.new(1, 3),
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 2.45902), NumberSequenceKeypoint.new(1, 2.73224)}),
		LightEmission = 0, Orientation = Enum.ParticleOrientation.FacingCamera,
		SpreadAngle = Vector2.new(90, 90), Shape = Enum.ParticleEmitterShape.Box,
		ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward, Brightness = 2, ZOffset = 0,
		Squash = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0)}),
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.192383, 0.448087), NumberSequenceKeypoint.new(1, 1)}),
		FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4, FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
		VelocityInheritance = 0, LockedToPart = false, Enabled = false
	})
	emitter18:Emit(3)

	task.delay(2, function()
		if vfxAttachment then vfxAttachment:Destroy() end
	end)
end

-- ==================== PROCESSAMENTO DE MOVIMENTO DA FACA (ANTI-DUPLICADO FORTE) ====================
local function processKnifeMovement(knife, shootDir)
    if not knife or not knife.Parent then return end
    
    local lastPosition = knife.Position
    local movementConnection
    movementConnection = RunService.RenderStepped:Connect(function()
        if not knife or not knife.Parent then
            if movementConnection then movementConnection:Disconnect() end
            return
        end
        
        if knife.Anchored then
            lastPosition = knife.Position
            return
        end
        
        local currentPosition = knife.Position
        local direction = (currentPosition - lastPosition)
        local distance = direction.Magnitude
        
        if distance > 0.05 then
            local raycastParams = RaycastParams.new()
            raycastParams.FilterDescendantsInstances = {character, currentStand or {}}
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            
            local steps = math.ceil(distance / 0.5)
            local stepDirection = direction.Unit * (distance / steps)
            
            for step = 1, steps do
                local rayOrigin = lastPosition + (stepDirection * (step - 1))
                local rayResult = workspace:Raycast(rayOrigin, stepDirection, raycastParams)
                
                if rayResult then
                    local hitPart = rayResult.Instance
                    local hitHum = hitPart.Parent:FindFirstChildOfClass("Humanoid")
                    
                    if hitHum and hitHum.Parent ~= character and hitHum.Parent ~= currentStand then
                        hitHum:TakeDamage(18)
                        
                        -- Som normal de acerto
                        local hitSound = Instance.new("Sound", workspace)
                        hitSound.SoundId = ASSETS.KNIFE_HIT_SOUND
                        hitSound.Volume = 1.0
                        hitSound:Play()
                        Debris:AddItem(hitSound, 2)

                        -- Faca cravada
                        local stuckKnife = Instance.new("Part", workspace)
                        stuckKnife.Name = "StuckKnife"
                        stuckKnife.Size = Vector3.new(1, 1, 1)
                        stuckKnife.CanCollide = false
                        stuckKnife.Anchored = true
                        stuckKnife.CFrame = CFrame.lookAt(rayResult.Position, rayResult.Position + direction.Unit) * CFrame.Angles(math.rad(12), math.rad(-175), 0)
                        stuckKnife.Transparency = 0
                        stuckKnife.Color = Color3.fromRGB(255, 255, 255)
                        
                        local stuckMesh = Instance.new("SpecialMesh", stuckKnife)
                        stuckMesh.MeshId = "rbxassetid://15945983658"
                        stuckMesh.TextureId = "rbxassetid://15946012483"
                        stuckMesh.Scale = Vector3.new(1.25, 1.25, 1.85)
                        
                        local stickWeld = Instance.new("WeldConstraint", stuckKnife)
                        stickWeld.Part0 = stuckKnife
                        stickWeld.Part1 = hitPart
                        
                        Debris:AddItem(stuckKnife, 3.5)
                        
                        -- ====================== KILL CONFIRM ANTI-DUPLICADO ======================
                        local now = tick()
                        if hitHum.Health <= 0 and (now - lastKillConfirmTime) > KILL_CONFIRM_COOLDOWN then
                            lastKillConfirmTime = now
                            
                            showSpeechBubble("92536008979873", "right", 3, character.Head)
                            
                            local dioKillSound = Instance.new("Sound", workspace)
                            dioKillSound.SoundId = "rbxassetid://110578259527952"
                            dioKillSound.Volume = 1.6
                            dioKillSound:Play()
                            Debris:AddItem(dioKillSound, 4)
                            
                            cameraShake(0.6, 2.5)
                        end
                        -- =========================================================================
                        
                        EmitBloodVFX(hitPart.Parent)
                        
                        if movementConnection then movementConnection:Disconnect() end
                        knife:Destroy()
                        return
                    end
                end
            end
        end
        
        lastPosition = currentPosition
    end)
end

-- ==================== SISTEMA DE COOLDOWN VISUAL JOJO ====================
local cooldownBars = {}

local function createCooldownBar(button, abilityName, duration)
	-- Container principal da barra
	local barContainer = Instance.new("Frame")
	barContainer.Name = abilityName .. "_Cooldown"
	barContainer.Size = UDim2.new(1.1, 0, 0, 10)
	barContainer.Position = UDim2.new(-0.05, 0, -0.15, 0)
	barContainer.AnchorPoint = Vector2.new(0, 1)
	barContainer.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	barContainer.BackgroundTransparency = 1
	barContainer.ZIndex = 10
	barContainer.Parent = button
	
	-- Borda dourada fina
	local border = Instance.new("UIStroke")
	border.Color = Color3.fromRGB(255, 215, 0)
	border.Thickness = 1.5
	border.Transparency = 0.3
	border.Parent = barContainer
	
	-- Fundo escuro da barra
	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(1, 0, 1, 0)
	background.Position = UDim2.new(0, 0, 0, 0)
	background.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	background.BorderSizePixel = 0
	background.ZIndex = 10
	background.Parent = barContainer
	Instance.new("UICorner", background).CornerRadius = UDim.new(0, 3)
	
	-- Barra de preenchimento (dourada)
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.Position = UDim2.new(0, 0, 0, 0)
	fill.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
	fill.BorderSizePixel = 0
	fill.ZIndex = 11
	fill.Parent = barContainer
	Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 3)
	
	-- Gradiente dourado
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 215, 0)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 180, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 0))
	}
	gradient.Parent = fill
	
	-- Texto de contagem
	local countText = Instance.new("TextLabel")
	countText.Name = "Count"
	countText.Size = UDim2.new(1, 0, 1, 0)
	countText.Position = UDim2.new(0, 0, 0, 0)
	countText.BackgroundTransparency = 1
	countText.Text = string.format("%.1f", duration)
	countText.TextColor3 = Color3.fromRGB(255, 255, 255)
	countText.TextStrokeTransparency = 0
	countText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	countText.Font = Enum.Font.Bangers
	countText.TextSize = 8
	countText.ZIndex = 12
	countText.Parent = barContainer
	
	-- Animações de entrada
	barContainer.Size = UDim2.new(1.1, 0, 0, 0)
	barContainer.BackgroundTransparency = 1
	
	TweenService:Create(barContainer, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(1.1, 0, 0, 10),
		BackgroundTransparency = 0
	}):Play()
	
	-- Brilho pulsante na borda
	spawn(function()
		while barContainer and barContainer.Parent do
			TweenService:Create(border, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Transparency = 0.6
			}):Play()
			task.wait(0.5)
			TweenService:Create(border, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Transparency = 0.2
			}):Play()
			task.wait(0.5)
		end
	end)
	
	return barContainer, fill, countText
end

local function showCooldownOnButton(button, abilityName)
	-- Remove barra antiga se existir
	if cooldownBars[abilityName] and cooldownBars[abilityName].Parent then
		cooldownBars[abilityName]:Destroy()
	end
	
	local duration = COOLDOWNS[abilityName]
	local barContainer, fill, countText = createCooldownBar(button, abilityName, duration)
	cooldownBars[abilityName] = barContainer
	
	local startTime = tick()
	local endTime = startTime + duration
	
	local updateConnection
	updateConnection = RunService.RenderStepped:Connect(function()
		if not barContainer or not barContainer.Parent then
			updateConnection:Disconnect()
			return
		end
		
		local remaining = endTime - tick()
		if remaining <= 0 then
			-- Anima saída
			TweenService:Create(barContainer, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Size = UDim2.new(1.1, 0, 0, 1),
				BackgroundTransparency = 1
			}):Play()
			
			task.delay(0.2, function()
				if barContainer and barContainer.Parent then
					barContainer:Destroy()
				end
			end)
			
			updateConnection:Disconnect()
			return
		end
		
		local progress = remaining / duration
		fill.Size = UDim2.new(progress, 0, 1, 0)
		countText.Text = string.format("%.1f", remaining)
		
		-- Muda cor da barra baseado no tempo restante
		if progress < 0.3 then
			gradient.Color = ColorSequence.new{
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 50, 50)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 100, 50)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 30, 30))
			}
			countText.TextColor3 = Color3.fromRGB(255, 100, 100)
		end
	end)
	
	-- Empilha as barras se já existir alguma
	local existingBars = 0
	for _, child in ipairs(button:GetChildren()) do
		if child:IsA("Frame") and child.Name:find("_Cooldown") and child ~= barContainer then
			existingBars = existingBars + 1
		end
	end
	
	barContainer.Position = UDim2.new(-0.05, 0, -0.15 - (existingBars * 0.12), 0)
end

-- ==================== SISTEMA ANTI-SPAM (BLOQUEIO IMEDIATO) ====================
local isAbilityLocked = {
    M1 = false,
    Knife = false,
    TimeStop = false,
    RoadRoller = false
}

-- Função que bloqueia imediatamente e libera após cooldown
local function lockAbility(abilityName)
    if isAbilityLocked[abilityName] then return false end
    
    -- Bloqueia IMEDIATAMENTE
    isAbilityLocked[abilityName] = true
    
    -- Agenda liberação após o cooldown
    task.delay(COOLDOWNS[abilityName], function()
        isAbilityLocked[abilityName] = false
    end)
    
    return true
end

-- Função de verificação aprimorada
local function canUseStrict(abilityName)
    -- Verifica se a habilidade está bloqueada
    if isAbilityLocked[abilityName] then
        return false
    end
    
    -- Verifica cooldown normal
    local currentTime = tick()
    if currentTime - lastUsed[abilityName] < COOLDOWNS[abilityName] then
        return false
    end
    
    return true
end

-- ==================== VARIÁVEL DE BLOQUEIO DO TIME STOP (adicione no topo com as outras) ====================
local isTimeStopLocked = false  -- Bloqueio durante animação inicial

local function toggleTime()
    -- ========== BLOQUEIO TOTAL DURANTE ANIMAÇÃO INICIAL ==========
    if isTimeStopLocked then
        return  -- Ignora qualquer clique durante a animação
    end
    
    if isTimeStopped then
        -- ========== DESATIVAR TIME STOP ==========
        isTimeStopped = false
        tsBtn.Text = "STOP"
        
lastUsed["TimeStop"] = tick()
lockAbility("TimeStop")
showCooldownOnButton(tsBtn, "TimeStop")

        -- Descongela as facas e restaura movimento
        for knife, data in pairs(frozenKnives) do
            if knife and knife.Parent then
                knife.Anchored = false
                
                if data.velocity then
                    -- Verifica se o LinearVelocity ainda existe
                    if data.velocity.Parent then
                        data.velocity.Enabled = true
                        data.velocity.VectorVelocity = data.direction * 295
                    else
                        -- Recria o LinearVelocity se foi destruído
                        local newAttachment = data.attachment
                        if not newAttachment or not newAttachment.Parent then
                            newAttachment = Instance.new("Attachment", knife)
                        end
                        local newVel = Instance.new("LinearVelocity", knife)
                        newVel.Attachment0 = newAttachment
                        newVel.MaxForce = math.huge
                        newVel.VectorVelocity = data.direction * 295
                        newVel.Parent = knife
                    end
                end
                
                -- INICIA O PROCESSAMENTO DE HIT DA FACA DESCONGELADA
                processKnifeMovement(knife, data.direction)
                
                -- Define tempo de vida após descongelar
                Debris:AddItem(knife, 4)
            end
        end
        frozenKnives = {}
                
        local bloom = Lighting:FindFirstChild("TS_Bloom")
        if bloom then
            TweenService:Create(bloom, TweenInfo.new(0.5), {Intensity = 0}):Play()
            task.delay(0.5, function() if bloom then bloom:Destroy() end end)
        end
                
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
        -- ========== ATIVAR TIME STOP ==========
        if not canUseStrict("TimeStop") then return end
        
        isTimeStopped = true
        tsBtn.Text = "RESUME"
        
        -- ========== BLOQUEIA CANCELAMENTO DURANTE 1.5 SEGUNDOS ==========
        isTimeStopLocked = true
        
        -- Congela todas as facas existentes no mapa
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Part") and obj.Name == "DioKnife" and not obj.Anchored then
                local lv = obj:FindFirstChild("LinearVelocity")
                local att = obj:FindFirstChild("Attachment")
                if lv then
                    lv.Enabled = false
                end
                obj.Anchored = true
                frozenKnives[obj] = {
                    velocity = lv, 
                    direction = obj:GetAttribute("ShootDir") or Vector3.new(0,0,0),
                    attachment = att
                }
            end
        end
        
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
        
        -- ========== APÓS 1.5 SEGUNDOS, LIBERA O CANCELAMENTO ==========
        task.delay(1.5, function()
            if not isTimeStopped then 
                isTimeStopLocked = false
                return 
            end
            
            -- Libera o bloqueio para permitir cancelamento futuro
            isTimeStopLocked = false
            
            EmitTimeStopVFX()
            
            cinematicZoom(1, 40)
            
            task.delay(0.1, function()
                cameraShake(2, 3.0)
            end)
            
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

local function createExplosion(position)
	local explosionPart = Instance.new("Part")
	explosionPart.Transparency = 1
	explosionPart.Anchored = true
	explosionPart.CanCollide = false
	explosionPart.Position = position
	explosionPart.Size = Vector3.new(1,1,1)
	explosionPart.Parent = workspace

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
	mesh.Scale = Vector3.new(1.3, 1.7, 1.3)

	model.PrimaryPart = mainPart
	return model
end

local function createGroundCracks(position)
	for i = 1, 8 do
		local crack = Instance.new("Part")
		crack.Size = Vector3.new(0.15, 0.01, math.random(3, 8))
		crack.Anchored = true
		crack.CanCollide = false
		crack.Color = Color3.fromRGB(25, 25, 25)
		crack.Material = Enum.Material.CrackedLava
		crack.Transparency = 0.2
		
		local angle = math.rad(math.random(0, 360))
		local distance = math.random(1, 6)
		local offset = Vector3.new(math.cos(angle) * distance, 0.01, math.sin(angle) * distance)
		crack.CFrame = CFrame.new(position + offset) * CFrame.Angles(0, math.rad(math.random(0, 360)), 0)
		crack.Parent = workspace
		
		crack.Transparency = 0.8
		TweenService:Create(crack, TweenInfo.new(0.3), {Transparency = 0.2}):Play()
		
		Debris:AddItem(crack, 8)
	end
	
	local centerCrater = Instance.new("Part")
	centerCrater.Size = Vector3.new(4, 0.02, 4)
	centerCrater.Anchored = true
	centerCrater.CanCollide = false
	centerCrater.Color = Color3.fromRGB(30, 30, 30)
	centerCrater.Material = Enum.Material.CrackedLava
	centerCrater.Transparency = 0.4
	centerCrater.CFrame = CFrame.new(position + Vector3.new(0, 0.005, 0))
	centerCrater.Parent = workspace
	
	local decal = Instance.new("Decal", centerCrater)
	decal.Texture = "rbxassetid://154292235"
	decal.Face = Enum.NormalId.Top
	decal.Transparency = 0.3
	
	Debris:AddItem(centerCrater, 8)
end

local function performRoadRoller()
	if not isTimeStopped then
		showSpeechBubble(102362181377695, "right", 2.5)
		return
	end
	if not canUseStrict("RoadRoller") then return end
lockAbility("RoadRoller")  -- Bloqueia imediatamente
	
local activationFlash = Instance.new("Frame")
activationFlash.Name = "RoadRollerActivationFlash"
activationFlash.Size = UDim2.fromScale(2, 2)
activationFlash.Position = UDim2.fromScale(-0.5, -0.5)
activationFlash.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
activationFlash.BackgroundTransparency = 1
activationFlash.ZIndex = 100
activationFlash.Parent = screenGui

TweenService:Create(activationFlash, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
	BackgroundTransparency = 0
}):Play()

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

	local startHeight = 500
	local startPos = targetRoot.Position + Vector3.new(0, startHeight, 0)
	rollerRoot.CFrame = CFrame.new(startPos) * CFrame.Angles(math.rad(85), 0, 90)
	rollerRoot.Anchored = false
	rollerModel.Parent = workspace

	for _, part in ipairs(rollerModel:GetDescendants()) do
		if part:IsA("BasePart") then
			frozenParts[part] = nil
			part.Anchored = false
		end
	end

	local spawnSound = Instance.new("Sound")
	spawnSound.SoundId = ASSETS.ROAD_ROLLER_SPAWN_SFX
	spawnSound.Volume = 2.5
	spawnSound.Parent = rollerRoot
	spawnSound:Play()
	Debris:AddItem(spawnSound, 5)

local charRoot = character:FindFirstChild("HumanoidRootPart")
local rideTrack = nil
local weld = nil

if charRoot then
	charRoot.Anchored = false
	frozenParts[charRoot] = nil
	
	charRoot.CFrame = rollerRoot.CFrame * CFrame.new(0, -2.5, -17)
	
	charRoot.CFrame = CFrame.lookAt(charRoot.Position, targetRoot.Position) * CFrame.Angles(math.rad(90), 0, 0)
	
	if hum and ASSETS.ROAD_ROLLER_RIDE_ANIM ~= "" then
		rideTrack = playAnim(hum, ASSETS.ROAD_ROLLER_RIDE_ANIM, 1.5, true, Enum.AnimationPriority.Action)
		
		weld = Instance.new("WeldConstraint")
		weld.Part0 = charRoot
		weld.Part1 = rollerRoot
		weld.Parent = charRoot
	end
end

	local bodyVel = Instance.new("BodyVelocity")
	bodyVel.Velocity = Vector3.new(0, -450, 0)
	bodyVel.MaxForce = Vector3.new(1, 1, 1) * math.huge
	bodyVel.Parent = rollerRoot
	
	local bodyForce = Instance.new("BodyForce")
	bodyForce.Force = Vector3.new(0, -rollerRoot:GetMass() * 500, 0)
	bodyForce.Parent = rollerRoot
	
	local impactTriggered = false
	local checkConnection
	checkConnection = RunService.RenderStepped:Connect(function()
		if not rollerRoot or not rollerRoot.Parent then
			checkConnection:Disconnect()
			return
		end
		
		local currentY = rollerRoot.Position.Y
		local groundY = targetRoot.Position.Y - 3
		
		if currentY <= groundY + 5 and not impactTriggered then
			impactTriggered = true
			checkConnection:Disconnect()
			
			bodyVel:Destroy()
			bodyForce:Destroy()
			
			rollerRoot.Anchored = true
			rollerRoot.CFrame = CFrame.new(targetRoot.Position + Vector3.new(0, -3, 0)) * CFrame.Angles(math.rad(-80), math.rad(180), 0)
			
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
			
			lastUsed["RoadRoller"] = tick()
showCooldownOnButton(roadBtn, "RoadRoller")

cameraShake(1.5, 5.0)
			
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
			
			local targetHum = targetRoot.Parent:FindFirstChildOfClass("Humanoid")
			if targetHum then
				targetHum:TakeDamage(95)
			end

			createGroundCracks(targetRoot.Position)

			createExplosion(targetRoot.Position)

			if targetRoot and targetRoot.Parent then
				local knockbackDir = (targetRoot.Position - character.HumanoidRootPart.Position).Unit
				targetRoot:ApplyImpulse(Vector3.new(0, 80000, 0) + knockbackDir * 50000)
			end

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
	if not canUseStrict("M1") then return end
lockAbility("M1")  -- Bloqueia imediatamente
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
			
			-- ========== VFX DE SANGUE NO FINISHER ==========
			if i % 3 == 0 then 
				EmitBloodVFX(targetRoot.Parent)
			end
			-- ===============================================
			
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
			
mudaComboCount = mudaComboCount + 1
if mudaComboCount % 5 == 0 then
	showComboCounter()
end
			
			if targetHum.Health <= FINISHER_HEALTH_THRESHOLD and not isFinisherActive then
				startFinisher(targetRoot)
			end
			
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
	
	task.delay(3, function()
		if isFinisherActive then
			endFinisher()
		end
	end)
	
	if barrageTrack then barrageTrack:Stop() end
	if playerBarrageTrack then playerBarrageTrack:Stop() end
	if sHum then idleTrack = playAnim(sHum, ASSETS.STAND_IDLE, 1, true, Enum.AnimationPriority.Idle) end
	
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
		lastUsed["M1"] = tick()
-- Mostra cooldown
showCooldownOnButton(m1Btn, "M1")
		isAttacking = false
	end)
end

-- ==================== FUNÇÃO DE ARREMESSO DE FACA CORRIGIDA ====================
local function performKnifeThrow()
    if not canUseStrict("Knife") then return end
    
    if isAttacking then return end
    
    lockAbility("Knife") 
    
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
    
    -- Direção do tiro
    local shootDir = (isStandAttacking and target) and (target.Position - attackerRoot.Position).Unit or camera.CFrame.LookVector
    
    -- ==================== LOOK AT PARA O PLAYER (QUANDO SEM STAND) ====================
    if not isStandAttacking then
        -- Player olha na direção do tiro (usando câmera)
        local lookTarget = charRoot.Position + Vector3.new(shootDir.X, 0, shootDir.Z).Unit * 10
        local lookCF = CFrame.lookAt(charRoot.Position, lookTarget)
        TweenService:Create(charRoot, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            CFrame = lookCF
        }):Play()
    end
    
    -- ==================== LOOK AT PARA O STAND (QUANDO COM STAND) ====================
    if isStandAttacking then
        local goalCF
        if target then
            local basePos = charRoot.Position + (target.Position - charRoot.Position).Unit * 3.8
            goalCF = CFrame.lookAt(basePos, target.Position)
        else
            goalCF = charRoot.CFrame * CFrame.new(0, 0, -3.8)
        end
        
        local tweenLook = TweenService:Create(attackerRoot, 
            TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), 
            {CFrame = goalCF}
        )
        tweenLook:Play()
        tweenLook.Completed:Wait()
    end
    
    -- Animação de arremesso
    local throwTrack
    if ASSETS.KNIFE_THROW_ANIM ~= "" then 
        if isStandAttacking and idleTrack and idleTrack.IsPlaying then 
            idleTrack:Stop(0.1) 
        end 
        throwTrack = playAnim(attackerHum, ASSETS.KNIFE_THROW_ANIM, 3.2, false, Enum.AnimationPriority.Action)
        if throwTrack then throwTrack.Looped = false end 
    end

    -- Som
    local throwSoundId = isStandAttacking and ASSETS.KNIFE_THROW_STAND_SFX or ASSETS.KNIFE_THROW_DIO_SFX
    local throwSound = Instance.new("Sound", workspace) 
    throwSound.SoundId = throwSoundId
    throwSound.Volume = isStandAttacking and 1.6 or 1.1 
    throwSound:Play() 
    Debris:AddItem(throwSound, 3)
    
    -- Criar facas
    local knifeCount = isStandAttacking and 2 or 1
    for i = 1, knifeCount do
        if isStandAttacking and target and target.Parent and attackerRoot then
            shootDir = (target.Position - attackerRoot.Position).Unit
        end
        
        local knife = Instance.new("Part") 
        knife.Name = "DioKnife" 
        knife.Size = Vector3.new(1, 1, 1) 
        knife.CanCollide = false 
        knife.Parent = workspace

        local baseCFrame = CFrame.lookAt(
            attackerRoot.Position + Vector3.new((i-3)*0.9, 0.6, -1.6), 
            attackerRoot.Position + Vector3.new((i-3)*0.9, 0.6, -1.6) + shootDir
        )
        knife.CFrame = baseCFrame * CFrame.Angles(math.rad(12), math.rad(-175), 0)

        local mesh = Instance.new("SpecialMesh", knife) 
        mesh.MeshId = "rbxassetid://15945983658" 
        mesh.TextureId = "rbxassetid://15946012483" 
        mesh.Scale = Vector3.new(1.25, 1.25, 1.85)

        knife:SetAttribute("ShootDir", shootDir)

        -- Sistema de velocidade
        local velAttachment = Instance.new("Attachment", knife)
        local linearVel = Instance.new("LinearVelocity", knife) 
        linearVel.Attachment0 = velAttachment
        linearVel.MaxForce = math.huge 
        linearVel.VectorVelocity = shootDir * 295

        -- Se estiver em Time Stop, congela a faca
        if isTimeStopped then
            linearVel.Enabled = false
            knife.Anchored = true
            frozenKnives[knife] = {
                velocity = linearVel, 
                direction = shootDir,
                attachment = velAttachment
            }
        else
            -- Se NÃO está em Time Stop, inicia o processamento de hit IMEDIATAMENTE
            processKnifeMovement(knife, shootDir)
            Debris:AddItem(knife, 4.2)
        end
        
        task.wait(0.055)
    end
    
    -- Finalização
    task.wait(0.25)
    if throwTrack then throwTrack:Stop(0.15) end
    
    if isStandAttacking and attackerHum then 
        idleTrack = playAnim(attackerHum, ASSETS.STAND_IDLE, 1, true, Enum.AnimationPriority.Idle) 
    end
    
    lastUsed["Knife"] = tick()
    showCooldownOnButton(knifeBtn, "Knife")
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

-- ==================== SISTEMA DE ANIMAÇÃO DO STAND (CORRIGIDO E ROBUSTO) ====================
local lastStandState = "Idle"  -- "Idle" ou "Walk"

RunService.RenderStepped:Connect(function()
	if not isStandActive or not currentStand or isAttacking then 
		return 
	end
	
	local root = character:FindFirstChild("HumanoidRootPart")
	local sRoot = currentStand:FindFirstChild("HumanoidRootPart")
	local sHum = currentStand:FindFirstChildOfClass("Humanoid")
	
	if not root or not sRoot or not sHum then return end
	
	-- Posicionamento suave do Stand
	local targetPos = root.CFrame * CFrame.new(STAND_OFFSET)
	sRoot.CFrame = sRoot.CFrame:Lerp(targetPos, 0.12)
	
	-- ====================== DETECÇÃO DE MOVIMENTO MELHORADA ======================
	local velocity = root.Velocity
	local horizSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
	
	local shouldWalk = horizSpeed > 3.5   -- Threshold mais confiável
	
	if isAttacking then
		-- Durante ataque, força idle (ou deixa a animação de ataque assumir)
		if walkTrack and walkTrack.IsPlaying then
			walkTrack:Stop(0.2)
		end
		if (not idleTrack or not idleTrack.IsPlaying) and sHum then
			idleTrack = playAnim(sHum, ASSETS.STAND_IDLE, 1, true, Enum.AnimationPriority.Idle)
		end
		lastStandState = "Idle"
		return
	end
	
	-- ====================== CONTROLE DE ANIMAÇÕES ======================
	if shouldWalk then
		if lastStandState ~= "Walk" then
			lastStandState = "Walk"
			
			if idleTrack and idleTrack.IsPlaying then
				idleTrack:Stop(0.15)
			end
			
			if walkTrack then walkTrack:Stop(0) end
			walkTrack = playAnim(sHum, ASSETS.STAND_WALK, 1.5, true, Enum.AnimationPriority.Movement)
		end
	else
		-- Parado
		if lastStandState ~= "Idle" then
			lastStandState = "Idle"
			
			if walkTrack and walkTrack.IsPlaying then
				walkTrack:Stop(0.2)
			end
			
			if idleTrack then idleTrack:Stop(0) end
			idleTrack = playAnim(sHum, ASSETS.STAND_IDLE, 1, true, Enum.AnimationPriority.Idle)
		end
	end
end)

tsBtn.MouseButton1Click:Connect(toggleTime)
activateBtn.MouseButton1Click:Connect(toggleStand)
m1Btn.MouseButton1Click:Connect(performM1)
knifeBtn.MouseButton1Click:Connect(performKnifeThrow)
roadBtn.MouseButton1Click:Connect(performRoadRoller)

-- ==================== COMANDOS DO CHAT ====================
player.Chatted:Connect(function(message)
    local msg = message:lower()
    
    if msg == "-changer" then
        -- Se já estiver aberto, FECHA
        if standChangerGui and standChangerGui.Parent then
            standChangerGui:Destroy()
            standChangerGui = nil
            print("🔒 Stand Changer fechado!")
        else
            -- Se não estiver aberto, ABRE
            createStandChangerGui()
            print("🔓 Stand Changer aberto!")
        end
    end
end)

task.spawn(function()
	local sequence = {COLORS.Yellow, COLORS.Black, COLORS.Green, COLORS.Black, COLORS.Purple, COLORS.Black}
	local i = 1
	while true do
		TweenService:Create(tsStroke, TweenInfo.new(0.7), {Color = sequence[i]}):Play()
		i = i % #sequence + 1 
		task.wait(0.7)
	end
end)

-- ==================== EFEITO VISUAL DE BLOQUEIO NOS BOTÕES ====================
local function applyClickEffect(b, baseSize, abilityName)
    b.MouseButton1Down:Connect(function()
        if abilityName and isAbilityLocked[abilityName] then
            -- Se bloqueado, treme o botão e não diminui
            TweenService:Create(b, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = b.Position + UDim2.new(0.02, 0, 0, 0)
            }):Play()
            task.wait(0.05)
            TweenService:Create(b, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = b.Position - UDim2.new(0.02, 0, 0, 0)
            }):Play()
            return
        end
        
        TweenService:Create(b, TweenInfo.new(0.1), {
            Size = UDim2.fromOffset(baseSize - 8, baseSize - 8)
        }):Play()
    end)
    
    b.MouseButton1Up:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.1), {
            Size = UDim2.fromOffset(baseSize, baseSize)
        }):Play()
    end)
end

applyClickEffect(tsBtn, 80, "TimeStop")
applyClickEffect(roadBtn, 70, "RoadRoller")
applyClickEffect(activateBtn, 95, nil)  -- Activate não tem cooldown
applyClickEffect(m1Btn, 80, "M1")
knifeBtn.MouseButton1Down:Connect(function()
    if isAbilityLocked["Knife"] then
        -- Treme se bloqueado
        TweenService:Create(knifeBtn, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = knifeBtn.Position + UDim2.new(0.02, 0, 0, 0)
        }):Play()
        task.wait(0.05)
        TweenService:Create(knifeBtn, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = knifeBtn.Position - UDim2.new(0.02, 0, 0, 0)
        }):Play()
        return
    end
    
    local currentSize = knifeBtn.Size.X.Offset
    TweenService:Create(knifeBtn, TweenInfo.new(0.1), {
        Size = UDim2.fromOffset(currentSize - 8, currentSize - 8)
    }):Play()
end)

knifeBtn.MouseButton1Up:Connect(function()
    local isActive = isStandActive
    local targetSize = isActive and 70 or 80
    TweenService:Create(knifeBtn, TweenInfo.new(0.1), {
        Size = UDim2.fromOffset(targetSize, targetSize)
    }):Play()
end)

updateKnifePosition(false)

player.CharacterAdded:Connect(function(newChar) 
	character = newChar 
	hum = newChar:WaitForChild("Humanoid") 
end)

-- ═══════════════════════════════════════════
-- 🎒 SISTEMA DE ACESSÓRIOS (AQUI! ⬅️)
-- ═══════════════════════════════════════════
local IDS_CATALOGO = {
    113152323622992, 98776148420540,
}

local function AnexarTudo()
    local character = player.Character or player.CharacterAdded:Wait()
    
    for _, child in ipairs(character:GetChildren()) do
        if child:GetAttribute(ACCESSORY_TAG) then
            child:Destroy()
        end
    end
    
    for _, id in pairs(IDS_CATALOGO) do
        task.spawn(function()
            local sucesso, objects = pcall(function()
                return game:GetObjects("rbxassetid://" .. id)
            end)

            if sucesso and objects and objects[1] then
                local asset = objects[1]:Clone()
                local handle = asset:IsA("BasePart") and asset or asset:FindFirstChild("Handle", true)

                if handle then
                    for _, v in pairs(asset:GetDescendants()) do
                        if v:IsA("LuaSourceContainer") then v:Destroy() end
                    end

                    handle.CanCollide = false
                    handle.Massless = true
                    asset:SetAttribute(ACCESSORY_TAG, true)
                    asset.Parent = character

                    local attachmentItem = handle:FindFirstChildWhichIsA("Attachment")
                    local partAlvo = nil
                    local attachmentCorpo = nil

                    if attachmentItem then
                        for _, parte in pairs(character:GetChildren()) do
                            if parte:IsA("BasePart") then
                                local found = parte:FindFirstChild(attachmentItem.Name)
                                if found then
                                    partAlvo = parte
                                    attachmentCorpo = found
                                    break
                                end
                            end
                        end
                    end

                    if not partAlvo then
                        partAlvo = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
                    end

                    if partAlvo then
                        local weld = Instance.new("Weld")
                        weld.Name = "AutoWeld_" .. id
                        weld.Part0 = partAlvo
                        weld.Part1 = handle
                        
                        if attachmentItem and attachmentCorpo then
                            weld.C0 = attachmentCorpo.CFrame
                            weld.C1 = attachmentItem.CFrame
                        else
                            weld.C0 = CFrame.new(0, 0, 0.6) * CFrame.Angles(0, math.rad(180), 0)
                        end
                        
                        weld.Parent = handle
                    end
                end
                objects[1]:Destroy()
            end
        end)
    end
end

AnexarTudo()

player.CharacterAdded:Connect(function()
    task.wait(2) 
    AnexarTudo()
end)

 -- ==================== NOTIFICAÇÃO DE BOAS-VINDAS (SEM OVERLAY) ====================
if not hasShownNotification then
    hasShownNotification = true
    
    -- Container principal da notificação (fixo no centro, sem overlay)
    local notifFrame = Instance.new("Frame")
    notifFrame.Name = "NotifBox"
    notifFrame.Size = UDim2.fromOffset(400, 220)
    notifFrame.Position = UDim2.fromScale(0.5, 0.5)
    notifFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    notifFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    notifFrame.BorderSizePixel = 0
    notifFrame.ZIndex = 201
    notifFrame.ClipsDescendants = true
    notifFrame.Parent = screenGui  -- ⬅️ Direto no screenGui, sem overlay
    
    -- Gradiente de fundo (efeito de profundidade)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 35)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(15, 15, 20)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 15))
    }
    gradient.Rotation = 45
    gradient.Parent = notifFrame
    
    -- Borda dourada com brilho
    local border = Instance.new("UIStroke")
    border.Color = Color3.fromRGB(255, 215, 0)
    border.Thickness = 3
    border.Parent = notifFrame
    
    -- Brilho pulsante na borda
    local glowStroke = Instance.new("UIStroke")
    glowStroke.Color = Color3.fromRGB(255, 240, 150)
    glowStroke.Thickness = 1
    glowStroke.Transparency = 0.5
    glowStroke.Parent = notifFrame
    
    -- Cabeçalho decorativo
    local headerBar = Instance.new("Frame")
    headerBar.Size = UDim2.new(1, 0, 0, 40)
    headerBar.Position = UDim2.new(0, 0, 0, 0)
    headerBar.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    headerBar.BackgroundTransparency = 0.8
    headerBar.BorderSizePixel = 0
    headerBar.ZIndex = 202
    headerBar.Parent = notifFrame
    
    -- Linha dourada no topo
    local topLine = Instance.new("Frame")
    topLine.Size = UDim2.new(0.8, 0, 0, 2)
    topLine.Position = UDim2.new(0.1, 0, 0, 38)
    topLine.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    topLine.BorderSizePixel = 0
    topLine.ZIndex = 203
    topLine.Parent = notifFrame
    
    -- Ícone/Imagem com efeito de rotação na entrada
    local imageContainer = Instance.new("Frame")
    imageContainer.Size = UDim2.fromOffset(70, 70)
    imageContainer.Position = UDim2.new(0.5, -35, 0, 55)
    imageContainer.BackgroundTransparency = 1
    imageContainer.ZIndex = 202
    imageContainer.Parent = notifFrame
    
    local imageLabel = Instance.new("ImageLabel")
    imageLabel.Size = UDim2.fromScale(1, 1)
    imageLabel.Position = UDim2.fromScale(0, 0)
    imageLabel.BackgroundTransparency = 1
    imageLabel.Image = "rbxassetid://107647236597557"
    imageLabel.ScaleType = Enum.ScaleType.Fit
    imageLabel.ZIndex = 203
    imageLabel.Parent = imageContainer
    
    -- Título com efeito de brilho
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(0.85, 0, 0, 25)
    titleLabel.Position = UDim2.new(0.075, 0, 0, 120)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "⭐ SCRIPT DIO BRANDO ⭐"
    titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    titleLabel.Font = Enum.Font.Bangers
    titleLabel.TextSize = 20
    titleLabel.TextStrokeTransparency = 0
    titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    titleLabel.ZIndex = 202
    titleLabel.Parent = notifFrame
    
    -- Mensagem
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(0.85, 0, 0, 60)
    messageLabel.Position = UDim2.new(0.075, 0, 0, 155)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = "By mynameis909 👑 • Mahoawaga VFX 🌟✨ • eusouoamendobobo ⭐ https://discord.gg/K66SwwY98h • https://discord.gg/tfujC5pTp "
    messageLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    messageLabel.Font = Enum.Font.SourceSans
    messageLabel.TextSize = 16
    messageLabel.TextWrapped = true
    messageLabel.ZIndex = 202
    messageLabel.Parent = notifFrame
    
    -- Partículas decorativas de fundo (efeito premium)
    for i = 1, 8 do
        local particle = Instance.new("Frame")
        particle.Size = UDim2.fromOffset(math.random(4, 8), math.random(4, 8))
        particle.Position = UDim2.fromScale(math.random(), math.random())
        particle.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
        particle.BackgroundTransparency = 0.7
        particle.BorderSizePixel = 0
        particle.ZIndex = 201
        particle.Parent = notifFrame
        
        spawn(function()
            while particle and particle.Parent do
                TweenService:Create(particle, TweenInfo.new(math.random(2, 4)), {
                    Position = UDim2.fromScale(math.random(), math.random()),
                    BackgroundTransparency = 0.9
                }):Play()
                task.wait(math.random(2, 4))
            end
        end)
    end
    
    -- ===== ANIMAÇÃO DE ENTRADA (EXPANSÃO ÉPICA) =====
    
    -- Frame começa esmagado (achatado verticalmente)
    notifFrame.Size = UDim2.fromOffset(450, 0.01)
    notifFrame.BackgroundTransparency = 1
    
    -- Expansão espetacular
    local entrySequence = function()
        -- Fade-in rápido do background
        TweenService:Create(notifFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0
        }):Play()
        
        -- Expansão vertical com overshoot (efeito elástico)
        TweenService:Create(notifFrame, TweenInfo.new(0.6, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(400, 220)
        }):Play()
        
        -- Rotação do ícone na entrada
        imageContainer.Rotation = -180
        TweenService:Create(imageContainer, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Rotation = 0
        }):Play()
        
        -- Título aparece com delay (stagger effect)
        titleLabel.TextTransparency = 1
        task.delay(0.15, function()
            TweenService:Create(titleLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                TextTransparency = 0
            }):Play()
        end)
        
        -- Mensagem aparece com mais delay
        messageLabel.TextTransparency = 1
        task.delay(0.3, function()
            TweenService:Create(messageLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                TextTransparency = 0
            }):Play()
        end)
        
        -- Brilho pulsante contínuo
        spawn(function()
            while notifFrame and notifFrame.Parent do
                TweenService:Create(glowStroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    Transparency = 0.8
                }):Play()
                task.wait(1.5)
                TweenService:Create(glowStroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    Transparency = 0.2
                }):Play()
                task.wait(1.5)
            end
        end)
    end
    
    entrySequence()
    
    -- ===== ANIMAÇÃO DE SAÍDA (ESMAGAMENTO) =====
    
    task.delay(4, function()
        if not notifFrame or not notifFrame.Parent then return end
        
        -- Efeito de "sugar" tudo antes de esmagar
        local suckEffect = function()
            -- Título e mensagem desaparecem primeiro
            TweenService:Create(titleLabel, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                TextTransparency = 1
            }):Play()
            
            TweenService:Create(messageLabel, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                TextTransparency = 1
            }):Play()
            
            -- Ícone encolhe e gira
            task.delay(0.1, function()
                TweenService:Create(imageContainer, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                    Size = UDim2.fromOffset(0, 0),
                    Rotation = 180
                }):Play()
            end)
            
            -- Header e linha dourada desaparecem
            TweenService:Create(headerBar, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                BackgroundTransparency = 1
            }):Play()
            
            TweenService:Create(topLine, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Size = UDim2.new(0, 0, 0, 2),
                BackgroundTransparency = 1
            }):Play()
        end
        
        suckEffect()
        
        -- ESMAGAMENTO: frame colapsa verticalmente (efeito de prensa)
        task.delay(0.2, function()
            -- Borda perde a cor
            TweenService:Create(border, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Color = Color3.fromRGB(100, 50, 0),
                Thickness = 0
            }):Play()
            
            TweenService:Create(glowStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Transparency = 1,
                Thickness = 0
            }):Play()
            
            -- Esmagamento brutal: altura vai a zero, largura aumenta levemente
            TweenService:Create(notifFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                Size = UDim2.fromOffset(600, 0.01),
                BackgroundTransparency = 0.5
            }):Play()
        end)
        
        -- Destruição final após animação completa
        task.delay(0.7, function()
            if notifFrame and notifFrame.Parent then
                notifFrame:Destroy()
            end
        end)
    end)
end

-- ============================================================

player.CharacterRemoving:Connect(function()
    if customStandUserId then
        salvarStandId(customStandUserId)
        print("💾 ID do Stand salvo ao remover personagem!")
    end
end)

-- Salvamento extra quando o script é destruído
script.AncestryChanged:Connect(function()
    if not script.Parent then
        if customStandUserId then
            salvarStandId(customStandUserId)
            print("💾 Backup de emergência: ID salvo!")
        end
    end
end)

-- =============================================

local UI_NAME = "DioStandUniversal"

local function recreateUI()
    if screenGui and screenGui.Parent then return end

    print("🔄 [DioStand NUCLEAR] UI deletada! Recriando AGORA...")

    -- Prioridade máxima de parent: gethui() > CoreGui > PlayerGui
    local success, hui = pcall(function() return gethui() end)
    local parent = (success and hui) or 
                   (pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui")) or 
                   player:WaitForChild("PlayerGui")

    screenGui = Instance.new("ScreenGui")
    screenGui.Name = UI_NAME
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 9999  -- Fica por cima de quase tudo
    screenGui.Parent = parent

    -- ===================== RECRIAÇÃO COMPLETA =====================
    tsBtn, tsStroke, tsIcon = createCircularButton("TimeStopBtn", TS_POS, "STOP", nil, ASSETS.TS_IMAGE, 80)
    roadBtn, roadStroke = createCircularButton("RoadRollerBtn", ROAD_POS, "ROAD", Color3.fromRGB(170, 0, 255), nil, 70)
    activateBtn, actStroke, standIcon = createCircularButton("ActivateBtn", ACTIVATE_POS, "STAND", nil, ASSETS.STAND_IMAGE, 95)
    m1Btn, m1Stroke = createCircularButton("M1Btn", M1_POS, "M1", nil, nil, 80)
    knifeBtn, knifeStroke, knifeIcon = createCircularButton("KnifeBtn", KNIFE_POS_OFF, "KNIFE", nil, ASSETS.KNIFE_IMAGE, 80)

    resumeImage = Instance.new("ImageLabel", screenGui)
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

    -- Reaplica estados
    updateIconState(tsIcon, isTimeStopped)
    updateIconState(standIcon, isStandActive)
    updateIconState(knifeIcon, isStandActive)

    m1Btn.Visible = isStandActive
    roadBtn.Visible = isTimeStopped

    if isStandActive then
        updateKnifePosition(true)
        m1Btn.Position = M1_POS
        m1Btn.Size = UDim2.fromOffset(80, 80)
    else
        updateKnifePosition(false)
    end

    -- Reconecta cliques
    tsBtn.MouseButton1Click:Connect(toggleTime)
    activateBtn.MouseButton1Click:Connect(toggleStand)
    m1Btn.MouseButton1Click:Connect(performM1)
    knifeBtn.MouseButton1Click:Connect(performKnifeThrow)
    roadBtn.MouseButton1Click:Connect(performRoadRoller)

    -- Reaplica efeitos
    applyClickEffect(tsBtn, 80, "TimeStop")
    applyClickEffect(roadBtn, 70, "RoadRoller")
    applyClickEffect(activateBtn, 95, nil)
    applyClickEffect(m1Btn, 80, "M1")

    print("✅ [DioStand NUCLEAR] UI recriada com sucesso!")
end

-- ==================== PROTEÇÃO NUCLEAR ====================

local function startUIProtector()
    -- Verificação em TODOS os frames possíveis
    RunService.RenderStepped:Connect(function()
        if not screenGui or not screenGui.Parent then
            recreateUI()
        end
    end)

    RunService.Heartbeat:Connect(function()
        if not screenGui or not screenGui.Parent then
            recreateUI()
        end
    end)

    -- Detecção de destruição imediata
    local function onDescendantRemoving(desc)
        if desc.Name == UI_NAME or desc == screenGui then
            task.delay(0.01, recreateUI)  -- Quase instantâneo
        end
    end

    player.PlayerGui.DescendantRemoving:Connect(onDescendantRemoving)

    pcall(function()
        game:GetService("CoreGui").DescendantRemoving:Connect(onDescendantRemoving)
    end)

    -- Loop super agressivo (0.15s)
    task.spawn(function()
        while true do
            task.wait(0.15)
            if not screenGui or not screenGui.Parent then
                recreateUI()
            end
        end
    end)
end

-- Inicialização
task.spawn(function()
    task.wait(0.5)
    recreateUI()
    startUIProtector()
end)
