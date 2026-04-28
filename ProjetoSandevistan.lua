local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")
local ContextActionService = game:GetService("ContextActionService")
local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Character, HRP, Humanoid

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
    LastHealth: number,
    NoRegenUntil: number,
    MusicSound: Sound?
}

local Constants = {
    MAX_ENERGY = 100,
    SANDI_SPEED = 67,
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
        SANDI = {DELAY = 0.075, DURATION = 3, END_TRANSPARENCY = 1},
        DASH = {DELAY = 0.07, DURATION = 0.35, END_TRANSPARENCY = 0.9},
        DODGE = {DELAY = 0.2, DURATION = 0.5, END_TRANSPARENCY = 0.9}
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
        NORMAL_DISTANCE_NO_ENEMY = 12,
        NORMAL_DISTANCE_ENEMY = 6
    },
    SANDEVISTAN_FAILURE_CHANCE = 0.3,
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

local Configurations = {
    SLOW_GRAVITY_MULTIPLIER = Constants.SLOW_FACTOR ^ 2,
    HOLOGRAM_MATERIAL = Enum.Material.Glass,
    ASSETS = {
        TEXTURES = {
            SPARKS = "rbxassetid://6071575297",
            CRACK1 = "rbxassetid://1439194003",
            CRACK2 = "rbxassetid://1439194003"
        }
    },
    HOLOGRAM_PRESERVE = {
        ACCESSORIES = true,
        HAIR = true,
        FACE = false
    }
}

local Colors = {
    SANDI_TINT = Color3.fromRGB(175, 255, 190),
    LIGHT_GREEN = Color3.fromRGB(105, 255, 140),
    DASH_GREEN = Color3.fromRGB(105, 255, 140),
    KIROSHI_RED = Color3.fromRGB(200, 50, 70),
    DODGE_LIME = Color3.fromRGB(200, 255, 200),
    RAINBOW_SEQUENCE = {
        Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 8, 0), Color3.fromRGB(255, 15, 0), Color3.fromRGB(255, 23, 0), Color3.fromRGB(255, 31, 0),
        Color3.fromRGB(255, 38, 0), Color3.fromRGB(255, 46, 0), Color3.fromRGB(255, 54, 0), Color3.fromRGB(255, 61, 0), Color3.fromRGB(255, 69, 0),
        Color3.fromRGB(255, 77, 0), Color3.fromRGB(255, 84, 0), Color3.fromRGB(255, 92, 0), Color3.fromRGB(255, 99, 0), Color3.fromRGB(255, 107, 0),
        Color3.fromRGB(255, 115, 0), Color3.fromRGB(255, 122, 0), Color3.fromRGB(255, 130, 0), Color3.fromRGB(255, 138, 0), Color3.fromRGB(255, 145, 0),
        Color3.fromRGB(255, 153, 0), Color3.fromRGB(255, 161, 0), Color3.fromRGB(255, 168, 0), Color3.fromRGB(255, 176, 0), Color3.fromRGB(255, 184, 0),
        Color3.fromRGB(255, 191, 0), Color3.fromRGB(255, 199, 0), Color3.fromRGB(255, 207, 0), Color3.fromRGB(255, 214, 0), Color3.fromRGB(255, 222, 0),
        Color3.fromRGB(255, 230, 0), Color3.fromRGB(255, 237, 0), Color3.fromRGB(255, 245, 0), Color3.fromRGB(255, 252, 0), Color3.fromRGB(250, 255, 0),
        Color3.fromRGB(242, 255, 0), Color3.fromRGB(235, 255, 0), Color3.fromRGB(227, 255, 0), Color3.fromRGB(219, 255, 0), Color3.fromRGB(212, 255, 0),
        Color3.fromRGB(204, 255, 0), Color3.fromRGB(196, 255, 0), Color3.fromRGB(189, 255, 0), Color3.fromRGB(181, 255, 0), Color3.fromRGB(173, 255, 0),
        Color3.fromRGB(166, 255, 0), Color3.fromRGB(158, 255, 0), Color3.fromRGB(150, 255, 0), Color3.fromRGB(143, 255, 0), Color3.fromRGB(135, 255, 0),
        Color3.fromRGB(128, 255, 0), Color3.fromRGB(120, 255, 0), Color3.fromRGB(112, 255, 0), Color3.fromRGB(105, 255, 0), Color3.fromRGB(97, 255, 0),
        Color3.fromRGB(89, 255, 0), Color3.fromRGB(82, 255, 0), Color3.fromRGB(74, 255, 0), Color3.fromRGB(66, 255, 0), Color3.fromRGB(59, 255, 0),
        Color3.fromRGB(51, 255, 0), Color3.fromRGB(43, 255, 0), Color3.fromRGB(36, 255, 0), Color3.fromRGB(28, 255, 0), Color3.fromRGB(20, 255, 0),
        Color3.fromRGB(13, 255, 0), Color3.fromRGB(5, 255, 0), Color3.fromRGB(0, 255, 3), Color3.fromRGB(0, 255, 10), Color3.fromRGB(0, 255, 18),
        Color3.fromRGB(0, 255, 25), Color3.fromRGB(0, 255, 33), Color3.fromRGB(0, 255, 41), Color3.fromRGB(0, 255, 48), Color3.fromRGB(0, 255, 56),
        Color3.fromRGB(0, 255, 64), Color3.fromRGB(0, 255, 71), Color3.fromRGB(0, 255, 79), Color3.fromRGB(0, 255, 87), Color3.fromRGB(0, 255, 94),
        Color3.fromRGB(0, 255, 102), Color3.fromRGB(0, 255, 110), Color3.fromRGB(0, 255, 117), Color3.fromRGB(0, 255, 125), Color3.fromRGB(0, 255, 133),
        Color3.fromRGB(0, 255, 140), Color3.fromRGB(0, 255, 148), Color3.fromRGB(0, 255, 156), Color3.fromRGB(0, 255, 163), Color3.fromRGB(0, 255, 171),
        Color3.fromRGB(0, 255, 179), Color3.fromRGB(0, 255, 186), Color3.fromRGB(0, 255, 194), Color3.fromRGB(0, 255, 201), Color3.fromRGB(0, 255, 209),
        Color3.fromRGB(0, 255, 217), Color3.fromRGB(0, 255, 224), Color3.fromRGB(0, 255, 232), Color3.fromRGB(0, 255, 240), Color3.fromRGB(0, 255, 247),
        Color3.fromRGB(0, 255, 255), Color3.fromRGB(0, 247, 255), Color3.fromRGB(0, 240, 255), Color3.fromRGB(0, 232, 255), Color3.fromRGB(0, 224, 255),
        Color3.fromRGB(0, 217, 255), Color3.fromRGB(0, 209, 255), Color3.fromRGB(0, 201, 255), Color3.fromRGB(0, 194, 255), Color3.fromRGB(0, 186, 255),
        Color3.fromRGB(0, 179, 255), Color3.fromRGB(0, 171, 255), Color3.fromRGB(0, 163, 255), Color3.fromRGB(0, 156, 255), Color3.fromRGB(0, 148, 255),
        Color3.fromRGB(0, 140, 255), Color3.fromRGB(0, 133, 255), Color3.fromRGB(0, 125, 255), Color3.fromRGB(0, 117, 255), Color3.fromRGB(0, 110, 255),
        Color3.fromRGB(0, 102, 255), Color3.fromRGB(0, 94, 255), Color3.fromRGB(0, 87, 255), Color3.fromRGB(0, 79, 255), Color3.fromRGB(0, 71, 255),
        Color3.fromRGB(0, 64, 255), Color3.fromRGB(0, 56, 255), Color3.fromRGB(0, 48, 255), Color3.fromRGB(0, 41, 255), Color3.fromRGB(0, 33, 255),
        Color3.fromRGB(0, 25, 255), Color3.fromRGB(0, 18, 255), Color3.fromRGB(0, 10, 255), Color3.fromRGB(0, 3, 255), Color3.fromRGB(5, 0, 255),
        Color3.fromRGB(13, 0, 255), Color3.fromRGB(20, 0, 255), Color3.fromRGB(28, 0, 255), Color3.fromRGB(36, 0, 255), Color3.fromRGB(43, 0, 255),
        Color3.fromRGB(51, 0, 255), Color3.fromRGB(59, 0, 255), Color3.fromRGB(66, 0, 255), Color3.fromRGB(74, 0, 255), Color3.fromRGB(82, 0, 255),
        Color3.fromRGB(89, 0, 255), Color3.fromRGB(97, 0, 255), Color3.fromRGB(105, 0, 255), Color3.fromRGB(112, 0, 255), Color3.fromRGB(120, 0, 255),
        Color3.fromRGB(128, 0, 255), Color3.fromRGB(135, 0, 255), Color3.fromRGB(143, 0, 255), Color3.fromRGB(150, 0, 255), Color3.fromRGB(158, 0, 255),
        Color3.fromRGB(166, 0, 255), Color3.fromRGB(173, 0, 255), Color3.fromRGB(181, 0, 255), Color3.fromRGB(189, 0, 255), Color3.fromRGB(196, 0, 255),
        Color3.fromRGB(204, 0, 255), Color3.fromRGB(212, 0, 255), Color3.fromRGB(219, 0, 255), Color3.fromRGB(227, 0, 255), Color3.fromRGB(235, 0, 255),
        Color3.fromRGB(242, 0, 255), Color3.fromRGB(250, 0, 255), Color3.fromRGB(255, 0, 252), Color3.fromRGB(255, 0, 245), Color3.fromRGB(255, 0, 237),
        Color3.fromRGB(255, 0, 230), Color3.fromRGB(255, 0, 222), Color3.fromRGB(255, 0, 214), Color3.fromRGB(255, 0, 207), Color3.fromRGB(255, 0, 199),
        Color3.fromRGB(255, 0, 191), Color3.fromRGB(255, 0, 184), Color3.fromRGB(255, 0, 176), Color3.fromRGB(255, 0, 168), Color3.fromRGB(255, 0, 161),
        Color3.fromRGB(255, 0, 153), Color3.fromRGB(255, 0, 145), Color3.fromRGB(255, 0, 138), Color3.fromRGB(255, 0, 130), Color3.fromRGB(255, 0, 122),
        Color3.fromRGB(255, 0, 115), Color3.fromRGB(255, 0, 107), Color3.fromRGB(255, 0, 99), Color3.fromRGB(255, 0, 92), Color3.fromRGB(255, 0, 84),
        Color3.fromRGB(255, 0, 77), Color3.fromRGB(255, 0, 69), Color3.fromRGB(255, 0, 61), Color3.fromRGB(255, 0, 54), Color3.fromRGB(255, 0, 46),
        Color3.fromRGB(255, 0, 38), Color3.fromRGB(255, 0, 31), Color3.fromRGB(255, 0, 23), Color3.fromRGB(255, 0, 15), Color3.fromRGB(255, 0, 8)
    },
    DODGE_START = Color3.fromRGB(160, 0, 255),
    DODGE_END = Color3.fromRGB(255, 0, 130),
    EDIT_MODE = Color3.fromRGB(0, 255, 255),
    UI_BG = Color3.fromRGB(6, 6, 10),
    UI_ACCENT = Color3.fromRGB(18, 18, 24),
    UI_NEON = Color3.fromRGB(0, 255, 200),
    UI_GLOW = Color3.fromRGB(255, 255, 255),
    UI_DARK = Color3.fromRGB(3, 3, 7),
    KIROSHI_TINT = Color3.fromRGB(200, 50, 70),
    KIROSHI = Color3.fromRGB(200, 50, 70),
    OPTICAL = Color3.fromRGB(0, 255, 255),
    ENERGY_FULL = Color3.fromRGB(105, 255, 140),
    ENERGY_MEDIUM = Color3.fromRGB(255, 215, 0),
    ENERGY_LOW = Color3.fromRGB(255, 40, 40),
    CYBER_CHROME = Color3.fromRGB(180, 190, 210),
    CYBER_ORANGE = Color3.fromRGB(255, 130, 40)
}

local cloneColorIndex = 34

local ButtonConfigs = {
    LockBtn = {Size = UDim2.new(0, 40, 0, 40), Position = UDim2.new(0, 8, 0.5, -210), BackgroundColor3 = Colors.UI_DARK, TextColor3 = Colors.UI_NEON, Font = Enum.Font.SciFi, TextSize = 22, Text = "⚙️"},
    DashBtn = {Key = "D", Color = Color3.fromRGB(255, 80, 0), Position = UDim2.new(0.93, 0, 0.25, 0)},
    SandiBtn = {Key = "S", Color = Color3.new(1,1,1), Position = UDim2.new(0.93, 0, 0.35, 0)},
    KiroshiBtn = {Key = "Ko", Color = Colors.KIROSHI, Position = UDim2.new(0.93, 0, 0.45, 0)},
    OpticalBtn = {Key = "Oc", Color = Colors.OPTICAL, Position = UDim2.new(0.93, 0, 0.55, 0)},
    DodgeBtn = {Key = "N", Color = Color3.fromRGB(0, 255, 140), Position = UDim2.new(0.93, 0, 0.65, 0)}
}

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

