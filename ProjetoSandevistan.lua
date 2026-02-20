local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local ContentProvider = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")

--// TIPOS
type Cooldowns = {
    SANDI: number,
    DASH: number,
    DODGE: number,
    KIROSHI: number,
    OPTICAL: number
}

type SystemState = {
    Energy: number,
    IsSandiActive: boolean,
    IsKiroshiActive: boolean,
    IsOpticalActive: boolean,
    IsDodgeReady: boolean,
    Cooldowns: Cooldowns,
    EditMode: boolean,
    LastVelocityY: number,
    ActiveLabels: number,
    LastHealth: number,
    LastDeactivationTime: number,
    NoRegenUntil: number,
    MusicSound: Sound?  
}

--// CONSTANTES 
local Constants = {
    MAX_ENERGY = 100,
    SANDI_SPEED = 65,
    DASH_FORCE = 100,
    MOVING_THRESHOLD = 1,
    OPTICAL_DURATION = 5,
    SLOW_FACTOR = 0.8,
    COOLDOWNS = {
        SANDI = 10,
        DASH = 3.5,
        DODGE = 5,
        KIROSHI = 3.5,
        OPTICAL = 6.5
    },
    HOLOGRAM_CLONE = {
        SANDI = {
            DELAY = 0.07,
            DURATION = 1,
            END_TRANSPARENCY = 1,
            OFFSET_X = 0,
            OFFSET_Y = 0,
            OFFSET_Z = 0
        },
        DASH = {
            DELAY = 0.07,
            DURATION = 0.3,
            END_TRANSPARENCY = 1,
            OFFSET_X = 0,
            OFFSET_Y = 0,
            OFFSET_Z = 0
        },
        DODGE = {
            DELAY = 0.2,
            DURATION = 0.5,
            END_TRANSPARENCY = 1,
            OFFSET_X = 0,
            OFFSET_Y = 0,
            OFFSET_Z = 0
        }
    },
    ENERGY_COSTS = {
        SANDI_ACTIVATE = 30,
        SANDI_DRAIN = 2.5,  
        DASH = 8,
        DODGE = 5,
        KIROSHI = 10,
        OPTICAL = 15
    },
    REGEN_RATE = 15,  
    REGEN_DELAY_ZERO = 10,
    REGEN_DELAY_USE = 5,
    DODGE_CONFIG = {
        VARIANT_THRESHOLD = 5.5,
        VARIANT_DURATION = 0.35,
        VARIANT_CLONE_INTERVAL = 0.05,
        NORMAL_CLONE_SPACING = 2,
        NORMAL_DISTANCE_NO_ENEMY = 12,
        NORMAL_DISTANCE_ENEMY = 6
    },
    SANDEVISTAN_FAILURE_CHANCE = 0.2,  
    GLITCH_DURATION = 1.5,
    CYBERPSYCHOSIS = {
        Duration = 6,
        PopupRate = 0.08,
        Radius = 7,
        ShakeIntensity = 0.6,
        WindowLifeTime = 0.5
    },
    ERROR_TEXTS = {
        "SYSTEM FAILURE", "CRITICAL ERROR", "NEURAL OVERLOAD", 
        "CONNECTION LOST", "0xFF0029A CORRUPT", "PSYCHOSIS DETECTED", 
        "FATAL EXCEPTION", "REBOOTING...", "NO SIGNAL"
    }
}

--// CONFIGURAÇÕES GERAIS 
local Configurations = {
    SLOW_GRAVITY_MULTIPLIER = Constants.SLOW_FACTOR ^ 2,
    HOLOGRAM_MATERIAL = Enum.Material.SmoothPlastic,
    ASSETS = {
        TEXTURES = {
            SMOKE = "rbxassetid://243023223",
            SPARKS = "rbxassetid://6071575297",
            HEX = "rbxassetid://6522338870",
            CRACK1 = "rbxassetid://1439194003",
            CRACK2 = "rbxassetid://1439194003"
        }
    },
    HOLOGRAM_PRESERVE = {
        ACCESSORIES = true,
        HAIR = true,
        FACE = false,
        CLOTHES = false,
        ORIGINAL_MATERIAL = false,
        ORIGINAL_COLOR = false
    }
}

--// CORES ATUALIZADAS (verde Sandevistan reduzido)
local Colors = {
    SANDI_TINT = Color3.fromRGB(175, 255, 190),
    DODGE_LIME = Color3.fromRGB(200, 255, 200),
    RAINBOW_SEQUENCE = {
Color3.fromRGB(255, 255, 0),
Color3.fromRGB(255, 188, 0),
Color3.fromRGB(255, 121, 0),
Color3.fromRGB(255, 54, 0),
Color3.fromRGB(255, 0, 13),
Color3.fromRGB(255, 0, 81),
Color3.fromRGB(255, 0, 148),
Color3.fromRGB(255, 0, 215),
Color3.fromRGB(228, 0, 255),
Color3.fromRGB(161, 0, 255),
Color3.fromRGB(94, 0, 255),
Color3.fromRGB(27, 0, 255),
Color3.fromRGB(0, 40, 255),
Color3.fromRGB(0, 107, 255),
Color3.fromRGB(0, 174, 255),
Color3.fromRGB(0, 242, 255),
Color3.fromRGB(0, 255, 201),
Color3.fromRGB(0, 255, 134),
Color3.fromRGB(0, 255, 67),
Color3.fromRGB(0, 255, 0)
},

    DASH_CYAN = Color3.fromRGB(0, 255, 255),
    DASH_CYAN_LIGHT = Color3.fromRGB(100, 255, 255),
    DASH_CYAN_DARK = Color3.fromRGB(0, 200, 200),
    DODGE_START = Color3.fromRGB(160, 0, 255),
    DODGE_END = Color3.fromRGB(255, 0, 130),
    EDIT_MODE = Color3.fromRGB(0, 255, 255),
    TEXT_DEFAULT = Color3.new(1, 1, 1),
    UI_BG = Color3.fromRGB(10, 10, 12),
    UI_ACCENT = Color3.fromRGB(40, 40, 45),
    UI_NEON = Color3.fromRGB(0, 255, 255),
    UI_GLOW = Color3.fromRGB(255, 255, 255),
    UI_DARK = Color3.fromRGB(5, 5, 7),
    KIROSHI_TINT = Color3.fromRGB(255, 100, 100),
    KIROSHI = Color3.fromRGB(255, 0, 0),
    OPTICAL = Color3.fromRGB(0, 255, 255),
    ENERGY_FULL = Color3.fromRGB(50, 205, 50),  
    ENERGY_MEDIUM = Color3.fromRGB(255, 255, 0), 
    ENERGY_LOW = Color3.fromRGB(255, 0, 0),  
    LIGHT_GREEN = Color3.fromRGB(72, 225, 148),  
    ERROR_TEXT = Color3.fromRGB(169, 169, 169),  
    ERROR_BORDER = Color3.fromRGB(105, 105, 105)  
}

--// CONFIGURAÇÕES DE BOTÕES
local ButtonConfigs = {
    LockBtn = {
        Size = UDim2.new(0, 40, 0, 40),
        Position = UDim2.new(0, 20, 0, 60),
        BackgroundColor3 = Colors.UI_DARK,
        TextColor3 = Colors.UI_NEON,
        Font = Enum.Font.SciFi,
        TextSize = 22,
        Text = "⚙️"
    },
    EnergyContainer = {
        Size = UDim2.new(0, 250, 0, 20),
        Position = UDim2.new(0.5, -125, 0.95, -10),
        BackgroundColor3 = Colors.UI_DARK,
        BorderSizePixel = 0
    },
    DashBtn = {
        Key = "D",
        Color = Colors.DASH_CYAN,
        Position = UDim2.new(0.7, 0, 0.85, 0)
    },
    SandiBtn = {
        Key = "S",
        Color = Color3.new(1,1,1),
        Position = UDim2.new(0.75, 0, 0.85, 0)
    },
    KiroshiBtn = {
        Key = "Ko",
        Color = Colors.KIROSHI,
        Position = UDim2.new(0.8, 0, 0.85, 0)
    },
    OpticalBtn = {
        Key = "Oc",
        Color = Colors.OPTICAL,
        Position = UDim2.new(0.85, 0, 0.85, 0)
    },
    DodgeBtn = {
        Key = "N",
        Color = Colors.DODGE_START,
        Position = UDim2.new(0.9, 0, 0.85, 0)
    },
    TrocarSetBtn = {
        Size = UDim2.new(0, 40, 0, 40),
        Position = UDim2.new(1, -60, 0, 45),
        BackgroundColor3 = Colors.UI_DARK,
        TextColor3 = Colors.UI_NEON,
        Font = Enum.Font.SciFi,
        TextSize = 22,
        Text = "⇌"
    }
}

--// NOVO: CONTROLE DE HABILIDADES (toggles do menu)
local EnabledAbilities = {
    Dash = true,
    Sandi = true,
    Kiroshi = true,
    Optical = true,
    Dodge = true
}

local AbilityMap = {
    Dash = "DashBtn",
    Sandi = "SandiBtn",
    Kiroshi = "KiroshiBtn",
    Optical = "OpticalBtn",
    Dodge = "DodgeBtn"
}

local SkillContainers = {}

--// ================= CONFIGURAÇÃO DE SETS (movido para cima conforme pedido para funcionar no menu) =================
local SET_1 = {120005268911290}
local SET_2 = {
    18358624045,
    18358533023,
    18358615215
}

local currentSet = 1
local setColors = {
    [1] = Color3.fromRGB(45, 45, 45),
    [2] = Color3.fromRGB(0, 120, 215)
}

--// NOVO: DODGE MODE (Modo 1 = Counter / Modo 2 = Automático)
local DodgeMode = "Counter"

--// SONS 
local Sounds = {
    DODGE_NORMAL = {id = "rbxassetid://107535457302936", volume = 1.5, pitch = 1, looped = false},
    DODGE_VARIANT = {id = "rbxassetid://95625766377559", volume = 1.5, pitch = 1, looped = false},
    DASH = {id = "rbxassetid://103247005619946", volume = 1.5, pitch = 1, looped = false},
    SANDI_ON = {id = "rbxassetid://123844681344865", volume = 1.5, pitch = 1, looped = false},
    SANDI_OFF = {id = "rbxassetid://118534165523355", volume = 1.5, pitch = 1, looped = false},
    SANDI_LOOP = {id = "rbxassetid://...", volume = 1.5, pitch = 1, looped = true},
    IDLE_MUSIC = {id = "rbxassetid://84295656118500", volume = 5, pitch = 1, looped = true},
    PSYCHOSIS = {id = "rbxassetid://87597277352254", volume = 1.5, pitch = 1, looped = false},
    PSYCHOSIS2 = {id = "rbxassetid://116079585368153", volume = 2, pitch = 1, looped = false},
    OPTICAL_CAMO = {id = "rbxassetid://942127495", volume = 1.5, pitch = 1, looped = false},
    SANDI_FAILURE = {id = "rbxassetid://73272481520628", volume = 1.5, pitch = 1, looped = false}
}

--// ADIÇÃO DA MÚSICA
local NOME_ARQUIVO = "I Really Want to Stay at Your House.mp3"
local VOLUME = 1
local LOOP = false
local AUTO_PLAY = true

local function detectarExecutor()
    if KRNL_LOADED then
        return "KRNL", getcustomasset
    elseif syn then
        return "Synapse X", syn.getcustomasset
    elseif fluxus then
        return "Fluxus", fluxus.getcustomasset
    elseif getcustomasset then
        return "Executor Genérico", getcustomasset
    else
        return nil, nil
    end
end

local function encontrarMusica()
    local executor, getasset = detectarExecutor()
    
    if not executor then
        return nil
    end
    
    local possibilidades = {
        NOME_ARQUIVO,
        "musica.mp3",
        "musica.ogg", 
        "musica.wav",
        "music.mp3",
        "music.ogg",
        "audio.mp3",
        "audio.ogg"
    }
    
    if getasset then
        for _, nome in ipairs(possibilidades) do
            local sucesso, resultado = pcall(function()
                return getasset(nome)
            end)
            
            if sucesso and resultado then
                return resultado
            end
        end
    end
    
    return NOME_ARQUIVO
end

local function tocarMusica()
    local musicaId = encontrarMusica()
    
    if not musicaId then
        return
    end
    
    local somAntigo = SoundService:FindFirstChild("MinhaMusicaLocal")
    if somAntigo then
        somAntigo:Destroy()
    end
    
    local som = Instance.new("Sound")
    som.Name = "MinhaMusicaLocal"
    som.SoundId = musicaId
    som.Volume = VOLUME
    som.Looped = LOOP
    som.RollOffMode = Enum.RollOffMode.Linear
    som.RollOffMaxDistance = 1000
    som.Parent = SoundService
    
    som.Loaded:Connect(function()
        som:Play()
    end)
    
    task.delay(2, function()
        if not som.IsLoaded then
            som:Play()
        end
    end)
    
    return som
