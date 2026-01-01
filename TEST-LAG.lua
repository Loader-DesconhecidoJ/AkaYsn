--// EXCLUSIVE MOBILE ANTI-DELAY DEFINITIVO
--// Gráfico 1 FORÇADO | Texturas mínimas
--// 85% partículas | 75% efeitos
--// Render mínimo FORÇADO 390
--// FPS + Ping REAL

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

local SOUND_LIMIT = 0.9
local MAP_LOOP = 10
local STREAM_MIN = 390
local GRAPHICS_LEVEL = 1

--==============================
-- FORÇA GRÁFICO + TEXTURA NO 1
--==============================

local function forceGraphicsLow()
	pcall(function()
		UserSettings.GameSettings.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
		UserSettings.GameSettings.GraphicsQualityLevel = GRAPHICS_LEVEL
		settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
	end)
end

forceGraphicsLow()

task.spawn(function()
	while true do
		forceGraphicsLow()
		task.wait(1)
	end
end)

--==============================
-- STREAMING (FORÇA MÍNIMO)
--==============================

pcall(function()
	if Workspace.StreamingEnabled then
		Workspace.StreamingMinRadius = STREAM_MIN
	end
end)

task.spawn(function()
	while true do
		pcall(function()
			if Workspace.StreamingEnabled and Workspace.StreamingMinRadius < STREAM_MIN then
				Workspace.StreamingMinRadius = STREAM_MIN
			end
		end)
		task.wait(3)
	end
end)

--==============================
-- ILUMINAÇÃO LEVE
--==============================

Lighting.GlobalShadows = false
Lighting.Technology = Enum.Technology.Compatibility
Lighting.Brightness = 1.6
Lighting.EnvironmentDiffuseScale = 0.3
Lighting.EnvironmentSpecularScale = 0.15
Lighting.FogStart = 0
Lighting.FogEnd = 1e10

--==============================
-- 85% PARTÍCULAS / 75% EFEITOS
--==============================

local function optimizeVisuals(obj)

	if obj:IsA("ParticleEmitter") then
		obj.Rate *= 0.15
		obj.Lifetime = NumberRange.new(
			obj.Lifetime.Min * 0.15,
			obj.Lifetime.Max * 0.15
		)
		obj.Speed = NumberRange.new(
			obj.Speed.Min * 0.25,
			obj.Speed.Max * 0.25
		)

	elseif obj:IsA("Trail") or obj:IsA("Beam") then
		obj.Enabled = math.random() < 0.25

	-- 🔻 EFEITOS 75% OFF
	elseif obj:IsA("ColorCorrectionEffect") then
		obj.Saturation *= 0.25
		obj.Contrast *= 0.25

	elseif obj:IsA("BloomEffect") then
		obj.Intensity *= 0.25

	elseif obj:IsA("BlurEffect") then
		obj.Size *= 0.25
	end
end

for _, v in ipairs(game:GetDescendants()) do
	optimizeVisuals(v)
end
game.DescendantAdded:Connect(optimizeVisuals)

--==============================
-- ANTI TREMOR DE CÂMERA
--==============================

RunService.RenderStepped:Connect(function()
	Camera.CameraType = Enum.CameraType.Custom
	Camera.FieldOfView = 70

	local char = Player.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum and hum.CameraOffset.Magnitude > 0 then
		hum.CameraOffset = Vector3.zero
	end
end)

--==============================
-- MAPA LEVE
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
		task.wait(MAP_LOOP)
	end
end)

--==============================
-- SOM > 0.9s REDUZIDO
--==============================

local function optimizeSound(sound)
	if not sound:IsA("Sound") then return end
	task.spawn(function()
		pcall(function()
			if sound.TimeLength == 0 then
				sound.Loaded:Wait()
			end
			if sound.TimeLength > SOUND_LIMIT then
				sound.Volume *= 0.3
			end
		end)
	end)
end

for _, s in ipairs(SoundService:GetDescendants()) do
	optimizeSound(s)
end
SoundService.DescendantAdded:Connect(optimizeSound)
workspace.DescendantAdded:Connect(optimizeSound)

--==============================
-- FPS + PING COUNTER
--==============================

local PlayerGui = Player:WaitForChild("PlayerGui")

local statsGui = Instance.new("ScreenGui")
statsGui.Name = "FPSPingCounter"
statsGui.ResetOnSpawn = false
statsGui.Parent = PlayerGui

local statsLabel = Instance.new("TextLabel")
statsLabel.Size = UDim2.new(0, 140, 0, 20)
statsLabel.Position = UDim2.new(0, 6, 0, 6)
statsLabel.BackgroundTransparency = 1
statsLabel.TextStrokeTransparency = 0.5
statsLabel.Font = Enum.Font.SourceSansBold
statsLabel.TextSize = 14
statsLabel.TextXAlignment = Enum.TextXAlignment.Left
statsLabel.Text = "FPS: -- | Ping: --"
statsLabel.Parent = statsGui

local frames = 0
local lastTime = tick()

RunService.RenderStepped:Connect(function()
	frames += 1
	local now = tick()

	if now - lastTime >= 0.5 then
		local fps = math.floor(frames / (now - lastTime))
		local ping = 0

		pcall(function()
			ping = math.floor(
				Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
			)
		end)

		statsLabel.Text = "FPS: "..fps.." | Ping: "..ping.."ms"

		if fps >= 50 then
			statsLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
		elseif fps >= 30 then
			statsLabel.TextColor3 = Color3.fromRGB(255, 170, 0)
		else
			statsLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
		end

		frames = 0
		lastTime = now
	end
end)

RunService:Set3dRenderingEnabled(true)

print("🔥 ANTI-DELAY FINAL | 75% EFEITOS | 85% PARTÍCULAS | RENDER 390 | FPS+PING")
