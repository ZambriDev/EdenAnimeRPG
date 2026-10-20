--!strict
local Leveling = {}

Leveling.MAX_LEVEL = 100

local BASE_XP = 100
local EXPONENT = 1.2

-- XP needed to go from `level` to `level + 1`
function Leveling.xpToNextLevel(level: number): number
	if level >= Leveling.MAX_LEVEL then
		return math.huge
	end
	return math.floor(BASE_XP * level ^ EXPONENT)
end

return Leveling
