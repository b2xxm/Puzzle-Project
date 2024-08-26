local ReplicatedStorage = game:GetService("ReplicatedStorage")


local shared = ReplicatedStorage.Shared
local remotes = ReplicatedStorage.Remotes


local Types = require(shared.Types)
local BoardService = require(shared.BoardService)
local Dices = require(script.Dices)


type Board = Types.Board


local submissions: { { player: Player, solution: Board } } = {}
local cache: { board: Board, blocked: { string } } = {
    board = BoardService.new(),
    blocked = {}
}


local Game = {}


function Game.start(): ()
    BoardService.reset(cache.board)

    table.clear(submissions)
    cache.blocked = Dices.roll()

    BoardService.setBlocked(cache.board, cache.blocked)

    -- start timer limit
    
    remotes.BroadcastNewBoard:FireAllClients(cache.blocked)
end


function Game.broadcastSpecific(player: Player): ()
    remotes.BroadcastNewBoard:FireClient(player, cache.blocked)
end


function Game.finish(): ()
    -- finish on time out or all participants submit successfully
    -- display submissions before resetting board
end


function Game.submit(player: Player, solution: Board): ()
    if BoardService.validate(cache.board, solution) then
        local submission = {}
        submission.player = player
        submission.solution = solution

        table.insert(submissions, submission)

        remotes.UpdateFinishers:FireAllClients(player)
    end
end


return Game