--// MOBILE ANTI-DELAY EXTREMO
--// 100% EFEITOS OFF
--// 100% PARTÍCULAS OFF
--// RENDER FIXO 170
--// FPS + PING REAL

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")
local Stats = game:GetService("Stats")
local UserSettings = UserSettings()

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--==============================
-- CONFIG
--==============================

local STREAM_RADIUS = 170
local GRAPHICS_LEVEL = 1
local SOUND_LIMIT = 0.4

--==============================
-- GRÁFICO FORÇADO NO 1
--==============================

local function forceGraphics()
	pcall(function()
		UserSettings.GameSettings.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
		UserSettings.GameSettings.GraphicsQualityLevel = GRAPHICS_LEVEL
		settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
	end)
end

forceGraphics()

task.spawn(function()
	while true do
		forceGraphics()
		task.wait(2)
	end
end)

--==============================
-- STREAMING FIXO (170 / 170)
--==============================

pcall(function()
	if Workspace.StreamingEnabled then
		Workspace.StreamingMinRadius = STREAM_RADIUS
		Workspace.StreamingTargetRadius = STREAM_RADIUS
	end
end)

task.spawn(function()
	while true do
		pcall(function()
			if Workspace.StreamingEnabled then
				Workspace.StreamingMinRadius = STREAM_RADIUS
				Workspace.StreamingTargetRadius = STREAM_RADIUS
			end
		end)
		task.wait(3)
	end
end)

--==============================
-- REMOVE 100% DOS EFEITOS VISUAIS
--==============================

local function removeAllEffects(obj)
	if obj:IsA("BloomEffect")
	or obj:IsA("BlurEffect")
	or obj:IsA("SunRaysEffect")
	or obj:IsA("DepthOfFieldEffect")
	or obj:IsA("ColorCorrectionEffect")
	or obj:IsA("Atmosphere")
	or obj:IsA("Sky")
	or obj:IsA("Clouds") then
		obj:Destroy()
	end
end

for _, v in ipairs(game:GetDescendants()) do
	removeAllEffects(v)
end
game.DescendantAdded:Connect(removeAllEffects)

-- Iluminação crua (mais leve impossível)
Lighting.GlobalShadows = false
Lighting.Technology = Enum.Technology.Compatibility
Lighting.Brightness = 1.5
Lighting.EnvironmentDiffuseScale = 0
Lighting.EnvironmentSpecularScale = 0
Lighting.FogStart = 0
Lighting.FogEnd = 1e10

--==============================
-- REMOVE 100% DAS PARTÍCULAS
--==============================

local function removeAllParticles(obj)
	if obj:IsA("ParticleEmitter")
	or obj:IsA("Trail")
	or obj:IsA("Beam")
	or obj:IsA("Smoke")
	or obj:IsA("Fire")
	or obj:IsA("Sparkles") then
		obj:Destroy()
	end
end

for _, v in ipairs(game:GetDescendants()) do
	removeAllParticles(v)
end
game.DescendantAdded:Connect(removeAllParticles)

--==============================
-- MAPA ULTRA LEVE
--==============================

task.spawn(function()
	while true do
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("BasePart") then
				obj.Material = Enum.Material.Plastic
				obj.CastShadow = false
				obj.Reflectance = 0
			end
		end
		task.wait(15)
	end
end)

--==============================
-- SOM LONGO REDUZIDO
--==============================

local function optimizeSound(sound)
	if not sound:IsA("Sound") then return end
	task.spawn(function()
		pcall(function()
			if sound.TimeLength == 0 then
				sound.Loaded:Wait()
			end
			if sound.TimeLength > SOUND_LIMIT then
				sound.Volume *= 0.4
			end
		end)
	end)
end

for _, s in ipairs(SoundService:GetDescendants()) do
	optimizeSound(s)
end
SoundService.DescendantAdded:Connect(optimizeSound)

--==============================
-- ANTI TREMOR DE CÂMERA
--==============================

RunService.RenderStepped:Connect(function()
	Camera.CameraType = Enum.CameraType.Custom
	Camera.FieldOfView = 70

	local char = Player.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.CameraOffset = Vector3.zero
	end
end)

--==============================
-- FPS COUNTER REAL + PING REAL
--==============================

local gui = Instance.new("ScreenGui")
gui.ResetOnSpawn = false
gui.Parent = Player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.Size = UDim2.new(0,160,0,20)
label.Position = UDim2.new(0,6,0,6)
label.BackgroundTransparency = 1
label.Font = Enum.Font.SourceSansBold
label.TextSize = 14
label.TextXAlignment = Enum.TextXAlignment.Left
label.Parent = gui

local frames = 0
local lastTime = os.clock()

RunService.RenderStepped:Connect(function()
	frames += 1
	local now = os.clock()

	if now - lastTime >= 0.5 then
		local fps = math.floor(frames / (now - lastTime))
		local ping = 0

		pcall(function()
			ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
		end)

		label.Text = "FPS: "..fps.." | Ping: "..ping.."ms"
		label.TextColor3 =
			fps >= 50 and Color3.fromRGB(0,255,0)
			or fps >= 30 and Color3.fromRGB(255,170,0)
			or Color3.fromRGB(255,60,60)

		frames = 0
		lastTime = now
	end
end)

print("🚀 ANTI-DELAY EXTREMO | 100% EFEITOS OFF | 100% PARTÍCULAS OFF | RENDER 170")
