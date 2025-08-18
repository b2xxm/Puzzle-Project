local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")


local shared = ReplicatedStorage.Shared
local prefabs = ReplicatedStorage.Prefabs
local client = shared.Client


local Types = require(shared.Types)
local PieceService = require(shared.PieceService)
local Configuration = require(shared.Configuration)
local InterfaceUtils = require(client.Interface.Utils)


type PieceType = Types.PieceType
type PieceShape = Types.PieceShape
type PieceData = Types.PieceData
type PieceObjectInfo = Types.PieceObjectInfo


local MAX_SCALE_VARIATION = 0.8
local OFFSET = (1 - MAX_SCALE_VARIATION) / 2


local player: Player = Players.LocalPlayer
local camera: Camera = Workspace.CurrentCamera
local reserved: { PieceObjectInfo } = {}


local Reserve = {}
Reserve.reserved = reserved


local function init(): ()
    while camera.ViewportSize.X == 1 and camera.ViewportSize.Y == 1 do
        camera:GetPropertyChangedSignal("ViewportSize"):Wait()
    end
end


local function randomPosition(): (number, number)
    local playerGui = player.PlayerGui
    local gameUi = playerGui:WaitForChild("GameUi")
    local boardFrame = gameUi:WaitForChild("Board") :: Frame

    while true do
        local xScale = (math.random() * MAX_SCALE_VARIATION) + OFFSET
        local yScale = (math.random() * MAX_SCALE_VARIATION) + OFFSET

        local xOffset, yOffset = InterfaceUtils.toOffsetPosition(xScale, yScale)
        
        local guiObjects = playerGui:GetGuiObjectsAtPosition(xOffset, yOffset)

        if not table.find(guiObjects, boardFrame) then
            return xScale, yScale
        end
    end
end


local function fillPieceCells(container: GuiObject, pieceData: PieceData, pieceType: PieceType): ()
    for rowIndex, shapeRow in pieceData.shape do
        local rowContainerPrefab = prefabs.Piece:WaitForChild("RowContainer") :: Frame
        local rowContainer = rowContainerPrefab:Clone()
        rowContainer.LayoutOrder = rowIndex

        local listLayout = rowContainer:WaitForChild("UIListLayout") :: UIListLayout
        listLayout.Padding = UDim.new(0, Configuration.boardInterface.padding)

        for bitPosition = pieceData.metadata.width - 1, 0, -1 do
            local bit = bit32.extract(shapeRow, bitPosition, 1)

            local pieceCellPrefab = prefabs.Grid:WaitForChild("Cell") :: Frame
            local pieceCell = pieceCellPrefab:Clone()
            pieceCell.Transparency = 1 - bit
            pieceCell.LayoutOrder = pieceData.metadata.width - bitPosition
            pieceCell.BackgroundColor3 = Configuration.boardInterface.colours.occupied[pieceType]
            pieceCell.ZIndex = 3 -- arbitrary ik
            pieceCell.Parent = rowContainer
        end

        rowContainer.Parent = container
    end
end


function Reserve.generatePiece(shape: PieceShape, pieceType: PieceType): PieceObjectInfo
    local pieceData = PieceService.getPieceDataByShape(shape, pieceType)

    local playerGui = player.PlayerGui
    
    local gameUi = playerGui:WaitForChild("GameUi")
    local boardFrame = gameUi:WaitForChild("Board")
    local grid = boardFrame:WaitForChild("Grid") :: Frame

    local padding = Configuration.boardInterface.padding
    local rows, columns = Configuration.board.rows, Configuration.board.columns

    local cellSizeX = (grid.AbsoluteSize.X - (padding * (columns - 1))) / columns
    local cellSizeY = (grid.AbsoluteSize.Y - (padding * (rows - 1))) / rows
    local boundSizeX = ((cellSizeX + padding) * pieceData.metadata.width) - padding
    local boundSizeY = ((cellSizeY + padding) * pieceData.metadata.height) - padding

    local piecePrefab = prefabs.Piece:WaitForChild("Bounds") :: GuiObject
    local piece = piecePrefab:Clone()
    piece.Size = UDim2.fromScale(0, boundSizeY / camera.ViewportSize.Y)

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
    local otherObjectInfo, index = Reserve.findPieceByType(objectInfo.pieceData.type)

    if otherObjectInfo then
        objectInfo.object:Destroy()

        table.remove(reserved, index)
    end
end


function Reserve.removePieceObjects(): ()
    for _, objectInfo in reserved do
        objectInfo.object:Destroy()
    end

    table.clear(reserved)
end


function Reserve.findPieceByType(pieceType: PieceType): (PieceObjectInfo?, number?)
    for index, objectInfo in reserved do
        if objectInfo.pieceData.type == pieceType then
            return objectInfo, index
        end
    end

    return
end


init()


return Reserve
