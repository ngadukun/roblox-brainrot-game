-- WorldBuilder.luau (ModuleScript, server)
-- Builds the night market's dressing at server start: warung stalls with
-- sloped roofs and neon lamps, trees, street lamps, a low fence around the
-- grounds, umbrella tents, chevron arrows on the conveyor belt and a sign
-- board over every base that names it and shows its lock state.
--
-- The heavy layout (ground, belt, plots, slot pads, spawn) is static in the
-- Rojo project; everything here is decoration the scripts account for, so
-- what a screenshot shows is what the code builds.

local Workspace = game:GetService("Workspace")

local WorldBuilder = {}

local BASE_INFO = {
	{ Name = "BASE BIRU", Color = Color3.fromRGB(64, 120, 255) },
	{ Name = "BASE MERAH", Color = Color3.fromRGB(255, 80, 70) },
	{ Name = "BASE KUNING", Color = Color3.fromRGB(255, 205, 48) },
	{ Name = "BASE HIJAU", Color = Color3.fromRGB(70, 200, 90) },
}

local STALL_COLORS = {
	Color3.fromRGB(255, 110, 90),
	Color3.fromRGB(255, 170, 60),
	Color3.fromRGB(90, 200, 220),
	Color3.fromRGB(240, 110, 200),
	Color3.fromRGB(140, 230, 120),
	Color3.fromRGB(170, 130, 255),
}

local function makePart(parent, name, size, color, position, rotationY)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Anchored = true
	part.CanCollide = false
	part.CFrame = CFrame.new(position) * CFrame.Angles(0, rotationY or 0, 0)
	part.Parent = parent
	return part
end

local function buildStall(parent, position, rotationY, color)
	local stall = Instance.new("Model")
	stall.Name = "Warung"
	stall.Parent = parent
	local counter = makePart(stall, "Counter", Vector3.new(7, 3, 3), color, position + Vector3.new(0, 1.5, 0), rotationY)
	counter.CanCollide = true
	local roof = makePart(
		stall,
		"Roof",
		Vector3.new(8.5, 0.3, 5),
		Color3.fromRGB(120, 72, 40),
		position + Vector3.new(0, 5.4, 0),
		rotationY
	)
	roof.CFrame = roof.CFrame * CFrame.Angles(math.rad(14), 0, 0)
	local lampBall = makePart(
		stall,
		"Lamp",
		Vector3.new(0.9, 0.9, 0.9),
		Color3.fromRGB(255, 214, 120),
		position + Vector3.new(0, 4.4, 0),
		rotationY
	)
	lampBall.Shape = Enum.PartType.Ball
	lampBall.Material = Enum.Material.Neon
	return stall
end

local function buildTree(parent, position)
	local trunk = makePart(parent, "Trunk", Vector3.new(1.2, 5, 1.2), Color3.fromRGB(96, 64, 36), position + Vector3.new(0, 2.5, 0))
	trunk.Shape = Enum.PartType.Cylinder
	local leaves = makePart(parent, "Leaves", Vector3.new(5.5, 5.5, 5.5), Color3.fromRGB(34, 92, 40), position + Vector3.new(0, 7, 0))
	leaves.Shape = Enum.PartType.Ball
	local leavesTop = makePart(parent, "LeavesTop", Vector3.new(3.6, 3.6, 3.6), Color3.fromRGB(44, 110, 50), position + Vector3.new(0, 9.4, 0))
	leavesTop.Shape = Enum.PartType.Ball
end

local function buildStreetLamp(parent, position)
	local pole = makePart(parent, "LampPole", Vector3.new(0.5, 8, 0.5), Color3.fromRGB(50, 50, 58), position + Vector3.new(0, 4, 0))
	pole.Shape = Enum.PartType.Cylinder
	local head = makePart(parent, "LampHead", Vector3.new(1.4, 1.4, 1.4), Color3.fromRGB(255, 226, 140), position + Vector3.new(0, 8.4, 0))
	head.Shape = Enum.PartType.Ball
	head.Material = Enum.Material.Neon
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 205, 110)
	light.Range = 20
	light.Brightness = 1.4
	light.Parent = head
