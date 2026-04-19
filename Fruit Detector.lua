local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local fruitData = {
	["Rocket"] = {rarity = "Common",    color = Color3.fromRGB(170, 170, 170), icon = "⭐"},
	["Spin"]   = {rarity = "Common",    color = Color3.fromRGB(170, 170, 170), icon = "⭐"},
	["Blade"]  = {rarity = "Common",    color = Color3.fromRGB(170, 170, 170), icon = "⭐"},
	["Spring"] = {rarity = "Common",    color = Color3.fromRGB(170, 170, 170), icon = "⭐"},
	["Bomb"]   = {rarity = "Common",    color = Color3.fromRGB(170, 170, 170), icon = "⭐"},
	["Smoke"]  = {rarity = "Common",    color = Color3.fromRGB(170, 170, 170), icon = "⭐"},
	["Spike"]  = {rarity = "Common",    color = Color3.fromRGB(170, 170, 170), icon = "⭐"},

	["Flame"]    = {rarity = "Uncommon", color = Color3.fromRGB(0, 170, 255), icon = "🔥"},
	["Ice"]      = {rarity = "Uncommon", color = Color3.fromRGB(0, 170, 255), icon = "🔥"},
	["Sand"]     = {rarity = "Uncommon", color = Color3.fromRGB(0, 170, 255), icon = "🔥"},
	["Dark"]     = {rarity = "Uncommon", color = Color3.fromRGB(0, 170, 255), icon = "🔥"},
	["Eagle"]    = {rarity = "Uncommon", color = Color3.fromRGB(0, 170, 255), icon = "🔥"},
	["Diamond"]  = {rarity = "Uncommon", color = Color3.fromRGB(0, 170, 255), icon = "🔥"},

	["Light"]  = {rarity = "Rare", color = Color3.fromRGB(0, 255, 100), icon = "💎"},
	["Rubber"] = {rarity = "Rare", color = Color3.fromRGB(0, 255, 100), icon = "💎"},
	["Ghost"]  = {rarity = "Rare", color = Color3.fromRGB(0, 255, 100), icon = "💎"},
	["Magma"]  = {rarity = "Rare", color = Color3.fromRGB(0, 255, 100), icon = "💎"},

	["Quake"]     = {rarity = "Legendary", color = Color3.fromRGB(180, 0, 255), icon = "👑"},
	["Buddha"]    = {rarity = "Legendary", color = Color3.fromRGB(180, 0, 255), icon = "👑"},
	["Love"]      = {rarity = "Legendary", color = Color3.fromRGB(180, 0, 255), icon = "👑"},
	["Creation"]  = {rarity = "Legendary", color = Color3.fromRGB(180, 0, 255), icon = "👑"},
	["Spider"]    = {rarity = "Legendary", color = Color3.fromRGB(180, 0, 255), icon = "👑"},
	["Sound"]     = {rarity = "Legendary", color = Color3.fromRGB(180, 0, 255), icon = "👑"},
	["Phoenix"]   = {rarity = "Legendary", color = Color3.fromRGB(180, 0, 255), icon = "👑"},
	["Portal"]    = {rarity = "Legendary", color = Color3.fromRGB(180, 0, 255), icon = "👑"},
	["Lightning"] = {rarity = "Legendary", color = Color3.fromRGB(180, 0, 255), icon = "👑"},
	["Pain"]      = {rarity = "Legendary", color = Color3.fromRGB(180, 0, 255), icon = "👑"},
	["Blizzard"]  = {rarity = "Legendary", color = Color3.fromRGB(180, 0, 255), icon = "👑"},

	["Gravity"] = {rarity = "Mythic", color = Color3.fromRGB(255, 180, 0), icon = "🌟"},
	["Mammoth"] = {rarity = "Mythic", color = Color3.fromRGB(255, 180, 0), icon = "🌟"},
	["T-Rex"]   = {rarity = "Mythic", color = Color3.fromRGB(255, 180, 0), icon = "🌟"},
	["Dough"]   = {rarity = "Mythic", color = Color3.fromRGB(255, 180, 0), icon = "🌟"},
	["Shadow"]  = {rarity = "Mythic", color = Color3.fromRGB(255, 180, 0), icon = "🌟"},
	["Venom"]   = {rarity = "Mythic", color = Color3.fromRGB(255, 180, 0), icon = "🌟"},
	["Gas"]     = {rarity = "Mythic", color = Color3.fromRGB(255, 180, 0), icon = "🌟"},
	["Spirit"]  = {rarity = "Mythic", color = Color3.fromRGB(255, 180, 0), icon = "🌟"},
	["Tiger"]   = {rarity = "Mythic", color = Color3.fromRGB(255, 180, 0), icon = "🌟"},
	["Yeti"]    = {rarity = "Mythic", color = Color3.fromRGB(255, 180, 0), icon = "🌟"},
	["Kitsune"] = {rarity = "Mythic", color = Color3.fromRGB(255, 180, 0), icon = "🌟"},
	["Control"] = {rarity = "Mythic", color = Color3.fromRGB(255, 180, 0), icon = "🌟"},
	["Dragon"]  = {rarity = "Mythic", color = Color3.fromRGB(255, 180, 0), icon = "🌟"},
}

