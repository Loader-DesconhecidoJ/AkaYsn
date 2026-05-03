local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hum = character:WaitForChild("Humanoid")

-- ============================================================
-- SISTEMA DE SALVAMENTO JSON
-- ============================================================
local ARQUIVO_CONFIG = "the_hand_config.json"

local function salvarStandId(userId)
    userId = tonumber(userId) or 0
    local config = {
        lastUserId = userId,
        lastUsed = os.time()
    }
    local sucesso, erro = pcall(function()
        local jsonData = game:GetService("HttpService"):JSONEncode(config)
        writefile(ARQUIVO_CONFIG, jsonData)
    end)
    if sucesso then
        print("💾 ID do Stand salvo: " .. tostring(userId))
        customStandUserId = userId > 0 and userId or nil
    else
        warn("❌ Erro ao salvar: " .. tostring(erro))
    end
end

local function carregarStandId()
    if not isfile(ARQUIVO_CONFIG) then
        print("📄 Nenhum arquivo de configuração encontrado.")
        return nil
    end
    local sucesso, conteudo = pcall(function()
        return readfile(ARQUIVO_CONFIG)
    end)
    if not sucesso or not conteudo then return nil end
    local sucesso2, config = pcall(function()
        return game:GetService("HttpService"):JSONDecode(conteudo)
    end)
    if sucesso2 and config and config.lastUserId ~= nil then
        print("📂 ID do Stand carregado: " .. tostring(config.lastUserId))
        return tonumber(config.lastUserId)
    end
    return nil
end

local function deletarArquivoConfig()
    if isfile(ARQUIVO_CONFIG) then
        pcall(function() delfile(ARQUIVO_CONFIG) end)
        print("🗑️ Arquivo de configuração deletado!")
    end
end

-- =========================================================
-- SISTEMA DE ANIMAÇÕES CUSTOMIZADAS (COMPLETO)
-- =========================================================

local CUSTOM_ANIMS = {
    Idle         = "rbxassetid://87348029422645",
    Walk         = "rbxassetid://83824798696498",
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

local function isR15()
    if not hum then return false end
    return hum.RigType == Enum.HumanoidRigType.R15
end

local originalIDs_anim = {}
local originalWalkSpeed_anim = 16
local jumpingConnection_anim = nil
local activeJumpTrack_anim = nil
local jumpStateConnection_anim = nil
local footprintConnection_anim = nil
local lastFootprintTime_anim = 0
local alternateFoot_anim = true
local idleTimer_anim = nil
local isIdle_anim = false
local sRunTrack_anim = nil
local lastSRunTime_anim = 0

-- =========================================================
-- FUNÇÕES DE ANIMAÇÃO
-- =========================================================

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
-- SISTEMA IDLE VARIANT (COMPLETO)
-- =========================================================

local IDLE_VARIANT_SETTINGS = {
    AnimId = "rbxassetid://133201196209194",
    SoundId = "rbxassetid://119056579190272",
    SpeechId = "107413276128350",
    WaitTime = 10,
    SoundVolume = 1.8,
    SpeechDuration = 3,
    SpeechSide = "right"
}

local idleVariant_Track = nil
local idleVariant_Timer = 0
local idleVariant_Active = false

local function playIdleVariant()
    if not hum or not character then return end
    
    if idleVariant_Track then
        pcall(function() idleVariant_Track:Stop() end)
        idleVariant_Track = nil
    end
    
    local anim = Instance.new("Animation")
    anim.AnimationId = IDLE_VARIANT_SETTINGS.AnimId
    idleVariant_Track = hum:LoadAnimation(anim)

    if idleVariant_Track then
        idleVariant_Track.Looped = false      
        idleVariant_Track.Priority = Enum.AnimationPriority.Idle
        idleVariant_Track:Play(0.3)
        idleVariant_Track:AdjustSpeed(1.4)      
    end
    
    local head = character:FindFirstChild("Head")
    local sound = Instance.new("Sound")
    sound.SoundId = IDLE_VARIANT_SETTINGS.SoundId
    sound.Volume = IDLE_VARIANT_SETTINGS.SoundVolume
    sound.Parent = head or character:FindFirstChild("HumanoidRootPart") or workspace
    sound:Play()
    game.Debris:AddItem(sound, 6)
    
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
        imageLabel.Size = UDim2.new(0.1, 0, 0.1, 0)
        imageLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
        imageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
        imageLabel.ImageTransparency = 1
        imageLabel.Rotation = -15
        imageLabel.Parent = billboard
        
        TweenService:Create(imageLabel, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(1.1, 0, 1.1, 0),
            ImageTransparency = 0,
            Rotation = 0
        }):Play()
        
        task.delay(0.4, function()
            if imageLabel and imageLabel.Parent then
                TweenService:Create(imageLabel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = UDim2.new(1, 0, 1, 0)
                }):Play()
            end
        end)
        
        task.delay(0.6, function()
            if imageLabel and imageLabel.Parent then
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

        task.delay(IDLE_VARIANT_SETTINGS.SpeechDuration - 0.4, function()
            if billboard and billboard.Parent then
                TweenService:Create(imageLabel, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                    Size = UDim2.new(0.1, 0, 0.1, 0),
                    ImageTransparency = 1,
                    Rotation = 15
                }):Play()
                
                task.delay(0.4, function()
                    if billboard and billboard.Parent then
                        billboard:Destroy()
                    end
                end)
            end
        end)
    end
    
    if idleVariant_Track then
        idleVariant_Track.Stopped:Once(function()
            idleVariant_Track = nil
            if idleVariant_Active then
                idleVariant_Timer = 0
            end
        end)
    end
end

local function checkIdleStatus(deltaTime)
    if not hum or not character then return end
    
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local speed = Vector3.new(root.Velocity.X, 0, root.Velocity.Z).Magnitude
    
    if speed > 2 then
        idleVariant_Timer = 0
        idleVariant_Active = false
        
        if idleVariant_Track then
            pcall(function() idleVariant_Track:Stop() end)
            idleVariant_Track = nil
        end
        return
    end
    
    idleVariant_Timer = idleVariant_Timer + deltaTime
    
    if idleVariant_Timer >= IDLE_VARIANT_SETTINGS.WaitTime and not idleVariant_Active then
        idleVariant_Active = true
        playIdleVariant()
    end
    
    if idleVariant_Timer >= IDLE_VARIANT_SETTINGS.WaitTime and idleVariant_Active and not idleVariant_Track then
        idleVariant_Active = false
        idleVariant_Timer = 0
    end
end

RunService.Heartbeat:Connect(function(deltaTime)
    if not isR15() then return end
    checkIdleStatus(deltaTime)
end)

player.CharacterAdded:Connect(function(newChar)
    idleVariant_Timer = 0
    idleVariant_Active = false
    if idleVariant_Track then
        pcall(function() idleVariant_Track:Stop() end)
        idleVariant_Track = nil
    end
end)

-- =========================================================
-- OUTRAS FUNÇÕES DE ANIMAÇÃO
-- =========================================================

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

-- =========================================================
-- LIMPEZA E CONFIGURAÇÃO DAS ANIMAÇÕES
-- =========================================================