local SET_1 = {120005268911290}
local SET_2 = {84715312484929, 120005268911290, 129989646284308}  
local SET_3 = {76673357358456, 101607241306335, 79690388560983}

local currentSet = 1
local setColors = {
    [1] = Color3.fromRGB(45, 45, 45),      -- Set 1
    [2] = Color3.fromRGB(0, 120, 215),     -- Set 2
    [3] = Color3.fromRGB(200, 50, 50)      -- Set 3 
}

local DodgeMode = "Counter"

local LiteMode = false
local Noclip = false
local noclipConnection

local AbilityActions = {Dash = "CyberDash", Sandi = "CyberSandi", Kiroshi = "CyberKiroshi", Optical = "CyberOptical", Dodge = "CyberDodge"}
local CurrentKeybinds = {Dash = Enum.KeyCode.Q, Sandi = Enum.KeyCode.E, Kiroshi = Enum.KeyCode.K, Optical = Enum.KeyCode.O, Dodge = Enum.KeyCode.N}
local RebindingAbility = nil
local KeybindCurrentTexts = {}

local Sounds = {
    DODGE_NORMAL = {id = "rbxassetid://104594227753486", volume = 1.5, pitch = 1, looped = false},
    DODGE_VARIANT = {id = "rbxassetid://136915991425056", volume = 1.5, pitch = 1, looped = false},
    DASH = {id = "rbxassetid://103247005619946", volume = 1.5, pitch = 1, looped = false},
    SANDI_ON = {id = "rbxassetid://123844681344865", volume = 1.5, pitch = 1, looped = false},
    SANDI_OFF = {id = "rbxassetid://118534165523355", volume = 1.5, pitch = 1, looped = false},
    SANDI_LOOP = {id = "rbxassetid://74707394872868", volume = 1.5, pitch = 1, looped = true},
    PSYCHOSIS = {id = "rbxassetid://116261614561232", volume = 2, pitch = 1, looped = false},
    PSYCHOSIS2 = {id = "rbxassetid://116079585368153", volume = 2, pitch = 1, looped = false},
    OPTICAL_CAMO = {id = "rbxassetid://115981406751041", volume = 1, pitch = 1, looped = false},
    SANDI_FAILURE = {id = "rbxassetid://132281440773764", volume = 5, pitch = 1, looped = false},
    COLLISION_IMPACT = {id = "rbxassetid://86227700557194", volume = 1.7, pitch = 1, looped = false},
    SPAWN = {id = "rbxassetid://138566469626743", volume = 1.5, pitch = 1, looped = false},
    KIROSHI_ON = {id = "rbxassetid://101563346734882", volume = 2.2, pitch = 1.05, looped = false},
    KIROSHI_OFF = {id = "rbxassetid://79307196411649", volume = 1.8, pitch = 0.95, looped = false}
}

local invisSound = Instance.new("Sound", Player:WaitForChild("PlayerGui"))
invisSound.SoundId = Sounds.OPTICAL_CAMO.id
invisSound.Volume = Sounds.OPTICAL_CAMO.volume
invisSound.PlaybackSpeed = Sounds.OPTICAL_CAMO.pitch
invisSound.Looped = Sounds.OPTICAL_CAMO.looped

local NOME_ARQUIVO = "I Really Want to Stay at Your House.mp3"
local VOLUME = 0.9
local LOOP = false

local function detectarExecutor()
    if KRNL_LOADED then return "KRNL", getcustomasset
    elseif syn then return "Synapse X", syn.getcustomasset
    elseif fluxus then return "Fluxus", fluxus.getcustomasset
    elseif getcustomasset then return "Executor Gen�rico", getcustomasset
    else return nil, nil end
end

local function encontrarMusica()
    local executor, getasset = detectarExecutor()
    if not executor then return nil end
    local possibilidades = {NOME_ARQUIVO, "musica.mp3", "musica.ogg", "musica.wav", "music.mp3", "music.ogg", "audio.mp3", "audio.ogg"}
    if getasset then
        for _, nome in ipairs(possibilidades) do
            local sucesso, resultado = pcall(function() return getasset(nome) end)
            if sucesso and resultado then return resultado end
        end
    end
    return NOME_ARQUIVO
end

local function tocarMusica()
    local musicaId = encontrarMusica()
    if not musicaId then return end
    local somAntigo = SoundService:FindFirstChild("MinhaMusicaLocal")
    if somAntigo then somAntigo:Destroy() end
    local som = Instance.new("Sound")
    som.Name = "MinhaMusicaLocal"
    som.SoundId = musicaId
    som.Volume = VOLUME
    som.Looped = LOOP
    som.RollOffMode = Enum.RollOffMode.Linear
    som.RollOffMaxDistance = 1000
    som.Parent = SoundService
    som.Loaded:Connect(function() som:Play() end)
    task.delay(2, function() if not som.IsLoaded then som:Play() end end)
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
        Titulo.Text = " Tocando Agora"
        Titulo.TextColor3 = Color3.fromRGB(255, 255, 255)
        Titulo.BackgroundTransparency = 1
        Titulo.Font = Enum.Font.GothamBold
        Titulo.TextSize = 16
        Titulo.Parent = Frame
        local BotaoParar = Instance.new("TextButton")
        BotaoParar.Size = UDim2.new(0.8, 0, 0.4, 0)
        BotaoParar.Position = UDim2.new(0.1, 0, 0.5, 0)
        BotaoParar.Text = " PARAR M�SICA"
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

local State: SystemState = {
    Energy = Constants.MAX_ENERGY,
    IsSandiActive = false,
    IsKiroshiActive = false,
    IsOpticalActive = false,
    IsDodgeReady = false,
    Cooldowns = {SANDI = 0, DASH = 0, DODGE = 0, KIROSHI = 0, OPTICAL = 0},
    EditMode = false,
    LastVelocityY = 0,
    LastHealth = 100,
    NoRegenUntil = 0,
    MusicSound = nil
}

local UI_Elements = {}
local ActiveCooldownFrames = {}
local sandiLoopSound: Sound? = nil
local lastSandiClone = 0
local savedPositions = {}
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
local energyFill: Frame
local energyPercentLabel: TextLabel
local settingsMenu = nil 

local function getSafeInvisPosition()
    local offset = Vector3.new(math.random(-5000, 5000), math.random(10000, 15000), math.random(-5000, 5000))
    return offset
end

