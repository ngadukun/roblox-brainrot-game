-- EventService.luau (ModuleScript, server)
-- The Hujan Krupuk: every EventIntervalSeconds a wave of crackers sweeps the
-- market. Clients get a five-second banner warning; when the wave lands, a
-- translucent wall rolls down the map and every player caught outside their
-- own base is flung back to spawn — dropping whatever they were carrying.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local BaseService = require(script.Parent:WaitForChild("BaseService"))
local StealService = require(script.Parent:WaitForChild("StealService"))

local EventService = {}

local waveRunning = false

local function buildWaveWall()
	local wall = Instance.new("Part")
	wall.Name = "KrupukWave"
	wall.Size = Vector3.new(150, 14, 3)
	wall.Color = Color3.fromRGB(245, 232, 190) -- cracker cream
	wall.Transparency = 0.45
	wall.Anchored = true
	wall.CanCollide = false
	wall.CanQuery = false
	wall.Material = Enum.Material.SmoothPlastic
	return wall
end

-- Roll the visible wall from the north edge to the south edge over about
-- two seconds, so screenshots catch a wall of crackers crossing the market.
local function sweepWaveWallAcrossMap()
	local wall = buildWaveWall()
	wall.Parent = Workspace
	local startZ = -70
	local endZ = 70
	local duration = 2
	local elapsed = 0
	wall:PivotTo(CFrame.new(0, 7, startZ))
	while elapsed < duration do
		local deltaTime = task.wait()
		elapsed = elapsed + deltaTime
		local z = startZ + (endZ - startZ) * math.min(elapsed / duration, 1)
		wall:PivotTo(CFrame.new(0, 7, z))
	end
	wall:Destroy()
end

local function knockPlayerBackToSpawn(player)
	local character = player.Character
	if not character then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	local spawnPad = Workspace:FindFirstChild("SpawnPad")
	if root and spawnPad then
		local target = spawnPad.Position + Vector3.new(0, 4, 0)
		root:PivotTo(CFrame.new(target))
		root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
	end
end

-- Crackers fall with the wave: a scatter of small cream discs rains over
-- the market for a few seconds and then cleans itself up.
local function rainKrupukOverMarket()
	local random = Random.new()
	local crackers = {}
	for _ = 1, 36 do
		local cracker = Instance.new("Part")
		cracker.Name = "Krupuk"
		cracker.Shape = Enum.PartType.Cylinder
		cracker.Size = Vector3.new(0.25, 1.6, 1.6)
		cracker.Color = Color3.fromRGB(245, 232, 190)
		cracker.Anchored = true
		cracker.CanCollide = false
		cracker.CanQuery = false
		cracker.CFrame = CFrame.new(random:NextNumber(-62, 62), random:NextNumber(26, 44), random:NextNumber(-62, 62))
			* CFrame.Angles(0, 0, math.rad(90))
		cracker.Parent = Workspace
		table.insert(crackers, { Part = cracker, Speed = random:NextNumber(9, 15) })
	end
	task.spawn(function()
		local fallen = 0
		while fallen < #crackers do
			local deltaTime = task.wait()
			fallen = 0
			for _, entry in ipairs(crackers) do
				local part = entry.Part
				if part.Position.Y <= 0.4 then
					fallen = fallen + 1
				else
					part.CFrame = part.CFrame * CFrame.new(0, -entry.Speed * deltaTime, 0)
				end
			end
		end
		task.wait(1.2)
		for _, entry in ipairs(crackers) do
			entry.Part:Destroy()
		end
	end)
end

-- One full wave: warn, wait, sweep, punish everyone caught outside.
function EventService.triggerKrupukWave()
	if waveRunning then
		return
	end
	waveRunning = true
	Remotes:WaitForChild("WaveWarning"):FireAllClients(
		"HUJAN KRUPUK! Lari pulang ke base kamu!",
		Config.EventWarningSeconds
	)
	task.wait(Config.EventWarningSeconds)
	rainKrupukOverMarket()
	for player, record in pairs(PlayerState.allPlayerRecords()) do
		if not BaseService.isCharacterOnOwnBase(record) then
			StealService.dropCarriedBrainrot(player)
			knockPlayerBackToSpawn(player)
			Remotes:WaitForChild("Toast"):FireClient(player, "Kena gelombang krupuk! Kamu terpental ke spawn")
		end
	end
	sweepWaveWallAcrossMap()
	waveRunning = false
end

function EventService.start()
	task.spawn(function()
		while true do
			task.wait(Config.EventIntervalSeconds)
			EventService.triggerKrupukWave()
		end
	end)
end

return EventService
