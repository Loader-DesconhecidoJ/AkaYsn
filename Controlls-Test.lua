-- SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local StarterGui = game:GetService("StarterGui")

-- Variáveis do player
local player = Players.LocalPlayer
local backpack = player:WaitForChild("Backpack")

-- Função para desativar a hotbar do Roblox
local function disableRobloxHotbar()
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) -- Desativa a mochila do Roblox
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Hotbar, false)   -- Desativa a hotbar do Roblox
    end)
end

-- Ativa ou desativa a hotbar personalizada
local customHotbarEnabled = true  -- Defina como 'true' se a hotbar personalizada deve ser ativada

-- Função para garantir que a hotbar do Roblox esteja desativada
task.spawn(function()
    while true do
        if customHotbarEnabled then
            disableRobloxHotbar()
        else
            pcall(function()
                StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true) -- Restaura a mochila
                StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Hotbar, true)   -- Restaura a hotbar
            end)
        end
        task.wait(1)  -- Verifica a cada 1 segundo
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
local backpack = player:WaitForChild("Backpack")

-- 3. Quando o personagem é adicionado ao jogador (resetado ou renascido)
player.CharacterAdded:Connect(function()
    task.wait(1)  -- Aguarda um pouco para garantir que o personagem tenha sido completamente reiniciado
    updateHotbar()  -- Atualiza a hotbar com os itens corretos
    refreshInventory()  -- Atualiza o inventário para refletir os itens corretos
end)

-- ===== PERSONAGEM ATUAL (CORRETO) =====
local character
local humanoid

-- Função para configurar o personagem
local function setupCharacter(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")

    -- Reconecta hotbar no personagem novo
    character.ChildAdded:Connect(updateHotbar)
    character.ChildRemoved:Connect(updateHotbar)
end

-- primeira vez
if player.Character then
    setupCharacter(player.Character)
end

-- quando morrer / renascer
player.CharacterAdded:Connect(setupCharacter)

-- Garantir que a hotbar seja sempre customizada ao entrar no jogo
pcall(function()
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
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

local gap = 70

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
local gap = 70

local btnY = actionBtn(gap,0,"Y",Color3.fromRGB(200,200,60))
local btnX = actionBtn(0,gap,"X",Color3.fromRGB(60,120,200))
local btnB = actionBtn(gap*2,gap,"B",Color3.fromRGB(200,60,60))
local btnA = actionBtn(gap,gap*2,"A",Color3.fromRGB(60,200,120))

-- BOTÃO DE PULO CUSTOMIZADO
local jumpBtn = Instance.new("TextButton")
jumpBtn.Size = UDim2.fromOffset(96,96)
jumpBtn.BackgroundColor3 = Color3.fromRGB(20,20,20)
jumpBtn.Text = "↑"
jumpBtn.TextScaled = true
jumpBtn.Font = Enum.Font.GothamBold
jumpBtn.TextColor3 = Color3.new(1,1,1)
jumpBtn.ZIndex = 50
jumpBtn.Visible = false
jumpBtn.Parent = gui

Instance.new("UICorner", jumpBtn).CornerRadius = UDim.new(1,0)

local Camera = workspace.CurrentCamera
local function updateJumpPosition()
	jumpBtn.Position = UDim2.new(0,160,1,-170)
end
updateJumpPosition()
Camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateJumpPosition)

jumpBtn.InputBegan:Connect(function(i)
	if i.UserInputType ~= Enum.UserInputType.Touch then return end
	pressToSize(jumpBtn, UDim2.fromOffset(84,84))
	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
end)

jumpBtn.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.Touch then
		pressToSize(jumpBtn, UDim2.fromOffset(96,96))
	end
end)


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

-- Função para atualizar o inventário customizado
local function refreshInventory()
    -- Limpar os itens antigos do inventário
    for _, c in ipairs(invGui:GetChildren()) do
        if c:IsA("ImageButton") then
            c:Destroy()  -- Limpa o inventário
        end
    end

    -- Atualizar o inventário com os itens da mochila e do personagem
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local slot = Instance.new("ImageButton")
            slot.BackgroundColor3 = Color3.fromRGB(60,60,60)
            slot.ZIndex = 17
            slot.Parent = invGui
            Instance.new("UICorner", slot)

            -- Verificar se a ferramenta tem um ícone atribuído
            if tool.TextureId ~= "" then
                slot.Image = tool.TextureId  -- Atualiza o ícone do slot
            else
                -- Caso a ferramenta não tenha ícone, pode exibir um texto alternativo
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

            -- Ao clicar no item do inventário, equipar a ferramenta no personagem
            slot.MouseButton1Click:Connect(function()
                tool.Parent = character  -- Equipando o item
                closeInventory()  -- Fechar o inventário
            end)
        end
    end

    -- Também inclui itens que já estão no personagem
    for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") then
            local slot = Instance.new("ImageButton")
            slot.BackgroundColor3 = Color3.fromRGB(60,60,60)
            slot.ZIndex = 17
            slot.Parent = invGui
            Instance.new("UICorner", slot)

            -- Verificar se a ferramenta tem um ícone atribuído
            if tool.TextureId ~= "" then
                slot.Image = tool.TextureId  -- Atualiza o ícone do slot
            else
                -- Caso a ferramenta não tenha ícone, pode exibir um texto alternativo
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

            -- Ao clicar no item do inventário, equipar a ferramenta no personagem
            slot.MouseButton1Click:Connect(function()
                tool.Parent = character  -- Equipando o item
                closeInventory()  -- Fechar o inventário
            end)
        end
    end
