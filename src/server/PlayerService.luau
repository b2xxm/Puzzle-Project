--!strict

local Players = game:GetService("Players")


local PlayerService = {}


function PlayerService.connectAdded(callback: (player: Player) -> ()): ()
    for _, player in Players:GetPlayers() do
        callback(player)
    end

    Players.PlayerAdded:Connect(callback)
end


return PlayerService