local function setTransparency(character, targetTransparency, duration)
    local tweenInfo = TweenInfo.new(duration or 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    for _, part in pairs(character:GetDescendants()) do
        if (part:IsA("BasePart") or part:IsA("Decal")) and part.Name ~= "HumanoidRootPart" then
            TweenService:Create(part, tweenInfo, {Transparency = targetTransparency}):Play()
        end
    end
end

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
    Weld.Part1 = Player.Character:FindFirstChild("UpperTorso") or Player.Character:FindFirstChild("Torso") or Player.Character:FindFirstChild("HumanoidRootPart")
    task.wait()
    Seat.CFrame = savedpos
    setTransparency(Player.Character, 0.5, 0.5)
end

local function deactivateInvisibility()
    local invisChair = Workspace:FindFirstChild('invischair')
    if invisChair then invisChair:Destroy() end
    setTransparency(Player.Character, 0, 0.5)
end

local function Create(className: string, properties: {[string]: any})
    local instance = Instance.new(className)
    for prop, value in properties do instance[prop] = value end
    return instance
end

local function PlaySFX(soundConfig: {id: string, volume: number?, pitch: number?})
    local sound = Create("Sound", {SoundId = soundConfig.id, Volume = soundConfig.volume or 1, PlaybackSpeed = soundConfig.pitch or 1, Parent = HRP or Camera})
    sound:Play()
    Debris:AddItem(sound, 10)
    return sound
end

local function CamShake(intensity: number, duration: number)
    if LiteMode then return end
    task.spawn(function()
        local startTime = os.clock()
        while os.clock() - startTime < duration do
            if Humanoid then
                Humanoid.CameraOffset = Vector3.new(math.random(-10,10)/10, math.random(-10,10)/10, math.random(-10,10)/10) * intensity
            end
            RunService.RenderStepped:Wait()
        end
        if Humanoid then Humanoid.CameraOffset = Vector3.zero end
    end)
end

local function ScreenFade(durationIn: number, hold: number, durationOut: number, tint: Color3, sat: number?, cont: number?)
    if LiteMode then return end
    local cc = Create("ColorCorrectionEffect", {Name = "CyberFade", TintColor = Color3.new(1,1,1), Saturation = 0, Contrast = 0, Parent = Lighting})
    TweenService:Create(cc, TweenInfo.new(durationIn, Enum.EasingStyle.Quad), {TintColor = tint, Saturation = sat or 0.6, Contrast = cont or 0.25}):Play()
    task.delay(durationIn + hold, function()
        TweenService:Create(cc, TweenInfo.new(durationOut, Enum.EasingStyle.Quad), {TintColor = Color3.new(1,1,1), Saturation = 0, Contrast = 0}):Play()
        task.delay(durationOut + 0.1, function() cc:Destroy() end)
    end)
end

local function ShowCooldownText(name: string, duration: number, color: Color3)
    task.spawn(function()
        local gui = Player.PlayerGui:FindFirstChild("CyberRebuilt")
        if not gui then return end
        local container = Create("Frame", {Size = UDim2.new(0, 220, 0, 42), Position = UDim2.new(0.5, -110, 0.72, 0), BackgroundColor3 = Color3.fromRGB(8, 8, 12), BackgroundTransparency = 0.05, BorderSizePixel = 0, Parent = gui})
        Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = container})
        local stroke = Create("UIStroke", {Color = color, Thickness = 2, Transparency = 0.2, Parent = container})
        local label = Create("TextLabel", {Size = UDim2.new(1, -20, 0.55, 0), Position = UDim2.new(0, 10, 0, 4), BackgroundTransparency = 1, TextColor3 = color, Font = Enum.Font.SciFi, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left, Text = name:upper(), Parent = container})
        local progressBar = Create("Frame", {Size = UDim2.new(1, -20, 0, 6), Position = UDim2.new(0, 10, 1, -12), BackgroundColor3 = Color3.fromRGB(20, 20, 25), BorderSizePixel = 0, Parent = container})
        Create("UICorner", {CornerRadius = UDim.new(0, 3), Parent = progressBar})
        local fillBar = Create("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = color, BorderSizePixel = 0, Parent = progressBar})
        Create("UICorner", {CornerRadius = UDim.new(0, 3), Parent = fillBar})
        local timer = Create("TextLabel", {Size = UDim2.new(0, 50, 1, 0), Position = UDim2.new(1, -55, 0, 0), BackgroundTransparency = 1, TextColor3 = Colors.UI_NEON, Font = Enum.Font.Code, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Right, Text = string.format("%.1fs", duration), Parent = container})
        table.insert(ActiveCooldownFrames, container)
        local startTime = os.clock()
        while os.clock() - startTime < duration do
            local remaining = math.max(0, duration - (os.clock() - startTime))
            local progress = remaining / duration
            timer.Text = string.format("%.1fs", remaining)
            fillBar.Size = UDim2.new(1 - progress, 0, 1, 0)
            local myIndex = 0
            for i, v in ipairs(ActiveCooldownFrames) do if v == container then myIndex = i break end end
            if myIndex > 0 then
                local targetPos = UDim2.new(0.5, -110, 0.72, -(myIndex - 1) * 50)
                container.Position = container.Position:Lerp(targetPos, 0.2)
            end
            RunService.RenderStepped:Wait()
        end
        TweenService:Create(container, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
        TweenService:Create(label, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
        TweenService:Create(timer, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
        TweenService:Create(progressBar, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
        TweenService:Create(fillBar, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
        TweenService:Create(stroke, TweenInfo.new(0.2), {Transparency = 1}):Play()
        task.wait(0.25)
        local index = 0
        for i, v in ipairs(ActiveCooldownFrames) do if v == container then index = i break end end
        if index > 0 then table.remove(ActiveCooldownFrames, index) end
        container:Destroy()
    end)
end

local function CreateHologramClone(delay: number, duration: number, endTransparency: number, offsetX: number, offsetY: number, offsetZ: number, cloneType: string, customCFrame: CFrame?)
    if LiteMode then return end
    local sourceChar = Character
    if not sourceChar then return end
    sourceChar.Archivable = true
    local hologramChar = sourceChar:Clone()
    local hologramHRP = hologramChar:FindFirstChild("HumanoidRootPart")
    if hologramHRP then
        if customCFrame and typeof(customCFrame) == "CFrame" then
            hologramHRP.CFrame = customCFrame
        elseif HRP and typeof(HRP.CFrame) == "CFrame" then
            hologramHRP.CFrame = HRP.CFrame + Vector3.new(offsetX or 0, offsetY or 0, offsetZ or 0)
        end
    end
    local humanoid = hologramChar:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid:Destroy() end
    local animateFolder = hologramChar:FindFirstChild("Animate")
    if animateFolder then animateFolder:Destroy() end
    for _, obj in ipairs(hologramChar:GetDescendants()) do
        if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") or obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") or obj:IsA("BindableEvent") or obj:IsA("BindableFunction") or obj:IsA("Animator") then
            obj:Destroy()
        end
    end
    for _, sound in ipairs(hologramChar:GetDescendants()) do if sound:IsA("Sound") then sound:Destroy() end end
    if not Configurations.HOLOGRAM_PRESERVE.FACE then
        local head = hologramChar:FindFirstChild("Head")
        if head then local face = head:FindFirstChild("face") if face and face:IsA("Decal") then face:Destroy() end end
    end
    for _, acc in ipairs(hologramChar:GetChildren()) do
        if acc:IsA("Accessory") then
            local isHair = acc:FindFirstChild("HairAttachment") or string.find(acc.Name:lower(), "hair") ~= nil
            if isHair and not Configurations.HOLOGRAM_PRESERVE.HAIR then acc:Destroy()
            elseif not isHair and not Configurations.HOLOGRAM_PRESERVE.ACCESSORIES then acc:Destroy() end
        end
    end
    local thisColor = Colors.RAINBOW_SEQUENCE[cloneColorIndex]
cloneColorIndex = (cloneColorIndex % #Colors.RAINBOW_SEQUENCE) + 1

-- Pinta TUDO no clone (corpo + acessórios + meshparts)
for _, part in ipairs(hologramChar:GetDescendants()) do
    if part:IsA("BasePart") then
        part.Anchored = true
        part.CanCollide = false
        part.Material = Configurations.HOLOGRAM_MATERIAL
        part.Transparency = 0.15
        part.Color = thisColor
    elseif part:IsA("Decal") or part:IsA("Texture") then
        part.Transparency = 0.25
    elseif part:IsA("MeshPart") then
        part.Color = thisColor
        part.TextureID = ""  -- Remove textura para a cor aparecer
    end
    
    -- Remove textura de SpecialMesh para mostrar a cor sólida
    if part:IsA("SpecialMesh") then
        part.TextureId = ""
    end
end

-- Segunda passada: pinta MeshParts que estão DENTRO de acessórios
for _, acc in ipairs(hologramChar:GetDescendants()) do
    if acc:IsA("Accessory") then
        for _, child in ipairs(acc:GetDescendants()) do
            if child:IsA("MeshPart") then
                child.Color = thisColor
                child.TextureID = ""
            elseif child:IsA("BasePart") then
                child.Color = thisColor
            end
        end
    end
end
    if hologramHRP then hologramHRP.Transparency = 1 end
    local rootPart = hologramChar:FindFirstChild("HumanoidRootPart")
    if rootPart then rootPart:Destroy() end
    local highlight = Instance.new("Highlight")
highlight.Name = "FullHoloHighlight"
highlight.Adornee = hologramChar
highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
highlight.FillTransparency = 0.6          -- Sem preenchimento (100% transparente)
highlight.OutlineTransparency = 0.3     -- Contorno fraco (60% transparente)
highlight.OutlineColor = thisColor       -- Cor do contorno
highlight.Parent = hologramChar
    if cloneType == "sandi" then
        hologramChar.Name = "HologramClone"
        local tag = Instance.new("BoolValue")
        tag.Name = "IsSandiClone"
        tag.Value = true
        tag.Parent = hologramChar
        highlight.FillColor = thisColor
        highlight.OutlineColor = thisColor
    elseif cloneType == "dash" then
        local palette = {Color3.fromRGB(255, 40, 40), Color3.fromRGB(255, 130, 30), Color3.fromRGB(255, 215, 40)}
        highlight.FillColor = palette[1]
        highlight.OutlineColor = palette[2]
        task.spawn(function()
            task.wait(delay)
            local startTime = os.clock()
            while os.clock() - startTime < duration do
                local progress = (os.clock() - startTime) / duration
                local idx = math.floor(progress * (#palette - 1)) + 1
                local nextIdx = math.min(idx + 1, #palette)
                local frac = (progress * (#palette - 1)) % 1
                local current = palette[idx]:Lerp(palette[nextIdx], frac)
                highlight.FillColor = current
                highlight.OutlineColor = current
                RunService.Heartbeat:Wait()
            end
        end)
    elseif cloneType == "dodge" then
        local palette = {Color3.fromRGB(0, 255, 90), Color3.fromRGB(80, 255, 170), Color3.fromRGB(0, 230, 255)}
        highlight.FillColor = palette[1]
        highlight.OutlineColor = palette[2]
        task.spawn(function()
            task.wait(delay)
            local startTime = os.clock()
            while os.clock() - startTime < duration do
                local progress = (os.clock() - startTime) / duration
                local idx = math.floor(progress * (#palette - 1)) + 1
                local nextIdx = math.min(idx + 1, #palette)
                local frac = (progress * (#palette - 1)) % 1
                local current = palette[idx]:Lerp(palette[nextIdx], frac)
                highlight.FillColor = current
                highlight.OutlineColor = current
                RunService.Heartbeat:Wait()
            end
        end)
    end
    task.delay(delay + duration * 0.7, function()
        if highlight and highlight.Parent then
            TweenService:Create(highlight, TweenInfo.new(0.4), {FillTransparency = 1, OutlineTransparency = 1}):Play()
        end
    end)
    for _, surf in ipairs(hologramChar:GetDescendants()) do
        if surf:IsA("Decal") or surf:IsA("Texture") then
            task.spawn(function()
                task.wait(delay + duration * 0.3)
                local fadeTween = TweenService:Create(surf, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {Transparency = 1})
                fadeTween:Play()
            end)
        end
    end
    hologramChar.Parent = Workspace
    Debris:AddItem(hologramChar, delay + duration)
end

local function TriggerSandevistanFailure()
    PlaySFX(Sounds.SANDI_FAILURE)
    local gui = Player.PlayerGui:FindFirstChild("CyberRebuilt") or Instance.new("ScreenGui", Player.PlayerGui)
    gui.Name = "CyberRebuilt"
    local errorFrame = Create("Frame", {Size = UDim2.new(0, 400, 0, 120), Position = UDim2.new(0.5, -200, 0.28, 0), BackgroundColor3 = Color3.fromRGB(25, 8, 0), BorderSizePixel = 0, Parent = gui})
    Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = errorFrame})
    local stroke = Create("UIStroke", {Color = Color3.fromRGB(255, 160, 30), Thickness = 4, Parent = errorFrame})
    local title = Create("TextLabel", {Size = UDim2.new(1,0,0.55,0), BackgroundTransparency = 1, Text = "SANDEVISTAN", TextColor3 = Color3.fromRGB(255, 200, 50), Font = Enum.Font.SciFi, TextSize = 42, TextStrokeTransparency = 0.3, Parent = errorFrame})
    local subtitle = Create("TextLabel", {Size = UDim2.new(1,0,0.45,0), Position = UDim2.new(0,0,0.55,0), BackgroundTransparency = 1, Text = "OVERLOAD - CALIBRATION REQUIRED", TextColor3 = Color3.fromRGB(255, 180, 60), Font = Enum.Font.Code, TextSize = 18, Parent = errorFrame})
    task.spawn(function()
        for i = 1, 8 do
            title.TextTransparency = i % 2 == 0 and 0.7 or 0
            task.wait(0.05)
        end
    end)
    task.delay(0.8, function() errorFrame:Destroy() end)
    if math.random() < 0.15 then task.wait(0.2) ExecCyberpsychosis() end
    State.Cooldowns.SANDI = os.clock() + 9
    State.NoRegenUntil = os.clock() + 9.5
    ShowCooldownText("SANDEVISTAN OVERLOAD", 9, Color3.fromRGB(255, 160, 30))
end

local function ApplyGlitchEffect()
    if LiteMode then return end
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
        task.delay(0.7, function() cc:Destroy() blur:Destroy() end)
    end)
end

-- ========== NOVAS ANIMAÇÕES ==========

-- Animação de Scanline (linhas horizontais piscando)
local function ScanlineEffect(gui)
    local scanline = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, -1, 0),
        BackgroundColor3 = Colors.UI_NEON,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Parent = gui
    })
    task.spawn(function()
        while scanline.Parent do
            TweenService:Create(scanline, TweenInfo.new(2, Enum.EasingStyle.Linear), {
                Position = UDim2.new(0, 0, 1, 0)
            }):Play()
            task.wait(2)
            scanline.Position = UDim2.new(0, 0, -1, 0)
        end
    end)
end

-- Animação de Glitch na tela toda
local function FullScreenGlitch()
    local gui = Player.PlayerGui:FindFirstChild("CyberRebuilt")
    if not gui then return end
    local glitch = Create("Frame", {
        Size = UDim2.new(1, 0, 0, math.random(10, 40)),
        Position = UDim2.new(0, math.random(-5, 5), 0, math.random(0, 100)/100),
        BackgroundColor3 = Color3.fromRGB(0, 255, 200),
        BackgroundTransparency = 0.7,
        BorderSizePixel = 0,
        Parent = gui
    })
    task.delay(0.08, function()
        TweenService:Create(glitch, TweenInfo.new(0.1), {BackgroundTransparency = 1}):Play()
        task.delay(0.15, function() glitch:Destroy() end)
    end)
end

-- Animação de pulsação (botões)
local function PulseAnimation(object)
    task.spawn(function()
        while object.Parent do
            TweenService:Create(object, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Size = UDim2.new(1.05, 0, 1.05, 0)
            }):Play()
            task.wait(0.8)
            TweenService:Create(object, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Size = UDim2.new(1, 0, 1, 0)
            }):Play()
            task.wait(0.8)
        end
    end)
end

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
    
    -- Posição aleatória em órbita 360° ao redor do personagem
    local angleHorizontal = math.random() * math.pi * 2  -- Ângulo horizontal (0 a 360°)
    local angleVertical = math.random(-0.6, 0.6) * math.pi  -- Das pernas até o rosto
local radius = math.random(5.5, 8)  -- Distância média
local heightOffset = math.random(-1, 3)  -- Variação para cobrir pernas também
    
    local orbitX = math.cos(angleHorizontal) * math.cos(angleVertical) * radius
    local orbitY = math.sin(angleVertical) * radius + heightOffset
    local orbitZ = math.sin(angleHorizontal) * math.cos(angleVertical) * radius
    
    local targetWidth = math.random(3.2, 5.5)   -- Tamanho médio
local targetHeight = math.random(2.0, 4.0)  -- Tamanho médio
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
    
    -- Posiciona em órbita ao redor do personagem
    part.Position = HRP.Position + Vector3.new(orbitX, orbitY, orbitZ)
    
    -- Sempre olhando para o personagem
    local look = CFrame.lookAt(part.Position, HRP.Position)
    part.CFrame = look * CFrame.Angles(math.rad(math.random(-15, 15)), math.rad(math.random(-20, 20)), 0)
    part.Parent = Workspace
    
    -- SurfaceGui
    local sgui = Instance.new("SurfaceGui")
    sgui.Face = Enum.NormalId.Front
    sgui.LightInfluence = 0
    sgui.PixelsPerStud = 50
    sgui.Parent = part
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1,0,1,0)
    frame.BackgroundColor3 = Color3.fromRGB(6,0,1)
    frame.BackgroundTransparency = 1
    frame.Parent = sgui
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 25, 60)
    stroke.Thickness = 4
    stroke.Transparency = 1
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
    label.TextTransparency = 1
    label.Parent = frame
    
    local sublabel = Instance.new("TextLabel")
    sublabel.Size = UDim2.new(1,-16,0.28,-8)
    sublabel.Position = UDim2.new(0,8,0.72,4)
    sublabel.BackgroundTransparency = 1
    sublabel.TextColor3 = Color3.fromRGB(255, 125, 140)
    sublabel.Font = Enum.Font.Code
    sublabel.TextScaled = true
    sublabel.Text = "0x"..string.format("%X", math.random(0x8000,0xFFFF)) .. "_NEURAL_CRITICAL"
    sublabel.TextTransparency = 1
    sublabel.Parent = frame
    
    -- ANIMAÇÃO DE ABRIR
    TweenService:Create(part, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = finalSize
    }):Play()
    
    TweenService:Create(frame, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0
    }):Play()
    
    TweenService:Create(stroke, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Transparency = 0
    }):Play()
    
    task.spawn(function()
        for i = 1, 6 do
            label.TextTransparency = i % 2 == 0 and 0.7 or 0.1
            task.wait(0.025)
        end
        TweenService:Create(label, TweenInfo.new(0.08), {
            TextTransparency = 0
        }):Play()
    end)
    
    task.delay(0.08, function()
        TweenService:Create(sublabel, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            TextTransparency = 0
        }):Play()
    end)
    
    -- ANIMAÇÃO DE FECHAR
    task.delay(Constants.CYBERPSYCHOSIS.WindowLifeTime - 0.3, function()
        if not part.Parent then return end
        
        TweenService:Create(label, TweenInfo.new(0.15), {TextTransparency = 1}):Play()
        TweenService:Create(sublabel, TweenInfo.new(0.15), {TextTransparency = 1}):Play()
        TweenService:Create(frame, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
        TweenService:Create(stroke, TweenInfo.new(0.2), {Transparency = 1}):Play()
        
        local closeTween = TweenService:Create(part, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = Vector3.new(0, 0, 0)
        })
        closeTween:Play()
        closeTween.Completed:Connect(function()
            part:Destroy()
        end)
    end)
end

local function shakeCamera()
	if not Humanoid then return end
	local intensity = Constants.CYBERPSYCHOSIS.ShakeIntensity
	Humanoid.CameraOffset = Vector3.new((math.random() - 0.5) * intensity, (math.random() - 0.5) * intensity, (math.random() - 0.5) * intensity)
end

local function ExecCyberpsychosis()
    PlaySFX(Sounds.PSYCHOSIS)
    PlaySFX(Sounds.PSYCHOSIS2)
    
    -- Janelas sincronizadas com "I'M GONNA RIP OUT HIS SPINE! YOU'RE DEAD, DEAD... DEAD.! DEAAD!!!"
    task.spawn(function()
        -- "I'M" (0.0s)
        spawnPopup()
        task.wait(0.15)
        -- "GONNA" (0.15s)
        spawnPopup()
        task.wait(0.15)
        -- "RIP" (0.3s)
        spawnPopup()
        spawnPopup()
        task.wait(0.12)
        -- "OUT" (0.42s)
        spawnPopup()
        task.wait(0.12)
        -- "HIS" (0.54s)
        spawnPopup()
        task.wait(0.1)
        -- "SPINE!" (0.64s) - explosão de janelas
        for i = 1, 4 do
            spawnPopup()
            task.wait(0.06)
        end
        task.wait(0.3)
        
        -- "YOU'RE" (1.18s)
        for i = 1, 3 do
            spawnPopup()
            task.wait(0.08)
        end
        task.wait(0.12)
        
        -- "DEAD," (1.54s)
        spawnPopup()
        spawnPopup()
        task.wait(0.2)
        
        -- "DEAD..." (1.74s)
        spawnPopup()
        spawnPopup()
        task.wait(0.15)
        
        -- "DEAD.!" (1.89s)
        for i = 1, 3 do
            spawnPopup()
            task.wait(0.05)
        end
        task.wait(0.15)
        
        -- "DEAAD!!!" (2.24s) - climax
        for i = 1, 8 do
            spawnPopup()
            task.wait(0.04)
        end
    end)

    if Humanoid then Humanoid.WalkSpeed = 0 Humanoid.JumpPower = 0 end
    if Lighting:FindFirstChild("SandiEffect") then Lighting.SandiEffect:Destroy() end
    local cc, blur = createLightingEffects()
    local startTime = tick()
    local connection
    local gui = Player.PlayerGui:FindFirstChild("CyberRebuilt") or Create("ScreenGui", {Name = "CyberRebuilt", Parent = Player.PlayerGui, IgnoreGuiInset = true})
    local vignette = Create("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 0.5, BackgroundColor3 = Color3.new(0, 0, 0), Parent = gui})
    local vignetteGradient = Create("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.5), NumberSequenceKeypoint.new(1, 1)}), Rotation = 0, Parent = vignette})
    task.spawn(function()
        while vignette.Parent do
            TweenService:Create(vignette, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.3}):Play()
            task.wait(0.5)
            TweenService:Create(vignette, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.7}):Play()
            task.wait(0.5)
        end
    end)
    local psychosisText = Create("TextLabel", {Size = UDim2.new(1, 0, 0.2, 0), Position = UDim2.new(0, 0, 0.4, 0), BackgroundTransparency = 1, Text = "CYBERPSYCHOSIS", TextColor3 = Color3.fromRGB(255, 0, 0), Font = Enum.Font.SciFi, TextSize = 80, TextTransparency = 0.5, Parent = gui})
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
        local crack = Create("ImageLabel", {Size = UDim2.new(0.3, 0, 0.3, 0), Position = UDim2.new(math.random(), 0, math.random(), 0), BackgroundTransparency = 1, Image = crackImages[math.random(1, #crackImages)], ImageTransparency = 0.5, Parent = gui})
        task.spawn(function()
            while crack.Parent do
                crack.Position = UDim2.new(math.random(), 0, math.random(), 0)
                TweenService:Create(crack, TweenInfo.new(0.1), {ImageTransparency = math.random(0.2, 0.8)}):Play()
                task.wait(0.1)
            end
        end)
    end
    local redOverlay = Create("ImageLabel", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ImageColor3 = Color3.fromRGB(255, 0, 0), ImageTransparency = 0.8, Parent = gui})
    local blueOverlay = Create("ImageLabel", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ImageColor3 = Color3.fromRGB(0, 0, 255), ImageTransparency = 0.8, Parent = gui})
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
                end
            end
            task.wait(0.1)
        end
        for _, part in ipairs(cyberParts) do
            if part then part.Transparency = 0 part.Color = Color3.new(1,1,1) end
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
            if Humanoid then Humanoid.WalkSpeed = 16 Humanoid.JumpPower = 50 Humanoid.CameraOffset = Vector3.zero end
            TweenService:Create(cc, TweenInfo.new(0.5), {TintColor = Color3.new(1,1,1), Saturation = 0}):Play()
            TweenService:Create(blur, TweenInfo.new(0.5), {Size = 0}):Play()
            Debris:AddItem(cc, 0.5)
            Debris:AddItem(blur, 0.5)
            connection:Disconnect()
            vignette:Destroy()
            psychosisText:Destroy()
            redOverlay:Destroy()
            blueOverlay:Destroy()
            for _, crack in ipairs(gui:GetChildren()) do if crack:IsA("ImageLabel") then crack:Destroy() end end
            for _, emitter in ipairs(emitters) do emitter.Enabled = false Debris:AddItem(emitter.Parent, 1) end
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
                if Humanoid.Health > Humanoid.MaxHealth * 0.5 then Humanoid.Health -= 1 * dt end
            end
        end
        blur.Size = math.random(4, 12)
        shakeCamera()
        if math.random() < Constants.CYBERPSYCHOSIS.PopupRate then spawnPopup() end
    end)
end

local function ToggleNoclip()
    Noclip = not Noclip
    if Noclip then
        noclipConnection = RunService.Stepped:Connect(function()
            if Character then
                for _, v in ipairs(Character:GetDescendants()) do
                    if v:IsA("BasePart") then
                        v.CanCollide = false
                    end
                end
            end
        end)
    else
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
        if Character then
            for _, v in ipairs(Character:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.CanCollide = true
                end
            end
        end
    end
end

local function CleanupSandiSounds()
    if sandiLoopSound then sandiLoopSound:Stop() sandiLoopSound:Destroy() sandiLoopSound = nil end
end

local function ExecDodge(enemyPart: BasePart?)
    ScreenFade(0.08, 0, 0.25, Colors.LIGHT_GREEN, 0.8, 0.4)
    local dodgeCC = Create("ColorCorrectionEffect", {Name = "DodgeEffect", TintColor = Color3.new(1, 1, 1), Saturation = 0, Contrast = 0, Parent = Lighting})
    TweenService:Create(dodgeCC, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TintColor = Colors.LIGHT_GREEN, Saturation = 0.45, Contrast = 0.25}):Play()
    local startCFrame = HRP.CFrame
    local distance = if enemyPart then (HRP.Position - enemyPart.Position).Magnitude else 0
    local dodgeDuration = 0.35

    if enemyPart and distance <= Constants.DODGE_CONFIG.VARIANT_THRESHOLD then
    -- ========== VARIANT: Giro em volta do inimigo (SEM clone inicial) ==========
    PlaySFX(Sounds.DODGE_VARIANT)
    task.spawn(function()
        local duration = Constants.DODGE_CONFIG.VARIANT_DURATION
        local startTime = tick()
        local relative = HRP.Position - enemyPart.Position
        local lastCloneTime = 0
        
        -- ESCOLHA ALEATÓRIA: 1 = direita (sentido horário), -1 = esquerda (anti-horário)
        local direction = if math.random(1, 2) == 1 then 1 else -1
        
        while tick() - startTime < duration do
            local alpha = (tick() - startTime) / duration
            local angle = alpha * math.pi * direction  -- Multiplica pela direção escolhida
            local rotated = CFrame.Angles(0, angle, 0) * relative
            local newPos = enemyPart.Position + rotated
            HRP.CFrame = CFrame.lookAt(newPos, enemyPart.Position)
            if tick() - lastCloneTime >= Constants.DODGE_CONFIG.VARIANT_CLONE_INTERVAL then
                CreateHologramClone(0, Constants.HOLOGRAM_CLONE.DODGE.DURATION, Constants.HOLOGRAM_CLONE.DODGE.END_TRANSPARENCY, 0, 0, 0, "dodge", HRP.CFrame)
                lastCloneTime = tick()
            end
            RunService.Heartbeat:Wait()
        end
        
        -- A posição final também precisa ser invertida se for para esquerda
        local finalAngle = math.pi * direction
        local finalRelative = CFrame.Angles(0, finalAngle, 0) * relative
        local finalPos = enemyPart.Position + finalRelative
        HRP.CFrame = CFrame.lookAt(finalPos, enemyPart.Position)
    end)

    else
        -- ========== NORMAL: Teleporte + clone na posição inicial ==========
        PlaySFX(Sounds.DODGE_NORMAL)
        local endCFrame
        if enemyPart then
            endCFrame = CFrame.lookAt((enemyPart.CFrame * CFrame.new(0, 0, Constants.DODGE_CONFIG.NORMAL_DISTANCE_ENEMY)).Position, enemyPart.Position)
        else
            endCFrame = HRP.CFrame * CFrame.new(0, 0, -Constants.DODGE_CONFIG.NORMAL_DISTANCE_NO_ENEMY)
        end
        -- Clone fantasma APENAS na posição inicial (dodge normal)
        CreateHologramClone(0, 1, 1, 0, 0, 0, "dodge", startCFrame)
        HRP.CFrame = endCFrame
        dodgeDuration = 0.22
    end

    CamShake(0.5, 0.2)
    task.delay(dodgeDuration, function()
        local fadeOut = TweenService:Create(dodgeCC, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TintColor = Color3.new(1, 1, 1), Saturation = 0, Contrast = 0})
        fadeOut:Play()
        fadeOut.Completed:Connect(function() dodgeCC:Destroy() end)
        ScreenFade(0.1, 0, 0.3, Colors.LIGHT_GREEN, 0.3, 0.15)
    end)
    local dodgeSignal = Instance.new("StringValue")
    dodgeSignal.Name = "CYBER_DODGE"
    dodgeSignal.Value = tostring(HRP.CFrame)
    dodgeSignal.Parent = Character
    Debris:AddItem(dodgeSignal, 0.6)
end

local function ActivateDodgeReady()
    if not EnabledAbilities.Dodge then return end
    if os.clock() < State.Cooldowns.DODGE then return end
    if DodgeMode == "Counter" then
        if State.Energy < Constants.ENERGY_COSTS.DODGE then return end
        State.Energy -= Constants.ENERGY_COSTS.DODGE
        State.Energy = math.max(0, State.Energy)
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
        State.IsDodgeReady = true
    end
end

local function UpdateDashButton()
    local gui = Player.PlayerGui:FindFirstChild("CyberRebuilt")
    if not gui then return end
    local dashBtn = gui:FindFirstChild("DashBtn")
    if not dashBtn then return end
    dashBtn.TextColor3 = State.IsSandiActive and Color3.new(0.5, 0.5, 0.5) or Colors.DASH_GREEN
end

local function UpdateKiroshiButton()
    local gui = Player.PlayerGui:FindFirstChild("CyberRebuilt")
    if not gui then return end
    local kiroshiBtn = gui:FindFirstChild("KiroshiBtn")
    if not kiroshiBtn then return end
    kiroshiBtn.TextColor3 = State.IsSandiActive and Color3.new(0.5, 0.5, 0.5) or Colors.KIROSHI
end

local function UpdateOpticalButton()
    local gui = Player.PlayerGui:FindFirstChild("CyberRebuilt")
    if not gui then return end
    local opticalBtn = gui:FindFirstChild("OpticalBtn")
    if not opticalBtn then return end
    opticalBtn.TextColor3 = State.IsSandiActive and Color3.new(0.5, 0.5, 0.5) or Colors.OPTICAL
end

local function ResetSandi()
    if not State.IsSandiActive then return end
    if Character then
        local marker = Character:FindFirstChild("CYBER_SANDI_ACTIVE")
        if marker then marker:Destroy() end
    end
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj.Name == "HologramClone" and obj:FindFirstChild("IsSandiClone") then
            obj:Destroy()
        end
    end
    State.IsSandiActive = false
    PlaySFX(Sounds.SANDI_OFF)
    State.Cooldowns.SANDI = os.clock() + Constants.COOLDOWNS.SANDI
    State.NoRegenUntil = os.clock() + Constants.REGEN_DELAY_USE
    ShowCooldownText("Sandevistan", Constants.COOLDOWNS.SANDI, Colors.RAINBOW_SEQUENCE[1])
    local sandiEffect = Lighting:FindFirstChild("SandiEffect")
    if sandiEffect then
        TweenService:Create(sandiEffect, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TintColor = Color3.new(1,1,1), Contrast = 0, Saturation = 0}):Play()
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
    if originalGravity then Workspace.Gravity = originalGravity originalGravity = nil end
    for hum, speed in pairs(originalWalkSpeeds) do if hum and hum.Parent then hum.WalkSpeed = speed end end
    for hum, power in pairs(originalJumpPowers) do if hum and hum.Parent then hum.JumpPower = power end end
    for track, speed in pairs(originalAnimationSpeeds) do if track then track:AdjustSpeed(speed) end end
    for sound, speed in pairs(originalSoundSpeeds) do if sound and sound.Parent then sound.PlaybackSpeed = speed end end
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
    UpdateDashButton()
    UpdateKiroshiButton()
    UpdateOpticalButton()
    if State.MusicSound then State.MusicSound:Destroy() State.MusicSound = nil end