end

---

-- AÇÕES

btnY.InputBegan:Connect(function(i)
    if i.UserInputType ~= Enum.UserInputType.Touch then return end
    pressToSize(btnY, UDim2.fromOffset(66,66))
    refreshInventory()  -- Atualiza o inventário
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

local INTERACT_DISTANCE = 12
local Camera = workspace.CurrentCamera
local holdingPrompt = nil

local function getCenterPrompt()
	local viewport = Camera.ViewportSize
	local ray = Camera:ViewportPointToRay(
		viewport.X / 2,
		viewport.Y / 2
	)

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {character}
	params.FilterType = Enum.RaycastFilterType.Blacklist

	local result = workspace:Raycast(
		ray.Origin,
		ray.Direction * INTERACT_DISTANCE,
		params
	)

	if not result then return nil end

	local hit = result.Instance
	if not hit then return nil end

	return hit:FindFirstChildOfClass("ProximityPrompt")
		or hit.Parent:FindFirstChildOfClass("ProximityPrompt")
end

-- QUANDO APERTA X
btnX.InputBegan:Connect(function(i)
	if i.UserInputType ~= Enum.UserInputType.Touch then return end
	pressToSize(btnX, UDim2.fromOffset(54,54))

	-- PRIORIDADE 1: TOOL NA MÃO
	for _, tool in ipairs(character:GetChildren()) do
		if tool:IsA("Tool") then
			tool:Activate()
			return
		end
	end

	-- PRIORIDADE 2: PROXIMITY PROMPT
	local prompt = getCenterPrompt()
	if not prompt or not prompt.Enabled then return end

	-- clique simples
	if prompt.HoldDuration == 0 then
		ProximityPromptService:TriggerPrompt(prompt)
	else
		-- interação de segurar
		holdingPrompt = prompt
		ProximityPromptService:BeginPromptHold(prompt)
	end
end)

-- QUANDO SOLTA X
btnX.InputEnded:Connect(function(i)
	if i.UserInputType ~= Enum.UserInputType.Touch then return end
	pressToSize(btnX, UDim2.fromOffset(60,60))

	if holdingPrompt then
		ProximityPromptService:EndPromptHold(holdingPrompt)
		holdingPrompt = nil
	end
end)

btnX.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.Touch then
		pressToSize(btnX, UDim2.fromOffset(60,60))
	end
end)

