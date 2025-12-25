-- =========================================
-- UNIVERSAL MOBILE FPS SCRIPT
-- PRESETS + FPS COUNTER
-- Client-Side | Visual Only
-- =========================================

--------------------------------------------------
-- 🔧 ESCOLHA O PRESET AQUI
--------------------------------------------------
-- 1 = FPS EXTREMO (visual feio, máximo desempenho)
-- 2 = BALANCEADO (recomendado)
-- 3 = VISUAL LEVE (menos agressivo)

local PRESET = 2
--------------------------------------------------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

--------------------------------------------------
-- 🛑 NO SHAKE TOTAL
--------------------------------------------------

local savedCFrame = camera.CFrame
local savedFOV = camera.FieldOfView

RunService.RenderStepped:Connect(function()
	camera.CFrame = savedCFrame
	camera.FieldOfView = savedFOV
end)

RunService.RenderStepped:Connect(function()
	savedCFrame = camera.CFrame
end)

--------------------------------------------------
-- ❄️ ANTI DELAY / ANTI FREEZE
--------------------------------------------------

RunService.RenderStepped:Connect(function()
	RunService.Heartbeat:Wait()
end)

task.spawn(function()
	while task.wait(12) do
		collectgarbage("step", 200)
	end
end)

--------------------------------------------------
-- 🌑 LIMPA EFEITOS DE LUZ
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
-- 🎨 CONFIGURAÇÕES POR PRESET
--------------------------------------------------

if PRESET == 1 then
	-- 🔥 FPS EXTREMO
	local c = Instance.new("ColorCorrectionEffect")
	c.Brightness = -0.1
	c.Contrast = 0
	c.Saturation = -0.6
	c.Parent = Lighting

	Lighting.ExposureCompensation = -0.6
	Lighting.GlobalShadows = false

elseif PRESET == 2 then
	-- ⚖️ BALANCEADO
	local c = Instance.new("ColorCorrectionEffect")
	c.Brightness = -0.05
	c.Contrast = 0.03
	c.Saturation = -0.3
	c.Parent = Lighting

	Lighting.ExposureCompensation = -0.4
	Lighting.GlobalShadows = false

elseif PRESET == 3 then
	-- 👁️ VISUAL LEVE
	local c = Instance.new("ColorCorrectionEffect")
	c.Brightness = 0
	c.Contrast = 0.05
	c.Saturation = -0.1
	c.Parent = Lighting

	Lighting.ExposureCompensation = -0.2
end

--------------------------------------------------
-- 🧱 REMOVER TEXTURAS / VISUAL EM BLOCOS
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
-- 🚀 QUALIDADE GRÁFICA MÍNIMA
--------------------------------------------------

settings().Rendering.QualityLevel = Enum.QualityLevel.Level01

--------------------------------------------------
-- 🔥 DESATIVAR EFEITOS PESADOS
--------------------------------------------------

for _, v in pairs(workspace:GetDescendants()) do
	if v:IsA("ParticleEmitter")
	or v:IsA("Trail")
	or v:IsA("Smoke")
	or v:IsA("Fire")
	or v:IsA("Explosion") then
		v.Enabled = false
	end
end

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

--------------------------------------------------
-- 📊 FPS COUNTER (LEVE / MOBILE)
--------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "FPSCounter"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.Size = UDim2.new(0,120,0,30)
label.Position = UDim2.new(0,10,0,10)
label.BackgroundTransparency = 0.4
label.BackgroundColor3 = Color3.fromRGB(0,0,0)
label.TextColor3 = Color3.fromRGB(0,255,0)
label.TextScaled = true
label.Font = Enum.Font.SourceSansBold
label.Text = "FPS: 0"
label.Parent = gui

local fps = 0
local frames = 0
local last = tick()

RunService.RenderStepped:Connect(function()
	frames += 1
	if tick() - last >= 1 then
		fps = frames
		frames = 0
		last = tick()
		label.Text = "FPS: "..fps
	end
end)
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
-- SUPER POTATO REAL (FUNCIONA)
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

-- Lighting
Lighting.GlobalShadows = false
Lighting.FogEnd = 9e9
Lighting.Brightness = 0
Lighting.ClockTime = 14
Lighting.EnvironmentDiffuseScale = 0
Lighting.EnvironmentSpecularScale = 0

-- Remove efeitos
for _,v in pairs(Lighting:GetChildren()) do
    if v:IsA("PostEffect") then
        v:Destroy()
    end
end

-- Mundo
for _,v in pairs(workspace:GetDescendants()) do
    if v:IsA("BasePart") then
        v.Material = Enum.Material.SmoothPlastic
        v.Reflectance = 0
    elseif v:IsA("Decal") or v:IsA("Texture") then
        v:Destroy()
    elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
        v.Enabled = false
    end
end

-- Remove sombras dinamicamente
RunService.RenderStepped:Connect(function()
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
end)

print("✅ Super Potato ATIVO")
