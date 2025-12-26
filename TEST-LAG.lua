--[[ 
    UNIVERSAL LOWEST GRAPHICS
    FFLAGS CONVERTIDAS PRA LUA
    FPS COUNTER REAL
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local lp = Players.LocalPlayer

-- ================= ENGINE QUALITY =================
pcall(function()
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
end)

-- ================= POST FX OFF (FFlagDisablePostFx) =================
for _,v in ipairs(Lighting:GetChildren()) do
    if v:IsA("PostEffect") then
        v.Enabled = false
    end
end

-- ================= LIGHTING LOWEST =================
Lighting.GlobalShadows = false
Lighting.Brightness = 1
Lighting.EnvironmentDiffuseScale = 0
Lighting.EnvironmentSpecularScale = 0
Lighting.Ambient = Color3.fromRGB(140,140,140)
Lighting.OutdoorAmbient = Color3.fromRGB(140,140,140)

-- Céu simples (DebugSkyGray)
if Lighting:FindFirstChildOfClass("Sky") then
    Lighting:FindFirstChildOfClass("Sky"):Destroy()
end

-- ================= LOWEST OBJECTS =================
local function lowest(v)
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

-- aplica UMA VEZ (sem travar)
for _,v in ipairs(workspace:GetDescendants()) do
    lowest(v)
end

-- novos objetos (leve)
workspace.DescendantAdded:Connect(function(v)
    if v:IsA("ParticleEmitter") or v:IsA("Trail") then
        v.Enabled = false
    end
end)

-- ================= FPS COUNTER REAL =================
local gui = Instance.new("ScreenGui")
gui.Name = "REAL_FPS"
gui.ResetOnSpawn = false
gui.Parent = lp:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.Size = UDim2.new(0,150,0,36)
label.Position = UDim2.new(0,10,0,10)
label.BackgroundTransparency = 0.35
label.BackgroundColor3 = Color3.new(0,0,0)
label.Font = Enum.Font.Code
label.TextSize = 18
label.BorderSizePixel = 0
label.Text = "FPS: 0"
label.Parent = gui
Instance.new("UICorner", label).CornerRadius = UDim.new(0,10)

local frames = 0
local last = tick()
local fps = 0

RunService.RenderStepped:Connect(function()
    frames += 1
    local now = tick()
    if now - last >= 1 then
        fps = math.floor(frames / (now - last))
        frames = 0
        last = now

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

print("[UNIVERSAL FLAGS] LOWEST + FPS REAL ativo")
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
