--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")


local shared = ReplicatedStorage.Shared


local Types = require(shared.Types)
local BoardUtils = require(script.Utils)
local Config = require(script.Config)
local Piece = require(script.Piece)


type Board = Types.Board
type PieceType = Types.PieceType


local Board = {}


function Board.new(): Board
    local board = {} :: Board

    for y = 1, Config.rows do
        for x = 1, Config.columns do
            local address = BoardUtils.toAddress(x, y)

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

    local pieces = {}

    for address, pieceType in board do
        local inputPieceType: PieceType = input[address]

        if not inputPieceType then
            return false
        end

        if pieceType == "none" then
            if inputPieceType == "none" or inputPieceType == "blocker" then
                return false
            end
        end

        if pieceType == "blocker" then
            if inputPieceType == "blocker" then
                continue
            else
                return false
            end
        end

        if not Piece.isAType(inputPieceType) then
            return false
        end

        if not pieces[inputPieceType] then
            pieces[inputPieceType] = {}
        end

        table.insert(pieces[inputPieceType], address)
    end

    for pieceType, addresses in pieces do
        if not Piece.validateShape(pieceType :: PieceType, addresses) then
            return false
        end
    end

    return true
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
