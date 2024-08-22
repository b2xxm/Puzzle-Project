local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


local prefabs = ReplicatedStorage.Prefabs


local player: Player = Players.LocalPlayer
local rows: { [Player]: Frame } = {}


local PlayerList = {}


local function initialise(): ()
    for _, otherPlayer in Players:GetChildren() do
        PlayerList.addPlayer(otherPlayer)
    end
end


function PlayerList.addPlayer(otherPlayer: Player): ()
    local playerGui = player.PlayerGui
    
    local gameUi = playerGui:WaitForChild("GameUi")
    local playerList = gameUi:WaitForChild("Players")

    local rowPrefab = prefabs.PlayerList:WaitForChild("Row")
    local row = rowPrefab:Clone()
    row.Name = otherPlayer.Name
    row.PlayerName.Text = otherPlayer.Name
    row.Parent = playerList

    rows[otherPlayer] = row
end


function PlayerList.removePlayer(otherPlayer): ()
    local row = rows[otherPlayer]

    if not row then
        return
    end

    row:Destroy()
end


initialise()


return PlayerList