end

local function criarGUI()
    pcall(function()
        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "MusicaGUI"
        ScreenGui.Parent = Player:WaitForChild("PlayerGui")
        
        local Frame = Instance.new("Frame")
        Frame.Size = UDim2.new(0, 200, 0, 100)
        Frame.Position = UDim2.new(0.5, -100, 0.9, -50)
        Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        Frame.BorderSizePixel = 0
        Frame.Parent = ScreenGui
        
        local Corner = Instance.new("UICorner")
        Corner.CornerRadius = UDim.new(0, 10)
        Corner.Parent = Frame
        
        local Titulo = Instance.new("TextLabel")
        Titulo.Size = UDim2.new(1, 0, 0.4, 0)
        Titulo.Text = "🎵 Tocando Agora"
        Titulo.TextColor3 = Color3.fromRGB(255, 255, 255)
        Titulo.BackgroundTransparency = 1
        Titulo.Font = Enum.Font.GothamBold
        Titulo.TextSize = 16
        Titulo.Parent = Frame
        
        local BotaoParar = Instance.new("TextButton")
        BotaoParar.Size = UDim2.new(0.8, 0, 0.4, 0)
        BotaoParar.Position = UDim2.new(0.1, 0, 0.5, 0)
        BotaoParar.Text = "⏹️ PARAR MÚSICA"
        BotaoParar.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        BotaoParar.TextColor3 = Color3.fromRGB(255, 255, 255)
        BotaoParar.Font = Enum.Font.GothamBold
        BotaoParar.TextSize = 14
        BotaoParar.Parent = Frame
        
        local CornerBtn = Instance.new("UICorner")
        CornerBtn.CornerRadius = UDim.new(0, 8)
        CornerBtn.Parent = BotaoParar
        
        BotaoParar.MouseButton1Click:Connect(function()
            if State.MusicSound then
                State.MusicSound:Destroy()
                State.MusicSound = nil
                ScreenGui:Destroy()
            end
        end)
    end)
end

--// ESTADO DO SISTEMA
local State: SystemState = {
    Energy = Constants.MAX_ENERGY,
    IsSandiActive = false,
    IsKiroshiActive = false,
    IsOpticalActive = false,
    IsDodgeReady = false,
    Cooldowns = {SANDI = 0, DASH = 0, DODGE = 0, KIROSHI = 0, OPTICAL = 0},
    EditMode = false,
    LastVelocityY = 0,
    ActiveLabels = 0,
    LastHealth = 100,
    LastDeactivationTime = 0,
    NoRegenUntil = 0,
    MusicSound = nil
}

local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Character, HRP, Humanoid
local UI_Elements = {}
local ActiveCooldownFrames = {}
local sandiLoopSound: Sound? = nil
local idleSound: Sound? = nil
local idleTime = 0
local lastSandiClone = 0
local savedPositions = {}
local originalStates = {}
local activeHighlights = {}
local originalGravity: number?
local originalPlayerJumpPower: number?
local originalWalkSpeeds: {[Humanoid]: number} = {}
local originalJumpPowers: {[Humanoid]: number} = {}
local originalAnimationSpeeds: {[AnimationTrack]: number} = {}
local originalSoundSpeeds: {[Sound]: number} = {}
local originalVelocityInstances: {Instance: Vector3} = {}
local animationConnections: {RBXScriptConnection} = {}
local opticalToken = 0

-- Variáveis e funções de invisibilidade
local invisSound = Instance.new("Sound", Player:WaitForChild("PlayerGui"))
invisSound.SoundId = Sounds.OPTICAL_CAMO.id
invisSound.Volume = Sounds.OPTICAL_CAMO.volume
invisSound.PlaybackSpeed = Sounds.OPTICAL_CAMO.pitch
invisSound.Looped = Sounds.OPTICAL_CAMO.looped

local function getSafeInvisPosition()
    local offset = Vector3.new(math.random(-5000, 5000), math.random(10000, 15000), math.random(-5000, 5000))
    return offset
end

