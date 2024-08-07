--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")


local shared = ReplicatedStorage.Shared


local Types = require(shared.Types)
local Board = require(script.Board)
local Dices = require(script.Dices)


type Board = Types.Board


local boardCache: Board = Board.new()


local Game = {}


function Game.start(): ()
    local blockerAddresses = Dices.roll()

    Board.setBlocked(boardCache, blockerAddresses)
end


function Game.finish(): ()
    Board.reset(boardCache)
end


return Game