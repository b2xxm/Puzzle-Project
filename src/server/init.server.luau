local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


local remotes = ReplicatedStorage.Remotes


local Game = require(script.Game)


local function playerAdded(player: Player): ()
    Game.broadcastSpecific(player)
end


-- temporary
Game.start()

for _, player in Players:GetPlayers() do
    playerAdded(player)
end


Players.PlayerAdded:Connect(playerAdded)

remotes.SubmitSolution.OnServerEvent:Connect(Game.submit)