local function cleanupCustomAnims()
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

    -- ==================== SÓ APLICAR EM R15 ====================
    if not isR15() then
        print("🛑 Custom Anims, IdleVariant e Footprints desativados (R6 detectado)")
        return
    end
    -- ========================================================

    local animate = char:WaitForChild("Animate", 5)

    if animate then
        animate:WaitForChild("idle", 3)
        animate:WaitForChild("walk", 3)
        animate:WaitForChild("run", 3)
        animate:WaitForChild("fall", 3)
    else
        warn("[TheHand] Animate não encontrado no personagem!")
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

    if jumpingConnection_anim then jumpingConnection_anim:Disconnect() end
    jumpingConnection_anim = hum.Jumping:Connect(function()
        if not SETTINGS.Enabled or not isR15() then return end
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
        if not isR15() then return end
        if activeJumpTrack_anim and activeJumpTrack_anim.IsPlaying then
            if newState ~= Enum.HumanoidStateType.Jumping and newState ~= Enum.HumanoidStateType.Freefall then
                activeJumpTrack_anim:Stop(0.15)
            end
        end
    end)

    if footprintConnection_anim then footprintConnection_anim:Disconnect() end
    footprintConnection_anim = RunService.Heartbeat:Connect(function()
        if not isR15() then return end
        
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

-- ============================================================
-- ASSETS DO THE HAND
-- ============================================================
local ASSETS = {
    STAND_ACTIVATE_SFX = "rbxassetid://1228344855",
    ERASE_SOUND = "rbxassetid://129674320502853",
    STAND_IDLE = "rbxassetid://98789048056989",
    STAND_WALK = "rbxassetid://91106826233224",
    STAND_RUN = "rbxassetid://99823081022996",  
    ERASE_ANIM = "rbxassetid://139217391004393",
    STAND_IMAGE = "rbxassetid://71063600838165",
    ERASE_IMAGE = "rbxassetid://107526909795121",
    OI_IMAGE = "94794505267303",
    KUSO_IMAGE = "83774881013358",
 
    DEACTIVATE_BUBBLES = {
        "84402000641079",   -- He arrives
        "120879643794125",   -- Rest
    },
}

local COLORS = {
    Blue       = Color3.fromRGB(0, 100, 255),
    LightBlue  = Color3.fromRGB(100, 180, 255),
    White      = Color3.fromRGB(255, 255, 255),
    Black      = Color3.fromRGB(10, 10, 15),
    Yellow     = Color3.fromRGB(255, 255, 100),
}

-- ============================================================
-- VARIÁVEIS DO STAND
-- ============================================================
local idSalvo = carregarStandId()
local customStandUserId = idSalvo and idSalvo > 0 and idSalvo or nil

local STAND_OFFSET = Vector3.new(3, 2.5, 2.5)
local isStandActive = false
local isAttacking = false
local currentStand = nil
local idleTrack = nil
local walkTrack = nil
local runTrack = nil  
local standChangerGui = nil   
local buttonDebounce = false
local flingNoclipHumans = {}
local flingNoclipConstraints = {}
local FlingTargetRoot = nil

local COOLDOWNS = {
    Erase = 1.7,
    SelfErase = 2.5,
}

local lastUsed = {Erase = 0, SelfErase = 0}
local isAbilityLocked = {Erase = false, SelfErase = false}

-- ============================================================
-- FUNÇÃO AUXILIAR: ENCONTRAR MÃO DIREITA (CORRIGIDO)
-- ============================================================
local function findRightHand(model)
    if not model then return nil end
    
    -- Tenta encontrar diretamente
    local rightHand = model:FindFirstChild("RightHand")
    if rightHand and rightHand:IsA("BasePart") then
        return rightHand
    end
    
    -- Procura no Right Arm (R15/Rthro)
    local rightArm = model:FindFirstChild("Right Arm") or model:FindFirstChild("RightArm")
    if rightArm and rightArm:IsA("BasePart") then
        rightHand = rightArm:FindFirstChild("RightHand")
        if rightHand then return rightHand end
    end
    
    -- Procura recursivamente em todos os descendentes
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant.Name == "RightHand" and descendant:IsA("BasePart") then
            return descendant
        end
    end
    
    -- Fallback: usa qualquer parte que contenha "RightHand" no nome
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant.Name:find("RightHand") then
            return descendant
        end
    end
    
    warn("⚠️ Não foi possível encontrar a mão direita do Stand")
    return nil
end

-- ============================================================
-- 🧱 NOCLIP TEMPORÁRIO (SÓ ATIVA NO ERASE POR 3 SEGUNDOS)
-- ============================================================
local tempNoclipConnection = nil
local tempNoclipEndTime = 0

local function desativarColisaoModelo(model)
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end

local function ativarNoClipTemporario()
    -- Se já existe uma conexão, limpa
    if tempNoclipConnection then
        tempNoclipConnection:Disconnect()
        tempNoclipConnection = nil
    end
    
    -- Marca o tempo de início
    tempNoclipEndTime = tick() + 3  -- 3 segundos
    
    local localPlayer = Players.LocalPlayer
    
    tempNoclipConnection = RunService.Stepped:Connect(function()
        -- Verifica se passou 3 segundos
        if tick() >= tempNoclipEndTime then
            if tempNoclipConnection then
                tempNoclipConnection:Disconnect()
                tempNoclipConnection = nil
                print("🔓 Noclip temporário desativado")
            end
            return
        end
        
        -- Desativa colisão de outros jogadores
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer and player.Character then
                pcall(function()
                    desativarColisaoModelo(player.Character)
                end)
            end
        end
        
        -- Desativa colisão de NPCs
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Humanoid") then
                local npc = obj.Parent
                if npc and npc:IsA("Model") and npc ~= character then
                    if npc:FindFirstChild("HumanoidRootPart") then
                        pcall(function()
                            desativarColisaoModelo(npc)
                        end)
                    end
                end
            end
        end
    end)
    
    print("🔒 Noclip temporário ativado (3 segundos)")
end

local function desativarNoClipTemporario()
    if tempNoclipConnection then
        tempNoclipConnection:Disconnect()
        tempNoclipConnection = nil
        print("🔓 Noclip temporário desativado manualmente")
    end
end

local function StartFling(targetRoot)
    local charRoot = character:FindFirstChild("HumanoidRootPart")
    if not charRoot or not hum or hum.Health <= 0 then return end
    
    FlingTargetRoot = targetRoot
    
    local flingConnection
    local startFlingTime = tick()
    local MAX_FLING_TIME = 3
    
    flingConnection = RunService.Stepped:Connect(function()
        if tick() - startFlingTime > MAX_FLING_TIME then
            if flingConnection then flingConnection:Disconnect() end
            return
        end
        
        if not character or not charRoot or hum.Health <= 0 then
            if flingConnection then flingConnection:Disconnect() end
            return
        end
        
        if not FlingTargetRoot or not FlingTargetRoot.Parent then
            if flingConnection then flingConnection:Disconnect() end
            return
        end
        
        local targetHum = FlingTargetRoot.Parent:FindFirstChildOfClass("Humanoid")
        if targetHum and targetHum.Health <= 0 then
            if flingConnection then flingConnection:Disconnect() end
            return
        end
        
        pcall(function()
            sethiddenproperty(charRoot, "PhysicsRepRootPart", FlingTargetRoot)
        end)
        
        pcall(function()
            local Nan = 0/0
            local NanVec = Vector3.new(Nan, Nan, Nan)
            sethiddenproperty(hum, "MoveDirectionInternal", NanVec)
            charRoot.AssemblyLinearVelocity = NanVec
            charRoot.AssemblyAngularVelocity = NanVec
        end)
    end)
    
    if character then
        local destroyConn
        destroyConn = character.Destroying:Connect(function()
            FlingTargetRoot = nil
            if flingConnection then flingConnection:Disconnect() end
            if destroyConn then destroyConn:Disconnect() end
        end)
    end
end

local function CleanUpFling()
    FlingTargetRoot = nil
    
    if character and character:FindFirstChild("HumanoidRootPart") then
        pcall(function()
            sethiddenproperty(character.HumanoidRootPart, "PhysicsRepRootPart", nil)
        end)
    end
    
    if hum then
        pcall(function()
            sethiddenproperty(hum, "MoveDirectionInternal", Vector3.new(0, 0, 0))
        end)
    end
end

-- ============================================================
-- SISTEMA DE STAND MODEL
-- ============================================================
local ACCESSORY_TAG = "TheHandAccessory"

local function getStandModel(depth)
    depth = depth or 0
    
    -- Proteção contra loop infinito
    if depth > 3 then
        warn("❌ Falha crítica: Não foi possível criar o Stand após 3 tentativas")
        return nil
    end
    
    local targetUserId = customStandUserId or player.UserId
    local success, model = pcall(function()
        local description = Players:GetHumanoidDescriptionFromUserId(targetUserId)
        local standModel = Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
        return standModel
    end)
    
    if not success or not model then
        warn("❌ Falha ao criar Stand (tentativa " .. depth .. "). Usando fallback...")
        customStandUserId = nil
        return getStandModel(depth + 1)  -- ✅ Agora tem limite de profundidade
    end
    
    model.Name = "TheHand"
    model.Archivable = true
    
    -- Marca o modelo com tag para identificação
    model:SetAttribute(ACCESSORY_TAG, true)
    
    for _, child in ipairs(model:GetChildren()) do
        if child:GetAttribute(ACCESSORY_TAG) then child:Destroy() end
    end
    for _, obj in ipairs(model:GetDescendants()) do
        if obj:GetAttribute(ACCESSORY_TAG) then obj:Destroy() end
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
        elseif obj:IsA("LuaSourceContainer") then
            obj:Destroy()
        end
    end
    
    local sHum = model:FindFirstChildOfClass("Humanoid")
    if sHum then
        sHum.RigType = Enum.HumanoidRigType.R15
        sHum.PlatformStand = true
        sHum.AutoRotate = false
        sHum.HipHeight = 0
    end
    
    return model
end

-- ============================================================
-- 🌌 EFEITO FOV ZOOM (RASGANDO O ESPAÇO-TEMPO) - SEM LINHAS
-- ============================================================
local FOV_ZOOM_CONFIG = {
    ZoomIntensity = 15,         -- Quanto o FOV diminui (70 → 55)
    ZoomSpeed = 0.06,           -- Velocidade do zoom IN (mais rápido)
    ReturnSpeed = 0.2,          -- Velocidade do zoom OUT (mais lento)
}

local function playSpaceTimeSlash(dashDirection)
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    local camera = workspace.CurrentCamera
    if not camera then return end
    
    local originalFOV = camera.FieldOfView
    
    -- =============================================
    -- EFEITO 1: ZOOM RÁPIDO (FOV diminui e volta)
    -- =============================================
    local zoomConnection
    local zoomStart = tick()
    local targetFOV = originalFOV - FOV_ZOOM_CONFIG.ZoomIntensity
    
    zoomConnection = RunService.RenderStepped:Connect(function()
        local elapsed = tick() - zoomStart
        
        -- Fase 1: Zoom IN rápido
        if elapsed < FOV_ZOOM_CONFIG.ZoomSpeed then
            local progress = elapsed / FOV_ZOOM_CONFIG.ZoomSpeed
            -- Easing Out para dar impacto
            local eased = 1 - (1 - progress) * (1 - progress)
            camera.FieldOfView = originalFOV + (targetFOV - originalFOV) * eased
        
        -- Fase 2: Zoom OUT lento (recuperação)
        elseif elapsed < FOV_ZOOM_CONFIG.ZoomSpeed + FOV_ZOOM_CONFIG.ReturnSpeed then
            local returnElapsed = elapsed - FOV_ZOOM_CONFIG.ZoomSpeed
            local returnProgress = returnElapsed / FOV_ZOOM_CONFIG.ReturnSpeed
            -- Easing InOut suave
            local eased = returnProgress < 0.5 
                and 2 * returnProgress * returnProgress 
                or 1 - (-2 * returnProgress + 2) * (-2 * returnProgress + 2) / 2
            camera.FieldOfView = targetFOV + (originalFOV - targetFOV) * eased
        
        -- Fim do efeito
        else
            camera.FieldOfView = originalFOV
            zoomConnection:Disconnect()
        end
    end)
    
    -- =============================================
    -- EFEITO 2: CHROMA SHIFT (cores azuladas)
    -- =============================================
    local colorCorrection = Instance.new("ColorCorrectionEffect")
    colorCorrection.Name = "SpaceTimeShift"
    colorCorrection.Saturation = 0.3
    colorCorrection.Contrast = 0.4
    colorCorrection.TintColor = Color3.fromRGB(100, 180, 255)
    colorCorrection.Parent = Lighting
    
    task.spawn(function()
        -- Fase 1: Cores ficam azuladas rapidamente
        TweenService:Create(colorCorrection, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Saturation = -0.6,
            Contrast = 0.7,
        }):Play()
        task.wait(0.1)
        
        -- Fase 2: Retorno suave ao normal
        local fadeBack = TweenService:Create(colorCorrection, 
            TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
            Saturation = 0,
            Contrast = 0,
            TintColor = Color3.fromRGB(255, 255, 255),
        })
        fadeBack:Play()
        fadeBack.Completed:Wait()
        
        colorCorrection:Destroy()
    end)
    
    -- =============================================
    -- EFEITO 3: BLUR (borrão nas bordas)
    -- =============================================
    local blur = Instance.new("BlurEffect")
    blur.Name = "SpaceTimeBlur"
    blur.Size = 0
    blur.Parent = Lighting
    
    task.spawn(function()
        -- Aparece rápido
        TweenService:Create(blur, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = 4,
        }):Play()
        task.wait(0.08)
        
        -- Desaparece lentamente
        TweenService:Create(blur, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
            Size = 0,
        }):Play()
        task.wait(0.7)
        
        blur:Destroy()
    end)
    
    -- Garante que o FOV volte ao normal
    task.delay(1, function()
        if zoomConnection then
            zoomConnection:Disconnect()
        end
        if camera then
            camera.FieldOfView = originalFOV
        end
    end)
    
    print("🌌 Rasgo espaço-temporal ativado!")
end

-- ============================================================
-- FUNÇÕES UTILITÁRIAS
-- ============================================================
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

local function getClosestTarget(maxDist)
    local closest, minDist = nil, maxDist
    local root = character and character:FindFirstChild("HumanoidRootPart")
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

local function showSpeechBubble(imageId, side, duration, customHead)
    if not customHead then
        if not character or not character:FindFirstChild("Head") then return end
        customHead = character.Head
    end
    local head = customHead
    if not head or not head.Parent then return end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "SpeechBubble"
    billboard.Adornee = head
    billboard.Size = UDim2.new(3.5, 0, 3.5, 0)
    billboard.StudsOffset = Vector3.new(side == "right" and 1.8 or -1.8, 1.5, 0)
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.MaxDistance = 100
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
            TweenService:Create(imageLabel, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Size = UDim2.new(0.2, 0, 0.2, 0),
                ImageTransparency = 1
            }):Play()
            task.delay(0.4, function()
                if billboard and billboard.Parent then billboard:Destroy() end
            end)
        end
    end)
end

local function lockAbility(abilityName)
    if isAbilityLocked[abilityName] then return false end
    isAbilityLocked[abilityName] = true
    task.delay(COOLDOWNS[abilityName], function()
        isAbilityLocked[abilityName] = false
    end)
    return true
end

local function canUseStrict(abilityName)
    if isAbilityLocked[abilityName] then return false end
    if tick() - lastUsed[abilityName] < COOLDOWNS[abilityName] then return false end
    return true
end

-- ============================================================
-- SISTEMA DE COOLDOWN VISUAL
-- ============================================================

local cooldownBars = {}