local function setTransparency(character, targetTransparency, duration)
    local tweenInfo = TweenInfo.new(duration or 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("Decal") then
            if part.Name == "HumanoidRootPart" then continue end
            TweenService:Create(part, tweenInfo, {Transparency = targetTransparency}):Play()
        end
    end
end

-- NOVO MÉTODO DE CAMUFLAGEM (igual ao script que você enviou)
local function activateInvisibility()
    invisSound:Play()
    local savedpos = Player.Character.HumanoidRootPart.CFrame
    task.wait()
    local invisPos = getSafeInvisPosition()
    Player.Character:MoveTo(invisPos)
    task.wait(0.15)
    local Seat = Instance.new('Seat', Workspace)
    Seat.Anchored = false
    Seat.CanCollide = false
    Seat.Name = 'invischair'
    Seat.Transparency = 1
    Seat.Position = invisPos
    local Weld = Instance.new("Weld", Seat)
    Weld.Part0 = Seat
    Weld.Part1 = Player.Character:FindFirstChild("Torso") or Player.Character.UpperTorso
    task.wait()
    Seat.CFrame = savedpos
    setTransparency(Player.Character, 0.5, 0.5)
end

local function deactivateInvisibility()
    invisSound:Play()
    local invisChair = Workspace:FindFirstChild('invischair')
    if invisChair then
        invisChair:Destroy()
    end
    setTransparency(Player.Character, 0, 0.5)
end

--// FUNÇÕES UTILITÁRIAS
local function Create(className: string, properties: {[string]: any})
    local instance = Instance.new(className)
    for prop, value in properties do
        instance[prop] = value
    end
    return instance
end

local function PlaySFX(soundConfig: {id: string, volume: number?, pitch: number?})
    local sound = Create("Sound", {
        SoundId = soundConfig.id,
        Volume = soundConfig.volume or 1,
        PlaybackSpeed = soundConfig.pitch or 1,
        Parent = HRP or Camera
    })
    sound:Play()
    Debris:AddItem(sound, 10)
    return sound
end

local function CamShake(intensity: number, duration: number)
    task.spawn(function()
        local startTime = os.clock()
        while os.clock() - startTime < duration do
            if not Humanoid then break end
            Humanoid.CameraOffset = Vector3.new(
                math.random(-10, 10)/10, 
                math.random(-10, 10)/10, 
                math.random(-10, 10)/10
            ) * intensity
            RunService.RenderStepped:Wait()
        end
        if Humanoid then Humanoid.CameraOffset = Vector3.zero end
    end)
end

--// UI DE COOLDOWN
local function ShowCooldownText(name: string, duration: number, color: Color3)
    task.spawn(function()
        local gui = Player.PlayerGui:FindFirstChild("CyberRebuilt")
        if not gui then return end
        
        local container = Create("Frame", {
            Size = UDim2.new(0, 180, 0, 30),
            Position = UDim2.new(0.5, -90, 0.7, 0),
            BackgroundColor3 = Colors.UI_DARK,
            BackgroundTransparency = 0.1,
            BorderSizePixel = 0,
            Parent = gui
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = container})
        local stroke = Create("UIStroke", {Color = color, Thickness = 1.5, Transparency = 0.3, Parent = container})
        
        local label = Create("TextLabel", {
            Size = UDim2.new(1, -15, 0.5, 0),
            Position = UDim2.new(0, 15, 0, 0),
            BackgroundTransparency = 1,
            TextColor3 = color,
            Font = Enum.Font.SciFi,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = name:upper(),
            Parent = container
        })
        
        local progressBar = Create("Frame", {
            Size = UDim2.new(1, 0, 0.4, 0),
            Position = UDim2.new(0, 0, 0.6, 0),
            BackgroundColor3 = Colors.UI_BG,
            BorderSizePixel = 0,
            Parent = container
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 3), Parent = progressBar})
        local fillBar = Create("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            Parent = progressBar
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 3), Parent = fillBar})
        local barGradient = Create("UIGradient", {Color = ColorSequence.new(color, color:Lerp(Colors.UI_NEON, 0.5)), Rotation = 90, Parent = fillBar})
        
        local timer = Create("TextLabel", {
            Size = UDim2.new(1, -15, 0.5, 0),
            Position = UDim2.new(0, -15, 0, 0),
            BackgroundTransparency = 1,
            TextColor3 = Colors.UI_NEON,
            Font = Enum.Font.Code,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Right,
            Parent = container
        })
        
        table.insert(ActiveCooldownFrames, container)
        
        local function GetMyIndex()
            for i, v in ipairs(ActiveCooldownFrames) do
                if v == container then return i end
            end
            return nil
        end
        
        if name:upper() == "SANDEVISTAN" then
            task.spawn(function()
                while container.Parent do
                    local hue = (os.clock() % 5) / 5
                    local rainbowColor = Color3.fromHSV(hue, 1, 1)
                    label.TextColor3 = rainbowColor
                    stroke.Color = rainbowColor
                    fillBar.BackgroundColor3 = rainbowColor
                    task.wait()
                end
            end)
        end
        
        local startTime = os.clock()
        while os.clock() - startTime < duration do
            local remaining = math.max(0, duration - (os.clock() - startTime))
            local progress = remaining / duration
            timer.Text = string.format("%.1fS", remaining)
            fillBar.Size = UDim2.new(1 - progress, 0, 1, 0)
            local myIndex = GetMyIndex()
            if myIndex then
                local targetPos = UDim2.new(0.5, -90, 0.7, -(myIndex - 1) * 35)
                container.Position = container.Position:Lerp(targetPos, 0.15)
            end
            RunService.RenderStepped:Wait()
        end
        
        TweenService:Create(container, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        TweenService:Create(label, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
        TweenService:Create(timer, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
        TweenService:Create(progressBar, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        TweenService:Create(fillBar, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        task.wait(0.3)
        
        local index = GetMyIndex()
        if index then table.remove(ActiveCooldownFrames, index) end
        container:Destroy()
    end)
end

--// EFEITOS VISUAIS
local function CreateHologramClone(delay: number, duration: number, endTransparency: number, offsetX: number, offsetY: number, offsetZ: number, cloneType: string, customCFrame: CFrame?)
    if not Character then return end
    Character.Archivable = true
    local hologramChar = Character:Clone()
    local hologramHRP = hologramChar:FindFirstChild("HumanoidRootPart")
    
    if cloneType == "glitch" then
        offsetX = math.random(-2, 2)
        offsetZ = math.random(-2, 2)
    end

    if hologramHRP and HRP then
        if customCFrame then
            hologramHRP.CFrame = customCFrame
        else
            hologramHRP.CFrame = HRP.CFrame + Vector3.new(offsetX, offsetY, offsetZ)
        end
    end
    
    -- Remove HumanoidRootPart dos clones de Optical Camouflage para evitar duplicatas indesejadas
    if cloneType == "optical" and hologramHRP then
        hologramHRP:Destroy()
        hologramHRP = nil
    end
    
    local humanoid = hologramChar:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid:Destroy() end
    local animateFolder = hologramChar:FindFirstChild("Animate")
    if animateFolder then animateFolder:Destroy() end
    
    for _, obj in ipairs(hologramChar:GetDescendants()) do
        if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") or
           obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") or
           obj:IsA("BindableEvent") or obj:IsA("BindableFunction") or
           obj:IsA("Animator") then
            obj:Destroy()
        end
    end

    for _, sound in ipairs(hologramChar:GetDescendants()) do
        if sound:IsA("Sound") then sound:Destroy() end
    end
    
    if not Configurations.HOLOGRAM_PRESERVE.FACE then
        local head = hologramChar:FindFirstChild("Head")
        if head then
            local face = head:FindFirstChild("face")
            if face and face:IsA("Decal") then face:Destroy() end
        end
    end
    
    if not Configurations.HOLOGRAM_PRESERVE.CLOTHES then
        local shirt = hologramChar:FindFirstChildOfClass("Shirt")
        if shirt then shirt:Destroy() end
        local pants = hologramChar:FindFirstChildOfClass("Pants")
        if pants then pants:Destroy() end
        local graphic = hologramChar:FindFirstChildOfClass("ShirtGraphic")
        if graphic then graphic:Destroy() end
    end
    
    for _, acc in ipairs(hologramChar:GetChildren()) do
        if acc:IsA("Accessory") then
            local isHair = acc:FindFirstChild("HairAttachment") or string.find(acc.Name:lower(), "hair") ~= nil
            if isHair and not Configurations.HOLOGRAM_PRESERVE.HAIR then
                acc:Destroy()
            elseif not isHair and not Configurations.HOLOGRAM_PRESERVE.ACCESSORIES then
                acc:Destroy()
            end
        end
    end
    
    for _, part in ipairs(hologramChar:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = true
            part.CanCollide = false
            if not Configurations.HOLOGRAM_PRESERVE.ORIGINAL_MATERIAL then
                part.Material = Configurations.HOLOGRAM_MATERIAL
            end
            part.Transparency = 0.1
        elseif part:IsA("Decal") or part:IsA("Texture") then
            part.Transparency = 0.1
        end
    end

    if hologramHRP then hologramHRP.Transparency = 1 end
    
    for _, part in ipairs(hologramChar:GetDescendants()) do
        if part:IsA("BasePart") then
            task.spawn(function()
                task.wait(delay)
                local colors = Colors.RAINBOW_SEQUENCE
                
                if not Configurations.HOLOGRAM_PRESERVE.ORIGINAL_COLOR and #colors >= 2 then
                    local startTime = os.clock()
                    local totalTime = duration
                    
                    while os.clock() - startTime < totalTime do
                        local progress = (os.clock() - startTime) / totalTime
                        local idx = math.floor(progress * (#colors - 1)) + 1
                        local nextIdx = math.min(idx + 1, #colors)
                        local frac = (progress * (#colors - 1)) % 1
                        
                        local currentColor = colors[idx]:Lerp(colors[nextIdx], frac)
                        part.Color = currentColor
                        
                        RunService.Heartbeat:Wait()
                    end
                    
                    local fadeTween = TweenService:Create(part, TweenInfo.new(duration * 0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                        Transparency = endTransparency
                    })
                    fadeTween:Play()
                end
            end)
        end
    end
    
    for _, surf in ipairs(hologramChar:GetDescendants()) do
        if surf:IsA("Decal") or surf:IsA("Texture") then
            task.spawn(function()
                task.wait(delay + duration * 0.3)
                local fadeTween = TweenService:Create(surf, TweenInfo.new(duration * 0.7, Enum.EasingStyle.Quad), {Transparency = endTransparency})
                fadeTween:Play()
            end)
        end
    end
    
    hologramChar.Parent = Workspace
    Debris:AddItem(hologramChar, delay + duration + 1)
end

--// NOVO SISTEMA DE FALHA SANDEVISTAN
local function TriggerSandevistanFailure()
    PlaySFX(Sounds.SANDI_FAILURE)
    
    local gui = Player.PlayerGui:FindFirstChild("CyberRebuilt") or Instance.new("ScreenGui", Player.PlayerGui)
    gui.Name = "CyberRebuilt"
    
    local errorFrame = Instance.new("Frame")
    errorFrame.Size = UDim2.new(0.65, 0, 0.25, 0)
    errorFrame.Position = UDim2.new(0.5, 0, 0.4, 0)
    errorFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    errorFrame.BackgroundColor3 = Color3.fromRGB(8, 0, 2)
    errorFrame.BorderSizePixel = 0
    errorFrame.Parent = gui
    
    Instance.new("UICorner", errorFrame).CornerRadius = UDim.new(0, 12)
    local stroke = Instance.new("UIStroke", errorFrame)
    stroke.Color = Color3.fromRGB(255, 30, 60)
    stroke.Thickness = 4
    stroke.Transparency = 0.2
    
    local title = Instance.new("TextLabel", errorFrame)
    title.Size = UDim2.new(1, 0, 0.45, 0)
    title.BackgroundTransparency = 1
    title.Text = "NEURAL OVERLOAD"
    title.TextColor3 = Color3.fromRGB(255, 40, 80)
    title.Font = Enum.Font.SciFi
    title.TextSize = 42
    title.TextStrokeTransparency = 0.3
    
    local desc = Instance.new("TextLabel", errorFrame)
    desc.Size = UDim2.new(1, 0, 0.55, 0)
    desc.Position = UDim2.new(0, 0, 0.45, 0)
    desc.BackgroundTransparency = 1
    desc.Text = "SANDEVISTAN CORE UNSTABLE\n0xFF0029A • PSYCHOSIS DETECTED"
    desc.TextColor3 = Color3.fromRGB(180, 180, 180)
    desc.Font = Enum.Font.Code
    desc.TextSize = 18
    desc.TextStrokeTransparency = 0.7
    
    task.spawn(function()
        for i = 1, 12 do
            title.TextTransparency = i % 2 == 0 and 0.9 or 0
            desc.TextTransparency = i % 2 == 0 and 0.8 or 0.2
            task.wait(0.045)
        end
        title.TextTransparency = 0
        desc.TextTransparency = 0
    end)
    
    task.delay(2.8, function()
        TweenService:Create(errorFrame, TweenInfo.new(0.6), {BackgroundTransparency = 1}):Play()
        TweenService:Create(title, TweenInfo.new(0.6), {TextTransparency = 1}):Play()
        TweenService:Create(desc, TweenInfo.new(0.6), {TextTransparency = 1}):Play()
        task.wait(0.7)
        errorFrame:Destroy()
    end)
    
    ApplyGlitchEffect()
    
    if math.random() < 0.3 then
        task.wait(0.4)
        ExecCyberpsychosis()
    end
    
    State.Cooldowns.SANDI = os.clock() + 7.5
    State.NoRegenUntil = os.clock() + 8
    ShowCooldownText("SANDEVISTAN FAILURE", 7.5, Color3.fromRGB(255, 40, 80))
end

local function ApplyGlitchEffect()
    task.spawn(function()
        local start = os.clock()
        local cc = Instance.new("ColorCorrectionEffect", Lighting)
        local blur = Instance.new("BlurEffect", Lighting)
        blur.Size = 0
        
        while os.clock() - start < 2.2 do
            CreateHologramClone(0, 0.08, 0.95, math.random(-3,3), math.random(-1,1), math.random(-3,3), "glitch")
            CamShake(0.65, 0.1)
            
            cc.Saturation = math.random(-2, 0.8)
            cc.Contrast = math.random(-1.5, 2)
            cc.TintColor = Color3.fromHSV(math.random(), 0.9, 1)
            blur.Size = math.random(12, 24)
            
            task.wait(0.055)
        end
        
        TweenService:Create(cc, TweenInfo.new(0.6), {Saturation = 0, Contrast = 0}):Play()
        TweenService:Create(blur, TweenInfo.new(0.6), {Size = 0}):Play()
        task.delay(0.7, function()
            cc:Destroy()
            blur:Destroy()
        end)
    end)
end

--// CYBERPSYCHOSIS ANTIGO (restaurado)
local function createLightingEffects()
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "PsychoCC"
	cc.TintColor = Color3.fromRGB(255, 80, 80)
	cc.Contrast = 0.6
	cc.Saturation = 1.3
	cc.Parent = Lighting

	local blur = Instance.new("BlurEffect")
	blur.Name = "PsychoBlur"
	blur.Size = 0
	blur.Parent = Lighting
	
	return cc, blur
end

local function spawnPopup()
	if not HRP then return end

	local targetWidth = math.random(3.8, 8.2)
	local targetHeight = math.random(2.3, 5.4)
	local finalSize = Vector3.new(targetWidth, targetHeight, 0.07)

	local part = Instance.new("Part")
	part.Name = "GlitchWindow"
	part.Size = Vector3.new(0, 0, 0)
	part.Color = Color3.fromRGB(9, 0, 2)
	part.Material = Enum.Material.Neon
	part.Transparency = 0.02
	part.CanCollide = false
	part.Anchored = true
	part.CastShadow = false
	
	local randomOffset = Vector3.new(
		math.random(-Constants.CYBERPSYCHOSIS.Radius, Constants.CYBERPSYCHOSIS.Radius),
		math.random(1.1, 6.8),
		math.random(-Constants.CYBERPSYCHOSIS.Radius, Constants.CYBERPSYCHOSIS.Radius)
	)
	
	part.Position = HRP.Position + randomOffset
	
	local look = CFrame.lookAt(part.Position, HRP.Position)
	part.CFrame = look * CFrame.Angles(
		math.rad(math.random(-25,25)), 
		math.rad(math.random(-40,40)), 
		math.rad(math.random(-15,15))
	)

	part.Parent = Workspace

	local sgui = Instance.new("SurfaceGui")
	sgui.Face = Enum.NormalId.Front
	sgui.LightInfluence = 0
	sgui.PixelsPerStud = 50
	sgui.Parent = part

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1,0,1,0)
	frame.BackgroundColor3 = Color3.fromRGB(6,0,1)
	frame.Parent = sgui

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 25, 60)
	stroke.Thickness = 4
	stroke.Parent = frame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 5)
	corner.Parent = frame

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1,-16,0.72,0)
	label.Position = UDim2.new(0,8,0,5)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 50, 80)
	label.TextScaled = true
	label.Font = Enum.Font.SciFi
	label.Text = Constants.ERROR_TEXTS[math.random(1, #Constants.ERROR_TEXTS)]
	label.TextStrokeTransparency = 0.4
	label.TextStrokeColor3 = Color3.fromRGB(255,0,25)
	label.Parent = frame

	local sublabel = Instance.new("TextLabel")
	sublabel.Size = UDim2.new(1,-16,0.28,-8)
	sublabel.Position = UDim2.new(0,8,0.72,4)
	sublabel.BackgroundTransparency = 1
	sublabel.TextColor3 = Color3.fromRGB(255, 125, 140)
	sublabel.Font = Enum.Font.Code
	sublabel.TextScaled = true
	sublabel.Text = "0x"..string.format("%X", math.random(0x8000,0xFFFF)) .. "_NEURAL_CRITICAL"
	sublabel.Parent = frame

	task.spawn(function()
		for i = 1,8 do
			label.TextTransparency = i%2 == 0 and 0.85 or 0
			task.wait(0.032)
		end
		label.TextTransparency = 0
	end)

	TweenService:Create(part, TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = finalSize}):Play()

	task.delay(Constants.CYBERPSYCHOSIS.WindowLifeTime - 0.25, function()
		if part.Parent then 
			TweenService:Create(part, TweenInfo.new(0.25), {Size = Vector3.new(0,0,0)}):Play() 
		end
	end)

	Debris:AddItem(part, Constants.CYBERPSYCHOSIS.WindowLifeTime + 0.5)
end

local function shakeCamera()
	if not Humanoid then return end
	local intensity = Constants.CYBERPSYCHOSIS.ShakeIntensity
	Humanoid.CameraOffset = Vector3.new(
		(math.random() - 0.5) * intensity,
		(math.random() - 0.5) * intensity,
		(math.random() - 0.5) * intensity
	)
end

local function ExecCyberpsychosis()
    PlaySFX(Sounds.PSYCHOSIS)
    PlaySFX(Sounds.PSYCHOSIS2)
    
    task.spawn(function()
        local syncTimes = {0.3, 0.8, 1.4, 2.0, 2.7, 3.2, 3.55, 3.8, 4.05, 4.3, 4.55, 4.8, 5.1, 5.4, 5.75}
        for _, t in ipairs(syncTimes) do
            task.delay(t, spawnPopup)
        end
        task.delay(4.0, function()
            for i = 1, 3 do
                spawnPopup()
                task.wait(0.09)
            end
        end)
        task.delay(5.2, function()
            for i = 1, 5 do
                spawnPopup()
                task.wait(0.06)
            end
        end)
    end)
    
    if Humanoid then
        Humanoid.WalkSpeed = 0
        Humanoid.JumpPower = 0
    end
    
    if Lighting:FindFirstChild("SandiEffect") then Lighting.SandiEffect:Destroy() end
    
    local cc, blur = createLightingEffects()
    
    local startTime = tick()
    local connection

    local gui = Player.PlayerGui:FindFirstChild("CyberRebuilt") or Create("ScreenGui", {Name = "CyberRebuilt", Parent = Player.PlayerGui, IgnoreGuiInset = true})
    
    local vignette = Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 0.5,
        BackgroundColor3 = Color3.new(0, 0, 0),
        Parent = gui
    })
    local vignetteGradient = Create("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.5, 0.5),
            NumberSequenceKeypoint.new(1, 1)
        }),
        Rotation = 0,
        Parent = vignette
    })
    task.spawn(function()
        while vignette.Parent do
            TweenService:Create(vignette, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.3}):Play()
            task.wait(0.5)
            TweenService:Create(vignette, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.7}):Play()
            task.wait(0.5)
        end
    end)

    local psychosisText = Create("TextLabel", {
        Size = UDim2.new(1, 0, 0.2, 0),
        Position = UDim2.new(0, 0, 0.4, 0),
        BackgroundTransparency = 1,
        Text = "CYBERPSYCHOSIS",
        TextColor3 = Color3.fromRGB(255, 0, 0),
        Font = Enum.Font.SciFi,
        TextSize = 80,
        TextTransparency = 0.5,
        Parent = gui
    })
    task.spawn(function()
        while psychosisText.Parent do
            TweenService:Create(psychosisText, TweenInfo.new(0.2), {TextTransparency = 0}):Play()
            task.wait(0.2)
            TweenService:Create(psychosisText, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
            task.wait(0.2)
        end
    end)

    local crackImages = {Configurations.ASSETS.TEXTURES.CRACK1, Configurations.ASSETS.TEXTURES.CRACK2}
    for i = 1, 5 do
        local crack = Create("ImageLabel", {
            Size = UDim2.new(0.3, 0, 0.3, 0),
            Position = UDim2.new(math.random(), 0, math.random(), 0),
            BackgroundTransparency = 1,
            Image = crackImages[math.random(1, #crackImages)],
            ImageTransparency = 0.5,
            Parent = gui
        })
        task.spawn(function()
            while crack.Parent do
                crack.Position = UDim2.new(math.random(), 0, math.random(), 0)
                TweenService:Create(crack, TweenInfo.new(0.1), {ImageTransparency = math.random(0.2, 0.8)}):Play()
                task.wait(0.1)
            end
        end)
    end

    local redOverlay = Create("ImageLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ImageColor3 = Color3.fromRGB(255, 0, 0),
        ImageTransparency = 0.8,
        Parent = gui
    })
    local blueOverlay = Create("ImageLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ImageColor3 = Color3.fromRGB(0, 0, 255),
        ImageTransparency = 0.8,
        Parent = gui
    })
    task.spawn(function()
        while redOverlay.Parent do
            redOverlay.Position = UDim2.new(0, math.random(-2, 2), 0, math.random(-2, 2))
            blueOverlay.Position = UDim2.new(0, math.random(-2, 2), 0, math.random(-2, 2))
            task.wait(0.05)
        end
    end)

    local parts = {Character:FindFirstChild("Head"), Character:FindFirstChild("RightArm"), Character:FindFirstChild("LeftArm")}
    local emitters = {}
    for _, part in ipairs(parts) do
        if part then
            local attachment = Instance.new("Attachment", part)
            local emitter = Instance.new("ParticleEmitter", attachment)
            emitter.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0))
            emitter.Size = NumberSequence.new(0.5)
            emitter.Texture = Configurations.ASSETS.TEXTURES.SPARKS
            emitter.Lifetime = NumberRange.new(0.5, 1)
            emitter.Rate = 50
            emitter.Speed = NumberRange.new(5, 10)
            emitter.Enabled = true
            table.insert(emitters, emitter)
        end
    end

    local phaseDuration = Constants.CYBERPSYCHOSIS.Duration / 3
    local currentPhase = 1

    local cyberParts = {Character:FindFirstChild("RightArm"), Character:FindFirstChild("LeftArm"), Character:FindFirstChild("Torso") or Character:FindFirstChild("UpperTorso")}
    task.spawn(function()
        while currentPhase <= 3 do
            for _, part in ipairs(cyberParts) do
                if part then
                    part.Transparency = math.random(0.2, 0.8)
                    part.Color = Color3.fromHSV(math.random(), 1, 1)
                end
            end
            task.wait(0.1)
        end
        for _, part in ipairs(cyberParts) do
            if part then
                part.Transparency = 0
                part.Color = Color3.new(1,1,1)
            end
        end
    end)

    local syncTimesDistortion = {0.3, 1.4, 2.7, 3.55, 4.05, 4.55, 5.1}
    for _, t in ipairs(syncTimesDistortion) do
        task.delay(t, function()
            TweenService:Create(vignette, TweenInfo.new(0.1), {BackgroundTransparency = 0}):Play()
            TweenService:Create(psychosisText, TweenInfo.new(0.1), {TextTransparency = 0}):Play()
            task.wait(0.1)
            TweenService:Create(vignette, TweenInfo.new(0.1), {BackgroundTransparency = 0.5}):Play()
            TweenService:Create(psychosisText, TweenInfo.new(0.1), {TextTransparency = 0.5}):Play()
        end)
    end

    connection = RunService.RenderStepped:Connect(function(dt)
        local elapsed = tick() - startTime
        if elapsed > Constants.CYBERPSYCHOSIS.Duration then
            if Humanoid then
                Humanoid.WalkSpeed = 16
                Humanoid.JumpPower = 50
                Humanoid.CameraOffset = Vector3.zero
            end
            
            TweenService:Create(cc, TweenInfo.new(0.5), {TintColor = Color3.new(1,1,1), Saturation = 0}):Play()
            TweenService:Create(blur, TweenInfo.new(0.5), {Size = 0}):Play()
            Debris:AddItem(cc, 0.5)
            Debris:AddItem(blur, 0.5)
            
            connection:Disconnect()

            vignette:Destroy()
            psychosisText:Destroy()
            redOverlay:Destroy()
            blueOverlay:Destroy()
            for _, crack in ipairs(gui:GetChildren()) do
                if crack:IsA("ImageLabel") then crack:Destroy() end
            end
            for _, emitter in ipairs(emitters) do
                emitter.Enabled = false
                Debris:AddItem(emitter.Parent, 1)
            end
            return
        end
        
        if elapsed < phaseDuration then
            currentPhase = 1
            Constants.CYBERPSYCHOSIS.ShakeIntensity = 0.2
            Constants.CYBERPSYCHOSIS.PopupRate = 0.05
            blur.Size = math.random(2, 6)
        elseif elapsed < phaseDuration * 2 then
            currentPhase = 2
            Constants.CYBERPSYCHOSIS.ShakeIntensity = 0.6
            Constants.CYBERPSYCHOSIS.PopupRate = 0.1
            blur.Size = math.random(8, 16)
        else
            currentPhase = 3
            Constants.CYBERPSYCHOSIS.ShakeIntensity = 1.0
            Constants.CYBERPSYCHOSIS.PopupRate = 0.15
            blur.Size = math.random(12, 20)
            if Humanoid then
                Humanoid.WalkSpeed = 50
                if Humanoid.Health > Humanoid.MaxHealth * 0.5 then
                    Humanoid.Health -= 1 * dt
                end
            end
        end

        blur.Size = math.random(4, 12)
        shakeCamera()
        
        if math.random() < Constants.CYBERPSYCHOSIS.PopupRate then
            spawnPopup()
        end
    end)
