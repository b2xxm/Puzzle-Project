local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local StarterGui = game:GetService("StarterGui")


local remotes = ReplicatedStorage.Remotes
local shared = ReplicatedStorage.Shared
local client = shared.Client


local Board = require(client.Interface.Board)
local PlayerList = require(client.Interface.PlayerList)
local Selector = require(client.Input.Selector)


remotes.BroadcastNewBoard.OnClientEvent:Connect(Board.newGame)
remotes.UpdateFinishers.OnClientEvent:Connect(PlayerList.setFinished)

Players.PlayerAdded:Connect(PlayerList.addPlayer)
Players.PlayerRemoving:Connect(PlayerList.removePlayer)

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)


ContextActionService:BindAction(
    PlayerList.actionName,
    PlayerList.toggleVisibility,
    false,
    PlayerList.input
)

ContextActionService:BindAction(
    Selector.actionName,
    Selector.action,
    false,
    table.unpack(Selector.inputs)
)