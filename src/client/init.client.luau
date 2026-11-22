--!strict
-- Cliente: só mostra a interface e pede coisas ao servidor.
-- Interface provisória do jogo de exemplo; o UI Kit vem depois.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local Config = require(ReplicatedStorage:WaitForChild("Game"):WaitForChild("Config"))

local player = Players.LocalPlayer
local clickRemote = Remotes.get("Click")

local gui = Instance.new("ScreenGui")
gui.Name = "HUD"
gui.ResetOnSpawn = false

local coins = Instance.new("TextLabel")
coins.Size = UDim2.fromOffset(260, 50)
coins.Position = UDim2.new(0.5, -130, 0, 20)
coins.BackgroundTransparency = 0.3
coins.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
coins.TextColor3 = Color3.fromRGB(255, 220, 80)
coins.TextScaled = true
coins.Font = Enum.Font.GothamBold
coins.Parent = gui

local button = Instance.new("TextButton")
button.Size = UDim2.fromOffset(220, 90)
button.Position = UDim2.new(0.5, -110, 1, -130)
button.BackgroundColor3 = Color3.fromRGB(60, 170, 90)
button.TextColor3 = Color3.new(1, 1, 1)
button.TextScaled = true
button.Font = Enum.Font.GothamBold
button.Text = "Clique!"
button.Parent = gui

for _, element in { coins, button } do
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = element
end

local function refresh()
	local value = player:GetAttribute("Coins")
	coins.Text = `{Config.Currency.Name}: {value or "..."}`
end

player:GetAttributeChangedSignal("Coins"):Connect(refresh)
refresh()

button.Activated:Connect(function()
	clickRemote:FireServer()
end)

gui.Parent = player:WaitForChild("PlayerGui")
