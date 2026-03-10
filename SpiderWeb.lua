--// ================================================
--// SISTEMA HOMEM-ARANHA - VERSÃO FINAL (HOLD PUXAR + IMPULSO 100% CORRIGIDO)
--// Correção EXATA do que você pediu no Modo Impulso:
--// • Teia agora gruda DE VERDADE nas paredes (attachment local na parte)
--// • Quando mira em PLAYER: teia gruda no player → você voa direto nele, colide e PARA em cima dele (exatamente como queria)
--// ================================================

--// CONFIGURAÇÕES
local CONFIG = {
    TEIA_DISTANCIA_MAX = 150,
    TEIA_VELOCIDADE = 250,
    TEIA_TWEEN_TIME = 0.05,
    
    -- MODO PUXAR HOLD
    HEAVY_MASS_THRESHOLD = 35,
    PULL_FORCE = 85,
    PULL_FORCE_HEAVY = 150,
    
    -- BALANÇO
    SWING_FORCA = 60,
    SWING_ALTURA = 40,
    
    -- IMPULSO
    IMPULSO_FORCA = 300,
    
    -- WALL-RUN
    WALL_RUN_VELOCIDADE = 50,
    WALL_RUN_ALTURA = 25,
    
    -- SPIDEY-SENSE
    SPIDEY_SENSE_DISTANCIA = 30,
    SPIDEY_SENSE_DURACAO = 3,
    
    -- CONTROLES
    TECLA_TEIA = Enum.KeyCode.E,
    TECLA_MODO = Enum.KeyCode.R,
    TECLA_WALL = Enum.KeyCode.F,
    TECLA_SENSE = Enum.KeyCode.T,
    
    CORES = {
        VERMELHO = Color3.fromRGB(196, 0, 0),
        AZUL = Color3.fromRGB(15, 40, 140),
        BRANCO = Color3.fromRGB(255, 255, 255),
        TEIA = Color3.fromRGB(220, 220, 255),
        SENSE = Color3.fromRGB(255, 200, 0)
    },
    
    MODES = {
        {id = 1, name = "PUXAR", icon = "🕸️"},
        {id = 2, name = "BALANÇO", icon = "🌆"},
        {id = 3, name = "IMPULSO", icon = "💨"}
    },
    
    SOM_PUXAR = "rbxassetid://107364109050462",
    SOM_IMPULSO = "rbxassetid://107364109050462",
    SOM_BALANCO = "rbxassetid://9084017080",
    
    TEXTURA_TEIA = "rbxassetid://104502286237890",
    
    UI_GLOW_COR = Color3.fromRGB(255, 50, 50),
    UI_GRADIENT = {
        Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(196, 0, 0)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 40, 140))
        }
    }
}

--// SERVIÇOS
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local camera = workspace.CurrentCamera

--// VARIÁVEIS
local currentMode = 1
local teiaAtiva = false
local teiaSegurando = false
local activeSwing = nil
local activeTeias = {}
local wallRunning = false
local wallConn = nil
local spideyActive = false
local spideyEnd = 0
local originalC0 = {}
local pullConn = nil
local spiderGui = nil
local UI = {}

local activeImpulseAlign = nil
local activeImpulseAtt0 = nil
local soundPuxar = nil
local soundImpulso = nil
local soundBalanco = nil
local handSideCycle = "Right"

