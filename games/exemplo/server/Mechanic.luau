--!strict
-- Mecânica central do jogo de exemplo: clicar no botão dá moedas.
-- Em cada jogo novo, este é o arquivo que você troca.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage:WaitForChild("Game"):WaitForChild("Config"))
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local Services = ServerScriptService:WaitForChild("Server"):WaitForChild("Services")
local CurrencyService = require(Services:WaitForChild("CurrencyService"))

local Mechanic = {}

local lastClick: { [Player]: number } = {}

function Mechanic.start()
	Remotes.onServer("Click", 15, function(player: Player)
		local now = os.clock()
		if now - (lastClick[player] or 0) < Config.Click.CooldownSeconds then
			return
		end
		lastClick[player] = now
		CurrencyService.add(player, Config.Click.Reward)
	end)

	Players.PlayerRemoving:Connect(function(player)
		lastClick[player] = nil
	end)
end

return Mechanic
