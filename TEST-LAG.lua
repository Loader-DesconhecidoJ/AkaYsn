--[[ 
    MODO EXTREMO - FPS MAX
    Render otimizado
    Anti-freeze
    Mobile Ultra Low
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

-- ================= QUALIDADE MÍNIMA =================
pcall(function()
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
end)

-- ================= ILUMINAÇÃO EXTREMA =================
for _,v in ipairs(Lighting:GetChildren()) do
    if v:IsA("PostEffect") then
        v.Enabled = false
    end
end

Lighting.GlobalShadows = false
Lighting.FogEnd = 1e10
Lighting.Brightness = 1
Lighting.EnvironmentDiffuseScale = 0
Lighting.EnvironmentSpecularScale = 0
Lighting.OutdoorAmbient = Color3.new(1,1,1)
Lighting.Ambient = Color3.new(1,1,1)

-- ================= RENDER / STREAM =================
pcall(function()
    workspace.StreamingEnabled = false
end)

-- ================= OTIMIZAÇÃO AGRESSIVA =================
local function extremeOptimize(v)
    if v:IsA("BasePart") then
        v.Material = Enum.Material.Plastic
        v.Reflectance = 0
        v.CastShadow = false
    elseif v:IsA("MeshPart") then
        v.Material = Enum.Material.Plastic
        v.TextureID = ""
        v.CastShadow = false
    elseif v:IsA("Decal") or v:IsA("Texture") then
        v.Transparency = 1
    elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
        v.Enabled = false
    elseif v:IsA("Fire") or v:IsA("Smoke") then
        v.Enabled = false
    end
end

-- aplica UMA VEZ
for _,v in ipairs(workspace:GetDescendants()) do
    extremeOptimize(v)
end

-- só novos objetos (sem loop infinito)
workspace.DescendantAdded:Connect(extremeOptimize)

-- ================= DISTÂNCIA DE RENDER (FAKE LOD) =================
local MAX_DISTANCE = 300 -- quanto menor, mais FPS

RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local pos = hrp.Position
    for _,p in ipairs(workspace:GetChildren()) do
        if p:IsA("BasePart") then
            local d = (p.Position - pos).Magnitude
            if d > MAX_DISTANCE then
                p.LocalTransparencyModifier = 1
            else
                p.LocalTransparencyModifier = 0
            end
        end
    end
end)

-- ================= ANIMAÇÕES =================
-- mantém SOMENTE as do player
workspace.DescendantAdded:Connect(function(v)
    if LocalPlayer.Character and v:IsDescendantOf(LocalPlayer.Character) then return end
    if v:IsA("Animator") then
        v.AnimationPlayed:Connect(function(track)
            track:Stop()
        end)
    end
end)

-- ================= FPS COUNTER REAL =================
local gui = Instance.new("ScreenGui")
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.Size = UDim2.new(0,140,0,40)
label.Position = UDim2.new(0,10,0,10)
label.BackgroundTransparency = 0.3
label.BackgroundColor3 = Color3.new(0,0,0)
label.TextColor3 = Color3.fromRGB(0,255,0)
label.Font = Enum.Font.Code
label.TextSize = 20
label.Text = "FPS: 0"
label.BorderSizePixel = 0
label.Parent = gui
Instance.new("UICorner", label).CornerRadius = UDim.new(0,10)

local frames = 0
local last = tick()

RunService.RenderStepped:Connect(function()
    frames += 1
    local now = tick()
    if now - last >= 1 then
        label.Text = "FPS: "..math.floor(frames / (now - last))
        frames = 0
        last = now
    end
end)

print("[MODO EXTREMO] FPS MAX + Render otimizado ativo")
--[[ 
    LOWEST GRAPHICS REAL
    Workspace + Texturas + Efeitos
    SEM travamento
    Mobile Safe
--]]

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

-- ================= QUALIDADE ENGINE =================
pcall(function()
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
end)

-- ================= ILUMINAÇÃO LOWEST =================
for _,v in ipairs(Lighting:GetChildren()) do
    if v:IsA("PostEffect") then
        v.Enabled = false
    end
end

Lighting.GlobalShadows = false
Lighting.Brightness = 1
Lighting.FogStart = 0
Lighting.FogEnd = 9e9
Lighting.Ambient = Color3.fromRGB(120,120,120)
Lighting.OutdoorAmbient = Color3.fromRGB(120,120,120)
Lighting.EnvironmentDiffuseScale = 0
Lighting.EnvironmentSpecularScale = 0

-- ================= FUNÇÃO LOWEST (LEVE) =================
local function applyLowest(v)
    -- PARTES
    if v:IsA("BasePart") then
        v.Material = Enum.Material.Plastic
        v.Reflectance = 0
        v.CastShadow = false

    -- MESH
    elseif v:IsA("MeshPart") then
        v.Material = Enum.Material.Plastic
        v.TextureID = ""
        v.CastShadow = false

    -- TEXTURAS
    elseif v:IsA("Decal") or v:IsA("Texture") then
        v.Transparency = 1

    -- EFEITOS
    elseif v:IsA("ParticleEmitter")
        or v:IsA("Trail")
        or v:IsA("Fire")
        or v:IsA("Smoke")
        or v:IsA("Sparkles") then
        v.Enabled = false
    end
end

-- ================= APLICA UMA VEZ =================
for _,v in ipairs(workspace:GetDescendants()) do
    applyLowest(v)
end

-- ================= NOVOS OBJETOS (SEM LOOP) =================
workspace.DescendantAdded:Connect(function(v)
    applyLowest(v)
end)

-- ================= RESPAWN FIX (LEVE) =================
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    for _,v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            v.LocalTransparencyModifier = 0
        end
    end
end)

print("[LOWEST GRAPHICS] Ativo | Estável | Sem travamento")