local function createCooldownBar(button, abilityName, duration)
    local barContainer = Instance.new("Frame")
    barContainer.Name = abilityName .. "_Cooldown"
    barContainer.Size = UDim2.new(1.1, 0, 0, 10)
    barContainer.Position = UDim2.new(-0.05, 0, -0.15, 0)
    barContainer.AnchorPoint = Vector2.new(0, 1)
    barContainer.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    barContainer.BackgroundTransparency = 1
    barContainer.ZIndex = 10
    barContainer.Parent = button
    
    local border = Instance.new("UIStroke")
    border.Color = Color3.fromRGB(0, 150, 255)
    border.Thickness = 1.5
    border.Transparency = 0.3
    border.Parent = barContainer
    
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.new(1, 0, 1, 0)
    background.Position = UDim2.new(0, 0, 0, 0)
    background.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    background.BorderSizePixel = 0
    background.ZIndex = 10
    background.Parent = barContainer
    Instance.new("UICorner", background).CornerRadius = UDim.new(0, 3)
    
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(1, 0, 1, 0)
    fill.Position = UDim2.new(0, 0, 0, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    fill.BorderSizePixel = 0
    fill.ZIndex = 11
    fill.Parent = barContainer
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 3)
    
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 180, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 120, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 60, 200))
    }
    gradient.Parent = fill
    
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
    
    barContainer.Size = UDim2.new(1.1, 0, 0, 0)
    barContainer.BackgroundTransparency = 1
    
    TweenService:Create(barContainer, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(1.1, 0, 0, 10),
        BackgroundTransparency = 0
    }):Play()
    
    task.spawn(function()
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
    
    return barContainer, fill, countText, gradient
end

local function showCooldownOnButton(button, abilityName)
    if cooldownBars[abilityName] and cooldownBars[abilityName].Parent then
        cooldownBars[abilityName]:Destroy()
    end
    
    local duration = COOLDOWNS[abilityName]
    local barContainer, fill, countText, gradient = createCooldownBar(button, abilityName, duration)
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
        
        if progress < 0.3 then
            gradient.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 50, 50)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 100, 50)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 30, 30))
            }
            countText.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
    end)
    
    local existingBars = 0
    for _, child in ipairs(button:GetChildren()) do
        if child:IsA("Frame") and child.Name:find("_Cooldown") and child ~= barContainer then
            existingBars = existingBars + 1
        end
    end
    
    barContainer.Position = UDim2.new(-0.05, 0, -0.15 - (existingBars * 0.12), 0)
end

-- ============================================================
-- FUNÇÕES DE ANIMAÇÃO DOS BOTÕES
-- ============================================================

local function animateButtonOut(button, targetPosition, delay)
    delay = delay or 0
    
    local startPos = UDim2.new(0.5, 0, 0.75, 0)
    
    button.Position = startPos
    button.Size = UDim2.fromOffset(0, 0)
    button.BackgroundTransparency = 1
    button.TextTransparency = 1
    button.Visible = true
    
    task.wait(delay)
    
    local expandTween = TweenService:Create(button, 
        TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), 
        {
            Position = targetPosition,
            Size = UDim2.fromOffset(80, 80),
            BackgroundTransparency = 0,
            TextTransparency = 0
        }
    )
    expandTween:Play()
    
    expandTween.Completed:Connect(function()
        button.TextTransparency = 0
    end)
    
    return expandTween
end

local function animateButtonIn(button, delay)
    delay = delay or 0
    
    local shrinkTween = TweenService:Create(button,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
        {
            Position = UDim2.new(0.5, 0, 0.75, 0),
            Size = UDim2.fromOffset(0, 0),
            BackgroundTransparency = 1,
            TextTransparency = 1
        }
    )
    shrinkTween:Play()
    
    shrinkTween.Completed:Connect(function()
        button.Visible = false
    end)
    
    return shrinkTween
end

-- ============================================================
-- SCREEN GUI
-- ============================================================
local screenGui = Instance.new("ScreenGui", player.PlayerGui)
screenGui.Name = "TheHandStand"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling  
screenGui.DisplayOrder = 999  

local function createButton(name, pos, text, color, size)
    size = size or 70
    color = color or Color3.fromRGB(0, 150, 255)
    
    local btn = Instance.new("TextButton", screenGui)
    btn.Name = name
    btn.Size = UDim2.fromOffset(size, size)
    btn.Position = pos
    btn.AnchorPoint = Vector2.new(0.5, 0.5)
    btn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Bangers
    btn.TextSize = 14
    btn.TextTransparency = 0
    btn.TextStrokeTransparency = 0
    btn.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    btn.AutoButtonColor = false
    btn.ZIndex = 1
    
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    
    local stroke = Instance.new("UIStroke", btn)
    stroke.Name = "MainStroke"
    stroke.Color = color
    stroke.Thickness = 3
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.ZIndex = 2
    
    local glowStroke = Instance.new("UIStroke", btn)
    glowStroke.Name = "GlowStroke"
    glowStroke.Color = color
    glowStroke.Thickness = 5
    glowStroke.Transparency = 0.6
    glowStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    glowStroke.ZIndex = 0
    
    local gradient = Instance.new("UIGradient", btn)
    gradient.Name = "ButtonGradient"
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(15, 15, 20)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 35))
    }
    gradient.Rotation = 45
    
    spawn(function()
        while btn and btn.Parent do
            TweenService:Create(glowStroke, TweenInfo.new(1.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Transparency = 0.75,
                Thickness = 6
            }):Play()
            task.wait(1.0)
            TweenService:Create(glowStroke, TweenInfo.new(1.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Transparency = 0.45,
                Thickness = 4
            }):Play()
            task.wait(1.0)
        end
    end)
    
    return btn, stroke, glowStroke
end

local activateBtn, actStroke, actGlow = createButton("ActivateBtn", UDim2.new(0.5, 0, 0.75, 0), "STAND", COLORS.Blue, 95)
local eraseBtn, eraseStroke, eraseGlow = createButton("EraseBtn", UDim2.new(0.6, 0, 0.78, 0), "ERASE", Color3.fromRGB(255, 255, 100), 80)
local selfEraseBtn, seStroke, seGlow = createButton("SelfEraseBtn", UDim2.new(0.37, 0, 0.78, 0), "DASH", Color3.fromRGB(0, 255, 200), 70)

selfEraseBtn.ZIndex = 100
selfEraseBtn.Active = true
selfEraseBtn.TextSize = 16
selfEraseBtn.TextColor3 = Color3.fromRGB(200, 255, 255)
selfEraseBtn.Visible = true
selfEraseBtn.Size = UDim2.fromOffset(70, 70)
selfEraseBtn.BackgroundTransparency = 0
selfEraseBtn.Position = UDim2.new(0.6, 0, 0.79, 0)

activateBtn.ZIndex = 100  
activateBtn.Active = true 
eraseBtn.ZIndex = 100
eraseBtn.Active = true

activateBtn.TextSize = 28
activateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

eraseBtn.TextSize = 22
eraseBtn.TextColor3 = Color3.fromRGB(255, 255, 200)

eraseBtn.Visible = false
eraseBtn.Size = UDim2.fromOffset(0, 0)
eraseBtn.BackgroundTransparency = 1

-- ============================================================
-- HABILIDADE SELF ERASE (DASH DE APAGAMENTO)
-- ============================================================

local function performSelfErase()
    if not canUseStrict("SelfErase") then return end
    if isAttacking then return end
    
    lockAbility("SelfErase")
    isAttacking = true
    
    local charRoot = character:FindFirstChild("HumanoidRootPart")
    if not charRoot then isAttacking = false return end
    
    -- 🔊 Som de dash
    local dashSound = Instance.new("Sound", workspace)
    dashSound.SoundId = "rbxassetid://70940902232180"
    dashSound.Volume = 1.5
    dashSound.PlaybackSpeed = 1.1
    dashSound:Play()
    Debris:AddItem(dashSound, 2)
    
    -- 🗯️ Balão de fala
    showSpeechBubble("94794505267303", "right", 1)
    
    -- ⚡ DASH NA DIREÇÃO QUE O BONECO ESTÁ OLHANDO
    local moveDirection = charRoot.CFrame.LookVector
    
    -- 🌌 ATIVA EFEITO ESPAÇO-TEMPO
playSpaceTimeSlash(moveDirection)
    
    -- 💥 Camera shake
    cameraShake(0.4, 2)
    
    -- 🌌 VFX DE APAGAMENTO NA POSIÇÃO ATUAL (antes do dash)
    local startPos = charRoot.Position
    local vfxPart = Instance.new("Part")
    vfxPart.Name = "SelfEraseVFX"
    vfxPart.Size = Vector3.new(0.5, 0.5, 0.5)
    vfxPart.Position = startPos
    vfxPart.Anchored = true
    vfxPart.CanCollide = false
    vfxPart.Transparency = 1
    vfxPart.Parent = workspace
    Debris:AddItem(vfxPart, 2)
    
    -- Partículas de onde você saiu
    local attach1 = Instance.new("Attachment", vfxPart)
    local pe1 = Instance.new("ParticleEmitter", attach1)
    pe1.Texture = "rbxassetid://14317181033"
    pe1.Color = ColorSequence.new(Color3.fromRGB(0, 150, 255))
    pe1.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 0)})
    pe1.Lifetime = NumberRange.new(0.3, 0.6)
    pe1.Rate = 80
    pe1.Speed = NumberRange.new(1, 3)
    pe1.SpreadAngle = Vector2.new(180, 180)
    pe1.LightEmission = 1
    pe1.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
    task.delay(0.5, function() pe1.Enabled = false end)
    
    -- 🔸 Highlight com animação pulsante no seu personagem
    local selfHighlight = Instance.new("Highlight", character)
    selfHighlight.Name = "SelfEraseHighlight"
    selfHighlight.OutlineColor = Color3.fromRGB(0, 200, 255)
    selfHighlight.OutlineTransparency = 1
    selfHighlight.FillColor = Color3.fromRGB(0, 150, 255)
    selfHighlight.FillTransparency = 1

    TweenService:Create(selfHighlight, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        OutlineTransparency = 0.3,
        FillTransparency = 0.7
    }):Play()

task.delay(0.3, function()
    if selfHighlight and selfHighlight.Parent then
        -- Animação rápida de saída
        TweenService:Create(selfHighlight, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            OutlineTransparency = 1,
            FillTransparency = 1
        }):Play()
        task.delay(0.2, function()
            if selfHighlight and selfHighlight.Parent then
                selfHighlight:Destroy()
            end
        end)
    end
end)
    
    task.wait(0.1)  -- Pequena espera pro VFX
    
    -- ⚡ DASH NA DIREÇÃO QUE O BONECO ESTÁ OLHANDO
    local moveDirection = charRoot.CFrame.LookVector
    
    local dashDistance = 50
    local targetPos = startPos + (moveDirection * dashDistance)
    
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.FilterDescendantsInstances = {character}

local rayResult = workspace:Raycast(startPos, moveDirection * dashDistance, rayParams)
if rayResult then
    targetPos = rayResult.Position - (moveDirection * 2)
