--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")


local shared = ReplicatedStorage.Shared
local prefabs = ReplicatedStorage.Prefabs


local Types = require(shared.Types)
local BoardService = require(shared.BoardService)
local BoardUtils = require(shared.BoardService.Utils)
local BoardConfig = require(shared.BoardService.Config)
local CellColours = require(script.CellColours)


type Board = Types.Board
type PieceType = Types.Board


local player: Player = Players.LocalPlayer
local board: Board = BoardService.new()
local cells: { [string]: Frame } = {}


local Board = {}


local function createRowContainer(y: number): Frame
    local containerPrefab = prefabs.Board:WaitForChild("RowContainer")
    local container = containerPrefab:Clone()
    container.Name = BoardUtils.getRow(y)
    container.LayoutOrder = y
    
    return container
end


local function createCell(x: number, y: number): Frame?
    local address = BoardUtils.toAddress(x, y)

    if not address then
        return
    end

    local cellPrefab = prefabs.Board:WaitForChild("Cell")
    local cell = cellPrefab:Clone()
    cell.Name = address
    cell.LayoutOrder = x
    
    return cell
end


local function initialise(): ()
    local playerGui = player.PlayerGui
    
    local gameUi = playerGui:WaitForChild("GameUi")
    local boardFrame = gameUi:WaitForChild("Board")
    local grid = boardFrame:WaitForChild("Grid")

    local rows = grid:WaitForChild("Rows")

    for y = 1, BoardConfig.rows do
        local rowContainer = createRowContainer(y)

        for x = 1, BoardConfig.columns do
            local cell = createCell(x, y)

            if not cell then
                continue
            end

            cells[cell.Name] = cell

            cell.Parent = rowContainer
        end

        rowContainer.Parent = rows
    end
end


function Board.newGame(blockerAddresses: { string }): ()
    BoardService.reset(board)
    BoardService.setBlocked(board, blockerAddresses)

    for address, _ in board do
        local cell = cells[address]
        local fill = cell:FindFirstChild("Fill") :: Frame
        
        cell.BackgroundColor3 = CellColours.unoccupied
        fill.BackgroundColor3 = CellColours.unoccupied
    end
    
    for _, address in blockerAddresses do
        local cell = cells[address]
        local fill = cell:FindFirstChild("Fill") :: Frame
        
        cell.BackgroundColor3 = CellColours.blocked
        fill.BackgroundColor3 = CellColours.blocked
    end
end


initialise()


return Board
