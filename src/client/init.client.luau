local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")


local remotes = ReplicatedStorage.Remotes
local shared = ReplicatedStorage.Shared
local client = shared.Client


local Board = require(client.Interface.Board)
local PlayerList = require(client.Interface.PlayerList)
local Selector = require(client.Input.Selector)
local Reserve = require(client.Interface.Reserve)
local Timer = require(client.Interface.Board.Timer)
local Spectate = require(client.Interface.Spectate)


local function newGame(blockerAddresses: { string }, startTime: number, duration: number): ()
    Board.newGame(blockerAddresses)
    Reserve.scatter()
    PlayerList.reset()
    Timer.start(startTime, duration)
    Selector.enable()
end


remotes.BroadcastNewBoard.OnClientEvent:Connect(newGame)
remotes.UpdateFinishers.OnClientEvent:Connect(PlayerList.setFinished)
remotes.Spectate.Broadcast.OnClientEvent:Connect(Spectate.moveMouse)
remotes.Spectate.Simulate.OnClientEvent:Connect(Spectate.simulate)

Players.PlayerAdded:Connect(PlayerList.addPlayer)
Players.PlayerRemoving:Connect(PlayerList.removePlayer)

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)

remotes.Spectate.Request.OnClientInvoke = Selector.setBroadcastStatus