end
    
    -- ❄️ Congela o personagem por um frame (efeito de apagamento)
    local freezeConnection
    freezeConnection = RunService.Stepped:Connect(function()
        charRoot.Velocity = Vector3.new(0, 0, 0)
        charRoot.RotVelocity = Vector3.new(0, 0, 0)
        freezeConnection:Disconnect()
    end)
    
    -- 🚀 TELEPORTA (DASH)
    charRoot.CFrame = CFrame.new(targetPos)
    charRoot.Velocity = moveDirection * 30  -- Impulso residual
    
    -- 🌌 VFX NO DESTINO
    local endVFX = Instance.new("Part")
    endVFX.Name = "SelfEraseEnd"
    endVFX.Size = Vector3.new(0.5, 0.5, 0.5)
    endVFX.Position = targetPos
    endVFX.Anchored = true
    endVFX.CanCollide = false
    endVFX.Transparency = 1
    endVFX.Parent = workspace
    Debris:AddItem(endVFX, 2)
    
    local attach2 = Instance.new("Attachment", endVFX)
    local pe2 = Instance.new("ParticleEmitter", attach2)
    pe2.Texture = "rbxassetid://14317181033"
    pe2.Color = ColorSequence.new(Color3.fromRGB(0, 200, 255))
    pe2.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 5), NumberSequenceKeypoint.new(1, 0)})
    pe2.Lifetime = NumberRange.new(0.3, 0.5)
    pe2.Rate = 100
    pe2.Speed = NumberRange.new(2, 5)
    pe2.SpreadAngle = Vector2.new(180, 180)
    pe2.LightEmission = 1
    pe2.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
    pe2.Acceleration = Vector3.new(0, 10, 0)
    task.delay(0.5, function() pe2.Enabled = false end)
    
    -- ✅ Finaliza
    lastUsed["SelfErase"] = tick()
    isAttacking = false
    showCooldownOnButton(selfEraseBtn, "SelfErase")
    
    print("💨 Self Erase Dash realizado!")
end

-- ============================================================
-- HABILIDADE DO THE HAND - ERASE (COM FLING)
-- ============================================================

local function performErase()
    if not canUseStrict("Erase") then return end
    if not isStandActive or not currentStand or isAttacking then return end
    
    local targetRoot = getClosestTarget(30) 
    
    if not targetRoot then
        -- 🗯️ Balão de fala "KUSO!"
        showSpeechBubble(ASSETS.KUSO_IMAGE, "right", 1.3)
        
        -- 🔊 Som de erro/grunhido
        local noTargetSound = Instance.new("Sound")
        noTargetSound.SoundId = "rbxassetid://110528754168298"
        noTargetSound.Volume = 1.5
        noTargetSound.Parent = character:FindFirstChild("Head") or workspace
        noTargetSound:Play()
        Debris:AddItem(noTargetSound, 3)
        
        -- ⏱️ Ativa cooldown no botão
        lockAbility("Erase")
        lastUsed["Erase"] = tick()
        showCooldownOnButton(eraseBtn, "Erase")
        
        print("❌ Nenhum alvo encontrado em 30 metros")
        return
    end
    
    -- ⏱️ Trava a habilidade
    lockAbility("Erase")
    
    isAttacking = true
    local sHum = currentStand:FindFirstChildOfClass("Humanoid")
    local sRoot = currentStand:FindFirstChild("HumanoidRootPart")
    local charRoot = character:FindFirstChild("HumanoidRootPart")
    
    if not sHum or not sRoot or not charRoot then
        isAttacking = false
        return
    end
    
    showSpeechBubble("119730997112794", "right", 1)
    
    -- Guarda a posição de retorno
    local returnCFrame = charRoot.CFrame * CFrame.new(STAND_OFFSET)
    
    -- =============================================
    -- FASE 1: STAND VAI ATÉ O ALVO
    -- =============================================
    if idleTrack and idleTrack.IsPlaying then idleTrack:Stop() end
    if walkTrack and walkTrack.IsPlaying then walkTrack:Stop() end
    if runTrack and runTrack.IsPlaying then runTrack:Stop() end
    
    local targetPos = targetRoot.Position
    local directionToTarget = (targetPos - charRoot.Position).Unit
    local standDestination = targetPos - directionToTarget * 5
    standDestination = Vector3.new(standDestination.X, targetPos.Y + 3, standDestination.Z)
    local lookAtTarget = CFrame.lookAt(standDestination, targetPos)
    
    local moveTween = TweenService:Create(sRoot, 
        TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
        {CFrame = lookAtTarget}
    )
    moveTween:Play()
    moveTween.Completed:Wait()
    
-- =============================================
-- FASE 2: ANIMAÇÃO DE ERASE (TOCA NORMALMENTE)
-- =============================================
local eraseAnim = Instance.new("Animation")
eraseAnim.AnimationId = ASSETS.ERASE_ANIM
local eraseTrack = sHum:LoadAnimation(eraseAnim)
eraseTrack.Looped = false
eraseTrack.Priority = Enum.AnimationPriority.Action
eraseTrack:Play(0)

-- ⚡ AJUSTE DE VELOCIDADE AQUI
local ERASE_ANIM_SPEED = 5.45
eraseTrack:AdjustSpeed(ERASE_ANIM_SPEED)

local animLength = eraseTrack.Length
    
    -- Trail na mão direita
    local sRightHand = findRightHand(currentStand)
    local trailMain, trailOutline, att0, att1, trailPart

    if sRightHand then
        local handSize = sRightHand.Size * 1.7

        trailPart = Instance.new("Part")
        trailPart.Name = "TheHandTrailPart"
        trailPart.Size = handSize
        trailPart.Transparency = 1
        trailPart.CanCollide = false
        trailPart.Anchored = false
        trailPart.CFrame = sRightHand.CFrame
        trailPart.Parent = currentStand

        local weld = Instance.new("WeldConstraint")
        weld.Part0 = trailPart
        weld.Part1 = sRightHand
        weld.Parent = trailPart

        att0 = Instance.new("Attachment", trailPart)
        att0.Position = Vector3.new(0, handSize.Y * 0.56, 0)
        att1 = Instance.new("Attachment", trailPart)
        att1.Position = Vector3.new(0, -handSize.Y * 0.56, 0)

        trailOutline = Instance.new("Trail", trailPart)
        trailOutline.Name = "TrailOutline"
        trailOutline.Attachment0 = att0
        trailOutline.Attachment1 = att1
        trailOutline.Lifetime = 0.80
        trailOutline.MinLength = 0.1
        trailOutline.MaxLength = 27
        trailOutline.LightEmission = 0
        trailOutline.LightInfluence = 0
        trailOutline.FaceCamera = true
        trailOutline.Enabled = true
        trailOutline.Texture = ""
        trailOutline.Color = ColorSequence.new(Color3.fromRGB(0, 0, 0))
        trailOutline.WidthScale = NumberSequence.new({
            NumberSequenceKeypoint.new(0.00, 7.4),
            NumberSequenceKeypoint.new(0.48, 5.9),
            NumberSequenceKeypoint.new(0.78, 3.8),
            NumberSequenceKeypoint.new(0.95, 1.3),
            NumberSequenceKeypoint.new(1.00, 0.0)
        })
        trailOutline.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0.00, 0.20),
            NumberSequenceKeypoint.new(0.58, 0.48),
            NumberSequenceKeypoint.new(1.00, 1.0)
        })

        trailMain = Instance.new("Trail", trailPart)
        trailMain.Name = "TrailMain"
        trailMain.Attachment0 = att0
        trailMain.Attachment1 = att1
        trailMain.Lifetime = 0.68
        trailMain.MinLength = 0.07
        trailMain.MaxLength = 24
        trailMain.LightEmission = 0.96
        trailMain.LightInfluence = 0
        trailMain.FaceCamera = true
        trailMain.Enabled = true
        trailMain.Texture = ""
        trailMain.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.00, Color3.fromRGB(140, 255, 255)),
            ColorSequenceKeypoint.new(0.25, Color3.fromRGB(50, 255, 240)),
            ColorSequenceKeypoint.new(0.52, Color3.fromRGB(0, 220, 255)),
            ColorSequenceKeypoint.new(0.80, Color3.fromRGB(0, 155, 255)),
            ColorSequenceKeypoint.new(1.00, Color3.fromRGB(30, 95, 210))
        })
        trailMain.WidthScale = NumberSequence.new({
            NumberSequenceKeypoint.new(0.00, 4.4),
            NumberSequenceKeypoint.new(0.35, 3.6),
            NumberSequenceKeypoint.new(0.67, 2.0),
            NumberSequenceKeypoint.new(0.89, 0.65),
            NumberSequenceKeypoint.new(1.00, 0.0)
        })
        trailMain.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0.00, 0.0),
            NumberSequenceKeypoint.new(0.40, 0.06),
            NumberSequenceKeypoint.new(0.72, 0.33),
            NumberSequenceKeypoint.new(1.00, 1.0)
        })
    end

    -- Som
    local eraseSound = Instance.new("Sound", workspace)
    eraseSound.SoundId = ASSETS.ERASE_SOUND
    eraseSound.Volume = 2
    eraseSound:Play()
    Debris:AddItem(eraseSound, 3)
    
    cameraShake(0.6, 3)
    
    task.wait(0.2)

    -- =============================================
