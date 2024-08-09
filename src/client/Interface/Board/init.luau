--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")


local shared = ReplicatedStorage:WaitForChild("Shared")
local remotes = ReplicatedStorage:WaitForChild("Remotes")


local Types = require(shared.Types)
local BoardService = require(shared.BoardService)
local BoardUtils = require(shared.BoardService.Utils)
local CellColours = require(script.CellColours)


type Board = Types.Board


local player: Player = Players.LocalPlayer
local playerGui: PlayerGui = player.PlayerGui
local boardCache: Board = BoardService.new()


local Board = {}


function Board.newGame(blockerAddresses: { string }): ()
    BoardService.reset(boardCache)
    BoardService.setBlocked(boardCache, blockerAddresses)
    
    for _, address in blockerAddresses do
        local row, column = BoardUtils.seperateAddress(address)

        
    end
end


remotes.BroadcastNewBoard.OnClientEvent:Connect(Board.newGame)


return Board