--// FUNÇÕES UTILITÁRIAS
local function getHand(side)
    if not character then return nil end
    return side == "Right" and 
        (character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")) or
        (character:FindFirstChild("LeftHand") or character:FindFirstChild("Left Arm"))
end

local function getShoulder(side)
    if not character then return nil end
    for _, motor in ipairs(character:GetDescendants()) do
        if motor:IsA("Motor6D") and motor.Name == side .. "Shoulder" then
            return motor
        end
    end
    return nil
end

local function aimArm(side, targetPos)
    local shoulder = getShoulder(side)
    if not shoulder then return end
    if not originalC0[side] then originalC0[side] = shoulder.C0 end
    
    local shoulderPos = shoulder.Part0.CFrame * shoulder.C0.p
    local dir = (targetPos - shoulderPos).Unit
    local targetCF = CFrame.lookAt(shoulderPos, shoulderPos + dir)
    local relativeRot = shoulder.Part0.CFrame:ToObjectSpace(targetCF)
    
    TweenService:Create(shoulder, TweenInfo.new(0.08), {
        C0 = CFrame.new(originalC0[side].p) * relativeRot.Rotation
    }):Play()
end

local function resetArm(side)
    local shoulder = getShoulder(side)
    if shoulder and originalC0[side] then
        TweenService:Create(shoulder, TweenInfo.new(0.3), {
            C0 = originalC0[side]
        }):Play()
    end
end

--// EFEITOS
local function criarImpacto(pos)
    for i = 1, 8 do
        local p = Instance.new("Part")
        p.Shape = Enum.PartType.Ball
        p.Size = Vector3.new(0.2, 0.2, 0.2)
        p.Position = pos
        p.Anchored = true
        p.CanCollide = false
        p.Material = Enum.Material.Neon
        p.Color = CONFIG.CORES.TEIA
        p.Parent = workspace.Terrain
        
        local dir = Vector3.new(math.random(-1,1), math.random(-1,1), math.random(-1,1)).Unit
        TweenService:Create(p, TweenInfo.new(0.3), {
            Position = pos + dir * math.random(3, 8),
            Transparency = 1,
            Size = Vector3.new(0,0,0)
        }):Play()
        Debris:AddItem(p, 0.3)
    end
end

--// SISTEMA DE TEIA (AGORA GRUDA SEMPRE NA PARTE HITADA)
local function criarTeia(hand, posicao, alvo)
    local att0 = Instance.new("Attachment")
    att0.Parent = hand
    att0.Position = Vector3.new(0, -0.5, 0)
    
    local att1 = Instance.new("Attachment")
    
    if alvo then
        att1.Parent = alvo
        att1.Position = alvo.CFrame:PointToObjectSpace(posicao)
    else
        att1.Parent = workspace.Terrain
        att1.WorldPosition = posicao
    end
    
    local beam = Instance.new("Beam")
    beam.Attachment0 = att0
    beam.Attachment1 = att1
    beam.Color = ColorSequence.new(CONFIG.CORES.TEIA)
    beam.Width0 = 0.18
    beam.Width1 = 0.12
    beam.LightEmission = 1
    beam.LightInfluence = 0.5
    beam.Texture = CONFIG.TEXTURA_TEIA
    beam.TextureLength = 4
    beam.TextureSpeed = 6
    beam.Transparency = NumberSequence.new(0.05)
    beam.Parent = workspace.Terrain
    
    beam.Width0 = 0
    TweenService:Create(beam, TweenInfo.new(0.06), {Width0 = 0.18}):Play()
    
    criarImpacto(posicao)
    return {beam = beam, att0 = att0, att1 = att1}
end

function limparTeias()
    for _, t in ipairs(activeTeias) do
        if t.beam then t.beam:Destroy() end
        if t.att0 then t.att0:Destroy() end
        if t.att1 then t.att1:Destroy() end
    end
    activeTeias = {}
    
    if activeSwing then
        if activeSwing.rope then activeSwing.rope:Destroy() end
        if activeSwing.attPlayer then activeSwing.attPlayer:Destroy() end
        if activeSwing.attTarget then activeSwing.attTarget:Destroy() end
        if activeSwing.anchor then activeSwing.anchor:Destroy() end
        activeSwing = nil
    end
    
    if pullConn then
        pullConn:Disconnect()
        pullConn = nil
    end
    
    if activeImpulseAlign then
        activeImpulseAlign:Destroy()
        activeImpulseAlign = nil
    end
    if activeImpulseAtt0 then
        activeImpulseAtt0:Destroy()
        activeImpulseAtt0 = nil
    end
    
    teiaAtiva = false
    teiaSegurando = false
    
    resetArm("Right")
    resetArm("Left")
end

--// MODO PUXAR (HOLD INFINITO)
local function modoPuxar(posicao, alvo, hand)
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local mass = (alvo and alvo.AssemblyMass) or 10
    local isHeavy = (alvo and not alvo.Anchored and mass > CONFIG.HEAVY_MASS_THRESHOLD)
    
    local teiaPrimary = criarTeia(hand, posicao, alvo)
    table.insert(activeTeias, teiaPrimary)
    
    if isHeavy then
        local otherHand = (hand == getHand("Right") and getHand("Left") or getHand("Right"))
        if otherHand then
            local teiaOther = criarTeia(otherHand, posicao, alvo)
            table.insert(activeTeias, teiaOther)
        end
    end
    
    if alvo and not alvo.Anchored then
        local force = isHeavy and CONFIG.PULL_FORCE_HEAVY or CONFIG.PULL_FORCE
        pullConn = RunService.Heartbeat:Connect(function()
            if not alvo or not alvo.Parent then limparTeias() return end
            local dir = (root.Position - alvo.Position).Unit
            local dist = (root.Position - alvo.Position).Magnitude
            if dist < 8 then limparTeias() return end
            alvo.AssemblyLinearVelocity = dir * force
        end)
    end
end

--// MODO BALANÇO (HOLD + MINI IMPULSO)
local function modoBalanco(posicao, alvo, hand)
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local anchor = Instance.new("Part")
    anchor.Anchored = true
    anchor.CanCollide = false
    anchor.Transparency = 1
    anchor.Size = Vector3.new(1, 1, 1)
    anchor.Position = posicao
    anchor.Parent = workspace.Terrain
    
    local teia = criarTeia(hand, posicao, anchor)
    table.insert(activeTeias, teia)
    
    local attPlayer = Instance.new("Attachment")
    attPlayer.Parent = root
    attPlayer.Position = Vector3.new(0, 0, 0)
    
    local attTarget = Instance.new("Attachment")
    attTarget.Parent = anchor
    attTarget.WorldPosition = posicao
    
    local rope = Instance.new("RopeConstraint")
    rope.Attachment0 = attPlayer
    rope.Attachment1 = attTarget
    rope.Length = (root.Position - posicao).Magnitude * 0.9
    rope.Restitution = 0.3
    rope.Visible = false
    rope.Parent = root
    
    activeSwing = {rope = rope, attPlayer = attPlayer, attTarget = attTarget, anchor = anchor}
    teiaSegurando = true
    
    local dir = (posicao - root.Position).Unit
    root.AssemblyLinearVelocity = dir * CONFIG.SWING_FORCA + Vector3.new(0, CONFIG.SWING_ALTURA, 0)
    
    -- MINI IMPULSO AO JOGAR A TEIA
    root.AssemblyLinearVelocity = root.AssemblyLinearVelocity + dir * 35 + Vector3.new(0, 20, 0)
    
    task.spawn(function()
        while activeSwing and activeSwing.rope do
            local currentDist = (root.Position - posicao).Magnitude
            if currentDist > activeSwing.rope.Length then
                activeSwing.rope.Length = math.min(100, activeSwing.rope.Length + 0.5)
            end
            task.wait(0.1)
        end
    end)
end

--// MODO IMPULSO (AGORA GRUDA DE VERDADE E PARA EM CIMA DO PLAYER)
local function modoImpulso(posicao, hitPart)
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local handRight = getHand("Right")
    local handLeft = getHand("Left")
    
    aimArm("Right", posicao)
    aimArm("Left", posicao)
    
    local teia1 = criarTeia(handRight, posicao, hitPart)
    local teia2 = criarTeia(handLeft, posicao, hitPart)
    
    table.insert(activeTeias, teia1)
    table.insert(activeTeias, teia2)
    
    local dir = (posicao - root.Position).Unit
    root.AssemblyLinearVelocity = dir * CONFIG.IMPULSO_FORCA + Vector3.new(0, 50, 0)
    
    if hitPart and hitPart.Parent then
        local targetHum = hitPart.Parent:FindFirstChildOfClass("Humanoid")
        if targetHum and targetHum ~= humanoid then
            activeImpulseAtt0 = Instance.new("Attachment")
            activeImpulseAtt0.Parent = root
            activeImpulseAtt0.Position = Vector3.new(0, 1.5, 0)
            
            activeImpulseAlign = Instance.new("AlignPosition")
            activeImpulseAlign.Attachment0 = activeImpulseAtt0
            activeImpulseAlign.Attachment1 = teia1.att1
            activeImpulseAlign.MaxForce = 100000
            activeImpulseAlign.Responsiveness = 28
            activeImpulseAlign.Parent = root
        end
    end
    
    local originalFOV = camera.FieldOfView
    camera.FieldOfView = originalFOV + 20
    TweenService:Create(camera, TweenInfo.new(0.5), {FieldOfView = originalFOV}):Play()
    
    task.delay(0.45, limparTeias)
end

--// FUNÇÃO PRINCIPAL DE TEIA
function atirarTeia()
    if teiaAtiva then return end
    teiaAtiva = true
    
    local ray = camera:ViewportPointToRay(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {character}
    params.FilterType = Enum.RaycastFilterType.Blacklist
    
    local result = workspace:Raycast(ray.Origin, ray.Direction * CONFIG.TEIA_DISTANCIA_MAX, params)
    local hitPos = result and result.Position or (ray.Origin + ray.Direction * 20)
    local hitPart = result and result.Instance
    
    local handSide = handSideCycle
    local hand = getHand(handSide)
    
    if currentMode == 1 and soundPuxar then
        soundPuxar:Play()
    elseif currentMode == 2 and soundBalanco then
        soundBalanco:Play()
    elseif currentMode == 3 and soundImpulso then
        soundImpulso:Play()
    end
    
    if currentMode == 1 then
        if not hitPart then teiaAtiva = false return end
        aimArm(handSide, hitPos)
        modoPuxar(hitPos, hitPart, hand)
        
    elseif currentMode == 2 then
        local inAir = humanoid:GetState() == Enum.HumanoidStateType.Freefall or
                      humanoid:GetState() == Enum.HumanoidStateType.Jumping
        
        if inAir and hitPart then
            aimArm(handSide, hitPos)
            modoBalanco(hitPos, hitPart, hand)
        else
            aimArm(handSide, hitPos)
            local tempTeia = criarTeia(hand, hitPos, nil)
            table.insert(activeTeias, tempTeia)
            task.delay(0.3, limparTeias)
        end
        
    elseif currentMode == 3 then
        modoImpulso(hitPos, hitPart)
    end
    
    -- ALTERNAR BRAÇO APÓS CADA TIRO
    handSideCycle = (handSideCycle == "Right" and "Left" or "Right")
end

--// WALL-RUN, SPIDEY-SENSE, UI e INPUTS
local function wallRunUpdate()
    if not wallRunning or not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {character}
    
    local wallRay = workspace:Raycast(root.Position, root.CFrame.LookVector * 3, params)
    local floorRay = workspace:Raycast(root.Position, Vector3.new(0, -5, 0), params)
    
    if wallRay and (not floorRay or floorRay.Distance > 3) then
        local normal = wallRay.Normal
        if math.abs(normal.Y) < 0.7 then
            humanoid.PlatformStand = true
            local upForce = Vector3.new(0, CONFIG.WALL_RUN_ALTURA, 0)
            local forwardForce = root.CFrame.LookVector * CONFIG.WALL_RUN_VELOCIDADE
            root.AssemblyLinearVelocity = upForce + forwardForce * 0.3
            
            local lookDir = -normal
            root.CFrame = CFrame.new(root.Position, root.Position + lookDir) * CFrame.Angles(0, math.pi, 0)
            return
        end
    end
    humanoid.PlatformStand = false
end

function toggleWallRun()
    wallRunning = not wallRunning
    if wallConn then wallConn:Disconnect() wallConn = nil end
    if wallRunning then
        wallConn = RunService.Heartbeat:Connect(wallRunUpdate)
        if UI.wallBtn then UI.wallBtn.BackgroundColor3 = CONFIG.CORES.VERMELHO end
    else
        humanoid.PlatformStand = false
        if UI.wallBtn then UI.wallBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30) end
    end
end

local function spideyMonitor()
    if not spideyActive or tick() > spideyEnd then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            local enemyRoot = plr.Character:FindFirstChild("HumanoidRootPart")
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if enemyRoot and hum then
                local dist = (enemyRoot.Position - root.Position).Magnitude
                if dist <= CONFIG.SPIDEY_SENSE_DISTANCIA then
                    local vel = enemyRoot.AssemblyLinearVelocity.Magnitude
                    if vel > 15 then
                        executarContraAtaque(plr.Character, enemyRoot)
                        break
                    end
                end
            end
        end
    end
end

function executarContraAtaque(inimigo, enemyRoot)
    if not spideyActive then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    criarImpacto(root.Position)
    local pullDir = (root.Position - enemyRoot.Position).Unit
    enemyRoot.AssemblyLinearVelocity = pullDir * 100 + Vector3.new(0, 30, 0)
    task.delay(0.15, function()
        if not enemyRoot.Parent then return end
        if (enemyRoot.Position - root.Position).Magnitude < 10 then
            humanoid.PlatformStand = true
            local jumpDir = (root.CFrame.LookVector * -1) + Vector3.new(0, 2, 0)
            root.AssemblyLinearVelocity = jumpDir.Unit * 80 + Vector3.new(0, 60, 0)
            for i = 1, 15 do
                if not root.Parent then break end
                root.CFrame = root.CFrame * CFrame.Angles(math.pi/7.5, 0, 0)
                task.wait(0.02)
            end
            task.delay(0.2, function()
                if root and root.Parent then
                    root.CFrame = CFrame.new(root.Position, enemyRoot.Position)
                    local human = inimigo:FindFirstChildOfClass("Humanoid")
                    if human then human:TakeDamage(30) end
                    enemyRoot.AssemblyLinearVelocity = enemyRoot.CFrame.LookVector * 50
                    criarImpacto(enemyRoot.Position)
                end
                humanoid.PlatformStand = false
            end)
        end
    end)
end

function ativarSpideySense()
    if tick() < spideyEnd + 8 then print("Spidey-Sense em cooldown!") return end
    spideyActive = true
    spideyEnd = tick() + CONFIG.SPIDEY_SENSE_DURACAO
    print("🕷️ SPIDEY-SENSE ATIVADO!")
    local root = character:FindFirstChild("HumanoidRootPart")
    if root then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player and plr.Character then
                local enemyRoot = plr.Character:FindFirstChild("HumanoidRootPart")
                if enemyRoot then
                    local dist = (enemyRoot.Position - root.Position).Magnitude
                    if dist <= CONFIG.SPIDEY_SENSE_DISTANCIA then
                        local bg = Instance.new("BillboardGui")
                        bg.Size = UDim2.new(0, 40, 0, 40) bg.AlwaysOnTop = true bg.Parent = enemyRoot
                        local img = Instance.new("Frame")
                        img.Size = UDim2.new(1,0,1,0) img.BackgroundColor3 = CONFIG.CORES.SENSE img.BorderSizePixel = 0 img.Parent = bg
                        Instance.new("UICorner", img).CornerRadius = UDim.new(1,0)
                        task.delay(CONFIG.SPIDEY_SENSE_DURACAO, function() bg:Destroy() end)
                    end
                end
            end
        end
    end
    task.spawn(function()
        while spideyActive and tick() <= spideyEnd do
            spideyMonitor()
            task.wait(0.15)
        end
        spideyActive = false
        print("🕷️ Spidey-Sense desativado")
    end)
end

local function criarUI()
    if spiderGui and spiderGui.Parent then spiderGui:Destroy() end
    local playerGui = player:WaitForChild("PlayerGui")
    local gui = Instance.new("ScreenGui")
    gui.Name = "SpiderSystemPro"
    gui.ResetOnSpawn = false
    gui.Parent = playerGui
    spiderGui = gui

    -- HUD MAIOR E CENTRALIZADO
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 340, 0, 180)
    mainFrame.Position = UDim2.new(1, -370, 1, -200)
    mainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    mainFrame.BackgroundTransparency = 0.25
    mainFrame.Parent = gui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 20)
    corner.Parent = mainFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 4
    stroke.Color = CONFIG.UI_GLOW_COR
    stroke.Transparency = 0.3
    stroke.Parent = mainFrame
    
    local gradient = Instance.new("UIGradient")
    gradient.Color = CONFIG.UI_GRADIENT.Color
    gradient.Rotation = 45
    gradient.Parent = mainFrame

    local webBg = Instance.new("ImageLabel")
    webBg.Size = UDim2.new(1, 0, 1, 0)
    webBg.BackgroundTransparency = 1
    webBg.Image = "rbxassetid://110747957343964"
    webBg.ImageTransparency = 0.85
    webBg.ScaleType = Enum.ScaleType.Tile
    webBg.TileSize = UDim2.new(0, 80, 0, 80)
    webBg.Parent = mainFrame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -90, 0, 35)
    title.Position = UDim2.new(0, 20, 0, 8)
    title.BackgroundTransparency = 1
    title.Text = "SPIDER-MAN"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextStrokeTransparency = 0
    title.TextStrokeColor3 = CONFIG.CORES.VERMELHO
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 24
    title.Parent = mainFrame

    -- BOTÃO PRINCIPAL MAIOR
    local mainBtn = Instance.new("TextButton")
    mainBtn.Size = UDim2.new(0, 115, 0, 115)
    mainBtn.Position = UDim2.new(0, 25, 0, 45)
    mainBtn.BackgroundColor3 = Color3.fromRGB(196, 0, 0)
    mainBtn.Text = "🕸️"
    mainBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    mainBtn.TextSize = 55
    mainBtn.Font = Enum.Font.GothamBold
    mainBtn.Parent = mainFrame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(1, 0)
    btnCorner.Parent = mainBtn
    
    local btnStroke = Instance.new("UIStroke")
    btnStroke.Thickness = 6
    btnStroke.Color = Color3.fromRGB(255, 200, 0)
    btnStroke.Parent = mainBtn

    -- LABEL DO MODO
    local modeLabel = Instance.new("TextLabel")
    modeLabel.Size = UDim2.new(0, 160, 0, 45)
    modeLabel.Position = UDim2.new(0, 160, 0, 55)
    modeLabel.BackgroundTransparency = 1
    modeLabel.Text = CONFIG.MODES[currentMode].icon .. " " .. CONFIG.MODES[currentMode].name
    modeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    modeLabel.TextStrokeTransparency = 0.6
    modeLabel.Font = Enum.Font.GothamBold
    modeLabel.TextSize = 20
    modeLabel.TextXAlignment = Enum.TextXAlignment.Left
    modeLabel.Parent = mainFrame
    UI.modeLabel = modeLabel

    -- BOTÕES LATERAIS (AGORA DENTRO DO HUD)
    local function criarBtnLateral(texto, posX, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 48, 0, 48)
        btn.Position = UDim2.new(0, posX, 0, 118)
        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        btn.Text = texto
        btn.TextColor3 = CONFIG.CORES.BRANCO
        btn.TextSize = 24
        btn.Font = Enum.Font.GothamBold
        btn.Parent = mainFrame
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)
        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    local modeBtn = criarBtnLateral("🔄", 165, function()
        currentMode = currentMode % 3 + 1
        if UI.modeLabel then UI.modeLabel.Text = CONFIG.MODES[currentMode].icon .. " " .. CONFIG.MODES[currentMode].name end
    end)

    local wallBtn = criarBtnLateral("🧗", 220, toggleWallRun)
    local senseBtn = criarBtnLateral("🕷️", 275, ativarSpideySense)

    -- BOTÃO DE DRAG (TOPO DIREITA)
    local isDraggable = false
    local dragging = false
    local dragStart
    local startPos

    local dragToggleBtn = Instance.new("TextButton")
    dragToggleBtn.Size = UDim2.new(0, 48, 0, 28)
    dragToggleBtn.Position = UDim2.new(1, -53, 0, 8)
    dragToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    dragToggleBtn.Text = "🔓"
    dragToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    dragToggleBtn.TextSize = 18
    dragToggleBtn.Font = Enum.Font.GothamBold
    dragToggleBtn.Parent = mainFrame
    Instance.new("UICorner", dragToggleBtn).CornerRadius = UDim.new(0, 8)

    local function updateDragButton()
        if isDraggable then
            dragToggleBtn.Text = "🔒"
            dragToggleBtn.BackgroundColor3 = CONFIG.CORES.VERMELHO
        else
            dragToggleBtn.Text = "🔓"
            dragToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        end
    end

    dragToggleBtn.MouseButton1Click:Connect(function()
        isDraggable = not isDraggable
        updateDragButton()
    end)

    -- LÓGICA DE DRAG (só funciona quando ativado)
    local function onDragStart(input)
        if not isDraggable then return end
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end

    local function onDragMove(input)
        if dragging then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end

    local function onDragEnd()
        dragging = false
    end

    mainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            onDragStart(input)
        end
    end)

    mainFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            onDragMove(input)
        end
    end)

    mainFrame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            onDragEnd()
        end
    end)

    -- CONEXÕES DO BOTÃO PRINCIPAL
    mainBtn.MouseButton1Down:Connect(function()
        atirarTeia()
        mainBtn.Size = UDim2.new(0, 105, 0, 105)
        mainBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    end)
    
    mainBtn.MouseButton1Up:Connect(function()
        if currentMode == 1 or currentMode == 2 then
            limparTeias()
        end
        mainBtn.Size = UDim2.new(0, 115, 0, 115)
        mainBtn.BackgroundColor3 = Color3.fromRGB(196, 0, 0)
    end)

    UI.mainBtn = mainBtn
    UI.wallBtn = wallBtn