local FRUIT_LIFETIME = 480

local isEnabled = true
local permanentlyDisabled = false
local mainGui = nil
local promptGui = nil
local miniMap = nil
local updateConnection = nil

local activeFruits = {}
local seenFruits = {}
local settings = {
	enabled = true,
	menuPosition = UDim2.new(0.5, 0, 0, 10)
}

local menuVisible = false
local menuTweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

if getgenv().FruitLocator_Settings then
	settings = getgenv().FruitLocator_Settings
	isEnabled = settings.enabled
else
	getgenv().FruitLocator_Settings = settings
end

local function getFruitPosition(fruit)
	if not fruit then return nil end
	local handle = fruit:FindFirstChild("Handle")
	if handle and handle:IsA("BasePart") then return handle.Position end
	local primary = fruit.PrimaryPart
	if primary then return primary.Position end
	local any = fruit:FindFirstChildWhichIsA("BasePart")
	if any then return any.Position end
	return fruit:GetPivot().Position
end

local function sendPremiumNotification(fruitName, rarity, distance)
	local color = rarity == "Mythic" and "🌟" or rarity == "Legendary" and "👑" or "🍎"
	StarterGui:SetCore("SendNotification", {
		Title = "🍎 FRUIT DETECTED",
		Text = string.format("[%s] %s %s • %.0fm", color, rarity:upper(), fruitName, distance),
		Duration = 10,
	})
end

local function triggerRareNotification(fruitName, rarity, distance)
	if rarity ~= "Legendary" and rarity ~= "Mythic" then return end
	
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://137071444068298"
	sound.Volume = 0.9
	sound.Parent = game:GetService("SoundService")
	sound:Play()
	task.delay(3, function() sound:Destroy() end)
	
	sendPremiumNotification(fruitName, rarity, distance)
end

local function createHighlight(fruit, color)
	if fruit:FindFirstChild("FruitHighlight") then return end
	local hl = Instance.new("Highlight")
	hl.Name = "FruitHighlight"
	hl.FillColor = color
	hl.OutlineColor = Color3.fromRGB(255,255,255)
	hl.FillTransparency = 0.7
	hl.OutlineTransparency = 0.3
	hl.Parent = fruit
	activeFruits[fruit].highlight = hl
end

