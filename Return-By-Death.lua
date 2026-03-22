print("=== REVIVE SCRIPT LOADED (Jujutsu Shenanigans Compatible) ===")

local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local deathPosition = nil

-- SOM
local REVIVE_SOUND_ID = "rbxassetid://18597544476"
local VOLUME = 3

local reviveSound = Instance.new("Sound")
reviveSound.SoundId = REVIVE_SOUND_ID
reviveSound.Volume = VOLUME
reviveSound.Parent = SoundService

-- GUI Flash
local flashGui = Instance.new("ScreenGui")
flashGui.ResetOnSpawn = false
flashGui.Parent = player:WaitForChild("PlayerGui")

local flashFrame = Instance.new("Frame")
flashFrame.Size = UDim2.fromScale(1,1)
flashFrame.BackgroundColor3 = Color3.fromRGB(220,220,255)
flashFrame.BackgroundTransparency = 1
flashFrame.ZIndex = 1000
flashFrame.Parent = flashGui

-- Bloom + Blur
local bloom = Instance.new("BloomEffect")
bloom.Intensity = 0
bloom.Size = 24
bloom.Threshold = 0.5
bloom.Parent = Lighting

local blur = Instance.new("BlurEffect")
blur.Size = 0
blur.Parent = Lighting

local function screenFlashEffects()
	for i = 0, 1, 0.1 do
		flashFrame.BackgroundTransparency = 1 - i * 0.6
		bloom.Intensity = i * 1
		blur.Size = i * 8
		task.wait(0.01)
	end
	for i = 0, 1, 0.1 do
		flashFrame.BackgroundTransparency = 0.4 + i * 0.6
		bloom.Intensity = 1 - i * 1
		blur.Size = 8 - i * 8
		task.wait(0.02)
	end
	flashFrame.BackgroundTransparency = 1
	bloom.Intensity = 0
	blur.Size = 0
end

local function applyRagdoll(clone)
	local humanoid = clone:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		humanoid.AutoRotate = false
	end

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

	for _, part in ipairs(clone:GetDescendants()) do
		if part:IsA("BasePart") then part.CanCollide = false end
	end
end

local function dissolveClone(clone, duration)
	for _, part in ipairs(clone:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Material = Enum.Material.SmoothPlastic
			TweenService:Create(part, TweenInfo.new(duration), {Transparency = 1}):Play()
		end
	end
end

local function addEnergyParticles(clone)
	for _, part in ipairs(clone:GetDescendants()) do
		if part:IsA("BasePart") then
			local emitter = Instance.new("ParticleEmitter")
			emitter.Texture = "rbxassetid://243660364"
			emitter.Rate = 5
			emitter.Lifetime = NumberRange.new(0.5)
			emitter.Speed = NumberRange.new(1)
			emitter.Parent = part
			Debris:AddItem(emitter, 3)
		end
	end
end

local function addTrail(clone)
	local root = clone:FindFirstChild("HumanoidRootPart")
	if root then
		local trail = Instance.new("Trail")
		trail.Attachment0 = Instance.new("Attachment", root)
		trail.Attachment1 = Instance.new("Attachment", root)
		trail.Lifetime = 0.3
		trail.Color = ColorSequence.new(Color3.fromRGB(200,200,255))
		trail.Parent = root
		Debris:AddItem(trail, 3)
	end
end

local function slowMotion()
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Humanoid") and obj.Parent ~= player.Character then
			local orig = obj.WalkSpeed
			obj.WalkSpeed = orig * 0.3
			task.delay(0.2, function() if obj then obj.WalkSpeed = orig end end)
		end
	end
end

-- TELEPORTE FORÇADO (agora só 1 segundo)
local function onCharacterAdded(character)
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")

	if deathPosition then
		local targetCFrame = CFrame.new(deathPosition + Vector3.new(0, 3, 0))

		root.CFrame = targetCFrame
		reviveSound:Play()
		slowMotion()
		screenFlashEffects()

		-- FORÇA o teleporte por 1 segundo (contra respawn forçado do jogo)
		local heartbeatConn
		heartbeatConn = RunService.Heartbeat:Connect(function()
			if root and root.Parent then
				root.CFrame = targetCFrame
			else
				heartbeatConn:Disconnect()
			end
		end)

		task.delay(1, function() if heartbeatConn then heartbeatConn:Disconnect() end end)
	end

	humanoid.Died:Connect(function()
		deathPosition = root.Position

		if character:FindFirstChild("CloneCreated") then return end
		Instance.new("BoolValue", character).Name = "CloneCreated"

		local clone = character:Clone()
		clone.Parent = workspace
		clone:MoveTo(deathPosition)

		for _, v in ipairs(clone:GetDescendants()) do
			if v:IsA("Script") or v:IsA("LocalScript") then v:Destroy() end
		end

		applyRagdoll(clone)
		addEnergyParticles(clone)
		addTrail(clone)

		for _, p in ipairs(character:GetDescendants()) do
			if p:IsA("BasePart") then
				p.Transparency = 1
				p.CanCollide = false
			end
		end

		task.delay(5, function()
			dissolveClone(clone, 3)
			task.delay(3, function()
				if clone and clone.Parent then clone:Destroy() end
			end)
		end)
	end)
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then onCharacterAdded(player.Character) end

print("=== REVIVE SCRIPT ATIVADO (força respawn = 1s) ===")
