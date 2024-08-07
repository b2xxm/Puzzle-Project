--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")


local shared = ReplicatedStorage.Shared


local Types = require(shared.Types)
local Board = require(script.Board)
local Dices = require(script.Dices)


type Board = Types.Board


local submissions: { { player: Player, solution: Board } } = {}
local boardCache: Board = Board.new()


local Game = {}


function Game.start(): ()
    local blockerAddresses = Dices.roll()

    Board.setBlocked(boardCache, blockerAddresses)

    -- start timer limit
end


function Game.finish(): ()
    Board.reset(boardCache)

    -- finish on time out or all participants submit successfully
    -- display submissions before resetting board
end


function Game.submit(player: Player, solution: Board): ()
    if Board.validate(boardCache, solution) then
        local submission = {}
        submission.player = player
        submission.solution = solution

        table.insert(submissions, submission)
    end
end


return Game