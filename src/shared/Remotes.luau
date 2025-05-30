local ReplicatedStorage = game:GetService("ReplicatedStorage")


local shared = ReplicatedStorage.Shared
local remotes = ReplicatedStorage.Remotes


local Types = require(shared.Types)


type Board = Types.Board
type ReservedPieces = Types.ReservedPieces
type SimulateOptions = Types.SimulationOptions

type ToServerClient<T...> = ToServer<T...> & ToClient<T...>
type Context = "server" | "client"
type Mode = Context | "shared"

type ToServer<T...> = {
    fireServer: (T...) -> (),
    onServerEvent: (callback: (player: Player, T...) -> ()) -> (),
}

type ToClient<T...> = {
    fireClient: (player: Player, T...) -> (),
    fireAllClients: (T...) -> (),
    onClientEvent: (callback: (T...) -> ()) -> ()
}

type ServerFunction<T..., R...> = {
    invoke: (T...) -> R...,
    onInvoke: (callback: (player: Player, T...) -> R...) -> ()
}

type ClientFunction<T..., R...> = {
    invoke: (player: Player, T...) -> R...,
    onInvoke: (callback: (T...) -> R...) -> ()
}


local function wrapEvent<T...>(remote: RemoteEvent, mode: Mode): ToServerClient<T...> | ToServer<T...> | ToClient<T...>
    if mode == "server" then
        return {
            fireServer = function(...: T...): ()
                remote:FireServer(...)
            end,
            onServerEvent = function(callback: (player: Player, T...) -> ()): ()
                remote.OnServerEvent:Connect(callback)
            end
        }

    elseif mode == "client" then
        return {
            fireClient = function(player: Player, ...: T...): ()
                remote:FireClient(player, ...)
            end,
            fireAllClients = function(...: T...): ()
                remote:FireAllClients(...)
            end,
            onClientEvent = function(callback: (T...) -> ()): ()
                remote.OnClientEvent:Connect(callback)
            end
        }

    elseif mode == "shared" then
        return {
            fireServer = function(...: T...): ()
                remote:FireServer(...)
            end,
            onServerEvent = function(callback: (player: Player, T...) -> ()): ()
                remote.OnServerEvent:Connect(callback)
            end,
            fireClient = function(player: Player, ...: T...): ()
                remote:FireClient(player, ...)
            end,
            fireAllClients = function(...: T...): ()
                remote:FireAllClients(...)
            end,
            onClientEvent = function(callback: (T...) -> ()): ()
                remote.OnClientEvent:Connect(callback)
            end
        }
    else
        error("invalid mode")
    end
end


local function wrapFunction<T..., R...>(remote: RemoteFunction, context: Context): ServerFunction<T..., R...> | ClientFunction<T..., R...>
    if context == "server" then
        return {
            invoke = function(...: T...): R...
                return remote:InvokeServer(...)
            end,
            onInvoke = function(callback: (player: Player, T...) -> R...): ()
                remote.OnServerInvoke = callback
            end
        }

    elseif context == "client" then
        return {
            invoke = function(player: Player, ...: T...): R...
                return remote:InvokeClient(player, ...)
            end,
            onInvoke = function(callback: (T...) -> R...): ()
                remote.OnClientInvoke = callback
            end
        }
    else
        error("invalid context")
    end
end


return {
    BroadcastNewBoard = wrapEvent(remotes.BroadcastNewBoard, "client") :: ToClient<{ string }, number, number>,
    SubmitSolution = wrapEvent(remotes.SubmitSolution, "server") :: ToServer<Types.Board>,
    UpdateFinishers = wrapEvent(remotes.UpdateFinishers, "client") :: ToClient<Player>,
    
    Spectate = {
        Subscribe = wrapFunction(remotes.Spectate.Subscribe, "server") :: ServerFunction<(string), (Board?, ReservedPieces?)>,
        Unsubscribe = wrapFunction(remotes.Spectate.Unsubscribe, "server") :: ServerFunction<(string), (Board?, ReservedPieces?)>,
        ToggleService = wrapFunction(remotes.Spectate.ToggleService, "client") :: ClientFunction<(boolean), (Board?, ReservedPieces?)>,
        StreamCursor = wrapEvent(remotes.Spectate.StreamCursor, "shared") :: ToServerClient<buffer>,
        SimulateActions = wrapEvent(remotes.Spectate.SimulateActions, "shared") :: ToServerClient<(SimulateOptions, ...any)>
    }
}