end

local function buildTent(parent, position, color)
	local pole = makePart(parent, "TentPole", Vector3.new(0.4, 4.5, 0.4), Color3.fromRGB(200, 200, 200), position + Vector3.new(0, 2.25, 0))
	pole.Shape = Enum.PartType.Cylinder
	local canopy = makePart(parent, "TentCanopy", Vector3.new(7, 1.6, 7), color, position + Vector3.new(0, 4.8, 0))
	canopy.Shape = Enum.PartType.Ball
end

local function buildBaseSign(parent, baseIndex, plotPosition, info)
	local sign = Instance.new("Model")
	sign.Name = "BaseSign" .. baseIndex
	sign.Parent = parent
	-- The sign stands on the plot edge that faces the market centre.
	local inward = -plotPosition.Unit
	local signPosition = plotPosition + inward * 11 + Vector3.new(0, 0, 0)
	local post = makePart(sign, "Post", Vector3.new(0.5, 6, 0.5), Color3.fromRGB(70, 52, 32), signPosition + Vector3.new(0, 3, 0))
	post.Shape = Enum.PartType.Cylinder
	local board = makePart(sign, "Board", Vector3.new(9, 3, 0.3), info.Color, signPosition + Vector3.new(0, 6.8, 0))
	board.CanCollide = false

	local gui = Instance.new("BillboardGui")
	gui.Name = "SignGui"
	gui.Size = UDim2.new(10, 0, 4, 0)
	gui.StudsOffset = Vector3.new(0, 0.4, 0)
	gui.AlwaysOnTop = true
	gui.Adornee = board
	gui.Parent = board

	local nameLine = Instance.new("TextLabel")
	nameLine.Name = "NameLine"
	nameLine.BackgroundTransparency = 1
	nameLine.Size = UDim2.new(1, 0, 0.55, 0)
	nameLine.Font = Enum.Font.GothamBlack
	nameLine.TextScaled = true
	nameLine.Text = info.Name
	nameLine.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLine.TextStrokeTransparency = 0.3
	nameLine.Parent = gui

	local lockLine = Instance.new("TextLabel")
	lockLine.Name = "LockLine"
	lockLine.BackgroundTransparency = 1
	lockLine.Size = UDim2.new(1, 0, 0.45, 0)
	lockLine.Position = UDim2.new(0, 0, 0.55, 0)
	lockLine.Font = Enum.Font.GothamBlack
	lockLine.TextScaled = true
	lockLine.Text = ""
	lockLine.TextColor3 = Color3.fromRGB(255, 90, 80)
	lockLine.TextStrokeTransparency = 0.3
	lockLine.Parent = gui
end

local function buildConveyorArrows(parent)
	local beltTopY = 1.05
	for _, z in ipairs({ -24, -8, 8, 24 }) do
		for _, side in ipairs({ -1, 1 }) do
			local arrow = makePart(
				parent,
				"Chevron",
				Vector3.new(2.6, 0.12, 0.55),
				Color3.fromRGB(255, 230, 90),
				Vector3.new(side * 0.85, beltTopY, z),
				side * math.rad(38)
			)
			arrow.Material = Enum.Material.Neon
		end
	end
end