-- FASE 3: VFX E FLING (RODA EM PARALELO!)
-- =============================================
task.spawn(function()
    
    ativarNoClipTemporario()
    
    local targetChar = targetRoot.Parent
    local originalSizes = {}
    local originalMeshScales = {}

        if targetChar then
            -- Highlight
            local highlight = Instance.new("Highlight")
            highlight.Name = "EraseHighlight"
            highlight.OutlineColor = Color3.fromRGB(0, 0, 0)
            highlight.OutlineTransparency = 1
            highlight.FillColor = Color3.fromRGB(0, 80, 200)
            highlight.FillTransparency = 1
            highlight.Parent = targetChar
            
            TweenService:Create(highlight, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
                { OutlineTransparency = 0.5, FillTransparency = 0.5 }
            ):Play()

            -- Vórtice
            local corePart = Instance.new("Part")
            corePart.Name = "ErasureVortex"
            corePart.Size = Vector3.new(1, 1, 1)
            corePart.Position = targetRoot.Position
            corePart.Anchored = true
            corePart.CanCollide = false
            corePart.Transparency = 1
            corePart.Parent = workspace
            Debris:AddItem(corePart, 3)

            local attachmentVortex = Instance.new("Attachment", corePart)

            local pe_dark = Instance.new("ParticleEmitter", attachmentVortex)
            pe_dark.Texture = "rbxassetid://14317181033"
            pe_dark.Color = ColorSequence.new(Color3.fromRGB(0, 0, 0))
            pe_dark.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 5), NumberSequenceKeypoint.new(1, 0)})
            pe_dark.Lifetime = NumberRange.new(0.5, 0.8)
            pe_dark.Rate = 150
            pe_dark.Speed = NumberRange.new(0, 2)
            pe_dark.SpreadAngle = Vector2.new(180, 180)
            pe_dark.RotSpeed = NumberRange.new(-100, 100)
            pe_dark.Acceleration = Vector3.new(0, 5, 0)
            pe_dark.ZOffset = 1

            local pe_blue = pe_dark:Clone()
            pe_blue.Parent = attachmentVortex
            pe_blue.Color = ColorSequence.new(Color3.fromRGB(0, 150, 255))
            pe_blue.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 0)})
            pe_blue.LightEmission = 1
            pe_blue.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})

            task.delay(0.6, function()
                pe_dark.Enabled = false
                pe_blue.Enabled = false
            end)

            -- Encolhimento
            local tweenInfoErasure = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
            for _, part in ipairs(targetChar:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    originalSizes[part] = part.Size
                    TweenService:Create(part, tweenInfoErasure, { Size = Vector3.new(0.05, 0.05, 0.05), Transparency = 1 }):Play()
                elseif part:IsA("SpecialMesh") then
                    originalMeshScales[part] = part.Scale
                    TweenService:Create(part, tweenInfoErasure, { Scale = Vector3.new(0, 0, 0) }):Play()
                end
            end
            
            task.delay(1.8, function()
                if highlight and highlight.Parent then
                    highlight:Destroy()
                end
            end)
        end

        task.wait(0.5)
        
        -- FLING
        local anchoredParts = {}
        local SYNC_DURATION = 1.5

        task.wait(0.1)
        local insidePos = charRoot.Position
        targetRoot.CFrame = CFrame.new(insidePos)
        targetRoot.Velocity = Vector3.new(0, 0, 0)
        targetRoot.RotVelocity = Vector3.new(0, 0, 0)

        local targetHum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
        if targetHum then
            targetHum.CollisionType = Enum.HumanoidCollisionType.OuterBox
            targetHum.AutoRotate = false
            table.insert(flingNoclipHumans, {
                humanoid = targetHum,
                originalCollisionType = Enum.HumanoidCollisionType.InnerBox,
                originalAutoRotate = true
            })
        end

        if charRoot then
            charRoot.CanCollide = false
            table.insert(anchoredParts, {part = charRoot, originalCanCollide = true})
        end

        if targetChar then
            for _, part in ipairs(targetChar:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide == true then
                    part.CanCollide = false
                    table.insert(anchoredParts, {part = part, originalCanCollide = true})
                end
            end
        end

        if targetChar then
            for _, part in ipairs(targetChar:GetDescendants()) do
                if part:IsA("BasePart") and not part.Anchored then
                    part.Anchored = true
                    table.insert(anchoredParts, {part = part, originalAnchored = false})
                end
            end
        end

        -- Teleporte contínuo
        local teleportConnection
        local TELEPORT_INTERVAL = 0.0000000000000000000000001
        local teleportStartTime = tick()

        teleportConnection = RunService.Heartbeat:Connect(function()
            if not targetRoot or not targetRoot.Parent then
                if teleportConnection then teleportConnection:Disconnect() end
                return
            end
            
            local targetHumCheck = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
            if targetHumCheck and targetHumCheck.Health <= 0 then
                if teleportConnection then teleportConnection:Disconnect() end
                return
            end
            
            if tick() - teleportStartTime > SYNC_DURATION then
                if teleportConnection then teleportConnection:Disconnect() end
                return
            end
            
            local myPos = charRoot.Position
            local offsetX = math.random(-50, 50) / 100
            local offsetY = math.random(-30, 30) / 100
            local offsetZ = math.random(-50, 50) / 100
            
            targetRoot.CFrame = CFrame.new(
                myPos.X + offsetX,
                myPos.Y + offsetY,
                myPos.Z + offsetZ
            )
            targetRoot.Velocity = Vector3.new(0, 0, 0)
            targetRoot.RotVelocity = Vector3.new(0, 0, 0)
        end)

        print("💥 NaN Fling iniciado")
        StartFling(targetRoot)

task.delay(SYNC_DURATION, function()
    print("⏰ Restaurando Fling...")
    
    desativarNoClipTemporario()
    
    if teleportConnection then
                teleportConnection:Disconnect()
                teleportConnection = nil
            end
            
            CleanUpFling()
            
            local targetHumCheck = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
            if targetHumCheck and targetHumCheck.Health > 0 and targetChar then
                local restoreInfo = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                for part, originalSize in pairs(originalSizes) do
                    if part and part.Parent then
                        pcall(function() TweenService:Create(part, restoreInfo, { Size = originalSize, Transparency = 0 }):Play() end)
                    end
                end
                for mesh, originalScale in pairs(originalMeshScales) do
                    if mesh and mesh.Parent then
                        pcall(function() TweenService:Create(mesh, restoreInfo, { Scale = originalScale }):Play() end)
                    end
                end
            end
            
            for _, data in ipairs(anchoredParts) do
                if data.part and data.part.Parent then
                    pcall(function() 
                        if data.originalCanCollide ~= nil then
                            data.part.CanCollide = data.originalCanCollide
                        end
                        if data.originalAnchored ~= nil then
                            data.part.Anchored = data.originalAnchored
                        end
                    end)
                end
            end
            
            local targetHumRestore = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
            if targetHumRestore then
                pcall(function()
                    targetHumRestore.CollisionType = Enum.HumanoidCollisionType.InnerBox
                    targetHumRestore.AutoRotate = true
                end)
            end
        end)
    end) -- Fim do task.spawn do Fling

    -- =============================================
    -- FASE 4: STAND VOLTA IMEDIATAMENTE!
    -- =============================================
    
    -- Espera a animação de erase terminar
    task.wait(animLength / eraseTrack.Speed)
    
    -- Para o erase
    if eraseTrack then eraseTrack:Stop() end
    
    -- Limpa trails
    if trailMain then
        trailMain.Enabled = false
        Debris:AddItem(trailMain, 1)
    end
    if trailOutline then
        trailOutline.Enabled = false
        Debris:AddItem(trailOutline, 1.1)
    end
    if trailPart then
        Debris:AddItem(trailPart, 1.3)
    end
    
    -- 🔊 Som de retorno
    local returnSound = Instance.new("Sound", workspace)
    returnSound.SoundId = "rbxassetid://9114330698"
    returnSound.Volume = 1.2
    returnSound:Play()
    Debris:AddItem(returnSound, 2)
    
    -- 💨 Partículas de retorno
    local returnVFX = Instance.new("Part")
    returnVFX.Name = "ReturnVFX"
    returnVFX.Size = Vector3.new(0.5, 0.5, 0.5)
    returnVFX.Position = sRoot.Position
    returnVFX.Anchored = true
    returnVFX.CanCollide = false
    returnVFX.Transparency = 1
    returnVFX.Parent = workspace
    Debris:AddItem(returnVFX, 2)
    
    local attachReturn = Instance.new("Attachment", returnVFX)
    local peReturn = Instance.new("ParticleEmitter", attachReturn)
    peReturn.Texture = "rbxassetid://14317181033"
    peReturn.Color = ColorSequence.new(Color3.fromRGB(0, 200, 255))
    peReturn.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 4), NumberSequenceKeypoint.new(1, 0)})
    peReturn.Lifetime = NumberRange.new(0.3, 0.6)
    peReturn.Rate = 60
    peReturn.Speed = NumberRange.new(2, 5)
    peReturn.SpreadAngle = Vector2.new(180, 180)
    peReturn.LightEmission = 1
    task.delay(0.5, function() peReturn.Enabled = false end)
    
    -- STAND VOLTA PARA TRÁS DO PLAYER
    local returnTween = TweenService:Create(sRoot, 
        TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), 
        {CFrame = returnCFrame}
    )
    returnTween:Play()
    returnTween.Completed:Wait()
    
    -- Volta ao idle
    idleTrack = playAnim(sHum, ASSETS.STAND_IDLE, 1, true, Enum.AnimationPriority.Idle)
    
    -- ✅ Finaliza (não espera o Fling!)
    lastUsed["Erase"] = tick()
    isAttacking = false
    showCooldownOnButton(eraseBtn, "Erase")
    
    print("✨ Stand já retornou! Fling continua em paralelo...")
end

-- ============================================================
-- EFEITO DE PULSAÇÃO NO BOTÃO STAND
-- ============================================================
local standPulseConnection = nil

local function startStandPulse()
    if standPulseConnection then 
        standPulseConnection:Disconnect() 
    end
    
    standPulseConnection = RunService.Heartbeat:Connect(function()
        if not isStandActive then
            if standPulseConnection then
                standPulseConnection:Disconnect()
                standPulseConnection = nil
            end
            return
        end
        
        local pulse = 1 + math.sin(tick() * 3) * 0.05
        activateBtn.Size = UDim2.fromOffset(95 * pulse, 95 * pulse)
    end)
end

-- ═══════════════════════════════════════════
-- 🌌 SISTEMA VFX DE SPAWN TEMPORAL
-- ═══════════════════════════════════════════

local SPAWN_VFX = {
    DistortionSphere = {
        InitialSize = Vector3.new(35, 35, 35),
        FinalSize = Vector3.new(0.01, 0.01, 0.01),
        Transparency = 0.985,
        Material = Enum.Material.Glass,
        Color = Color3.fromRGB(100, 180, 255),
        Duration = 0.6,
        EasingStyle = Enum.EasingStyle.Exponential,
        EasingDirection = Enum.EasingDirection.In,
    },
}

-- Esfera de distorção com material Glass
local function createDistortionSphere(position)
    local sphere = Instance.new("Part")
    sphere.Name = "TemporalDistortion"
    sphere.Shape = Enum.PartType.Ball
    sphere.Size = SPAWN_VFX.DistortionSphere.InitialSize
    sphere.Position = position
    sphere.Anchored = true
    sphere.CanCollide = false
    sphere.Material = SPAWN_VFX.DistortionSphere.Material
    sphere.Color = SPAWN_VFX.DistortionSphere.Color
    sphere.Transparency = SPAWN_VFX.DistortionSphere.Transparency
    sphere.CastShadow = false
    sphere.Parent = workspace
    
    -- PointLight dentro da esfera para brilho azul
    local pointLight = Instance.new("PointLight")
    pointLight.Brightness = 0
    pointLight.Range = 35
    pointLight.Color = Color3.fromRGB(100, 180, 255)
    pointLight.Parent = sphere
    
    -- SurfaceLight na borda para glow
    local surfaceLight = Instance.new("SurfaceLight")
    surfaceLight.Brightness = 0.2
    surfaceLight.Range = 30
    surfaceLight.Color = Color3.fromRGB(0, 120, 255)
    surfaceLight.Face = Enum.NormalId.Front
    surfaceLight.Parent = sphere
    
    -- Animação de contração
    local tweenInfo = TweenInfo.new(
        SPAWN_VFX.DistortionSphere.Duration,
        SPAWN_VFX.DistortionSphere.EasingStyle,
        SPAWN_VFX.DistortionSphere.EasingDirection
    )
    
    local sphereGoals = {
        Size = SPAWN_VFX.DistortionSphere.FinalSize,
        Transparency = 1
    }
    
    local lightGoals = {
        Brightness = 8
    }
    
    TweenService:Create(sphere, tweenInfo, sphereGoals):Play()
    TweenService:Create(pointLight, tweenInfo, lightGoals):Play()
    
    -- Remove após a animação
    task.delay(SPAWN_VFX.DistortionSphere.Duration + 0.1, function()
        if sphere and sphere.Parent then
            sphere:Destroy()
        end
    end)
end

-- Camera Shake Premium (bem suave e polido)
local function cameraShakePremium(duration, intensity)
    if not hum then return end
    
    local start = tick()
    local connection
    
    connection = RunService.RenderStepped:Connect(function()
        local elapsed = tick() - start
        
        if elapsed < duration then
            -- Fade out suave da intensidade
            local progress = elapsed / duration
            local currentIntensity = intensity * (1 - progress) * (1 - progress)
            
            -- Movimento orgânico usando seno/coseno
            local rx = math.sin(elapsed * 20) * currentIntensity * 0.4
            local ry = math.cos(elapsed * 17) * currentIntensity * 0.3
            local rz = math.sin(elapsed * 23) * currentIntensity * 0.25
            
            hum.CameraOffset = Vector3.new(rx, ry, rz)
        else
            -- Reset suave no final
            hum.CameraOffset = Vector3.new(0, 0, 0)
            connection:Disconnect()
        end
    end)
end

-- Função principal
local function spawnTemporalVFX()
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    local charRoot = character.HumanoidRootPart
    local spawnPosition = charRoot.CFrame * CFrame.new(STAND_OFFSET)
    local spawnPos = spawnPosition.Position
    
    -- 1. Esfera de vidro gigante
    createDistortionSphere(spawnPos)
    
    -- 2. Camera shake premium
    cameraShakePremium(0.6, 2.0)
end

print("✅ VFX de Spawn carregado!")

local firstActivation = true   

