--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")


local shared = ReplicatedStorage.Shared


local Types = require(shared.Types)
local BoardUtils = require(shared.BoardService.Utils)
local BoardConfig = require(shared.BoardService.Config)


type Board = Types.Board
type PieceType = Types.PieceType
type PieceData = Types.PieceData
type ShapeBounds = { top: number, bottom: number, left: number, right: number }


local pieceTypes: { PieceType } = { "red", "orange", "yellow", "green", "lblue", "dblue", "purple", "brown", "grey", "blocker", "none" }

local pieceDatas: { [PieceType]: { { number } } } = {
    red = { { 0b110, 0b011 }, { 0b01, 0b11, 0b10 }, { 0b011, 0b110 }, { 0b10, 0b11, 0b01 } },
    orange = { { 0b111 }, { 0b1, 0b1, 0b1 } },
    yellow = { { 0b010, 0b111 }, { 0b10, 0b11, 0b10 }, { 0b111, 0b010 }, { 0b01, 0b11, 0b01 } },
    green = { { 0b11, 0b11 } },
    lblue = {
        { 0b10, 0b10, 0b11 }, { 0b111, 0b100 }, { 0b11, 0b01, 0b01 }, { 0b001, 0b111 },
        { 0b01, 0b01, 0b11 }, { 0b100, 0b111 }, { 0b11, 0b10, 0b10 }, { 0b111, 0b001 },
    },
    dblue = { { 0b1 } },
    purple = { { 0b10, 0b11 }, { 0b11, 0b10 }, { 0b11, 0b01 }, { 0b01, 0b11 } },
    brown = { { 0b1, 0b1 }, { 0b11 } },
    grey = { { 0b1, 0b1, 0b1, 0b1 }, { 0b1111 } },
}


local PieceService = {}


local function getShapeBounds(addresses: { string }): ShapeBounds
    local shapeBounds = {
        top = BoardConfig.rows,
        bottom = 1,
        left = BoardConfig.columns,
        right = 1
    }

    for _, address in addresses do
        local x, y = BoardUtils.toCoordinates(address)

        if not x or not y then
            continue
        end

        shapeBounds.top = if y < shapeBounds.top then y else shapeBounds.top
        shapeBounds.bottom = if y > shapeBounds.bottom then y else shapeBounds.bottom
        shapeBounds.left = if x < shapeBounds.left then x else shapeBounds.left
        shapeBounds.right = if x > shapeBounds.right then x else shapeBounds.right
    end

    return shapeBounds
end


function PieceService.isAType(toCheck: string): boolean
    for _, pieceType: PieceType in pieceTypes do
        if toCheck == pieceType then
            return true
        end
    end

    return false
end


function PieceService.validateShape(pieceType: PieceType, occupyingAddresses: { string }): boolean
    local pieceShape = PieceService.getPieceData(occupyingAddresses).data
    local variations = pieceDatas[pieceType]

    if not variations then
        return false
    end

    for _, variation in variations do
        local matches = true

        for index, row in variation do
            if pieceShape[index] == row then
                continue
            end

            matches = false

            break
        end

        if matches then
            return true
        end
    end

    return false
end


function PieceService.getPieceData(addresses: { string }): PieceData
    local shapeBounds = getShapeBounds(addresses)

    local shapeRows = {}
    local metadata = {
        rows = (shapeBounds.bottom - shapeBounds.top) + 1,
        columns = (shapeBounds.right - shapeBounds.left) + 1
    }

    for y = shapeBounds.top, shapeBounds.bottom do
        local rowBinary = 0

        for x = shapeBounds.left, shapeBounds.right do
            rowBinary = bit32.lshift(rowBinary, 1)

            local currentAddress = BoardUtils.toAddress(x, y)

            if not currentAddress then
                continue
            end

            if table.find(addresses, currentAddress) then
                rowBinary += 1
            end
        end

        table.insert(shapeRows, rowBinary)
    end
   
    return { data = shapeRows, metadata = metadata }
end


function PieceService.getPieceType(occupyingAddresses: { string }): PieceType
    for _, pieceType: PieceType in pieceTypes do
        if PieceService.validateShape(pieceType, occupyingAddresses) then
            return pieceType
        end
    end

    return "none"
end


function PieceService.rotate(pieceData: PieceData, clockwise: boolean): ()
    local oldShapeRows = pieceData.data
    local oldMetadata = pieceData.metadata

    local newShapeRows = {}
    local newMetadata = {
		rows = oldMetadata.columns,
		columns = oldMetadata.rows
	}

    local positionStart, positionEnd, indexStart, indexEnd, step

    if clockwise then
        positionStart, positionEnd = oldMetadata.columns, 1 
        indexStart, indexEnd = oldMetadata.rows, 1
        step = -1
    else
        positionStart, positionEnd = 1, oldMetadata.columns
        indexStart, indexEnd = 1, oldMetadata.rows
        step = 1
    end

    for bitPosition = positionStart, positionEnd, step do
        local newRowBinary = 0

        for rowIndex = indexStart, indexEnd, step do
            newRowBinary = bit32.lshift(newRowBinary, 1)

            local oldRowBinary = oldShapeRows[rowIndex]
            local bit = bit32.extract(oldRowBinary, bitPosition - 1, 1)

            newRowBinary += bit
        end

        table.insert(newShapeRows, newRowBinary)
    end

    pieceData.data = newShapeRows
    pieceData.metadata = newMetadata
end


function PieceService.flipHorizontal(pieceData: PieceData): ()
    local oldShapeRows = pieceData.data
    local newShapeRows = {}

    for _, row in oldShapeRows do
        local flippedRow = 0

        for bitPosition = 1, pieceData.metadata.columns do
            flippedRow = bit32.lshift(flippedRow, 1)
            
            local bit = bit32.extract(row, bitPosition - 1, 1)
            
            flippedRow += bit
        end

        table.insert(newShapeRows, flippedRow)
    end

    pieceData.data = newShapeRows
end


function PieceService.flipVertical(pieceData: PieceData): ()
    local oldShapeRows = pieceData.data
    local newShapeRows = {}

    for index = #oldShapeRows, 1, -1 do
        table.insert(newShapeRows, oldShapeRows[index])
    end

    pieceData.data = newShapeRows
end


return PieceService
