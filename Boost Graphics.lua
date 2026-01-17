local Lighting = game:GetService("Lighting")

-- LIMPEZA TOTAL DE AMBIENTE
Lighting:ClearAllChildren()

-- CONFIGURAÇÃO DE RENDERIZAÇÃO FÍSICA
Lighting.ClockTime = 17.8
Lighting.Brightness = 3.5 -- Brilho intenso para HDR
Lighting.ExposureCompensation = 0.8
Lighting.ShadowSoftness = 0 -- Sombras ultra nítidas (Realismo 4K)
Lighting.EnvironmentDiffuseScale = 1
Lighting.EnvironmentSpecularScale = 1
Lighting.GeographicLatitude = 45 -- Muda o ângulo das sombras para ficar mais estético

-- 1. ATMOSPHERE (Scattering de luz avançado)
local atm = Instance.new("Atmosphere", Lighting)
atm.Density = 0.3
atm.Offset = 0.5
atm.Color = Color3.fromRGB(255, 170, 100) -- Tom dourado
atm.Decay = Color3.fromRGB(50, 40, 80)    -- Sombras azuladas profundas
atm.Glare = 5  -- Reflexo solar intenso
atm.Haze = 2   -- Neblina de calor no horizonte

-- 2. COLOR CORRECTION (O "LUT" de Cinema)
local cc = Instance.new("ColorCorrectionEffect", Lighting)
cc.Brightness = 0.05
cc.Contrast = 0.55 -- Contraste agressivo para profundidade
cc.Saturation = 0.35
cc.TintColor = Color3.fromRGB(255, 245, 230)

-- 3. BLOOM (Simulação de lente de câmera)
local bloom = Instance.new("BloomEffect", Lighting)
bloom.Intensity = 0.8
bloom.Size = 40
bloom.Threshold = 0.9 -- Apenas luzes muito fortes brilham

-- 4. DEPTH OF FIELD (Anti-Aliasing natural e Foco)
local dof = Instance.new("DepthOfFieldEffect", Lighting)
dof.FarIntensity = 1
dof.NearIntensity = 0.1
dof.FocusDistance = 45
dof.InFocusRadius = 25

-- 5. SUNRAYS (Raios Volumétricos)
local rays = Instance.new("SunRaysEffect", Lighting)
rays.Intensity = 0.2
rays.Spread = 1

-- 6. AMBIENT SOUND (Som 3D de Vento e Natureza)
local sound = Instance.new("Sound", game:GetService("SoundService"))
sound.SoundId = "rbxassetid://6008893443" -- Vento de montanha realista
sound.Volume = 0.6
sound.Looped = true
sound:Play()

-- AJUSTE DE TERRENO (Se houver grama ou água)
local terrain = workspace:FindFirstChildOfClass("Terrain")
if terrain then
    terrain.WaterReflectance = 1
    terrain.WaterWaveSize = 0.15
    terrain.WaterWaveSpeed = 10
    terrain.WaterTransparency = 0.8
    terrain.WaterColor = Color3.fromRGB(50, 90, 110)
end

print("--- ULTRA 4K SHADERS LOADED (17.8) ---")
