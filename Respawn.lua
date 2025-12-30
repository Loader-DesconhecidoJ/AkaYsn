-- Respawn cinematográfico estilo Return by Death + clone ragdoll + dissolve + flash + bloom + câmera distorcida

local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer

local deathPosition = nil

-- SOM
local REVIVE_SOUND_ID = "rbxassetid://18597544476"
local IMPACT_SOUND_ID = "rbxassetid://81257331910512"
local VOLUME = 3

local reviveSound = Instance.new("Sound")
reviveSound.SoundId = REVIVE_SOUND_ID
reviveSound.Volume = VOLUME
reviveSound.Parent = SoundService

local impactSound = Instance.new("Sound")
impactSound.SoundId = IMPACT_SOUND_ID
impactSound.Volume = VOLUME
impactSound.Parent = SoundService

-- GUI do flash
local flashGui = Instance.new("ScreenGui")
flashGui.ResetOnSpawn = false
flashGui.Parent = player:WaitForChild("PlayerGui")

local flashFrame = Instance.new("Frame")
flashFrame.Size = UDim2.fromScale(1,1)
flashFrame.Position = UDim2.new(0,0,0,0)
flashFrame.AnchorPoint = Vector2.new(0,0)
flashFrame.BackgroundColor3 = Color3.fromRGB(220,220,255)
flashFrame.BackgroundTransparency = 1
flashFrame.ZIndex = 1000
flashFrame.Parent = flashGui

-- Bloom leve
local bloom = Instance.new("BloomEffect")
bloom.Intensity = 0
bloom.Size = 24
bloom.Threshold = 0.5
bloom.Parent = Lighting

-- Blur da tela leve para distorção
local blur = Instance.new("BlurEffect")
blur.Size = 0
blur.Parent = Lighting

-- flash + bloom + blur + leve distorção
local function screenFlashEffects()
	for i=0,1,0.1 do
		flashFrame.BackgroundTransparency = 1 - i*0.6
		bloom.Intensity = i*1
		blur.Size = i*8
		task.wait(0.02)
	end
	for i=0,1,0.1 do
		flashFrame.BackgroundTransparency = 0.4 + i*0.6
		bloom.Intensity = 1 - i*1
		blur.Size = 8 - i*8
		task.wait(0.02)
	end
	flashFrame.BackgroundTransparency = 1
	bloom.Intensity = 0
	blur.Size = 0
end

-- ragdoll realista
local function applyRealRagdoll(clone)
	local humanoid = clone:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	humanoid.AutoRotate = false

	for _, joint in ipairs(clone:GetDescendants()) do
		if joint:IsA("Motor6D") then
			local a1 = Instance.new("Attachment", joint.Part0)
			local a2 = Instance.new("Attachment", joint.Part1)
			a1.CFrame = joint.C0
			a2.CFrame = joint.C1

			local socket = Instance.new("BallSocketConstraint")
			socket.Attachment0 = a1
			socket.Attachment1 = a2
			socket.LimitsEnabled = true
			socket.TwistLimitsEnabled = true
			socket.Parent = joint.Parent

			joint:Destroy()
		end
	end

	local root = clone:FindFirstChild("HumanoidRootPart")
	if root then
		root.Velocity = Vector3.new(math.random(-5,5), 10, math.random(-5,5))
		root.RotVelocity = Vector3.new(math.random(-2,2), math.random(-2,2), math.random(-2,2))
	end

	-- desativa colisão entre clone e corpo real
	for _, part in ipairs(clone:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
		end
	end
end

-- dissolve gradual
local function dissolveClone(clone, duration)
	for _, part in ipairs(clone:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Material = Enum.Material.SmoothPlastic
			local tween = TweenService:Create(part, TweenInfo.new(duration), {Transparency = 1})
			tween:Play()
		end
	end
end

-- impacto do clone
local function setupImpactSound(clone)
	local root = clone:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local touchedConnection
	touchedConnection = root.Touched:Connect(function(hit)
		if hit and hit:IsA("BasePart") and hit.Parent ~= clone then
			impactSound:Play()
			local cam = workspace.CurrentCamera
			if cam then
				local originalCFrame = cam.CFrame
				for i=1,5 do
					cam.CFrame = originalCFrame * CFrame.new(math.random(-0.2,0.2),math.random(-0.2,0.2),math.random(-0.2,0.2))
					task.wait(0.03)
				end
				cam.CFrame = originalCFrame
			end
			touchedConnection:Disconnect()
		end
	end)
end

-- efeito de “tempo parado”
local function freezeTimeBriefly()
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Humanoid") and obj.Parent ~= player.Character then
			local origSpeed = obj.WalkSpeed
			obj.WalkSpeed = 0
			task.delay(0.1, function()
				if obj then obj.WalkSpeed = origSpeed end
			end)
		end
	end
end

-- personagem spawnou
local function onCharacterAdded(character)
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	local head = character:WaitForChild("Head")

	if deathPosition then
		root.CFrame = CFrame.new(deathPosition + Vector3.new(0,3,0))
		reviveSound:Play()
		freezeTimeBriefly()
		screenFlashEffects()
	end

	humanoid.Died:Connect(function()
		deathPosition = root.Position

		if character:FindFirstChild("CloneCreated") then return end
		Instance.new("BoolValue", character).Name = "CloneCreated"

		local clone = character:Clone()
		clone.Parent = workspace
		clone:MoveTo(deathPosition)

		for _, v in ipairs(clone:GetDescendants()) do
			if v:IsA("Script") or v:IsA("LocalScript") then
				v:Destroy()
			end
		end

		applyRealRagdoll(clone)
		setupImpactSound(clone)

		-- some com corpo real
		for _, p in ipairs(character:GetDescendants()) do
			if p:IsA("BasePart") then
				p.Transparency = 1
				p.CanCollide = false
			end
		end

		-- dissolve gradual do clone depois de 10 segundos
		task.delay(10, function()
			dissolveClone(clone, 3)
			task.delay(3, function()
				if clone.Parent then clone:Destroy() end
			end)
		end)
	end)
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
	onCharacterAdded(player.Character)
end