end

local function PlayActivationSequence()
    local textures = {"rbxassetid://118003464090928","rbxassetid://100849825361179","rbxassetid://96105818070338","rbxassetid://110826337725055","rbxassetid://139215133344337","rbxassetid://98416340638203","rbxassetid://114952882072808","rbxassetid://87959360506687","rbxassetid://99027028936189","rbxassetid://126972351917677"}
    local fullSeq = {}
    for _, tex in ipairs(textures) do table.insert(fullSeq, tex) end
    local gui = Player.PlayerGui:FindFirstChild("CyberRebuilt")
    if not gui then return end
    local overlay = Create("ImageLabel", {Name = "SandiTextureOverlay", Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1, ImageTransparency = 0.10, ZIndex = 100, Parent = gui})
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
    if State.IsSandiActive then ResetSandi() return end
    if State.Energy < Constants.ENERGY_COSTS.SANDI_ACTIVATE then return end
    if math.random() < Constants.SANDEVISTAN_FAILURE_CHANCE then TriggerSandevistanFailure() return end
    State.Energy -= Constants.ENERGY_COSTS.SANDI_ACTIVATE
    State.Energy = math.max(0, State.Energy)
    State.NoRegenUntil = os.clock() + Constants.REGEN_DELAY_USE
    State.IsSandiActive = true
    PlaySFX(Sounds.SANDI_ON)
    CamShake(1.5, 0.4)
    TweenService:Create(Camera, TweenInfo.new(0.4), {FieldOfView = 115}):Play()
    local sandiEffect = Create("ColorCorrectionEffect", {Name = "SandiEffect", TintColor = Color3.new(1,1,1), Contrast = 0, Saturation = 0, Parent = Lighting})
    TweenService:Create(sandiEffect, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TintColor = Colors.LIGHT_GREEN, Contrast = 0.15, Saturation = 0.3}):Play()
    PlayActivationSequence()
    ScreenFade(0.25, 0.1, 0.4, Colors.LIGHT_GREEN, 0.7, 0.3)
    local sandiMarker = Instance.new("BoolValue")
    sandiMarker.Name = "CYBER_SANDI_ACTIVE"
    sandiMarker.Parent = Character
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
end

