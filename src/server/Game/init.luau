local ReplicatedStorage = game:GetService("ReplicatedStorage")


local shared = ReplicatedStorage.Shared
local remotes = ReplicatedStorage.Remotes


local Types = require(shared.Types)
local BoardService = require(shared.BoardService)
local GameConfig = require(script.Config)
local Dices = require(script.Dices)


type LookUp<T> = Types.LookUp<T>
type Board = Types.Board


local submissions: { { player: Player, solution: Board } } = {}
local activeTimerThread: thread = nil
local currentStartTime: number = 0

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
    remotes.BroadcastNewBoard:FireClient(
        player,
        cache.blocked,
        currentStartTime,
        GameConfig.maxGameDuration
    )
end


local function updateFinishers(player: Player): ()
    for _, submission in submissions do
        remotes.UpdateFinishers:FireClient(player, submission.player)
    end
end


local function checkFinish(): ()
    local activePlayerCount = 0

    for _ in players.active do
        activePlayerCount += 1
    end

    if #submissions == activePlayerCount then
        Game.finish()
    end
end


function Game.start(): ()
    BoardService.reset(cache.board)

    table.clear(submissions)

    cache.blocked = Dices.roll()
    activeTimerThread = task.delay(GameConfig.maxGameDuration, Game.finish)

    BoardService.setBlocked(cache.board, cache.blocked)

    currentStartTime = tick()
    
    remotes.BroadcastNewBoard:FireAllClients(
        cache.blocked,
        currentStartTime,
        GameConfig.maxGameDuration
    )
end


function Game.finish(): ()
    if coroutine.running() ~= activeTimerThread then
        task.cancel(activeTimerThread)
    end

    task.wait(GameConfig.intermissionDuration)

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