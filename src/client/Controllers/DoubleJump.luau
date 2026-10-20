--!strict
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local MAX_EXTRA_JUMPS = 1 -- 1 = double jump, 2 = triple jump
local EXTRA_JUMP_POWER = 80 -- upward speed of the extra jump (a normal jump is ~50)
local MIN_AIR_TIME = 0.2 -- seconds after leaving the ground before an extra jump is allowed
local DEBUG = false

local DoubleJump = {}

function DoubleJump.init()
	local player = Players.LocalPlayer
	local humanoid: Humanoid? = nil
	local rootPart: BasePart? = nil
	local extraJumpsUsed = 0
	local lastJumpTime = 0

	local function onCharacter(character: Model)
		local newHumanoid = character:WaitForChild("Humanoid") :: Humanoid
		humanoid = newHumanoid
		rootPart = character:WaitForChild("HumanoidRootPart") :: BasePart
		extraJumpsUsed = 0

		newHumanoid.StateChanged:Connect(function(_, newState)
			if newState == Enum.HumanoidStateType.Jumping then
				lastJumpTime = os.clock()
			elseif newState == Enum.HumanoidStateType.Landed or newState == Enum.HumanoidStateType.Running then
				extraJumpsUsed = 0
			end
		end)
	end

	if player.Character then
		onCharacter(player.Character)
	end
	player.CharacterAdded:Connect(onCharacter)

	UserInputService.JumpRequest:Connect(function()
		local currentHumanoid = humanoid
		local root = rootPart
		if not currentHumanoid or not root then
			return
		end

		local state = currentHumanoid:GetState()
		local inAir = state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall
		local ready = os.clock() - lastJumpTime >= MIN_AIR_TIME

		if DEBUG then
			print("JumpRequest | state:", state.Name, "| inAir:", inAir, "| ready:", ready, "| used:", extraJumpsUsed)
		end

		if inAir and ready and extraJumpsUsed < MAX_EXTRA_JUMPS then
			extraJumpsUsed += 1
			lastJumpTime = os.clock()

			-- Keep horizontal speed, replace vertical speed with the extra jump power
			local velocity = root.AssemblyLinearVelocity
			root.AssemblyLinearVelocity = Vector3.new(velocity.X, EXTRA_JUMP_POWER, velocity.Z)
		end
	end)
end

return DoubleJump