btnB.InputBegan:Connect(function(i)
	if i.UserInputType ~= Enum.UserInputType.Touch then return end
	pressToSize(btnB, UDim2.fromOffset(54,54))

	for _, tool in ipairs(character:GetChildren()) do
		if tool:IsA("Tool") then
			tool.Parent = workspace

			if tool:FindFirstChild("Handle") then
				tool.Handle.CFrame =
					character.HumanoidRootPart.CFrame *
					CFrame.new(0, 0, -2)
			end
			return
		end
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

    -- Verificando se há ferramentas na mochila
    for _, t in ipairs(backpack:GetChildren()) do
        if t:IsA("Tool") then
            table.insert(tools, t)
        end
    end

    -- Verificando se há ferramentas no personagem
    for _, t in ipairs(character:GetChildren()) do
        if t:IsA("Tool") then
            table.insert(tools, t)
        end
    end

    return tools
end

-- Função para atualizar a hotbar personalizada
local function updateHotbar()
    -- Limpar os slots da hotbar
    for _, slot in ipairs(hotSlots) do
        stopGlow(slot)
        slot.Tool = nil
        slot.Icon.Image = ""  -- Limpar o ícone
    end

    -- Obter todos os itens da mochila e do personagem
    local tools = getAllTools()

    -- Atualiza os slots da hotbar com os itens
    for i = 1, math.min(#tools, MAX_SLOTS) do
        local tool = tools[i]
        local slot = hotSlots[i]
        slot.Tool = tool

        -- Verificar se a ferramenta tem um ícone atribuído
        if tool.TextureId ~= "" then
            slot.Icon.Image = tool.TextureId -- Atualiza o ícone do slot
        else
            slot.Icon.Image = ""  -- Caso não tenha ícone, deixa em branco
        end

        -- Aplica o efeito de brilho (glow) na ferramenta se ela estiver equipada no personagem
        if tool.Parent == character then
            slot.Stroke.Thickness = 3
            startGlow(slot)
        end
    end
end

---

-- Input Hotbar (Equipar / Desequipar)
for _, slot in ipairs(hotSlots) do
    slot.Button.InputBegan:Connect(function(i)
        if i.UserInputType ~= Enum.UserInputType.Touch then return end
        if not slot.Tool then return end

        -- Animar o botão ao ser pressionado
        pressToSize(slot.Button, UDim2.fromOffset(54,54))

        -- Se a ferramenta estiver no personagem, remova-a e a coloque na mochila
        if slot.Tool.Parent == character then
            slot.Tool.Parent = backpack
        else
            -- Caso contrário, equipe a ferramenta no personagem
            slot.Tool.Parent = character
        end

        -- Após a ação, atualize a hotbar para refletir a mudança
        task.wait()
        updateHotbar()
    end)

    -- Ao soltar o botão, retorne ao tamanho original
    slot.Button.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch then
            pressToSize(slot.Button, UDim2.fromOffset(60,60))
        end
    end)
end


---

-- ===== EVENTOS =====

-- Atualiza a hotbar e o inventário quando um item for adicionado ou removido
backpack.ChildAdded:Connect(function(child)
    print("Item adicionado à mochila:", child.Name)
    updateHotbar()  -- Atualiza a hotbar com os itens
    refreshInventory()  -- Atualiza o inventário para refletir os itens
end)

backpack.ChildRemoved:Connect(function(child)
    print("Item removido da mochila:", child.Name)
    updateHotbar()  -- Atualiza a hotbar com os itens
    refreshInventory()  -- Atualiza o inventário para refletir os itens
end)

character.ChildAdded:Connect(function(child)
    print("Item adicionado ao personagem:", child.Name)
    updateHotbar()  -- Atualiza a hotbar com os itens
    refreshInventory()  -- Atualiza o inventário para refletir os itens
end)

character.ChildRemoved:Connect(function(child)
    print("Item removido do personagem:", child.Name)
    updateHotbar()  -- Atualiza a hotbar com os itens
    refreshInventory()  -- Atualiza o inventário para refletir os itens
end)

-- Quando o personagem for resetado ou renascido, chamamos a atualização da hotbar
player.CharacterAdded:Connect(function()
    task.wait(1)  -- Aguarda um pouco para garantir que o personagem tenha sido completamente reiniciado
    updateHotbar()  -- Atualiza a hotbar com os itens corretos
    refreshInventory()  -- Atualiza o inventário para refletir os itens corretos
end)

-- === ADAPTAÇÃO AUTOMÁTICA À TELA (D-PAD + A B X Y) ===

local Camera = workspace.CurrentCamera

local function updateControlPositions()
	local viewport = Camera.ViewportSize
	local margin = math.clamp(viewport.X * 0.04, 16, 40)

	-- D-PAD (lado esquerdo)
	dpad.Position = UDim2.new(
		0,
		margin + 30,
		1,
		- dpad.Size.Y.Offset - margin - 20
	)

	-- BOTÃO DE PULO (espelhado do D-PAD)
	jumpBtn.Position = UDim2.new(
		1,
		- jumpBtn.Size.X.Offset - margin - 30,
		1,
		- dpad.Size.Y.Offset - margin - -40
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
settingsBtn.Position = UDim2.fromOffset(20,20)
settingsBtn.Text = "⚙️"
settingsBtn.TextSize = 24
settingsBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
settingsBtn.TextColor3 = Color3.new(1,1,1)
settingsBtn.ZIndex = 200
settingsBtn.Parent = settingsGui
Instance.new("UICorner", settingsBtn)

-- Painel do menu
local menuFrame = Instance.new("Frame")
menuFrame.Size = UDim2.fromOffset(260,220)  -- Tamanho do menu
menuFrame.Position = UDim2.fromOffset(20,70)
menuFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
menuFrame.Visible = false
menuFrame.ZIndex = 201
menuFrame.Parent = settingsGui
Instance.new("UICorner", menuFrame)

-- =========================
-- SCROLL NO MENU DE CONFIGURAÇÕES
-- =========================

-- Criar o ScrollingFrame dentro do menuFrame
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.fromOffset(260, 180)  -- Reduzido para permitir o cabeçalho
scrollFrame.Position = UDim2.fromOffset(0, 0)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 10  -- Espessura da barra de rolagem
scrollFrame.ZIndex = 200
scrollFrame.Parent = menuFrame

-- Layout para os botões dentro do ScrollingFrame
local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 12)
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = scrollFrame

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

-- Função para criar botões dentro do scrollFrame
local function menuButton(text)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(220, 46)
    b.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    b.TextColor3 = Color3.new(1, 1, 1)
    b.TextScaled = true
    b.Font = Enum.Font.GothamBold
    b.Text = text
    b.AutoButtonColor = false
    b.ZIndex = 202
    b.Parent = scrollFrame  -- Botões agora são filhos de scrollFrame
    Instance.new("UICorner", b)
    return b
end


-- =========================
-- BOTÕES DO MENU (3)
-- =========================

local hotbarBtn = menuButton("Hotbar: Custom")
local option2Btn = menuButton("Opção 2 (Jogo Teleporte)")
local option3Btn = menuButton("Opção 3 (D-Pad para Analógico)")
-- Inicializa a variável para saber se o analógico está ativado ou não
local analogEnabled = false

-- Função para alternar entre os modos de controle
option3Btn.MouseButton1Click:Connect(function()
    analogEnabled = not analogEnabled
    updateControlMode()  -- Atualiza o modo de controle
end)
local jumpToggleBtn = menuButton("Controles: A B X Y")

option2Btn.BackgroundTransparency = 0.4
option3Btn.BackgroundTransparency = 0.4

local usingJumpOnly = false

local function updateControlMode()
	btnA.Visible = not usingJumpOnly
	btnB.Visible = not usingJumpOnly
	btnX.Visible = not usingJumpOnly
	btnY.Visible = not usingJumpOnly
	jumpBtn.Visible = usingJumpOnly
	dpad.Visible = not analogEnabled

    -- Se analógico estiver ativado, ocultamos o D-Pad e mostramos o joystick
    if analogEnabled then
        analogJoystick.Visible = true
    else
        analogJoystick.Visible = false
    end
end

	if usingJumpOnly then
		jumpToggleBtn.Text = "Controles: Pulo"
	else
		jumpToggleBtn.Text = "Controles: A B X Y"
	end
end

jumpToggleBtn.MouseButton1Click:Connect(function()
	usingJumpOnly = not usingJumpOnly
	updateControlMode()
end)

-- Joystick Analógico
local analogJoystick = Instance.new("Frame")
analogJoystick.Size = UDim2.fromOffset(150, 150)
analogJoystick.Position = UDim2.new(0, 100, 1, -250)  -- Posição do joystick
analogJoystick.BackgroundTransparency = 1
analogJoystick.Visible = false
analogJoystick.ZIndex = 20
analogJoystick.Parent = gui

-- Criando o centro do joystick
local analogBase = Instance.new("Frame")
analogBase.Size = UDim2.fromOffset(80, 80)
analogBase.Position = UDim2.fromOffset(35, 35)
analogBase.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
analogBase.BackgroundTransparency = 0.4
analogBase.ZIndex = 21
analogBase.Parent = analogJoystick
Instance.new("UICorner", analogBase).CornerRadius = UDim.new(1, 0)

-- Criando a alavanca do joystick
local analogStick = Instance.new("Frame")
analogStick.Size = UDim2.fromOffset(30, 30)
analogStick.Position = UDim2.fromOffset(25, 25)
analogStick.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
analogStick.ZIndex = 22
analogStick.Parent = analogBase
Instance.new("UICorner", analogStick).CornerRadius = UDim.new(0.5, 0)

local moveVector = Vector3.zero
local moveSpeed = 10

-- Detecta o toque para movimentar a alavanca
local dragging = false
local initialPosition = UDim2.new(0.5, 0, 0.5, 0)

analogBase.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
    end
end)