-- ==================== CUTSCENE OKUYASU - THE HAND (CORTES SUAVES NO MEIO) ====================
local function playOkuyasuCutscene()
    if not character or not character:FindFirstChild("HumanoidRootPart") or not character:FindFirstChild("Head") then return end
    
    local root = character.HumanoidRootPart
    local head = character.Head
    local camera = workspace.CurrentCamera
    if not camera then return end
    
    isAttacking = true
    
    -- ==================== CONGELA O PLAYER ====================
    if hum then
        hum.WalkSpeed = 0
        hum.JumpPower = 0
        hum.AutoRotate = false
    end
    local animate = character:FindFirstChild("Animate")
    if animate then animate.Disabled = true end
    
    -- ==================== SALVA CÂMERA ====================
    local originalCameraType = camera.CameraType
    local originalCameraSubject = camera.CameraSubject
    camera.CameraType = Enum.CameraType.Scriptable
    
    -- ==================== SOM ====================
    local okuyasuVoice = Instance.new("Sound")
    okuyasuVoice.SoundId = "rbxassetid://5375544504"
    okuyasuVoice.Volume = 2.5
    okuyasuVoice.PlaybackSpeed = 1
    okuyasuVoice.Parent = head
    okuyasuVoice:Play()
    Debris:AddItem(okuyasuVoice, 5)
    
    -- ==================== FUNÇÃO DE CORTE BLACK NO MEIO ====================
    local function createBlackFrame()
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 120, 1, 120)
        frame.Position = UDim2.new(0, -60, 0, -60)
        frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        frame.BackgroundTransparency = 1
        frame.ZIndex = 1500
        frame.Parent = screenGui
        return frame
    end
    
    -- Corte black no meio: fade out 0.1s → (posiciona câmera) → preto 0.04s → fade in 0.1s
    local function smoothBlackCut(newCameraCFrame)
        local frame = createBlackFrame()
        
        -- FADE OUT: Tela escurece em 0.1s
        local fadeOut = TweenService:Create(frame, 
            TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), 
            {BackgroundTransparency = 0})
        fadeOut:Play()
        fadeOut.Completed:Wait()
        
        -- 🔄 POSICIONA A CÂMERA ENQUANTO ESTÁ PRETO (não se vê o corte)
        camera.CFrame = newCameraCFrame
        
        -- Pequena pausa no preto
        task.wait(0.04)
        
        -- FADE IN: Tela clareia em 0.1s
        local fadeIn = TweenService:Create(frame, 
            TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
            {BackgroundTransparency = 1})
        fadeIn:Play()
        fadeIn.Completed:Wait()
        
        frame:Destroy()
    end
    
    -- ═══════════════════════════════════════
    -- FASE 0: FRAME PRETO INICIAL (0.0 - 0.25s)
    -- ═══════════════════════════════════════
    camera.CFrame = CFrame.new(root.Position + Vector3.new(0, 0.5, -6), root.Position + Vector3.new(0, 2, 0))
    
    local black0 = createBlackFrame()
    black0.BackgroundTransparency = 0
    task.wait(0.15)
    local fade0 = TweenService:Create(black0, 
        TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
        {BackgroundTransparency = 1})
    fade0:Play()
    fade0.Completed:Wait()
    black0:Destroy()
    
    -- ═══════════════════════════════════════
    -- FASE 1: BALÃO DE FALA (0.25 - 0.55s)
    -- ═══════════════════════════════════════
    showSpeechBubble("94794505267303", "right", 2.8)
    
    local balloonPos = head.Position + Vector3.new(-1.8, 2.5, 0)
    
    -- Desliza suavemente até o balão
    local tweenToBalloon = TweenService:Create(camera, 
        TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), 
        {CFrame = CFrame.new(balloonPos + Vector3.new(0, 0.3, -3), balloonPos)})
    tweenToBalloon:Play()
    tweenToBalloon.Completed:Wait()
    task.wait(0.1)
    
    -- ═══════════════════════════════════════
    -- FASE 2: CORTE → ROSTO DO PLAYER (0.65 - 1.05s)
    -- ═══════════════════════════════════════
    local facePos = head.Position
    
    -- Câmera vai ficar perto do rosto
    local faceCameraCFrame = CFrame.new(facePos + Vector3.new(0, 0.2, -0.5), facePos + Vector3.new(0, 0.2, 0))
    
    -- Corta com black, posiciona câmera no rosto enquanto está preto
    smoothBlackCut(faceCameraCFrame)
    
    -- 🎬 INICIA ANIMAÇÃO DO PLAYER
    local playerAnim = Instance.new("Animation")
    playerAnim.AnimationId = "rbxassetid://114636753459405"
    local playerTrack = hum:LoadAnimation(playerAnim)
    playerTrack.Looped = false
    playerTrack.Priority = Enum.AnimationPriority.Action
    playerTrack:Play(0.15)
    
    task.wait(0.08)
    
    -- Desliza suavemente do rosto para trás
    local tween_face_out = TweenService:Create(camera, 
        TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), 
        {CFrame = CFrame.new(facePos + Vector3.new(0, 0.3, -2.2), facePos + Vector3.new(0, 0.2, 0))})
    tween_face_out:Play()
    tween_face_out.Completed:Wait()
    
    -- ═══════════════════════════════════════
    -- FASE 3: DESLIZA PARA O TORSO (1.15 - 1.55s)
    -- ═══════════════════════════════════════
    local upperTorso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
    local torsoPos = (upperTorso and upperTorso.Position) or root.Position + Vector3.new(0, 1.5, 0)
    
    local tween_to_torso = TweenService:Create(camera, 
        TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), 
        {CFrame = CFrame.new(torsoPos + Vector3.new(0.5, 0.2, -3), torsoPos)})
    tween_to_torso:Play()
    tween_to_torso.Completed:Wait()
    task.wait(0.05)
    
    -- ═══════════════════════════════════════
    -- FASE 4: CORTE → STAND SPAWN (1.6 - 3.0s)
    -- ═══════════════════════════════════════
    
    -- Prepara o Stand
    if currentStand then
        local sRoot = currentStand:FindFirstChild("HumanoidRootPart")
        if sRoot then
            sRoot.CFrame = root.CFrame * CFrame.new(STAND_OFFSET)
            sRoot.Anchored = true
        end
        for _, p in ipairs(currentStand:GetDescendants()) do
            if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then p.Transparency = 1
            elseif p:IsA("Decal") then p.Transparency = 1 end
        end
    end
    
    local standBasePos = root.CFrame * CFrame.new(STAND_OFFSET)
    
    -- Câmera olhando pra baixo (onde o Stand vai surgir)
    local spawnCameraCFrame = CFrame.new(
        standBasePos.Position + Vector3.new(0, 4.5, 2.5),
        standBasePos.Position + Vector3.new(0, 1.5, 0)
    )
    
    -- Corta com black, posiciona câmera no spawn enquanto está preto
    smoothBlackCut(spawnCameraCFrame)
    
    -- 🎬 SPAWN VFX + ANIMAÇÃO DO STAND
    spawnTemporalVFX()
    
    if currentStand then
        local sHum = currentStand:FindFirstChildOfClass("Humanoid")
        if sHum then
            local standAnim = Instance.new("Animation")
            standAnim.AnimationId = "rbxassetid://106157895353915"
            local standTrack = sHum:LoadAnimation(standAnim)
            standTrack.Looped = false
            standTrack.Priority = Enum.AnimationPriority.Action
            standTrack:Play(0.15)
        end
        
        -- Stand aparece com transparência
        for _, p in ipairs(currentStand:GetDescendants()) do
            if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                TweenService:Create(p, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
                    {Transparency = 0}):Play()
            elseif p:IsA("Decal") then
                TweenService:Create(p, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
                    {Transparency = 0}):Play()
            end
        end
    end
    
    -- Shake durante o spawn
    cameraShakePremium(0.45, 1.5)
    task.wait(0.25)
    
    -- ═══════════════════════════════════════
    -- FASE 5: CÂMERA DESLIZA DA CABEÇA ATÉ OS PÉS DO STAND (3.0 - 3.8s)
    -- ═══════════════════════════════════════
    local standHeadPos = standBasePos.Position + Vector3.new(0, 5, 0)
    local standFeetPos = standBasePos.Position + Vector3.new(0, 0.2, 0)
    
    -- Começa na cabeça
    camera.CFrame = CFrame.new(
        standHeadPos + Vector3.new(0, 0.3, -3.5),
        standHeadPos
    )
    task.wait(0.08)
    
    -- Desliza até os pés
    local revealDuration = 0.7
    local revealStart = tick()
    local revealConnection
    revealConnection = RunService.RenderStepped:Connect(function()
        local elapsed = tick() - revealStart
        local progress = math.clamp(elapsed / revealDuration, 0, 1)
        local easedProgress = progress < 0.5 and 2*progress*progress or -1+(4-2*progress)*progress
        
        local currentY = standHeadPos.Y + (standFeetPos.Y - standHeadPos.Y) * easedProgress
        local currentLookY = currentY
        
        camera.CFrame = CFrame.new(
            Vector3.new(standBasePos.Position.X, currentY + 1.8, standBasePos.Position.Z - 3.5),
            Vector3.new(standBasePos.Position.X, currentLookY, standBasePos.Position.Z)
        )
        
        if progress >= 1 then revealConnection:Disconnect() end
    end)
    task.wait(revealDuration + 0.12)
    
    -- ═══════════════════════════════════════
    -- FASE 6: CORTE → CÂMERA NAS COSTAS (3.85 - 4.5s)
    -- ═══════════════════════════════════════
    
    -- Câmera atrás do player
    local behindCameraCFrame = CFrame.new(
        root.Position + root.CFrame.LookVector * -8 + Vector3.new(0, 4, 0),
        root.Position + Vector3.new(0, 2, 0)
    )
    
    -- Corta com black, posiciona câmera nas costas enquanto está preto
    smoothBlackCut(behindCameraCFrame)
    
    -- Retrai suavemente para a posição normal
    local originalCamPos = root.Position + root.CFrame.LookVector * -10 + Vector3.new(0, 5, 0)
    local finalTween = TweenService:Create(camera, 
        TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), 
        {CFrame = CFrame.new(originalCamPos, root.Position + Vector3.new(0, 3, 0))})
    finalTween:Play()
    finalTween.Completed:Wait()
    
    -- ═══════════════════════════════════════
    -- RESTAURAÇÃO
    -- ═══════════════════════════════════════
    camera.CameraType = originalCameraType
    camera.CameraSubject = originalCameraSubject
    
    -- Para animação do player
    if playerTrack and playerTrack.IsPlaying then
        playerTrack:Stop(0.3)
    end
    
    -- Para animação do Stand e inicia idle
    if currentStand then
        local sHum = currentStand:FindFirstChildOfClass("Humanoid")
        if sHum then
            for _, track in ipairs(sHum:GetPlayingAnimationTracks()) do
                if track.Animation and track.Animation.AnimationId == "rbxassetid://106157895353915" then
                    track:Stop(0.3)
                end
            end
            idleTrack = playAnim(sHum, ASSETS.STAND_IDLE, 1, true, Enum.AnimationPriority.Idle)
        end
    end
    
    if hum then
        hum.WalkSpeed = originalWalkSpeed_anim
        hum.JumpPower = SETTINGS.JumpPower
        hum.AutoRotate = true
    end
    if animate then animate.Disabled = false end
    
    isAttacking = false
    cameraShakePremium(0.15, 0.5)
    print("🎬 Cutscene THE HAND finalizada!")
end

