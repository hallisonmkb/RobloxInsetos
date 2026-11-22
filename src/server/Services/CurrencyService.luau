--!strict
-- CurrencyService: moedas, multiplicador e renda offline. Tudo decidido no servidor.
-- O cliente só lê o atributo "Coins" do jogador (e a leaderstats).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Game"):WaitForChild("Config"))
local DataService = require(script.Parent.DataService)

local CurrencyService = {}

local multipliers: { [Player]: number } = {}

local function publish(player: Player, data: { [string]: any })
	player:SetAttribute("Coins", data.Coins)
	local leaderstats = player:FindFirstChild("leaderstats")
	local value = leaderstats and leaderstats:FindFirstChild(Config.Currency.Name)
	if value then
		(value :: IntValue).Value = data.Coins
	end
end

function CurrencyService.getMultiplier(player: Player): number
	return multipliers[player] or Config.Currency.StartingMultiplier
end

-- Outros serviços (game passes, rebirth) ajustam o multiplicador por aqui.
function CurrencyService.setMultiplier(player: Player, value: number)
	multipliers[player] = value
end

-- Dá moedas aplicando o multiplicador. Retorna quanto foi dado de fato.
function CurrencyService.add(player: Player, baseAmount: number, ignoreMultiplier: boolean?): number
	local data = DataService.get(player)
	if not data or baseAmount <= 0 then
		return 0
	end
	local amount = if ignoreMultiplier then baseAmount else baseAmount * CurrencyService.getMultiplier(player)
	amount = math.floor(amount)
	data.Coins += amount
	data.TotalCoinsEarned += amount
	publish(player, data)
	return amount
end

-- Tenta gastar. Retorna false se não tiver saldo.
function CurrencyService.spend(player: Player, amount: number): boolean
	local data = DataService.get(player)
	if not data or amount < 0 or data.Coins < amount then
		return false
	end
	data.Coins -= amount
	publish(player, data)
	return true
end

function CurrencyService.get(player: Player): number
	local data = DataService.get(player)
	return if data then data.Coins else 0
end

function CurrencyService.start()
	DataService.Loaded:Connect(function(player: Player, data)
		local leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		local value = Instance.new("IntValue")
		value.Name = Config.Currency.Name
		value.Parent = leaderstats
		leaderstats.Parent = player

		-- Renda offline
		local now = os.time()
		if data.LastLogin > 0 and Config.Currency.OfflinePerSecond > 0 then
			local seconds = math.clamp(now - data.LastLogin, 0, Config.Currency.MaxOfflineSeconds)
			CurrencyService.add(player, seconds * Config.Currency.OfflinePerSecond, true)
		end
		data.LastLogin = now
		publish(player, data)
	end)

	DataService.onBeforeRelease(function(_player, data)
		data.LastLogin = os.time()
	end)

	Players.PlayerRemoving:Connect(function(player)
		multipliers[player] = nil
	end)
end

return CurrencyService
