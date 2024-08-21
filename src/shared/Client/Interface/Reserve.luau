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
type PieceObjectInfo = Types.PieceObjectInfo


local player: Player = Players.LocalPlayer
local camera: Camera = Workspace.CurrentCamera
local reserved: { PieceObjectInfo } = {}


local Reserve = {}
Reserve.reserved = reserved


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

function randomPosition()
    -- fix magic numbers after

    while true do
        local x = (math.random() * 0.8) + 0.1
        
        if x <= 0.35 or x >= 0.65 then
            local y = (math.random() * 0.8) + 0.1
            
            return x, y
        end
    end
end


function Reserve.scatter(): ()
    for pieceType: PieceType, variations in PieceService.pieceVariationsMap do
        local shapeIndex = math.random(#variations)
        local shape = variations[shapeIndex]

        local piece = generatePiece(shape, pieceType)
        piece.Position = UDim2.fromScale(randomPosition())
        
        table.insert(reserved, {
            type = pieceType,
            shape = shape,
            object = piece
        })
    end
end

return Reserve
