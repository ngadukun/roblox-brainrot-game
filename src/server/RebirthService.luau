-- RebirthService.luau (ModuleScript, server)
-- Rebirth: once a player has earned RebirthThresholdEarned over their run,
-- they may burn it all down — brainrots gone, cash back to the starting
-- purse — for a permanent income multiplier that stacks with every rebirth.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local PlayerState = require(script.Parent:WaitForChild("PlayerState"))

local RebirthService = {}

local function toast(player, text)
	Remotes:WaitForChild("Toast"):FireClient(player, text)
end

local function sendState(player)
	local record = PlayerState.getPlayerRecord(player)
	if record then
		Remotes:WaitForChild("UpdateState"):FireClient(player, PlayerState.snapshotStateForClient(record))
	end
end

-- Burn the run down and raise the multiplier. Validated here: the earnings
-- threshold is checked against the server's own record, never the client's.
function RebirthService.rebirthForMultiplier(player)
	local record = PlayerState.getPlayerRecord(player)
	if not record then
		return false
	end
	if record.TotalEarned < Config.RebirthThresholdEarned then
		local missing = Config.RebirthThresholdEarned - record.TotalEarned
		toast(player, "Rebirth butuh total penghasilan $" .. Config.RebirthThresholdEarned .. " — kurang $" .. missing)
		return false
	end

	-- Everything on the base is sold back to the night.
	for slotIndex, brainrotId in pairs(record.Slots) do
		local brainrot = PlayerState.getBrainrotRecord(brainrotId)
		if brainrot then
			brainrot.Model:Destroy()
			PlayerState.removeBrainrotRecord(brainrotId)
		end
		record.Slots[slotIndex] = nil
	end
	if record.CarryingId ~= nil then
		local carried = PlayerState.getBrainrotRecord(record.CarryingId)
		if carried then
			carried.Model:Destroy()
			PlayerState.removeBrainrotRecord(record.CarryingId)
		end
		record.CarryingId = nil
	end

	record.Cash = Config.StartingCash
	record.TotalEarned = 0
	record.LockUntil = 0 -- a fresh run starts with a fresh lock, too
	record.LockCooldownUntil = 0
	record.Rebirths = record.Rebirths + 1
	record.Multiplier = 1 + record.Rebirths * Config.RebirthMultiplierStep

	toast(player, "REBIRTH! Penghasilan sekarang x" .. record.Multiplier)
	sendState(player)
	return true
end

return RebirthService
