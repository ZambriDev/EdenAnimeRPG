local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Swim = require(script.Controllers.Swim)
Swim.init()

local Dash = require(script.Controllers.Dash)
Dash.init()

local DoubleJump = require(script.Controllers.DoubleJump)
DoubleJump.init()

local QuestTypes = require(ReplicatedStorage.Shared.QuestTypes)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local questUpdate = remotes:WaitForChild("QuestUpdate") :: RemoteEvent
local attack = remotes:WaitForChild("Attack") :: RemoteEvent

-- UI provisional: se borra cuando esté el componente de React
local gui = Instance.new("ScreenGui")
gui.Name = "QuestGui"
gui.ResetOnSpawn = false
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.Size = UDim2.fromOffset(320, 40)
label.Position = UDim2.new(1, -330, 0, 10)
label.BackgroundTransparency = 0.4
label.BackgroundColor3 = Color3.new(0, 0, 0)
label.TextColor3 = Color3.new(1, 1, 1)
label.TextScaled = true
label.Text = "Sin quest activa"
label.Parent = gui

questUpdate.OnClientEvent:Connect(function(payload: QuestTypes.QuestPayload)
	if payload.status == "done" then
		label.Text = `¡Quest completada! +{payload.reward.XP} XP, +{payload.reward.Gold} oro`
	elseif payload.status == "ready" then
		label.Text = `{payload.name}: ¡Regresa con el guardia!`
	else
		label.Text = `{payload.name}: {payload.progress}/{payload.amount}`
	end
end)

-- El ataque debe seguir existiendo aunque cambie la UI
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		attack:FireServer()
	end
end)
