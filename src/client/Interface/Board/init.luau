--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")


local shared = ReplicatedStorage:WaitForChild("Shared")
local remotes = ReplicatedStorage:WaitForChild("Remotes")


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
    local container = Instance.new("Frame")
    container.Name = BoardUtils.getRow(y)
    container.LayoutOrder = y
    container.BackgroundTransparency = 1

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 3)
    listLayout.FillDirection = Enum.FillDirection.Horizontal
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Wraps = false
    listLayout.HorizontalFlex = Enum.UIFlexAlignment.Fill
    listLayout.VerticalFlex = Enum.UIFlexAlignment.Fill
    listLayout.Parent = container
    
    return container
end


local function createCell(x: number, y: number): Frame?
    local address = BoardUtils.toAddress(x, y)

    if not address then
        return
    end

    local cell = Instance.new("Frame")
    cell.Name = address
    cell.LayoutOrder = x
    cell.BorderSizePixel = 0
    
    return cell
end


local function newGame(blockerAddresses: { string }): ()
    BoardService.reset(board)
    BoardService.setBlocked(board, blockerAddresses)

    for address, _ in board do
        cells[address].BackgroundColor3 = CellColours.unoccupied
    end
    
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


initialise()

remotes.BroadcastNewBoard.OnClientEvent:Connect(newGame)


return Board