local function createMainMenu()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "FruitLocatorPainel"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 215, 0, 85)
	mainFrame.Position = settings.menuPosition
	mainFrame.AnchorPoint = Vector2.new(0.5, 0)
	mainFrame.BackgroundColor3 = Color3.fromRGB(9, 9, 13)
	mainFrame.BackgroundTransparency = 0.32
	mainFrame.BorderSizePixel = 0
	mainFrame.Visible = false
	mainFrame.Parent = screenGui

	local outerGlow = Instance.new("UIStroke")
	outerGlow.Color = Color3.fromRGB(110, 190, 255)
	outerGlow.Thickness = 3.8
	outerGlow.Transparency = 0.35
	outerGlow.Parent = mainFrame

	local innerGlow = Instance.new("UIStroke")
	innerGlow.Color = Color3.fromRGB(170, 120, 255)
	innerGlow.Thickness = 1.1
	innerGlow.Transparency = 0.7
	innerGlow.Parent = mainFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = mainFrame

	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 34)
	header.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
	header.BackgroundTransparency = 0.3
	header.Parent = mainFrame

	local headerGradient = Instance.new("UIGradient")
	headerGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(110, 190, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(170, 120, 255))
	}
	headerGradient.Rotation = 90
	headerGradient.Parent = header

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 14)
	headerCorner.Parent = header

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -68, 1, 0)
	title.Position = UDim2.new(0, 14, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "🍎 FRUIT LOCATOR"
	title.TextColor3 = Color3.fromRGB(235, 235, 255)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBlack
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	local countLabel = Instance.new("TextLabel")
	countLabel.Name = "Count"
	countLabel.Size = UDim2.new(0, 42, 1, 0)
	countLabel.Position = UDim2.new(1, -54, 0, 0)
	countLabel.BackgroundTransparency = 1
	countLabel.Text = "0"
	countLabel.TextColor3 = Color3.fromRGB(255, 215, 80)
	countLabel.TextScaled = true
	countLabel.Font = Enum.Font.GothamBlack
	countLabel.Parent = header

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Scroll"
	scroll.Size = UDim2.new(1, -12, 1, -40)
	scroll.Position = UDim2.new(0, 6, 0, 36)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 3
	scroll.ScrollBarImageColor3 = Color3.fromRGB(120, 190, 255)
	scroll.Parent = mainFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 4)
	listLayout.Parent = scroll

	local dragging = false
	header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			local mouse = LocalPlayer:GetMouse()
			local offset = Vector2.new(mainFrame.Position.X.Offset - mouse.X, mainFrame.Position.Y.Offset - mouse.Y)
			local conn
			conn = RunService.RenderStepped:Connect(function()
				if dragging then
					mainFrame.Position = UDim2.new(0, mouse.X + offset.X, 0, mouse.Y + offset.Y)
				else
					conn:Disconnect()
				end
			end)
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					settings.menuPosition = mainFrame.Position
					getgenv().FruitLocator_Settings = settings
				end
			end)
		end
	end)

	mainGui = {
		ScreenGui = screenGui,
		Frame = mainFrame,
		Title = title,
		Count = countLabel,
		Scroll = scroll
	}
	return mainGui
end

