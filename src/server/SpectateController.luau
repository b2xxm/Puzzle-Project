local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")


local shared = ReplicatedStorage.Shared
local remotes = ReplicatedStorage.Remotes


local Types = require(shared.Types)
local Submissions = require(ServerScriptService.Server.Game.Submissions)


type Board = Types.Board
type ReservedPieces = Types.ReservedPieces


local subscriptions: { [Player]: { Player } } = {}


local SpectateController = {}


local function unsubscribe(player: Player, broadcaster: Player): ()
    local list = subscriptions[broadcaster]

    if not list then
        return
    end

    local index = table.find(list, player)

    if index then
        table.remove(list, index)
    end

    if #list == 0 then
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

    local board: Board, pieces: ReservedPieces = remotes.Spectate.Request:InvokeClient(selectedPlayer, true)

    return board, pieces
end


function SpectateController.stopBroadcast(broadcaster: Player): ()
    local list = subscriptions[broadcaster]

    if list then
        while true do
            local player = list[1]

            unsubscribe(player, broadcaster)

            if not subscriptions[broadcaster] then
                break
            end
        end

        subscriptions[broadcaster] = nil
    end
end


function SpectateController.stopAllBroadcasts(): ()
    for broadcaster in subscriptions do
        SpectateController.stopBroadcast(broadcaster)
    end
end


function SpectateController.onSubmit(broadcaster: Player): ()
    remotes.Spectate.Request:InvokeClient(broadcaster, false)

    if subscriptions[broadcaster] then
        subscriptions[broadcaster] = nil
    end
end


return SpectateController
