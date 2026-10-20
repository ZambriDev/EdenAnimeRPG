local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Progression = require(script.Parent.Progression)

local Quests = require(ReplicatedStorage.Shared.Quests)
local QuestTypes = require(ReplicatedStorage.Shared.QuestTypes)
type QuestPayload = QuestTypes.QuestPayload

local QuestService = {}

type QuestState = { questId: string, progress: number, status: "active" | "done" }
local states: { [Player]: QuestState } = {}
local questUpdate: RemoteEvent

local function setupLeaderstats(player: Player)
	local stats = Progression.GetLeaderstats(player)
	if not stats:FindFirstChild("Gold") then
		local gold = Instance.new("IntValue")
		gold.Name = "Gold"
		gold.Parent = stats
	end
end

local function buildPayload(state: QuestState): QuestPayload
	local quest = Quests[state.questId]

	local status: "active" | "ready" | "done" = state.status
	if state.status == "active" and state.progress >= quest.Amount then
		status = "ready"
	end

	return {
		questId = quest.Id,
		name = quest.Name,
		progress = state.progress,
		amount = quest.Amount,
		status = status,
		reward = quest.Reward,
	}
end

local function handleTalk(player: Player)
	local state = states[player]

	if not state or state.status == "done" then
		states[player] = { questId = "kill_bandits", progress = 0, status = "active" }
		questUpdate:FireClient(player, buildPayload(states[player]))
		return
	end

	local quest = Quests[state.questId]

	if state.status == "active" and state.progress >= quest.Amount then
		state.status = "done"

		Progression.AddXP(player, quest.Reward.XP)

		local stats = player:FindFirstChild("leaderstats")
		local gold = stats and stats:FindFirstChild("Gold") :: IntValue?
		if gold then
			gold.Value += quest.Reward.Gold
		end
	end

	questUpdate:FireClient(player, buildPayload(state))
end

function QuestService.OnEnemyKilled(enemyName: string, userId: number?)
	if not userId then
		return
	end
	local player = Players:GetPlayerByUserId(userId)
	local state = player and states[player]
	if not player or not state or state.status ~= "active" then
		return
	end

	local quest = Quests[state.questId]
	if quest.Target == enemyName then
		state.progress = math.min(state.progress + 1, quest.Amount)
		questUpdate:FireClient(player, buildPayload(state))
	end
end
Progression.Start()

function QuestService.Start(remote: RemoteEvent)
	questUpdate = remote

	Players.PlayerAdded:Connect(setupLeaderstats)

	-- jugadores que ya estaban dentro antes de conectar el evento
	for _, player in Players:GetPlayers() do
		task.spawn(setupLeaderstats, player)
	end

	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)

	local npc = Workspace:WaitForChild("QuestNPC")
	local prompt = npc:FindFirstChildWhichIsA("ProximityPrompt", true)
	assert(prompt, "QuestNPC necesita un ProximityPrompt")
	prompt.Triggered:Connect(handleTalk)
end

return QuestService
