--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")


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
type PieceData = Types.PieceData


local player: Player = Players.LocalPlayer
local camera: Camera = Workspace.CurrentCamera
local reserved: { [PieceType]: PieceShape } = {}


local Reserve = {}


local function fillPieceCells(container: Frame, pieceData: PieceData, pieceType: PieceType): ()
    for rowIndex, shapeRow in pieceData.data do
        local rowContainerPrefab = prefabs.Grid:WaitForChild("RowContainer") :: Frame
        local rowContainer = rowContainerPrefab:Clone()
        rowContainer.LayoutOrder = rowIndex

        local listLayout = rowContainer:WaitForChild("UIListLayout") :: UIListLayout
        listLayout.Padding = UDim.new(0, BoardInterfaceConfig.padding)

        for bitPosition = pieceData.metadata.width - 1, 0, -1 do
            local bit = bit32.extract(shapeRow, bitPosition, 1)

            local pieceCellPrefab = prefabs.Grid:WaitForChild("Cell") :: Frame
            local pieceCell = pieceCellPrefab:Clone()
            pieceCell.Transparency = 1 - bit
            pieceCell.LayoutOrder = pieceData.metadata.width - bitPosition
            pieceCell.BackgroundColor3 = CellColours.occupied[pieceType]
            pieceCell.Parent = rowContainer
        end

        rowContainer.Parent = container
    end
end


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
    local boundSizeX = ((cellSizeX + padding) * pieceData.metadata.width) - padding
    local boundSizeY = ((cellSizeY + padding) * pieceData.metadata.height) - padding
    
    local piecePrefab = prefabs.Piece:WaitForChild("Bounds") :: Frame
    local piece = piecePrefab:Clone()
    piece.Size = UDim2.fromScale(boundSizeX / camera.ViewportSize.X, 0)

    local aspectRatio = piece:WaitForChild("UIAspectRatioConstraint") :: UIAspectRatioConstraint
    aspectRatio.AspectRatio = boundSizeX / boundSizeY

    local listLayout = piece:WaitForChild("UIListLayout") :: UIListLayout
    listLayout.Padding = UDim.new(0, padding)

    fillPieceCells(piece, pieceData, pieceType)

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

--[[    STEPS

> clone new piece ( and set padding )
> generate piece bound size from cell size of grid ( x, y )
> set piece size to ( x / viewportSizeX, 0 ) // y size is unnecessary due to aspect ratio
> set aspect ratio ( x / y )
> fill in piece rows to make up the piece

]]