--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LP = Players.LocalPlayer

--// STATES
local Enabled = false
local TargetType = "PLAYERS"
local LockMode = "CAMLOCK" -- CAMLOCK / AIMLOCK / ASSIST
local BodyPart = "Head"
local Target = nil
local Hue = 0
local PartMenuOpen = false

--// CONFIG
local FOV = 100
local CamSmooth = 0.98
local AimSmooth = 1
local AssistStrength = 1

--// FOV CIRCLE (AIM ASSIST ONLY)
local FovCircle = Drawing.new("Circle")
FovCircle.Visible = false
FovCircle.Thickness = 2
FovCircle.NumSides = 64
FovCircle.Filled = false
FovCircle.Radius = FOV
FovCircle.Color = Color3.fromRGB(0,170,255)

--// WALL CHECK (AIM ASSIST)
local RayParams = RaycastParams.new()
RayParams.FilterType = Enum.RaycastFilterType.Blacklist
RayParams.IgnoreWater = true

local function hasLineOfSight(part)
	RayParams.FilterDescendantsInstances = {LP.Character}
	local origin = Camera.CFrame.Position
	local direction = (part.Position - origin)
	local result = workspace:Raycast(origin, direction, RayParams)
	if result then
		return result.Instance:IsDescendantOf(part.Parent)
	end
	return true
end

--// TEAM CHECK (AIM ASSIST)
local function sameTeam(part)
	if TargetType ~= "PLAYERS" then return false end
	local plr = Players:GetPlayerFromCharacter(part.Parent)
	if not plr then return false end
	return LP.Team ~= nil and plr.Team == LP.Team
end

--// UTILS
local function getPart(char)
	if BodyPart == "Head" then
		return char:FindFirstChild("Head")
	elseif BodyPart == "Torso" then
		return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
	else
		return char:FindFirstChild("LeftFoot") or char:FindFirstChild("RightFoot")
	end
end

local function isNPC(m)
	return m:IsA("Model")
		and m:FindFirstChildOfClass("Humanoid")
		and not Players:GetPlayerFromCharacter(m)
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
main.Size = UDim2.new(0,260,0,54)
main.Position = UDim2.new(0.5,-130,0.6,0)
main.BackgroundColor3 = Color3.fromRGB(20,20,20)
main.BorderSizePixel = 0
Instance.new("UICorner", main).CornerRadius = UDim.new(0,12)

--// DRAG
local dragging, startPos, dragStart
main.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		startPos = main.Position
		dragStart = i.Position
	end
end)

main.InputChanged:Connect(function(i)
	if dragging then
		local delta = i.Position - dragStart
		main.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

UIS.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

--// BUTTON FACTORY
local function sideBtn(text,y)
	local b = Instance.new("TextButton", main)
	b.Size = UDim2.new(0,44,0,18)
	b.Position = UDim2.new(0,6,0,y)
	b.Text = text
	b.Font = Enum.Font.GothamBold
	b.TextSize = 11
	b.TextColor3 = Color3.new(1,1,1)
	b.BackgroundColor3 = Color3.fromRGB(35,35,35)
	b.BorderSizePixel = 0
	Instance.new("UICorner", b)
	return b
end

local targetBtn = sideBtn("P",4)
local modeBtn   = sideBtn("CAM",20)
local partBtn   = sideBtn("PART",36)

--// TOGGLE
local toggle = Instance.new("TextButton", main)
toggle.Size = UDim2.new(0,120,0,30)
toggle.Position = UDim2.new(0.5,-60,0.5,-15)
toggle.Text = "OFF"
toggle.Font = Enum.Font.GothamBold
toggle.TextSize = 14
toggle.TextColor3 = Color3.new(1,1,1)
toggle.BackgroundColor3 = Color3.fromRGB(60,60,60)
toggle.BorderSizePixel = 0
Instance.new("UICorner", toggle)

--// PART MENU
local partMenu = Instance.new("Frame", gui)
partMenu.Size = UDim2.new(0,84,0,90)
partMenu.Visible = false
partMenu.BackgroundColor3 = Color3.fromRGB(25,25,25)
partMenu.BorderSizePixel = 0
Instance.new("UICorner", partMenu)

local function updatePartMenu()
	local p,s = partBtn.AbsolutePosition, partBtn.AbsoluteSize
	partMenu.Position = UDim2.fromOffset(p.X, p.Y + s.Y + 4)
end

local function partOption(text,y)
	local b = Instance.new("TextButton", partMenu)
	b.Size = UDim2.new(1,-8,0,24)
	b.Position = UDim2.new(0,4,0,y)
	b.Text = text
	b.Font = Enum.Font.GothamBold
	b.TextSize = 11
	b.TextColor3 = Color3.new(1,1,1)
	b.BackgroundColor3 = Color3.fromRGB(45,45,45)
	b.BorderSizePixel = 0
	Instance.new("UICorner", b)
	return b
end

partOption("HEAD",4).MouseButton1Click:Connect(function() BodyPart="Head" partMenu.Visible=false PartMenuOpen=false end)
partOption("TORSO",32).MouseButton1Click:Connect(function() BodyPart="Torso" partMenu.Visible=false PartMenuOpen=false end)
partOption("FOOT",60).MouseButton1Click:Connect(function() BodyPart="Foot" partMenu.Visible=false PartMenuOpen=false end)

--// BUTTON ACTIONS
modeBtn.MouseButton1Click:Connect(function()
	if LockMode == "CAMLOCK" then LockMode="AIMLOCK" modeBtn.Text="AIM"
	elseif LockMode=="AIMLOCK" then LockMode="ASSIST" modeBtn.Text="AST"
	else LockMode="CAMLOCK" modeBtn.Text="CAM" end
end)

targetBtn.MouseButton1Click:Connect(function()
	TargetType = TargetType=="PLAYERS" and "NPCS" or "PLAYERS"
	targetBtn.Text = TargetType=="PLAYERS" and "P" or "N"
	Target=nil
end)

toggle.MouseButton1Click:Connect(function()
	Enabled = not Enabled
	toggle.Text = Enabled and "ON" or "OFF"
	Target=nil
end)

partBtn.MouseButton1Click:Connect(function()
	PartMenuOpen = not PartMenuOpen
	if PartMenuOpen then updatePartMenu() end
	partMenu.Visible = PartMenuOpen
end)

--// LOOP
RunService.RenderStepped:Connect(function(dt)
	Hue = (Hue + dt*0.5) % 1
	toggle.BackgroundColor3 = Color3.fromHSV(Hue,0.85,0.9)

	FovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
	FovCircle.Visible = Enabled and LockMode=="ASSIST"

	if not Enabled then return end
	if not Target or not Target.Parent then Target=getTarget() return end

	if LockMode=="CAMLOCK" then
		Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, Target.Position), CamSmooth)

	elseif LockMode=="AIMLOCK" then
		local char=LP.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			local hrp=char.HumanoidRootPart
			local look=Vector3.new(Target.Position.X, hrp.Position.Y, Target.Position.Z)
			hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(hrp.Position, look), AimSmooth)
		end

	elseif LockMode=="ASSIST" then
		if not sameTeam(Target) and hasLineOfSight(Target) then
			local camCF=Camera.CFrame
			local dir=(Target.Position-camCF.Position).Unit
			Camera.CFrame = CFrame.new(camCF.Position, camCF.Position + camCF.LookVector:Lerp(dir, AssistStrength))
		end
	end
end)
