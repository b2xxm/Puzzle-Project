local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


local remotes = ReplicatedStorage.Remotes


local Game = require(script.Game)
local Subscriptions = require(script.Subscriptions)


for _, player in Players:GetPlayers() do
    Game.playerAdded(player)
end


Game.start()


Players.PlayerAdded:Connect(Game.playerAdded)
Players.PlayerRemoving:Connect(Game.playerRemoving)

remotes.SubmitSolution.OnServerEvent:Connect(Game.submit)
remotes.Spectate.StreamCursor.OnServerEvent:Connect(Subscriptions.streamCursor)
remotes.Spectate.SimulateActions.OnServerEvent:Connect(Subscriptions.simulate)

remotes.Spectate.Subscribe.OnServerInvoke = Subscriptions.subscribe
