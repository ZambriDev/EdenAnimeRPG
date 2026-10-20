--!strict
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local WATER_TAG = "Water"
local FLOAT_DEPTH = 1 -- how far the root sits below the surface (higher = lower in the water)
local JUMP_LIFT = 5 -- how high above the surface the target goes while jump is held
local SPRING = 40 -- how strongly you're pulled toward the surface
local DAMPING = 10 -- how quickly bobbing settles down
local WATER_SPEED = 0.6 -- walk speed multiplier in water

local Swim = {}

-- Returns the water Part containing this position, if any
local function getWater(position: Vector3): BasePart?
	for _, part in CollectionService:GetTagged(WATER_TAG) do
		if part:IsA("BasePart") then
			local localPos = part.CFrame:PointToObjectSpace(position)
			local half = part.Size / 2
			if math.abs(localPos.X) <= half.X and math.abs(localPos.Y) <= half.Y and math.abs(localPos.Z) <= half.Z then
				return part
			end
		end
	end
	return nil
end

function Swim.init()
	local player = Players.LocalPlayer
	local connection: RBXScriptConnection? = nil

	local function onCharacter(character: Model)
		local root = character:WaitForChild("HumanoidRootPart") :: BasePart
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid

		local attachment = Instance.new("Attachment")
		attachment.Parent = root

		local force = Instance.new("VectorForce")
		force.Attachment0 = attachment
		force.RelativeTo = Enum.ActuatorRelativeTo.World
		force.ApplyAtCenterOfMass = true
		force.Force = Vector3.zero
		force.Parent = root

		local normalSpeed = humanoid.WalkSpeed

		if connection then
			connection:Disconnect()
		end
		connection = RunService.Heartbeat:Connect(function()
			local water = getWater(root.Position)
			if water then
				local surfaceY = water.Position.Y + water.Size.Y / 2
				local targetY = surfaceY - FLOAT_DEPTH

				-- Holding jump raises the target above the surface so you can hop out
				if humanoid.Jump or UserInputService:IsKeyDown(Enum.KeyCode.Space) then
					targetY = surfaceY + JUMP_LIFT / 2 + math.sqrt(humanoid.JumpPower)
				end

				local velocityY = root.AssemblyLinearVelocity.Y
				local acceleration = workspace.Gravity + SPRING * (targetY - root.Position.Y) - DAMPING * velocityY
				force.Force = Vector3.new(0, root.AssemblyMass * acceleration, 0)
				humanoid.WalkSpeed = normalSpeed * WATER_SPEED
			else
				force.Force = Vector3.zero
				humanoid.WalkSpeed = normalSpeed
			end
		end)
	end

	if player.Character then
		onCharacter(player.Character)
	end
	player.CharacterAdded:Connect(onCharacter)
end

return Swim
