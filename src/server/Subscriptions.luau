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


local Subscriptions = {}


local function unsubscribe(player: Player, service: Player): ()
    local subscribers = subscriptions[service]

    if not subscribers then
        return
    end

    local index = table.find(subscribers, player)

    if index then
        table.remove(subscribers, index)
    end

    if #subscribers == 0 then
        subscriptions[service] = nil

        remotes.Spectate.ToggleService:InvokeClient(service, false)
    end
end


local function findPlayer(name: string): Player?
    for _, player in Players:GetPlayers() do
        if player.Name == name then
            return player
        end
    end

    return nil
end


function Subscriptions.subscribe(player: Player, serviceName: string): (Board?, ReservedPieces?)
    local service = findPlayer(serviceName)
    local selfSolution = Submissions.get(player)

    if not service or player == service or not selfSolution then
        return selfSolution
    end

    local solution = Submissions.get(service)

    if solution then
        return solution
    end

    if not subscriptions[service] then
        subscriptions[service] = {}
    end

    table.insert(subscriptions[service], player)

    return remotes.Spectate.ToggleService:InvokeClient(service, true)
end


function Subscriptions.unsubscribe(player: Player, serviceName: string): (Board?, ReservedPieces?)
    unsubscribe(player, Players[serviceName])

    return Submissions.get(player)
end


function Subscriptions.stopService(service: Player): ()
    local subscribers = subscriptions[service]

    if not subscribers then
        return
    end

    while true do
        local subscriber = subscribers[1]

        unsubscribe(subscriber, service)

        if not subscriptions[service] then
            break
        end
    end
end


function Subscriptions.stopAllServices(): ()
    for service in subscriptions do
        Subscriptions.stopService(service)
    end
end


function Subscriptions.onSubmit(broadcaster: Player): ()
    -- if the service finishes, firing the remote everytime would be unnecessary
    -- stopping this service would allow the subscribers to view the solution without the service streaming it

    remotes.Spectate.ToggleService:InvokeClient(broadcaster, false)

    subscriptions[broadcaster] = nil
end


function Subscriptions.streamCursor(service: Player, mouseX: number, mouseY: number): ()
    local subscribers = subscriptions[service]

    if not subscribers then
        remotes.Spectate.ToggleService:InvokeClient(service, false)

        return
    end

    for _, subscriber in subscribers do
        remotes.Spectate.StreamCursor:FireClient(subscriber, mouseX, mouseY)
    end
end


function Subscriptions.simulate(service: Player, option: SimulationOptions, ...: any)
    local subscribers = subscriptions[service]

    if not subscribers then
        remotes.Spectate.ToggleService:InvokeClient(service, false)
    end

    for _, subscriber in subscribers do
        remotes.Spectate.SimulateActions:FireClient(subscriber, option, ...)
    end
end


return Subscriptions
