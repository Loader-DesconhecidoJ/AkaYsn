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
local LockedTarget = nil
local Hue = 0
local PartMenuOpen = false

--// CONFIG
local FOV = 120
local CamSmooth = 0.98
local AimSmooth = 1
local AssistStrength = 0.95

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
	return LP.Team and plr.Team == LP.Team
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
local dragging,startPos,dragStart
main.InputBegan:Connect(function(i)
	if i.UserInputType==Enum.UserInputType.MouseButton1 then
		dragging=true
		startPos=main.Position
		dragStart=i.Position
	end
end)
main.InputChanged:Connect(function(i)
	if dragging then
		local d=i.Position-dragStart
		main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
	end
end)
UIS.InputEnded:Connect(function(i)
	if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
end)

--// LOOP
RunService.RenderStepped:Connect(function(dt)
	Hue = (Hue + dt*0.5) % 1

	FovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
	FovCircle.Visible = Enabled and LockMode=="ASSIST"

	if not Enabled then
		LockedTarget = nil
		return
	end

	-- 🔒 CAMLOCK & AIMLOCK → ALVO FIXO (NUNCA TROCA)
	if LockMode ~= "ASSIST" then
		if not LockedTarget or not LockedTarget.Parent then
			LockedTarget = getTarget()
		end
	end

	if LockMode == "CAMLOCK" and LockedTarget then
		Camera.CFrame = Camera.CFrame:Lerp(
			CFrame.new(Camera.CFrame.Position, LockedTarget.Position),
			CamSmooth
		)

	elseif LockMode == "AIMLOCK" and LockedTarget then
		local char = LP.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			local hrp = char.HumanoidRootPart
			local look = Vector3.new(LockedTarget.Position.X, hrp.Position.Y, LockedTarget.Position.Z)
			hrp.CFrame = hrp.CFrame:Lerp(
				CFrame.new(hrp.Position, look),
				AimSmooth
			)
		end

	-- 🎯 AIM ASSIST → DINÂMICO
	elseif LockMode == "ASSIST" then
		local t = getTarget()
		if t and not sameTeam(t) and hasLineOfSight(t) then
			local camCF = Camera.CFrame
			local dir = (t.Position - camCF.Position).Unit
			Camera.CFrame = CFrame.new(
				camCF.Position,
				camCF.Position + camCF.LookVector:Lerp(dir, AssistStrength)
			)
		end
	end
end)
