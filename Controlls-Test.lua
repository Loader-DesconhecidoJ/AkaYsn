-- SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local StarterGui = game:GetService("StarterGui")

-- =========================
-- FPS + RELÓGIO (HUD RGB)
-- =========================

local player = Players.LocalPlayer

-- GUI base
local gui = Instance.new("ScreenGui")
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player.PlayerGui

-- FPS
local fpsLabel = Instance.new("TextLabel")
fpsLabel.Size = UDim2.fromOffset(120,30)
fpsLabel.Position = UDim2.fromOffset(20,20)
fpsLabel.BackgroundTransparency = 1 -- remove fundo
fpsLabel.TextColor3 = Color3.new(1,1,1)
fpsLabel.Font = Enum.Font.GothamBold
fpsLabel.TextSize = 18
fpsLabel.TextXAlignment = Enum.TextXAlignment.Left
fpsLabel.Text = "FPS: 0"
fpsLabel.ZIndex = 300
fpsLabel.Parent = gui

-- RELÓGIO
local clockLabel = Instance.new("TextLabel")
clockLabel.Size = UDim2.fromOffset(160,30)
clockLabel.Position = UDim2.new(1,-180,0,20)
clockLabel.BackgroundTransparency = 1 -- remove fundo
clockLabel.TextColor3 = Color3.new(1,1,1)
clockLabel.Font = Enum.Font.GothamBold
clockLabel.TextSize = 18
clockLabel.TextXAlignment = Enum.TextXAlignment.Right
clockLabel.Text = "--:--:--"
clockLabel.ZIndex = 300
clockLabel.Parent = gui

-- =========================
-- RGB ANIMADO
-- =========================

local hue = 0

RunService.RenderStepped:Connect(function(dt)
	hue = (hue + dt * 0.15) % 1
	local color = Color3.fromHSV(hue, 1, 1)
	fpsLabel.TextColor3 = color
	clockLabel.TextColor3 = color
end)

-- =========================
-- CONTADOR FPS
-- =========================

local frames = 0
local last = tick()

RunService.RenderStepped:Connect(function()
	frames += 1
	if tick() - last >= 1 then
		fpsLabel.Text = "FPS: "..frames
		frames = 0
		last = tick()
	end
end)

-- =========================
-- ATUALIZA RELÓGIO
-- =========================

task.spawn(function()
	while true do
		clockLabel.Text = os.date("%H:%M:%S")
		task.wait(1)
	end
end)
-- === DESATIVAR CONTROLES PADRÃO DO ROBLOX MOBILE ===

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.TouchControls, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end)

task.spawn(function()
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")

	local function removeTouchGui()
		local tg = pg:FindFirstChild("TouchGui")
		if tg then
			tg:Destroy()
		end
	end

	removeTouchGui()
	pg.ChildAdded:Connect(removeTouchGui)
end)

-- PLAYER
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local backpack = player:WaitForChild("Backpack")

player.CharacterAdded:Connect(function(char)
character = char
humanoid = char:WaitForChild("Humanoid")
end)

-- GUI
local gui = Instance.new("ScreenGui")
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player.PlayerGui


---

-- ANIMAÇÃO DE BOTÃO

local function pressToSize(btn, size)
TweenService:Create(
btn,
TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
{ Size = size }
):Play()
end


---

-- D-PAD

local dpad = Instance.new("Frame")
dpad.Size = UDim2.fromOffset(180,180)
dpad.Position = UDim2.new(0,140,1,-230)
dpad.BackgroundTransparency = 1
dpad.ZIndex = 20
dpad.Parent = gui

local function dpadBtn(x,y,t)
local b = Instance.new("TextButton")
b.Size = UDim2.fromOffset(70,70)
b.Position = UDim2.fromOffset(x,y)
b.Text = t
b.TextSize = 36
b.Font = Enum.Font.GothamBold
b.BackgroundColor3 = Color3.fromRGB(70,70,70)
b.TextColor3 = Color3.fromRGB(240,240,240)
b.BackgroundTransparency = 0.15
b.AutoButtonColor = false
b.ZIndex = 21
b.Parent = dpad
Instance.new("UICorner", b).CornerRadius = UDim.new(0.25,0)
return b
end