local function ExecDash()
    if State.IsSandiActive then return end
    if State.Energy < Constants.ENERGY_COSTS.DASH or os.clock() < State.Cooldowns.DASH then return end
    State.Energy -= Constants.ENERGY_COSTS.DASH
    State.Energy = math.max(0, State.Energy)
    State.NoRegenUntil = os.clock() + Constants.REGEN_DELAY_USE
    State.Cooldowns.DASH = os.clock() + Constants.COOLDOWNS.DASH
    PlaySFX(Sounds.DASH)
    ShowCooldownText("Dash Impulse", Constants.COOLDOWNS.DASH, Colors.DASH_GREEN)
    ScreenFade(0.15, 0, 0.35, Colors.DASH_GREEN, 0.5, 0.2)
    local dashEffect = Create("ColorCorrectionEffect", {Name = "DashEffect", TintColor = Color3.new(1,1,1), Contrast = 0, Saturation = 0, Parent = Lighting})
    TweenService:Create(dashEffect, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TintColor = Colors.DASH_GREEN, Contrast = 0.1, Saturation = -0.1}):Play()
    TweenService:Create(Camera, TweenInfo.new(0.25), {FieldOfView = 125}):Play()
    local direction
    if Humanoid.FloorMaterial ~= Enum.Material.Air then
        local lookVector = HRP.CFrame.LookVector
        local moveDir = Humanoid.MoveDirection
        direction = moveDir:Dot(lookVector) < 0 and -lookVector or lookVector
    else
        direction = Camera.CFrame.LookVector
    end
    local bv = Create("BodyVelocity", {MaxForce = Vector3.new(1e6, 1e6, 1e6), Velocity = direction * Constants.DASH_FORCE, Parent = HRP})
    local collisionConn
    collisionConn = HRP.Touched:Connect(function(hit)
        local hitParent = hit.Parent
        if hitParent then
            local otherHum = hitParent:FindFirstChildOfClass("Humanoid")
            if otherHum and otherHum ~= Humanoid and otherHum.Health > 0 then
                if bv and bv.Parent then bv:Destroy() end
                HRP.Velocity = Vector3.new(0, HRP.Velocity.Y, 0)
                PlaySFX(Sounds.COLLISION_IMPACT)
                if collisionConn then 
                    collisionConn:Disconnect()
                    collisionConn = nil
                end
            end
        end
    end)
    Debris:AddItem(bv, 0.25)
    task.spawn(function()
        local start = os.clock()
        while os.clock() - start < 0.25 do
            if not LiteMode then
                CreateHologramClone(Constants.HOLOGRAM_CLONE.DASH.DELAY, Constants.HOLOGRAM_CLONE.DASH.DURATION, Constants.HOLOGRAM_CLONE.DASH.END_TRANSPARENCY, 0, 0, 0, "dash")
            end
            RunService.Heartbeat:Wait()
        end
        if collisionConn then collisionConn:Disconnect() end
        TweenService:Create(dashEffect, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TintColor = Color3.new(1,1,1), Contrast = 0, Saturation = 0}):Play()
        TweenService:Create(Camera, TweenInfo.new(0.4), {FieldOfView = 70}):Play()
        Debris:AddItem(dashEffect, 0.45)
    end)
    local dashSignal = Instance.new("StringValue")
    dashSignal.Name = "CYBER_DASH"
    dashSignal.Value = tostring(HRP.CFrame)
    dashSignal.Parent = Character
    Debris:AddItem(dashSignal, 0.4)
end

local function ExecKiroshi()
    if State.IsSandiActive then return end
    if State.Energy < Constants.ENERGY_COSTS.KIROSHI or os.clock() < State.Cooldowns.KIROSHI or State.IsKiroshiActive then return end
    State.Energy -= Constants.ENERGY_COSTS.KIROSHI
    State.Energy = math.max(0, State.Energy)
    State.NoRegenUntil = os.clock() + Constants.REGEN_DELAY_USE
    State.IsKiroshiActive = true
    PlaySFX(Sounds.KIROSHI_ON)
    ScreenFade(0.3, 0.2, 0.6, Colors.KIROSHI_RED, 0.7, 0.25)
    local kiroshiCC = Create("ColorCorrectionEffect", {Name = "KiroshiCC", TintColor = Colors.KIROSHI_RED, Saturation = 0.5, Contrast = 0.2, Parent = Lighting})
    for _, p in Players:GetPlayers() do
        if p ~= Player then
            local char = p.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local highlight = Create("Highlight", {
                    OutlineColor = Colors.KIROSHI_RED,
                    FillColor = Colors.KIROSHI_RED,
                    FillTransparency = 0.85,
                    OutlineTransparency = 0,
                    Parent = char
                })
                table.insert(activeHighlights, highlight)
                local billboard = Create("BillboardGui", {
                    Size = UDim2.new(0, 120, 0, 52),
                    StudsOffset = Vector3.new(0, 3, 0),
                    AlwaysOnTop = true,
                    Parent = char
                })
                local frame = Create("Frame", {Size = UDim2.new(1,0,1,0), BackgroundTransparency = 0.4, BackgroundColor3 = Color3.new(0,0,0), Parent = billboard})
                Create("UICorner", {CornerRadius = UDim.new(0,6), Parent = frame})
                local hpBarBG = Create("Frame", {Size = UDim2.new(0.88,0,0.16,0), Position = UDim2.new(0.06,0,0.12,0), BackgroundColor3 = Color3.new(0.1,0.1,0.1), Parent = frame})
                Create("UICorner", {Parent = hpBarBG})
                local hpBar = Create("Frame", {Size = UDim2.new(1,0,1,0), BackgroundColor3 = Colors.KIROSHI_RED, Parent = hpBarBG})
                Create("UICorner", {Parent = hpBar})
                local nameLabel = Create("TextLabel", {Size = UDim2.new(1,0,0.38,0), Position = UDim2.new(0,0,0.28,0), BackgroundTransparency = 1, Text = p.DisplayName:upper(), TextColor3 = Colors.KIROSHI_RED, Font = Enum.Font.SciFi, TextSize = 12, Parent = frame})
                local distLabel = Create("TextLabel", {Size = UDim2.new(1,0,0.28,0), Position = UDim2.new(0,0,0.68,0), BackgroundTransparency = 1, Text = "DIST: 00m", TextColor3 = Color3.new(1,1,1), Font = Enum.Font.Code, TextSize = 10, Parent = frame})
                table.insert(activeHighlights, billboard)
                task.spawn(function()
                    while State.IsKiroshiActive and char.Parent do
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if hum and HRP then
                            local dist = math.floor((HRP.Position - char.HumanoidRootPart.Position).Magnitude)
                            distLabel.Text = string.format("DIST: %dm", dist)
                            local hpPercent = hum.Health / hum.MaxHealth
                            hpBar.Size = UDim2.new(hpPercent, 0, 1, 0)
                            if hpPercent < 0.4 then nameLabel.Text = "THREAT HIGH" end
                        end
                        task.wait(0.08)
                    end
                end)
            end
        end
    end
    task.spawn(function()
        task.wait(5)
        if not State.IsKiroshiActive then return end
        PlaySFX(Sounds.KIROSHI_OFF)
        ScreenFade(0.4, 0, 0.6, Colors.KIROSHI_RED, 0.3, 0.1)
        State.IsKiroshiActive = false
        State.Cooldowns.KIROSHI = os.clock() + Constants.COOLDOWNS.KIROSHI
        ShowCooldownText("KIROSHI OPTICS", Constants.COOLDOWNS.KIROSHI, Colors.KIROSHI)
        if kiroshiCC then TweenService:Create(kiroshiCC, TweenInfo.new(0.6), {Saturation = 0, Contrast = 0}):Play() task.delay(0.7, function() kiroshiCC:Destroy() end) end
        for _, h in ipairs(activeHighlights) do if h then h:Destroy() end end
        activeHighlights = {}
    end)
end

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
    if State.IsOpticalActive then ResetOptical() return end
    if os.clock() < State.Cooldowns.OPTICAL then return end
    if State.Energy < Constants.ENERGY_COSTS.OPTICAL then return end
    State.Energy -= Constants.ENERGY_COSTS.OPTICAL
    State.Energy = math.max(0, State.Energy)
    State.NoRegenUntil = os.clock() + Constants.REGEN_DELAY_USE
    State.IsOpticalActive = true
    activateInvisibility()
    opticalToken += 1
    local myToken = opticalToken
    task.delay(Constants.OPTICAL_DURATION, function()
        if myToken == opticalToken then ResetOptical() end
    end)
end

