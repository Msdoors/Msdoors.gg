local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local nameUI = playerGui:FindFirstChild("NameUI" .. player.Name)

local LOBBY_TEXT = "MSDOORS LOBBY"

local function randomColor()
	return Color3.new(math.random(), math.random(), math.random())
end

local function tween(obj, duration, props)
	TweenService:Create(obj, TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), props):Play()
end

local function animateGradient(gradient)
	task.spawn(function()
		while true do
			tween(gradient, 1, { Rotation = gradient.Rotation + 180 })
			task.wait(1)
		end
	end)
end

if not nameUI then
	warn("NameUI do jogador " .. player.Name .. " não encontrado!")
	return
end

local usernameLabel = nameUI:FindFirstChild("Username")
if usernameLabel then
	local gradient = Instance.new("UIGradient", usernameLabel)
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(1, Color3.new(0, 0.5, 1))
	})
	animateGradient(gradient)

	task.spawn(function()
		local fullName = "[MS]" .. player.Name
		local frames = {}
		for i = 1, #fullName do table.insert(frames, fullName:sub(1, i) .. "_") end
		for i = #fullName, 1, -1 do table.insert(frames, fullName:sub(1, i) .. "_") end
		while true do
			for _, frame in ipairs(frames) do
				usernameLabel.Text = frame
				tween(usernameLabel, 0.2, { TextColor3 = randomColor() })
				task.wait(0.2)
			end
		end
	end)
end

local function applyVisuals()
	local stuff = nameUI:FindFirstChild("Stuff")
	local frame = stuff and stuff:FindFirstChild("Frame")
	if not frame then return end

	local textBadge = frame:FindFirstChild("TextBadge")
	if textBadge then
		textBadge.Text = "msdoors"
		textBadge.TextColor3 = Color3.fromRGB(0, 255, 255)
		local bg = textBadge:FindFirstChild("UIGradient") or Instance.new("UIGradient", textBadge)
		task.spawn(function()
			while true do
				tween(bg, 1, {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, randomColor()),
						ColorSequenceKeypoint.new(1, randomColor())
					})
				})
				task.wait(1)
			end
		end)
	end

	local iconBadge = frame:FindFirstChild("IconBadge")
	if iconBadge then iconBadge.Image = "rbxassetid://100573561401335" end

	local textDeaths = frame:FindFirstChild("TextDeaths")
	if textDeaths then
		textDeaths.Text = LOBBY_TEXT
		textDeaths.TextColor3 = Color3.fromRGB(0, 255, 255)
	end

	local escapesHolder = frame:FindFirstChild("IconEscapesHolder")
	local deathHolder = frame:FindFirstChild("IconDeathHolder")
	if escapesHolder and deathHolder then
		escapesHolder.Visible = true
		deathHolder.Visible = false
	end
end

applyVisuals()

local textDeaths = nameUI:FindFirstChild("Stuff") and nameUI.Stuff.Frame:FindFirstChild("TextDeaths")
if textDeaths then
	task.spawn(function()
		while true do
			if textDeaths.Text ~= LOBBY_TEXT then applyVisuals() end
			task.wait(0.5)
		end
	end)
end
