--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local DASH_KEY = Enum.KeyCode.Q
local DASH_SPEED = 100 -- starting speed in studs/second
local DASH_TIME = 0.4 -- how long the dash lasts
local COOLDOWN = 1 -- seconds between dashes

local DASH_JUMP_HORIZONTAL = 90 -- horizontal speed when you jump out of a dash
local DASH_JUMP_POWER = 30 -- vertical jump power during a dash (a normal jump is ~50)
local DEBUG = false

type ActiveDash = {
	direction: Vector3,
	finish: (jumped: boolean) -> (),
}

local Dash = {}

function Dash.init()
	local player = Players.LocalPlayer
	local lastDash = 0
	local activeDash: ActiveDash? = nil
	local currentHumanoid: Humanoid? = nil
	local currentRoot: BasePart? = nil

	local function onCharacter(character: Model)
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		local root = character:WaitForChild("HumanoidRootPart") :: BasePart
		currentHumanoid = humanoid
		currentRoot = root
		activeDash = nil

		-- Jumping while a dash is active turns it into a dash jump
		humanoid.StateChanged:Connect(function(_, newState)
			local dash = activeDash
			if newState ~= Enum.HumanoidStateType.Jumping or not dash then
				return
			end

			local direction = dash.direction
			dash.finish(true)

			-- Wait one frame so the Humanoid's own jump has been applied, then
			-- replace only the horizontal speed and keep its (reduced) vertical speed
			RunService.Heartbeat:Wait()
			if root.Parent then
				local v = root.AssemblyLinearVelocity
				root.AssemblyLinearVelocity =
					Vector3.new(direction.X * DASH_JUMP_HORIZONTAL, v.Y, direction.Z * DASH_JUMP_HORIZONTAL)
				if DEBUG then
					print("Dash jump! vertical speed:", v.Y)
				end
			end
		end)
	end

	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
	player.CharacterAdded:Connect(onCharacter)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or input.KeyCode ~= DASH_KEY then
			return
		end
		if activeDash or os.clock() - lastDash < COOLDOWN then
			return
		end

		local humanoid = currentHumanoid
		local root = currentRoot
		if not (humanoid and root and root.Parent and humanoid.Health > 0) then
			return
		end

		-- Dash where the player is moving; if standing still, dash forward
		local moveDirection = humanoid.MoveDirection
		if moveDirection.Magnitude < 0.1 then
			moveDirection = root.CFrame.LookVector
		end
		local flat = Vector3.new(moveDirection.X, 0, moveDirection.Z)
		if flat.Magnitude < 0.01 then
			return
		end
		local direction = flat.Unit

		lastDash = os.clock()

		-- Lower the jump power for the duration of the dash
		local originalUseJumpPower = humanoid.UseJumpPower
		local originalJumpPower = humanoid.JumpPower
		humanoid.UseJumpPower = true
		humanoid.JumpPower = DASH_JUMP_POWER

		local attachment = Instance.new("Attachment")
		attachment.Parent = root

		local velocity = Instance.new("LinearVelocity")
		velocity.Attachment0 = attachment
		velocity.RelativeTo = Enum.ActuatorRelativeTo.World
		velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
		velocity.PrimaryTangentAxis = Vector3.xAxis
		velocity.SecondaryTangentAxis = Vector3.zAxis
		velocity.MaxForce = 100000
		velocity.PlaneVelocity = Vector2.new(direction.X * DASH_SPEED, direction.Z * DASH_SPEED)
		velocity.Parent = root

		local startTime = os.clock()
		local connection: RBXScriptConnection? = nil
		local finished = false

		local function restoreJump()
			humanoid.UseJumpPower = originalUseJumpPower
			humanoid.JumpPower = originalJumpPower
		end

		local function finish(jumped: boolean)
			if finished then
				return
			end
			finished = true
			activeDash = nil

			if connection then
				connection:Disconnect()
			end
			velocity:Destroy()
			attachment:Destroy()

			if jumped then
				-- Keep the reduced power for a moment so this jump is not affected
				task.delay(0.1, restoreJump)
			else
				restoreJump()
			end
		end

		activeDash = { direction = direction, finish = finish }

		if DEBUG then
			print("Dashing toward", direction)
		end

		connection = RunService.Heartbeat:Connect(function()
			local progress = (os.clock() - startTime) / DASH_TIME
			if progress >= 1 or humanoid.Health <= 0 or not root.Parent then
				finish(false)
				return
			end
			-- Fade the speed out smoothly instead of stopping instantly
			local speed = DASH_SPEED * (1 - progress)
			velocity.PlaneVelocity = Vector2.new(direction.X * speed, direction.Z * speed)
		end)
	end)
end

return Dash