end

--// FUNÇÕES DE HABILIDADES
local function CleanupSandiSounds()
    if sandiLoopSound then
        sandiLoopSound:Stop()
        sandiLoopSound:Destroy()
        sandiLoopSound = nil
    end
    if idleSound then
        idleSound:Stop()
        idleSound:Destroy()
        idleSound = nil
    end
    idleTime = 0
end

local function ShowErrorText()
    local gui = Player.PlayerGui:FindFirstChild("CyberRebuilt") or Create("ScreenGui", {Name = "CyberRebuilt", Parent = Player.PlayerGui, IgnoreGuiInset = true})
    
    local errorContainer = Create("Frame", {
        Size = UDim2.new(0.6, 0, 0.15, 0),
        Position = UDim2.new(0.2, 0, 0.4, 0),
        BackgroundColor3 = Colors.UI_DARK,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        Parent = gui
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = errorContainer})
    local stroke = Create("UIStroke", {Color = Colors.ERROR_BORDER, Thickness = 2, Transparency = 0, Parent = errorContainer})
    
    local errorLabel = Create("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "Error : Sandevistan Contains Errors",
        TextColor3 = Colors.ERROR_TEXT,
        Font = Enum.Font.SciFi,
        TextSize = 32,
        TextTransparency = 1,
        Parent = errorContainer
    })
    
    local fadeIn = TweenService:Create(errorContainer, TweenInfo.new(0.5), {BackgroundTransparency = 0.1})
    local fadeInLabel = TweenService:Create(errorLabel, TweenInfo.new(0.5), {TextTransparency = 0})
    local fadeInStroke = TweenService:Create(stroke, TweenInfo.new(0.5), {Transparency = 0})
    fadeIn:Play()
    fadeInLabel:Play()
    fadeInStroke:Play()
    
    task.delay(3, function()
        local fadeOut = TweenService:Create(errorContainer, TweenInfo.new(0.5), {BackgroundTransparency = 1})
        local fadeOutLabel = TweenService:Create(errorLabel, TweenInfo.new(0.5), {TextTransparency = 1})
        local fadeOutStroke = TweenService:Create(stroke, TweenInfo.new(0.5), {Transparency = 1})
        fadeOut:Play()
        fadeOutLabel:Play()
        fadeOutStroke:Play()
        fadeOut.Completed:Connect(function()
            errorContainer:Destroy()
        end)
    end)
end

local function ExecDodge(enemyPart: BasePart?)
    local dodgeCC = Create("ColorCorrectionEffect", {
        Name = "DodgeEffect",
        TintColor = Color3.new(1, 1, 1),
        Saturation = 0,
        Contrast = 0,
        Parent = Lighting
    })

    TweenService:Create(dodgeCC, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TintColor = Colors.DODGE_LIME,
        Saturation = 0.45,
        Contrast = 0.25
    }):Play()

    local startCFrame = HRP.CFrame
    local distance = if enemyPart then (HRP.Position - enemyPart.Position).Magnitude else 0

    local dodgeDuration = 0.35

    if enemyPart and distance <= Constants.DODGE_CONFIG.VARIANT_THRESHOLD then
        PlaySFX(Sounds.DODGE_VARIANT)

        task.spawn(function()
            local duration = Constants.DODGE_CONFIG.VARIANT_DURATION
            local startTime = tick()
            local relative = HRP.Position - enemyPart.Position
            local lastCloneTime = 0

            while tick() - startTime < duration do
                local alpha = (tick() - startTime) / duration
                local angle = alpha * math.pi
                local rotated = CFrame.new(0, 0, 0) * CFrame.Angles(0, angle, 0) * relative
                local newPos = enemyPart.Position + rotated
                HRP.CFrame = CFrame.lookAt(newPos, enemyPart.Position)

                if tick() - lastCloneTime >= Constants.DODGE_CONFIG.VARIANT_CLONE_INTERVAL then
                    CreateHologramClone(0, Constants.HOLOGRAM_CLONE.DODGE.DURATION, Constants.HOLOGRAM_CLONE.DODGE.END_TRANSPARENCY, 0, 0, 0, "dodge", HRP.CFrame)
                    lastCloneTime = tick()
                end

                RunService.Heartbeat:Wait()
            end

            local finalRelative = relative * CFrame.Angles(0, math.pi, 0)
            local finalPos = enemyPart.Position + finalRelative
            HRP.CFrame = CFrame.lookAt(finalPos, enemyPart.Position)
        end)

    else
        PlaySFX(Sounds.DODGE_NORMAL)
        local endCFrame = enemyPart and 
            CFrame.lookAt((enemyPart.CFrame * CFrame.new(0, 0, Constants.DODGE_CONFIG.NORMAL_DISTANCE_ENEMY)).Position, enemyPart.Position) or
            HRP.CFrame * CFrame.new(0, 0, -Constants.DODGE_CONFIG.NORMAL_DISTANCE_NO_ENEMY)

        CreateHologramClone(0, 1, 1, 0, 0, 0, "dodge", startCFrame)
        HRP.CFrame = endCFrame

        dodgeDuration = 0.22
    end

    CamShake(0.5, 0.2)

    task.delay(dodgeDuration, function()
        local fadeOut = TweenService:Create(dodgeCC, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            TintColor = Color3.new(1, 1, 1),
            Saturation = 0,
            Contrast = 0
        })
        fadeOut:Play()
        fadeOut.Completed:Connect(function()
            dodgeCC:Destroy()
        end)
    end)
end

local function ActivateDodgeReady()
    if not EnabledAbilities.Dodge then return end
    if os.clock() < State.Cooldowns.DODGE then return end
    
    if DodgeMode == "Counter" then
        -- Modo Counter (comportamento antigo)
        if State.Energy < Constants.ENERGY_COSTS.DODGE then return end
        State.Energy -= Constants.ENERGY_COSTS.DODGE
        State.NoRegenUntil = os.clock() + Constants.REGEN_DELAY_USE
        State.IsDodgeReady = true
        
        task.spawn(function()
            task.wait(2)
            if State.IsDodgeReady and DodgeMode == "Counter" then
                State.IsDodgeReady = false
                State.Cooldowns.DODGE = os.clock() + Constants.COOLDOWNS.DODGE
                ShowCooldownText("Neural Dodge", Constants.COOLDOWNS.DODGE, Colors.DODGE_END)
            end
        end)
    else
        -- Modo Automático: fica pronto infinitamente até ser usado
        State.IsDodgeReady = true
    end
end

local function UpdateDashButton()
    local gui = Player.PlayerGui:FindFirstChild("CyberRebuilt")
    if not gui then return end
    local dashBtn = gui:FindFirstChild("DashBtn")
    if not dashBtn then return end
    
    if State.IsSandiActive then
        dashBtn.TextColor3 = Color3.new(0.5, 0.5, 0.5)
    else
        dashBtn.TextColor3 = Colors.DASH_CYAN
    end
end

local function UpdateKiroshiButton()
    local gui = Player.PlayerGui:FindFirstChild("CyberRebuilt")
    if not gui then return end
    local kiroshiBtn = gui:FindFirstChild("KiroshiBtn")
    if not kiroshiBtn then return end
    
    if State.IsSandiActive then
        kiroshiBtn.TextColor3 = Color3.new(0.5, 0.5, 0.5)
    else
        kiroshiBtn.TextColor3 = Colors.KIROSHI
    end
