--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")


local shared = ReplicatedStorage.Shared
local remotes = ReplicatedStorage.Remotes


local Types = require(shared.Types)
local Dices = require(script.Dices)
local BoardService = require(shared.BoardService)


type Board = Types.Board


local submissions: { { player: Player, solution: Board } } = {}
local boardCache: Board = BoardService.new()


local Game = {}


function Game.start(): ()
    BoardService.reset(boardCache)
    table.clear(submissions)

    local blockerAddresses = Dices.roll()
    BoardService.setBlocked(boardCache, blockerAddresses)

    -- start timer limit
    
    remotes.BroadcastNewBoard:FireAllClients(blockerAddresses)
end


function Game.finish(): ()
    -- finish on time out or all participants submit successfully
    -- display submissions before resetting board
end


function Game.submit(player: Player, solution: Board): ()
    if BoardService.validate(boardCache, solution) then
        local submission = {}
        submission.player = player
        submission.solution = solution

        table.insert(submissions, submission)
    end
end


return Game