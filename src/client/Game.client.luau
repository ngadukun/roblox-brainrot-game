-- Game.client.luau (LocalScript, StarterPlayerScripts.Client.Game)
-- The client's bootstrap: build the HUD, send its button presses to the
-- server as remotes, and feed every server message (state snapshots, toasts,
-- the wave warning) into the HUD. The client decides nothing about money or
-- ownership; it only asks and displays.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Hud = require(script.Parent:WaitForChild("Hud"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local hud = Hud.build(playerGui, {
	onToggleLock = function()
		Remotes:WaitForChild("ToggleLock"):FireServer()
	end,
	onBuySlot = function()
		Remotes:WaitForChild("BuySlot"):FireServer()
	end,
	onRebirth = function()
		Remotes:WaitForChild("Rebirth"):FireServer()
	end,
})

Remotes:WaitForChild("UpdateState").OnClientEvent:Connect(function(snapshot)
	hud.updateState(snapshot)
end)

Remotes:WaitForChild("Toast").OnClientEvent:Connect(function(text)
	hud.showToast(text)
end)

Remotes:WaitForChild("WaveWarning").OnClientEvent:Connect(function(text, seconds)
	hud.showWaveWarning(text, seconds)
end)

-- A greeting once the HUD is up, so a first-time player knows the market
-- is open and where the game happens.
task.delay(1.5, function()
	hud.showToast("Selamat datang di Warung Brainrot! Beli brainrot di conveyor tengah")
end)
