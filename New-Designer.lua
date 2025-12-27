--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LP = Players.LocalPlayer

--// CONFIG
local FOV = 120
local CamSmooth = 1
local AimSmooth = 1

--// STATE
local Enabled = false
local TargetType = "PLAYERS" -- PLAYERS / NPCS
local LockMode = "CAMLOCK" -- CAMLOCK / AIMLOCK
local Target = nil
local Hue = 0
local MenuOpen = true

--// UTIL
local function getPart(char)
	return char:FindFirstChild("Head")
		or char:FindFirstChild("UpperTorso")
		or char:FindFirstChild("Torso")
		or char:FindFirstChild("HumanoidRootPart")
end

local function isNPC(m)
	return m:IsA("Model")
		and m:FindFirstChildOfClass("Humanoid")
		and Players:GetPlayerFromCharacter(m) == nil
end

local function getTarget()
	local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
	local best, dist = nil, math.huge

	local function check(char)
		local part = getPart(char)
		if not part then return end
		local pos, on = Camera:WorldToViewportPoint(part.Position)
		if not on then return end
		local d = (Vector2.new(pos.X,pos.Y) - center).Magnitude
		if d < FOV and d < dist then
			best, dist = part, d
		end
	end

	if TargetType == "PLAYERS" then
		for _,p in ipairs(Players:GetPlayers()) do
			if p ~= LP and p.Character then
				check(p.Character)
			end
		end
	else
		for _,m in ipairs(workspace:GetDescendants()) do
			if isNPC(m) then
				check(m)
			end
		end
	end

	return best
end

--// GUI
local gui = Instance.new("ScreenGui", LP.PlayerGui)
gui.ResetOnSpawn = false

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0,300,0,60)
main.Position = UDim2.new(0.5,-150,0.6,0)
main.BackgroundColor3 = Color3.fromRGB(22,22,22)
main.BorderSizePixel = 0
Instance.new("UICorner", main).CornerRadius = UDim.new(0,10)

--// DRAG (PC + MOBILE)
local dragging, dragStart, startPos

local function updateDrag(input)
	local delta = input.Position - dragStart
	main.Position = UDim2.new(
		startPos.X.Scale,
		startPos.X.Offset + delta.X,
		startPos.Y.Scale,
		startPos.Y.Offset + delta.Y
	)
end

main.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
	or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = main.Position
	end
end)

main.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
	or input.UserInputType == Enum.UserInputType.Touch) then
		updateDrag(input)
	end
end)

UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
	or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

--// MENU BUTTON
local menuBtn = Instance.new("TextButton", main)
menuBtn.Size = UDim2.new(0,36,1,0)
menuBtn.Text = "<"
menuBtn.Font = Enum.Font.GothamBold
menuBtn.TextSize = 18
menuBtn.TextColor3 = Color3.new(1,1,1)
menuBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
menuBtn.BorderSizePixel = 0
Instance.new("UICorner", menuBtn).CornerRadius = UDim.new(0,10)

--// TOGGLE
local toggle = Instance.new("TextButton", main)
toggle.Size = UDim2.new(0,150,0,36)
toggle.Position = UDim2.new(0,45,0,12)
toggle.Text = "TOGGLE OFF"
toggle.Font = Enum.Font.GothamBold
toggle.TextSize = 16
toggle.TextColor3 = Color3.new(1,1,1)
toggle.BackgroundColor3 = Color3.fromRGB(40,40,40)
toggle.BorderSizePixel = 0
Instance.new("UICorner", toggle).CornerRadius = UDim.new(0,8)

--// SIDE BUTTONS
local function sideBtn(text,y)
	local b = Instance.new("TextButton", main)
	b.Size = UDim2.new(0,50,0,22)
	b.Position = UDim2.new(1,-55,0,y)
	b.Text = text
	b.Font = Enum.Font.Gotham
	b.TextSize = 12
	b.TextColor3 = Color3.new(1,1,1)
	b.BackgroundColor3 = Color3.fromRGB(35,35,35)
	b.BorderSizePixel = 0
	Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
	return b
end

local targetBtn = sideBtn("P",10)
local modeBtn = sideBtn("CAM",34)

--// INTERACTIONS
menuBtn.MouseButton1Click:Connect(function()
	MenuOpen = not MenuOpen
	main.Size = MenuOpen and UDim2.new(0,300,0,60) or UDim2.new(0,36,0,60)
	menuBtn.Text = MenuOpen and "<" or ">"
	toggle.Visible = MenuOpen
	targetBtn.Visible = MenuOpen
	modeBtn.Visible = MenuOpen
end)

toggle.MouseButton1Click:Connect(function()
	Enabled = not Enabled
	toggle.Text = Enabled and "TOGGLE ON" or "TOGGLE OFF"
	Target = Enabled and getTarget() or nil
end)

targetBtn.MouseButton1Click:Connect(function()
	TargetType = TargetType == "PLAYERS" and "NPCS" or "PLAYERS"
	targetBtn.Text = TargetType == "PLAYERS" and "P" or "N"
	Target = nil
end)

modeBtn.MouseButton1Click:Connect(function()
	LockMode = LockMode == "CAMLOCK" and "AIMLOCK" or "CAMLOCK"
	modeBtn.Text = LockMode == "CAMLOCK" and "CAM" or "AIM"
end)

--// MAIN LOOP (RGB + LOCK)
RunService.RenderStepped:Connect(function(dt)
	-- RGB
	Hue = (Hue + dt * 0.4) % 1
	toggle.BackgroundColor3 = Color3.fromHSV(Hue,0.85,0.9)

	if not Enabled or not Target or not Target.Parent then return end

	-- CAMLOCK
	if LockMode == "CAMLOCK" then
		Camera.CFrame = Camera.CFrame:Lerp(
			CFrame.new(Camera.CFrame.Position, Target.Position),
			CamSmooth
		)
	end

	-- AIMLOCK REAL
	if LockMode == "AIMLOCK" then
		local char = LP.Character
		if char then
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then
				local lookPos = Vector3.new(
					Target.Position.X,
					hrp.Position.Y,
					Target.Position.Z
				)
				hrp.CFrame = hrp.CFrame:Lerp(
					CFrame.new(hrp.Position, lookPos),
					AimSmooth
				)
			end
		end
	end
end)
