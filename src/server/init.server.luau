--!strict
-- Inicia os serviços do kit base e depois todos os módulos do jogo (pasta Game).

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

-- Cada ModuleScript em games/<jogo>/server com função start() é iniciado.
local gameFolder = ServerScriptService:WaitForChild("Game")
for _, module in gameFolder:GetChildren() do
	if module:IsA("ModuleScript") then
		local ok, err = pcall(function()
			local m = require(module) :: any
			if type(m) == "table" and type(m.start) == "function" then
				m.start()
			end
		end)
		if not ok then
			warn(`[Kit base] erro ao iniciar {module.Name}: {err}`)
		end
	end
end

print("[Kit base] servidor pronto")
