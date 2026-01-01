--==============================
-- FPS COUNTER (REAL | LEVE)
--==============================

local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local fpsGui = Instance.new("ScreenGui")
fpsGui.Name = "FPSCounter"
fpsGui.ResetOnSpawn = false
fpsGui.Parent = PlayerGui

local fpsLabel = Instance.new("TextLabel")
fpsLabel.Size = UDim2.new(0, 80, 0, 20)
fpsLabel.Position = UDim2.new(0, 6, 0, 6)
fpsLabel.BackgroundTransparency = 1
fpsLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
fpsLabel.TextStrokeTransparency = 0.5
fpsLabel.Font = Enum.Font.SourceSansBold
fpsLabel.TextSize = 14
fpsLabel.TextXAlignment = Enum.TextXAlignment.Left
fpsLabel.Text = "FPS: --"
fpsLabel.Parent = fpsGui

local frames = 0
local lastTime = tick()

RunService.RenderStepped:Connect(function()
	frames += 1
	local now = tick()

	if now - lastTime >= 0.5 then
		local fps = math.floor(frames / (now - lastTime))
		fpsLabel.Text = "FPS: " .. fps

		-- cor dinâmica (opcional, leve)
		if fps >= 50 then
			fpsLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
		elseif fps >= 30 then
			fpsLabel.TextColor3 = Color3.fromRGB(255, 170, 0)
		else
			fpsLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
		end

		frames = 0
		lastTime = now
	end
end)
--// EXCLUSIVE MOBILE ANTI-DELAY
--// 83% partículas | 65% efeitos | render mínimo FORÇADO 390

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")
local UserSettings = UserSettings()

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--==============================
-- CONFIG
--==============================

local SOUND_LIMIT = 0.9
local MAP_LOOP = 10
local STREAM_MIN = 390

--==============================
-- GRÁFICO BAIXO
--==============================

pcall(function()
	UserSettings.GameSettings.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
	UserSettings.GameSettings.GraphicsQualityLevel = 1
	settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
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
-- 83% PARTÍCULAS / 65% EFEITOS
--==============================

local function optimizeVisuals(obj)

	-- Partículas (83% OFF)
	if obj:IsA("ParticleEmitter") then
		obj.Rate *= 0.17
		obj.Lifetime = NumberRange.new(
			obj.Lifetime.Min * 0.17,
			obj.Lifetime.Max * 0.17
		)
		obj.Speed = NumberRange.new(
			obj.Speed.Min * 0.3,
			obj.Speed.Max * 0.3
		)

	-- Trails / Beams
	elseif obj:IsA("Trail") or obj:IsA("Beam") then
		obj.Enabled = math.random() < 0.3

	-- Efeitos (65%)
	elseif obj:IsA("ColorCorrectionEffect") then
		obj.Saturation *= 0.35
		obj.Contrast *= 0.35

	elseif obj:IsA("BloomEffect") then
		obj.Intensity *= 0.35

	elseif obj:IsA("BlurEffect") then
		obj.Size *= 0.35
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

RunService:Set3dRenderingEnabled(true)

print("✅ MOBILE EXCLUSIVE | 83% partículas | 65% efeitos | render mínimo 390")