end

local function configurarInputs()
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == CONFIG.TECLA_TEIA then atirarTeia()
        elseif input.KeyCode == CONFIG.TECLA_MODO then
            currentMode = currentMode % 3 + 1
            if UI.modeLabel then UI.modeLabel.Text = CONFIG.MODES[currentMode].icon .. " " .. CONFIG.MODES[currentMode].name end
        elseif input.KeyCode == CONFIG.TECLA_WALL then toggleWallRun()
        elseif input.KeyCode == CONFIG.TECLA_SENSE then ativarSpideySense()
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == CONFIG.TECLA_TEIA then
            if currentMode == 1 or currentMode == 2 then
                limparTeias()
            end
        end
    end)
end

--// INICIALIZAR
local function iniciar()
    repeat task.wait() until player:FindFirstChild("PlayerGui") and player.Character
    criarUI()
    
    soundPuxar = Instance.new("Sound")
    soundPuxar.SoundId = CONFIG.SOM_PUXAR
    soundPuxar.Volume = 0.75
    soundPuxar.PlaybackSpeed = 1.05
    soundPuxar.Parent = camera
    
    soundImpulso = Instance.new("Sound")
    soundImpulso.SoundId = CONFIG.SOM_IMPULSO
    soundImpulso.Volume = 0.75
    soundImpulso.PlaybackSpeed = 1.05
    soundImpulso.Parent = camera
    
    soundBalanco = Instance.new("Sound")
    soundBalanco.SoundId = CONFIG.SOM_BALANCO
    soundBalanco.Volume = 0.75
    soundBalanco.PlaybackSpeed = 1.05
    soundBalanco.Parent = camera
    
    configurarInputs()
    
    player.CharacterAdded:Connect(function(newChar)
        character = newChar
        humanoid = newChar:WaitForChild("Humanoid")
        if wallConn then wallConn:Disconnect() wallConn = nil end
        if pullConn then pullConn:Disconnect() pullConn = nil end
        wallRunning = false spideyActive = false originalC0 = {} 
        activeImpulseAlign = nil
        activeImpulseAtt0 = nil
        handSideCycle = "Right"
        limparTeias()
        
        task.wait(0.5)
        criarUI()
        
        if soundPuxar then soundPuxar:Destroy() end
        if soundImpulso then soundImpulso:Destroy() end
        if soundBalanco then soundBalanco:Destroy() end
        
        soundPuxar = Instance.new("Sound")
        soundPuxar.SoundId = CONFIG.SOM_PUXAR
        soundPuxar.Volume = 0.75
        soundPuxar.PlaybackSpeed = 1.05
        soundPuxar.Parent = camera
        
        soundImpulso = Instance.new("Sound")
        soundImpulso.SoundId = CONFIG.SOM_IMPULSO
        soundImpulso.Volume = 0.75
        soundImpulso.PlaybackSpeed = 1.05
        soundImpulso.Parent = camera
        
        soundBalanco = Instance.new("Sound")
        soundBalanco.SoundId = CONFIG.SOM_BALANCO
        soundBalanco.Volume = 0.75
        soundBalanco.PlaybackSpeed = 1.05
        soundBalanco.Parent = camera
    end)
    
    print("🕷️ SISTEMA HOMEM-ARANHA - IMPULSO CORRIGIDO (gruda em paredes E players)!")
    print("Mira em player no modo Impulso = voa e PARA em cima dele!")
end

pcall(iniciar)
