-- StealService.luau (ModuleScript, server)
-- Stealing, the genre's tension: a brainrot resting on someone else's base
-- carries a hold-to-steal prompt. A successful thief carries the catch above
-- their head, and it only becomes theirs when they reach their own base —
-- drop it in a slot there. A locked base refuses every thief, and the
-- krupuk wave can knock a carried brainrot out of a thief's hands.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local BaseService = require(script.Parent:WaitForChild("BaseService"))
local BrainrotFactory = require(script.Parent:WaitForChild("BrainrotFactory"))

local StealService = {}

local function toast(player, text)
	Remotes:WaitForChild("Toast"):FireClient(player, text)
end

local function sendState(player)
	local record = PlayerState.getPlayerRecord(player)
	if record then
		Remotes:WaitForChild("UpdateState"):FireClient(player, PlayerState.snapshotStateForClient(record))
	end
end

local function promptOf(brainrot)
	local body = brainrot.Model:FindFirstChild("Body")
	if not body then
		return nil
	end
	return body:FindFirstChild("Prompt")
end

-- Turn a brainrot's prompt back into a shop prompt (name, price, tap to
-- buy). Both prompt handlers stay connected for the brainrot's whole life
-- and guard on where the brainrot is, so flipping the text is safe.
local function resetPromptToBuy(brainrot)
	local prompt = promptOf(brainrot)
	if not prompt then
		return
	end
	prompt.ActionText = "Beli"
	prompt.ObjectText = brainrot.Definition.Name .. " — $" .. brainrot.Definition.Price
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = Config.BuyDistanceStuds
	prompt.Enabled = true
end

-- Once a brainrot rests on a base, its prompt stops selling and starts
-- tempting thieves: hold E for StealHoldSeconds to take it.
function StealService.attachStealPrompt(brainrot)
	local prompt = promptOf(brainrot)
	if not prompt then
		return
	end
	prompt.ActionText = "Curi"
	prompt.ObjectText = brainrot.Definition.Name
	prompt.HoldDuration = Config.StealHoldSeconds
	prompt.MaxActivationDistance = Config.StealDistanceStuds
	if prompt:GetAttribute("StealConnected") then
		return
	end
	prompt:SetAttribute("StealConnected", true)
	prompt.Triggered:Connect(function(thief)
		StealService.stealBrainrotFromBase(thief, brainrot.Id)
	end)
end

-- Take a brainrot off its owner's base and put it on the thief's head.
-- Validated on the server: the target must be resting, not the thief's own,
-- its base unlocked, and the thief needs empty hands and a free slot waiting
-- at home.
function StealService.stealBrainrotFromBase(thief, brainrotId)
	local thiefRecord = PlayerState.getPlayerRecord(thief)
	local brainrot = PlayerState.getBrainrotRecord(brainrotId)
	if not thiefRecord or not brainrot then
		return false
	end
	if brainrot.Where ~= "Base" or brainrot.Owner == nil then
		return false
	end
	if brainrot.Owner == thief then
		return false -- your own brainrot needs no stealing
	end
	if thiefRecord.CarryingId ~= nil then
		toast(thief, "Tangan penuh! Antar dulu yang kamu bawa")
		return false
	end
	if PlayerState.firstFreeSlotIndex(thiefRecord) == nil then
		toast(thief, "Base kamu penuh, tidak ada slot untuk hasil curian")
		return false
	end
	local ownerRecord = PlayerState.getPlayerRecord(brainrot.Owner)
	if ownerRecord and PlayerState.isBaseLocked(ownerRecord) then
		toast(thief, "Base ini sedang terkunci!")
		return false
	end

	if ownerRecord then
		BaseService.removeBrainrotFromBase(ownerRecord, brainrot)
		sendState(ownerRecord.Player)
	end
	brainrot.Where = "Carried"
	brainrot.Owner = nil
	thiefRecord.CarryingId = brainrotId
	local prompt = promptOf(brainrot)
	if prompt then
		prompt.Enabled = false
	end
	toast(thief, "Dapat! Bawa pulang ke base kamu!")
	sendState(thief)
	return true
end

-- Settle a carried brainrot onto the carrier's base: called when the
-- carrier walks onto their own plot with full hands.
function StealService.depositCarriedBrainrot(player)
	local record = PlayerState.getPlayerRecord(player)
	if not record or record.CarryingId == nil then
		return
	end
	local brainrot = PlayerState.getBrainrotRecord(record.CarryingId)
	record.CarryingId = nil
	if not brainrot then
		return
	end
	local slotIndex = PlayerState.firstFreeSlotIndex(record)
	if slotIndex == nil then
		-- No room after all: the catch slips away and is lost.
		brainrot.Model:Destroy()
		PlayerState.removeBrainrotRecord(brainrot.Id)
		toast(player, "Base penuh — hasil curian lepas!")
		sendState(player)
		return
	end
	BaseService.placeBrainrotOnBaseSlot(record, brainrot, slotIndex)
	local prompt = promptOf(brainrot)
	if prompt then
		prompt.Enabled = true
	end
	StealService.attachStealPrompt(brainrot)
	toast(player, brainrot.Definition.Name .. " hasil curian masuk base!")
	sendState(player)
end

-- Knock whatever a player is carrying out of the game (the krupuk wave does
-- this). The catch is lost for good, which is what makes the wave hurt.
function StealService.dropCarriedBrainrot(player)
	local record = PlayerState.getPlayerRecord(player)
	if not record or record.CarryingId == nil then
		return
	end
	local brainrot = PlayerState.getBrainrotRecord(record.CarryingId)
	record.CarryingId = nil
	if brainrot then
		brainrot.Model:Destroy()
		PlayerState.removeBrainrotRecord(brainrot.Id)
	end
	sendState(player)
end

-- A carrier who dies drops the catch back onto the conveyor where they
-- fell: it rejoins the belt at that spot and can be bought again.
function StealService.dropCarriedBrainrotToBelt(player)
	local record = PlayerState.getPlayerRecord(player)
	if not record or record.CarryingId == nil then
		return
	end
	local brainrot = PlayerState.getBrainrotRecord(record.CarryingId)
	record.CarryingId = nil
	if not brainrot then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local dropZ = root and root.Position.Z or 0
	brainrot.Where = "Conveyor"
	brainrot.ConveyorZ = math.clamp(dropZ, Config.ConveyorStartZ, Config.ConveyorEndZ)
	resetPromptToBuy(brainrot)
	sendState(player)
end

-- The carry loop: every frame, a carried brainrot rides above its carrier's
-- head, and stepping onto home ground deposits it. A carrier who dies drops
-- the catch back onto the belt.
function StealService.start()
	RunService.Heartbeat:Connect(function()
		local drops = {}
		for player, record in pairs(PlayerState.allPlayerRecords()) do
			if record.CarryingId ~= nil then
				local brainrot = PlayerState.getBrainrotRecord(record.CarryingId)
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				if brainrot and humanoid and humanoid.Health <= 0 then
					table.insert(drops, player)
				elseif brainrot and root then
					local carryPosition = root.Position + Vector3.new(0, Config.CarryRiseStuds + BrainrotFactory.halfBodyHeight(), 0)
					brainrot.Model:PivotTo(CFrame.new(carryPosition))
					if BaseService.isCharacterOnOwnBase(record) then
						StealService.depositCarriedBrainrot(player)
					end
				end
			end
		end
		for _, player in ipairs(drops) do
			StealService.dropCarriedBrainrotToBelt(player)
		end
	end)
end

return StealService
