--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")


local shared = ReplicatedStorage:WaitForChild("Shared")
local remotes = ReplicatedStorage:WaitForChild("Remotes")


local Types = require(shared.Types)
local BoardService = require(shared.BoardService)
local CellColours = require(script.CellColours)


type Board = Types.Board
type PieceType = Types.Board


local player: Player = Players.LocalPlayer
local board: Board = BoardService.new()
local cells: { [string]: Frame } = {}


local Board = {}


local function newGame(blockerAddresses: { string }): ()
    BoardService.reset(board)
    BoardService.setBlocked(board, blockerAddresses)
    
    for _, address in blockerAddresses do
        cells[address].BackgroundColor3 = CellColours.blocked
    end
end


local function initialise(): ()
    local playerGui = player.PlayerGui
    
    local boardUi = playerGui:WaitForChild("BoardUI")
    local boardFrame = boardUi:WaitForChild("Board")
    local grid = boardFrame:WaitForChild("Grid")

    local rows = grid:WaitForChild("Rows")

    for _, rowContainer in rows:GetChildren() do
        if not rowContainer:IsA("Frame") then
            continue
        end

        local row = rowContainer.Name

        for _, cell in rowContainer:GetChildren() do
            if not cell:IsA("Frame") then
                continue
            end

            local column = cell.Name
            local address = row .. column

            cells[address] = cell
        end
    end
end


initialise()

remotes.BroadcastNewBoard.OnClientEvent:Connect(newGame)


return Board
