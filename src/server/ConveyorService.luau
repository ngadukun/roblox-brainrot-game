-- ConveyorService.luau (ModuleScript, server)
-- The belt at the heart of the market: every few seconds a new brainrot
-- walks on at the north end and strolls south at a steady pace, wearing its
-- buy prompt. Anything unsold at the south end despawns. Movement is a
-- Heartbeat step on anchored models, so the belt never jitters with physics.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local BrainrotData = require(Shared:WaitForChild("BrainrotData"))

local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local BrainrotFactory = require(script.Parent:WaitForChild("BrainrotFactory"))
local EconomyService = require(script.Parent:WaitForChild("EconomyService"))

local ConveyorService = {}

local random = Random.new()

local function brainrotContainer()
	local container = Workspace:FindFirstChild("Brainrots")
	if not container then
		container = Instance.new("Folder")
		container.Name = "Brainrots"
		container.Parent = Workspace
	end
	return container
end

local function beltTopY()
	local belt = Workspace:WaitForChild("Conveyor"):WaitForChild("Belt")
	return belt.Position.Y + belt.Size.Y / 2
end

local function countOnConveyor()
	local count = 0
	for _, brainrot in pairs(PlayerState.allBrainrotRecords()) do
		if brainrot.Where == "Conveyor" then
			count = count + 1
		end
	end
	return count
end

-- Put one brainrot on the belt: roll its mutation, build its model at the
-- north end and wire its buy prompt to the economy.
function ConveyorService.spawnBrainrotOnConveyor(def)
	def = def or BrainrotData.pickWeightedDefinition(random)
	local mutationName = BrainrotFactory.rollMutationForSpawn(random)
	local rate = BrainrotFactory.computeIncomeRate(def, mutationName)
	local model = BrainrotFactory.buildBrainrotModel(def, mutationName)
	local brainrot = PlayerState.addBrainrotRecord(def, mutationName, rate, model)

	local y = beltTopY() + BrainrotFactory.halfBodyHeight()
	model:PivotTo(CFrame.new(0, y, Config.ConveyorStartZ))
	model.Parent = brainrotContainer()

	local body = model:FindFirstChild("Body")
	local prompt = body and body:FindFirstChild("Prompt")
	if prompt then
		prompt.Triggered:Connect(function(player)
			EconomyService.buyBrainrotFromConveyor(player, brainrot.Id)
		end)
	end
	return brainrot
end

-- Spawn a named cast member, for the tour and for events that want a star
-- on the belt right now.
function ConveyorService.spawnNamedBrainrot(name)
	local def = BrainrotData.getDefinitionByName(name)
	if not def then
		return nil
	end
	return ConveyorService.spawnBrainrotOnConveyor(def)
end

local function despawnBrainrot(brainrot)
	brainrot.Model:Destroy()
	PlayerState.removeBrainrotRecord(brainrot.Id)
end

-- One belt step: walk every conveyor brainrot south with a small bob, so
-- the line reads as strolling rather than sliding, and take off any that
-- reached the end unsold.
function ConveyorService.moveBrainrotsAlongConveyor(deltaTime)
	local step = Config.ConveyorSpeedStuds * deltaTime
	local beltY = beltTopY() + BrainrotFactory.halfBodyHeight()
	local now = os.clock()
	local arrived = {}
	for _, brainrot in pairs(PlayerState.allBrainrotRecords()) do
		if brainrot.Where == "Conveyor" then
			brainrot.ConveyorZ = brainrot.ConveyorZ + step
			if brainrot.ConveyorZ >= Config.ConveyorEndZ then
				table.insert(arrived, brainrot)
			else
				local bob = math.sin((now - brainrot.SpawnedAt) * 7 + brainrot.Id) * 0.09
				brainrot.Model:PivotTo(CFrame.new(0, beltY + bob, brainrot.ConveyorZ))
			end
		end
	end
	for _, brainrot in ipairs(arrived) do
		despawnBrainrot(brainrot)
	end
end

function ConveyorService.start()
	RunService.Heartbeat:Connect(function(deltaTime)
		ConveyorService.moveBrainrotsAlongConveyor(deltaTime)
	end)
	task.spawn(function()
		while true do
			task.wait(Config.SpawnIntervalSeconds)
			if countOnConveyor() < Config.MaxBrainrotsOnConveyor then
				ConveyorService.spawnBrainrotOnConveyor()
			end
		end
	end)
end

return ConveyorService