end

local function UpdateOpticalButton()
    local gui = Player.PlayerGui:FindFirstChild("CyberRebuilt")
    if not gui then return end
    local opticalBtn = gui:FindFirstChild("OpticalBtn")
    if not opticalBtn then return end
    
    if State.IsSandiActive then
        opticalBtn.TextColor3 = Color3.new(0.5, 0.5, 0.5)
    else
        opticalBtn.TextColor3 = Colors.OPTICAL
    end
end

local function ResetSandi()
    if not State.IsSandiActive then return end
    State.IsSandiActive = false
    PlaySFX(Sounds.SANDI_OFF)
    State.Cooldowns.SANDI = os.clock() + Constants.COOLDOWNS.SANDI
    State.NoRegenUntil = os.clock() + Constants.REGEN_DELAY_USE
    ShowCooldownText("Sandevistan", Constants.COOLDOWNS.SANDI, Colors.RAINBOW_SEQUENCE[1])
    local sandiEffect = Lighting:FindFirstChild("SandiEffect")
    if sandiEffect then
        TweenService:Create(sandiEffect, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            TintColor = Color3.new(1,1,1),
            Contrast = 0,
            Saturation = 0
        }):Play()
        task.delay(0.5, function() sandiEffect:Destroy() end)
    end
    if Humanoid then
        Humanoid.WalkSpeed = 16
        if originalPlayerJumpPower then
            Humanoid.UseJumpPower = true
            Humanoid.JumpPower = originalPlayerJumpPower
            originalPlayerJumpPower = nil
        end
    end
    TweenService:Create(Camera, TweenInfo.new(0.6), {FieldOfView = 70}):Play()
    CleanupSandiSounds()
    if originalGravity then
        Workspace.Gravity = originalGravity
        originalGravity = nil
    end
    for hum, speed in pairs(originalWalkSpeeds) do
        if hum and hum.Parent then hum.WalkSpeed = speed end
    end
    for hum, power in pairs(originalJumpPowers) do
        if hum and hum.Parent then hum.JumpPower = power end
    end
    for track, speed in pairs(originalAnimationSpeeds) do
        if track then track:AdjustSpeed(speed) end
    end
    for sound, speed in pairs(originalSoundSpeeds) do
        if sound and sound.Parent then sound.PlaybackSpeed = speed end
    end
    for velInst, vel in pairs(originalVelocityInstances) do
        if velInst and velInst.Parent then
            if velInst:IsA("BodyVelocity") then velInst.Velocity = vel
            elseif velInst:IsA("LinearVelocity") then velInst.VectorVelocity = vel end
        end
    end
    for _, conn in ipairs(animationConnections) do conn:Disconnect() end
    originalWalkSpeeds = {}
    originalJumpPowers = {}
    originalAnimationSpeeds = {}
    originalSoundSpeeds = {}
    originalVelocityInstances = {}
    animationConnections = {}
    originalStates = {}
    UpdateDashButton()
    UpdateKiroshiButton()
    UpdateOpticalButton()
    
    if State.MusicSound then
        State.MusicSound:Destroy()
        State.MusicSound = nil
    end
    local musicaGui = Player.PlayerGui:FindFirstChild("MusicaGUI")
    if musicaGui then
        musicaGui:Destroy()
    end
end

local function PlayActivationSequence()
    local textures = {
        "rbxassetid://84920149837951",
        "rbxassetid://138600197729943",
        "rbxassetid://91101401638106",
        "rbxassetid://136578715529335",
        "rbxassetid://132751511897004",
        "rbxassetid://135370243485541"
    }
    local fullSeq = {}
    for _, tex in ipairs(textures) do table.insert(fullSeq, tex) end
    for i = #textures - 1, 1, -1 do table.insert(fullSeq, textures[i]) end
    local gui = Player.PlayerGui:FindFirstChild("CyberRebuilt")
    if not gui then return end
    local overlay = Create("ImageLabel", {
        Name = "SandiTextureOverlay",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        ImageTransparency = 0.10,
        ZIndex = 100,
        Parent = gui
    })
    task.spawn(function()
        for _, tex in ipairs(fullSeq) do
            overlay.Image = tex
            task.wait(0.08)
        end
        TweenService:Create(overlay, TweenInfo.new(0.2), {ImageTransparency = 1}):Play()
        task.wait(0.2)
        overlay:Destroy()
    end)
end

local function ExecSandi()
    if os.clock() < State.Cooldowns.SANDI and not State.IsSandiActive then return end
    if State.IsSandiActive then
        ResetSandi()
        return
    end
    if State.Energy < Constants.ENERGY_COSTS.SANDI_ACTIVATE then return end
    
    if math.random() < Constants.SANDEVISTAN_FAILURE_CHANCE then
        TriggerSandevistanFailure()
        return
    end
    
    State.Energy -= Constants.ENERGY_COSTS.SANDI_ACTIVATE
    State.NoRegenUntil = os.clock() + Constants.REGEN_DELAY_USE
    State.IsSandiActive = true
    PlaySFX(Sounds.SANDI_ON)
    CamShake(1.5, 0.4)
    TweenService:Create(Camera, TweenInfo.new(0.4), {FieldOfView = 115}):Play()
    
    local sandiEffect = Create("ColorCorrectionEffect", {Name = "SandiEffect", TintColor = Color3.new(1,1,1), Contrast = 0, Saturation = 0, Parent = Lighting})
    TweenService:Create(sandiEffect, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TintColor = Colors.LIGHT_GREEN,
        Contrast = 0.15,
        Saturation = 0.3
    }):Play()
    
    PlayActivationSequence()
    
    lastSandiClone = 0
    
    originalGravity = Workspace.Gravity
    Workspace.Gravity = originalGravity * Configurations.SLOW_GRAVITY_MULTIPLIER
    originalWalkSpeeds = {}
    originalJumpPowers = {}
    originalAnimationSpeeds = {}
    originalSoundSpeeds = {}
    originalVelocityInstances = {}
    animationConnections = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player then
            local char = p.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    originalWalkSpeeds[hum] = hum.WalkSpeed
                    hum.WalkSpeed = hum.WalkSpeed * Constants.SLOW_FACTOR
                    originalJumpPowers[hum] = hum.JumpPower
                    hum.JumpPower = hum.JumpPower * Constants.SLOW_FACTOR
                    local animator = hum:FindFirstChild("Animator")
                    if animator then
                        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                            originalAnimationSpeeds[track] = track.Speed
                            track:AdjustSpeed(track.Speed * Constants.SLOW_FACTOR)
                        end
                        local conn = animator.AnimationPlayed:Connect(function(track)
                            originalAnimationSpeeds[track] = track.Speed / Constants.SLOW_FACTOR
                            track:AdjustSpeed(track.Speed * Constants.SLOW_FACTOR)
                        end)
                        table.insert(animationConnections, conn)
                    end
                end
                for _, sound in ipairs(char:GetDescendants()) do
                    if sound:IsA("Sound") and sound.Playing then
                        originalSoundSpeeds[sound] = sound.PlaybackSpeed
                        sound.PlaybackSpeed = sound.PlaybackSpeed * Constants.SLOW_FACTOR
                    end
                end
            end
        end
    end
    if Humanoid then
        originalPlayerJumpPower = Humanoid.JumpPower
        Humanoid.JumpPower = Humanoid.JumpPower / Constants.SLOW_FACTOR
    end
    for _, sound in ipairs(Workspace:GetDescendants()) do
        if sound:IsA("Sound") and sound.Playing and not sound:IsDescendantOf(Character) then
            originalSoundSpeeds[sound] = sound.PlaybackSpeed
            sound.PlaybackSpeed = sound.PlaybackSpeed * Constants.SLOW_FACTOR
        end
    end
    local soundConn = Workspace.DescendantAdded:Connect(function(desc)
        if desc:IsA("Sound") and not desc:IsDescendantOf(Character) then
            originalSoundSpeeds[desc] = desc.PlaybackSpeed
            desc.PlaybackSpeed = desc.PlaybackSpeed * Constants.SLOW_FACTOR
        end
    end)
    table.insert(animationConnections, soundConn)
    local playerAddedConn = Players.PlayerAdded:Connect(function(newPlayer)
        newPlayer.CharacterAdded:Connect(function(char)
            local hum = char:WaitForChild("Humanoid")
            originalWalkSpeeds[hum] = hum.WalkSpeed
            hum.WalkSpeed = hum.WalkSpeed * Constants.SLOW_FACTOR
            originalJumpPowers[hum] = hum.JumpPower
            hum.JumpPower = hum.JumpPower * Constants.SLOW_FACTOR
            local animator = hum:WaitForChild("Animator")
            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                originalAnimationSpeeds[track] = track.Speed
                track:AdjustSpeed(track.Speed * Constants.SLOW_FACTOR)
            end
            local conn = animator.AnimationPlayed:Connect(function(track)
                originalAnimationSpeeds[track] = track.Speed / Constants.SLOW_FACTOR
                track:AdjustSpeed(track.Speed * Constants.SLOW_FACTOR)
            end)
            table.insert(animationConnections, conn)
            for _, sound in ipairs(char:GetDescendants()) do
                if sound:IsA("Sound") and sound.Playing then
                    originalSoundSpeeds[sound] = sound.PlaybackSpeed
                    sound.PlaybackSpeed = sound.PlaybackSpeed * Constants.SLOW_FACTOR
                end
            end
        end)
    end)
    table.insert(animationConnections, playerAddedConn)
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BodyVelocity") then
            originalVelocityInstances[obj] = obj.Velocity
            obj.Velocity = obj.Velocity * Constants.SLOW_FACTOR
        elseif obj:IsA("LinearVelocity") then
            originalVelocityInstances[obj] = obj.VectorVelocity
            obj.VectorVelocity = obj.VectorVelocity * Constants.SLOW_FACTOR
        end
    end
    local velocityConn = Workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("BodyVelocity") then
            originalVelocityInstances[obj] = obj.Velocity
            obj.Velocity = obj.Velocity * Constants.SLOW_FACTOR
        elseif obj:IsA("LinearVelocity") then
            originalVelocityInstances[obj] = obj.VectorVelocity
            obj.VectorVelocity = obj.VectorVelocity * Constants.SLOW_FACTOR
        end
    end)
    table.insert(animationConnections, velocityConn)
    
    UpdateDashButton()
    UpdateKiroshiButton()
    UpdateOpticalButton()
    
    State.MusicSound = tocarMusica()
    criarGUI()
end

--// DASH ANTIGO (restaurado exatamente como estava no original)
local function ExecDash()
    if State.IsSandiActive then return end
    if State.Energy < Constants.ENERGY_COSTS.DASH or os.clock() < State.Cooldowns.DASH then return end
    State.Energy -= Constants.ENERGY_COSTS.DASH
    State.NoRegenUntil = os.clock() + Constants.REGEN_DELAY_USE
    State.Cooldowns.DASH = os.clock() + Constants.COOLDOWNS.DASH
    PlaySFX(Sounds.DASH)
    ShowCooldownText("Dash Impulse", Constants.COOLDOWNS.DASH, Colors.DASH_CYAN)
    local dashEffect = Create("ColorCorrectionEffect", {Name = "DashEffect", TintColor = Color3.new(1,1,1), Contrast = 0, Saturation = 0, Parent = Lighting})
    TweenService:Create(dashEffect, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TintColor = Colors.DASH_CYAN,
        Contrast = 0.1,
        Saturation = -0.1
    }):Play()
    TweenService:Create(Camera, TweenInfo.new(0.25), {FieldOfView = 125}):Play()
    local direction
    if Humanoid.FloorMaterial ~= Enum.Material.Air then
        local lookVector = HRP.CFrame.LookVector
        local moveDir = Humanoid.MoveDirection
        if moveDir:Dot(lookVector) < 0 then
            direction = -lookVector
        else
            direction = lookVector
        end
    else
        direction = Camera.CFrame.LookVector
    end
    local bv = Create("BodyVelocity", {MaxForce = Vector3.new(1e6, 1e6, 1e6), Velocity = direction * Constants.DASH_FORCE, Parent = HRP})
    Debris:AddItem(bv, 0.25)
    task.spawn(function()
        local start = os.clock()
        while os.clock() - start < 0.25 do
            CreateHologramClone(Constants.HOLOGRAM_CLONE.DASH.DELAY, Constants.HOLOGRAM_CLONE.DASH.DURATION, Constants.HOLOGRAM_CLONE.DASH.END_TRANSPARENCY, Constants.HOLOGRAM_CLONE.DASH.OFFSET_X, Constants.HOLOGRAM_CLONE.DASH.OFFSET_Y, Constants.HOLOGRAM_CLONE.DASH.OFFSET_Z, "dash")
            RunService.Heartbeat:Wait()
        end
        TweenService:Create(dashEffect, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TintColor = Color3.new(1,1,1), Contrast = 0, Saturation = 0}):Play()
        TweenService:Create(Camera, TweenInfo.new(0.4), {FieldOfView = 70}):Play()
        Debris:AddItem(dashEffect, 0.45)
    end)
