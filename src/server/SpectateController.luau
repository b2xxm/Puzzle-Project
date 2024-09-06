local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")


local shared = ReplicatedStorage.Shared


local Types = require(shared.Types)
local Submissions = require(ServerScriptService.Server.Game.Submissions)


type Board = Types.Board


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

        print(player, "unsubscribed from", broadcaster)
    end

    if #list == 0 then
        print(broadcaster, "stopped broadcasting")

        subscriptions[broadcaster] = nil
    end
end


function SpectateController.subscribe(player: Player, shouldSubscribe: boolean, newName: string, oldName: string?): Board?
    local newPlayer = Players[newName]

    if not shouldSubscribe then
        unsubscribe(player, newPlayer)

        return Submissions.get(player)
    end

    if oldName then
        local oldPlayer = Players[oldName]

        unsubscribe(player, oldPlayer)
    end

    if player == newPlayer then
        return Submissions.get(player)
    end

    if not Submissions.get(player) then
        return
    end

    local newPlayerSolution = Submissions.get(newPlayer)

    if newPlayerSolution then
        return newPlayerSolution
    end

    if not subscriptions[newPlayer] then
        subscriptions[newPlayer] = {}

        -- request client B to start broadcasting/ updating
        print(newPlayer, "started broadcasting")
    end

    table.insert(subscriptions[newPlayer], player)

    print(player, "subscribed to", newPlayer)

    return
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


return SpectateController
