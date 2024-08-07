--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")


local shared = ReplicatedStorage.Shared


local Types = require(shared.Types)
local BoardUtils = require(script.Parent.Utils)
local Config = require(script.Parent.Config)


type Board = Types.Board
type PieceType = Types.PieceType
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


local Piece = {}


local function getShapeBounds(addresses: { string }): ShapeBounds
    local shapeBounds = {
        top = Config.rows,
        bottom = 1,
        left = Config.columns,
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


function Piece.isAType(toCheck: string): boolean
    for _, pieceType: PieceType in pieceTypes do
        if toCheck == pieceType then
            return true
        end
    end

    return false
end


function Piece.validateShape(pieceType: PieceType, addresses: { string }): boolean
    local shapeBounds = getShapeBounds(addresses)
    local shapeBinary = {}

    for y = shapeBounds.top, shapeBounds.bottom do
        local binaryRow = 0

        for x = shapeBounds.left, shapeBounds.right do
            binaryRow = bit32.lshift(binaryRow, 1)

            local address = BoardUtils.toAddress(x, y)

            if not address then
                continue
            end

            if table.find(addresses, address) then
                binaryRow += 1
            end
        end

        table.insert(shapeBinary, binaryRow)
    end

    local variations = pieceDatas[pieceType]

    for _, pieceData in variations do
        local isMatch = true

        for index, binary in pieceData do
            if shapeBinary[index] == binary then
                continue
            end

            isMatch = false

            break
        end

        if isMatch then
            return true
        end
    end

    return false
end


return Piece
