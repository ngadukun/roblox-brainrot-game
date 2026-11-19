-- BrainrotFactory.luau (ModuleScript, server)
-- Builds a brainrot character out of plain Roblox parts: a coloured body, a
-- smaller head, two black eyes and a floating label that reads the name (with
-- a star for a mutation), the rarity and the money per second. No external
-- assets are used, so any account can open the place and see the cast.
--
-- Every part is anchored and non-colliding: brainrots are moved by pivoting
-- their model, never by physics, which keeps the conveyor deterministic.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local BrainrotFactory = {}

local BODY_SIZE = Vector3.new(2.4, 3, 1.6)

-- Roll the mutation for a fresh spawn: mostly none, sometimes Gold, rarely
-- Diamond. Returns the mutation name and the rate multiplier it carries.
function BrainrotFactory.rollMutationForSpawn(random)
	local roll = random:NextNumber()
	if roll < Config.DiamondChance then
		return "Diamond", Config.DiamondRateMultiplier
	elseif roll < Config.DiamondChance + Config.GoldChance then
		return "Gold", Config.GoldRateMultiplier
	end
	return "None", 1
end

function BrainrotFactory.computeIncomeRate(def, mutationName)
	local rate = def.IncomePerSecond
	if mutationName == "Gold" then
		rate = rate * Config.GoldRateMultiplier
	elseif mutationName == "Diamond" then
		rate = rate * Config.DiamondRateMultiplier
	end
	return rate
end

local function makePart(name, size, color, offset)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CFrame = CFrame.new(offset)
	return part
end

local function makeLabelLine(name, text, size, color, order)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0.34, 0)
	label.Position = UDim2.new(0, 0, (order - 1) * 0.33, 0)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.35
	return label
end

-- Build the model for one cast definition under one mutation. The model's
-- pivot sits at the centre of the body, so callers place it half a body
-- height above whatever surface the brainrot stands on.
function BrainrotFactory.buildBrainrotModel(def, mutationName)
	local bodyColor = Color3.fromRGB(def.BodyColor[1], def.BodyColor[2], def.BodyColor[3])
	local scale = 1
	if mutationName == "Gold" then
		bodyColor = Color3.fromRGB(255, 205, 48)
		scale = 1.15
	elseif mutationName == "Diamond" then
		bodyColor = Color3.fromRGB(120, 235, 255)
		scale = 1.3
	end

	local model = Instance.new("Model")
	model.Name = def.Name

	local body = makePart("Body", BODY_SIZE * scale, bodyColor, Vector3.new(0, 0, 0))
	body.Parent = model
	model.PrimaryPart = body

	-- A soft shadow disc under the feet, so the character reads as standing
	-- on the belt or the pad instead of floating over it.
	local shadow = makePart(
		"Shadow",
		Vector3.new(2.6 * scale, 0.08, 2.2 * scale),
		Color3.fromRGB(10, 10, 14),
		Vector3.new(0, -BODY_SIZE.Y / 2 * scale + 0.05, 0)
	)
	shadow.Transparency = 0.45
	shadow.Parent = model

	local head = makePart(
		"Head",
		Vector3.new(1.5, 1.2, 1.2) * scale,
		bodyColor,
		Vector3.new(0, (BODY_SIZE.Y / 2 + 0.6) * scale, 0)
	)
	head.Parent = model

	local eyeColor = Color3.fromRGB(12, 12, 12)
	local eyeSize = Vector3.new(0.22, 0.3, 0.1) * scale
	local headFrontZ = 0.62 * scale
	local headY = (BODY_SIZE.Y / 2 + 0.65) * scale
	local eyeLeft = makePart("EyeLeft", eyeSize, eyeColor, Vector3.new(-0.35 * scale, headY, headFrontZ))
	eyeLeft.Parent = model
	local eyeRight = makePart("EyeRight", eyeSize, eyeColor, Vector3.new(0.35 * scale, headY, headFrontZ))
	eyeRight.Parent = model

	local label = Instance.new("BillboardGui")
	label.Name = "Label"
	label.Size = UDim2.new(7, 0, 3, 0)
	label.StudsOffset = Vector3.new(0, (BODY_SIZE.Y / 2 + 2.1) * scale, 0)
	label.AlwaysOnTop = true
	label.Adornee = body

	local displayName = def.Name
	if mutationName ~= "None" then
		displayName = "★ " .. string.upper(mutationName) .. " " .. def.Name
	end
	local rate = BrainrotFactory.computeIncomeRate(def, mutationName)
	local nameLine = makeLabelLine("NameLine", displayName, 20, Color3.fromRGB(255, 255, 255), 1)
	nameLine.Parent = label
	local rarityLine = makeLabelLine(
		"RarityLine",
		def.Rarity,
		16,
		Color3.fromRGB(def.RarityColor[1], def.RarityColor[2], def.RarityColor[3]),
		2
	)
	rarityLine.Parent = label
	local rateLine = makeLabelLine("RateLine", "$" .. rate .. "/detik", 16, Color3.fromRGB(140, 255, 140), 3)
	rateLine.Parent = label
	label.Parent = body

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Prompt"
	prompt.ActionText = "Beli"
	prompt.ObjectText = def.Name .. " — $" .. def.Price
	prompt.HoldDuration = 0
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = Config.BuyDistanceStuds
	prompt.RequiresLineOfSight = false
	prompt.Parent = body

	return model
end

-- Half the body height: how far above a surface the model's pivot belongs.
function BrainrotFactory.halfBodyHeight()
	return BODY_SIZE.Y / 2
end

return BrainrotFactory
