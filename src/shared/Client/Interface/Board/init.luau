local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")


local shared = ReplicatedStorage.Shared
local prefabs = ReplicatedStorage.Prefabs


local Types = require(shared.Types)
local BoardService = require(shared.BoardService)
local BoardUtils = require(shared.BoardService.Utils)
local BoardConfig = require(shared.BoardService.Config)
local BoardInterfaceConfig = require(script.Config)
local CellColours = require(script.CellColours)


type Board = Types.Board
type PieceType = Types.Board


local player: Player = Players.LocalPlayer
local board: Board = BoardService.new()
local cells: { [string]: Frame } = {}


local Board = {}
Board.cells = cells
Board.board = board


local function createRowContainer(y: number): Frame
    local containerPrefab = prefabs.Grid:WaitForChild("RowContainer")
    local container = containerPrefab:Clone()
    container.Name = BoardUtils.getRow(y)
    container.LayoutOrder = y

    local listLayout = container:WaitForChild("UIListLayout")
    listLayout.Padding = UDim.new(0, BoardInterfaceConfig.padding)
    
    return container
end


local function createCell(x: number, y: number): Frame?
    local address = BoardUtils.toAddress(x, y) :: string

    local cellPrefab = prefabs.Grid:WaitForChild("Cell")
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
    local listLayout = rows:WaitForChild("UIListLayout") :: UIListLayout
    listLayout.Padding = UDim.new(0, BoardInterfaceConfig.padding)

    for y = 1, BoardConfig.rows do
        local rowContainer = createRowContainer(y)

        for x = 1, BoardConfig.columns do
            local cell = createCell(x, y)

            if not cell then
                continue
            end

            cells[cell.Name] = cell

            cell.BackgroundColor3 = CellColours.unoccupied
            cell.Parent = rowContainer
        end

        rowContainer.Parent = rows
    end
end


function Board.newGame(blockerAddresses: { string }): ()
    BoardService.reset(board)
    BoardService.setBlocked(board, blockerAddresses)

    for address in board do
        local cell = cells[address]

        if table.find(blockerAddresses, address) then
            cell.Transparency = 1

            continue
        end

        cell.BackgroundColor3 = CellColours.unoccupied
        cell.Transparency = 0
    end
end


function Board.placePiece(occupyingAddresses: { string }, pieceType: PieceType): boolean
    local success = BoardService.placePiece(board, occupyingAddresses, pieceType)

    if not success then
        return false
    end

    local colour = CellColours.occupied[pieceType]

    for _, address in occupyingAddresses do
        local cell = cells[address]
        cell.BackgroundColor3 = colour
    end

    return success
end


function Board.removePiece(occupyingAddresses: { string }): ()
    for _, address in occupyingAddresses do
        Board.board[address] = "none"
        Board.cells[address].BackgroundColor3 = CellColours.unoccupied
    end
end


initialise()


return Board
