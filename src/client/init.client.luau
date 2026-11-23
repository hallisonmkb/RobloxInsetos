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

-- Ecrã pisca a vermelho sempre que o jogador perde vida (qualquer dano, mesmo pequeno).
local TweenService = game:GetService("TweenService")

local hurtGui = Instance.new("ScreenGui")
hurtGui.Name = "DamageFlash"
hurtGui.ResetOnSpawn = false
hurtGui.IgnoreGuiInset = true -- cobre o ecrã todo, incluindo a barra de cima
hurtGui.DisplayOrder = -1 -- fica por baixo do HUD

local hurt = Instance.new("Frame")
hurt.Size = UDim2.fromScale(1, 1)
hurt.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
hurt.BackgroundTransparency = 1
hurt.BorderSizePixel = 0
hurt.Active = false
hurt.Parent = hurtGui
hurtGui.Parent = player:WaitForChild("PlayerGui")

local fade = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function watchCharacter(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	if not humanoid then
		return
	end
	local last = humanoid.Health
	humanoid.HealthChanged:Connect(function(health)
		if health < last then
			hurt.BackgroundTransparency = 0.55
			TweenService:Create(hurt, fade, { BackgroundTransparency = 1 }):Play()
		end
		last = health
	end)
end

player.CharacterAdded:Connect(watchCharacter)
if player.Character then
	task.spawn(watchCharacter, player.Character)
end

gui.Parent = player:WaitForChild("PlayerGui")
