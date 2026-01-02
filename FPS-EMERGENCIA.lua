--// MOBILE EXCLUSIVE ANTI-DELAY + ANTI-CRASH FINAL
--// Gráfico 1 FORÇADO | Render mínimo 390
--// Base: 85% partículas | 75% efeitos
--// Emergência automática + Ultra-emergência MANUAL
--// FPS + Ping REAL

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")
local Stats = game:GetService("Stats")
local UserSettings = UserSettings()
local UIS = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--==============================
-- CONFIG
--==============================

local STREAM_MIN = 400
local SOUND_LIMIT = 0.9

local FPS_DANGER = 22
local FPS_RECOVER = 35
local PING_DANGER = 220

-- Estados
local Emergency = false
local UltraEmergency = false

--==============================
-- FORÇA GRÁFICO 1 SEMPRE
--==============================

local function forceGraphicsLow()
	pcall(function()
		UserSettings.GameSettings.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
		UserSettings.GameSettings.GraphicsQualityLevel = 1
		settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
	end)
end

task.spawn(function()
	while true do
		forceGraphicsLow()
		task.wait(1)
	end
end)

--==============================
-- STREAMING FIXO
--==============================

pcall(function()
	if Workspace.StreamingEnabled then
		Workspace.StreamingMinRadius = STREAM_MIN
	end
end)

--==============================
-- ILUMINAÇÃO LEVE
--==============================

Lighting.GlobalShadows = false
Lighting.Technology = Enum.Technology.Compatibility
Lighting.FogEnd = 1e10

--==============================
-- OTIMIZAÇÃO VISUAL
--==============================

local function optimizeVisuals(obj)
	if obj:IsA("ParticleEmitter") then
		if UltraEmergency then
			obj.Enabled = false
		elseif Emergency then
			obj.Rate *= 0.05
			obj.Lifetime = NumberRange.new(0.05, 0.1)
		else
			obj.Rate *= 0.15
			obj.Lifetime = NumberRange.new(
				obj.Lifetime.Min * 0.15,
				obj.Lifetime.Max * 0.15
			)
		end

	elseif obj:IsA("Trail") or obj:IsA("Beam") then
		obj.Enabled = not (Emergency or UltraEmergency) and math.random() < 0.25

	elseif obj:IsA("BloomEffect") or obj:IsA("BlurEffect") then
		obj.Enabled = not (Emergency or UltraEmergency)
		if not Emergency and not UltraEmergency then
			obj.Intensity *= 0.25
		end

	elseif obj:IsA("ColorCorrectionEffect") then
		if Emergency or UltraEmergency then
			obj.Enabled = false
		else
			obj.Saturation *= 0.25
			obj.Contrast *= 0.25
		end
	end
end

for _, v in ipairs(game:GetDescendants()) do
	optimizeVisuals(v)
end
game.DescendantAdded:Connect(optimizeVisuals)

--==============================
-- SOM
--==============================

local function optimizeSound(sound)
	if not sound:IsA("Sound") then return end
	task.spawn(function()
		pcall(function()
			if sound.TimeLength == 0 then sound.Loaded:Wait() end
			if Emergency or UltraEmergency or sound.TimeLength > SOUND_LIMIT then
				sound.Volume *= 0.2
			end
		end)
	end)
end

SoundService.DescendantAdded:Connect(optimizeSound)

--==============================
-- ANTI TREMOR TOTAL
--==============================

RunService.RenderStepped:Connect(function()
	Camera.CameraType = Enum.CameraType.Custom
	Camera.FieldOfView = 70

	local char = Player.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.CameraOffset = Vector3.zero
		end
	end
end)

--==============================
-- FPS + PING + DETECÇÃO
--==============================

local PlayerGui = Player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui", PlayerGui)
gui.ResetOnSpawn = false

local label = Instance.new("TextLabel", gui)
label.Size = UDim2.new(0, 200, 0, 22)
label.Position = UDim2.new(0, 6, 0, 6)
label.BackgroundTransparency = 1
label.Font = Enum.Font.SourceSansBold
label.TextSize = 14
label.TextXAlignment = Enum.TextXAlignment.Left

local frames = 0
local last = tick()

RunService.RenderStepped:Connect(function()
	frames += 1
	local now = tick()

	if now - last >= 0.5 then
		local fps = math.floor(frames / (now - last))
		local ping = 0

		pcall(function()
			ping = math.floor(
				Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
			)
		end)

		-- AUTOMÁTICO (só se Ultra não estiver ativo)
		if not UltraEmergency then
			if (fps <= FPS_DANGER or ping >= PING_DANGER) and not Emergency then
				Emergency = true
			elseif fps >= FPS_RECOVER and Emergency then
				Emergency = false
			end
		end

		label.Text =
			UltraEmergency and ("🛑 ULTRA | FPS: "..fps.." | Ping: "..ping.."ms")
			or Emergency and ("⚠ EMERGÊNCIA | FPS: "..fps.." | Ping: "..ping.."ms")
			or ("FPS: "..fps.." | Ping: "..ping.."ms")

		label.TextColor3 =
			UltraEmergency and Color3.fromRGB(255, 0, 0)
			or Emergency and Color3.fromRGB(255, 120, 0)
			or Color3.fromRGB(0, 255, 0)

		frames = 0
		last = now
	end
end)

--==============================
-- ULTRA-EMERGÊNCIA MANUAL (3 TOQUES / 2s)
--==============================

local touchCount = 0
local touchStart = 0

UIS.TouchStarted:Connect(function()
	touchCount += 1
	if touchCount == 1 then
		touchStart = tick()
	end

	if touchCount >= 3 and tick() - touchStart >= 2 then
		UltraEmergency = not UltraEmergency
		touchCount = 0
	end
end)

UIS.TouchEnded:Connect(function()
	if tick() - touchStart > 2 then
		touchCount = 0
	end
end)

--==============================
-- PRIORIDADE ULTRA
--==============================

task.spawn(function()
	while true do
		if UltraEmergency then
			Emergency = false
			forceGraphicsLow()
		end
		task.wait(0.5)
	end
end)

print("🛡️ ANTI-CRASH + ULTRA-EMERGÊNCIA ATIVO")
