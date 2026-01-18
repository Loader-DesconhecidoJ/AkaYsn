local Lighting = game:GetService("Lighting")

-- 1. Configurações de Tempo e Atmosfera
Lighting.ClockTime = 17.8
Lighting.Brightness = 2 -- Mantém luz direcional, mas controlada
Lighting.Ambient = Color3.fromRGB(0, 0, 0) -- Zero luz de fundo (escuridão total nas sombras)
Lighting.OutdoorAmbient = Color3.fromRGB(10, 10, 10) -- Mínima luz externa
Lighting.ExposureCompensation = 0.5 -- Ajuste de exposição para 4K
Lighting.ShadowSoftness = 0 -- Sombras nítidas e realistas

-- 2. Efeito Bloom (O Brilho Branco)
local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect", Lighting)
bloom.Intensity = 1.2
bloom.Size = 24
bloom.Threshold = 0.8 -- Apenas cores muito claras (branco) brilham

-- 3. ColorCorrection (Otimização 4K)
local color = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect", Lighting)
color.Contrast = 0.15
color.Saturation = 0.1
color.TintColor = Color3.fromRGB(255, 255, 255)

-- 4. SunRays (Efeito de feixes de luz)
local sunRays = Lighting:FindFirstChildOfClass("SunRaysEffect") or Instance.new("SunRaysEffect", Lighting)
sunRays.Intensity = 0.1
sunRays.Spread = 1

-- 5. Atmosphere (Neblina densa e realista)
local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
atmosphere.Density = 0.3
atmosphere.Offset = 0.1
atmosphere.Color = Color3.fromRGB(150, 150, 150)
atmosphere.Decay = Color3.fromRGB(0, 0, 0)

print("Boost Graphics 4K Ativado!")