local function SpawnRebootWindow()
    if not HRP then return end
    local part = Instance.new("Part")
    part.Name = "RebootSystemWindow"
    part.Size = Vector3.new(0, 0, 0.08)
    part.Color = Color3.fromRGB(0, 195, 255)
    part.Material = Enum.Material.Neon
    part.Transparency = 0.03
    part.CanCollide = false
    part.Anchored = true
    part.CastShadow = false
    part.Parent = Workspace
    local sgui = Instance.new("SurfaceGui", part)
    sgui.Face = Enum.NormalId.Front
    sgui.PixelsPerStud = 65
    local frame = Instance.new("Frame", sgui)
    frame.Size = UDim2.new(1,0,1,0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 12, 28)
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Color3.fromRGB(80, 220, 255)
    stroke.Thickness = 6
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1,-20,0.65,0)
    title.Position = UDim2.new(0,10,0,8)
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.fromRGB(80, 255, 220)
    title.Font = Enum.Font.SciFi
    title.TextSize = 52
    title.TextStrokeTransparency = 0.4
    title.Text = "REBOOT SYSTEM"
    local subtitle = Instance.new("TextLabel", frame)
    subtitle.Size = UDim2.new(1,-20,0.28,0)
    subtitle.Position = UDim2.new(0,10,0.68,0)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "NEURAL INTERFACE RESTORED"
    subtitle.TextColor3 = Color3.fromRGB(180, 255, 240)
    subtitle.Font = Enum.Font.Code
    subtitle.TextSize = 22
    local function updatePosition()
        if HRP and part.Parent then
            local frontOffset = HRP.CFrame.LookVector * 7 + Vector3.new(0, 1.5, 0)
            part.CFrame = CFrame.lookAt(HRP.Position + frontOffset, HRP.Position)
        end
    end
    updatePosition()
    TweenService:Create(part, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = Vector3.new(5.2, 3.1, 0.08)}):Play()
    local followConn = RunService.Heartbeat:Connect(updatePosition)
    task.delay(3, function()
        if followConn then followConn:Disconnect() end
        if part and part.Parent then
            TweenService:Create(part, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {Size = Vector3.new(0.1, 0.1, 0.08)}):Play()
            task.delay(0.5, function() part:Destroy() end)
        end
    end)
end

local function SpawnAnimation()
    local spawnSound = Instance.new("Sound")
    spawnSound.SoundId = "rbxassetid://121480304779842"
    spawnSound.Volume = 2.0
    spawnSound.PlaybackSpeed = 1
    spawnSound.Parent = Camera
    spawnSound:Play()
    task.delay(3, function()
        if spawnSound and spawnSound.Parent then
            spawnSound:Stop()
            spawnSound:Destroy()
        end
    end)
    if not HRP then return end
    local gui = Player.PlayerGui:FindFirstChild("CyberRebuilt") or Instance.new("ScreenGui", Player.PlayerGui)
    local rebootText = Instance.new("TextLabel")
    rebootText.Size = UDim2.new(1,0,0.14,0)
    rebootText.Position = UDim2.new(0,0,-0.2,0)
    rebootText.BackgroundTransparency = 1
    rebootText.TextColor3 = Color3.fromRGB(0, 255, 220)
    rebootText.Font = Enum.Font.SciFi
    rebootText.TextSize = 92
    rebootText.TextTransparency = 1
    rebootText.TextStrokeTransparency = 0.6
    rebootText.Parent = gui
    TweenService:Create(rebootText, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0,0,0.08,0), TextTransparency = 0}):Play()
    task.spawn(function()
        local baseText = "REBOOT SEQUENCE"
        local dotsCycle = {".", "..", "..."}
        local idx = 1
        local startTimeText = os.clock()
        while os.clock() - startTimeText < 3 do
            rebootText.Text = baseText .. dotsCycle[idx]
            idx = idx % 3 + 1
            task.wait(0.35)
        end
    end)
    task.delay(3, function()
        TweenService:Create(rebootText, TweenInfo.new(0.8), {TextTransparency = 1, Position = UDim2.new(0,0,-0.1,0)}):Play()
        task.delay(1, function() rebootText:Destroy() end)
    end)
    SpawnRebootWindow()
end

local function UpdateKeybind(ability)
    ContextActionService:UnbindAction(AbilityActions[ability])
    ContextActionService:BindAction(AbilityActions[ability], function(_, inputState)
        if inputState == Enum.UserInputState.Begin then
            if ability == "Dash" then ExecDash()
            elseif ability == "Sandi" then ExecSandi()
            elseif ability == "Kiroshi" then ExecKiroshi()
            elseif ability == "Optical" then ExecOptical()
            elseif ability == "Dodge" then ActivateDodgeReady() end
        end
        return Enum.ContextActionResult.Sink
    end, false, CurrentKeybinds[ability])
end

local function BindAllKeybinds()
    for ab in pairs(CurrentKeybinds) do UpdateKeybind(ab) end
end

local function LimparAcessorios()
    local char = Player.Character
    if char then
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("Accessory") and (v.Name:find("SetItem_") or v:FindFirstChild("AutoWeldTag")) then v:Destroy() end
        end
    end
end

local function AplicarSet(listaIds)
    local character = Player.Character or Player.CharacterAdded:Wait()
    LimparAcessorios()
    for _, id in pairs(listaIds) do
        task.spawn(function()
            local sucesso, objects = pcall(function() return game:GetObjects("rbxassetid://" .. id) end)
            if sucesso and objects and objects[1] then
                local asset = objects[1]:Clone()
                asset.Name = "SetItem_" .. id
                local tag = Instance.new("BoolValue")
                tag.Name = "AutoWeldTag"
                tag.Parent = asset
                local handle = asset:IsA("BasePart") and asset or asset:FindFirstChild("Handle", true)
                if handle then
                    for _, v in pairs(asset:GetDescendants()) do if v:IsA("LuaSourceContainer") then v:Destroy() end end
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
                                if found then partAlvo = parte attachmentCorpo = found break end
                            end
                        end
                    end
                    if not partAlvo then partAlvo = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart") end
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
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and dragging and State.EditMode then
            local delta = input.Position - dragStart
            movable.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
end

local function CreateEnergyBar(gui)
    local container = Create("Frame", {
        Name = "EnergyBar",
        Size = UDim2.new(0, 32, 0, 310),
        Position = UDim2.new(0, 28, 0.5, -155),
        BackgroundColor3 = Color3.fromRGB(4, 4, 9),
        BorderSizePixel = 0,
        Parent = gui
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 18), Parent = container})

    Create("UIStroke", {Color = Colors.CYBER_CHROME, Thickness = 7, Transparency = 0.05, Parent = container})
    Create("UIStroke", {Color = Colors.UI_NEON, Thickness = 3.5, Transparency = 0.45, Parent = container})

    local innerGlow = Create("UIStroke", {Color = Colors.CYBER_ORANGE, Thickness = 12, Transparency = 0.75, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = container})

    local inner = Create("Frame", {Size = UDim2.new(1, -10, 1, -10), Position = UDim2.new(0, 5, 0, 5), BackgroundColor3 = Color3.fromRGB(2, 2, 7), BorderSizePixel = 0, Parent = container})
    Create("UICorner", {CornerRadius = UDim.new(0, 14), Parent = inner})

    energyFill = Create("Frame", {
    Name = "Fill",
    Size = UDim2.new(1, -12, 1, -12),
    Position = UDim2.new(0, 6, 1, -6),
    AnchorPoint = Vector2.new(0, 1),
    ClipsDescendants = true,
        BackgroundColor3 = Colors.LIGHT_GREEN,
        BorderSizePixel = 0,
        Parent = inner
    })
    local fillGradient = Create("UIGradient", {Color = ColorSequence.new(Colors.LIGHT_GREEN, Colors.CYBER_ORANGE), Rotation = 90, Parent = energyFill})
    Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = energyFill})

    local scanline = Create("Frame", {Size = UDim2.new(1, 0, 0, 3), BackgroundColor3 = Color3.fromRGB(255,255,255), BackgroundTransparency = 0.7, Parent = energyFill})
    Create("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(0.5,0), NumberSequenceKeypoint.new(1,1)}), Parent = scanline})
    task.spawn(function()
        while energyFill.Parent do
            scanline.Position = UDim2.new(0, 0, math.random(), 0)
            TweenService:Create(scanline, TweenInfo.new(0.6, Enum.EasingStyle.Linear), {Position = UDim2.new(0,0,1,0)}):Play()
            task.wait(0.6)
        end
    end)

    local coreLabel = Create("TextLabel", {
        Size = UDim2.new(0, 34, 0, 160),
        Position = UDim2.new(1, 14, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        Text = "NEURAL\nCORE",
        TextColor3 = Colors.CYBER_ORANGE,
        Font = Enum.Font.SciFi,
        TextSize = 16,
        TextStrokeTransparency = 0.35,
        Rotation = -90,
        Parent = container
    })

    energyPercentLabel = Create("TextLabel", {
        Size = UDim2.new(0, 50, 0, 22),
        Position = UDim2.new(0.5, 0, 1, 12),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundTransparency = 1,
        Text = "100%",
        TextColor3 = Colors.UI_NEON,
        Font = Enum.Font.Code,
        TextSize = 18,
        TextStrokeTransparency = 0.25,
        Parent = container
    })

    local circuitTop = Create("Frame", {Size = UDim2.new(1, -14, 0, 2), Position = UDim2.new(0, 7, 0, 9), BackgroundColor3 = Colors.UI_NEON, BorderSizePixel = 0, Parent = container})
    Create("UIGradient", {Color = ColorSequence.new(Color3.fromRGB(255,255,255), Colors.UI_NEON), Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(0.4,0), NumberSequenceKeypoint.new(1,1)}), Parent = circuitTop})

    local circuitBottom = Create("Frame", {Size = UDim2.new(1, -14, 0, 2), Position = UDim2.new(0, 7, 1, -11), BackgroundColor3 = Colors.UI_NEON, BorderSizePixel = 0, Parent = container})
    Create("UIGradient", {Color = ColorSequence.new(Color3.fromRGB(255,255,255), Colors.UI_NEON), Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(0.4,0), NumberSequenceKeypoint.new(1,1)}), Parent = circuitBottom})

    return container
end