end

local function ExecKiroshi()
    if State.IsSandiActive then return end
    if State.Energy < Constants.ENERGY_COSTS.KIROSHI or os.clock() < State.Cooldowns.KIROSHI or State.IsKiroshiActive then return end
    State.Energy -= Constants.ENERGY_COSTS.KIROSHI
    State.NoRegenUntil = os.clock() + Constants.REGEN_DELAY_USE
    State.IsKiroshiActive = true

    local kiroshiEffect = Create("ColorCorrectionEffect", {Name = "KiroshiEffect", TintColor = Color3.new(1,1,1), Contrast = 0, Saturation = 0, Parent = Lighting})
    TweenService:Create(kiroshiEffect, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TintColor = Colors.KIROSHI_TINT,
        Contrast = 0.1,
        Saturation = -0.1
    }):Play()

    for _, p in Players:GetPlayers() do
        if p ~= Player then
            local char = p.Character
            if char then
                local highlight = Create("Highlight", {
                    OutlineColor = Colors.KIROSHI,
                    FillTransparency = 1,
                    OutlineTransparency = 0,
                    Parent = char
                })
                table.insert(activeHighlights, highlight)
                
                local billboard = Create("BillboardGui", {
                    Size = UDim2.new(0, 200, 0, 80),
                    StudsOffset = Vector3.new(0, 3, 0),
                    AlwaysOnTop = true,
                    Parent = char
                })
                local hpLabel = Create("TextLabel", {
                    Size = UDim2.new(1, 0, 0.3, 0),
                    BackgroundTransparency = 1,
                    Text = "HP: 100/100",
                    TextColor3 = Color3.new(1,1,1),
                    Font = Enum.Font.Code,
                    TextSize = 18,
                    Parent = billboard
                })
                local distLabel = Create("TextLabel", {
                    Size = UDim2.new(1, 0, 0.3, 0),
                    Position = UDim2.new(0,0,0.3,0),
                    BackgroundTransparency = 1,
                    Text = "DIST: 10m",
                    TextColor3 = Colors.KIROSHI,
                    Font = Enum.Font.Code,
                    TextSize = 16,
                    Parent = billboard
                })
                table.insert(activeHighlights, billboard)
                
                task.spawn(function()
                    while State.IsKiroshiActive do
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if hum and HRP then
                            local dist = math.floor((HRP.Position - char.HumanoidRootPart.Position).Magnitude)
                            hpLabel.Text = string.format("HP: %d/%d", hum.Health, hum.MaxHealth)
                            distLabel.Text = string.format("DIST: %dm", dist)
                            if hum.Health / hum.MaxHealth < 0.5 then
                                hpLabel.TextColor3 = Color3.new(1, 0.2, 0.2)
                                hpLabel.Text = hpLabel.Text .. " [FRACO]"
                            end
                        end
                        task.wait(0.1)
                    end
                    billboard:Destroy()
                end)
            end
        end
    end

    task.spawn(function()
        task.wait(5)
        State.IsKiroshiActive = false
        State.Cooldowns.KIROSHI = os.clock() + Constants.COOLDOWNS.KIROSHI
        ShowCooldownText("Kiroshi Optics", Constants.COOLDOWNS.KIROSHI, Colors.KIROSHI)

        if kiroshiEffect then
            TweenService:Create(kiroshiEffect, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                TintColor = Color3.new(1,1,1),
                Contrast = 0,
                Saturation = 0
            }):Play()
            task.delay(0.5, function() kiroshiEffect:Destroy() end)
        end

        for _, h in ipairs(activeHighlights) do
            h:Destroy()
        end
        activeHighlights = {}
    end)
end

-- OPTICAL CAMUFLAGEM ATUALIZADO (exatamente como no script que você enviou - resto do código intacto)
local function ResetOptical()
    if not State.IsOpticalActive then return end
    
    opticalToken += 1
    
    State.IsOpticalActive = false
    deactivateInvisibility()
    State.Cooldowns.OPTICAL = os.clock() + Constants.COOLDOWNS.OPTICAL
    State.NoRegenUntil = os.clock() + Constants.REGEN_DELAY_USE
    
    ShowCooldownText("Camuflagem", Constants.COOLDOWNS.OPTICAL, Colors.OPTICAL)
end

local function ExecOptical()
    if State.IsSandiActive then return end
    
    if State.IsOpticalActive then
        ResetOptical()
        return
    end

    if os.clock() < State.Cooldowns.OPTICAL then return end
    
    if State.Energy < Constants.ENERGY_COSTS.OPTICAL then return end
    
    State.Energy -= Constants.ENERGY_COSTS.OPTICAL
    State.NoRegenUntil = os.clock() + Constants.REGEN_DELAY_USE
    State.IsOpticalActive = true
    
    activateInvisibility()

    opticalToken += 1
    local myToken = opticalToken
    
    task.delay(Constants.OPTICAL_DURATION, function()
        if myToken == opticalToken then
            ResetOptical()
        end
    end)
end

--// FUNÇÕES DE SET (mantidas intactas)
local function LimparAcessorios()
    local char = Player.Character
    if char then
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("Accessory") and (v.Name:find("SetItem_") or v:FindFirstChild("AutoWeldTag")) then
                v:Destroy()
            end
        end
    end
end

local function AplicarSet(listaIds)
    local character = Player.Character or Player.CharacterAdded:Wait()
    LimparAcessorios()

    for _, id in pairs(listaIds) do
        task.spawn(function()
            local sucesso, objects = pcall(function()
                return game:GetObjects("rbxassetid://" .. id)
            end)

            if sucesso and objects and objects[1] then
                local asset = objects[1]:Clone()
                asset.Name = "SetItem_" .. id
                
                local tag = Instance.new("BoolValue")
                tag.Name = "AutoWeldTag"
                tag.Parent = asset

                local handle = asset:IsA("BasePart") and asset or asset:FindFirstChild("Handle", true)

                if handle then
                    for _, v in pairs(asset:GetDescendants()) do
                        if v:IsA("LuaSourceContainer") then v:Destroy() end
                    end

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

--// SISTEMA DE UI
local function MakeDraggable(movable: Frame, hit: GuiObject)
    hit = hit or movable
    local dragging = false
    local dragStart, startPos
    local stroke = Create("UIStroke", {Color = Colors.UI_NEON, Thickness = 2, Transparency = 0.5, Enabled = false, Parent = movable})
    table.insert(UI_Elements, {Frame = movable, Stroke = stroke})
    
    hit.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and State.EditMode then
            dragging = true
            dragStart = input.Position
            startPos = movable.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if dragging and State.EditMode then
                local delta = input.Position - dragStart
                movable.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end
    end)
    UserInputService.InputEnded:Connect(function(input) 
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
            dragging = false
        end
    end)
end

