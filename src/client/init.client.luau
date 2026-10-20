local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Networker = require(ReplicatedStorage.Packages.Networker)

local Swim = require(script.Controllers.Swim)
Swim.init()

local DoubleJump = require(script.Controllers.DoubleJump)
DoubleJump.init()