local function BuildUI()
    if Player.PlayerGui:FindFirstChild("CyberRebuilt") then Player.PlayerGui.CyberRebuilt:Destroy() end
    local gui = Create("ScreenGui", {Name = "CyberRebuilt", Parent = Player.PlayerGui, IgnoreGuiInset = true})

    local hudOverlay = Create("Frame", {Size = UDim2.new(1,0,1,0), BackgroundColor3 = Color3.fromRGB(0,0,0), BackgroundTransparency = 0.92, Parent = gui})
    Create("UIGradient", {Color = ColorSequence.new(Color3.fromRGB(10,10,15), Color3.fromRGB(0,0,0)), Rotation = 90, Parent = hudOverlay})

    CreateEnergyBar(gui)
    KeybindCurrentTexts = {}

    local lockBtn = Create("TextButton", {Name = "LockBtn", Size = ButtonConfigs.LockBtn.Size, Position = ButtonConfigs.LockBtn.Position, Text = ButtonConfigs.LockBtn.Text, BackgroundColor3 = ButtonConfigs.LockBtn.BackgroundColor3, TextColor3 = ButtonConfigs.LockBtn.TextColor3, Font = ButtonConfigs.LockBtn.Font, TextSize = ButtonConfigs.LockBtn.TextSize, Parent = gui})
    Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = lockBtn})
    local lockStroke1 = Create("UIStroke", {Color = Colors.CYBER_CHROME, Thickness = 3, Transparency = 0.3, Parent = lockBtn})
    local lockStroke2 = Create("UIStroke", {Color = Colors.UI_NEON, Thickness = 1.5, Transparency = 0.6, Parent = lockBtn})
    local lockGradient = Create("UIGradient", {Color = ColorSequence.new(Colors.UI_DARK, Colors.CYBER_ORANGE), Rotation = 45, Parent = lockBtn})

    local function CreateSkillBtn(key, color, pos, name, func)
        local btnContainer = Create("Frame", {Name = name .. "Container", Size = UDim2.new(0, 54, 0, 54), Position = savedPositions[name] or pos, BackgroundTransparency = 1, Parent = gui})

        local btn = Create("TextButton", {Name = name, Size = UDim2.new(1, 0, 1, 0), Text = key, BackgroundColor3 = Colors.UI_DARK, TextColor3 = color, Font = Enum.Font.SciFi, TextSize = 21, AutoButtonColor = false, Parent = btnContainer})

        local strokeOuter = Create("UIStroke", {Color = color, Thickness = 3.5, Transparency = 0.25, Parent = btn})
        local strokeInner = Create("UIStroke", {Color = Colors.CYBER_CHROME, Thickness = 1.2, Transparency = 0.5, Parent = btn})

        Create("UICorner", {CornerRadius = UDim.new(0, 14), Parent = btn})

        local gradient = Create("UIGradient", {Color = ColorSequence.new(Colors.UI_DARK, color:Lerp(Colors.UI_NEON, 0.45)), Rotation = 35, Parent = btn})

        local glow = Create("UIStroke", {Color = Colors.UI_GLOW, Thickness = 4.5, Transparency = 0.78, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = btn})

        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundColor3 = color:Lerp(Colors.CYBER_ORANGE, 0.3)}):Play()
            TweenService:Create(glow, TweenInfo.new(0.15), {Transparency = 0.35}):Play()
            TweenService:Create(strokeOuter, TweenInfo.new(0.15), {Thickness = 4.2}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {BackgroundColor3 = Colors.UI_DARK}):Play()
            TweenService:Create(glow, TweenInfo.new(0.2), {Transparency = 0.78}):Play()
            TweenService:Create(strokeOuter, TweenInfo.new(0.2), {Thickness = 3.5}):Play()
        end)

        btn.MouseButton1Down:Connect(function()
            if not State.EditMode then
                TweenService:Create(btn, TweenInfo.new(0.08, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0.9, 0, 0.9, 0), BackgroundColor3 = color}):Play()
                func()
            end
        end)
        btn.MouseButton1Up:Connect(function()
            if not State.EditMode then
                TweenService:Create(btn, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Colors.UI_DARK}):Play()
            end
        end)

        TweenService:Create(btn, TweenInfo.new(2.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Rotation = 2.8}):Play()

        MakeDraggable(btnContainer, btn)
        SkillContainers[name] = btnContainer

        if name == "SandiBtn" then
            task.spawn(function()
                while btn.Parent do
                    local hue = (os.clock() % 4.5) / 4.5
                    local rainbowColor = Color3.fromHSV(hue, 1, 1)
                    btn.TextColor3 = rainbowColor
                    strokeOuter.Color = rainbowColor
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

    for abilityKey, isEnabled in pairs(EnabledAbilities) do
        local btnName = AbilityMap[abilityKey]
        if btnName and SkillContainers[btnName] then
            local visible = isEnabled
            if btnName == "DodgeBtn" then visible = visible and (DodgeMode == "Counter") end
            SkillContainers[btnName].Visible = visible
        end
    end

    local settingsMenu = Create("Frame", {
    Name = "SettingsMenu", 
    Size = UDim2.new(0, 0, 0, 0),  -- Tamanho inicial 0
    Position = UDim2.new(0, 78, 0, 28), 
    BackgroundColor3 = Color3.fromRGB(4,4,8), 
    Visible = false,
    BorderSizePixel = 0, 
    Parent = gui
})
    Create("UICorner", {CornerRadius = UDim.new(0, 16), Parent = settingsMenu})
    local menuStroke1 = Create("UIStroke", {Color = Colors.CYBER_CHROME, Thickness = 4, Transparency = 0.2, Parent = settingsMenu})
    local menuStroke2 = Create("UIStroke", {Color = Colors.UI_NEON, Thickness = 1.5, Transparency = 0.55, Parent = settingsMenu})

    local title = Create("TextLabel", {Size = UDim2.new(1, 0, 0, 54), BackgroundTransparency = 1, Text = "NEURAL INTERFACE\nCYBER REBUILT 2077", TextColor3 = Colors.CYBER_ORANGE, Font = Enum.Font.SciFi, TextSize = 19, TextStrokeTransparency = 0.5, Parent = settingsMenu})

    local scroll = Create("ScrollingFrame", {Name = "AbilitiesScroll", Size = UDim2.new(1, -24, 1, -148), Position = UDim2.new(0, 12, 0, 66), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 6, ScrollBarImageColor3 = Colors.UI_NEON, Parent = settingsMenu})
    Create("UIListLayout", {Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder, Parent = scroll})

    local abilitiesList = {
        {display = "DASH IMPULSE", key = "Dash", color = Colors.DASH_GREEN},
        {display = "SANDEVISTAN", key = "Sandi", color = Colors.SANDI_TINT},
        {display = "KIROSHI OPTICS", key = "Kiroshi", color = Colors.KIROSHI},
        {display = "OPTICAL CAMO", key = "Optical", color = Colors.OPTICAL},
        {display = "NEURAL DODGE", key = "Dodge", color = Colors.DODGE_START}
    }
    for _, ab in ipairs(abilitiesList) do
        local row = Create("Frame", {Size = UDim2.new(1, 0, 0, 54), BackgroundColor3 = Colors.UI_BG, BorderSizePixel = 0, Parent = scroll})
        Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = row})
        Create("TextLabel", {Size = UDim2.new(0.64, 0, 1, 0), BackgroundTransparency = 1, Text = "  " .. ab.display, TextColor3 = ab.color, Font = Enum.Font.SciFi, TextSize = 19, TextXAlignment = Enum.TextXAlignment.Left, Parent = row})

        local tog = Create("TextButton", {Size = UDim2.new(0.29, 0, 0.78, 0), Position = UDim2.new(0.68, 0, 0.11, 0), Text = EnabledAbilities[ab.key] and "ON" or "OFF", BackgroundColor3 = EnabledAbilities[ab.key] and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(200, 40, 40), TextColor3 = Color3.new(1,1,1), Font = Enum.Font.SciFi, TextSize = 17, Parent = row})
        Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = tog})

        tog.MouseButton1Click:Connect(function()
            EnabledAbilities[ab.key] = not EnabledAbilities[ab.key]
            tog.Text = EnabledAbilities[ab.key] and "ON" or "OFF"
            tog.BackgroundColor3 = EnabledAbilities[ab.key] and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(200, 40, 40)
            if ab.key == "Dodge" and not EnabledAbilities.Dodge then State.IsDodgeReady = false end
            local btnName = AbilityMap[ab.key]
            if btnName and SkillContainers[btnName] then
                local visible = EnabledAbilities[ab.key]
                if btnName == "DodgeBtn" then visible = visible and DodgeMode == "Counter" end
                SkillContainers[btnName].Visible = visible
            end
        end)
    end

    local modeRow = Create("Frame", {Size = UDim2.new(1, 0, 0, 54), BackgroundColor3 = Colors.UI_BG, BorderSizePixel = 0, Parent = scroll})
    Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = modeRow})
    Create("TextLabel", {Size = UDim2.new(0.64, 0, 1, 0), BackgroundTransparency = 1, Text = "  DODGE MODE", TextColor3 = Colors.DODGE_START, Font = Enum.Font.SciFi, TextSize = 19, TextXAlignment = Enum.TextXAlignment.Left, Parent = modeRow})
    local modeToggle = Create("TextButton", {Size = UDim2.new(0.29, 0, 0.78, 0), Position = UDim2.new(0.68, 0, 0.11, 0), Text = DodgeMode == "Counter" and "COUNTER" or "AUTO", BackgroundColor3 = DodgeMode == "Counter" and Color3.fromRGB(255, 165, 0) or Color3.fromRGB(0, 255, 255), TextColor3 = Color3.new(1,1,1), Font = Enum.Font.SciFi, TextSize = 17, Parent = modeRow})
    Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = modeToggle})
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
        if SkillContainers["DodgeBtn"] then SkillContainers["DodgeBtn"].Visible = (EnabledAbilities.Dodge and DodgeMode == "Counter") end
    end)

    local liteRow = Create("Frame", {Size = UDim2.new(1, 0, 0, 52), BackgroundColor3 = Colors.UI_BG, BorderSizePixel = 0, Parent = scroll})
    Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = liteRow})
    Create("TextLabel", {Size = UDim2.new(0.65, 0, 1, 0), BackgroundTransparency = 1, Text = "  MODO LITE", TextColor3 = Colors.UI_NEON, Font = Enum.Font.SciFi, TextSize = 19, TextXAlignment = Enum.TextXAlignment.Left, Parent = liteRow})
    local liteToggle = Create("TextButton", {Size = UDim2.new(0.28, 0, 0.75, 0), Position = UDim2.new(0.69, 0, 0.125, 0), Text = LiteMode and "ON" or "OFF", BackgroundColor3 = LiteMode and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(200, 40, 40), TextColor3 = Color3.new(1,1,1), Font = Enum.Font.SciFi, TextSize = 17, Parent = liteRow})
    Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = liteToggle})
    liteToggle.MouseButton1Click:Connect(function()
        LiteMode = not LiteMode
        liteToggle.Text = LiteMode and "ON" or "OFF"
        liteToggle.BackgroundColor3 = LiteMode and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(200, 40, 40)
    end)

    local noclipRow = Create("Frame", {Size = UDim2.new(1, 0, 0, 52), BackgroundColor3 = Colors.UI_BG, BorderSizePixel = 0, Parent = scroll})
    Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = noclipRow})
    Create("TextLabel", {Size = UDim2.new(0.65, 0, 1, 0), BackgroundTransparency = 1, Text = "  NOCLIP", TextColor3 = Colors.UI_NEON, Font = Enum.Font.SciFi, TextSize = 19, TextXAlignment = Enum.TextXAlignment.Left, Parent = noclipRow})
    local noclipToggle = Create("TextButton", {Size = UDim2.new(0.28, 0, 0.75, 0), Position = UDim2.new(0.69, 0, 0.125, 0), Text = Noclip and "ON" or "OFF", BackgroundColor3 = Noclip and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(200, 40, 40), TextColor3 = Color3.new(1,1,1), Font = Enum.Font.SciFi, TextSize = 17, Parent = noclipRow})
    Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = noclipToggle})
    noclipToggle.MouseButton1Click:Connect(function()
        ToggleNoclip()
        noclipToggle.Text = Noclip and "ON" or "OFF"
        noclipToggle.BackgroundColor3 = Noclip and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(200, 40, 40)
    end)

    local keybindsHeader = Create("TextLabel", {Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, Text = "  CUSTOM KEYBINDS", TextColor3 = Colors.UI_NEON, Font = Enum.Font.SciFi, TextSize = 21, TextXAlignment = Enum.TextXAlignment.Left, Parent = scroll})

    local keybindList = {
        {name = "DASH IMPULSE", ab = "Dash", color = Colors.DASH_GREEN},
        {name = "SANDEVISTAN", ab = "Sandi", color = Colors.SANDI_TINT},
        {name = "KIROSHI OPTICS", ab = "Kiroshi", color = Colors.KIROSHI},
        {name = "OPTICAL CAMO", ab = "Optical", color = Colors.OPTICAL},
        {name = "NEURAL DODGE", ab = "Dodge", color = Colors.DODGE_START}
    }
    for _, kb in ipairs(keybindList) do
        local row = Create("Frame", {Size = UDim2.new(1, 0, 0, 54), BackgroundColor3 = Colors.UI_BG, BorderSizePixel = 0, Parent = scroll})
        Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = row})
        Create("TextLabel", {Size = UDim2.new(0.48, 0, 1, 0), BackgroundTransparency = 1, Text = "  " .. kb.name, TextColor3 = kb.color, Font = Enum.Font.SciFi, TextSize = 19, TextXAlignment = Enum.TextXAlignment.Left, Parent = row})
        local currentKeyText = Create("TextLabel", {Size = UDim2.new(0.26, 0, 1, 0), Position = UDim2.new(0.48, 0, 0, 0), BackgroundTransparency = 1, Text = CurrentKeybinds[kb.ab].Name, TextColor3 = Colors.UI_NEON, Font = Enum.Font.Code, TextSize = 21, Parent = row})
        KeybindCurrentTexts[kb.ab] = currentKeyText
        local rebindButton = Create("TextButton", {Size = UDim2.new(0.22, 0, 0.78, 0), Position = UDim2.new(0.76, 0, 0.11, 0), Text = "REBIND", BackgroundColor3 = Colors.UI_ACCENT, TextColor3 = Colors.UI_NEON, Font = Enum.Font.SciFi, TextSize = 16, Parent = row})
        Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = rebindButton})
        rebindButton.MouseButton1Click:Connect(function() RebindingAbility = kb.ab end)
    end

    local setsRow = Create("Frame", {Size = UDim2.new(1, 0, 0, 64), BackgroundTransparency = 1, Parent = scroll})
    local setsBtn = Create("TextButton", {Size = UDim2.new(0.9, 0, 0, 50), Position = UDim2.new(0.05, 0, 0, 6), Text = " TROCA SET", BackgroundColor3 = setColors[currentSet], TextColor3 = Colors.UI_NEON, Font = Enum.Font.SciFi, TextSize = 21, Parent = setsRow})
    Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = setsBtn})
    Create("UIStroke", {Color = Colors.UI_NEON, Thickness = 2.5, Parent = setsBtn})
    setsBtn.MouseButton1Click:Connect(function()
    if currentSet == 1 then
        currentSet = 2
        setsBtn.BackgroundColor3 = setColors[2]
        AplicarSet(SET_2)
    elseif currentSet == 2 then
        currentSet = 3
        setsBtn.BackgroundColor3 = setColors[3]
        AplicarSet(SET_3)
    else
        currentSet = 1
        setsBtn.BackgroundColor3 = setColors[1]
        AplicarSet(SET_1)
    end
end)

    scroll.CanvasSize = UDim2.new(0, 0, 0, scroll.UIListLayout.AbsoluteContentSize.Y + 160)

    MakeDraggable(gui:FindFirstChild("EnergyBar"), gui:FindFirstChild("EnergyBar"))
    lockBtn.MouseButton1Click:Connect(function()
        State.EditMode = not State.EditMode
        lockBtn.BackgroundColor3 = State.EditMode and Colors.EDIT_MODE or Colors.UI_DARK
        lockBtn.TextColor3 = State.EditMode and Colors.UI_DARK or Colors.UI_NEON
        for _, item in ipairs(UI_Elements) do item.Stroke.Enabled = State.EditMode end
        if not State.EditMode then
            savedPositions["EnergyContainer"] = gui:FindFirstChild("EnergyBar").Position
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
    if SkillContainers["DodgeBtn"] then SkillContainers["DodgeBtn"].Visible = (EnabledAbilities.Dodge and DodgeMode == "Counter") end

    -- ===== APLICAR ANIMAÇÕES =====
    ScanlineEffect(gui)
    task.delay(0.5, function() FullScreenGlitch() end)
    
    -- Glitch periódico a cada 30 segundos
    task.spawn(function()
        while gui.Parent do
            task.wait(30)
            FullScreenGlitch()
        end
    end)
    
    -- Aplicar pulsação em TODOS os botões de habilidade
    for _, btnName in pairs({"DashBtn", "SandiBtn", "KiroshiBtn", "OpticalBtn", "DodgeBtn"}) do
        local container = gui:FindFirstChild(btnName .. "Container")
        if container then
            local btn = container:FindFirstChild(btnName)
            if btn then
                PulseAnimation(btn)
            end
        end
    end
end

local function InitWalkEffect()
    if LiteMode then return end
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

local function UpdateDirectionalMovement()
    local now = workspace:GetServerTimeNow()
    if now - lastTime >= tickRate then
        lastTime = now
        local moveDirection = HRP.CFrame:VectorToObjectSpace(Humanoid.MoveDirection)
        if moveDirection:Dot(Vector3.new(1,0,-1).Unit) > dotThreshold then
            LerpJoints(moveDirection, {RootJoint = {math.rad(-moveDirection.Z) * 5, 0, math.rad(-moveDirection.X) * 25}, Neck = {math.rad(moveDirection.Z) * 5, 0, math.rad(moveDirection.X) * 15}, RightShoulder = {0, math.rad(-moveDirection.X) * 10, 0}, LeftShoulder = {0, math.rad(-moveDirection.X) * 10, 0}, RightHip = {0, math.rad(-moveDirection.X) * 10, 0}, LeftHip = {0, math.rad(-moveDirection.X) * 10, 0}})
        elseif moveDirection:Dot(Vector3.new(1,0,1).Unit) > dotThreshold then
            LerpJoints(moveDirection, {RootJoint = {math.rad(-moveDirection.Z) * 5, 0, math.rad(moveDirection.X) * 25}, Neck = {math.rad(moveDirection.Z) * 5, 0, math.rad(-moveDirection.X) * 25}, RightShoulder = {0, math.rad(moveDirection.X) * 10, 0}, LeftShoulder = {0, math.rad(moveDirection.X) * 10, 0}, RightHip = {0, math.rad(moveDirection.X) * 10, 0}, LeftHip = {0, math.rad(moveDirection.X) * 10, 0}})
        elseif moveDirection:Dot(Vector3.new(-1,0,1).Unit) > dotThreshold then
            LerpJoints(moveDirection, {RootJoint = {math.rad(-moveDirection.Z) * 5, 0, math.rad(moveDirection.X) * 25}, Neck = {math.rad(moveDirection.Z) * 5, 0, math.rad(-moveDirection.X) * 25}, RightShoulder = {0, math.rad(moveDirection.X) * 10, 0}, LeftShoulder = {0, math.rad(moveDirection.X) * 10, 0}, RightHip = {0, math.rad(moveDirection.X) * 10, 0}, LeftHip = {0, math.rad(moveDirection.X) * 10, 0}})
        elseif moveDirection:Dot(Vector3.new(-1,0,-1).Unit) > dotThreshold then
            LerpJoints(moveDirection, {RootJoint = {math.rad(-moveDirection.Z) * 5, 0, math.rad(-moveDirection.X) * 25}, Neck = {math.rad(moveDirection.Z) * 5, 0, math.rad(moveDirection.X) * 15}, RightShoulder = {0, math.rad(-moveDirection.X) * 10, 0}, LeftShoulder = {0, math.rad(-moveDirection.X) * 10, 0}, RightHip = {0, math.rad(-moveDirection.X) * 10, 0}, LeftHip = {0, math.rad(-moveDirection.X) * 10, 0}})
        elseif moveDirection:Dot(Vector3.new(0,0,-1).Unit) > dotThreshold then
            LerpJoints(moveDirection, {RootJoint = {math.rad(-moveDirection.Z) * 10, 0, 0}, Neck = {math.rad(moveDirection.Z) * 10, 0, 0}, RightShoulder = {0, 0, 0}, LeftShoulder = {0, 0, 0}, RightHip = {0, 0, 0}, LeftHip = {0, 0, 0}})
        elseif moveDirection:Dot(Vector3.new(1,0,0).Unit) > dotThreshold then
            LerpJoints(moveDirection, {RootJoint = {0, 0, math.rad(-moveDirection.X) * 35}, Neck = {0, 0, math.rad(moveDirection.X) * 35}, RightShoulder = {0, math.rad(-moveDirection.X) * 15, 0}, LeftShoulder = {0, math.rad(-moveDirection.X) * 15, 0}, RightHip = {0, math.rad(-moveDirection.X) * 15, 0}, LeftHip = {0, math.rad(-moveDirection.X) * 15, 0}})
        elseif moveDirection:Dot(Vector3.new(0,0,1).Unit) > dotThreshold then
            LerpJoints(moveDirection, {RootJoint = {math.rad(-moveDirection.Z) * 10, 0, 0}, Neck = {math.rad(moveDirection.Z) * 10, 0, 0}, RightShoulder = {0, 0, 0}, LeftShoulder = {0, 0, 0}, RightHip = {0, 0, 0}, LeftHip = {0, 0, 0}})
        elseif moveDirection:Dot(Vector3.new(-1,0,0).Unit) > dotThreshold then
            LerpJoints(moveDirection, {RootJoint = {0, 0, math.rad(-moveDirection.X) * 35}, Neck = {0, 0, math.rad(moveDirection.X) * 35}, RightShoulder = {0, math.rad(-moveDirection.X) * 15, 0}, LeftShoulder = {0, math.rad(-moveDirection.X) * 15, 0}, RightHip = {0, math.rad(-moveDirection.X) * 15, 0}, LeftHip = {0, math.rad(-moveDirection.X) * 15, 0}})
        else
            LerpJoints(moveDirection, {RootJoint = {0, 0, 0}, Neck = {0, 0, 0}, RightShoulder = {0, 0, 0}, LeftShoulder = {0, 0, 0}, RightHip = {0, 0, 0}, LeftHip = {0, 0, 0}})
        end
    end
end

local function InitDirectionalMovement()
    if LiteMode then return end
    local torso = Character:FindFirstChild("UpperTorso") or Character:FindFirstChild("Torso")
    if not torso then return end
    
    -- Verifica se é R15
    local isR15 = (torso:FindFirstChild("Neck") ~= nil)
    
    if isR15 then
        -- R15: usa RootJoint, Right Shoulder, Left Shoulder, Right Hip, Left Hip
        local rootJoint = HRP:FindFirstChild("RootJoint")
        local neck = torso:FindFirstChild("Neck")
        local rightShoulder = torso:FindFirstChild("Right Shoulder")
        local leftShoulder = torso:FindFirstChild("Left Shoulder")
        local rightHip = torso:FindFirstChild("Right Hip")
        local leftHip = torso:FindFirstChild("Left Hip")
        
        if not rootJoint or not neck or not rightShoulder or not leftShoulder or not rightHip or not leftHip then
            return -- Faltam juntas, não inicializa
        end
        
        Joints = {
            RootJoint = rootJoint,
            Neck = neck,
            RightShoulder = rightShoulder,
            LeftShoulder = leftShoulder,
            RightHip = rightHip,
            LeftHip = leftHip
        }
        
        JointsC0 = {
            RootJointC0 = rootJoint.C0,
            NeckC0 = neck.C0,
            RightShoulderC0 = rightShoulder.C0,
            LeftShoulderC0 = leftShoulder.C0,
            RightHipC0 = rightHip.C0,
            LeftHipC0 = leftHip.C0
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
end

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
            if DodgeMode == "Auto" then
                if State.Energy >= Constants.ENERGY_COSTS.DODGE then
                    State.Energy -= Constants.ENERGY_COSTS.DODGE
                    State.Energy = math.max(0, State.Energy)
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
        State.Energy = math.max(0, State.Energy)
        Humanoid.WalkSpeed = Constants.SANDI_SPEED
        if isMoving then
            if os.clock() - lastSandiClone > Constants.HOLOGRAM_CLONE.SANDI.DELAY then
                CreateHologramClone(Constants.HOLOGRAM_CLONE.SANDI.DELAY, Constants.HOLOGRAM_CLONE.SANDI.DURATION, Constants.HOLOGRAM_CLONE.SANDI.END_TRANSPARENCY, 0, 0, 0, "sandi")
                lastSandiClone = os.clock()
            end
            if sandiLoopSound and not sandiLoopSound.Playing then sandiLoopSound:Play()
            elseif not sandiLoopSound then
                sandiLoopSound = Create("Sound", {SoundId = Sounds.SANDI_LOOP.id, Volume = Sounds.SANDI_LOOP.volume, PlaybackSpeed = Sounds.SANDI_LOOP.pitch, Looped = Sounds.SANDI_LOOP.looped, Parent = HRP})
                sandiLoopSound:Play()
            end
        else
            if sandiLoopSound and sandiLoopSound.Playing then sandiLoopSound:Stop() end
        end
        if State.Energy <= 0 then
            State.NoRegenUntil = os.clock() + Constants.REGEN_DELAY_ZERO
            local luck = math.random(1, 100)
            if luck <= 30 then ExecCyberpsychosis() end
            ResetSandi()
        end
    else
        if os.clock() > State.NoRegenUntil then
            State.Energy = math.min(Constants.MAX_ENERGY, State.Energy + (Constants.REGEN_RATE * dt))
        end
    end
    if DodgeMode == "Auto" and os.clock() >= State.Cooldowns.DODGE and not State.IsDodgeReady and State.Energy >= Constants.ENERGY_COSTS.DODGE and EnabledAbilities.Dodge then
        ActivateDodgeReady()
    end
    if energyFill and energyPercentLabel then
        local percent = State.Energy / Constants.MAX_ENERGY
        local safePercent = math.max(0.02, percent)  -- Mínimo de 1% visível
energyFill.Size = UDim2.new(1, -10, safePercent, -10)
        energyPercentLabel.Text = string.format("%d%%", math.floor(State.Energy))
        local barColor
        if percent > 0.6 then
            barColor = Colors.LIGHT_GREEN
        elseif percent > 0.3 then
            barColor = Colors.ENERGY_MEDIUM
        else
            barColor = Colors.ENERGY_LOW
        end
        energyFill.BackgroundColor3 = barColor
    end
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if RebindingAbility then
        if input.KeyCode ~= Enum.KeyCode.Unknown then
            CurrentKeybinds[RebindingAbility] = input.KeyCode
            UpdateKeybind(RebindingAbility)
            if KeybindCurrentTexts[RebindingAbility] then KeybindCurrentTexts[RebindingAbility].Text = input.KeyCode.Name end
            RebindingAbility = nil
        end
        return
    end
end)

local function SetupCharacter(character)
    ResetSandi()
    ResetOptical()
    CleanupSandiSounds()
    Character = character
    HRP = character:WaitForChild("HumanoidRootPart")
    Humanoid = character:WaitForChild("Humanoid")
    State.LastHealth = Humanoid.Health
    BuildUI()
    BindAllKeybinds()
    InitWalkEffect()
    InitDirectionalMovement()
    
    task.delay(2, function()
        if Character and Character.Parent then
            if currentSet == 1 then
                AplicarSet(SET_1)
            elseif currentSet == 2 then
                AplicarSet(SET_2)
            else
                AplicarSet(SET_3)
            end
        end
    end)
end

-- ========== COMANDO DE CHAT -Settings ==========
Player.Chatted:Connect(function(message)
    local msg = message:lower():gsub("%s+", "")
    if msg == "-settings" then
        local gui = Player.PlayerGui:FindFirstChild("CyberRebuilt")
        if gui then
            local menu = gui:FindFirstChild("SettingsMenu")
            if menu then
                local newState = not menu.Visible
                
                if newState then
                    -- ===== ABRIR COM ANIMAÇÃO =====
                    menu.Visible = true
                    menu.Size = UDim2.new(0, 0, 0, 0)
                    menu.BackgroundTransparency = 1
                    TweenService:Create(menu, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                        Size = UDim2.new(0, 340, 0, 480),
                        BackgroundTransparency = 0
                    }):Play()
                    
                else
                    -- ===== FECHAR COM ANIMAÇÃO =====
                    local closeTween = TweenService:Create(menu, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                        Size = UDim2.new(0, 0, 0, 0),
                        BackgroundTransparency = 1
                    })
                    closeTween:Play()
                    
                    closeTween.Completed:Connect(function()
                        menu.Visible = false
                    end)
                end
            end
        end
    end
end)

local function Init()
    if Player.Character then 
        SetupCharacter(Player.Character)
        task.delay(0.3, SpawnAnimation)
    end
    Player.CharacterAdded:Connect(SetupCharacter)
end

Init()

if Player.Character then
    AplicarSet(SET_1)
end
