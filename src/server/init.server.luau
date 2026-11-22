--!strict
-- Inicia os serviços do kit base e depois a mecânica do jogo.

local ServerScriptService = game:GetService("ServerScriptService")

local Services = script:WaitForChild("Services")

-- A ordem importa: quem depende de outro vem depois.
local ORDER = {
	"DataService",
	"CurrencyService",
}

for _, name in ORDER do
	local service = require(Services:WaitForChild(name)) :: any
	service.start()
end

local gameFolder = ServerScriptService:WaitForChild("Game")
local mechanic = require(gameFolder:WaitForChild("Mechanic")) :: any
mechanic.start()

print("[Kit base] servidor pronto")
