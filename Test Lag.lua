--// 🔥 OPTIMIZER MOBILE 2026 - ULTRA LITE (Zero Input Lag + Anti Spam)
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer

local effectClasses = {
    ParticleEmitter = true, Trail = true, Smoke = true, Fire = true, Sparkles = true,
    Beam = true, SelectionBox = true, SelectionHighlight = true,
    PointLight = true, SpotLight = true, SurfaceLight = true, Explosion = true
}

local function cleanVFX(obj)
    if obj:IsA("Highlight") then
        pcall(function()
            obj.Enabled = false
            obj.FillTransparency = 1
            obj.OutlineTransparency = 1
        end)
        return
    end
    if effectClasses[obj.ClassName] then
        pcall(function()
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Light") then
                obj.Enabled = false
            else
                obj:Destroy()
            end
        end)
    end
end

local function optimizePart(part)
    if not part:IsA("BasePart") then return end
    pcall(function()
        part.Material = Enum.Material.SmoothPlastic
        part.CastShadow = false
        if part:IsA("MeshPart") then
            part.CollisionFidelity = Enum.CollisionFidelity.Box
        end
    end)
end

local function setupCharacter(character)
    for _, v in ipairs(character:GetDescendants()) do
        cleanVFX(v)
    end
    character.DescendantAdded:Connect(cleanVFX)
end

local function monitorPlayer(player)
    if player == localPlayer then return end
    player.CharacterAdded:Connect(setupCharacter)
    if player.Character then
        setupCharacter(player.Character)
    end
end

--// INÍCIO (muito mais leve)
local function optimizeLighting()
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("PostEffect") or obj:IsA("Sky") or obj:IsA("Atmosphere") or obj:IsA("Clouds") then
            pcall(obj.Destroy, obj)
        end
    end

    Lighting.GlobalShadows = false
    Lighting.FogEnd = 500
    Lighting.FogStart = 400
    Lighting.EnvironmentDiffuseScale = 0
    Lighting.EnvironmentSpecularScale = 0

    pcall(function()
        Lighting.Technology = Enum.Technology.Compatibility
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end)

    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        terrain.WaterWaveSize = 0
        terrain.WaterWaveSpeed = 0
        terrain.WaterReflectance = 0
        terrain.WaterTransparency = 1
    end
end

optimizeLighting()

-- Monitora só jogadores (nada de limpar o mapa inteiro)
for _, plr in ipairs(Players:GetPlayers()) do
    monitorPlayer(plr)
end
Players.PlayerAdded:Connect(monitorPlayer)

-- Limpa só as coisas novas que aparecem (task.defer = super leve)
Workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("BasePart") then
        task.defer(optimizePart, obj)
    else
        cleanVFX(obj)
    end
end)

Lighting.ChildAdded:Connect(function(child)
    if child:IsA("PostEffect") or child:IsA("Sky") or child:IsA("Atmosphere") or child:IsA("Clouds") then
        child:Destroy()
    end
end)

print("✅ ULTRA LITE carregado! Toques devem voltar ao normal.")
