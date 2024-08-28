local ReplicatedStorage = game:GetService("ReplicatedStorage")


local shared = ReplicatedStorage.Shared
local remotes = ReplicatedStorage.Remotes


local Types = require(shared.Types)
local BoardService = require(shared.BoardService)
local Dices = require(script.Dices)


type LookUp<T> = Types.LookUp<T>
type Board = Types.Board


local submissions: { { player: Player, solution: Board } } = {}

local players: { active: LookUp<Player>, inactive: LookUp<Player> } = {
    active = {},
    inactive = {}
}

local cache: { board: Board, blocked: { string } } = {
    board = BoardService.new(),
    blocked = {}
}


local Game = {}


local function broadcastSpecific(player: Player): ()
    remotes.BroadcastNewBoard:FireClient(player, cache.blocked)
end


local function updateFinishers(player: Player): ()
    for _, submission in submissions do
        remotes.UpdateFinishers:FireClient(player, submission.player)
    end
end


local function checkFinish(): ()
    if #submissions == #players.active then
        Game.finish()
    end
end


function Game.start(): ()
    BoardService.reset(cache.board)

    table.clear(submissions)
    cache.blocked = Dices.roll()

    BoardService.setBlocked(cache.board, cache.blocked)

    -- start timer limit
    
    remotes.BroadcastNewBoard:FireAllClients(cache.blocked)
end


function Game.finish(): ()
    task.wait(3)

    Game.start()
end


function Game.submit(player: Player, solution: Board): ()
    if BoardService.validate(cache.board, solution) then
        for _, submission in submissions do
            if submission.player == player then
                return false
            end
        end

        local submission = {}
        submission.player = player
        submission.solution = solution

        table.insert(submissions, submission)

        remotes.UpdateFinishers:FireAllClients(player)

        checkFinish()
    end
end


function Game.playerAdded(player: Player): ()
    players.active[player] = true
    
    broadcastSpecific(player)
    updateFinishers(player)
end


function Game.playerRemoving(player: Player): ()
    if players.active[player] then
        for index, submission in submissions do
            if submission.player == player then
                table.remove(submission, index)
            end
        end

        players.active[player] = nil

        return
    end

    players.inactive[player] = nil

    checkFinish()
end


return Game