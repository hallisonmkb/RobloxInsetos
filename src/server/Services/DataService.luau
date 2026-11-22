--!strict
-- DataService: salva e carrega o perfil de cada jogador.
-- - Trava de sessão: o mesmo jogador não é carregado em dois servidores ao mesmo tempo
--   (evita duplicar itens trocando de servidor rápido).
-- - Autosave a cada 60 s, ao sair e ao desligar o servidor.
-- - Campos novos da Config.DefaultData são adicionados aos perfis antigos.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Game"):WaitForChild("Config"))

local STORE_NAME = "PlayerData_v1"
local AUTOSAVE_INTERVAL = 60
local LOCK_EXPIRE_SECONDS = 30 * 60 -- trava mais velha que isso é considerada abandonada
local LOAD_ATTEMPTS = 6
local RETRY_DELAY = 5

type Data = { [string]: any }
type Record = { Data: Data, Session: { JobId: string, Time: number }? }

local DataService = {}

local store = DataStoreService:GetDataStore(STORE_NAME)
local profiles: { [Player]: Data } = {}
local loadedEvent = Instance.new("BindableEvent")
DataService.Loaded = loadedEvent.Event -- (player, data)
local beforeRelease: { (Player, Data) -> () } = {}

local jobId = if game.JobId ~= "" then game.JobId else "studio"

local function keyFor(player: Player): string
	return `u_{player.UserId}`
end

local function deepCopy<T>(value: T): T
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for k, v in value :: any do
		copy[k] = deepCopy(v)
	end
	return copy :: any
end

local function reconcile(data: Data, template: Data)
	for k, v in template do
		if data[k] == nil then
			data[k] = deepCopy(v)
		elseif type(v) == "table" and type(data[k]) == "table" then
			reconcile(data[k], v)
		end
	end
end

local function tryLoad(player: Player, forceSteal: boolean): (boolean, Data?)
	local result: Data? = nil
	local ok, err = pcall(function()
		store:UpdateAsync(keyFor(player), function(old: Record?)
			local record: Record = old or { Data = deepCopy(Config.DefaultData) }
			local session = record.Session
			local lockedElsewhere = session ~= nil
				and session.JobId ~= jobId
				and os.time() - session.Time < LOCK_EXPIRE_SECONDS
			if lockedElsewhere and not forceSteal then
				result = nil
				return nil -- não grava nada; tenta de novo depois
			end
			record.Session = { JobId = jobId, Time = os.time() }
			result = record.Data
			return record
		end)
	end)
	if not ok then
		warn(`[DataService] falha ao carregar {player.Name}: {err}`)
		return false, nil
	end
	return true, result
end

local function save(player: Player, data: Data, release: boolean): boolean
	local ok, err = pcall(function()
		store:UpdateAsync(keyFor(player), function(old: Record?)
			if old and old.Session and old.Session.JobId ~= jobId then
				return nil -- outro servidor assumiu; não sobrescreve
			end
			return {
				Data = data,
				Session = if release then nil else { JobId = jobId, Time = os.time() },
			}
		end)
	end)
	if not ok then
		warn(`[DataService] falha ao salvar {player.Name}: {err}`)
	end
	return ok
end

local function onPlayerAdded(player: Player)
	local data: Data? = nil
	for attempt = 1, LOAD_ATTEMPTS do
		local ok, loaded = tryLoad(player, attempt == LOAD_ATTEMPTS)
		if ok and loaded then
			data = loaded
			break
		end
		if not player.Parent then
			return
		end
		task.wait(RETRY_DELAY)
	end

	if not data then
		player:Kick("Não foi possível carregar seus dados. Tente entrar de novo.")
		return
	end
	if not player.Parent then
		save(player, data, true) -- saiu durante o carregamento: libera a trava
		return
	end

	reconcile(data, Config.DefaultData)
	profiles[player] = data
	loadedEvent:Fire(player, data)
end

local function onPlayerRemoving(player: Player)
	local data = profiles[player]
	if not data then
		return
	end
	for _, callback in beforeRelease do
		local ok, err = pcall(callback, player, data)
		if not ok then
			warn(`[DataService] erro antes de salvar {player.Name}: {err}`)
		end
	end
	save(player, data, true)
	profiles[player] = nil
end

-- Retorna o perfil se já carregou (ou nil).
function DataService.get(player: Player): Data?
	return profiles[player]
end

-- Roda antes do último save do jogador (ao sair). Use para gravar o horário de saída etc.
function DataService.onBeforeRelease(callback: (Player, Data) -> ())
	table.insert(beforeRelease, callback)
end

-- Espera o perfil carregar (ou o jogador sair).
function DataService.waitFor(player: Player): Data?
	while player.Parent and not profiles[player] do
		task.wait()
	end
	return profiles[player]
end

function DataService.start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)
			for player, data in profiles do
				task.spawn(save, player, data, false)
			end
		end
	end)

	game:BindToClose(function()
		-- Salva todos (com os ganchos) e espera terminar antes de o servidor fechar.
		for player in profiles do
			task.spawn(onPlayerRemoving, player)
		end
		while next(profiles) ~= nil do
			task.wait()
		end
	end)
end

return DataService
