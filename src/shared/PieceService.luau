local ReplicatedStorage = game:GetService("ReplicatedStorage")


local shared = ReplicatedStorage.Shared


local Types = require(shared.Types)
local BoardUtils = require(shared.BoardService.Utils)
local Configuration = require(shared.Configuration)


type Board = Types.Board
type PieceType = Types.PieceType
type PieceShape = Types.PieceShape
type PieceData = Types.PieceData

type PieceVariations = { [PieceType]: { PieceShape } }
type ShapeBounds = { top: number, bottom: number, left: number, right: number }


local PIECE_VARIATIONS_MAP: PieceVariations = {
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
PieceService.pieceVariationsMap = PIECE_VARIATIONS_MAP


local function getShapeBounds(addresses: { string }): ShapeBounds
    local shapeBounds = {
        top = Configuration.board.rows,
        bottom = 1,
        left = Configuration.board.columns,
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


function PieceService.isAType(pieceType: string): boolean
    return PIECE_VARIATIONS_MAP[pieceType :: PieceType] ~= nil
end


function PieceService.validateShape(pieceType: PieceType, occupyingAddresses: { string }): boolean
    local pieceData = PieceService.getPieceDataByAddress(occupyingAddresses, pieceType)
    local pieceShape = pieceData.shape
    local variations = PIECE_VARIATIONS_MAP[pieceType]

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


function PieceService.getPieceDataByAddress(addresses: { string }, pieceType: PieceType): PieceData
    local shapeBounds = getShapeBounds(addresses)

    local shape = {}
    local metadata = {
        height = (shapeBounds.bottom - shapeBounds.top) + 1,
        width = (shapeBounds.right - shapeBounds.left) + 1
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

        table.insert(shape, rowBinary)
    end

    return { shape = shape, metadata = metadata, type = pieceType }
end


function PieceService.getPieceDataByShape(shape: PieceShape, pieceType: PieceType): PieceData
    local height = #shape
    local width = 0

    local mergedRows = bit32.bor(table.unpack(shape))

    while true do
        local bit = bit32.extract(mergedRows, width, 1)
        
        if bit == 0 then
            break
        end
        
        width += 1
    end
   
    local metadata = { height = height, width = width }

    return { shape = shape, metadata = metadata, type = pieceType }
end


function PieceService.rotate(pieceData: PieceData, clockwise: boolean): ()
    local oldShapeRows = pieceData.shape
    local oldMetadata = pieceData.metadata

    local newShapeRows = {}
    local newMetadata = {
        height = oldMetadata.width,
        width = oldMetadata.height
    }

    local positionStart, positionEnd, indexStart, indexEnd, step

    if clockwise then
        positionStart, positionEnd = oldMetadata.width - 1, 0
        indexStart, indexEnd = oldMetadata.height, 1
        step = -1
    else
        positionStart, positionEnd = 0, oldMetadata.width - 1
        indexStart, indexEnd = 1, oldMetadata.height
        step = 1
    end

    for bitPosition = positionStart, positionEnd, step do
        local newRowBinary = 0

        for rowIndex = indexStart, indexEnd, step do
            newRowBinary = bit32.lshift(newRowBinary, 1)

            local oldRowBinary = oldShapeRows[rowIndex]
            local bit = bit32.extract(oldRowBinary, bitPosition, 1)

            newRowBinary += bit
        end

        table.insert(newShapeRows, newRowBinary)
    end

    pieceData.shape = newShapeRows
    pieceData.metadata = newMetadata
end


function PieceService.flipHorizontal(pieceData: PieceData): ()
    local oldShapeRows = pieceData.shape
    local newShapeRows = {}

    for _, row in oldShapeRows do
        local flippedRow = 0

        for bitPosition = 1, pieceData.metadata.width do
            flippedRow = bit32.lshift(flippedRow, 1)
            
            local bit = bit32.extract(row, bitPosition - 1, 1)
            
            flippedRow += bit
        end

        table.insert(newShapeRows, flippedRow)
    end

    pieceData.shape = newShapeRows
end


function PieceService.flipVertical(pieceData: PieceData): ()
    local oldShapeRows = pieceData.shape
    local newShapeRows = {}

    for index = #oldShapeRows, 1, -1 do
        table.insert(newShapeRows, oldShapeRows[index])
    end

    pieceData.shape = newShapeRows
end


return PieceService
