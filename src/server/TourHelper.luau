-- TourHelper.luau (ModuleScript, server)
-- Reviewer shortcuts named by TOUR.json: each function brings the live game
-- to one of the screenshot moments — money to spend, a star on the conveyor,
-- a stocked base, the krupuk wave — without playing the whole ladder first.
-- These are plain functions on a ModuleScript; TOUR.json calls them by name.

local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local ConveyorService = require(script.Parent:WaitForChild("ConveyorService"))
local EventService = require(script.Parent:WaitForChild("EventService"))
local EconomyService = require(script.Parent:WaitForChild("EconomyService"))

local TourHelper = {}

local function firstPlayerRecord()
	for player, record in pairs(PlayerState.allPlayerRecords()) do
		return player, record
	end
	return nil, nil
end

-- Hand the first player a pile of cash (and count it as earned, so the
-- rebirth threshold is within reach too).
function TourHelper.grantCash(amount)
	local player, record = firstPlayerRecord()
	if not record then
		return
	end
	record.Cash = record.Cash + amount
	record.TotalEarned = record.TotalEarned + amount
	EconomyService.sendStateToClient(player)
end

-- Put a named cast member on the conveyor right now, e.g. "Garuda Emas".
function TourHelper.spawnBrainrot(name)
	return ConveyorService.spawnNamedBrainrot(name)
end

-- Stock the belt with a random crowd, so the market looks alive at once.
function TourHelper.fillConveyor()
	for _ = 1, 4 do
		ConveyorService.spawnBrainrotOnConveyor()
	end
end

-- Start the Hujan Krupuk at once instead of waiting out the interval.
function TourHelper.triggerWave()
	EventService.triggerKrupukWave()
end

return TourHelper