-- ==================== TOGGLE STAND ====================
local function toggleStand()
    if isStandActive then
    -- DESATIVAR
    isStandActive = false
    isAttacking = false
    activateBtn.Text = "Show"
    activateBtn.Size = UDim2.fromOffset(95, 95)

    CleanUpFling()
    
    local randomBubble = ASSETS.DEACTIVATE_BUBBLES[math.random(1, #ASSETS.DEACTIVATE_BUBBLES)]
    showSpeechBubble(randomBubble, "right", 1)
        
        -- Anima o Erase saindo
        spawn(function() animateButtonIn(eraseBtn, 0) end)
        
        local tweenSelfEraseBack = TweenService:Create(selfEraseBtn, 
    TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), 
    {
        Position = UDim2.new(0.6, 0, 0.79, 0),
    }
)
        tweenSelfEraseBack:Play()

        if idleTrack then idleTrack:Stop(0.1) end
        if walkTrack then walkTrack:Stop(0.1) end
        if runTrack then runTrack:Stop(0.1) end  

        if currentStand then
            local root = currentStand:FindFirstChild("HumanoidRootPart")
            if root then
                root.Anchored = false
                TweenService:Create(root, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {
                    CFrame = character.HumanoidRootPart.CFrame
                }):Play()
            end
            for _, p in ipairs(currentStand:GetDescendants()) do
                if p:IsA("BasePart") then
                    TweenService:Create(p, TweenInfo.new(0.4), {Transparency = 1}):Play()
                end
            end
            Debris:AddItem(currentStand, 0.6)
            currentStand = nil
        end
    else
        -- ATIVAR STAND
        isStandActive = true
        startStandPulse()
        activateBtn.Text = "Rest"
        activateBtn.Size = UDim2.fromOffset(95, 95)

        -- Anima o Erase aparecendo
        spawn(function() animateButtonOut(eraseBtn, UDim2.new(0.6, 0, 0.78, 0), 0.12) end)
        
        local tweenSelfEraseSlide = TweenService:Create(selfEraseBtn, 
    TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), 
    {
        Position = UDim2.new(0.7, 0, 0.79, 0),
    }
)
        tweenSelfEraseSlide:Play()

        if firstActivation then
            firstActivation = false
            print("🎬 Primeira ativação - Iniciando cutscene")
            
            task.spawn(function()
                currentStand = getStandModel()
                if not currentStand then return end
                currentStand.Parent = workspace
                
                local sHum = currentStand:FindFirstChildOfClass("Humanoid")
                local sRoot = currentStand:FindFirstChild("HumanoidRootPart")

                if sHum then
                    sHum.PlatformStand = true
                    sHum.AutoRotate = false
                end
                if sRoot then
                    sRoot.Anchored = true
                    sRoot.CFrame = character.HumanoidRootPart.CFrame * CFrame.new(STAND_OFFSET)
                end

                playOkuyasuCutscene()

                task.delay(1.3, function()
                    if currentStand then
                        for _, p in ipairs(currentStand:GetDescendants()) do
                            if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                                TweenService:Create(p, TweenInfo.new(0.6), {Transparency = 0}):Play()
                            elseif p:IsA("Decal") then
                                TweenService:Create(p, TweenInfo.new(0.6), {Transparency = 0}):Play()
                            end
                        end
                        if sHum then
                            idleTrack = playAnim(sHum, ASSETS.STAND_IDLE, 1, true, Enum.AnimationPriority.Idle)
                        end
                    end
                end)
            end)
        else
            -- Ativação normal
            spawnTemporalVFX()
            showSpeechBubble(ASSETS.OI_IMAGE, "right", 1)

            local sound = Instance.new("Sound", workspace)
            sound.SoundId = ASSETS.STAND_ACTIVATE_SFX
            sound.Volume = 1.5
            sound:Play()
            Debris:AddItem(sound, 5)

            task.spawn(function()
                currentStand = getStandModel()
                currentStand.Parent = workspace
                local sHum = currentStand:FindFirstChildOfClass("Humanoid")
                local sRoot = currentStand:FindFirstChild("HumanoidRootPart")

                if sHum then 
                    sHum.PlatformStand = true
                    sHum.AutoRotate = false 
                end
                if sRoot then 
                    sRoot.Anchored = true 
                    sRoot.CFrame = character.HumanoidRootPart.CFrame * CFrame.new(STAND_OFFSET)
                end

                for _, p in ipairs(currentStand:GetDescendants()) do
                    if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                        p.Transparency = 1
                        TweenService:Create(p, TweenInfo.new(0.45), {Transparency = 0}):Play()
                    elseif p:IsA("Decal") then
                        TweenService:Create(p, TweenInfo.new(0.45), {Transparency = 0}):Play()
                    end
                end

                if sHum then
                    idleTrack = playAnim(sHum, ASSETS.STAND_IDLE, 1, true, Enum.AnimationPriority.Idle)
                end
            end)
        end
    end
end

-- ============================================================
-- ANIMAÇÃO DO STAND SEGUINDO (IDLE / WALK / RUN)
-- ============================================================
local lastStandState = "Idle"

-- ✅ Configurações das animações
local STAND_ANIM_SPEEDS = {
    Idle = 1.0,
    Walk = 1.5,   -- Velocidade da animação de walk
    Run = 0.8,    -- Velocidade da animação de run (ajuste conforme necessário)
}

-- ✅ Limiares de velocidade
local WALK_THRESHOLD = 5   -- Acima de 5 studs/s = Walk
local RUN_THRESHOLD = 14   -- Acima de 14 studs/s = Run

RunService.RenderStepped:Connect(function()
    if not isStandActive or not currentStand or isAttacking then return end
    
    local root = character:FindFirstChild("HumanoidRootPart")
    local sRoot = currentStand:FindFirstChild("HumanoidRootPart")
    local sHum = currentStand:FindFirstChildOfClass("Humanoid")
    
    if not root or not sRoot or not sHum then return end
    
    -- Movimento suave do Stand seguindo o player
    local targetPos = root.CFrame * CFrame.new(STAND_OFFSET)
    sRoot.CFrame = sRoot.CFrame:Lerp(targetPos, 0.12)
    
    -- Velocidade horizontal do player
    local velocity = root.Velocity
    local horizSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
    
    -- ═══════════════════════════════════════
    -- LÓGICA DE TRANSIÇÃO DE ANIMAÇÕES
    -- ═══════════════════════════════════════
    
    if horizSpeed >= RUN_THRESHOLD then
        -- 🏃‍♂️ VELOCIDADE ALTA = ANIMAÇÃO DE RUN
        if lastStandState ~= "Run" then
            lastStandState = "Run"
            
            -- Para Idle
            if idleTrack and idleTrack.IsPlaying then 
                idleTrack:Stop(0.15) 
            end
            
            -- Para Walk
            if walkTrack and walkTrack.IsPlaying then 
                walkTrack:Stop(0.1) 
            end
            
            -- Toca Run
            runTrack = playAnim(sHum, ASSETS.STAND_RUN, STAND_ANIM_SPEEDS.Run, true, Enum.AnimationPriority.Movement)
        end
        
        -- ✅ Ajusta a velocidade da animação de run baseado na velocidade do player
        if runTrack and runTrack.IsPlaying then
            local speedMultiplier = math.clamp(horizSpeed / RUN_THRESHOLD, 0.8, 2.0)
            pcall(function()
                runTrack:AdjustSpeed(STAND_ANIM_SPEEDS.Run * speedMultiplier)
            end)
        end
        
    elseif horizSpeed >= WALK_THRESHOLD then
        -- 🚶‍♂️ VELOCIDADE MÉDIA = ANIMAÇÃO DE WALK
        if lastStandState ~= "Walk" then
            lastStandState = "Walk"
            
            -- Para Idle
            if idleTrack and idleTrack.IsPlaying then 
                idleTrack:Stop(0.15) 
            end
            
            -- Para Run
            if runTrack and runTrack.IsPlaying then 
                runTrack:Stop(0.1) 
                runTrack = nil
            end
            
            -- Toca Walk
            walkTrack = playAnim(sHum, ASSETS.STAND_WALK, STAND_ANIM_SPEEDS.Walk, true, Enum.AnimationPriority.Movement)
        end
        
        -- ✅ Ajusta a velocidade da animação de walk baseado na velocidade do player
        if walkTrack and walkTrack.IsPlaying then
            local speedMultiplier = math.clamp(horizSpeed / WALK_THRESHOLD, 0.8, 1.8)
            pcall(function()
                walkTrack:AdjustSpeed(STAND_ANIM_SPEEDS.Walk * speedMultiplier)
            end)
        end
        
    else
        -- 🧍‍♂️ PARADO OU MUITO DEVAGAR = ANIMAÇÃO DE IDLE
        if lastStandState ~= "Idle" then
            lastStandState = "Idle"
            
            -- Para Walk
            if walkTrack and walkTrack.IsPlaying then 
                walkTrack:Stop(0.2) 
            end
            
            -- Para Run
            if runTrack and runTrack.IsPlaying then 
                runTrack:Stop(0.2) 
                runTrack = nil
            end
            
            -- Toca Idle
            idleTrack = playAnim(sHum, ASSETS.STAND_IDLE, STAND_ANIM_SPEEDS.Idle, true, Enum.AnimationPriority.Idle)
        end
    end
end)

-- ============================================================
-- STAND CHANGER GUI (simplificada)
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
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.fromOffset(350, 280)
    mainFrame.Position = UDim2.fromScale(0.5, 0.45)
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = gui
    
    local stroke = Instance.new("UIStroke", mainFrame)
    stroke.Color = Color3.fromRGB(0, 150, 255)
    stroke.Thickness = 4
    
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 16)
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 50)
    title.BackgroundTransparency = 1
    title.Text = "THE HAND CHANGER "
    title.TextColor3 = Color3.fromRGB(100, 180, 255)
    title.Font = Enum.Font.Bangers
    title.TextSize = 24
    title.Parent = mainFrame
    
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(0.85, 0, 0, 25)
    statusLabel.Position = UDim2.new(0.075, 0, 0.22, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = customStandUserId and "⚡ Stand Customizado" or "👤 Stand Padrão"
    statusLabel.TextColor3 = customStandUserId and Color3.fromRGB(100, 180, 255) or Color3.fromRGB(150, 150, 150)
    statusLabel.Font = Enum.Font.SourceSansBold
    statusLabel.TextSize = 14
    statusLabel.Parent = mainFrame
    
    local idBox = Instance.new("TextBox")
    idBox.Size = UDim2.new(0.85, 0, 0, 40)
    idBox.Position = UDim2.new(0.075, 0, 0.35, 0)
    idBox.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    idBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    idBox.PlaceholderText = "User ID..."
    idBox.Text = customStandUserId and tostring(customStandUserId) or ""
    idBox.Font = Enum.Font.SourceSans
    idBox.TextSize = 16
    idBox.Parent = mainFrame
    Instance.new("UICorner", idBox).CornerRadius = UDim.new(0, 10)
    
    local addBtn = Instance.new("TextButton")
    addBtn.Size = UDim2.new(0.4, 0, 0, 45)
    addBtn.Position = UDim2.new(0.075, 0, 0.55, 0)
    addBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    addBtn.Text = "ADD"
    addBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    addBtn.Font = Enum.Font.Bangers
    addBtn.TextSize = 20
    addBtn.Parent = mainFrame
    Instance.new("UICorner", addBtn).CornerRadius = UDim.new(0, 10)
    
    local resetBtn = Instance.new("TextButton")
    resetBtn.Size = UDim2.new(0.4, 0, 0, 45)
    resetBtn.Position = UDim2.new(0.525, 0, 0.55, 0)
    resetBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    resetBtn.Text = "RESET"
    resetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    resetBtn.Font = Enum.Font.Bangers
    resetBtn.TextSize = 20
    resetBtn.Parent = mainFrame
    Instance.new("UICorner", resetBtn).CornerRadius = UDim.new(0, 10)
    
    local saveBtn = Instance.new("TextButton")
    saveBtn.Size = UDim2.new(0.85, 0, 0, 35)
    saveBtn.Position = UDim2.new(0.075, 0, 0.75, 0)
    saveBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 80)
    saveBtn.Text = "💾 SALVAR ID"
    saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    saveBtn.Font = Enum.Font.Bangers
    saveBtn.TextSize = 16
    saveBtn.Parent = mainFrame
    Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 10)
    
    addBtn.MouseButton1Click:Connect(function()
        local input = idBox.Text:match("%d+")
        local inputId = tonumber(input)
        if inputId and inputId > 0 then
            customStandUserId = inputId
            salvarStandId(inputId)
            statusLabel.Text = "⚡ Stand Customizado"
            statusLabel.TextColor3 = Color3.fromRGB(100, 180, 255)
            if isStandActive then
                toggleStand()
                task.wait(0.25)
                toggleStand()
            end
            gui:Destroy()
            standChangerGui = nil
        end
    end)
    
    resetBtn.MouseButton1Click:Connect(function()
        customStandUserId = nil
        deletarArquivoConfig()
        statusLabel.Text = "👤 Stand Padrão"
        statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        if isStandActive then
            toggleStand()
            task.wait(0.3)
            toggleStand()
        end
        gui:Destroy()
        standChangerGui = nil
    end)
    
    saveBtn.MouseButton1Click:Connect(function()
        salvarStandId(customStandUserId or player.UserId)
        saveBtn.Text = "✅ SALVO!"
        task.delay(1.5, function()
            if saveBtn and saveBtn.Parent then
                saveBtn.Text = "💾 SALVAR ID"
            end
        end)
    end)
    
    standChangerGui = gui
