-- BaseService.luau (ModuleScript, server)
-- Owns the four base plots: deals them to joining players, knows where each
-- slot pad stands, paints pads a player has not bought yet as ghost pads,
-- runs the base lock with its cooldown, and sells extra slots.
--
-- The plots themselves are static parts in Workspace.Bases (Base1..Base4,
-- each with a Plot part and Slot1..Slot10 pads) laid out by the Rojo
-- project; this service only reads their positions and restyles them.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local BrainrotFactory = require(script.Parent:WaitForChild("BrainrotFactory"))

local BaseService = {}

local baseOwners = {} -- [base index] = Player

local function toast(player, text)
	Remotes:WaitForChild("Toast"):FireClient(player, text)
end

local function sendState(player)
	local record = PlayerState.getPlayerRecord(player)
	if record then
		Remotes:WaitForChild("UpdateState"):FireClient(player, PlayerState.snapshotStateForClient(record))
	end
end

local function baseFolder(baseIndex)
	local bases = Workspace:WaitForChild("Bases")
	return bases:WaitForChild("Base" .. baseIndex)
end

function BaseService.getSlotPad(baseIndex, slotIndex)
	return baseFolder(baseIndex):WaitForChild("Slot" .. slotIndex)
end

-- Where a brainrot stands when it rests on a slot: on top of the pad, its
-- pivot half a body height above the pad's top face.
function BaseService.getSlotCFrame(baseIndex, slotIndex)
	local pad = BaseService.getSlotPad(baseIndex, slotIndex)
	local topY = pad.Position.Y + pad.Size.Y / 2 + BrainrotFactory.halfBodyHeight()
	return CFrame.new(pad.Position.X, topY, pad.Position.Z)
end

-- Pads the player has not bought are shown ghosted, so the base reads as
-- "room to grow" in the world and in screenshots; the next free pad they do
-- own glows, pointing at where the next catch will land.
function BaseService.refreshSlotPadVisuals(record)
	local nextFree = PlayerState.firstFreeSlotIndex(record)
	for slotIndex = 1, Config.MaxSlots do
		local pad = BaseService.getSlotPad(record.BaseIndex, slotIndex)
		if slotIndex > record.SlotCount then
			pad.Transparency = 0.65
			pad.Material = Enum.Material.SmoothPlastic
		else
			pad.Transparency = 0
			if slotIndex == nextFree then
				pad.Material = Enum.Material.Neon
			else
				pad.Material = Enum.Material.SmoothPlastic
			end
		end
	end
end

-- Put a brainrot onto a base slot: ownership, slot bookkeeping and the
-- model's resting place all change together here.
function BaseService.placeBrainrotOnBaseSlot(record, brainrot, slotIndex)
	record.Slots[slotIndex] = brainrot.Id
	brainrot.Owner = record.Player
	brainrot.Where = "Base"
	brainrot.SlotIndex = slotIndex
	brainrot.Model:PivotTo(BaseService.getSlotCFrame(record.BaseIndex, slotIndex))
	BaseService.refreshSlotPadVisuals(record)
end

function BaseService.removeBrainrotFromBase(record, brainrot)
	if brainrot.SlotIndex and record.Slots[brainrot.SlotIndex] == brainrot.Id then
		record.Slots[brainrot.SlotIndex] = nil
	end
	brainrot.SlotIndex = nil
	brainrot.Owner = nil
	BaseService.refreshSlotPadVisuals(record)
end

-- True when the player's character stands on their own plot, which is what
-- keeps them safe from the krupuk wave and lets a carried brainrot deposit.
function BaseService.isCharacterOnOwnBase(record)
	local character = record.Player.Character
	if not character then
		return false
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local plot = baseFolder(record.BaseIndex):WaitForChild("Plot")
	local dx = math.abs(root.Position.X - plot.Position.X)
	local dz = math.abs(root.Position.Z - plot.Position.Z)
	return dx <= plot.Size.X / 2 and dz <= plot.Size.Z / 2