local function createMiniMap()
	local frame = Instance.new("Frame")
	frame.Name = "MiniMap"
	frame.Size = UDim2.new(0, 85, 0, 85)
	frame.Position = UDim2.new(0, 15, 0, 25)
	frame.BackgroundColor3 = Color3.fromRGB(6, 8, 12)
	frame.BackgroundTransparency = 0.35
	frame.Parent = mainGui.ScreenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(100, 180, 255)
	stroke.Thickness = 2.5
	stroke.Parent = frame

	local inner = Instance.new("Frame")
	inner.Size = UDim2.new(1, -12, 1, -12)
	inner.Position = UDim2.new(0.5, 0, 0.5, 0)
	inner.AnchorPoint = Vector2.new(0.5, 0.5)
	inner.BackgroundTransparency = 1
	inner.Parent = frame

	local innerCorner = Instance.new("UICorner")
	innerCorner.CornerRadius = UDim.new(1, 0)
	innerCorner.Parent = inner

	for i = 1, 3 do
		local ring = Instance.new("Frame")
		ring.BackgroundTransparency = 1
		ring.Size = UDim2.new(1 - (i * 0.24), 0, 1 - (i * 0.24), 0)
		ring.Position = UDim2.new(0.5, 0, 0.5, 0)
		ring.AnchorPoint = Vector2.new(0.5, 0.5)
		ring.Parent = frame

		local ringCorner = Instance.new("UICorner")
		ringCorner.CornerRadius = UDim.new(1, 0)
		ringCorner.Parent = ring

		local ringStroke = Instance.new("UIStroke")
		ringStroke.Color = Color3.fromRGB(80, 160, 255)
		ringStroke.Thickness = 1.1
		ringStroke.Transparency = 0.65
		ringStroke.Parent = ring
	end

	local playerArrow = Instance.new("TextLabel")
	playerArrow.Name = "PlayerArrow"
	playerArrow.Size = UDim2.new(0, 24, 0, 24)
	playerArrow.Position = UDim2.new(0.5, -12, 0.5, -12)
	playerArrow.BackgroundTransparency = 1
	playerArrow.Text = "▲"
	playerArrow.TextColor3 = Color3.fromRGB(0, 255, 120)
	playerArrow.TextScaled = true
	playerArrow.Font = Enum.Font.GothamBold
	playerArrow.ZIndex = 10
	playerArrow.Parent = frame

	miniMap = {Frame = frame, Dots = {}}
end

local function updateMiniMap(rootPos, foundFruits)
	if not miniMap then return end
	for _, dot in pairs(miniMap.Dots) do 
		if dot and dot.Parent then dot:Destroy() end 
	end
	miniMap.Dots = {}

	local scale = 36

	local character = LocalPlayer.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then 
		return 
	end

	local rootCFrame = character.HumanoidRootPart.CFrame
	local rightVec = rootCFrame.RightVector
	local forwardVec = rootCFrame.LookVector

	for _, fruit in ipairs(foundFruits) do
		local fruitPos = getFruitPosition(fruit.model)
		if fruitPos then
			local rel = fruitPos - rootPos
			local dist = rel.Magnitude
			if dist > 1 then
				local localX = rel:Dot(rightVec)
				local localForward = rel:Dot(forwardVec)

				local factor = math.min(dist, 400) / 400 * scale
				local mapX = (localX / dist) * factor
				local mapZ = - (localForward / dist) * factor

				local dot = Instance.new("Frame")
				dot.Size = UDim2.new(0, 6, 0, 6)
				dot.Position = UDim2.new(0.5, mapX, 0.5, mapZ)
				dot.BackgroundColor3 = fruit.color
				dot.BorderSizePixel = 0
				dot.Parent = miniMap.Frame

				local dotCorner = Instance.new("UICorner")
				dotCorner.CornerRadius = UDim.new(1,0)
				dotCorner.Parent = dot

				table.insert(miniMap.Dots, dot)
			end
		end
	end
end

local function showMenu()
	if menuVisible then return end
	menuVisible = true
	local targetPosition = settings.menuPosition
	mainGui.Frame.Position = UDim2.new(targetPosition.X.Scale, targetPosition.X.Offset, targetPosition.Y.Scale, targetPosition.Y.Offset - 150)
	mainGui.Frame.Visible = true
	local tween = TweenService:Create(mainGui.Frame, menuTweenInfo, {Position = targetPosition})
	tween:Play()
end

local function hideMenu()
	if not menuVisible then return end
	menuVisible = false
	local targetPosition = settings.menuPosition
	local offscreenPos = UDim2.new(targetPosition.X.Scale, targetPosition.X.Offset, targetPosition.Y.Scale, targetPosition.Y.Offset - 150)
	local tween = TweenService:Create(mainGui.Frame, menuTweenInfo, {Position = offscreenPos})
	tween:Play()
	tween.Completed:Connect(function(playbackState)
		if playbackState == Enum.PlaybackState.Completed and not menuVisible then
			mainGui.Frame.Visible = false
		end
	end)
