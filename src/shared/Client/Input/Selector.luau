--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local Workspace = game:GetService("Workspace")
local GuiService = game:GetService("GuiService")


local shared = ReplicatedStorage.Shared
local client = shared.Client


local Types = require(shared.Types)
local PieceService = require(shared.PieceService)
local Reserve = require(client.Interface.Reserve)


type PieceObjectInfo = Types.PieceObjectInfo
type PieceActionInputs = {
    flip: { horizontal: Enum.KeyCode, vertical: Enum.KeyCode },
    rotate: { counterclockwise: Enum.KeyCode, clockwise: Enum.KeyCode },
}


local player: Player = Players.LocalPlayer
local camera: Camera = Workspace.CurrentCamera
local selected: PieceObjectInfo? = nil


local PIECE_ACTION_NAME: string = "PieceAction"
local PIECE_ACTION_INPUTS: PieceActionInputs = {
    flip = {
        horizontal = Enum.KeyCode.R,
        vertical = Enum.KeyCode.T
    },
    rotate = {
        clockwise = Enum.KeyCode.E,
        counterclockwise = Enum.KeyCode.Q
    }
}


local Selector = {}
Selector.actionName = "PieceSelection"
Selector.inputs = {
    Enum.UserInputType.MouseButton1,
    Enum.UserInputType.MouseMovement
}


local function getPosition(input: InputObject): UDim2
    local inset = (GuiService:GetGuiInset()).Y

    return UDim2.fromScale(
        input.Position.X / camera.ViewportSize.X,
        (input.Position.Y + inset) / camera.ViewportSize.Y
    )
end


local function pieceAction(_: string, state: Enum.UserInputState, input: InputObject): ()
    if state ~= Enum.UserInputState.Begin or not selected then
        return
    end

    local position = selected.object.Position

    selected.object:Destroy()

    if input.KeyCode == PIECE_ACTION_INPUTS.flip.horizontal then
        PieceService.flipHorizontal(selected.pieceData)

    elseif input.KeyCode == PIECE_ACTION_INPUTS.flip.vertical then
        PieceService.flipVertical(selected.pieceData)

    elseif input.KeyCode == PIECE_ACTION_INPUTS.rotate.clockwise then
        PieceService.rotate(selected.pieceData, true)

    elseif input.KeyCode == PIECE_ACTION_INPUTS.rotate.counterclockwise then
        PieceService.rotate(selected.pieceData, false)
    end

    selected.object = Reserve.generatePiece(selected.pieceData.shape, selected.pieceData.type)
    selected.object.Position = position
end


function Selector.action(_: string, state: Enum.UserInputState, input: InputObject): ()
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if state == Enum.UserInputState.Begin then
            local playerGui = player.PlayerGui
            
            local x, y = input.Position.X, input.Position.Y
            local guiObjects = playerGui:GetGuiObjectsAtPosition(x, y)

            for _, object in guiObjects do
                for _, reserveInfo in Reserve.reserved do
                    if object ~= reserveInfo.object then
                        continue
                    end

                    selected = reserveInfo

                    break
                end

                if selected then
                    selected.object.Position = getPosition(input)

                    break
                end
            end

            ContextActionService:BindAction(
                PIECE_ACTION_NAME,
                pieceAction,
                false,
                PIECE_ACTION_INPUTS.flip.horizontal,
                PIECE_ACTION_INPUTS.flip.vertical,
                PIECE_ACTION_INPUTS.rotate.clockwise,
                PIECE_ACTION_INPUTS.rotate.counterclockwise
            )
        else
            selected = nil
            
            ContextActionService:UnbindAction(PIECE_ACTION_NAME)
        end
    else
        if state ~= Enum.UserInputState.Change or not selected then
            return
        end

        selected.object.Position = getPosition(input)
    end
end


return Selector