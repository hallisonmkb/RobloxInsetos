--!strict
-- RemoteGuard: todos os RemoteEvents num só lugar, com limite de chamadas.
-- Servidor: Remotes.onServer("Nome", rateLimitPorSegundo, handler)
-- Cliente:  Remotes.get("Nome"):FireServer(...)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local FOLDER_NAME = "Remotes"

local Remotes = {}

local function getFolder(): Folder
	if RunService:IsServer() then
		local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = FOLDER_NAME
			folder.Parent = ReplicatedStorage
		end
		return folder :: Folder
	end
	return ReplicatedStorage:WaitForChild(FOLDER_NAME) :: Folder
end

function Remotes.get(name: string): RemoteEvent
	local folder = getFolder()
	if RunService:IsServer() then
		local remote = folder:FindFirstChild(name)
		if not remote then
			remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
		return remote :: RemoteEvent
	end
	return folder:WaitForChild(name) :: RemoteEvent
end

-- Registra um handler no servidor com limite de chamadas por jogador.
-- Chamadas acima do limite são ignoradas em silêncio.
function Remotes.onServer(name: string, maxPerSecond: number, handler: (Player, ...any) -> ())
	assert(RunService:IsServer(), "Remotes.onServer só roda no servidor")
	local remote = Remotes.get(name)
	local windows: { [Player]: { start: number, count: number } } = {}

	Players.PlayerRemoving:Connect(function(player)
		windows[player] = nil
	end)

	remote.OnServerEvent:Connect(function(player, ...)
		local now = os.clock()
		local w = windows[player]
		if not w or now - w.start >= 1 then
			w = { start = now, count = 0 }
			windows[player] = w
		end
		w.count += 1
		if w.count > maxPerSecond then
			return
		end
		local ok, err = pcall(handler, player, ...)
		if not ok then
			warn(`[Remotes] erro em {name} de {player.Name}: {err}`)
		end
	end)
end

return Remotes
