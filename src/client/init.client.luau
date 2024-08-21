--! strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")


local remotes = ReplicatedStorage.Remotes
local shared = ReplicatedStorage.Shared
local client = shared.Client


local Board = require(client.Interface.Board)
local PlayerList = require(client.Interface.PlayerList)
local Reserve = require(client.Interface.Reserve)
local Selector = require(client.Input.Selector)


Reserve.scatter()


remotes.BroadcastNewBoard.OnClientEvent:Connect(Board.newGame)

Players.PlayerAdded:Connect(PlayerList.addPlayer)
Players.PlayerRemoving:Connect(PlayerList.removePlayer)

ContextActionService:BindAction(Selector.actionName, Selector.actionCallback, false, table.unpack(Selector.inputs))
