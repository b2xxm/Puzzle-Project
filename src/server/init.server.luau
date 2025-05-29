local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


local shared = ReplicatedStorage.Shared


local Game = require(script.Game)
local Subscriptions = require(script.Subscriptions)
local Remotes = require(shared.Remotes)


for _, player in Players:GetPlayers() do
    Game.playerAdded(player)
end


Game.start()


Players.PlayerAdded:Connect(Game.playerAdded)
Players.PlayerRemoving:Connect(Game.playerRemoving)


Remotes.SubmitSolution.onServerEvent(Game.submit)
Remotes.Spectate.StreamCursor.onServerEvent(Subscriptions.streamCursor)
Remotes.Spectate.SimulateActions.onServerEvent(Subscriptions.simulate)

Remotes.Spectate.Subscribe.onInvoke(Subscriptions.subscribe)
Remotes.Spectate.Unsubscribe.onInvoke(Subscriptions.unsubscribe)