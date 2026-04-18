-- ================================================
-- LOCALIZADOR DE FRUTAS - Blox Fruits (2026)
-- AGORA DETECTA TOOL + MODEL + SEM LAG + MENU MINI
-- ================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local fruitData = {
	["Rocket"] = {rarity = "Comum", color = Color3.fromRGB(170, 170, 170)},
	["Spin"] = {rarity = "Comum", color = Color3.fromRGB(170, 170, 170)},
	["Blade"] = {rarity = "Comum", color = Color3.fromRGB(170, 170, 170)},
	["Spring"] = {rarity = "Comum", color = Color3.fromRGB(170, 170, 170)},
	["Bomb"] = {rarity = "Comum", color = Color3.fromRGB(170, 170, 170)},
	["Smoke"] = {rarity = "Comum", color = Color3.fromRGB(170, 170, 170)},
	["Spike"] = {rarity = "Comum", color = Color3.fromRGB(170, 170, 170)},

	["Flame"] = {rarity = "Incomum", color = Color3.fromRGB(0, 170, 255)},
	["Ice"] = {rarity = "Incomum", color = Color3.fromRGB(0, 170, 255)},
	["Sand"] = {rarity = "Incomum", color = Color3.fromRGB(0, 170, 255)},
	["Dark"] = {rarity = "Incomum", color = Color3.fromRGB(0, 170, 255)},
	["Eagle"] = {rarity = "Incomum", color = Color3.fromRGB(0, 170, 255)},
	["Diamond"] = {rarity = "Incomum", color = Color3.fromRGB(0, 170, 255)},

	["Light"] = {rarity = "Raro", color = Color3.fromRGB(0, 255, 100)},
	["Rubber"] = {rarity = "Raro", color = Color3.fromRGB(0, 255, 100)},
	["Ghost"] = {rarity = "Raro", color = Color3.fromRGB(0, 255, 100)},
	["Magma"] = {rarity = "Raro", color = Color3.fromRGB(0, 255, 100)},

	["Quake"] = {rarity = "Lendário", color = Color3.fromRGB(180, 0, 255)},
	["Buddha"] = {rarity = "Lendário", color = Color3.fromRGB(180, 0, 255)},
	["Love"] = {rarity = "Lendário", color = Color3.fromRGB(180, 0, 255)},
	["Creation"] = {rarity = "Lendário", color = Color3.fromRGB(180, 0, 255)},
	["Spider"] = {rarity = "Lendário", color = Color3.fromRGB(180, 0, 255)},
	["Sound"] = {rarity = "Lendário", color = Color3.fromRGB(180, 0, 255)},
	["Phoenix"] = {rarity = "Lendário", color = Color3.fromRGB(180, 0, 255)},
	["Portal"] = {rarity = "Lendário", color = Color3.fromRGB(180, 0, 255)},
	["Lightning"] = {rarity = "Lendário", color = Color3.fromRGB(180, 0, 255)},
	["Pain"] = {rarity = "Lendário", color = Color3.fromRGB(180, 0, 255)},
	["Blizzard"] = {rarity = "Lendário", color = Color3.fromRGB(180, 0, 255)},

	["Gravity"] = {rarity = "Mítico", color = Color3.fromRGB(255, 180, 0)},
	["Mammoth"] = {rarity = "Mítico", color = Color3.fromRGB(255, 180, 0)},
	["T-Rex"] = {rarity = "Mítico", color = Color3.fromRGB(255, 180, 0)},
	["Dough"] = {rarity = "Mítico", color = Color3.fromRGB(255, 180, 0)},
	["Shadow"] = {rarity = "Mítico", color = Color3.fromRGB(255, 180, 0)},
	["Venom"] = {rarity = "Mítico", color = Color3.fromRGB(255, 180, 0)},
	["Gas"] = {rarity = "Mítico", color = Color3.fromRGB(255, 180, 0)},
	["Spirit"] = {rarity = "Mítico", color = Color3.fromRGB(255, 180, 0)},
	["Tiger"] = {rarity = "Mítico", color = Color3.fromRGB(255, 180, 0)},
	["Yeti"] = {rarity = "Mítico", color = Color3.fromRGB(255, 180, 0)},
	["Kitsune"] = {rarity = "Mítico", color = Color3.fromRGB(255, 180, 0)},
	["Control"] = {rarity = "Mítico", color = Color3.fromRGB(255, 180, 0)},
	["Dragon"] = {rarity = "Mítico", color = Color3.fromRGB(255, 180, 0)},
}