local gap = 69

local up = dpadBtn(gap, 0, "↑")
local down = dpadBtn(gap, gap*2, "↓")
local left = dpadBtn(0, gap, "←")
local right = dpadBtn(gap*2, gap, "→")

local moveVec = Vector3.zero

local function bindMove(btn, vec)
local original = btn.Size
btn.InputBegan:Connect(function(i)
if i.UserInputType == Enum.UserInputType.Touch then
moveVec = vec
pressToSize(btn, UDim2.fromOffset(54,54))
end
end)
btn.InputEnded:Connect(function(i)
if i.UserInputType == Enum.UserInputType.Touch then
moveVec = Vector3.zero
pressToSize(btn, original)
end
end)
end

bindMove(up, Vector3.new(0,0,-1))
bindMove(down, Vector3.new(0,0,1))
bindMove(left, Vector3.new(-1,0,0))
bindMove(right, Vector3.new(1,0,0))

RunService.RenderStepped:Connect(function()
humanoid:Move(moveVec, true)
end)


---

-- BOTÕES A B X Y (CORRIGIDOS)

local actionPad = Instance.new("Frame")
actionPad.Size = UDim2.fromOffset(220,220)
actionPad.BackgroundTransparency = 1
actionPad.ZIndex = 20
actionPad.Parent = gui

local function actionBtn(x,y,t,c)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(70,70)
	b.Position = UDim2.fromOffset(x,y)
	b.Text = t
	b.TextScaled = true
	b.Font = Enum.Font.GothamBold
	b.BackgroundColor3 = c
	b.TextColor3 = Color3.new(1,1,1)
	b.BackgroundTransparency = 0.12
	b.AutoButtonColor = false
	b.ZIndex = 21
	b.Parent = actionPad
	Instance.new("UICorner", b).CornerRadius = UDim.new(0.35,0)

	-- animação de pressão
	local original = b.Size
	b.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch then
			pressToSize(b, UDim2.fromOffset(62,62))
		end
	end)
	b.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch then
			pressToSize(b, original)
		end
	end)

	return b
end

-- layout estilo controle
local gap = 60

local btnY = actionBtn(gap,0,"Y",Color3.fromRGB(200,200,60))
local btnX = actionBtn(0,gap,"X",Color3.fromRGB(60,120,200))
local btnB = actionBtn(gap*2,gap,"B",Color3.fromRGB(200,60,60))
local btnA = actionBtn(gap,gap*2,"A",Color3.fromRGB(60,200,120))


---

-- INVENTÁRIO (NÃO BLOQUEIA TOQUE)

local invContainer = Instance.new("Frame")
invContainer.AnchorPoint = Vector2.new(0.5,0.5)
invContainer.Position = UDim2.fromScale(0.5,0.5)
invContainer.Size = UDim2.fromScale(0,0)
invContainer.BackgroundColor3 = Color3.fromRGB(25,25,25)
invContainer.Visible = false
invContainer.ZIndex = 15
invContainer.Active = false
invContainer.Parent = gui
Instance.new("UICorner", invContainer)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(160,160,160)
stroke.Thickness = 2
stroke.Parent = invContainer

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,40)
title.BackgroundTransparency = 1
title.Text = "Inventário"
title.Font = Enum.Font.GothamBold
title.TextSize = 26
title.TextColor3 = Color3.fromRGB(230,230,230)
title.ZIndex = 16
title.Parent = invContainer

local invGui = Instance.new("ScrollingFrame")
invGui.Position = UDim2.fromOffset(10,50)
invGui.Size = UDim2.new(1,-20,1,-60)
invGui.ScrollBarImageTransparency = 0.4
invGui.BackgroundTransparency = 1
invGui.ZIndex = 16
invGui.Parent = invContainer

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.fromOffset(70,70)
grid.CellPadding = UDim2.fromOffset(10,10)
grid.Parent = invGui

grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
invGui.CanvasSize = UDim2.fromOffset(0, grid.AbsoluteContentSize.Y + 20)
end)

local function openInventory()
invContainer.Visible = true
TweenService:Create(invContainer,
TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
{Size = UDim2.fromScale(0.4,0.45)}
):Play()
end

local function closeInventory()
local t = TweenService:Create(invContainer,
TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
{Size = UDim2.fromScale(0,0)}
)
t:Play()
t.Completed:Wait()
invContainer.Visible = false
end

local function refreshInventory()
for _,c in ipairs(invGui:GetChildren()) do
if c:IsA("ImageButton") then c:Destroy() end
end

for _,tool in ipairs(backpack:GetChildren()) do
if tool:IsA("Tool") then
local slot = Instance.new("ImageButton")
slot.BackgroundColor3 = Color3.fromRGB(60,60,60)
slot.ZIndex = 17
slot.Parent = invGui
Instance.new("UICorner", slot)

if tool.TextureId ~= "" then
slot.Image = tool.TextureId
else
local txt = Instance.new("TextLabel")
txt.Size = UDim2.fromScale(1,1)
txt.BackgroundTransparency = 1
txt.Text = tool.Name
txt.TextWrapped = true
txt.TextScaled = true
txt.TextColor3 = Color3.new(1,1,1)
txt.ZIndex = 18
txt.Parent = slot
end

slot.MouseButton1Click:Connect(function()
tool.Parent = character
closeInventory()
end)

end

end

end


---

-- AÇÕES

btnY.InputBegan:Connect(function(i)
if i.UserInputType ~= Enum.UserInputType.Touch then return end
pressToSize(btnY, UDim2.fromOffset(66,66))
refreshInventory()
if invContainer.Visible then
closeInventory()
else
openInventory()
end
end)
btnY.InputEnded:Connect(function(i)
if i.UserInputType == Enum.UserInputType.Touch then
pressToSize(btnY, UDim2.fromOffset(60,60))
end
end)

btnA.InputBegan:Connect(function(i)
if i.UserInputType == Enum.UserInputType.Touch then
pressToSize(btnA, UDim2.fromOffset(54,54))
humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
end
end)
btnA.InputEnded:Connect(function(i)
if i.UserInputType == Enum.UserInputType.Touch then
pressToSize(btnA, UDim2.fromOffset(60,60))
end
end)

btnX.InputBegan:Connect(function(i)
if i.UserInputType ~= Enum.UserInputType.Touch then return end
pressToSize(btnX, UDim2.fromOffset(54,54))
for _,t in ipairs(character:GetChildren()) do
if t:IsA("Tool") then
t:Activate()
return
end
end
end)
btnX.InputEnded:Connect(function(i)
if i.UserInputType == Enum.UserInputType.Touch then
pressToSize(btnX, UDim2.fromOffset(60,60))
end
end)

btnB.InputBegan:Connect(function(i)
if i.UserInputType == Enum.UserInputType.Touch then
pressToSize(btnB, UDim2.fromOffset(54,54))
StarterGui:SetCore("OpenMenu")
end
end)
btnB.InputEnded:Connect(function(i)
if i.UserInputType == Enum.UserInputType.Touch then
pressToSize(btnB, UDim2.fromOffset(60,60))
end
end)

-- HOTBAR CUSTOMIZADA (BUG FIX + GLOW RGB)

pcall(function()
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end)

local hotbar = Instance.new("Frame")
hotbar.Size = UDim2.fromOffset(360,70)
hotbar.Position = UDim2.new(0.5,0,1,-90)
hotbar.AnchorPoint = Vector2.new(0.5,0)
hotbar.BackgroundTransparency = 1
hotbar.ZIndex = 18
hotbar.Parent = gui

local MAX_SLOTS = 5
local hotSlots = {}
local glowTweens = {}

