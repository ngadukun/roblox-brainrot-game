-- PlayerState.luau (ModuleScript, server)
-- The single store for all live game state. Every service reads and writes
-- player progress and brainrot ownership through here, so there is exactly
-- one answer to "who owns what, and how much money does everyone have".
--
-- A player record holds cash, lifetime earnings, rebirth count and income
-- multiplier, the base plot they were dealt, their slot table (slot index ->
-- brainrot id), their lock timers and the brainrot they are carrying.
-- A brainrot record holds its definition, its mutation, its income rate, its
-- model, its owner (nil while it rides the conveyor), where it is
-- ("Conveyor", "Base" or "Carried"), its slot and its conveyor position.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local PlayerState = {}

local playerRecords = {} -- [Player] = player record
local brainrotRecords = {} -- [brainrot id] = brainrot record
local nextBrainrotId = 0

-- Players -----------------------------------------------------------------

function PlayerState.registerPlayer(player, baseIndex)
	local record = {
		Player = player,
		Cash = Config.StartingCash,
		TotalEarned = 0,
		Rebirths = 0,
		Multiplier = 1,
		BaseIndex = baseIndex,
		Slots = {}, -- [slot index] = brainrot id
		SlotCount = Config.StartingSlots,
		LockUntil = 0,
		LockCooldownUntil = 0,
		CarryingId = nil,
	}
	playerRecords[player] = record
	return record
end

function PlayerState.getPlayerRecord(player)
	return playerRecords[player]
end

function PlayerState.removePlayer(player)
	playerRecords[player] = nil
end

function PlayerState.allPlayerRecords()
	return playerRecords
end

-- Brainrots ---------------------------------------------------------------

function PlayerState.addBrainrotRecord(def, mutationName, rate, model)
	nextBrainrotId = nextBrainrotId + 1
	local record = {
		Id = nextBrainrotId,
		Definition = def,
		Mutation = mutationName,
		IncomePerSecond = rate,
		Model = model,
		Owner = nil,
		Where = "Conveyor",
		SlotIndex = nil,
		ConveyorZ = Config.ConveyorStartZ,
		SpawnedAt = os.clock(), -- the conveyor's walk bob is phased from this
	}
	brainrotRecords[record.Id] = record
	return record
end

function PlayerState.getBrainrotRecord(id)
	return brainrotRecords[id]
end

function PlayerState.removeBrainrotRecord(id)
	brainrotRecords[id] = nil
end

function PlayerState.allBrainrotRecords()
	return brainrotRecords
end

-- Derived answers -----------------------------------------------------------

-- Income is the sum of the rates of the brainrots resting on the player's
-- base, scaled by their rebirth multiplier.
function PlayerState.computeIncomePerSecond(record)
	local sum = 0
	for _, brainrotId in pairs(record.Slots) do
		local brainrot = brainrotRecords[brainrotId]
		if brainrot then
			sum = sum + brainrot.IncomePerSecond
		end
	end
	return math.floor(sum * record.Multiplier)
end

function PlayerState.firstFreeSlotIndex(record)
	for slotIndex = 1, record.SlotCount do
		if record.Slots[slotIndex] == nil then
			return slotIndex
		end
	end
	return nil
end

function PlayerState.countBrainrotsOnBase(record)
	local count = 0
	for _ in pairs(record.Slots) do
		count = count + 1
	end
	return count
end

function PlayerState.isBaseLocked(record)
	return os.clock() < record.LockUntil
end

-- Price of the next slot upgrade: the first extra slot costs
-- FirstExtraSlotPrice and every further one doubles.
function PlayerState.priceOfNextSlot(record)
	local extrasBought = record.SlotCount - Config.StartingSlots
	return Config.FirstExtraSlotPrice * (2 ^ extrasBought)
end

-- The snapshot the client HUD renders from, built in this one place so every
-- service that changes state sends the exact same shape.
function PlayerState.snapshotStateForClient(record)
	local now = os.clock()
	local snapshot = {
		Cash = record.Cash,
		BaseIndex = record.BaseIndex,
		IncomePerSecond = PlayerState.computeIncomePerSecond(record),
		Rebirths = record.Rebirths,
		Multiplier = record.Multiplier,
		BaseBrainrots = PlayerState.countBrainrotsOnBase(record),
		SlotCount = record.SlotCount,
		NextSlotPrice = 0,
		IsLocked = now < record.LockUntil,
		LockSecondsLeft = math.max(0, math.ceil(record.LockUntil - now)),
		LockCooldownSecondsLeft = math.max(0, math.ceil(record.LockCooldownUntil - now)),
		IsCarrying = record.CarryingId ~= nil,
	}
	if record.SlotCount < Config.MaxSlots then
		snapshot.NextSlotPrice = PlayerState.priceOfNextSlot(record)
	end
	return snapshot
end

return PlayerState
