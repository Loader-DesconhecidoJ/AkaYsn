--!strict
--[[
    ╔═════════════════════════════════════════════════════════════════════════════╗
    ║               PREMIUM CYBERPUNK SANDEVISTAN - EDGERUNNERS STYLE V4.3        ║
    ║              INSPIRED BY DAVID MARTINEZ'S SANDEVISTAN FROM CYBERPUNK 2077   ║
    ║        UPDATES: FIXED INIT ANIMATION, REMOVED OBJECT SCAN IN KIROSHI        ║
    ╚═════════════════════════════════════════════════════════════════════════════╝

]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

--// TYPES
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
    Cooldowns: Cooldowns,
    EditMode: boolean,
    LastVelocityY: number,
    ActiveLabels: number,
    LastHealth: number,
    LastDeactivationTime: number,
    NoRegenUntil: number
}

--// CONSTANTS
local Constants = {
    MAX_ENERGY = 100,
    SANDI_SPEED = 80,
    DASH_FORCE = 100,
    IMPACT_THRESHOLD = -60,
    MOVING_THRESHOLD = 1,
    OPTICAL_DURATION = 5,
    SLOW_FACTOR = 0.8,
    COOLDOWNS = {
        SANDI = 8,
        DASH = 3.5,
        DODGE = 4.5,
        KIROSHI = 5,
        OPTICAL = 6.5
    },
    HOLOGRAM_CLONE = {
        SANDI = {
            DELAY = 0.045,
            DURATION = 1,
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
        SANDI_DRAIN = 3,  -- per second
        DASH = 8,
        DODGE = 10,
        KIROSHI = 10,
        OPTICAL = 20
    },
    REGEN_RATE = 15,  -- per second
    REGEN_DELAY_ZERO = 10,
    REGEN_DELAY_USE = 5,
    DODGE_INVINCIBILITY_DURATION = 0,  -- seconds
    KIROSHI_WEAKNESSES = {"Fogo", "Gelo", "Eletricidade", "Veneno"}  -- Example weaknesses
}

--// CONFIGURATIONS
local Configurations = {
    SLOW_GRAVITY_MULTIPLIER = Constants.SLOW_FACTOR ^ 2,  -- Adjust this independently if you want custom gravity during slow motion (default is SLOW_FACTOR ^ 2 for realistic physics)
    HOLOGRAM_MATERIAL = Enum.Material.SmoothPlastic,
    COLORS = {
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
            Color3.fromRGB(160, 0, 255),  -- Purple
            Color3.fromRGB(255, 0, 130)   -- Pink
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
        ENERGY_FULL = Color3.fromRGB(50, 205, 50),  -- Lime green
        ENERGY_MEDIUM = Color3.fromRGB(255, 255, 0),  -- Yellow
        ENERGY_LOW = Color3.fromRGB(255, 0, 0),  -- Red
        LIGHT_GREEN = Color3.fromRGB(200, 255, 200),  -- Light green for fades
        FLASH_COLOR = Color3.new(1,1,1)  -- White flash color
    },
    ASSETS = {
        SOUNDS = {
            IMPACT = "rbxassetid://4453098167",
            DODGE = "rbxassetid://70643008100559",
            DASH = "rbxassetid://103247005619946",
            SANDI_ON = "rbxassetid://123844681344865",  -- Customized to match David's activation sound
            SANDI_OFF = "rbxassetid://118534165523355",
            HIT = "rbxassetid://5665936061",
            SANDI_LOOP = "rbxassetid://81793359483683",
            IDLE_MUSIC = "rbxassetid://84295656118500",
            DODGE_VARIANT_SOUND = "rbxassetid://70643008100559"
        },
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
    },
    DODGE_CONFIG = {
        VARIANT_DISTANCE = 5,  -- Distance to trigger variant
        SPIN_DURATION = 0.5,  -- Duration of spin
        CLONE_INTERVAL = 0.05,  -- Interval for clones during spin
        CLONE_SPACING = 2,  -- Spacing for normal dodge clones (studs)
        FLASH_DURATION = 0.1  -- Duration of flash
    }
}

--// STATE MANAGEMENT
local State: SystemState = {
    Energy = Constants.MAX_ENERGY,
    IsSandiActive = false,
    IsKiroshiActive = false,
    IsOpticalActive = false,
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

-- Invisibility variables and functions
local invisSound = Instance.new("Sound", Player:WaitForChild("PlayerGui"))
invisSound.SoundId = "rbxassetid://942127495"
invisSound.Volume = 1

local function getSafeInvisPosition()
    local offset = Vector3.new(math.random(-5000, 5000), math.random(10000, 15000), math.random(-5000, 5000))  -- Alto no céu, randômico
    return offset
end

local function setTransparency(character, targetTransparency, duration)
    local tweenInfo = TweenInfo.new(duration or 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("Decal") then
            TweenService:Create(part, tweenInfo, {Transparency = targetTransparency}):Play()
        end
    end
end

local function activateInvisibility()
    invisSound:Play()
    local savedpos = Player.Character.HumanoidRootPart.CFrame
    wait()
    local invisPos = getSafeInvisPosition()
    Player.Character:MoveTo(invisPos)
    wait(.15)
    local Seat = Instance.new('Seat', game.Workspace)
    Seat.Anchored = false
    Seat.CanCollide = false
    Seat.Name = 'invischair'
    Seat.Transparency = 1
    Seat.Position = invisPos
    local Weld = Instance.new("Weld", Seat)
    Weld.Part0 = Seat
    Weld.Part1 = Player.Character:FindFirstChild("Torso") or Player.Character.UpperTorso
    wait()
    Seat.CFrame = savedpos
    setTransparency(Player.Character, 0.5, 0.5)  -- Fade to semi-transparent
    game.StarterGui:SetCore("SendNotification", {
        Title = "Optical Camo (on)",
        Duration = 3,
        Text = "STATUS:"
    })
end

local function deactivateInvisibility()
    invisSound:Play()
    local invisChair = workspace:FindFirstChild('invischair')
    if invisChair then
        invisChair:Destroy()
    end
    setTransparency(Player.Character, 0, 0.5)  -- Fade to visible
    game.StarterGui:SetCore("SendNotification", {
        Title = "Optical Camo (off)",
        Duration = 3,
        Text = "STATUS:"
    })
end

--// UTILITY FUNCTIONS
local function Create(className: string, properties: {[string]: any})
    local instance = Instance.new(className)
    for prop, value in properties do
        instance[prop] = value
    end
    return instance
end

local function PlaySFX(id: string, volume: number?, pitch: number?)
    local sound = Create("Sound", {
        SoundId = id,
        Volume = volume or 1,
        PlaybackSpeed = pitch or 1,
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

--// COOLDOWN UI (Updated for rainbow animation on Sandevistan)
local function ShowCooldownText(name: string, duration: number, color: Color3)
    task.spawn(function()
        local gui = Player.PlayerGui:FindFirstChild("CyberRebuilt")
        if not gui then return end
        
        local container = Create("Frame", {
            Size = UDim2.new(0, 220, 0, 35),
            Position = UDim2.new(0.5, -110, 0.7, 0),
            BackgroundColor3 = Configurations.COLORS.UI_BG,
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
            TextColor3 = Configurations.COLORS.TEXT_DEFAULT,
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

--// VISUAL EFFECTS
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

    -- Adicionado: Destruir todos os sons no clone para evitar clonagem de áudios
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
                part.Color = Configurations.COLORS.RAINBOW_SEQUENCE[1]
            end
            part.Transparency = 0.3  -- Slightly less transparent for hologram feel
        elseif part:IsA("Decal") or part:IsA("Texture") then
            part.Transparency = 0.3
        end
    end

    -- Fix para remover o bloco cinza (HumanoidRootPart visível)
    if hologramHRP then
        hologramHRP.Transparency = 1
    end
    
    for _, part in ipairs(hologramChar:GetDescendants()) do
        if part:IsA("BasePart") then
            task.spawn(function()
                task.wait(delay)
                local colors = if cloneType == "sandi" or cloneType == "dash" then Configurations.COLORS.RAINBOW_SEQUENCE
                    elseif cloneType == "glitch" then {Color3.new(1,0,0), Color3.new(0,0,0), Color3.new(1,1,1), Color3.new(1,0,0)}
                    elseif cloneType == "dodge" then Configurations.COLORS.RAINBOW_SEQUENCE -- Changed to rainbow for dodge clones
                    else Configurations.COLORS.RAINBOW_SEQUENCE
                
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

--// CYBERPSYCHOSIS (Enhanced for premium feel)
local function ExecCyberpsychosis()
    PlaySFX("rbxassetid://87597277352254", 2)
    
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

--// ABILITY FUNCTIONS
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

local function ExecDodge(enemyPart: BasePart?)
    if State.Energy < Constants.ENERGY_COSTS.DODGE or os.clock() < State.Cooldowns.DODGE then return end
    State.Energy -= Constants.ENERGY_COSTS.DODGE
    State.NoRegenUntil = os.clock() + Constants.REGEN_DELAY_USE
    State.Cooldowns.DODGE = os.clock() + Constants.COOLDOWNS.DODGE
    ShowCooldownText("Neural Dodge", Constants.COOLDOWNS.DODGE, Configurations.COLORS.DODGE_END)
    
    -- Fade in light green world
    local cc = Create("ColorCorrectionEffect", {TintColor = Color3.new(1,1,1), Saturation = 0.5, Parent = Lighting})
    TweenService:Create(cc, TweenInfo.new(0.5), {TintColor = Configurations.COLORS.LIGHT_GREEN, Saturation = -0.2}):Play()
    
    local startCFrame = HRP.CFrame
    local distance = (HRP.Position - enemyPart.Position).Magnitude
    
    if enemyPart and distance <= Configurations.DODGE_CONFIG.VARIANT_DISTANCE then
        -- Variant: 180° spin around attacker
        PlaySFX(Configurations.ASSETS.SOUNDS.DODGE_VARIANT_SOUND, 1.5)
        
        -- Quick white flash
        local flashGui = Create("ScreenGui", {Parent = Player.PlayerGui})
        local flashFrame = Create("Frame", {Size = UDim2.new(1,0,1,0), BackgroundColor3 = Configurations.COLORS.FLASH_COLOR, Transparency = 1, Parent = flashGui})
        TweenService:Create(flashFrame, TweenInfo.new(Configurations.DODGE_CONFIG.FLASH_DURATION), {Transparency = 0}):Play()
        task.delay(Configurations.DODGE_CONFIG.FLASH_DURATION, function()
            TweenService:Create(flashFrame, TweenInfo.new(Configurations.DODGE_CONFIG.FLASH_DURATION), {Transparency = 1}):Play()
            task.delay(Configurations.DODGE_CONFIG.FLASH_DURATION, function() flashGui:Destroy() end)
        end)
        
        -- Spin movement
        task.spawn(function()
            local duration = Configurations.DODGE_CONFIG.SPIN_DURATION
            local startTime = tick()
            local relative = HRP.Position - enemyPart.Position
            local lastCloneTime = 0
            local cloneInterval = Configurations.DODGE_CONFIG.CLONE_INTERVAL
            
            while tick() - startTime < duration do
                local alpha = (tick() - startTime) / duration
                local angle = alpha * math.pi
                local rotated = CFrame.new(0, 0, 0) * CFrame.Angles(0, angle, 0) * relative
                local newPos = enemyPart.Position + rotated
                HRP.CFrame = CFrame.lookAt(newPos, enemyPart.Position)
                
                -- Create rainbow hologram clones
                if tick() - lastCloneTime >= cloneInterval then
                    CreateHologramClone(0, Constants.HOLOGRAM_CLONE.DODGE.DURATION, Constants.HOLOGRAM_CLONE.DODGE.END_TRANSPARENCY, 0, 0, 0, "dodge", HRP.CFrame)
                    lastCloneTime = tick()
                end
                
                RunService.Heartbeat:Wait()
            end
            
            -- Ensure final position behind
            local finalRelative = relative * CFrame.Angles(0, math.pi, 0)
            local finalPos = enemyPart.Position + finalRelative
            HRP.CFrame = CFrame.lookAt(finalPos, enemyPart.Position)
        end)
        
    else
        -- Normal dodge
        PlaySFX(Configurations.ASSETS.SOUNDS.DODGE, 1.5)
        local endCFrame
        if enemyPart then 
            endCFrame = CFrame.lookAt((enemyPart.CFrame * CFrame.new(0, 0, 6)).Position, enemyPart.Position)
        else 
            endCFrame = HRP.CFrame * CFrame.new(0, 0, -12) 
        end
        HRP.CFrame = endCFrame
        
        -- Create trail of rainbow clones
        local startPos = startCFrame.Position
        local endPos = endCFrame.Position
        local direction = (endPos - startPos).Unit
        local distance = (endPos - startPos).Magnitude
        local numClones = math.floor(distance / Configurations.DODGE_CONFIG.CLONE_SPACING)  -- Clone every 2 studs
        for i = 1, numClones do
            local pos = startPos + direction * (i * (distance / numClones))
            local cloneCFrame = CFrame.new(pos) * startCFrame.Rotation
            CreateHologramClone(0, Constants.HOLOGRAM_CLONE.DODGE.DURATION, Constants.HOLOGRAM_CLONE.DODGE.END_TRANSPARENCY, 0, 0, 0, "dodge", cloneCFrame)
        end
    end
    
    CamShake(0.5, 0.2)
    
    -- Fade out
    local t = TweenService:Create(cc, TweenInfo.new(0.5), {TintColor = Color3.new(1,1,1), Saturation = 0})
    t:Play()
    t.Completed:Connect(function() cc:Destroy() end)
end

local function ResetSandi()
    if not State.IsSandiActive then return end
    State.IsSandiActive = false
    PlaySFX(Configurations.ASSETS.SOUNDS.SANDI_OFF, 1)
    State.Cooldowns.SANDI = os.clock() + Constants.COOLDOWNS.SANDI
    State.NoRegenUntil = os.clock() + Constants.REGEN_DELAY_USE
    ShowCooldownText("Sandevistan", Constants.COOLDOWNS.SANDI, Configurations.COLORS.RAINBOW_SEQUENCE[1])
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
            Humanoid.JumpPower = originalPlayerJumpPower
            originalPlayerJumpPower = nil
        end
    end
    TweenService:Create(Camera, TweenInfo.new(0.6), {FieldOfView = 70}):Play()
    CleanupSandiSounds()
    -- Restore slow motion
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

local function UpdateDashButton()
    local gui = Player.PlayerGui:FindFirstChild("CyberRebuilt")
    if not gui then return end
    local dashBtn = gui:FindFirstChild("DashBtn")
    if not dashBtn then return end
    
    if State.IsSandiActive then
        dashBtn.TextColor3 = Color3.new(0.5, 0.5, 0.5)
    else
        dashBtn.TextColor3 = Configurations.COLORS.DASH_CYAN
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
        kiroshiBtn.TextColor3 = Configurations.COLORS.KIROSHI
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
        opticalBtn.TextColor3 = Configurations.COLORS.OPTICAL
    end
end

-- Refactored Sandevistan to closely mimic David Martinez's: Intense activation, time freeze for others, super speed, rainbow holograms during movement.
local function ExecSandi()
    if os.clock() < State.Cooldowns.SANDI and not State.IsSandiActive then return end
    if State.IsSandiActive then
        ResetSandi()
        return
    end
    if State.Energy < Constants.ENERGY_COSTS.SANDI_ACTIVATE then return end
    State.Energy -= Constants.ENERGY_COSTS.SANDI_ACTIVATE
    State.NoRegenUntil = os.clock() + Constants.REGEN_DELAY_USE
    State.IsSandiActive = true
    PlaySFX(Configurations.ASSETS.SOUNDS.SANDI_ON, 1)  -- David's activation sound
    CamShake(1.5, 0.4)  -- Stronger shake for premium feel
    TweenService:Create(Camera, TweenInfo.new(0.4), {FieldOfView = 115}):Play()
    
    local sandiEffect = Create("ColorCorrectionEffect", {Name = "SandiEffect", TintColor = Color3.new(1,1,1), Contrast = 0, Saturation = 0, Parent = Lighting})
    -- Fade in light green
    TweenService:Create(sandiEffect, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TintColor = Configurations.COLORS.LIGHT_GREEN,
        Contrast = 0.15,  -- Enhanced contrast
        Saturation = -0.2  -- Deeper desaturation for Cyberpunk vibe
    }):Play()
    
    PlayActivationSequence()
    
    lastSandiClone = 0
    
    -- Start slow motion for the world
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
                        for
