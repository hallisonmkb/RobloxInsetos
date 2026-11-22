--!strict
-- Configuração do jogo. Balanceie aqui, sem mexer no código dos serviços.

local Config = {}

Config.GameName = "Exemplo"

-- Dados iniciais de todo jogador novo. Campos novos aparecem
-- automaticamente para jogadores antigos (o DataService completa).
Config.DefaultData = {
	Coins = 0,
	TotalCoinsEarned = 0,
	Level = 1,
	XP = 0,
	Rebirths = 0,
	LastLogin = 0,
	DailyStreak = 0,
}

Config.Currency = {
	Name = "Moedas",
	StartingMultiplier = 1,
	OfflinePerSecond = 0, -- renda offline por segundo (0 = desligada)
	MaxOfflineSeconds = 8 * 60 * 60, -- limite de 8 h de renda offline
}

-- Mecânica de exemplo: clicar dá moedas.
Config.Click = {
	Reward = 1,
	CooldownSeconds = 0.15,
}

return Config
