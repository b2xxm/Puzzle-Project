--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local GuiService = game:GetService("GuiService")


local shared = ReplicatedStorage.Shared
local client = shared.Client


local Types = require(shared.Types)
local Reserve = require(client.Interface.Reserve)


type PieceObjectInfo = Types.PieceObjectInfo


local player: Player = Players.LocalPlayer
local camera: Camera = Workspace.CurrentCamera
local selected: PieceObjectInfo? = nil


local Selector = {}
Selector.actionName = "PieceSelection"
Selector.inputs = {
    Enum.UserInputType.MouseButton1,
    Enum.UserInputType.MouseMovement
}


local function position(input: InputObject): UDim2
    local inset = (GuiService:GetGuiInset()).Y

    return UDim2.fromScale(
        input.Position.X / camera.ViewportSize.X,
        (input.Position.Y + inset) / camera.ViewportSize.Y
    )
end


function Selector.actionCallback(_: string, state: Enum.UserInputState, input: InputObject): ()
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if state == Enum.UserInputState.Begin then
            -- select/ enable rotate + flip
            
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
                    selected.object.Position = position(input)

                    break
                end
            end
        else
            selected = nil
        end
    else
        if state ~= Enum.UserInputState.Change or not selected then
            return
        end

        selected.object.Position = position(input)
    end
end


return Selector