local GLOW_COLORS = {
Color3.fromRGB(0,255,0),
Color3.fromRGB(0,170,255),
Color3.fromRGB(255,60,60),
Color3.fromRGB(255,220,0)
}

local function createSlot(index)
local btn = Instance.new("ImageButton")
btn.Size = UDim2.fromOffset(60,60)
btn.Position = UDim2.fromOffset((index-1)*70,0)
btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
btn.BackgroundTransparency = 0.15
btn.AutoButtonColor = false
btn.ZIndex = 19
btn.Parent = hotbar
Instance.new("UICorner", btn).CornerRadius = UDim.new(0.3,0)

local stroke = Instance.new("UIStroke")
stroke.Thickness = 0
stroke.Color = Color3.new(1,1,1)
stroke.Parent = btn

local icon = Instance.new("ImageLabel")
icon.Size = UDim2.fromScale(0.9,0.9)
icon.Position = UDim2.fromScale(0.05,0.05)
icon.BackgroundTransparency = 1
icon.ZIndex = 20
icon.Parent = btn

return {
Button = btn,
Icon = icon,
Stroke = stroke,
Tool = nil
}

end

for i = 1, MAX_SLOTS do
hotSlots[i] = createSlot(i)
end


---

-- GLOW RGB ANIMADO

local function startGlow(slot)
if glowTweens[slot] then return end
local idx = 1

glowTweens[slot] = task.spawn(function()
while slot.Tool and slot.Tool.Parent == character do
local tween = TweenService:Create(
slot.Stroke,
TweenInfo.new(0.35, Enum.EasingStyle.Linear),
{ Color = GLOW_COLORS[idx] }
)
tween:Play()
tween.Completed:Wait()
idx = idx % #GLOW_COLORS + 1
end
end)

end

local function stopGlow(slot)
glowTweens[slot] = nil
slot.Stroke.Thickness = 0
end


---

-- UPDATE HOTBAR (BACKPACK + CHARACTER)

local function getAllTools()
local tools = {}

for _,t in ipairs(backpack:GetChildren()) do
if t:IsA("Tool") then
table.insert(tools, t)
end
end
for _,t in ipairs(character:GetChildren()) do
if t:IsA("Tool") then
table.insert(tools, t)
end
end

return tools

end

local function updateHotbar()
for _,slot in ipairs(hotSlots) do
stopGlow(slot)
slot.Tool = nil
slot.Icon.Image = ""
end

local tools = getAllTools()

for i = 1, math.min(#tools, MAX_SLOTS) do
local tool = tools[i]
local slot = hotSlots[i]
slot.Tool = tool

if tool.TextureId ~= "" then
slot.Icon.Image = tool.TextureId
end

if tool.Parent == character then
slot.Stroke.Thickness = 3
startGlow(slot)
end

end

end


---

-- INPUT HOTBAR (EQUIPAR / DESEQUIPAR)

for _,slot in ipairs(hotSlots) do
slot.Button.InputBegan:Connect(function(i)
if i.UserInputType ~= Enum.UserInputType.Touch then return end
if not slot.Tool then return end

pressToSize(slot.Button, UDim2.fromOffset(54,54))

if slot.Tool.Parent == character then
slot.Tool.Parent = backpack
else
slot.Tool.Parent = character
end

task.wait()
updateHotbar()

end)

slot.Button.InputEnded:Connect(function(i)
if i.UserInputType == Enum.UserInputType.Touch then
pressToSize(slot.Button, UDim2.fromOffset(60,60))
end
end)

end


---

-- EVENTOS

backpack.ChildAdded:Connect(updateHotbar)
backpack.ChildRemoved:Connect(updateHotbar)
character.ChildAdded:Connect(updateHotbar)
character.ChildRemoved:Connect(updateHotbar)

task.wait(0.2)
updateHotbar()
-- === ADAPTAÇÃO AUTOMÁTICA À TELA (D-PAD + A B X Y) ===

local Camera = workspace.CurrentCamera

local function updateControlPositions()
	local viewport = Camera.ViewportSize
	local margin = math.clamp(viewport.X * 0.04, 16, 40)

	-- D-PAD (lado esquerdo)
dpad.Position = UDim2.new(
	0, 
	margin + 30, -- mais pra direita
	1, 
	- dpad.Size.Y.Offset - margin - 20
)

	-- ACTION PAD (lado direito)
actionPad.Position = UDim2.new(
	1, 
	- actionPad.Size.X.Offset - margin - 5, -- mais pra direita
	1, 
	- actionPad.Size.Y.Offset - margin + 10  -- mais pra baixo
)
end

-- Atualiza ao iniciar
updateControlPositions()

-- Atualiza se a tela mudar (rotação / resize)
Camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateControlPositions)
-- =========================
-- MENU DE CONFIGURAÇÕES
-- =========================

