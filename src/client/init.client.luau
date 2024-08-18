--! strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


local remotes = ReplicatedStorage.Remotes
local interface = script.Interface


local Board = require(interface.Board)
local PlayerList = require(interface.PlayerList)


remotes.BroadcastNewBoard.OnClientEvent:Connect(Board.newGame)

Players.PlayerAdded:Connect(PlayerList.addPlayer)
Players.PlayerRemoving:Connect(PlayerList.removePlayer)
