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

-- Inimigos presos a uma zona. "Model" e "Zone" são os nomes no Workspace.
-- Cada inimigo anda só dentro da Part da zona e ataca quem estiver nela.
Config.Enemies = {
	{
		Model = "Fire Worker",
		Zone = "ZonaFormiga",
		Damage = 10, -- dano por ataque
		AttackRange = 5, -- distância para morder (studs)
		AttackCooldown = 1, -- segundos entre ataques
		ChaseSpeed = 14, -- velocidade perseguindo (studs/s)
		WanderSpeed = 5, -- velocidade passeando
		EdgeMargin = 2, -- distância mínima da borda da zona
		FacingOffset = 0, -- graus para girar o modelo se ele andar de lado/de costas
	},
}

return Config
