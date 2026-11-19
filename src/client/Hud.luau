-- Hud.luau (ModuleScript, client)
-- Builds the Warung Brainrot screen: a money bar across the top centre, the
-- three action buttons along the bottom centre, a big centre banner for the
-- krupuk warning, a toast in the bottom right and a hint line. Nothing is
-- drawn in the top-left corner, where Roblox puts its own menu buttons.
--
-- The module only draws and reports button presses through the callbacks it
-- is built with; all numbers arrive from the server in state snapshots.

local Hud = {}

local function formatCash(amount)
	local digits = tostring(math.floor(amount))
	local grouped = digits
	while true do
		local replaced, count = string.gsub(grouped, "^(-?%d+)(%d%d%d)", "%1,%2")
		grouped = replaced
		if count == 0 then
			break
		end
	end
	return "$" .. grouped
end

local function makeLabel(parent, name, size, position, text, textSize, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Size = size
	label.Position = position
	label.Font = Enum.Font.GothamBold
	label.TextSize = textSize
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.4
	label.Parent = parent
	return label
end

local function makeButton(parent, name, size, position, text, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = color
	button.BackgroundTransparency = 0.15
	button.Font = Enum.Font.GothamBlack
	button.TextSize = 20
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.AutoButtonColor = true
	button.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button
	return button
end

-- Build the whole HUD into the player's GUI. Callbacks: onToggleLock,
-- onBuySlot, onRebirth — fired when the matching button is pressed.
function Hud.build(playerGui, callbacks)
	local gui = Instance.new("ScreenGui")
	gui.Name = "WarungHud"
	gui.ResetOnSpawn = false
	gui.Parent = playerGui

	local hud = {}

	-- Top centre money bar: cash, income rate, rebirth standing.
	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.AnchorPoint = Vector2.new(0.5, 0)
	topBar.Position = UDim2.new(0.5, 0, 0, 10)
	topBar.Size = UDim2.new(0, 620, 0, 58)
	topBar.BackgroundColor3 = Color3.fromRGB(16, 18, 34)
	topBar.BackgroundTransparency = 0.25
	topBar.Parent = gui
	local topCorner = Instance.new("UICorner")
	topCorner.CornerRadius = UDim.new(0, 12)
	topCorner.Parent = topBar

	hud.cashLabel = makeLabel(topBar, "Cash", UDim2.new(0.36, 0, 1, 0), UDim2.new(0, 12, 0, 0), "$150", 30, Color3.fromRGB(150, 255, 150))
	hud.cashLabel.TextXAlignment = Enum.TextXAlignment.Left
	hud.incomeLabel = makeLabel(topBar, "Income", UDim2.new(0.3, 0, 1, 0), UDim2.new(0.37, 0, 0, 0), "+$0/detik", 22, Color3.fromRGB(255, 240, 170))
	hud.rebirthLabel = makeLabel(topBar, "Rebirth", UDim2.new(0.3, 0, 1, 0), UDim2.new(0.68, 0, 0, 0), "Rebirth 0 · x1", 20, Color3.fromRGB(200, 170, 255))
	hud.rebirthLabel.TextXAlignment = Enum.TextXAlignment.Right

	-- Centre banner for the wave warning, hidden until the event calls.
	hud.bannerLabel = makeLabel(gui, "Banner", UDim2.new(0.8, 0, 0, 90), UDim2.new(0.1, 0, 0.3, 0), "", 44, Color3.fromRGB(255, 120, 90))
	hud.bannerLabel.Font = Enum.Font.GothamBlack
	hud.bannerLabel.Visible = false

	-- Bottom centre action buttons.
	local buttonBar = Instance.new("Frame")
	buttonBar.Name = "ButtonBar"
	buttonBar.AnchorPoint = Vector2.new(0.5, 1)
	buttonBar.Position = UDim2.new(0.5, 0, 1, -14)
	buttonBar.Size = UDim2.new(0, 620, 0, 56)
	buttonBar.BackgroundTransparency = 1
	buttonBar.Parent = gui

	hud.lockButton = makeButton(buttonBar, "LockButton", UDim2.new(0.32, 0, 1, 0), UDim2.new(0, 0, 0, 0), "KUNCI BASE", Color3.fromRGB(52, 96, 200))
	hud.slotButton = makeButton(buttonBar, "SlotButton", UDim2.new(0.32, 0, 1, 0), UDim2.new(0.34, 0, 0, 0), "BELI SLOT", Color3.fromRGB(38, 150, 84))
	hud.rebirthButton = makeButton(buttonBar, "RebirthButton", UDim2.new(0.32, 0, 1, 0), UDim2.new(0.68, 0, 0, 0), "REBIRTH", Color3.fromRGB(140, 70, 200))

	hud.lockButton.MouseButton1Click:Connect(callbacks.onToggleLock)
	hud.slotButton.MouseButton1Click:Connect(callbacks.onBuySlot)
	hud.rebirthButton.MouseButton1Click:Connect(callbacks.onRebirth)

	-- Hint line above the buttons, and the toast in the bottom right.
	hud.hintLabel = makeLabel(
		gui,
		"Hint",
		UDim2.new(0.7, 0, 0, 26),
		UDim2.new(0.15, 0, 1, -104),
		"Dekati brainrot di conveyor, tekan E untuk beli. Curi dari base lawan yang tidak terkunci!",
		17,
		Color3.fromRGB(230, 230, 230)
	)
	hud.toastLabel = makeLabel(gui, "Toast", UDim2.new(0.34, 0, 0, 30), UDim2.new(0.65, 0, 1, -140), "", 20, Color3.fromRGB(255, 255, 190))
	hud.toastLabel.TextXAlignment = Enum.TextXAlignment.Right

	hud.toastToken = 0
	hud.warningToken = 0

	-- Render one server snapshot: cash, income, rebirth standing, and the
	-- lock/slot buttons labelled with what they will do next.
	function hud.updateState(snapshot)
		hud.cashLabel.Text = formatCash(snapshot.Cash)
		hud.incomeLabel.Text = "+" .. formatCash(snapshot.IncomePerSecond) .. "/detik"
		hud.rebirthLabel.Text = "Rebirth " .. snapshot.Rebirths .. " · x" .. snapshot.Multiplier .. " · Base " .. snapshot.BaseBrainrots .. "/" .. snapshot.SlotCount
		if snapshot.IsLocked then
			hud.lockButton.Text = "TERKUNCI " .. snapshot.LockSecondsLeft .. "d"
		elseif snapshot.LockCooldownSecondsLeft > 0 then
			hud.lockButton.Text = "KUNCI (" .. snapshot.LockCooldownSecondsLeft .. "d)"
		else
			hud.lockButton.Text = "KUNCI BASE"
		end
		if snapshot.NextSlotPrice > 0 then
			hud.slotButton.Text = "BELI SLOT " .. formatCash(snapshot.NextSlotPrice)
		else
			hud.slotButton.Text = "SLOT PENUH"
		end
	end

	-- A short message in the bottom right; newer toasts replace older ones.
	function hud.showToast(text)
		hud.toastToken = hud.toastToken + 1
		local token = hud.toastToken
		hud.toastLabel.Text = text
		task.delay(3.2, function()
			if hud.toastToken == token then
				hud.toastLabel.Text = ""
			end
		end)
	end

	-- The wave banner, counting its warning seconds down in the open.
	function hud.showWaveWarning(text, seconds)
		hud.warningToken = hud.warningToken + 1
		local token = hud.warningToken
		hud.bannerLabel.Visible = true
		task.spawn(function()
			for remaining = seconds, 1, -1 do
				if hud.warningToken ~= token then
					return
				end
				hud.bannerLabel.Text = text .. "  " .. remaining
				task.wait(1)
			end
			if hud.warningToken == token then
				hud.bannerLabel.Visible = false
			end
		end)
	end

	return hud
end

return Hud
