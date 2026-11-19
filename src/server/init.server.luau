-- init.server.luau (Script, ServerScriptService.Server)
-- Bootstrap for Warung Brainrot: build the market's decorations, wire the
-- player lifecycle to the base service, connect the client remotes to the
-- services that answer them, then start the loops (income tick, conveyor,
-- stealing, the krupuk wave timer).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerState = require(script:WaitForChild("PlayerState"))
local BaseService = require(script:WaitForChild("BaseService"))
local EconomyService = require(script:WaitForChild("EconomyService"))
local ConveyorService = require(script:WaitForChild("ConveyorService"))
local StealService = require(script:WaitForChild("StealService"))
local EventService = require(script:WaitForChild("EventService"))
local RebirthService = require(script:WaitForChild("RebirthService"))
local WorldBuilder = require(script:WaitForChild("WorldBuilder"))
require(script:WaitForChild("TourHelper")) -- loaded so TOUR.json can call it

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

WorldBuilder.buildNightMarketDecorations()

Players.PlayerAdded:Connect(function(player)
	local record = BaseService.onPlayerJoined(player)
	-- Send the opening numbers once the client has had a moment to build
	-- its HUD, so the first frame already shows the starting purse.
	task.delay(1, function()
		if PlayerState.getPlayerRecord(player) == record then
			EconomyService.sendStateToClient(player)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	BaseService.onPlayerLeft(player)
end)

Remotes:WaitForChild("ToggleLock").OnServerEvent:Connect(function(player)
	BaseService.lockBaseWithCooldown(player)
end)

Remotes:WaitForChild("BuySlot").OnServerEvent:Connect(function(player)
	BaseService.buyExtraSlot(player)
end)

Remotes:WaitForChild("Rebirth").OnServerEvent:Connect(function(player)
	RebirthService.rebirthForMultiplier(player)
end)

-- Start each loop guarded: one service failing must not silence the rest
-- of the market, and the warning names the one that broke.
local function startService(name, start)
	local ok, err = pcall(start)
	if not ok then
		warn("Warung Brainrot: " .. name .. " failed to start: " .. tostring(err))
	end
end

startService("EconomyService", EconomyService.start)
startService("ConveyorService", ConveyorService.start)
startService("StealService", StealService.start)
startService("EventService", EventService.start)