local function BuildUI()
    if Player.PlayerGui:FindFirstChild("CyberRebuilt") then Player.PlayerGui.CyberRebuilt:Destroy() end
    local gui = Create("ScreenGui", {Name = "CyberRebuilt", Parent = Player.PlayerGui, IgnoreGuiInset = true})
    
    local lockBtn = Create("TextButton", {
        Name = "LockBtn",
        Size = ButtonConfigs.LockBtn.Size,
        Position = ButtonConfigs.LockBtn.Position,
        Text = ButtonConfigs.LockBtn.Text,
        BackgroundColor3 = ButtonConfigs.LockBtn.BackgroundColor3,
        TextColor3 = ButtonConfigs.LockBtn.TextColor3,
        Font = ButtonConfigs.LockBtn.Font,
        TextSize = ButtonConfigs.LockBtn.TextSize,
        Parent = gui
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = lockBtn})
    Create("UIStroke", {Color = Colors.UI_NEON, Thickness = 2, Transparency = 0.4, Parent = lockBtn})
    local gradientLock = Create("UIGradient", {Color = ColorSequence.new(Colors.UI_DARK, Colors.UI_NEON), Rotation = 45, Parent = lockBtn})
    
    local energyContainer = Create("Frame", {
        Name = "EnergyContainer",
        Size = ButtonConfigs.EnergyContainer.Size,
        Position = savedPositions["EnergyContainer"] or ButtonConfigs.EnergyContainer.Position,
        BackgroundColor3 = Colors.UI_DARK,
        BorderSizePixel = 0,
        Parent = gui
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = energyContainer})
    Create("UIStroke", {Color = Colors.UI_NEON, Thickness = 1.5, Transparency = 0.5, Parent = energyContainer})
    
    local fill = Create("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Colors.ENERGY_FULL, BorderSizePixel = 0, Parent = energyContainer})
    Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = fill})
    local energyGradient = Create("UIGradient", {Color = ColorSequence.new(Colors.ENERGY_LOW, Colors.ENERGY_FULL), Rotation = 0, Parent = fill})
    
    local energyLabel = Create("TextLabel", {Size = UDim2.new(1, 0, 0, 25), Position = UDim2.new(0, 0, -1.5, 0), BackgroundTransparency = 1, Text = "SYSTEM ENERGY: 100%", TextColor3 = Colors.UI_NEON, Font = Enum.Font.SciFi, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Parent = energyContainer})
    
    local function CreateSkillBtn(key, color, pos, name, func)
        local btnContainer = Create("Frame", {Name = name .. "Container", Size = UDim2.new(0, 45, 0, 45), Position = savedPositions[name] or pos, BackgroundTransparency = 1, Parent = gui})
        local btn = Create("TextButton", {Name = name, Size = UDim2.new(1, 0, 1, 0), Text = key, BackgroundColor3 = Colors.UI_DARK, TextColor3 = color, Font = Enum.Font.SciFi, TextSize = 16, AutoButtonColor = false, Parent = btnContainer})
        local stroke = Create("UIStroke", {Color = color, Thickness = 2.5, Transparency = 0.4, Parent = btn})
        Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = btn})
        local gradient = Create("UIGradient", {Color = ColorSequence.new(Colors.UI_DARK, color:Lerp(Colors.UI_NEON, 0.3)), Rotation = 45, Parent = btn})
        
        local glow = Create("UIStroke", {Color = Colors.UI_GLOW, Thickness = 3, Transparency = 0.8, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = btn})
        
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = color:Lerp(Colors.UI_NEON, 0.2)}):Play()
            TweenService:Create(glow, TweenInfo.new(0.2), {Transparency = 0.5}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Colors.UI_DARK}):Play()
            TweenService:Create(glow, TweenInfo.new(0.2), {Transparency = 0.8}):Play()
        end)
        
        btn.MouseButton1Down:Connect(function()
            if not State.EditMode then
                TweenService:Create(btn, TweenInfo.new(0.1, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {Size = UDim2.new(0.9, 0, 0.9, 0), BackgroundColor3 = color, TextColor3 = Colors.UI_DARK}):Play()
                TweenService:Create(stroke, TweenInfo.new(0.1), {Transparency = 0}):Play()
                func()
            end
        end)
        btn.MouseButton1Up:Connect(function()
            if not State.EditMode then
                TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Bounce, Enum.EasingDirection.In), {Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Colors.UI_DARK, TextColor3 = color}):Play()
                TweenService:Create(stroke, TweenInfo.new(0.2), {Transparency = 0.4}):Play()
            end
        end)
        
        TweenService:Create(btn, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Rotation = 3}):Play()
        
        MakeDraggable(btnContainer, btn)
        SkillContainers[name] = btnContainer
        if name == "SandiBtn" then
            task.spawn(function()
                while btn.Parent do
                    local hue = (os.clock() % 5) / 5
                    local rainbowColor = Color3.fromHSV(hue, 1, 1)
                    btn.TextColor3 = rainbowColor
                    stroke.Color = rainbowColor
                    gradient.Color = ColorSequence.new(Colors.UI_DARK, rainbowColor)
                    task.wait()
                end
            end)
        end
        return btn
    end
    
    CreateSkillBtn(ButtonConfigs.DashBtn.Key, ButtonConfigs.DashBtn.Color, ButtonConfigs.DashBtn.Position, "DashBtn", ExecDash)
    CreateSkillBtn(ButtonConfigs.SandiBtn.Key, ButtonConfigs.SandiBtn.Color, ButtonConfigs.SandiBtn.Position, "SandiBtn", ExecSandi)
    CreateSkillBtn(ButtonConfigs.KiroshiBtn.Key, ButtonConfigs.KiroshiBtn.Color, ButtonConfigs.KiroshiBtn.Position, "KiroshiBtn", ExecKiroshi)
    CreateSkillBtn(ButtonConfigs.OpticalBtn.Key, ButtonConfigs.OpticalBtn.Color, ButtonConfigs.OpticalBtn.Position, "OpticalBtn", ExecOptical)
    CreateSkillBtn(ButtonConfigs.DodgeBtn.Key, ButtonConfigs.DodgeBtn.Color, ButtonConfigs.DodgeBtn.Position, "DodgeBtn", ActivateDodgeReady)
    
    -- NOVO: Botão Settings fixo + Menu com Scroll (exatamente como pedido)
    local settingsBtn = Create("TextButton", {
        Name = "SettingsBtn",
        Size = UDim2.new(0, 40, 0, 40),
        Position = UDim2.new(0, 20, 0, 100),
        BackgroundColor3 = Colors.UI_DARK,
        TextColor3 = Colors.UI_NEON,
        Font = Enum.Font.SciFi,
        TextSize = 26,
        Text = "⚒︎",
        Parent = gui
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = settingsBtn})
    Create("UIStroke", {Color = Colors.UI_NEON, Thickness = 2, Transparency = 0.4, Parent = settingsBtn})
    local gradientSettings = Create("UIGradient", {Color = ColorSequence.new(Colors.UI_DARK, Colors.UI_NEON), Rotation = 45, Parent = settingsBtn})

    local settingsMenu = Create("Frame", {
        Name = "SettingsMenu",
        Size = UDim2.new(0, 320, 0, 460),
        Position = UDim2.new(0, 75, 0, 30),
        BackgroundColor3 = Colors.UI_DARK,
        Visible = false,
        BorderSizePixel = 0,
        Parent = gui
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 14), Parent = settingsMenu})
    Create("UIStroke", {Color = Colors.UI_NEON, Thickness = 3, Parent = settingsMenu})

    local title = Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundTransparency = 1,
        Text = "SETTINGS",
        TextColor3 = Colors.UI_NEON,
        Font = Enum.Font.SciFi,
        TextSize = 28,
        Parent = settingsMenu
    })

    local scroll = Create("ScrollingFrame", {
        Name = "AbilitiesScroll",
        Size = UDim2.new(1, -20, 1, -130),
        Position = UDim2.new(0, 10, 0, 60),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 8,
        ScrollBarImageColor3 = Colors.UI_NEON,
        Parent = settingsMenu
    })
    Create("UIListLayout", {Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder, Parent = scroll})

    local abilitiesList = {
        {display = "DASH IMPULSE", key = "Dash", color = Colors.DASH_CYAN},
        {display = "SANDEVISTAN", key = "Sandi", color = Colors.SANDI_TINT},
        {display = "KIROSHI OPTICS", key = "Kiroshi", color = Colors.KIROSHI},
        {display = "OPTICAL CAMO", key = "Optical", color = Colors.OPTICAL},
        {display = "NEURAL DODGE", key = "Dodge", color = Colors.DODGE_START}
    }

    for _, ab in ipairs(abilitiesList) do
        local row = Create("Frame", {
            Size = UDim2.new(1, 0, 0, 52),
            BackgroundColor3 = Colors.UI_BG,
            BorderSizePixel = 0,
            Parent = scroll
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = row})

        Create("TextLabel", {
            Size = UDim2.new(0.65, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "  " .. ab.display,
            TextColor3 = ab.color,
            Font = Enum.Font.SciFi,
            TextSize = 19,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = row
        })

        local tog = Create("TextButton", {
            Size = UDim2.new(0.28, 0, 0.75, 0),
            Position = UDim2.new(0.69, 0, 0.125, 0),
            Text = EnabledAbilities[ab.key] and "ON" or "OFF",
            BackgroundColor3 = EnabledAbilities[ab.key] and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(200, 40, 40),
            TextColor3 = Color3.new(1,1,1),
            Font = Enum.Font.SciFi,
            TextSize = 17,
            Parent = row
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = tog})

        tog.MouseButton1Click:Connect(function()
            EnabledAbilities[ab.key] = not EnabledAbilities[ab.key]
            tog.Text = EnabledAbilities[ab.key] and "ON" or "OFF"
            tog.BackgroundColor3 = EnabledAbilities[ab.key] and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(200, 40, 40)
            
            if ab.key == "Dodge" and not EnabledAbilities.Dodge then
                State.IsDodgeReady = false
            end
            
            local btnName = AbilityMap[ab.key]
            if btnName and SkillContainers[btnName] then
                local visible = EnabledAbilities[ab.key]
                if btnName == "DodgeBtn" then
                    visible = visible and DodgeMode == "Counter"
                end
                SkillContainers[btnName].Visible = visible
            end
        end)
    end

    --// NOVO: DODGE MODE SELECTOR (Modo 1 Counter / Modo 2 Auto)
    local modeRow = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 52),
        BackgroundColor3 = Colors.UI_BG,
        BorderSizePixel = 0,
        Parent = scroll
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = modeRow})

    Create("TextLabel", {
        Size = UDim2.new(0.65, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "  DODGE MODE",
        TextColor3 = Colors.DODGE_START,
        Font = Enum.Font.SciFi,
        TextSize = 19,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = modeRow
    })

    local modeToggle = Create("TextButton", {
        Size = UDim2.new(0.28, 0, 0.75, 0),
        Position = UDim2.new(0.69, 0, 0.125, 0),
        Text = DodgeMode == "Counter" and "COUNTER" or "AUTO",
        BackgroundColor3 = DodgeMode == "Counter" and Color3.fromRGB(255, 165, 0) or Color3.fromRGB(0, 255, 255),
        TextColor3 = Color3.new(1,1,1),
        Font = Enum.Font.SciFi,
        TextSize = 17,
        Parent = modeRow
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = modeToggle})

    modeToggle.MouseButton1Click:Connect(function()
        if DodgeMode == "Counter" then
            DodgeMode = "Auto"
            modeToggle.Text = "AUTO"
            modeToggle.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
        else
            DodgeMode = "Counter"
            modeToggle.Text = "COUNTER"
            modeToggle.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
        end
        -- Atualiza visibilidade do botão Dodge
        if SkillContainers["DodgeBtn"] then
            SkillContainers["DodgeBtn"].Visible = (EnabledAbilities.Dodge and DodgeMode == "Counter")
        end
    end)

    -- Sets movido para dentro do menu (exatamente como pedido)
    local setsRow = Create("Frame", {Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1, Parent = scroll})
    local setsBtn = Create("TextButton", {
        Size = UDim2.new(0.9, 0, 0, 48),
        Position = UDim2.new(0.05, 0, 0, 6),
        Text = "⇌ TROCA SET",
        BackgroundColor3 = setColors[currentSet],
        TextColor3 = Colors.UI_NEON,
        Font = Enum.Font.SciFi,
        TextSize = 20,
        Parent = setsRow
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = setsBtn})
    Create("UIStroke", {Color = Colors.UI_NEON, Thickness = 2, Parent = setsBtn})

    setsBtn.MouseButton1Click:Connect(function()
        if currentSet == 1 then
            currentSet = 2
            setsBtn.BackgroundColor3 = setColors[2]
            AplicarSet(SET_2)
        else
            currentSet = 1
            setsBtn.BackgroundColor3 = setColors[1]
            AplicarSet(SET_1)
        end
    end)

    scroll.CanvasSize = UDim2.new(0, 0, 0, scroll.UIListLayout.AbsoluteContentSize.Y + 150)

    settingsBtn.MouseButton1Click:Connect(function()
        settingsMenu.Visible = not settingsMenu.Visible
    end)

    MakeDraggable(energyContainer, energyContainer)
    -- LockBtn e SettingsBtn fixos (sem draggable para ficarem fixos na esquerda)
    lockBtn.MouseButton1Click:Connect(function()
        State.EditMode = not State.EditMode
        lockBtn.BackgroundColor3 = State.EditMode and Colors.EDIT_MODE or Colors.UI_DARK
        lockBtn.TextColor3 = State.EditMode and Colors.UI_DARK or Colors.UI_NEON
        for _, item in ipairs(UI_Elements) do item.Stroke.Enabled = State.EditMode end
        if not State.EditMode then
            savedPositions["EnergyContainer"] = energyContainer.Position
            savedPositions["DashBtn"] = gui:FindFirstChild("DashBtnContainer").Position
            savedPositions["SandiBtn"] = gui:FindFirstChild("SandiBtnContainer").Position
            savedPositions["KiroshiBtn"] = gui:FindFirstChild("KiroshiBtnContainer").Position
            savedPositions["OpticalBtn"] = gui:FindFirstChild("OpticalBtnContainer").Position
            savedPositions["DodgeBtn"] = gui:FindFirstChild("DodgeBtnContainer").Position
        end
    end)
    
    UpdateDashButton()
    UpdateKiroshiButton()
    UpdateOpticalButton()
    
    -- Inicializa visibilidade do botão Dodge conforme modo atual
    if SkillContainers["DodgeBtn"] then
        SkillContainers["DodgeBtn"].Visible = (EnabledAbilities.Dodge and DodgeMode == "Counter")
    end
    
    local rsConn
    rsConn = RunService.RenderStepped:Connect(function()
        local percent = State.Energy / Constants.MAX_ENERGY

        fill.Size = fill.Size:Lerp(UDim2.new(percent, 0, 1, 0), 0.1)

        local energyColor

        if percent > 0.5 then
            energyColor = Colors.ENERGY_MEDIUM:Lerp(Colors.ENERGY_FULL, (percent - 0.5) * 2)
        else
            energyColor = Colors.ENERGY_LOW:Lerp(Colors.ENERGY_MEDIUM, percent * 2)
        end

        fill.BackgroundColor3 = energyColor
        energyLabel.TextColor3 = energyColor
        energyLabel.Text = string.format("SYSTEM ENERGY: %d%%", math.clamp(math.floor(State.Energy), 0, 100))
    end)

    gui.AncestryChanged:Connect(function()
        if not gui.Parent then
            rsConn:Disconnect()
        end
    end)

end

--// EFEITO DE CAMINHADA
local function InitWalkEffect()
    RunService.RenderStepped:Connect(function()
        local CT = tick()
        
        if Humanoid.MoveDirection.Magnitude > 0 then
            local BobbleX = math.cos(CT*5)*0.25
            local BobbleY = math.abs(math.sin(CT*5))*0.25
            local Bobble = Vector3.new(BobbleX,BobbleY,0)
            Humanoid.CameraOffset = Humanoid.CameraOffset:lerp(Bobble, 0.25)
        else
            Humanoid.CameraOffset = Humanoid.CameraOffset * 0.75
        end
    end)
end

--// MOVIMENTO DIRECIONAL
local Joints = {}
local JointsC0 = {}
local JointTilts = {}
local DefaultLerpAlpha = 0.145
local dotThreshold = 0.9
local lastTime = 0
local tickRate = 1 / 60

local function LerpJoints(moveDirection, angles)
    JointTilts.RootJointTilt = JointTilts.RootJointTilt:Lerp(CFrame.Angles(unpack(angles.RootJoint)), DefaultLerpAlpha)
    Joints.RootJoint.C0 = JointsC0.RootJointC0 * JointTilts.RootJointTilt
    
    JointTilts.NeckTilt = JointTilts.NeckTilt:Lerp(CFrame.Angles(unpack(angles.Neck)), DefaultLerpAlpha)
    Joints.Neck.C0 = JointsC0.NeckC0 * JointTilts.NeckTilt
    
    JointTilts.RightShoulderTilt = JointTilts.RightShoulderTilt:Lerp(CFrame.Angles(unpack(angles.RightShoulder)), DefaultLerpAlpha)
    Joints.RightShoulder.C0 = JointsC0.RightShoulderC0 * JointTilts.RightShoulderTilt
    
    JointTilts.LeftShoulderTilt = JointTilts.LeftShoulderTilt:Lerp(CFrame.Angles(unpack(angles.LeftShoulder)), DefaultLerpAlpha)
    Joints.LeftShoulder.C0 = JointsC0.LeftShoulderC0 * JointTilts.LeftShoulderTilt
    
    JointTilts.RightHipTilt = JointTilts.RightHipTilt:Lerp(CFrame.Angles(unpack(angles.RightHip)), DefaultLerpAlpha)
    Joints.RightHip.C0 = JointsC0.RightHipC0 * JointTilts.RightHipTilt
    
    JointTilts.LeftHipTilt = JointTilts.LeftHipTilt:Lerp(CFrame.Angles(unpack(angles.LeftHip)), DefaultLerpAlpha)
    Joints.LeftHip.C0 = JointsC0.LeftHipC0 * JointTilts.LeftHipTilt
end

local function UpdateDirectionalMovement(deltaTime)
    local now = workspace:GetServerTimeNow()
    if now - lastTime >= tickRate then
        lastTime = now
        
        local moveDirection = HRP.CFrame:VectorToObjectSpace(Humanoid.MoveDirection)
        
        if moveDirection:Dot(Vector3.new(1,0,-1).Unit) > dotThreshold then
            LerpJoints(moveDirection, {
            RootJoint = {math.rad(-moveDirection.Z) * 5, 0, math.rad(-moveDirection.X) * 25},
            Neck = {math.rad(moveDirection.Z) * 5, 0, math.rad(moveDirection.X) * 15},
            RightShoulder = {0, math.rad(-moveDirection.X) * 10, 0},
            LeftShoulder = {0, math.rad(-moveDirection.X) * 10, 0},
            RightHip = {0, math.rad(-moveDirection.X) * 10, 0},
            LeftHip = {0, math.rad(-moveDirection.X) * 10, 0}
            })
        elseif moveDirection:Dot(Vector3.new(1,0,1).Unit) > dotThreshold then
            LerpJoints(moveDirection, {
            RootJoint = {math.rad(-moveDirection.Z) * 5, 0, math.rad(moveDirection.X) * 25},
            Neck = {math.rad(moveDirection.Z) * 5, 0, math.rad(-moveDirection.X) * 25},
            RightShoulder = {0, math.rad(moveDirection.X) * 10, 0},
            LeftShoulder = {0, math.rad(moveDirection.X) * 10, 0},
            RightHip = {0, math.rad(moveDirection.X) * 10, 0},
            LeftHip = {0, math.rad(moveDirection.X) * 10, 0}
            })
        elseif moveDirection:Dot(Vector3.new(-1,0,1).Unit) > dotThreshold then
            LerpJoints(moveDirection, {
            RootJoint = {math.rad(-moveDirection.Z) * 5, 0, math.rad(moveDirection.X) * 25},
            Neck = {math.rad(moveDirection.Z) * 5, 0, math.rad(-moveDirection.X) * 25},
            RightShoulder = {0, math.rad(moveDirection.X) * 10, 0},
            LeftShoulder = {0, math.rad(moveDirection.X) * 10, 0},
            RightHip = {0, math.rad(moveDirection.X) * 10, 0},
            LeftHip = {0, math.rad(moveDirection.X) * 10, 0}
            })
        elseif moveDirection:Dot(Vector3.new(-1,0,-1).Unit) > dotThreshold then
            LerpJoints(moveDirection, {
            RootJoint = {math.rad(-moveDirection.Z) * 5, 0, math.rad(-moveDirection.X) * 25},
            Neck = {math.rad(moveDirection.Z) * 5, 0, math.rad(moveDirection.X) * 15},
            RightShoulder = {0, math.rad(-moveDirection.X) * 10, 0},
            LeftShoulder = {0, math.rad(-moveDirection.X) * 10, 0},
            RightHip = {0, math.rad(-moveDirection.X) * 10, 0},
            LeftHip = {0, math.rad(-moveDirection.X) * 10, 0}
            })
        elseif moveDirection:Dot(Vector3.new(0,0,-1).Unit) > dotThreshold then
            LerpJoints(moveDirection, {
            RootJoint = {math.rad(-moveDirection.Z) * 10, 0, 0},
            Neck = {math.rad(moveDirection.Z) * 10, 0, 0},
            RightShoulder = {0, 0, 0},
            LeftShoulder = {0, 0, 0},
            RightHip = {0, 0, 0},
            LeftHip = {0, 0, 0}
            })
        elseif moveDirection:Dot(Vector3.new(1,0,0).Unit) > dotThreshold then
            LerpJoints(moveDirection, {
            RootJoint = {0, 0, math.rad(-moveDirection.X) * 35},
            Neck = {0, 0, math.rad(moveDirection.X) * 35},
            RightShoulder = {0, math.rad(-moveDirection.X) * 15, 0},
            LeftShoulder = {0, math.rad(-moveDirection.X) * 15, 0},
            RightHip = {0, math.rad(-moveDirection.X) * 15, 0},
            LeftHip = {0, math.rad(-moveDirection.X) * 15, 0}
            })
        elseif moveDirection:Dot(Vector3.new(0,0,1).Unit) > dotThreshold then
            LerpJoints(moveDirection, {
            RootJoint = {math.rad(-moveDirection.Z) * 10, 0, 0},
            Neck = {math.rad(moveDirection.Z) * 10, 0, 0},
            RightShoulder = {0, 0, 0},
            LeftShoulder = {0, 0, 0},
            RightHip = {0, 0, 0},
            LeftHip = {0, 0, 0}
            })
        elseif moveDirection:Dot(Vector3.new(-1,0,0).Unit) > dotThreshold then
            LerpJoints(moveDirection, {
            RootJoint = {0, 0, math.rad(-moveDirection.X) * 35},
            Neck = {0, 0, math.rad(moveDirection.X) * 35},
            RightShoulder = {0, math.rad(-moveDirection.X) * 15, 0},
            LeftShoulder = {0, math.rad(-moveDirection.X) * 15, 0},
            RightHip = {0, math.rad(-moveDirection.X) * 15, 0},
            LeftHip = {0, math.rad(-moveDirection.X) * 15, 0}
            })
        else
            LerpJoints(moveDirection, {
            RootJoint = {0, 0, 0},
            Neck = {0, 0, 0},
            RightShoulder = {0, 0, 0},
            LeftShoulder = {0, 0, 0},
            RightHip = {0, 0, 0},
            LeftHip = {0, 0, 0}
            })
        end
    end
end

local function InitDirectionalMovement()
    local torso = Character:FindFirstChild("Torso") or Character:FindFirstChild("UpperTorso")

    Joints = {
        RootJoint = HRP:WaitForChild("RootJoint"),
        Neck = torso:WaitForChild("Neck"),
        RightShoulder = torso:WaitForChild("Right Shoulder"),
        LeftShoulder = torso:WaitForChild("Left Shoulder"),
        RightHip = torso:WaitForChild("Right Hip"),
        LeftHip = torso:WaitForChild("Left Hip")
    }

    JointsC0 = {
        RootJointC0 = Joints.RootJoint.C0,
        NeckC0 = Joints.Neck.C0,
        RightShoulderC0 = Joints.RightShoulder.C0,
        LeftShoulderC0 = Joints.LeftShoulder.C0,
        RightHipC0 = Joints.RightHip.C0,
        LeftHipC0 = Joints.LeftHip.C0
    }

    JointTilts = {
        RootJointTilt = CFrame.new(),
        NeckTilt = CFrame.new(),
        RightShoulderTilt = CFrame.new(),
        LeftShoulderTilt = CFrame.new(),
        RightHipTilt = CFrame.new(),
        LeftHipTilt = CFrame.new()
    }

    RunService.Heartbeat:Connect(UpdateDirectionalMovement)
end

--// LOOP PRINCIPAL
RunService.Heartbeat:Connect(function(dt)
    if not HRP or not Humanoid then return end
    if Humanoid.Health < State.LastHealth then
        local dmgDealt = State.LastHealth - Humanoid.Health
        if dmgDealt > 1 and State.IsDodgeReady and EnabledAbilities.Dodge then
            local ca = nil
            local ld = 25
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Humanoid") and obj.Parent ~= Character then
                    local r = obj.Parent:FindFirstChild("HumanoidRootPart")
                    if r and (HRP.Position - r.Position).Magnitude < ld then 
                        ld = (HRP.Position - r.Position).Magnitude
                        ca = r 
                    end
                end
            end
            
            ExecDodge(ca)
            
            -- Nova lógica: energia só é gasta no uso real
            if DodgeMode == "Auto" then
                if State.Energy >= Constants.ENERGY_COSTS.DODGE then
                    State.Energy -= Constants.ENERGY_COSTS.DODGE
                    State.NoRegenUntil = os.clock() + Constants.REGEN_DELAY_USE
                end
            end
            
            State.IsDodgeReady = false
            State.Cooldowns.DODGE = os.clock() + Constants.COOLDOWNS.DODGE
            ShowCooldownText("Neural Dodge", Constants.COOLDOWNS.DODGE, Colors.DODGE_END)
        end
    end
    State.LastHealth = Humanoid.Health
    State.LastVelocityY = HRP.Velocity.Y
    local isMoving = HRP.Velocity.Magnitude > Constants.MOVING_THRESHOLD
    if State.IsSandiActive then
        State.Energy -= Constants.ENERGY_COSTS.SANDI_DRAIN * dt
        Humanoid.WalkSpeed = Constants.SANDI_SPEED
        
        if isMoving then
            idleTime = 0
            if idleSound and idleSound.Playing then
                idleSound:Stop()
            end
            if os.clock() - lastSandiClone > Constants.HOLOGRAM_CLONE.SANDI.DELAY then
                CreateHologramClone(Constants.HOLOGRAM_CLONE.SANDI.DELAY, Constants.HOLOGRAM_CLONE.SANDI.DURATION, Constants.HOLOGRAM_CLONE.SANDI.END_TRANSPARENCY, Constants.HOLOGRAM_CLONE.SANDI.OFFSET_X, Constants.HOLOGRAM_CLONE.SANDI.OFFSET_Y, Constants.HOLOGRAM_CLONE.SANDI.OFFSET_Z, "sandi")
                lastSandiClone = os.clock()
            end
            if sandiLoopSound and not sandiLoopSound.Playing then
                sandiLoopSound:Play()
            elseif not sandiLoopSound then
                sandiLoopSound = Create("Sound", {
                    SoundId = Sounds.SANDI_LOOP.id,
                    Volume = Sounds.SANDI_LOOP.volume,
                    PlaybackSpeed = Sounds.SANDI_LOOP.pitch,
                    Looped = Sounds.SANDI_LOOP.looped,
                    Parent = HRP
                })
                sandiLoopSound:Play()
            end
        else
            idleTime += dt
            if idleTime >= 60 then
                if not idleSound or not idleSound.Playing then
                    idleSound = Create("Sound", {
                        SoundId = Sounds.IDLE_MUSIC.id,
                        Volume = Sounds.IDLE_MUSIC.volume,
                        PlaybackSpeed = Sounds.IDLE_MUSIC.pitch,
                        Looped = Sounds.IDLE_MUSIC.looped,
                        Parent = HRP
                    })
                    idleSound:Play()
                end
            end
            if sandiLoopSound and sandiLoopSound.Playing then
                sandiLoopSound:Stop()
            end
        end
        
        if State.Energy <= 0 then
            State.NoRegenUntil = os.clock() + Constants.REGEN_DELAY_ZERO
            local luck = math.random(1, 100)
            if luck <= 30 then
                ExecCyberpsychosis()
            end
            ResetSandi()
        end
    else
        if os.clock() > State.NoRegenUntil then
            State.Energy = math.min(Constants.MAX_ENERGY, State.Energy + (Constants.REGEN_RATE * dt))
        end
    end

    --// AUTO DODGE MODE (Modo Automático - agora permanente até uso)
    if DodgeMode == "Auto" 
       and os.clock() >= State.Cooldowns.DODGE 
       and not State.IsDodgeReady 
       and State.Energy >= Constants.ENERGY_COSTS.DODGE
       and EnabledAbilities.Dodge then
        ActivateDodgeReady()
    end
end)

local KeyActions = {
    [Enum.KeyCode.Q] = ExecDash,
    [Enum.KeyCode.E] = ExecSandi,
    [Enum.KeyCode.K] = ExecKiroshi,
    [Enum.KeyCode.O] = ExecOptical,
}

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    
    if input.KeyCode == Enum.KeyCode.N then
        if DodgeMode == "Counter" and EnabledAbilities.Dodge then
            ActivateDodgeReady()
        end
        return
    end
    
    local action = KeyActions[input.KeyCode]
    
    if action then
        action()
    end
end)

