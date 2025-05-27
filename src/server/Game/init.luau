local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")


local shared = ReplicatedStorage.Shared
local remotes = ReplicatedStorage.Remotes


local Types = require(shared.Types)
local BoardService = require(shared.BoardService)
local Configuration = require(shared.Configuration)
local Dices = require(script.Dices)
local Submissions = require(script.Submissions)
local Subscriptions = require(ServerScriptService.Server.Subscriptions)


type LookUp<T> = Types.LookUp<T>
type Board = Types.Board


local activeTimerThread: thread = nil
local currentStartTime: number = 0
local board: Board = BoardService.new()
local blocked: { string } = {}

local players: { active: LookUp<Player>, inactive: LookUp<Player> } = {
    active = {},
    inactive = {}
}


local Game = {}


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
    blocked = Dices.roll()
    activeTimerThread = task.delay(Configuration.game.maxGameDuration, Game.finish)
    currentStartTime = Workspace:GetServerTimeNow()

    BoardService.setBlocked(board, blocked)
    
    remotes.BroadcastNewBoard:FireAllClients(
        blocked,
        currentStartTime,
        Configuration.game.maxGameDuration
    )
end


function Game.finish(): ()
    if coroutine.running() ~= activeTimerThread then
        task.cancel(activeTimerThread)
    end

    task.wait(Configuration.game.intermissionDuration)

    BoardService.reset(board)
    Submissions.clear()
    Subscriptions.stopAllServices()
    Game.start()
end


function Game.submit(player: Player, solution: Board): ()
    if BoardService.validate(board, solution) then
        if Submissions.get(player) then
            return
        end

        Submissions.add(player, solution)
        Subscriptions.onSubmit(player)

        remotes.UpdateFinishers:FireAllClients(player)

        checkFinish()
    end
end


function Game.playerAdded(player: Player): ()
    players.active[player] = true
    
    remotes.BroadcastNewBoard:FireClient(
        player,
        blocked,
        currentStartTime,
        Configuration.game.maxGameDuration
    )
    
    for otherPlayer in Submissions.list do
        remotes.UpdateFinishers:FireClient(player, otherPlayer)
    end
end


function Game.playerRemoving(player: Player): ()
    if players.active[player] then
        Submissions.remove(player)

        players.active[player] = nil
    end

    players.inactive[player] = nil

    checkFinish()
    Subscriptions.stopService(player)
end


return Game