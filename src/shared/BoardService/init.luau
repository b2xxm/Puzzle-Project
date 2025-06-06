local ReplicatedStorage = game:GetService("ReplicatedStorage")


local shared = ReplicatedStorage.Shared


local Types = require(shared.Types)
local BoardUtils = require(script.Utils)
local Configuration = require(shared.Configuration)
local PieceService = require(shared.PieceService)


type Board = Types.Board
type PieceType = Types.PieceType


local BoardService = {}


function BoardService.new(): Board
    local board = {} :: Board

    for y = 1, Configuration.board.rows do
        for x = 1, Configuration.board.columns do
            local address = BoardUtils.toAddress(x, y) :: string
            board[address] = "none"
        end
    end

    return board
end


function BoardService.validate(board: Board, input: Board): boolean
    if typeof(input) ~= "table" then
        return false
    end

    local pieces = {}

    for address, pieceType in board do
        local inputPieceType = input[address]

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

        if not PieceService.isAType(inputPieceType) then
            return false
        end

        if not pieces[inputPieceType] then
            pieces[inputPieceType] = {}
        end

        table.insert(pieces[inputPieceType], address)
    end

    for pieceType, addresses in pieces do
        if not PieceService.validateShape(pieceType :: PieceType, addresses) then
            return false
        end
    end

    return true
end


function BoardService.setBlocked(board: Board, addresses: { string }): ()
    for _, address in addresses do
        board[address] = "blocker"
    end
end


function BoardService.reset(board: Board): ()
    for address in board do
        board[address] = "none"
    end
end


function BoardService.placePiece(board: Board, addresses: { string }, pieceType: PieceType): boolean
    if not PieceService.validateShape(pieceType, addresses) then
        return false
    end

    local changedCell = {}

    for _, address in addresses do
        if board[address] ~= "none" then
            for _, changedAddress in changedCell do
                board[changedAddress :: string] = "none"
            end

            return false
        end

        board[address] = pieceType

        table.insert(changedCell, address)
    end

    return true
end


return BoardService
