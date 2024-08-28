local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


local remotes = ReplicatedStorage.Remotes


local Game = require(script.Game)


for _, player in Players:GetPlayers() do
    Game.playerAdded(player)
end


Game.start()


Players.PlayerAdded:Connect(Game.playerAdded)
Players.PlayerRemoving:Connect(Game.playerRemoving)

remotes.SubmitSolution.OnServerEvent:Connect(Game.submit)