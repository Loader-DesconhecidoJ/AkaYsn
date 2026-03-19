-- =============================================
-- SCRIPT MISTURADO: LOW QUALITY EXTREMO + FOV 110 + FPS BOOST MÁXIMO
-- Deixa o jogo feio pra porra, FOV travado em 110, roda liso pra caralho
-- Mistura perfeita dos 2 scripts originais (low quality + todas as otimizações)
-- Cole no executor (Fluxus, Krnl, Solara, etc.)
-- =============================================

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Camera = Workspace.CurrentCamera

local function ApplyLowQuality()
    -- === LIGHTING ULTRA RUIM (low quality extremo) ===
    Lighting.Technology = Enum.Technology.Compatibility     -- segredo principal pra pixelado + leve
    Lighting.GlobalShadows = false
    Lighting.ShadowSoftness = 0
    Lighting.Brightness = 0.5
    Lighting.Ambient = Color3.fromRGB(65, 65, 65)
    Lighting.OutdoorAmbient = Color3.fromRGB(80, 80, 80)
    Lighting.EnvironmentDiffuseScale = 0.2
    Lighting.EnvironmentSpecularScale = 0.1
    
    -- Fog otimizado (mistura: limite distante do segundo + extremo do primeiro)
    Lighting.FogStart = 80
    Lighting.FogEnd = 100
    Lighting.FogColor = Color3.fromRGB(185, 185, 195)
    
    -- Desativa TODOS os efeitos bonitos + Atmosphere zerado
    for _, v in pairs(Lighting:GetChildren()) do
        if v:IsA("BloomEffect") or v:IsA("ColorCorrectionEffect") or 
           v:IsA("DepthOfFieldEffect") or v:IsA("SunRaysEffect") or 
           v:IsA("BlurEffect") or v:IsA("Atmosphere") then
            v.Enabled = false
            if v:IsA("Atmosphere") then
                v.Density = 0
                v.Offset = 0
                v.Glare = 0
                v.Haze = 0
            end
        end
    end
    
    -- === TERRAIN + ÁGUA (fica horrível mas leve pra caralho) ===
    if Workspace:FindFirstChild("Terrain") then
        local t = Workspace.Terrain
        t.WaterWaveSize = 0
        t.WaterWaveSpeed = 0
        t.WaterReflectance = 0
        t.WaterTransparency = 1
    end
end

-- Aplica em tudo que já existe
ApplyLowQuality()

-- Aplica em tudo que aparecer depois (nunca mais volta bonito)
Workspace.DescendantAdded:Connect(function(desc)
    if desc:IsA("BasePart") then
        desc.CastShadow = false
    elseif desc:IsA("ParticleEmitter") or desc:IsA("Trail") or desc:IsA("Beam") then
        desc.Enabled = false
    elseif desc:IsA("BloomEffect") or desc:IsA("ColorCorrectionEffect") or 
           desc:IsA("DepthOfFieldEffect") or desc:IsA("SunRaysEffect") or 
           desc:IsA("BlurEffect") or desc:IsA("Atmosphere") then
        desc.Enabled = false
    end
end)

-- Reaplica toda hora pra garantir que o jogo não tente carregar qualidade
RunService.Heartbeat:Connect(function()
    if Lighting.Technology ~= Enum.Technology.Compatibility then
        Lighting.Technology = Enum.Technology.Compatibility
    end
end)

-- === FOV 110 TRAVADO (prioridade máxima do segundo script) ===
local FOV_ALVO = 110

RunService.PreRender:Connect(function()
    Camera.FieldOfView = FOV_ALVO
end)

RunService.RenderStepped:Connect(function()
    Camera.FieldOfView = FOV_ALVO
end)

-- === OTIMIZAÇÕES TURBO DE PERFORMANCE (streaming, physics, etc.) ===
Workspace.StreamingEnabled = true
Lighting.EagerBulkExecution = true
settings().Rendering.EagerBulkExecution = true

-- Physics otimizado (zero sleep + throttle desativado)
pcall(function()
    settings().Physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.Disabled
    settings().Physics.AllowSleep = false
    settings().Physics.ForceSleep = false
end)

-- Configurações extras de performance máxima
pcall(function()
    settings().Rendering.EagerBulkExecution = true
    settings().Performance.MaxFPS = 0
    settings().Network.ShowGui = false
end)

print("✅ Script MISTURADO ativado! Low Quality EXTREMO + FOV 110 travado + FPS voando pra caralho!")
