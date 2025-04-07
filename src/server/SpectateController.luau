local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")


local shared = ReplicatedStorage.Shared
local remotes = ReplicatedStorage.Remotes


local Types = require(shared.Types)
local Submissions = require(ServerScriptService.Server.Game.Submissions)


type Board = Types.Board
type ReservedPieces = Types.ReservedPieces
type SimulationOptions = Types.SimulationOptions


local subscriptions: { [Player]: { Player } } = {}


local SpectateController = {}


local function unsubscribe(player: Player, broadcaster: Player): ()
    local subscribers = subscriptions[broadcaster]

    if not subscribers then
        return
    end

    local index = table.find(subscribers, player)

    if index then
        table.remove(subscribers, index)
    end

    if #subscribers == 0 then
        subscriptions[broadcaster] = nil

        remotes.Spectate.Request:InvokeClient(broadcaster, false)
    end
end


function SpectateController.subscribe(player: Player, shouldSubscribe: boolean, selected: string, previous: string?): (Board?, ReservedPieces?)
    local selectedPlayer = Players[selected]

    if not shouldSubscribe then
        unsubscribe(player, selectedPlayer)

        return Submissions.get(player)
    end

    if previous then
        local previousPlayer = Players[previous]

        unsubscribe(player, previousPlayer)
    end

    if player == selectedPlayer then
        return Submissions.get(player)
    end

    if not Submissions.get(player) then
        return
    end

    local selectedPlayerSolution = Submissions.get(selectedPlayer)

    if selectedPlayerSolution then
        return selectedPlayerSolution
    end

    if not subscriptions[selectedPlayer] then
        subscriptions[selectedPlayer] = {}
    end

    table.insert(subscriptions[selectedPlayer], player)

    return remotes.Spectate.Request:InvokeClient(selectedPlayer, true)
end


function SpectateController.stopBroadcast(broadcaster: Player): ()
    local subscribers = subscriptions[broadcaster]

    if subscribers then
        while true do
            local subscriber = subscribers[1]

            unsubscribe(subscriber, broadcaster)

            if not subscriptions[broadcaster] then
                break
            end
        end
    end
end


function SpectateController.stopAllBroadcasts(): ()
    for broadcaster in subscriptions do
        SpectateController.stopBroadcast(broadcaster)
    end
end


function SpectateController.onSubmit(broadcaster: Player): ()
    remotes.Spectate.Request:InvokeClient(broadcaster, false)

    subscriptions[broadcaster] = nil
end


function SpectateController.broadcast(broadcaster: Player, mouseX: number, mouseY: number): ()
    local subscribers = subscriptions[broadcaster]

    if not subscribers then
        remotes.Spectate.Request:InvokeClient(broadcaster, false)

        return
    end

    for _, subscriber in subscribers do
        remotes.Spectate.Broadcast:FireClient(subscriber, mouseX, mouseY)
    end
end


function SpectateController.simulate(broadcaster: Player, option: SimulationOptions, ...: any)
    local subscribers = subscriptions[broadcaster]

    if not subscribers then
        remotes.Spectate.Request:InvokeClient(broadcaster, false)
    end

    for _, subscriber in subscribers do
        remotes.Spectate.Simulate:FireClient(subscriber, option, ...)
    end
end


return SpectateController