local settingsGui = Instance.new("ScreenGui")
settingsGui.ResetOnSpawn = false
settingsGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
settingsGui.Parent = player.PlayerGui

-- Botão de abrir menu
local settingsBtn = Instance.new("TextButton")
settingsBtn.Size = UDim2.fromOffset(44,44)
settingsBtn.Position = UDim2.fromOffset(20,60)
settingsBtn.Text = "⚙️"
settingsBtn.TextSize = 24
settingsBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
settingsBtn.TextColor3 = Color3.new(1,1,1)
settingsBtn.ZIndex = 200
settingsBtn.Parent = settingsGui
Instance.new("UICorner", settingsBtn)

-- Painel do menu
local menuFrame = Instance.new("Frame")
menuFrame.Size = UDim2.fromOffset(260,220)
menuFrame.Position = UDim2.fromOffset(20,70)
menuFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
menuFrame.Visible = false
menuFrame.ZIndex = 201
menuFrame.Parent = settingsGui
Instance.new("UICorner", menuFrame)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(120,120,120)
stroke.Thickness = 2
stroke.Parent = menuFrame

-- Layout
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0,12)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.Parent = menuFrame

-- Função para criar botão do menu
local function menuButton(text, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(220,46)
    b.BackgroundColor3 = Color3.fromRGB(60,60,60)
    b.TextColor3 = Color3.new(1,1,1)
    b.TextScaled = true
    b.Font = Enum.Font.GothamBold
    b.Text = text
    b.AutoButtonColor = false
    b.ZIndex = 202
    b.Parent = menuFrame
    Instance.new("UICorner", b)

    b.MouseButton1Click:Connect(callback)

    return b
end

-- =========================
-- BOTÕES DO MENU (3)
-- =========================

local hotbarBtn = menuButton("Hotbar: Custom")
local option2Btn = menuButton("Opção 2 (Jogo Teleporte)")
local option3Btn = menuButton("Opção 3 (em breve)")

option2Btn.BackgroundTransparency = 0.4
option3Btn.BackgroundTransparency = 0.4

-- =========================
-- NOVO MENU DE JOGOS (Opção 2)
-- =========================

local gamesMenu = Instance.new("Frame")
gamesMenu.Size = UDim2.fromOffset(300, 350)  -- Aumentei o tamanho para acomodar os botões dentro
gamesMenu.Position = UDim2.fromScale(0.5, 0.5)  -- Centraliza no meio da tela
gamesMenu.AnchorPoint = Vector2.new(0.5, 0.5)  -- Centraliza a âncora
gamesMenu.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
gamesMenu.Visible = false
gamesMenu.ZIndex = 201
gamesMenu.Parent = settingsGui
Instance.new("UICorner", gamesMenu)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(120, 120, 120)
stroke.Thickness = 2
stroke.Parent = gamesMenu

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.fromOffset(100, 100)  -- Botões de 100x100 pixels
gridLayout.CellPadding = UDim2.fromOffset(10, 10)  -- Espaço entre os botões
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
gridLayout.VerticalAlignment = Enum.VerticalAlignment.Center
gridLayout.Parent = gamesMenu

-- Função para criar botões de jogos
local function createGameButton(gameName, gameId)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(100, 100)  -- Tamanho quadrado dos botões
    b.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    b.TextColor3 = Color3.new(1, 1, 1)
    b.TextScaled = true
    b.Font = Enum.Font.GothamBold
    b.Text = gameName
    b.AutoButtonColor = false
    b.ZIndex = 202
    b.Parent = gamesMenu
    Instance.new("UICorner", b)

    -- Ação do botão (teleportar para o jogo)
    b.MouseButton1Click:Connect(function()
        game:GetService("TeleportService"):Teleport(gameId, player)
    end)
end

-- Adicionando botões de jogos
createGameButton("Gun-Grounds-FFA", 12137249458)  -- Troque 123456789 pelo ID do seu jogo
createGameButton("Jogo 2", 987654321)  -- Troque 987654321 pelo ID do seu jogo
createGameButton("Jogo 3", 112233445)  -- Troque 112233445 pelo ID do seu jogo
createGameButton("Jogo 4", 556677889)  -- Troque 556677889 pelo ID do seu jogo

-- Animação para abrir o menu de jogos (Teleport Games)
local function openGamesMenu()
    gamesMenu.Visible = true
    TweenService:Create(gamesMenu,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Size = UDim2.fromScale(0.5, 0.5) }  -- Ajuste o tamanho conforme necessário
    ):Play()
