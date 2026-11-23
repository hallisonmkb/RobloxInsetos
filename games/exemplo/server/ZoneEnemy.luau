--!strict
-- Inimigo preso a uma zona: passeia dentro da Part da zona e persegue/ataca
-- qualquer jogador que entrar nela. Funciona com qualquer modelo (não precisa de Humanoid):
-- o modelo é ancorado e movido pelo servidor.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Game"):WaitForChild("Config"))

local ZoneEnemy = {}

type EnemyConfig = {
	Model: string,
	Zone: string,
	Damage: number,
	AttackRange: number,
	AttackCooldown: number,
	ChaseSpeed: number,
	WanderSpeed: number,
	EdgeMargin: number,
	FacingOffset: number,
}

-- Desliga scripts que vieram com o modelo (Toolbox pode trazer backdoor).
local function neutralize(model: Model)
	for _, item in model:GetDescendants() do
		if item:IsA("BaseScript") then
			item.Enabled = false
			item:Destroy()
		elseif item:IsA("BasePart") then
			item.Anchored = true
			item.CanCollide = false
		elseif item:IsA("Humanoid") then
			item.PlatformStand = true
		end
	end
end

-- Posição dentro da zona, nos eixos locais X/Z da Part.
local function localXZ(zone: BasePart, worldPos: Vector3): Vector3
	return zone.CFrame:PointToObjectSpace(worldPos)
end

local function isInside(zone: BasePart, worldPos: Vector3): boolean
	local p = localXZ(zone, worldPos)
	local half = zone.Size / 2
	return math.abs(p.X) <= half.X and math.abs(p.Z) <= half.Z and p.Y > -half.Y - 2 and p.Y < half.Y + 20
end

local function clampToZone(zone: BasePart, worldPos: Vector3, margin: number, height: number): Vector3
	local p = localXZ(zone, worldPos)
	local half = zone.Size / 2
	local x = math.clamp(p.X, -half.X + margin, half.X - margin)
	local z = math.clamp(p.Z, -half.Z + margin, half.Z - margin)
	return zone.CFrame:PointToWorldSpace(Vector3.new(x, half.Y + height, z))
end

local function randomPointIn(zone: BasePart, margin: number, height: number): Vector3
	local half = zone.Size / 2
	local x = (math.random() * 2 - 1) * math.max(half.X - margin, 0)
	local z = (math.random() * 2 - 1) * math.max(half.Z - margin, 0)
	return zone.CFrame:PointToWorldSpace(Vector3.new(x, half.Y + height, z))
end

local function findTarget(zone: BasePart, from: Vector3): (Humanoid?, BasePart?)
	local best: Humanoid?, bestRoot: BasePart?, bestDist = nil, nil, math.huge
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if humanoid and root and humanoid.Health > 0 and isInside(zone, root.Position) then
			local dist = (root.Position - from).Magnitude
			if dist < bestDist then
				best, bestRoot, bestDist = humanoid, root, dist
			end
		end
	end
	return best, bestRoot
end

local function run(cfg: EnemyConfig)
	local model = workspace:WaitForChild(cfg.Model, 10)
	local zone = workspace:WaitForChild(cfg.Zone, 10)
	if not model or not model:IsA("Model") then
		warn(`[ZoneEnemy] modelo "{cfg.Model}" não encontrado no Workspace`)
		return
	end
	if not zone or not zone:IsA("BasePart") then
		warn(`[ZoneEnemy] zona "{cfg.Zone}" não encontrada (renomeie a Part da zona para "{cfg.Zone}")`)
		return
	end

	neutralize(model)

	-- Altura do modelo acima do topo da zona, para ele "andar" sobre ela.
	local startLocal = zone.CFrame:PointToObjectSpace(model:GetPivot().Position)
	local height = math.max(startLocal.Y - zone.Size.Y / 2, 0)

	local position = clampToZone(zone, model:GetPivot().Position, cfg.EdgeMargin, height)
	local wanderGoal = randomPointIn(zone, cfg.EdgeMargin, height)
	local nextWander = 0
	local lastAttack = 0
	local facing = CFrame.Angles(0, math.rad(cfg.FacingOffset), 0)

	RunService.Heartbeat:Connect(function(dt)
		if not model.Parent then
			return
		end
		local now = os.clock()
		local humanoid, root = findTarget(zone, position)

		local goal: Vector3
		local speed: number
		if humanoid and root then
			goal = clampToZone(zone, root.Position, cfg.EdgeMargin, height)
			speed = cfg.ChaseSpeed
			local flat = Vector3.new(root.Position.X - position.X, 0, root.Position.Z - position.Z)
			if flat.Magnitude <= cfg.AttackRange and now - lastAttack >= cfg.AttackCooldown then
				lastAttack = now
				humanoid:TakeDamage(cfg.Damage)
			end
		else
			if now >= nextWander or (wanderGoal - position).Magnitude < 1 then
				wanderGoal = randomPointIn(zone, cfg.EdgeMargin, height)
				nextWander = now + math.random(3, 6)
			end
			goal = wanderGoal
			speed = cfg.WanderSpeed
		end

		local delta = goal - position
		local flatDelta = Vector3.new(delta.X, 0, delta.Z)
		local step = math.min(speed * dt, flatDelta.Magnitude)
		-- Não encosta no jogador: para quando já está no alcance do ataque.
		if humanoid and flatDelta.Magnitude <= cfg.AttackRange * 0.6 then
			step = 0
		end
		if flatDelta.Magnitude > 0.01 then
			position = clampToZone(zone, position + flatDelta.Unit * step, cfg.EdgeMargin, height)
			model:PivotTo(CFrame.lookAt(position, position + flatDelta) * facing)
		end
	end)
end

function ZoneEnemy.start()
	for _, cfg in Config.Enemies do
		task.spawn(run, cfg :: any)
	end
end

return ZoneEnemy
