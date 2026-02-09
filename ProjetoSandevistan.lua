--!strict
--[[
    ╔═════════════════════════════════════════════════════════════════════════════╗
    ║               PREMIUM CYBERPUNK SANDEVISTAN - EDGERUNNERS STYLE V4.3        ║
    ║              INSPIRED BY DAVID MARTINEZ'S SANDEVISTAN FROM CYBERPUNK 2077   ║
    ║        UPDATES: Automatic Dodge removed. Registered as a Counter.        ║
    ╚═════════════════════════════════════════════════════════════════════════════╝
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local ContentProvider = game:GetService("ContentProvider")

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
    NoRegenUntil: number
}

--// CONSTANTES 
local Constants = {
    MAX_ENERGY = 100,
    SANDI_SPEED = 75,
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
            DELAY = 0.055,
            DURATION = 0.5,
            END_TRANSPARENCY = 0.9,
            OFFSET_X = 0,
            OFFSET_Y = 0,
            OFFSET_Z = 0
        },
        DASH = {
            DELAY = 0.45,
            DURATION = 0.4,
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
    DODGE_INVINCIBILITY_DURATION = 0,  
    KIROSHI_WEAKNESSES = {"Fogo", "Gelo", "Eletricidade", "Veneno"},  
    DODGE_CONFIG = {
        VARIANT_THRESHOLD = 5.5,
        VARIANT_DURATION = 0.2,
        VARIANT_CLONE_INTERVAL = 0.05,
        NORMAL_CLONE_SPACING = 2,
        NORMAL_DISTANCE_NO_ENEMY = 12,
        NORMAL_DISTANCE_ENEMY = 6
    },
    SANDEVISTAN_FAILURE_CHANCE = 0.3,  
    GLITCH_DURATION = 3
}

--// CONFIGURAÇÕES GERAIS 
local Configurations = {
    SLOW_GRAVITY_MULTIPLIER = Constants.SLOW_FACTOR ^ 2,  -- Ajuste para gravidade personalizada durante slow motion
    HOLOGRAM_MATERIAL = Enum.Material.Plastic,
    ASSETS = {
        TEXTURES = {
            SMOKE = "rbxassetid://243023223",
            SPARKS = "rbxassetid://6071575297",
            HEX = "rbxassetid://6522338870"
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

--// CORES 
local Colors = {
    SANDI_TINT = Color3.fromRGB(200, 255, 200),
    RAINBOW_SEQUENCE = {
        Color3.fromRGB(255, 0, 0),
        Color3.fromRGB(255, 165, 0),
        Color3.fromRGB(255, 255, 0),
        Color3.fromRGB(0, 255, 0),
        Color3.fromRGB(0, 0, 255),
        Color3.fromRGB(75, 0, 130),
        Color3.fromRGB(238, 130, 238)
    },
    DODGE_SEQUENCE = {
        Color3.fromRGB(160, 0, 255),  -- Roxo
        Color3.fromRGB(255, 0, 130)   -- Rosa
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
    KIROSHI_TINT = Color3.fromRGB(255, 100, 100),
    KIROSHI = Color3.fromRGB(255, 0, 0),
    OPTICAL = Color3.fromRGB(0, 255, 255),
    ENERGY_FULL = Color3.fromRGB(50, 205, 50),  
    ENERGY_MEDIUM = Color3.fromRGB(255, 255, 0), 
    ENERGY_LOW = Color3.fromRGB(255, 0, 0),  
    LIGHT_GREEN = Color3.fromRGB(100, 200, 100),  
    ERROR_TEXT = Color3.fromRGB(169, 169, 169),  
    ERROR_BORDER = Color3.fromRGB(105, 105, 105)  
}

--// SONS 
local Sounds = {
    DODGE_NORMAL = {id = "rbxassetid://120416852427789", volume = 1.5, pitch = 1, looped = false},
    DODGE_VARIANT = {id = "rbxassetid://80429302872625", volume = 1.5, pitch = 1, looped = false},
    DASH = {id = "rbxassetid://103247005619946", volume = 1.2, pitch = 1, looped = false},
    SANDI_ON = {id = "rbxassetid://123844681344865", volume = 1, pitch = 1, looped = false},
    SANDI_OFF = {id = "rbxassetid://118534165523355", volume = 1, pitch = 1, looped = false},
    SANDI_LOOP = {id = "rbxassetid://81793359483683", volume = 1, pitch = 1, looped = true},
    IDLE_MUSIC = {id = "rbxassetid://84295656118500", volume = 5, pitch = 1, looped = true},
    PSYCHOSIS = {id = "rbxassetid://87597277352254", volume = 2, pitch = 1, looped = false},
    OPTICAL_CAMO = {id = "rbxassetid://942127495", volume = 1, pitch = 1, looped = false},
    SANDI_FAILURE = {id = "rbxassetid://73272481520628", volume = 1, pitch = 1, looped = false}
}

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
    NoRegenUntil = 0
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
local isInvincible = false
local opticalToken = 0

-- Variáveis e funções de invisibilidade
local invisSound = Instance.new("Sound", Player:WaitForChild("PlayerGui"))
invisSound.SoundId = Sounds.OPTICAL_CAMO.id
invisSound.Volume = Sounds.OPTICAL_CAMO.volume
invisSound.PlaybackSpeed = Sounds.OPTICAL_CAMO.pitch
invisSound.Looped = Sounds.OPTICAL_CAMO.looped

local function getSafeInvisPosition()
    local offset = Vector3.new(math.random(-5000, 5000), math.random(10000, 15000), math.random(-5000, 5000))  -- Alto no céu, randômico
    return offset
end

local function setTransparency(character, targetTransparency, duration)
    local tweenInfo = TweenInfo.new(duration or 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("Decal") then
            if part.Name == "HumanoidRootPart" then
                continue
            end
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
    Weld.Part1 = Player.Character:FindFirstChild("Torso") or Player.Character.UpperTorso
    task.wait()
    Seat.CFrame = savedpos
    setTransparency(Player.Character, 0.5, 0.5)  -- Fade para semi-transparente
end

local function deactivateInvisibility()
    invisSound:Play()
    local invisChair = Workspace:FindFirstChild('invischair')
    if invisChair then
        invisChair:Destroy()
    end
    setTransparency(Player.Character, 0, 0.5)  -- Fade para visível
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
            Size = UDim2.new(0, 220, 0, 35),
            Position = UDim2.new(0.5, -110, 0.7, 0),
            BackgroundColor3 = Colors.UI_BG,
            BackgroundTransparency = 0.2,
            BorderSizePixel = 0,
            Parent = gui
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = container})
        local stroke = Create("UIStroke", {Color = color, Thickness = 1.2, Transparency = 0.4, Parent = container})
        
        local label = Create("TextLabel", {
            Size = UDim2.new(1, -10, 1, 0),
            Position = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
            TextColor3 = color,
            Font = Enum.Font.SciFi,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = name:upper(),
            Parent = container
        })
        
        local timer = Create("TextLabel", {
            Size = UDim2.new(1, -10, 1, 0),
            Position = UDim2.new(0, -10, 0, 0),
            BackgroundTransparency = 1,
            TextColor3 = Colors.TEXT_DEFAULT,
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
                    task.wait()
                end
            end)
        end
        
        local startTime = os.clock()
        while os.clock() - startTime < duration do
            local remaining = math.max(0, duration - (os.clock() - startTime))
            timer.Text = string.format("%.1fS", remaining)
            local myIndex = GetMyIndex()
            if myIndex then
                local targetPos = UDim2.new(0.5, -110, 0.7, -(myIndex - 1) * 40)
                container.Position = container.Position:Lerp(targetPos, 0.15)
            end
            RunService.RenderStepped:Wait()
        end
        
        TweenService:Create(container, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        TweenService:Create(label, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
        TweenService:Create(timer, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
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
    
    local humanoid = hologramChar:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid:Destroy()
    end
    local animateFolder = hologramChar:FindFirstChild("Animate")
    if animateFolder then
        animateFolder:Destroy()
    end
    for _, obj in ipairs(hologramChar:GetDescendants()) do
        if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") or
           obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") or
           obj:IsA("BindableEvent") or obj:IsA("BindableFunction") or
           obj:IsA("Animator") then
            obj:Destroy()
        end
    end

    -- Destruir sons no clone
    for _, sound in ipairs(hologramChar:GetDescendants()) do
        if sound:IsA("Sound") then
            sound:Destroy()
        end
    end
    
    if not Configurations.HOLOGRAM_PRESERVE.FACE then
        local head = hologramChar:FindFirstChild("Head")
        if head then
            local face = head:FindFirstChild("face")
            if face and face:IsA("Decal") then
                face:Destroy()
            end
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
            if not Configurations.HOLOGRAM_PRESERVE.ORIGINAL_COLOR then
                part.Color = Colors.RAINBOW_SEQUENCE[1]
            end
            part.Transparency = 0.3
        elseif part:IsA("Decal") or part:IsA("Texture") then
            part.Transparency = 0.3
        end
    end

    if hologramHRP then
        hologramHRP.Transparency = 1
    end
    
    for _, part in ipairs(hologramChar:GetDescendants()) do
        if part:IsA("BasePart") then
            task.spawn(function()
                task.wait(delay)
                local colors = if cloneType == "sandi" or cloneType == "dash" then Colors.RAINBOW_SEQUENCE
                    elseif cloneType == "glitch" then {Color3.new(1,0,0), Color3.new(0,0,0), Color3.new(1,1,1), Color3.new(1,0,0)}
                    elseif cloneType == "dodge" then Colors.RAINBOW_SEQUENCE
                    else Colors.RAINBOW_SEQUENCE
                
                if not Configurations.HOLOGRAM_PRESERVE.ORIGINAL_COLOR then
                    part.Color = colors[1]
                    local animSpeed = duration / (#colors - 1)
                    
                    for i = 1, #colors - 1 do
                        local ti = TweenInfo.new(animSpeed, Enum.EasingStyle.Linear)
                        local tween = TweenService:Create(part, ti, {Color = colors[i + 1]})
                        tween:Play()
                        tween.Completed:Wait()
                    end
                end
                
                local fadeTween = TweenService:Create(part, TweenInfo.new(duration * 0.7), {Transparency = endTransparency})
                fadeTween:Play()
            end)
        end
    end
    
    for _, surf in ipairs(hologramChar:GetDescendants()) do
        if surf:IsA("Decal") or surf:IsA("Texture") then
            task.spawn(function()
                task.wait(delay + duration * 0.3)
                local fadeTween = TweenService:Create(surf, TweenInfo.new(duration * 0.7), {Transparency = endTransparency})
                fadeTween:Play()
            end)
        end
    end
    
    hologramChar.Parent = Workspace
    Debris:AddItem(hologramChar, delay + duration + 0.5)
end

--// CYBERPSYCHOSIS
local function ExecCyberpsychosis()
    PlaySFX(Sounds.PSYCHOSIS)
    
    if Humanoid then
        Humanoid.WalkSpeed = 0
        Humanoid.JumpPower = 0
    end
    
    if Lighting:FindFirstChild("SandiEffect") then Lighting.SandiEffect:Destroy() end
    
    local blur = Create("BlurEffect", {Size = 0, Parent = Lighting})
    local bloom = Create("BloomEffect", {Intensity = 0, Size = 0, Threshold = 0.5, Parent = Lighting})
    local dof = Create("DepthOfFieldEffect", {FocusDistance = 0.1, InFocusRadius = 0.1, NearIntensity = 1, FarIntensity = 1, Parent = Lighting})
    local cc = Create("ColorCorrectionEffect", {
        TintColor = Color3.fromRGB(255, 50, 50), 
        Saturation = -1, 
        Contrast = 2,
        Brightness = -0.1, 
        Parent = Lighting
    })
    
    local psychoGui = Create("ScreenGui", {Name = "PsychoGui", Parent = Player.PlayerGui, IgnoreGuiInset = true})
    
    local yellText = Create("TextLabel", {
        Size = UDim2.new(1, 0, 0.2, 0),
        Position = UDim2.new(0, 0, 0.4, 0),
        BackgroundTransparency = 1,
        Text = "I'M GONNA RIP OUT HIS SPINE! YOU'RE DEAD, DEAD... DEAD.! DEAAD!!!.",
        TextColor3 = Color3.fromRGB(255, 0, 0),
        Font = Enum.Font.SciFi,
        TextSize = 40,
        TextWrapped = true,
        TextTransparency = 1,
        Parent = psychoGui
    })
    Create("UIStroke", {Color = Color3.fromRGB(0, 0, 0), Thickness = 2, Transparency = 0.5, Parent = yellText})
    TweenService:Create(yellText, TweenInfo.new(0.5, Enum.EasingStyle.Bounce), {TextTransparency = 0}):Play()
    
    local warnings = {
        "WARNING: CYBERPSYCHOSIS DETECTED",
        "SYSTEM OVERLOAD",
        "NEURAL FAILURE IMMINENT",
        "MAXTECH INTERVENTION REQUIRED",
        "PSYCHOSQUAD ALERT"
    }
    
    for i = 1, 15 do
        local warnLabel = Create("TextLabel", {
            Size = UDim2.new(0.4, 0, 0.1, 0),
            Position = UDim2.new(math.random(), 0, math.random(), 0),
            BackgroundTransparency = 0.3,
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            Text = warnings[math.random(1, #warnings)],
            TextColor3 = Color3.fromRGB(255, 0, 0),
            Font = Enum.Font.Code,
            TextSize = 24,
            TextTransparency = 0,
            Parent = psychoGui
        })
        Create("UIStroke", {Color = Color3.fromRGB(255, 0, 0), Thickness = 2, Parent = warnLabel})
        Create("UIGradient", {Color = ColorSequence.new(Color3.new(1,0,0), Color3.new(0.5,0,0)), Parent = warnLabel})
        
        task.spawn(function()
            while warnLabel do
                warnLabel.TextTransparency = math.random(0, 5)/10
                warnLabel.Position = UDim2.new(math.random(0, 60)/100, 0, math.random(0, 80)/100, 0)
                warnLabel.Rotation = math.random(-5, 5)
                task.wait(0.05)
            end
        end)
    end
    
    task.spawn(function()
        local duration = 4
        local startTime = os.clock()
        
        while os.clock() - startTime < duration do
            if Humanoid then
                Humanoid.CameraOffset = Vector3.new(math.random(-3,3), math.random(-3,3), math.random(-3,3))
            end
            
            Camera.FieldOfView = math.random(40, 120)
            
            cc.Brightness = math.random(-6, 6) / 10
            cc.TintColor = Color3.fromHSV(math.random(), 1, 1)
            blur.Size = math.random(10, 30)
            bloom.Intensity = math.random(1, 3)
            bloom.Size = math.random(20, 40)
            dof.FocusDistance = math.random(0, 50)/100

            CreateHologramClone(0, 0.15, 1, 0, 0, 0, "glitch")
            
            task.wait(math.random(1, 3) / 20)
        end
        
        if Humanoid then
            Humanoid.Health -= 40
            Humanoid.WalkSpeed = 16
            Humanoid.JumpPower = 50
            Humanoid.CameraOffset = Vector3.new(0,0,0)
        end
        
        TweenService:Create(Camera, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {FieldOfView = 70}):Play()
        TweenService:Create(cc, TweenInfo.new(1, Enum.EasingStyle.Quad), {TintColor = Color3.new(1,1,1), Saturation = 0, Contrast = 0, Brightness = 0}):Play()
        TweenService:Create(blur, TweenInfo.new(1, Enum.EasingStyle.Quad), {Size = 0}):Play()
        TweenService:Create(bloom, TweenInfo.new(1, Enum.EasingStyle.Quad), {Intensity = 0, Size = 0}):Play()
        TweenService:Create(dof, TweenInfo.new(1, Enum.EasingStyle.Quad), {NearIntensity = 0, FarIntensity = 0}):Play()
        
        TweenService:Create(yellText, TweenInfo.new(1, Enum.EasingStyle.Quad), {TextTransparency = 1}):Play()
        
        task.wait(1)
        cc:Destroy()
        blur:Destroy()
        bloom:Destroy()
        dof:Destroy()
        psychoGui:Destroy()
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
    
    local errorLabel = Create("TextLabel", {
        Size = UDim2.new(0.5, 0, 0.1, 0),
        Position = UDim2.new(0.25, 0, 0.4, 0),
        BackgroundTransparency = 1,
        Text = "Error : Sandevistan Contains Errors",
        TextColor3 = Colors.ERROR_TEXT,
        Font = Enum.Font.SciFi,
        TextSize = 30,
        TextTransparency = 1,
        Parent = gui
    })
    local stroke = Create("UIStroke", {Color = Colors.ERROR_BORDER, Thickness = 2, Transparency = 1, Parent = errorLabel})
    
    local fadeIn = TweenService:Create(errorLabel, TweenInfo.new(0.5), {TextTransparency = 0})
    local fadeInStroke = TweenService:Create(stroke, TweenInfo.new(0.5), {Transparency = 0})
    fadeIn:Play()
    fadeInStroke:Play()
    
    task.delay(3, function()
        local fadeOut = TweenService:Create(errorLabel, TweenInfo.new(0.5), {TextTransparency = 1})
        local fadeOutStroke = TweenService:Create(stroke, TweenInfo.new(0.5), {Transparency = 1})
        fadeOut:Play()
        fadeOutStroke:Play()
        fadeOut.Completed:Connect(function()
            errorLabel:Destroy()
        end)
    end)
end

local function ApplyGlitchEffect()
    task.spawn(function()
        local startTime = os.clock()
        local glitchCC = Create("ColorCorrectionEffect", {TintColor = Color3.new(1,1,1), Contrast = 0, Saturation = 0, Parent = Lighting})
        local glitchBlur = Create("BlurEffect", {Size = 0, Parent = Lighting})
        
        while os.clock() - startTime < Constants.GLITCH_DURATION do
            CreateHologramClone(0, 0.1, 1, 0, 0, 0, "glitch")
            CamShake(0.3, 0.1)
            
            glitchCC.TintColor = Color3.fromHSV(math.random(), 1, 1)
            glitchCC.Contrast = math.random(-2, 2)
            glitchBlur.Size = math.random(5, 15)
            
            task.wait(0.1)
        end
        
        glitchCC:Destroy()
        glitchBlur:Destroy()
    end)
end

local function ExecDodge(enemyPart: BasePart?)
    -- Fade in verde limão
    local cc = Create("ColorCorrectionEffect", {Name = "DodgeEffect", TintColor = Color3.new(1,1,1), Saturation = 0.5, Parent = Lighting})
    TweenService:Create(cc, TweenInfo.new(0.5), {TintColor = Colors.LIGHT_GREEN, Saturation = -0.2}):Play()
    
    local startCFrame = HRP.CFrame
    local distance = if enemyPart then (HRP.Position - enemyPart.Position).Magnitude else 0
    
    if enemyPart and distance <= Constants.DODGE_CONFIG.VARIANT_THRESHOLD then
        -- Variante: giro 180° ao redor do atacante
        PlaySFX(Sounds.DODGE_VARIANT)
        
        -- Flash branco rápido
        local flashGui = Create("ScreenGui", {Parent = Player.PlayerGui})
        local flashFrame = Create("Frame", {Size = UDim2.new(1,0,1,0), BackgroundColor3 = Color3.new(1,1,1), Transparency = 1, Parent = flashGui})
        TweenService:Create(flashFrame, TweenInfo.new(0.1), {Transparency = 0}):Play()
        task.delay(0.1, function()
            TweenService:Create(flashFrame, TweenInfo.new(0.1), {Transparency = 1}):Play()
            task.delay(0.1, function() flashGui:Destroy() end)
        end)
        
        -- Movimento de giro
        task.spawn(function()
            local duration = Constants.DODGE_CONFIG.VARIANT_DURATION
            local startTime = tick()
            local relative = HRP.Position - enemyPart.Position
            local lastCloneTime = 0
            local cloneInterval = Constants.DODGE_CONFIG.VARIANT_CLONE_INTERVAL
            
            while tick() - startTime < duration do
                local alpha = (tick() - startTime) / duration
                local angle = alpha * math.pi
                local rotated = CFrame.new(0, 0, 0) * CFrame.Angles(0, angle, 0) * relative
                local newPos = enemyPart.Position + rotated
                HRP.CFrame = CFrame.lookAt(newPos, enemyPart.Position)
                
                if tick() - lastCloneTime >= cloneInterval then
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
        -- Dodge normal
        PlaySFX(Sounds.DODGE_NORMAL)
        local endCFrame
        if enemyPart then 
            endCFrame = CFrame.lookAt((enemyPart.CFrame * CFrame.new(0, 0, Constants.DODGE_CONFIG.NORMAL_DISTANCE_ENEMY)).Position, enemyPart.Position)
        else 
            endCFrame = HRP.CFrame * CFrame.new(0, 0, -Constants.DODGE_CONFIG.NORMAL_DISTANCE_NO_ENEMY) 
        end
        
        -- Clone único no local inicial, dura 1s e some em fade out
        CreateHologramClone(0, 1, 1, 0, 0, 0, "dodge", startCFrame)
        
        HRP.CFrame = endCFrame
    end
    
    CamShake(0.5, 0.2)
    
    -- Invencibilidade (sem stun ou knockback)
    isInvincible = true
    local forceField = Instance.new("ForceField")
    forceField.Parent = Character
    task.delay(Constants.DODGE_INVINCIBILITY_DURATION, function()
        isInvincible = false
        if forceField then forceField:Destroy() end
        -- Fade out do verde limão
        local t = TweenService:Create(cc, TweenInfo.new(0.5), {TintColor = Color3.new(1,1,1), Saturation = 0})
        t:Play()
        t.Completed:Connect(function() cc:Destroy() end)
    end)
end

local function ActivateDodgeReady()
    if State.Energy < Constants.ENERGY_COSTS.DODGE or os.clock() < State.Cooldowns.DODGE then return end
    State.Energy -= Constants.ENERGY_COSTS.DODGE
    State.NoRegenUntil = os.clock() + Constants.REGEN_DELAY_USE
    State.IsDodgeReady = true
    -- Opcional: adicionar efeito visual durante os 2s, como uma borda ou tint
    task.spawn(function()
        task.wait(2)
        if State.IsDodgeReady then
            State.IsDodgeReady = false
            State.Cooldowns.DODGE = os.clock() + Constants.COOLDOWNS.DODGE
            ShowCooldownText("Neural Dodge", Constants.COOLDOWNS.DODGE, Colors.DODGE_END)
        end
    end)
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
        -- Fade out ao desativar
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
    -- Restaurar slow motion
    if originalGravity then
        Workspace.Gravity = originalGravity
        originalGravity = nil
    end
    for hum, speed in pairs(originalWalkSpeeds) do
        if hum and hum.Parent then
            hum.WalkSpeed = speed
        end
    end
    for hum, power in pairs(originalJumpPowers) do
        if hum and hum.Parent then
            hum.JumpPower = power
        end
    end
    for track, speed in pairs(originalAnimationSpeeds) do
        if track then
            track:AdjustSpeed(speed)
        end
    end
    for sound, speed in pairs(originalSoundSpeeds) do
        if sound and sound.Parent then
            sound.PlaybackSpeed = speed
        end
    end
    for velInst, vel in pairs(originalVelocityInstances) do
        if velInst and velInst.Parent then
            if velInst:IsA("BodyVelocity") then
                velInst.Velocity = vel
            elseif velInst:IsA("LinearVelocity") then
                velInst.VectorVelocity = vel
            end
        end
    end
    for _, conn in ipairs(animationConnections) do
        conn:Disconnect()
    end
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
    for _, tex in ipairs(textures) do
        table.insert(fullSeq, tex)
    end
    for i = #textures - 1, 1, -1 do
        table.insert(fullSeq, textures[i])
    end
    local gui = Player.PlayerGui:FindFirstChild("CyberRebuilt")
    if not gui then return end
    local overlay = Create("ImageLabel", {
        Name = "SandiTextureOverlay",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        ImageTransparency = 0.3,
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
    
    -- 20% chance de falha
    if math.random() < Constants.SANDEVISTAN_FAILURE_CHANCE then
        PlaySFX(Sounds.SANDI_FAILURE)
        ShowErrorText()
        ApplyGlitchEffect()
        State.Cooldowns.SANDI = os.clock() + Constants.COOLDOWNS.SANDI
        State.NoRegenUntil = os.clock() + Constants.REGEN_DELAY_USE
        ShowCooldownText("Sandevistan", Constants.COOLDOWNS.SANDI, Colors.RAINBOW_SEQUENCE[1])
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
        Saturation = -0.2
    }):Play()
    
    PlayActivationSequence()
    
    lastSandiClone = 0
    
    -- Slow motion para o mundo
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
end

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

local function ResetOptical()
    if not State.IsOpticalActive then return end
    
    opticalToken += 1
    
    State.IsOpticalActive = false
    deactivateInvisibility()
    State.Cooldowns.OPTICAL = os.clock() + Constants.COOLDOWNS.OPTICAL
    State.NoRegenUntil = os.clock() + Constants.REGEN_DELAY_USE
    
    ShowCooldownText("Optical Camouflage", Constants.COOLDOWNS.OPTICAL, Colors.OPTICAL)
end

local function ExecOptical()
    if State.IsSandiActive then return end
    
    if State.IsOpticalActive then
        ResetOptical()
        return
    end

    if os.clock() < State.Cooldowns.OPTICAL then
        return
    end
    
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

--// SISTEMA DE UI
local function MakeDraggable(frame: Frame)
    local dragging = false
    local dragStart, startPos
    local stroke = Create("UIStroke", {Color = Colors.EDIT_MODE, Thickness = 2, Enabled = false, Parent = frame})
    table.insert(UI_Elements, {Frame = frame, Stroke = stroke})
    
    frame.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and State.EditMode then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if dragging and State.EditMode then
                local delta = input.Position - dragStart
                frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            elseif dragging then
                dragging = false
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
    
    local lockBtn = Create("TextButton", {Name = "LockBtn", Size = UDim2.new(0, 35, 0, 35), Position = savedPositions["LockBtn"] or UDim2.new(1, -50, 0, 50), Text = "⚙️", BackgroundColor3 = Colors.UI_BG, TextColor3 = Colors.TEXT_DEFAULT, Font = Enum.Font.SciFi, TextSize = 20, Parent = gui})
    Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = lockBtn})
    Create("UIStroke", {Color = Colors.TEXT_DEFAULT, Thickness = 2, Parent = lockBtn})
    local gradientLock = Create("UIGradient", {Color = ColorSequence.new(Colors.UI_BG, Colors.UI_ACCENT), Rotation = 45, Parent = lockBtn})
    
    local energyContainer = Create("Frame", {Name = "EnergyContainer", Size = UDim2.new(0, 300, 0, 15), Position = savedPositions["EnergyContainer"] or UDim2.new(0.5, -150, 0.92, 0), BackgroundColor3 = Colors.UI_BG, BorderSizePixel = 0, Parent = gui})
    Create("UICorner", {CornerRadius = UDim.new(0, 2), Parent = energyContainer})
    Create("UIStroke", {Color = Colors.UI_ACCENT, Thickness = 1, Parent = energyContainer})
    
    local fill = Create("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Colors.ENERGY_FULL, BorderSizePixel = 0, Parent = energyContainer})
    Create("UICorner", {CornerRadius = UDim.new(0, 2), Parent = fill})
    local energyGradient = Create("UIGradient", {Color = ColorSequence.new(Colors.ENERGY_LOW, Colors.ENERGY_FULL), Rotation = 0, Parent = fill})
    
    local energyLabel = Create("TextLabel", {Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, -1.2, 0), BackgroundTransparency = 1, Text = "SYSTEM ENERGY: 100%", TextColor3 = Colors.ENERGY_FULL, Font = Enum.Font.Code, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = energyContainer})
    
    local function CreateSkillBtn(key, color, pos, name, func)
        local btn = Create("TextButton", {Name = name, Size = UDim2.new(0, 50, 0, 50), Position = savedPositions[name] or pos, Text = key, BackgroundColor3 = Colors.UI_BG, TextColor3 = color, Font = Enum.Font.SciFi, TextSize = 18, AutoButtonColor = false, Parent = gui})
        local stroke = Create("UIStroke", {Color = color, Thickness = 2, Transparency = 0.5, Parent = btn})
        Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = btn})
        local gradient = Create("UIGradient", {Color = ColorSequence.new(Colors.UI_BG, color), Rotation = 45, Parent = btn})
        
        btn.MouseButton1Down:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.1, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {Size = UDim2.new(0, 45, 0, 45), BackgroundColor3 = color, TextColor3 = Colors.UI_BG}):Play()
            TweenService:Create(stroke, TweenInfo.new(0.1), {Transparency = 0}):Play()
            if not State.EditMode then
                func()
            end
        end)
        btn.MouseButton1Up:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Bounce, Enum.EasingDirection.In), {Size = UDim2.new(0, 50, 0, 50), BackgroundColor3 = Colors.UI_BG, TextColor3 = color}):Play()
            TweenService:Create(stroke, TweenInfo.new(0.2), {Transparency = 0.5}):Play()
        end)
        
        TweenService:Create(btn, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Rotation = 2}):Play()
        
        MakeDraggable(btn)
        if name == "SandiBtn" then
            task.spawn(function()
                while btn.Parent do
                    local hue = (os.clock() % 5) / 5
                    local rainbowColor = Color3.fromHSV(hue, 1, 1)
                    btn.TextColor3 = rainbowColor
                    stroke.Color = rainbowColor
                    gradient.Color = ColorSequence.new(Colors.UI_BG, rainbowColor)
                    task.wait()
                end
            end)
        end
        return btn
    end
    
    CreateSkillBtn("D", Colors.DASH_CYAN, UDim2.new(0.75, 0, 0.85, 0), "DashBtn", ExecDash)
    CreateSkillBtn("S", Color3.new(1,1,1), UDim2.new(0.8, 0, 0.85, 0), "SandiBtn", ExecSandi)
    CreateSkillBtn("Ko", Colors.KIROSHI, UDim2.new(0.85, 0, 0.85, 0), "KiroshiBtn", ExecKiroshi)
    CreateSkillBtn("Oc", Colors.OPTICAL, UDim2.new(0.9, 0, 0.85, 0), "OpticalBtn", ExecOptical)
    CreateSkillBtn("N", Colors.DODGE_START, UDim2.new(0.95, 0, 0.85, 0), "DodgeBtn", ActivateDodgeReady)
    
    MakeDraggable(energyContainer)
    MakeDraggable(lockBtn)
    
    lockBtn.MouseButton1Click:Connect(function()
        State.EditMode = not State.EditMode
        lockBtn.BackgroundColor3 = State.EditMode and Colors.EDIT_MODE or Colors.UI_BG
        lockBtn.TextColor3 = State.EditMode and Colors.UI_BG or Colors.TEXT_DEFAULT
        for _, item in ipairs(UI_Elements) do item.Stroke.Enabled = State.EditMode end
        if not State.EditMode then
            savedPositions["LockBtn"] = lockBtn.Position
            savedPositions["EnergyContainer"] = energyContainer.Position
            savedPositions["DashBtn"] = gui:FindFirstChild("DashBtn").Position
            savedPositions["SandiBtn"] = gui:FindFirstChild("SandiBtn").Position
            savedPositions["KiroshiBtn"] = gui:FindFirstChild("KiroshiBtn").Position
            savedPositions["OpticalBtn"] = gui:FindFirstChild("OpticalBtn").Position
            savedPositions["DodgeBtn"] = gui:FindFirstChild("DodgeBtn").Position
        end
    end)
    
    UpdateDashButton()
    UpdateKiroshiButton()
    UpdateOpticalButton()
    
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
    Joints = {
        RootJoint = HRP:WaitForChild("RootJoint"),
        Neck = Character.Torso:WaitForChild("Neck"),
        RightShoulder = Character.Torso:WaitForChild("Right Shoulder"),
        LeftShoulder = Character.Torso:WaitForChild("Left Shoulder"),
        RightHip = Character.Torso:WaitForChild("Right Hip"),
        LeftHip = Character.Torso:WaitForChild("Left Hip")
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
        if dmgDealt > 1 and State.IsDodgeReady then
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
            State.IsDodgeReady = false
            State.Cooldowns.DODGE = os.clock() + Constants.COOLDOWNS.DODGE
            ShowCooldownText("Neural Dodge", Constants.COOLDOWNS.DODGE, Colors.DODGE_END)
        end
        if isInvincible then
            Humanoid.Health = State.LastHealth
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
end)

local KeyActions = {
    [Enum.KeyCode.D] = ExecDash,
    [Enum.KeyCode.S] = ExecSandi,
    [Enum.KeyCode.K] = ExecKiroshi,
    [Enum.KeyCode.O] = ExecOptical,
    [Enum.KeyCode.N] = ActivateDodgeReady,
}

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    
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

-- Roupinhas da mother
local IDS_CATALOGO = {
    18358624045,
    18358533023,
    18358615215,
    89883990361521,
}

local function attachAsset(character: Model, id: number)

    local success, objects = pcall(function()
        return game:GetObjects(("rbxassetid://%d"):format(id))
    end)

    if not success or not objects or not objects[1] then
        warn("Failed to load asset:", id)
        return
    end

    local asset = objects[1]

    for _, obj in ipairs(asset:GetDescendants()) do
        if obj:IsA("LuaSourceContainer")
        or obj:IsA("Weld")
        or obj:IsA("WeldConstraint")
        or obj:IsA("Motor6D") then
            obj:Destroy()
        end
    end

    local handle = asset:IsA("BasePart")
        and asset
        or asset:FindFirstChildWhichIsA("BasePart", true)

    if not handle then
        warn("Asset has no BasePart:", id)
        asset:Destroy()
        return
    end

    handle.CanCollide = false
    handle.Massless = true
    handle.Anchored = false

    local itemAttachment = handle:FindFirstChildWhichIsA("Attachment", true)

    if itemAttachment then
        
        local bodyAttachment = character:FindFirstChild(itemAttachment.Name, true)

        if bodyAttachment and bodyAttachment:IsA("Attachment") then
            local rc = Instance.new("RigidConstraint")
            rc.Attachment0 = bodyAttachment
            rc.Attachment1 = itemAttachment
            rc.Parent = handle

            asset.Parent = character
            return
        end
    end
    
    local root = character:FindFirstChild("HumanoidRootPart")

    local targetPart =
        character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("Torso")
        or root

    if not targetPart then
        warn("No valid body part:", id)
        asset:Destroy()
        return
    end

    handle.CFrame = targetPart.CFrame

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = targetPart
    weld.Part1 = handle
    weld.Parent = handle

    asset.Parent = character
end


local function AnexarTudo()
    local character = Player.Character or Player.CharacterAdded:Wait()

    local assetsToLoad = {}

    for _, id in ipairs(IDS_CATALOGO) do
        table.insert(assetsToLoad, "rbxassetid://"..id)
    end

    ContentProvider:PreloadAsync(assetsToLoad)

    for _, id in ipairs(IDS_CATALOGO) do
        attachAsset(character, id)
    end
end

AnexarTudo()

Player.CharacterAdded:Connect(function(char)
    char:WaitForChild("HumanoidRootPart")
    task.wait(0.5)
    AnexarTudo()
end)
