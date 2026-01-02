--// ANTI DELAY + AUTO ULTRA + MODO CRÍTICO
--// FPS controla agressividade TOTAL
--// CRÍTICO remove 100% partículas e efeitos
--// ULTRA/CRÍTICO só sai com FPS >= 40

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

local STREAM_MIN = 390
local SOUND_LIMIT = 0.9
local FPS_EXIT = 40

--==============================
-- FORÇA GRÁFICO 1
--==============================

task.spawn(function()
	while true do
		pcall(function()
			UserSettings.GameSettings.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
			UserSettings.GameSettings.GraphicsQualityLevel = 1
			settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
		end)
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
-- NÍVEL POR FPS
--==============================

local function getLevelByFPS(fps)
	if fps <= 12 then
		return "CRITICAL"
	elseif fps <= 21 then
		return "ULTRA"
	elseif fps <= 29 then
		return "EMERGENCY"
	elseif fps <= 39 then
		return "LIGHT"
	else
		return "NORMAL"
	end
end

--==============================
-- VISUAIS DINÂMICOS
--==============================

local function optimizeVisuals(obj, level)
	if obj:IsA("ParticleEmitter") then
		if level == "CRITICAL" then
			obj.Enabled = false -- 100%
		elseif level == "ULTRA" then
			obj.Rate *= 0.05
			obj.Lifetime = NumberRange.new(0.03, 0.08)
		elseif level == "EMERGENCY" then
			obj.Rate *= 0.2
		elseif level == "LIGHT" then
			obj.Rate *= 0.6
		end

	elseif obj:IsA("Trail") or obj:IsA("Beam") then
		if level == "CRITICAL" then
			obj.Enabled = false
		elseif level == "ULTRA" then
			obj.Enabled = false
		elseif level == "EMERGENCY" then
			obj.Enabled = math.random() < 0.2
		elseif level == "LIGHT" then
			obj.Enabled = math.random() < 0.6
		end

	elseif obj:IsA("BloomEffect") or obj:IsA("BlurEffect")
		or obj:IsA("SunRaysEffect") or obj:IsA("DepthOfFieldEffect") then

		if level == "CRITICAL" then
			obj.Enabled = false
		elseif level == "ULTRA" then
			obj.Enabled = false
		elseif level == "EMERGENCY" then
			obj.Intensity *= 0.25
		elseif level == "LIGHT" then
			obj.Intensity *= 0.6
		end

	elseif obj:IsA("ColorCorrectionEffect") then
		if level == "CRITICAL" then
			obj.Enabled = false
		elseif level == "ULTRA" then
			obj.Enabled = false
		elseif level == "EMERGENCY" then
			obj.Saturation *= 0.25
			obj.Contrast *= 0.25
		elseif level == "LIGHT" then
			obj.Saturation *= 0.6
		end
	end
end

--==============================
-- SOM
--==============================

SoundService.DescendantAdded:Connect(function(s)
	if not s:IsA("Sound") then return end
	task.spawn(function()
		pcall(function()
			if s.TimeLength == 0 then s.Loaded:Wait() end
			if s.TimeLength > SOUND_LIMIT then
				s.Volume *= 0.2
			end
		end)
	end)
end)

--==============================
-- ANTI TREMOR DE CÂMERA
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
-- FPS + PING + AUTO CONTROLE
--==============================

local gui = Instance.new("ScreenGui", Player.PlayerGui)
gui.ResetOnSpawn = false

local label = Instance.new("TextLabel", gui)
label.Size = UDim2.new(0, 260, 0, 22)
label.Position = UDim2.new(0, 6, 0, 6)
label.BackgroundTransparency = 1
label.Font = Enum.Font.SourceSansBold
label.TextSize = 14
label.TextXAlignment = Enum.TextXAlignment.Left

local frames = 0
local last = tick()
local lockedCritical = false

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

		if fps <= 12 then
			lockedCritical = true
		elseif lockedCritical and fps >= FPS_EXIT then
			lockedCritical = false
		end

		local level = lockedCritical and "CRITICAL" or getLevelByFPS(fps)

		for _, v in ipairs(game:GetDescendants()) do
			optimizeVisuals(v, level)
		end

		label.Text =
			level == "CRITICAL" and ("💀 CRÍTICO | FPS: "..fps.." | Ping: "..ping.."ms")
			or level == "ULTRA" and ("🔴 ULTRA | FPS: "..fps.." | Ping: "..ping.."ms")
			or level == "EMERGENCY" and ("🟠 EMERGÊNCIA | FPS: "..fps.." | Ping: "..ping.."ms")
			or level == "LIGHT" and ("🟡 LEVE | FPS: "..fps.." | Ping: "..ping.."ms")
			or ("🟢 FPS: "..fps.." | Ping: "..ping.."ms")

		label.TextColor3 =
			level == "CRITICAL" and Color3.fromRGB(150,0,0)
			or level == "ULTRA" and Color3.fromRGB(255,0,0)
			or level == "EMERGENCY" and Color3.fromRGB(255,150,0)
			or level == "LIGHT" and Color3.fromRGB(255,255,0)
			or Color3.fromRGB(0,255,0)

		frames = 0
		last = now
	end
end)

print("🛡️ AUTO ULTRA + MODO CRÍTICO ATIVO")
