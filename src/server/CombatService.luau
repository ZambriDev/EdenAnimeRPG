local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local COOLDOWN = 0.5
local RANGE = 8
local FIST_DAMAGE = 5

-- Más adelante: leer arma equipada, nivel, bonos, etc.
local function getDamage(player: Player): number
	return FIST_DAMAGE
end

local CombatService = {}
local lastAttack: { [Player]: number } = {}

function CombatService.Start(attackRemote: RemoteEvent)
	attackRemote.OnServerEvent:Connect(function(player)
		local now = os.clock()
		if lastAttack[player] and now - lastAttack[player] < COOLDOWN then
			return
		end
		lastAttack[player] = now

		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local folder = Workspace:FindFirstChild("Enemies")
		if not root or not folder then
			return
		end

		local closest, closestHumanoid, closestDist = nil, nil, math.huge
		for _, enemy in folder:GetChildren() do
			local humanoid = enemy:FindFirstChildOfClass("Humanoid")
			local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
			if humanoid and enemyRoot and humanoid.Health > 0 then
				local dist = (enemyRoot.Position - root.Position).Magnitude
				if dist <= RANGE and dist < closestDist then
					closest, closestHumanoid, closestDist = enemy, humanoid, dist
				end
			end
		end

		if closest and closestHumanoid then
			closest:SetAttribute("LastAttacker", player.UserId)
			closestHumanoid:TakeDamage(getDamage(player))
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		lastAttack[player] = nil
	end)
end

return CombatService