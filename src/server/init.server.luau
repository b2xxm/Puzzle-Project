--!strict

local Players = game:GetService("Players")


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