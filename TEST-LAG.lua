--[[ 
    LOWEST GRAPHICS REAL + FPS COUNTER
    Workspace + Texturas + Efeitos
    Estável | Mobile Safe
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
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

-- ================= FUNÇÃO LOWEST =================
local function applyLowest(v)
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

-- ================= NOVOS OBJETOS =================
workspace.DescendantAdded:Connect(applyLowest)

-- ================= RESPAWN FIX =================
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    for _,v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            v.LocalTransparencyModifier = 0
        end
    end
end)

-- ================= FPS COUNTER REAL =================
local gui = Instance.new("ScreenGui")
gui.Name = "FPS_COUNTER_REAL"
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.Size = UDim2.new(0,150,0,40)
label.Position = UDim2.new(0,10,0,10)
label.BackgroundTransparency = 0.3
label.BackgroundColor3 = Color3.fromRGB(0,0,0)
label.TextColor3 = Color3.fromRGB(0,255,0)
label.Font = Enum.Font.Code
label.TextSize = 20
label.BorderSizePixel = 0
label.Text = "FPS: 0"
label.Parent = gui

Instance.new("UICorner", label).CornerRadius = UDim.new(0,10)

local frames = 0
local lastTime = tick()
local fps = 0

RunService.RenderStepped:Connect(function()
    frames += 1
    local now = tick()
    if now - lastTime >= 1 then
        fps = math.floor(frames / (now - lastTime))
        frames = 0
        lastTime = now

        label.Text = "FPS: "..fps

        if fps >= 40 then
            label.TextColor3 = Color3.fromRGB(0,255,0)
        elseif fps >= 25 then
            label.TextColor3 = Color3.fromRGB(255,170,0)
        else
            label.TextColor3 = Color3.fromRGB(255,0,0)
        end
    end
end)

print("[LOWEST GRAPHICS + FPS COUNTER] Ativo | Estável")
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