end

local function createFruitRow(fruit)
	local row = Instance.new("Frame")
	row.Name = "FruitRow"
	row.Size = UDim2.new(1, 0, 0, 32)
	row.BackgroundColor3 = fruit.color
	row.BackgroundTransparency = 0.90
	row.Parent = mainGui.Scroll

	local rowStroke = Instance.new("UIStroke")
	rowStroke.Color = fruit.color
	rowStroke.Thickness = 1.4
	rowStroke.Transparency = 0.5
	rowStroke.Parent = row

	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 10)
	rowCorner.Parent = row

	local content = Instance.new("Frame")
	content.Size = UDim2.new(1, -12, 1, -6)
	content.Position = UDim2.new(0, 6, 0, 3)
	content.BackgroundTransparency = 1
	content.Parent = row

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 8)
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Parent = content

	local iconFrame = Instance.new("Frame")
	iconFrame.Size = UDim2.new(0, 32, 0, 32)
	iconFrame.BackgroundTransparency = 1
	iconFrame.Parent = content

	local vLayout = Instance.new("UIListLayout")
	vLayout.FillDirection = Enum.FillDirection.Vertical
	vLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	vLayout.Padding = UDim.new(0, 1)
	vLayout.Parent = iconFrame

	local badge = Instance.new("TextLabel")
	badge.Size = UDim2.new(1, 0, 0, 13)
	badge.BackgroundColor3 = fruit.color
	badge.BackgroundTransparency = 0.25
	badge.Text = fruit.rarity:upper()
	badge.TextColor3 = Color3.new(1,1,1)
	badge.TextScaled = true
	badge.Font = Enum.Font.GothamBold
	badge.Parent = iconFrame
	local badgeCorner = Instance.new("UICorner")
	badgeCorner.CornerRadius = UDim.new(0, 3)
	badgeCorner.Parent = badge

	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(1, 0, 0, 18)
	icon.BackgroundTransparency = 1
	icon.Text = fruit.icon
	icon.TextScaled = true
	icon.Font = Enum.Font.GothamBlack
	icon.TextColor3 = fruit.color
	icon.Parent = iconFrame

	local info = Instance.new("TextLabel")
	info.Size = UDim2.new(0.52, 0, 1, 0)
	info.BackgroundTransparency = 1
	info.Text = string.format("%s\n<font color='#e0e0e8' size='11'>%.0fm • %ds</font>", 
		fruit.name, fruit.distance, fruit.timeLeft)
	info.RichText = true
	info.TextColor3 = Color3.fromRGB(245,245,250)
	info.TextXAlignment = Enum.TextXAlignment.Left
	info.TextScaled = true
	info.Font = Enum.Font.GothamSemibold
	info.Parent = content

	local bringBtn = Instance.new("TextButton")
	bringBtn.Size = UDim2.new(0.26, 0, 0.78, 0)
	bringBtn.BackgroundColor3 = Color3.fromRGB(255, 175, 55)
	bringBtn.Text = "BRING"
	bringBtn.TextColor3 = Color3.fromRGB(0,0,0)
	bringBtn.TextScaled = true
	bringBtn.Font = Enum.Font.GothamBold
	bringBtn.Parent = content

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = bringBtn

	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = Color3.fromRGB(255, 235, 120)
	btnStroke.Thickness = 1.6
	btnStroke.Parent = bringBtn

	bringBtn.MouseEnter:Connect(function()
		TweenService:Create(bringBtn, TweenInfo.new(0.12), {Size = UDim2.new(0.28,0,0.82,0)}):Play()
	end)
	bringBtn.MouseLeave:Connect(function()
		TweenService:Create(bringBtn, TweenInfo.new(0.12), {Size = UDim2.new(0.26,0,0.78,0)}):Play()
	end)

	bringBtn.MouseButton1Click:Connect(function()
		local char = LocalPlayer.Character
		if char and char:FindFirstChild("HumanoidRootPart") and fruit.model and fruit.model.Parent then
			local target = char.HumanoidRootPart.CFrame * CFrame.new(0, 5, 0)
			local handle = fruit.model:FindFirstChild("Handle") or fruit.model:FindFirstChildWhichIsA("BasePart")
			if handle then handle.CFrame = target end
		end
	end)

	local progressContainer = Instance.new("Frame")
	progressContainer.Size = UDim2.new(1, 0, 0, 3)
	progressContainer.Position = UDim2.new(0, 0, 1, -4)
	progressContainer.BackgroundTransparency = 1
	progressContainer.Parent = row

	local t = fruit.timeLeft / FRUIT_LIFETIME
	local progress = Instance.new("Frame")
	progress.Size = UDim2.new(t, 0, 1, 0)
	progress.BackgroundColor3 = Color3.fromRGB(255 * (1 - t), 255 * t, 0)
	progress.Parent = progressContainer
	local progCorner = Instance.new("UICorner")
	progCorner.CornerRadius = UDim.new(1,0)
	progCorner.Parent = progress

	return row