end

-- Player lifecycle -----------------------------------------------------------

function BaseService.onPlayerJoined(player)
	local baseIndex = nil
	for candidate = 1, Config.BaseCount do
		if baseOwners[candidate] == nil then
			baseIndex = candidate
			break
		end
	end
	if baseIndex == nil then
		baseIndex = (Players.NumPlayers % Config.BaseCount) + 1 -- full house: share the next plot in turn
	end
	baseOwners[baseIndex] = player
	local record = PlayerState.registerPlayer(player, baseIndex)
	BaseService.refreshSlotPadVisuals(record)
	return record
end

function BaseService.onPlayerLeft(player)
	local record = PlayerState.getPlayerRecord(player)
	if not record then
		return
	end
	if baseOwners[record.BaseIndex] == player then
		baseOwners[record.BaseIndex] = nil
	end
	-- Everything the player owned leaves the world with them.
	for _, brainrotId in pairs(record.Slots) do
		local brainrot = PlayerState.getBrainrotRecord(brainrotId)
		if brainrot then
			brainrot.Model:Destroy()
			PlayerState.removeBrainrotRecord(brainrotId)
		end
	end
	if record.CarryingId then
		local carried = PlayerState.getBrainrotRecord(record.CarryingId)
		if carried then
			carried.Model:Destroy()
			PlayerState.removeBrainrotRecord(record.CarryingId)
		end
	end
	PlayerState.removePlayer(player)
end

-- Remote actions ---------------------------------------------------------------

-- ToggleLock: lock the caller's base for LockDurationSeconds, then make them
-- wait out LockCooldownSeconds before locking again.
function BaseService.lockBaseWithCooldown(player)
	local record = PlayerState.getPlayerRecord(player)
	if not record then
		return
	end
	local now = os.clock()
	if now < record.LockCooldownUntil then
		local waitSeconds = math.ceil(record.LockCooldownUntil - now)
		toast(player, "Kunci base masih cooldown " .. waitSeconds .. " detik")
		return
	end
	record.LockUntil = now + Config.LockDurationSeconds
	record.LockCooldownUntil = now + Config.LockCooldownSeconds
	BaseService.setLockSignText(record.BaseIndex, "TERKUNCI!")
	task.delay(Config.LockDurationSeconds, function()
		BaseService.setLockSignText(record.BaseIndex, "")
	end)
	toast(player, "Base terkunci " .. Config.LockDurationSeconds .. " detik")
	sendState(player)
end

-- The lock line lives on the base's sign board, built by WorldBuilder; if the
-- board is not there the lock still works, it just shows nothing.
function BaseService.setLockSignText(baseIndex, text)
	local decorations = Workspace:FindFirstChild("Decorations")
	if not decorations then
		return
	end
	local sign = decorations:FindFirstChild("BaseSign" .. baseIndex)
	if not sign then
		return
	end
	local board = sign:FindFirstChild("Board")
	if not board then
		return
	end
	local gui = board:FindFirstChild("SignGui")
	if not gui then
		return
	end
	local lockLine = gui:FindFirstChild("LockLine")
	if lockLine then
		lockLine.Text = text
	end
end

-- BuySlot: sell the caller their next slot at the doubling price.
function BaseService.buyExtraSlot(player)
	local record = PlayerState.getPlayerRecord(player)
	if not record then
		return
	end
	if record.SlotCount >= Config.MaxSlots then
		toast(player, "Slot base sudah maksimum")
		return
	end
	local price = PlayerState.priceOfNextSlot(record)
	if record.Cash < price then
		toast(player, "Uang belum cukup untuk slot: butuh $" .. price)
		return
	end
	record.Cash = record.Cash - price
	record.SlotCount = record.SlotCount + 1
	BaseService.refreshSlotPadVisuals(record)
	toast(player, "Slot baru terbeli! Sekarang " .. record.SlotCount .. " slot")
	sendState(player)
end

return BaseService