-- Strings of small neon bulbs sagging between the lamp posts along the
-- plaza's two long edges — the night market's signature ceiling.
local function buildStringLights(parent)
	local runs = {
		{ from = Vector3.new(-12, 8.4, -34), to = Vector3.new(-12, 8.4, 34) },
		{ from = Vector3.new(12, 8.4, -34), to = Vector3.new(12, 8.4, 34) },
		{ from = Vector3.new(-34, 8.4, -12), to = Vector3.new(34, 8.4, -12) },
		{ from = Vector3.new(-34, 8.4, 12), to = Vector3.new(34, 8.4, 12) },
	}
	local bulbColors = {
		Color3.fromRGB(255, 150, 90),
		Color3.fromRGB(255, 220, 120),
		Color3.fromRGB(140, 230, 255),
		Color3.fromRGB(255, 140, 200),
	}
	local bulbCount = 13
	for runIndex, run in ipairs(runs) do
		for step = 0, bulbCount - 1 do
			local fraction = step / (bulbCount - 1)
			local position = run.from:Lerp(run.to, fraction)
			local sag = math.sin(fraction * math.pi) * -1.1
			local bulb = makePart(
				parent,
				"StringBulb",
				Vector3.new(0.55, 0.55, 0.55),
				bulbColors[(step + runIndex) % #bulbColors + 1],
				position + Vector3.new(0, sag, 0)
			)
			bulb.Shape = Enum.PartType.Ball
			bulb.Material = Enum.Material.Neon
		end
	end
end

-- Build everything, once, into a Decorations folder.
function WorldBuilder.buildNightMarketDecorations()
	local decorations = Instance.new("Folder")
	decorations.Name = "Decorations"
	decorations.Parent = Workspace

	local stallSpots = {
		{ Vector3.new(-22, 0, -42), 0 },
		{ Vector3.new(22, 0, -42), 0 },
		{ Vector3.new(-22, 0, 42), math.rad(180) },
		{ Vector3.new(22, 0, 42), math.rad(180) },
		{ Vector3.new(-42, 0, -20), math.rad(90) },
		{ Vector3.new(42, 0, 20), math.rad(-90) },
	}
	for index, spot in ipairs(stallSpots) do
		buildStall(decorations, spot[1], spot[2], STALL_COLORS[index])
	end

	local treeSpots = {
		Vector3.new(-64, 0, -64), Vector3.new(64, 0, -64), Vector3.new(-64, 0, 64), Vector3.new(64, 0, 64),
		Vector3.new(-64, 0, 0), Vector3.new(64, 0, 0), Vector3.new(0, 0, -64), Vector3.new(0, 0, 64),
		Vector3.new(-34, 0, -58), Vector3.new(34, 0, 58),
	}
	for _, spot in ipairs(treeSpots) do
		buildTree(decorations, spot)
	end

	local lampSpots = {
		Vector3.new(-12, 0, -34), Vector3.new(12, 0, -34), Vector3.new(-12, 0, 34), Vector3.new(12, 0, 34),
		Vector3.new(-34, 0, -12), Vector3.new(34, 0, -12), Vector3.new(-34, 0, 12), Vector3.new(34, 0, 12),
	}
	for _, spot in ipairs(lampSpots) do
		buildStreetLamp(decorations, spot)
	end

	local tentSpots = {
		{ Vector3.new(-58, 0, -30), Color3.fromRGB(255, 120, 120) },
		{ Vector3.new(58, 0, 30), Color3.fromRGB(120, 200, 255) },
		{ Vector3.new(-58, 0, 30), Color3.fromRGB(255, 220, 110) },
		{ Vector3.new(58, 0, -30), Color3.fromRGB(150, 255, 170) },
	}
	for _, spot in ipairs(tentSpots) do
		buildTent(decorations, spot[1], spot[2])
	end

	-- A low fence rings the grounds on all four sides.
	local fenceColor = Color3.fromRGB(110, 84, 52)
	makePart(decorations, "FenceNorth", Vector3.new(144, 2.5, 1), fenceColor, Vector3.new(0, 1.25, -71.5))
	makePart(decorations, "FenceSouth", Vector3.new(144, 2.5, 1), fenceColor, Vector3.new(0, 1.25, 71.5))
	makePart(decorations, "FenceWest", Vector3.new(1, 2.5, 144), fenceColor, Vector3.new(-71.5, 1.25, 0))
	makePart(decorations, "FenceEast", Vector3.new(1, 2.5, 144), fenceColor, Vector3.new(71.5, 1.25, 0))

	buildConveyorArrows(decorations)
	buildStringLights(decorations)

	local bases = Workspace:WaitForChild("Bases")
	for baseIndex = 1, 4 do
		local plot = bases:WaitForChild("Base" .. baseIndex):WaitForChild("Plot")
		buildBaseSign(decorations, baseIndex, Vector3.new(plot.Position.X, 0, plot.Position.Z), BASE_INFO[baseIndex])
	end

	return decorations
end

return WorldBuilder
