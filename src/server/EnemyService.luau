local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local RESPAWN_TIME = 5

local EnemyService = {}

local enemiesFolder

local function spawnEnemy(spawnPart: BasePart, onKilled)
	local template = ServerStorage.Enemies:FindFirstChild(spawnPart:GetAttribute("EnemyType") or "Bandit")
	if not template then
		warn("No existe el enemigo en ServerStorage.Enemies")
		return
	end

	local enemy = template:Clone()
	enemy:PivotTo(spawnPart.CFrame + Vector3.new(0, 3, 0))
	enemy.Parent = enemiesFolder

	local humanoid = enemy:WaitForChild("Humanoid") :: Humanoid
	humanoid.Died:Connect(function()
		onKilled(enemy.Name, enemy:GetAttribute("LastAttacker"))
		task.delay(2, function()
			enemy:Destroy()
		end)
		task.delay(RESPAWN_TIME, spawnEnemy, spawnPart, onKilled)
	end)
end

function EnemyService.Start(onKilled)
	enemiesFolder = Instance.new("Folder")
	enemiesFolder.Name = "Enemies"
	enemiesFolder.Parent = Workspace

	local spawns = Workspace:WaitForChild("EnemySpawns")
	for _, spawnPart in spawns:GetChildren() do
		if spawnPart:IsA("BasePart") then
			spawnEnemy(spawnPart, onKilled)
		end
	end
end

return EnemyService
