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
local InterfaceUtils = require(client.Interface.Utils)


type PieceType = Types.PieceType
type PieceShape = Types.PieceShape
type PieceData = Types.PieceData
type PieceObjectInfo = Types.PieceObjectInfo


local player: Player = Players.LocalPlayer
local camera: Camera = Workspace.CurrentCamera
local reserved: { PieceObjectInfo } = {}


local Reserve = {}
Reserve.reserved = reserved


local function randomPosition(): (number, number)
    -- get rid of magic numbers
    local playerGui = player.PlayerGui
    local gameUi = playerGui:WaitForChild("GameUi")
    local boardFrame = gameUi:WaitForChild("Board") :: Frame

    while true do
        local xScale = (math.random() * 0.8) + 0.1
        local yScale = (math.random() * 0.8) + 0.1

        local xOffset, yOffset = InterfaceUtils.toOffsetPosition(xScale, yScale)
        
        local guiObjects = playerGui:GetGuiObjectsAtPosition(xOffset, yOffset)

        if not table.find(guiObjects, boardFrame) then
            return xScale, yScale
        end
    end
end


local function fillPieceCells(container: GuiObject, pieceData: PieceData, pieceType: PieceType): ()
    for rowIndex, shapeRow in pieceData.shape do
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
            pieceCell.BackgroundColor3 = BoardInterfaceConfig.colours.occupied[pieceType]
            pieceCell.Parent = rowContainer
        end

        rowContainer.Parent = container
    end
end


function Reserve.generatePiece(shape: PieceShape, pieceType: PieceType): PieceObjectInfo
    -- fix more scaling issues....
    local pieceData = PieceService.getPieceDataByShape(shape, pieceType)

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
    
    local piecePrefab = prefabs.Piece:WaitForChild("Bounds") :: GuiObject
    local piece = piecePrefab:Clone()
    piece.Size = UDim2.fromScale(boundSizeX / camera.ViewportSize.X, 0)

    local aspectRatio = piece:WaitForChild("UIAspectRatioConstraint") :: UIAspectRatioConstraint
    aspectRatio.AspectRatio = boundSizeX / boundSizeY

    local listLayout = piece:WaitForChild("UIListLayout") :: UIListLayout
    listLayout.Padding = UDim.new(0, padding)

    fillPieceCells(piece, pieceData, pieceType)

    piece.Parent = gameUi:WaitForChild("Reserve")

    local objectInfo = { pieceData = pieceData, object = piece }
    table.insert(reserved, objectInfo)

    return objectInfo
end


function Reserve.scatter(): ()
    Reserve.removePieceObjects()

    for pieceType: PieceType, variations in PieceService.pieceVariationsMap do
        local shapeIndex = math.random(#variations)
        local shape = variations[shapeIndex]

        local objectInfo = Reserve.generatePiece(shape, pieceType)
        objectInfo.object.Position = UDim2.fromScale(randomPosition())
    end
end


function Reserve.removePieceObject(objectInfo: PieceObjectInfo): ()
    for index, otherObjectInfo in reserved do
        if objectInfo == otherObjectInfo then
            objectInfo.object:Destroy()

            table.remove(reserved, index)

            break
        end
    end
end


function Reserve.removePieceObjects(): ()
    for _, objectInfo in reserved do
        objectInfo.object:Destroy()
    end

    table.clear(reserved)
end


return Reserve
