--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")


local shared = ReplicatedStorage.Shared


local Types = require(shared.Types)


type Board = Types.Board


local ROWS: number = 6
local COLUMNS: number = 6
local ASCII_OFFSET: number = 64


local Board = {}


local function validateCoordinates(x: number?, y: number?): boolean
    if typeof(x) ~= "number" or typeof(y) ~= "number" then
        return false
    end

    if x < 1 or x > ROWS then
        return false
    end

    if y < 1 or y > COLUMNS then
        return false
    end

    return true
end


local function toAddress(x: number, y: number): string?
    if not validateCoordinates(x, y) then
        return
    end

    local row = string.char(x + ASCII_OFFSET)
    local column = tostring(y)

    local address = row..column

    return address
end


-- local function toCoordinates(address: string): (number?, number?)
--     local row = address:gsub("%A", "")
--     local column = address:gsub("%D", "")

--     local x = string.byte(row) - ASCII_OFFSET
--     local y = tonumber(column)

--     if not validateCoordinates(x, y) then
--         return
--     end

--     return x, y
-- end


function Board.new(): Board
    local board: Board = {}

    for x = 1, ROWS do
        for y = 1, COLUMNS do
            local address = toAddress(x, y)

            if not address then
                continue
            end

            board[address] = "none"
        end
    end

    return board
end


function Board.validate(board: Board, input: Board): boolean
    if typeof(input) ~= "table" then
        return false
    end

    for address, pieceType in board do
        local inputPieceType = input[address]

        if not inputPieceType then
            return false
        end

        if pieceType == "none" and (inputPieceType == "none" or inputPieceType == "blocker") then
            return false
        end

        if pieceType == "blocker" and inputPieceType == "blocker" then
            continue
        else
            return false
        end

        -- advanced validation (sort piece by type and validate shape)
    end

    return true -- temporary
end


function Board.setBlocked(board: Board, addresses: { string }): ()
    for _, address in addresses do
        board[address] = "blocker"
    end
end


function Board.reset(board: Board): ()
    for address in board do
        board[address] = "none"
    end
end


return Board