end

-- ============================================================
-- ANIMAÇÃO DE CLIQUE NOS BOTÕES
-- ============================================================
local function animateClick(button)
    -- Efeito de pressionar (scale down rápido)
    local pressDown = TweenService:Create(button, 
        TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.In), 
        {
            Size = UDim2.fromOffset(button.Size.X.Offset * 0.85, button.Size.Y.Offset * 0.85)
        }
    )
    pressDown:Play()
    pressDown.Completed:Wait()
    
    -- Brilho no clique
    local originalColor = button.BackgroundColor3
    TweenService:Create(button, 
        TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
        {BackgroundColor3 = Color3.fromRGB(255, 255, 255)}
    ):Play()
    task.wait(0.05)
    TweenService:Create(button, 
        TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
        {BackgroundColor3 = originalColor}
    ):Play()
    
    -- Efeito de soltar (scale up com bounce)
    local releaseUp = TweenService:Create(button, 
        TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), 
        {
            Size = UDim2.fromOffset(button.Size.X.Offset / 0.85, button.Size.Y.Offset / 0.85)
        }
    )
    releaseUp:Play()
end

-- ============================================================
-- CONEXÕES
-- ============================================================

activateBtn.MouseButton1Click:Connect(function()
    if buttonDebounce then return end
    buttonDebounce = true
    animateClick(activateBtn)  
    toggleStand()
    task.wait(0.3)
    buttonDebounce = false
end)

eraseBtn.MouseButton1Click:Connect(function()
    if buttonDebounce then return end
    buttonDebounce = true
    animateClick(eraseBtn)  
    performErase()
    task.wait(0.3)
    buttonDebounce = false
end)

selfEraseBtn.MouseButton1Click:Connect(function()
    if buttonDebounce then return end
    buttonDebounce = true
    animateClick(selfEraseBtn)  
    performSelfErase()
    task.wait(0.3)
    buttonDebounce = false
end)

player.Chatted:Connect(function(message)
    if message:lower() == "-changer" then
        if standChangerGui and standChangerGui.Parent then
            standChangerGui:Destroy()
            standChangerGui = nil
        end
        createStandChangerGui()
    end
end)

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    hum = newChar:WaitForChild("Humanoid")
    CleanUpFling()
    
    -- Se o Stand estava ativo, mantém ativo com o novo corpo
    if isStandActive and currentStand then
        task.wait(0.3)
        
        local charRoot = character:FindFirstChild("HumanoidRootPart")
        local sRoot = currentStand:FindFirstChild("HumanoidRootPart")
        local sHum = currentStand:FindFirstChildOfClass("Humanoid")
        
        if charRoot and sRoot and sHum then
            sRoot.Anchored = true
            sRoot.CFrame = charRoot.CFrame * CFrame.new(STAND_OFFSET)
            
            if idleTrack then pcall(function() idleTrack:Stop() end) end
            idleTrack = playAnim(sHum, ASSETS.STAND_IDLE, 1, true, Enum.AnimationPriority.Idle)
            
            for _, p in ipairs(currentStand:GetDescendants()) do
                if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                    p.Transparency = 0
                elseif p:IsA("Decal") then
                    p.Transparency = 0
                end
            end
            
            print("🔄 Stand reconectado ao novo personagem!")
        end
    end
end)

-- ============================================================
-- NOTIFICAÇÃO DE BOAS-VINDAS
-- ============================================================
local notifFrame = Instance.new("Frame")
notifFrame.Size = UDim2.fromOffset(380, 180)
notifFrame.Position = UDim2.fromScale(0.5, 0.5)
notifFrame.AnchorPoint = Vector2.new(0.5, 0.5)
notifFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
notifFrame.BorderSizePixel = 0
notifFrame.ZIndex = 201
notifFrame.Parent = screenGui
notifFrame.Active = false  
notifFrame.ZIndex = 200

local border = Instance.new("UIStroke", notifFrame)
border.Color = Color3.fromRGB(0, 150, 255)
border.Thickness = 3

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0.85, 0, 0, 30)
titleLabel.Position = UDim2.new(0.075, 0, 0, 20)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "THE HAND - Okuyasu Nijimura "
titleLabel.TextColor3 = Color3.fromRGB(100, 180, 255)
titleLabel.Font = Enum.Font.Bangers
titleLabel.TextSize = 18
titleLabel.TextStrokeTransparency = 0
titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
titleLabel.ZIndex = 202
titleLabel.Parent = notifFrame

local messageLabel = Instance.new("TextLabel")
messageLabel.Size = UDim2.new(0.85, 0, 0, 100)
messageLabel.Position = UDim2.new(0.075, 0, 0, 65)
messageLabel.BackgroundTransparency = 1
messageLabel.Text = "Incompleto sem ideias\n\nComando: -changer para trocar o Stand"
messageLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
messageLabel.Font = Enum.Font.SourceSans
messageLabel.TextSize = 13
messageLabel.TextWrapped = true
messageLabel.ZIndex = 202
messageLabel.Parent = notifFrame

notifFrame.Size = UDim2.fromOffset(450, 0.01)
TweenService:Create(notifFrame, TweenInfo.new(0.6, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
    Size = UDim2.fromOffset(380, 180)
}):Play()

task.delay(2, function()
    if notifFrame and notifFrame.Parent then
        TweenService:Create(notifFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Size = UDim2.fromOffset(500, 0.01),
            BackgroundTransparency = 0.5
        }):Play()
        task.delay(0.5, function()
            if notifFrame and notifFrame.Parent then
                notifFrame:Destroy()
            end
        end)
    end
end)

-- ═══════════════════════════════════════════
-- 🎒 SISTEMA DE ACESSÓRIOS (ANTI-CLONE)
-- ═══════════════════════════════════════════

local ACCESSORY_TAG = "TheHandAccessory"

local IDS_CATALOGO = {
    14790235358, 70875299727788, 94509636088732,
}

local function AnexarTudo()
    local character = player.Character or player.CharacterAdded:Wait()
    
    -- Limpa os itens antigos que o script colocou
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
                
                -- Limpa scripts maliciosos do asset
                for _, v in pairs(asset:GetDescendants()) do
                    if v:IsA("LuaSourceContainer") then v:Destroy() end
                end

                asset:SetAttribute(ACCESSORY_TAG, true)

                -- 👕 SE FOR ROUPA (Shirt, Pants, T-Shirt)
                if asset:IsA("Shirt") or asset:IsA("Pants") or asset:IsA("ShirtGraphic") then
                    -- Remove a roupa padrão do personagem para a nova aparecer
                    for _, oldCloth in ipairs(character:GetChildren()) do
                        if oldCloth.ClassName == asset.ClassName then
                            oldCloth:Destroy()
                        end
                    end
                    -- Aplica a roupa nova no personagem
                    asset.Parent = character

                -- 🎒 SE FOR ACESSÓRIO (Chapéus, espadas, etc)
                else
                    local handle = asset:IsA("BasePart") and asset or asset:FindFirstChild("Handle", true)

                    if handle then
                        handle.CanCollide = false
                        handle.Massless = true
                        
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

local function fullCleanup(preserveStand)
    warn("🧹 Executando limpeza...")
    
    desativarNoClipTemporario()
    
    CleanUpFling()
    
    cleanupCustomAnims()
    
    -- ⚠️ SÓ DESTRÓI O STAND SE NÃO FOR PRA PRESERVAR
    if not preserveStand then
        -- Destrói Stand ativo
        if currentStand then
            pcall(function()
                if currentStand.Parent then
                    for _, child in ipairs(currentStand:GetDescendants()) do
                        if child:IsA("Trail") then
                            child.Enabled = false
                        end
                    end
                    currentStand:Destroy()
                end
            end)
            currentStand = nil
        end
        
        -- Reseta variáveis de animação
        if idleTrack then pcall(function() idleTrack:Stop() end) idleTrack = nil end
        if walkTrack then pcall(function() walkTrack:Stop() end) walkTrack = nil end
        if runTrack then pcall(function() runTrack:Stop() end) runTrack = nil end

        if FlingTargetRoot then FlingTargetRoot = nil end
        
        -- RESETA O ESTADO DO STAND E BOTÕES
        isStandActive = false
        isAttacking = false
        
        -- Reseta o botão principal para "STAND"
        if activateBtn and activateBtn.Parent then
            activateBtn.Text = "STAND"
            activateBtn.Size = UDim2.fromOffset(95, 95)
        end
        
        -- Para o pulso do botão
        if standPulseConnection then
            standPulseConnection:Disconnect()
            standPulseConnection = nil
        end
        
        -- Esconde o botão de ERASE
        if eraseBtn and eraseBtn.Parent then
            pcall(function()
                eraseBtn.Visible = false
                eraseBtn.Size = UDim2.fromOffset(0, 0)
                eraseBtn.BackgroundTransparency = 1
            end)
        end
    end
    
    -- Limpa sons (sempre)
    for _, sound in ipairs(workspace:GetDescendants()) do
        if sound:IsA("Sound") and (sound.SoundId:find("9114330698") or sound.SoundId:find("140225325762905")) then
            pcall(function() sound:Destroy() end)
        end
    end
    
    -- Limpa partes fantasmas (sempre)
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:GetAttribute("TheHand_FlingPart") or obj.Name == "SimFloor_Fling" then
            pcall(function() obj:Destroy() end)
        end
    end
    
    print("✅ Limpeza concluída - Stand " .. (preserveStand and "preservado" or "resetado"))
end

-- Quando morrer, preserva o Stand
player.CharacterRemoving:Connect(function()
    fullCleanup(true)
end)

-- Limpa tudo quando sair do jogo
player.Destroying:Connect(function()
    fullCleanup(false)
end)

if character then
    local currentChar = character
    currentChar.Destroying:Connect(function()
        fullCleanup(true)
    end)
end
