--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Leveling = require(ReplicatedStorage.Shared.Leveling)

local Progression = {}

-- Shared helper so every system uses the same leaderstats folder
function Progression.GetLeaderstats(player: Player): Folder
	local existing = player:FindFirstChild("leaderstats")
	if existing and existing:IsA("Folder") then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = "leaderstats"
	folder.Parent = player
	return folder
end

local function ensureValue(stats: Folder, name: string, startValue: number): IntValue
	local existing = stats:FindFirstChild(name)
	if existing and existing:IsA("IntValue") then
		return existing
	end
	local value = Instance.new("IntValue")
	value.Name = name
	value.Value = startValue
	value.Parent = stats
	return value
end

local function setupPlayer(player: Player)
	local stats = Progression.GetLeaderstats(player)
	ensureValue(stats, "Level", 1)
	ensureValue(stats, "XP", 0)
end

-- Adds XP, handles multiple level-ups at once. Returns how many levels were gained.
function Progression.AddXP(player: Player, amount: number): number
	local stats = player:FindFirstChild("leaderstats")
	local levelValue = stats and stats:FindFirstChild("Level")
	local xpValue = stats and stats:FindFirstChild("XP")
	if not (levelValue and levelValue:IsA("IntValue") and xpValue and xpValue:IsA("IntValue")) then
		return 0
	end

	amount = math.floor(amount)
	if amount <= 0 then
		return 0
	end

	local startLevel = levelValue.Value
	local level = startLevel
	local xp = xpValue.Value + amount

	while level < Leveling.MAX_LEVEL do
		local needed = Leveling.xpToNextLevel(level)
		if xp < needed then
			break
		end
		xp -= needed
		level += 1
	end

	if level >= Leveling.MAX_LEVEL then
		xp = 0 -- nothing left to earn at the cap
	end

	xpValue.Value = xp
	levelValue.Value = level

	return level - startLevel
end

function Progression.Start()
	Players.PlayerAdded:Connect(setupPlayer)
	for _, player in Players:GetPlayers() do
		task.spawn(setupPlayer, player)
	end
end

return Progression