local isEnabled = true
local permanentlyDisabled = false
local mainGui = nil
local promptGui = nil
local updateConnection = nil
local seenFruits = {}
local lastUpdate = 0

local function getFruitPosition(fruit)
	if not fruit then return nil end
	local handle = fruit:FindFirstChild("Handle")
	if handle and handle:IsA("BasePart") then return handle.Position end
	local primary = fruit.PrimaryPart
	if primary then return primary.Position end
	local anyPart = fruit:FindFirstChildWhichIsA("BasePart")
	if anyPart then return anyPart.Position end
	return fruit:GetPivot().Position
end

local function triggerRareNotification(fruitName, rarity)
	if not mainGui or not mainGui.ScreenGui then return end
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://12221967"
	sound.Volume = 0.8
	sound.Parent = mainGui.ScreenGui
	sound:Play()
	task.delay(3, function() if sound then sound:Destroy() end end)
	print("🚨 NOVA " .. rarity .. ": " .. fruitName .. "!")
end

local function createMainMenu()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "FruitLocatorGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

	local frame = Instance.new("Frame")
	frame.Name = "MainFrame"
	frame.Size = UDim2.new(0.22, 0, 0, 110)
	frame.Position = UDim2.new(0.5, 0, 0, 10)
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	frame.BackgroundTransparency = 0.35
	frame.BorderSizePixel = 0
	frame.Visible = true
	frame.Parent = screenGui

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 255, 255)
	stroke.Thickness = 2
	stroke.Transparency = 0.3
	stroke.Parent = frame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 26)
	title.BackgroundTransparency = 1
	title.Text = "🍎 0 FRUTAS 🍎"
	title.TextColor3 = Color3.fromRGB(0, 255, 255)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = frame

	local titleStroke = Instance.new("UIStroke")
	titleStroke.Color = Color3.fromRGB(0, 255, 255)
	titleStroke.Thickness = 0.8
	titleStroke.Parent = title

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Scroll"
	scroll.Size = UDim2.new(1, -10, 1, -32)
	scroll.Position = UDim2.new(0, 5, 0, 28)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 3
	scroll.ScrollBarImageColor3 = Color3.fromRGB(0, 255, 255)
	scroll.Parent = frame

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 3)
	listLayout.Parent = scroll

	mainGui = {ScreenGui = screenGui, Frame = frame, Scroll = scroll, Title = title}
	return mainGui
end