analogBase.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.Touch then
        -- Calcula o movimento do joystick
        local touchPos = input.Position
        local basePos = analogJoystick.AbsolutePosition
        local direction = touchPos - basePos
        direction = direction.Unit * math.min(direction.Magnitude, 40)  -- Limita o movimento a um círculo de raio 40

        analogStick.Position = UDim2.fromOffset(direction.X + 25, direction.Y + 25)
        moveVector = Vector3.new(direction.X, 0, direction.Y) * moveSpeed
    end
end)

analogBase.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
        analogStick.Position = initialPosition  -- Retorna a alavanca para o centro
        moveVector = Vector3.zero
    end
end)

-- Atualizando o movimento do personagem
RunService.RenderStepped:Connect(function()
    if analogEnabled then
        humanoid:Move(moveVector, true)
    end
end)

updateControlMode()

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
        pcall(function()
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
        end)
        hotbarBtn.Text = "Hotbar: Roblox"
    end
end

hotbarBtn.MouseButton1Click:Connect(function()
    customHotbarEnabled = not customHotbarEnabled
    updateHotbarState()
end)

-- =========================
-- ABRIR / FECHAR MENU
-- =========================

settingsBtn.MouseButton1Click:Connect(function()
    menuFrame.Visible = not menuFrame.Visible
end)

-- estado inicial
updateHotbarState()
