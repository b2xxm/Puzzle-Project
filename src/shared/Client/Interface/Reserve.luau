--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


local shared = ReplicatedStorage.Shared
local prefabs = ReplicatedStorage.Prefabs
local client = shared.Client


local Types = require(shared.Types)
local PieceService = require(shared.PieceService)
local BoardConfig = require(shared.BoardService.Config)
local BoardInterfaceConfig = require(client.Interface.Board.Config)
local CellColours = require(client.Interface.Board.CellColours)


type PieceType = Types.PieceType
type PieceShape = Types.PieceShape


local player: Player = Players.LocalPlayer
local reserved: { [PieceType]: PieceShape } = {}


local Reserve = {}


local function generatePiece(shape: PieceShape, pieceType: PieceType): Frame
    local pieceData = PieceService.getPieceDataByShape(shape)

    local playerGui = player.PlayerGui
    
    local gameUi = playerGui:WaitForChild("GameUi")
    local boardFrame = gameUi:WaitForChild("Board")
    local grid = boardFrame:WaitForChild("Grid") :: Frame

    local padding = BoardInterfaceConfig.padding
    local rows, columns = BoardConfig.rows, BoardConfig.columns

    local cellSizeX = (grid.AbsoluteSize.X - (padding * (columns - 1))) / columns
    local cellSizeY = (grid.AbsoluteSize.Y - (padding * (rows - 1))) / rows

    local piecePrefab = prefabs.Piece:WaitForChild("Bounds") :: Frame
    local piece = piecePrefab:Clone()
    piece.Name = pieceType
    
    -- later make it adapt to new size, on viewport size change
    piece.Size = UDim2.fromOffset(
        ((cellSizeX + padding) * pieceData.metadata.width) - padding,
        ((cellSizeY + padding) * pieceData.metadata.height) - padding
    )

    local gridLayout = piece:WaitForChild("UIGridLayout") :: UIGridLayout
    gridLayout.CellPadding = UDim2.fromOffset(padding, padding)
    gridLayout.CellSize = UDim2.fromOffset(cellSizeX, cellSizeY)

    for rowIndex, shapeRow in pieceData.data do
        for bitPosition = 0, pieceData.metadata.width - 1 do
            local bit = bit32.extract(shapeRow, bitPosition, 1)

            local pieceCellPrefab = prefabs.Piece:WaitForChild("Cell") :: Frame
            local pieceCell = pieceCellPrefab:Clone()
            pieceCell.Transparency = 1 - bit
            pieceCell.ZIndex = (rowIndex - 1) * pieceData.metadata.width + bitPosition + 1
            pieceCell.BackgroundColor3 = CellColours.occupied[pieceType]
            pieceCell.Parent = piece
        end
    end

    piece.Parent = gameUi:WaitForChild("Reserve")

    return piece
end


function Reserve.scatter(): ()
    local pieceDatas = PieceService.getPieceDatas()

    for pieceType: PieceType, variations in pieceDatas do
        local shapeIndex = math.random(#variations)
        local shape = variations[shapeIndex]

        reserved[pieceType] = shape

        local piece = generatePiece(shape, pieceType)

        -- temporary to view each piece
        piece.Position = UDim2.fromOffset(
            math.random(100, 1000),
            math.random(100, 500)
        )
    end
end


return Reserve

-- get piece data
-- generate piece ui (interactable)
-- scatter functionality (take all pieces back from board)
-- place back into reserve