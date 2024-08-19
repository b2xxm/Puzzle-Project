--! strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


local remotes = ReplicatedStorage.Remotes
local shared = ReplicatedStorage.Shared
local client = shared.Client


local Board = require(client.Interface.Board)
local PlayerList = require(client.Interface.PlayerList)
local Reserve = require(client.Interface.Reserve)


Reserve.scatter()


remotes.BroadcastNewBoard.OnClientEvent:Connect(Board.newGame)

Players.PlayerAdded:Connect(PlayerList.addPlayer)
Players.PlayerRemoving:Connect(PlayerList.removePlayer)