local function updateFruitList()
	if not mainGui or not isEnabled then return end
	if tick() - lastUpdate < 0.25 then return end
	lastUpdate = tick()

	local character = LocalPlayer.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then 
		mainGui.Frame.Visible = false
		return 
	end

	local rootPos = character.HumanoidRootPart.Position
	local foundFruits = {}
	local seenObjects = {}

	-- 1. Frutas no workspace (dropadas ou no mapa)
	for _, obj in ipairs(workspace:GetChildren()) do
		if (obj:IsA("Model") or obj:IsA("Tool")) and fruitData[obj.Name] and not seenObjects[obj] then
			seenObjects[obj] = true
			if obj:FindFirstChild("Handle") then
				local fruitPos = getFruitPosition(obj)
				if fruitPos then
					local distance = (rootPos - fruitPos).Magnitude
					table.insert(foundFruits, {
						name = obj.Name,
						rarity = fruitData[obj.Name].rarity,
						color = fruitData[obj.Name].color,
						distance = distance,
						object = obj
					})
				end
			end
		end
	end

	-- 2. Frutas spawnadas no DevilFruitSpawner
	local spawner = workspace:FindFirstChild("DevilFruitSpawner")
	if spawner then
		local spawnedFolder = spawner:FindFirstChild("SpawnedDFS") or spawner
		for _, obj in ipairs(spawnedFolder:GetChildren()) do
			if (obj:IsA("Model") or obj:IsA("Tool")) and fruitData[obj.Name] and not seenObjects[obj] then
				seenObjects[obj] = true
				if obj:FindFirstChild("Handle") then
					local fruitPos = getFruitPosition(obj)
					if fruitPos then
						local distance = (rootPos - fruitPos).Magnitude
						table.insert(foundFruits, {
							name = obj.Name,
							rarity = fruitData[obj.Name].rarity,
							color = fruitData[obj.Name].color,
							distance = distance,
							object = obj
						})
					end
				end
			end
		end
	end

	table.sort(foundFruits, function(a, b) return a.distance < b.distance end)

	mainGui.Frame.Visible = true
	mainGui.Title.Text = string.format("🍎 %d FRUTAS 🍎", #foundFruits)

	-- Limpa lista
	for _, child in ipairs(mainGui.Scroll:GetChildren()) do
		if child:IsA("Frame") and child.Name == "FruitRow" then child:Destroy() end
	end

	local newSeen = {}
	for _, fruit in ipairs(foundFruits) do
		local fruitObject = fruit.object
		newSeen[fruitObject] = true

		if (fruit.rarity == "Lendário" or fruit.rarity == "Mítico") and not seenFruits[fruitObject] then
			triggerRareNotification(fruit.name, fruit.rarity)
		end

		local row = Instance.new("Frame")
		row.Name = "FruitRow"
		row.Size = UDim2.new(1, 0, 0, 22)
		row.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
		row.BackgroundTransparency = 0.75
		row.Parent = mainGui.Scroll

		local rowStroke = Instance.new("UIStroke")
		rowStroke.Color = Color3.fromRGB(0, 255, 255)
		rowStroke.Thickness = 1
		rowStroke.Transparency = 0.6
		rowStroke.Parent = row

		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 6)
		rowCorner.Parent = row

		local rowLayout = Instance.new("UIListLayout")
		rowLayout.FillDirection = Enum.FillDirection.Horizontal
		rowLayout.Padding = UDim.new(0, 5)
		rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		rowLayout.Parent = row

		local infoLabel = Instance.new("TextLabel")
		infoLabel.Size = UDim2.new(0.68, 0, 1, 0)
		infoLabel.BackgroundTransparency = 1
		infoLabel.Text = string.format("%s • %.0fm", fruit.name, fruit.distance)
		infoLabel.TextColor3 = fruit.color
		infoLabel.TextXAlignment = Enum.TextXAlignment.Left
		infoLabel.TextScaled = true
		infoLabel.Font = Enum.Font.GothamSemibold
		infoLabel.Parent = row

		local infoPadding = Instance.new("UIPadding")
		infoPadding.PaddingLeft = UDim.new(0, 6)
		infoPadding.Parent = infoLabel

		local tpBtn = Instance.new("TextButton")
		tpBtn.Size = UDim2.new(0.28, 0, 1, 0)
		tpBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
		tpBtn.Text = "TP"
		tpBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
		tpBtn.TextScaled = true
		tpBtn.Font = Enum.Font.GothamBold
		tpBtn.Parent = row

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 6)
		btnCorner.Parent = tpBtn

		tpBtn.MouseButton1Click:Connect(function()
			local char = LocalPlayer.Character
			if char and char:FindFirstChild("HumanoidRootPart") and fruitObject and fruitObject.Parent then
				local fruitPos = getFruitPosition(fruitObject)
				if fruitPos then
					char.HumanoidRootPart.CFrame = CFrame.new(fruitPos.X, fruitPos.Y + 4, fruitPos.Z)
				end
			end
		end)
	end

	seenFruits = newSeen
	mainGui.Scroll.CanvasSize = UDim2.new(0, 0, 0, mainGui.Scroll.UIListLayout.AbsoluteContentSize.Y + 8)
