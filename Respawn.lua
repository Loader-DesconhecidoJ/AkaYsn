-- Respawn instantâneo + som + "?" com ÓRBITA LARGA ao redor da cabeça

local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local deathPosition = nil

-- SOM
local REVIVE_SOUND_ID = "rbxassetid://18597544476"
local VOLUME = 3

-- CONFIG EFEITO (ÓRBITA LARGA)
local EFFECT_DURATION = 3
local ORBIT_RADIUS = 0.65        -- MUITO MAIS LARGO
local ORBIT_HEIGHT = 0.95        -- BAIXO
local ORBIT_SPEED = 2.2
local QUESTION_COUNT = 3

-- cria som
local reviveSound = Instance.new("Sound")
reviveSound.SoundId = REVIVE_SOUND_ID
reviveSound.Volume = VOLUME
reviveSound.Looped = false
reviveSound.Parent = SoundService

-- cria um "?"
local function createQuestion(head)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromScale(0.75, 0.75)
	bb.AlwaysOnTop = true
	bb.Parent = head

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.fromScale(1, 1)
	txt.BackgroundTransparency = 1
	txt.Text = "?"
	txt.TextScaled = true
	txt.Font = Enum.Font.GothamBold
	txt.TextColor3 = Color3.fromRGB(255, 255, 255)
	txt.TextStrokeTransparency = 0
	txt.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	txt.Parent = bb

	return bb
end

-- efeito completo
local function createOrbitQuestions(head)
	local questions = {}
	local offsets = {}

	-- offsets uniformes (0°, 120°, 240°)
	for i = 1, QUESTION_COUNT do
		questions[i] = createQuestion(head)
		offsets[i] = (math.pi * 2 / QUESTION_COUNT) * (i - 1)
	end

	local start = tick()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local elapsed = tick() - start
		if elapsed >= EFFECT_DURATION then
			conn:Disconnect()
			for _, q in ipairs(questions) do
				q:Destroy()
			end
			return
		end

		for i, q in ipairs(questions) do
			local ang = elapsed * ORBIT_SPEED + offsets[i]
			local x = math.cos(ang) * ORBIT_RADIUS
			local z = math.sin(ang) * ORBIT_RADIUS
			q.StudsOffset = Vector3.new(x, ORBIT_HEIGHT, z)
		end
	end)
end

-- personagem nasceu
local function onCharacterAdded(character)
	local humanoid = character:WaitForChild("Humanoid", 2)
	local root = character:WaitForChild("HumanoidRootPart", 2)
	local head = character:WaitForChild("Head", 2)
	if not humanoid or not root or not head then return end

	if deathPosition then
		RunService.RenderStepped:Wait()
		root.CFrame = CFrame.new(deathPosition + Vector3.new(0, 3, 0))
		reviveSound:Play()
		createOrbitQuestions(head)
	end

	humanoid.Died:Connect(function()
		if character:FindFirstChild("HumanoidRootPart") then
			deathPosition = character.HumanoidRootPart.Position
		end
	end)
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then onCharacterAdded(player.Character) end
