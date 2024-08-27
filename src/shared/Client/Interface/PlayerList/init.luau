local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


local prefabs = ReplicatedStorage.Prefabs


local Colours = require(script.Colours)


local player: Player = Players.LocalPlayer
local rows: { [Player]: GuiObject } = {}


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


function PlayerList.removePlayer(otherPlayer: Player): ()
    local row = rows[otherPlayer]

    if not row then
        return
    end

    row:Destroy()
end


function PlayerList.setFinished(otherPlayer: Player): ()
    local row = rows[otherPlayer]

    if not row then
        return
    end

    local name = row:WaitForChild("PlayerName")
    local background = name:WaitForChild("Background") :: GuiObject

    background.BackgroundColor3 = Colours.finished
end


function PlayerList.reset(): ()
    for _, row in rows do
        local name = row:WaitForChild("PlayerName")
        local background = name:WaitForChild("Background") :: GuiObject

        background.BackgroundColor3 = Colours.unfinished
    end
end


initialise()


return PlayerList