end

-- Animação para fechar o menu de jogos
local function closeGamesMenu()
    local tween = TweenService:Create(gamesMenu,
        TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { Size = UDim2.fromScale(0, 0) }
    )
    tween:Play()
    tween.Completed:Wait()
    gamesMenu.Visible = false
end

-- Mostrar o menu de jogos ao clicar na opção 2 do menu
option2Btn.MouseButton1Click:Connect(function()
    if gamesMenu.Visible then
        closeGamesMenu()
    else
        openGamesMenu()
    end
end)

-- Botão de voltar para o menu principal
local backButton = Instance.new("TextButton")
backButton.Size = UDim2.fromOffset(220, 46)
backButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
backButton.TextColor3 = Color3.new(1, 1, 1)
backButton.TextScaled = true
backButton.Font = Enum.Font.GothamBold
backButton.Text = "Voltar"
backButton.AutoButtonColor = false
backButton.ZIndex = 202
backButton.Parent = gamesMenu
Instance.new("UICorner", backButton)

backButton.MouseButton1Click:Connect(function()
    closeGamesMenu()  -- Fecha o menu de jogos
end)

-- =========================
-- CONTROLE HOTBAR
-- =========================

local customHotbarEnabled = true

local function updateHotbarState()
    if customHotbarEnabled then
        hotbar.Visible = true
        pcall(function()
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
        end)
        hotbarBtn.Text = "Hotbar: Custom"
    else
        hotbar.Visible = false
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
        hotbarBtn.Text = "Hotbar: Default"
    end
end

-- =========================
-- SCROLL NO MENU CONFIG
-- =========================

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.fromOffset(260, 300)  -- Tamanho maior para acomodar o conteúdo
scrollFrame.Position = UDim2.fromOffset(20, 70)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 6
scrollFrame.Parent = menuFrame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 12)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Top
layout.Parent = scrollFrame

-- Botões para ativar/desativar FPS, Relógio e Controles
local fpsEnabled = true
local clockEnabled = true
local controlsEnabled = true

local function toggleFPS()
    fpsEnabled = not fpsEnabled
    fpsLabel.Visible = fpsEnabled
end

local function toggleClock()
    clockEnabled = not clockEnabled
    clockLabel.Visible = clockEnabled
end

local function toggleControls()
    controlsEnabled = not controlsEnabled
    dpad.Visible = controlsEnabled
    actionPad.Visible = controlsEnabled
end

-- Botões no menu para controlar as opções
local fpsBtn = menuButton("FPS: On", function()
    toggle
