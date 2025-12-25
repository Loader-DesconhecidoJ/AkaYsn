-- =========================================
-- UNIVERSAL MOBILE FPS SCRIPT V2
-- EXTREMO + ESTÁVEL + BAIXO USO DE CPU
-- Client-Side | Visual Only
-- =========================================

------------------ PRESET ------------------
-- 1 = FPS EXTREMO
-- 2 = BALANCEADO (recomendado)
-- 3 = VISUAL LEVE
local PRESET = 1
--------------------------------------------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

--------------------------------------------------
-- 🛑 NO SHAKE (LEVE, SEM FORÇAR CPU)
--------------------------------------------------

local lastCF = camera.CFrame
local lastFOV = camera.FieldOfView

RunService.RenderStepped:Connect(function()
	camera.CFrame = lastCF
	camera.FieldOfView = lastFOV
	lastCF = camera.CFrame
end)

--------------------------------------------------
-- ❄️ ANTI STUTTER INTELIGENTE
--------------------------------------------------

task.spawn(function()
	while task.wait(0.25) do
		RunService.Heartbeat:Wait()
	end
end)

task.spawn(function()
	while task.wait(15) do
		collectgarbage("step", 150)
	end
end)

--------------------------------------------------
-- 🌑 LIMPEZA DE LUZ (UMA VEZ)
--------------------------------------------------

local function cleanLighting()
	for _, v in ipairs(Lighting:GetChildren()) do
		if v:IsA("BloomEffect")
		or v:IsA("SunRaysEffect")
		or v:IsA("DepthOfFieldEffect")
		or v:IsA("ColorCorrectionEffect") then
			v:Destroy()
		end
	end
end

cleanLighting()

--------------------------------------------------
-- 🎨 PRESETS DE COR (OTIMIZADOS)
--------------------------------------------------

local cc = Instance.new("ColorCorrectionEffect")
cc.Parent = Lighting

if PRESET == 1 then
	cc.Brightness = -0.1
	cc.Contrast = 0
	cc.Saturation = -0.6
	Lighting.ExposureCompensation = -0.6
	Lighting.GlobalShadows = false

elseif PRESET == 2 then
	cc.Brightness = -0.05
	cc.Contrast = 0.03
	cc.Saturation = -0.3
	Lighting.ExposureCompensation = -0.4
	Lighting.GlobalShadows = false

else
	cc.Brightness = 0
	cc.Contrast = 0.05
	cc.Saturation = -0.1
	Lighting.ExposureCompensation = -0.2
end

--------------------------------------------------
-- 🧱 REMOVER TEXTURAS (EVENT-BASED)
--------------------------------------------------

local function optimizeInstance(obj)
	if obj:IsA("Texture") or obj:IsA("Decal") then
		obj:Destroy()
	elseif obj:IsA("BasePart") then
		obj.Material = Enum.Material.Plastic
		obj.Reflectance = 0
	end
end

for _, v in ipairs(workspace:GetDescendants()) do
	optimizeInstance(v)
end

workspace.DescendantAdded:Connect(optimizeInstance)

--------------------------------------------------
-- 🚀 QUALIDADE GRÁFICA MÍNIMA
--------------------------------------------------

settings().Rendering.QualityLevel = Enum.QualityLevel.Level01

--------------------------------------------------
-- 🔥 DESATIVAR EFEITOS PESADOS
--------------------------------------------------

local function disableEffects(obj)
	if obj:IsA("ParticleEmitter")
	or obj:IsA("Trail")
	or obj:IsA("Smoke")
	or obj:IsA("Fire")
	or obj:IsA("Explosion") then
		obj.Enabled = false
	end
end

for _, v in ipairs(workspace:GetDescendants()) do
	disableEffects(v)
end

workspace.DescendantAdded:Connect(disableEffects)

--------------------------------------------------
-- 🔁 ANTI POST-FX RECRIADO
--------------------------------------------------

Lighting.ChildAdded:Connect(function(child)
	if child:IsA("BloomEffect")
	or child:IsA("SunRaysEffect")
	or child:IsA("DepthOfFieldEffect") then
		child:Destroy()
	end
end)

--------------------------------------------------
-- 📊 FPS COUNTER (MÉDIA REAL, SEM OSCILAÇÃO)
--------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local lbl = Instance.new("TextLabel")
lbl.Size = UDim2.new(0,130,0,28)
lbl.Position = UDim2.new(0,10,0,10)
lbl.BackgroundTransparency = 0.4
lbl.BackgroundColor3 = Color3.fromRGB(0,0,0)
lbl.TextColor3 = Color3.fromRGB(0,255,0)
lbl.Font = Enum.Font.SourceSansBold
lbl.TextScaled = true
lbl.Text = "FPS: --"
lbl.Parent = gui

local frames = 0
local lastTime = tick()
local fpsSmooth = 0

RunService.RenderStepped:Connect(function()
	frames += 1
	local now = tick()
	if now - lastTime >= 1 then
		local raw = frames / (now - lastTime)
		fpsSmooth = fpsSmooth == 0 and raw or (fpsSmooth * 0.7 + raw * 0.3)
		lbl.Text = "FPS: "..math.floor(fpsSmooth)
		frames = 0
		lastTime = now
	end
end)

--------------------------------------------------
-- ♻️ RESPAWN SAFE
--------------------------------------------------

player.CharacterAdded:Connect(function()
	task.wait(0.5)
	cleanLighting()
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