local function GetOrCreateEffect(className, props)
    local effect = Lighting:FindFirstChild(className)
    if not effect then
        effect = Instance.new(className)
        effect.Parent = Lighting
    end

    for k, v in pairs(props) do
        effect[k] = v
    end

    return effect
end

local function InitVisualEffects()
    GetOrCreateEffect("BloomEffect", {
        Intensity = 0.5,
        Size = 20,
        Threshold = 1
    })

    GetOrCreateEffect("SunRaysEffect", {
        Intensity = 0.2,
        Spread = 0.5
    })

    GetOrCreateEffect("BlurEffect", {
        Size = 2
    })

    GetOrCreateEffect("ColorCorrectionEffect", {
        Contrast = 0.1,
        Saturation = 0.2
    })
end

local function SetupCharacter(character)
    ResetSandi()
    ResetOptical()
    CleanupSandiSounds()

    Character = character
    HRP = character:WaitForChild("HumanoidRootPart")
    Humanoid = character:WaitForChild("Humanoid")

    State.LastHealth = Humanoid.Health

    BuildUI()
    InitWalkEffect()
    InitDirectionalMovement()
end

local function Init()
    InitVisualEffects()

    if Player.Character then
        SetupCharacter(Player.Character)
    end

    Player.CharacterAdded:Connect(SetupCharacter)
end

Init()

--// FUNÇÕES DE SET (mantidas intactas - defs movidas para cima para o botão funcionar, aqui só os connects)
Player.CharacterAdded:Connect(function()
    task.wait(2)
    if currentSet == 1 then AplicarSet(SET_1) else AplicarSet(SET_2) end
end)

AplicarSet(SET_1)