end

local function startUpdateLoop()
	if updateConnection then return end
	updateConnection = RunService.Heartbeat:Connect(updateFruitList)
end

local function onCharacterDied()
	isEnabled = false
	if mainGui and mainGui.Frame then mainGui.Frame.Visible = false end
end

local function onCharacterAdded(character)
	task.wait(1)
	if permanentlyDisabled then return end
	if isEnabled then startUpdateLoop() return end
	createReActivationPrompt()
end

local function createReActivationPrompt()
	if promptGui then return end
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "FruitReactivatePrompt"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = LocalPlayer.PlayerGui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 340, 0, 160)
	frame.Position = UDim2.new(0.5, -170, 0.4, 0)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	frame.BackgroundTransparency = 0.2
	frame.Parent = screenGui

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 255, 255)
	stroke.Thickness = 4
	stroke.Parent = frame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 15)
	corner.Parent = frame

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 50)
	title.BackgroundTransparency = 1
	title.Text = "🔄 Script pausado"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = frame

	local question = Instance.new("TextLabel")
	question.Size = UDim2.new(1, 0, 0, 40)
	question.Position = UDim2.new(0, 0, 0, 50)
	question.BackgroundTransparency = 1
	question.Text = "Deseja ativar o Localizador novamente?"
	question.TextColor3 = Color3.fromRGB(200, 200, 200)
	question.TextScaled = true
	question.Font = Enum.Font.Gotham
	question.Parent = frame

	local btnYes = Instance.new("TextButton")
	btnYes.Size = UDim2.new(0.45, 0, 0, 45)
	btnYes.Position = UDim2.new(0.05, 0, 0.68, 0)
	btnYes.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
	btnYes.Text = "SIM"
	btnYes.TextColor3 = Color3.fromRGB(0, 0, 0)
	btnYes.TextScaled = true
	btnYes.Font = Enum.Font.GothamBold
	btnYes.Parent = frame

	local yesCorner = Instance.new("UICorner")
	yesCorner.CornerRadius = UDim.new(0, 10)
	yesCorner.Parent = btnYes

	local btnNo = Instance.new("TextButton")
	btnNo.Size = UDim2.new(0.45, 0, 0, 45)
	btnNo.Position = UDim2.new(0.5, 0, 0.68, 0)
	btnNo.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
	btnNo.Text = "NÃO (parar permanente)"
	btnNo.TextColor3 = Color3.fromRGB(255, 255, 255)
	btnNo.TextScaled = true
	btnNo.Font = Enum.Font.GothamBold
	btnNo.Parent = frame

	local noCorner = Instance.new("UICorner")
	noCorner.CornerRadius = UDim.new(0, 10)
	noCorner.Parent = btnNo

	btnYes.MouseButton1Click:Connect(function()
		isEnabled = true
		permanentlyDisabled = false
		screenGui:Destroy()
		promptGui = nil
	end)

	btnNo.MouseButton1Click:Connect(function()
		permanentlyDisabled = true
		isEnabled = false
		screenGui:Destroy()
		promptGui = nil
	end)

	promptGui = screenGui
end

local function init()
	mainGui = createMainMenu()
	startUpdateLoop()

	if LocalPlayer.Character then
		local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
		if humanoid then humanoid.Died:Connect(onCharacterDied) end
	end

	LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
	LocalPlayer.CharacterRemoving:Connect(function() isEnabled = false end)

	print("✅ Localizador ATUALIZADO - agora pega Tool + Model!")
end

init()
