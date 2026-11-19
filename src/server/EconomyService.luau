-- EconomyService.luau (ModuleScript, server)
-- The money: a one-second tick that pays every player the income of the
-- brainrots resting on their base, and the purchase that moves a brainrot
-- from the conveyor onto a buyer's base. Every purchase is validated here on
-- the server — cash, a free slot, the brainrot still being on the belt and
-- the buyer standing close — never trusted from the client.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local BaseService = require(script.Parent:WaitForChild("BaseService"))
local StealService = require(script.Parent:WaitForChild("StealService"))

local EconomyService = {}

local function toast(player, text)
	Remotes:WaitForChild("Toast"):FireClient(player, text)
end

function EconomyService.sendStateToClient(player)
	local record = PlayerState.getPlayerRecord(player)
	if record then
		Remotes:WaitForChild("UpdateState"):FireClient(player, PlayerState.snapshotStateForClient(record))
	end
end

local function distanceBetween(a, b)
	return (a - b).Magnitude
end

-- Buy the brainrot a player just prompted on the conveyor. Returns true when
-- the sale went through; every refusal tells the buyer why by toast.
function EconomyService.buyBrainrotFromConveyor(player, brainrotId)
	local record = PlayerState.getPlayerRecord(player)
	local brainrot = PlayerState.getBrainrotRecord(brainrotId)
	if not record or not brainrot then
		return false
	end
	if brainrot.Where ~= "Conveyor" then
		return false -- someone else bought it first
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local brainrotPosition = brainrot.Model:GetPivot().Position
	if distanceBetween(root.Position, brainrotPosition) > Config.BuyDistanceStuds then
		toast(player, "Terlalu jauh dari brainrot")
		return false
	end
	local slotIndex = PlayerState.firstFreeSlotIndex(record)
	if slotIndex == nil then
		toast(player, "Base penuh! Beli slot atau rebirth dulu")
		return false
	end
	local price = brainrot.Definition.Price
	if record.Cash < price then
		toast(player, "Uang belum cukup: butuh $" .. price)
		return false
	end

	record.Cash = record.Cash - price
	BaseService.placeBrainrotOnBaseSlot(record, brainrot, slotIndex)
	StealService.attachStealPrompt(brainrot)
	toast(player, brainrot.Definition.Name .. " sekarang di base kamu!")
	if PlayerState.firstFreeSlotIndex(record) == nil then
		toast(player, "Base penuh — beli slot lagi atau rebirth untuk lanjut")
	end
	EconomyService.sendStateToClient(player)
	return true
end

-- The income tick: every TickSeconds, pay each player their base's income
-- and push the fresh numbers to their HUD.
function EconomyService.tickIncomePerSecond()
	for player, record in pairs(PlayerState.allPlayerRecords()) do
		local income = PlayerState.computeIncomePerSecond(record)
		if income > 0 then
			record.Cash = record.Cash + income
			record.TotalEarned = record.TotalEarned + income
		end
		EconomyService.sendStateToClient(player)
	end
end

function EconomyService.start()
	task.spawn(function()
		while true do
			task.wait(Config.TickSeconds)
			EconomyService.tickIncomePerSecond()
		end
	end)
end

return EconomyService
