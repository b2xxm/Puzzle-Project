local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")


local shared = ReplicatedStorage.Shared
local remotes = ReplicatedStorage.Remotes


local Types = require(shared.Types)
local BoardService = require(shared.BoardService)
local GameConfig = require(script.Config)
local Dices = require(script.Dices)
local Submissions = require(script.Submissions)
local SpectateController = require(ServerScriptService.Server.SpectateController)


type LookUp<T> = Types.LookUp<T>
type Board = Types.Board


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
    for otherPlayer in Submissions.list do
        remotes.UpdateFinishers:FireClient(player, otherPlayer)
    end
end


local function checkFinish(): ()
    local activePlayerCount = 0

    for _ in players.active do
        activePlayerCount += 1
    end

    if Submissions.getCount() == activePlayerCount then
        Game.finish()
    end
end


function Game.start(): ()
    BoardService.reset(cache.board)
    Submissions.clear()
    SpectateController.stopAllBroadcasts()

    cache.blocked = Dices.roll()
    activeTimerThread = task.delay(GameConfig.maxGameDuration, Game.finish)
    currentStartTime = tick()

    BoardService.setBlocked(cache.board, cache.blocked)
    
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
        if Submissions.get(player) then
            return
        end

        Submissions.add(player, solution)
        SpectateController.onSubmit(player)

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
        Submissions.remove(player)

        players.active[player] = nil

        return
    end

    players.inactive[player] = nil

    checkFinish()
    SpectateController.stopBroadcast(player)
end


return Game