end

local function updateFruitList()
	if not mainGui or not isEnabled then return end

	local character = LocalPlayer.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then 
		if menuVisible then hideMenu() end
		return 
	end

	local rootPos = character.HumanoidRootPart.Position
	local foundFruits = {}

	for fruit, data in pairs(activeFruits) do
		if fruit and fruit.Parent then
			local fruitPos = getFruitPosition(fruit)
			if fruitPos then
				local distance = (rootPos - fruitPos).Magnitude
				local timeLeft = math.max(0, FRUIT_LIFETIME - (os.time() - data.spawnTime))

				table.insert(foundFruits, {
					name = fruit.Name,
					rarity = fruitData[data.baseName].rarity,
					color = fruitData[data.baseName].color,
					icon = fruitData[data.baseName].icon,
					distance = distance,
					timeLeft = timeLeft,
					model = fruit
				})
			end
		else
			if data.highlight then data.highlight:Destroy() end
			activeFruits[fruit] = nil
		end
	end

	table.sort(foundFruits, function(a, b) return a.distance < b.distance end)

	mainGui.Count.Text = tostring(#foundFruits)

	local shouldShow = #foundFruits > 0

	if shouldShow then
		for _, child in ipairs(mainGui.Scroll:GetChildren()) do
			if child:IsA("Frame") and child.Name == "FruitRow" then child:Destroy() end
		end

		local newSeen = {}
		for _, fruit in ipairs(foundFruits) do
			local fruitModel = fruit.model
			newSeen[fruitModel] = true

			if (fruit.rarity == "Legendary" or fruit.rarity == "Mythic") and not seenFruits[fruitModel] then
				triggerRareNotification(fruit.name, fruit.rarity, fruit.distance)
			end

			local row = createFruitRow(fruit)
		end

		seenFruits = newSeen
		mainGui.Scroll.CanvasSize = UDim2.new(0, 0, 0, mainGui.Scroll.UIListLayout.AbsoluteContentSize.Y + 8)
	else
		for _, child in ipairs(mainGui.Scroll:GetChildren()) do
			if child:IsA("Frame") and child.Name == "FruitRow" then child:Destroy() end
		end
	end

	if shouldShow and not menuVisible then
		showMenu()
	elseif not shouldShow and menuVisible then
		hideMenu()
	end

	updateMiniMap(rootPos, foundFruits)
end

local function startUpdateLoop()
	if updateConnection then return end
	updateConnection = task.spawn(function()
		while true do
			if isEnabled and mainGui then
				updateFruitList()
			end
			task.wait(0.4)
		end
	end)
end

local function onDescendantAdded(obj)
	if (obj:IsA("Tool") or obj:IsA("Model")) and not activeFruits[obj] then
		local baseName = obj.Name:match("^(.+) Fruit$")
		if baseName and fruitData[baseName] then
			activeFruits[obj] = {
				baseName = baseName,
				spawnTime = os.time()
			}
			createHighlight(obj, fruitData[baseName].color)
		end
	end
end

local function onDescendantRemoving(obj)
	if activeFruits[obj] then
		if activeFruits[obj].highlight then activeFruits[obj].highlight:Destroy() end
		activeFruits[obj] = nil
	end
end

local function scanInitialFruits()
	for _, obj in ipairs(workspace:GetDescendants()) do
		onDescendantAdded(obj)
	end
end

local function onCharacterDied()
	isEnabled = false
	if menuVisible then hideMenu() end
	if miniMap and miniMap.Frame then
		miniMap.Frame.Visible = false
	end
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
	frame.BackgroundColor3 = Color3.fromRGB(10,10,12)
	frame.BackgroundTransparency = 0.2
	frame.Parent = screenGui

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(180,190,200)
	stroke.Thickness = 4
	stroke.Parent = frame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 15)
	corner.Parent = frame

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 50)
	title.BackgroundTransparency = 1
	title.Text = "🔄 Script Paused"
	title.TextColor3 = Color3.fromRGB(255,255,255)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBlack
	title.Parent = frame

	local question = Instance.new("TextLabel")
	question.Size = UDim2.new(1, 0, 0, 40)
	question.Position = UDim2.new(0, 0, 0, 50)
	question.BackgroundTransparency = 1
	question.Text = "Do you want to reactivate the Fruit Locator?"
	question.TextColor3 = Color3.fromRGB(200,200,200)
	question.TextScaled = true
	question.Font = Enum.Font.Gotham
	question.Parent = frame

	local btnYes = Instance.new("TextButton")
	btnYes.Size = UDim2.new(0.45, 0, 0, 45)
	btnYes.Position = UDim2.new(0.05, 0, 0.68, 0)
	btnYes.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
	btnYes.Text = "YES"
	btnYes.TextColor3 = Color3.fromRGB(0, 0, 0)
	btnYes.TextScaled = true
	btnYes.Font = Enum.Font.GothamBold
	btnYes.Parent = frame

	local btnNo = Instance.new("TextButton")
	btnNo.Size = UDim2.new(0.45, 0, 0, 45)
	btnNo.Position = UDim2.new(0.5, 0, 0.68, 0)
	btnNo.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
	btnNo.Text = "NO (stop permanently)"
	btnNo.TextColor3 = Color3.fromRGB(255,255,255)
	btnNo.TextScaled = true
	btnNo.Font = Enum.Font.GothamBold
	btnNo.Parent = frame

	local function makeCorner(btn)
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0,10)
		c.Parent = btn
	end
	makeCorner(btnYes)
	makeCorner(btnNo)

	btnYes.MouseButton1Click:Connect(function()
		isEnabled = true
		settings.enabled = true
		getgenv().FruitLocator_Settings = settings
		if miniMap and miniMap.Frame then
			miniMap.Frame.Visible = true
		end
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

local function setupCharacter(character)
	if not character then return end
	local humanoid = character:WaitForChild("Humanoid", 5)
	if humanoid then humanoid.Died:Connect(onCharacterDied) end
end

local function onCharacterAdded(character)
	task.spawn(function()
		task.wait(1)
		if permanentlyDisabled then return end
		setupCharacter(character)
		if not isEnabled then createReActivationPrompt() end
	end)
end

local function init()
	mainGui = createMainMenu()
	createMiniMap()

	scanInitialFruits()
	workspace.DescendantAdded:Connect(onDescendantAdded)
	workspace.DescendantRemoving:Connect(onDescendantRemoving)

	startUpdateLoop()

	LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
	LocalPlayer.CharacterRemoving:Connect(function() isEnabled = false end)

	if LocalPlayer.Character then onCharacterAdded(LocalPlayer.Character) end
end

init()
