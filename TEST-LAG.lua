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
local MAX_DISTANCE = 350 -- quanto menor, mais FPS

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
-- FASTFLAG SIMULATION SCRIPT (MOBILE)
-- Visual + Performance | Client-Side

local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local ContentProvider = game:GetService("ContentProvider")
local camera = workspace.CurrentCamera

--------------------------------------------------
-- 🚫 SIMULA: FFlagDisablePostFx
--------------------------------------------------

for _, v in pairs(Lighting:GetChildren()) do
	if v:IsA("BloomEffect")
	or v:IsA("SunRaysEffect")
	or v:IsA("DepthOfFieldEffect")
	or v:IsA("ColorCorrectionEffect") then
		v:Destroy()
	end
end

local cc = Instance.new("ColorCorrectionEffect")
cc.Brightness = -0.05
cc.Contrast = 0.03
cc.Saturation = -0.30
cc.Parent = Lighting

Lighting.ExposureCompensation = -0.4
Lighting.GlobalShadows = false

--------------------------------------------------
-- 🧱 SIMULA: TextureQualityOverride + SkipMips
--------------------------------------------------

for _, obj in pairs(workspace:GetDescendants()) do
	if obj:IsA("Texture") or obj:IsA("Decal") then
		obj:Destroy()
	elseif obj:IsA("BasePart") then
		obj.Material = Enum.Material.Plastic
		obj.Reflectance = 0
	end
end

--------------------------------------------------
-- 🌍 SIMULA: Terrain simplificado
--------------------------------------------------

local terrain = workspace:FindFirstChildOfClass("Terrain")
if terrain then
	terrain.WaterWaveSize = 0
	terrain.WaterWaveSpeed = 0
	terrain.WaterReflectance = 0
	terrain.WaterTransparency = 1
end

--------------------------------------------------
-- 🛑 NO SHAKE (ANTI CAMERA)
--------------------------------------------------

local lastCFrame = camera.CFrame
local lastFOV = camera.FieldOfView

RunService.RenderStepped:Connect(function()
	camera.CFrame = lastCFrame
	camera.FieldOfView = lastFOV
end)

RunService.RenderStepped:Connect(function()
	lastCFrame = camera.CFrame
end)

--------------------------------------------------
-- ❄️ ANTI DELAY / GC / STUTTER
--------------------------------------------------

pcall(function()
	ContentProvider:PreloadAsync({})
end)

task.spawn(function()
	while task.wait(12) do
		collectgarbage("step", 200)
	end
end)

--------------------------------------------------
-- 🚀 FPS / RENDER OTIMIZADO
--------------------------------------------------

settings().Rendering.QualityLevel = Enum.QualityLevel.Level01

pcall(function()
	sethiddenproperty(Lighting, "Technology", Enum.Technology.Compatibility)
end)

pcall(function()
	workspace.StreamingEnabled = false
end)

--------------------------------------------------
-- 🔥 DESATIVAR EFEITOS PESADOS
--------------------------------------------------

for _, v in pairs(workspace:GetDescendants()) do
	if v:IsA("ParticleEmitter")
	or v:IsA("Trail")
	or v:IsA("Smoke")
	or v:IsA("Fire") then
		v.Enabled = false
	end
end

--------------------------------------------------
-- 🔁 ANTI RECRIAÇÃO DE POSTFX
--------------------------------------------------

Lighting.ChildAdded:Connect(function(child)
	if child:IsA("BloomEffect")
	or child:IsA("SunRaysEffect")
	or child:IsA("DepthOfFieldEffect") then
		child:Destroy()
	end
end)
-- FASTFLAG SIMULATION SCRIPT (MOBILE)
-- Visual + Render Optimization
-- Client-Side

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

--------------------------------------------------
-- 🚫 SIMULA: FFlagDisablePostFx = true
--------------------------------------------------

for _, v in pairs(Lighting:GetChildren()) do
	if v:IsA("BloomEffect")
	or v:IsA("SunRaysEffect")
	or v:IsA("DepthOfFieldEffect")
	or v:IsA("ColorCorrectionEffect") then
		v:Destroy()
	end
end

--------------------------------------------------
-- 🌑 SIMULA: FFlagDebugSkyGray = false
--------------------------------------------------

Lighting.Ambient = Color3.fromRGB(120,120,120)
Lighting.OutdoorAmbient = Color3.fromRGB(120,120,120)
Lighting.Brightness = 1
Lighting.ExposureCompensation = -0.4
Lighting.GlobalShadows = false

--------------------------------------------------
-- 🧱 SIMULA: TextureQualityOverride + SkipMips
--------------------------------------------------

for _, obj in pairs(workspace:GetDescendants()) do
	if obj:IsA("Texture") or obj:IsA("Decal") then
		obj:Destroy()
	elseif obj:IsA("BasePart") then
		obj.Material = Enum.Material.Plastic
		obj.Reflectance = 0
	end
end

--------------------------------------------------
-- 🖼️ SIMULA: DFIntTextureQualityOverride = 0
--------------------------------------------------

settings().Rendering.QualityLevel = Enum.QualityLevel.Level01

--------------------------------------------------
-- 🎮 SIMULA: MSAA 4x (parcial)
--------------------------------------------------

pcall(function()
	sethiddenproperty(Lighting, "Technology", Enum.Technology.Compatibility)
end)

--------------------------------------------------
-- ❄️ REDUZ STUTTER (scheduler fake)
--------------------------------------------------

RunService.RenderStepped:Connect(function()
	RunService.Heartbeat:Wait()
end)

--------------------------------------------------
-- 🔁 ANTI EFEITOS RECRIADOS
--------------------------------------------------

Lighting.ChildAdded:Connect(function(child)
	if child:IsA("BloomEffect")
	or child:IsA("SunRaysEffect")
	or child:IsA("DepthOfFieldEffect") then
		child:Destroy()
	end
end)
