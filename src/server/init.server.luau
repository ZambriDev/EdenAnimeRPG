local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local questUpdate = Instance.new("RemoteEvent")
questUpdate.Name = "QuestUpdate"
questUpdate.Parent = remotes

local attack = Instance.new("RemoteEvent")
attack.Name = "Attack"
attack.Parent = remotes

local QuestService = require(script.QuestService)
local EnemyService = require(script.EnemyService)
local CombatService = require(script.CombatService)

QuestService.Start(questUpdate)
CombatService.Start(attack)
EnemyService.Start(QuestService.OnEnemyKilled)