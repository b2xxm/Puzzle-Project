local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")


local shared = ReplicatedStorage.Shared
local client = shared.Client


local Types = require(shared.Types)
local Input = require(client.Input)
local InterfaceUtils = require(client.Interface.Utils)
local Selector = require(client.Interface.Selector)


type DeviceType = Types.DeviceType


local player: Player = Players.LocalPlayer
local cursor: GuiObject = nil


local Cursor = {}


local function init(): ()
    local playerGui = player.PlayerGui
    local gameUi = playerGui:WaitForChild("GameUi")

    cursor = gameUi:WaitForChild("UserCursor") :: GuiObject
end


local function move(position: Vector3): ()
    local x, y = InterfaceUtils.toScalePosition(position.X, position.Y)

    cursor.Position = UDim2.fromScale(
        math.clamp(x, 0, 1),
        math.clamp(y, 0, 1)
    )
end


local function desktopAction(_: string, state: Enum.UserInputState, input: InputObject): Enum.ContextActionResult
    if state == Enum.UserInputState.Change then
        move(input.Position)

    elseif state == Enum.UserInputState.Begin then
        move(input.Position)
        
        cursor.Visible = true

    elseif state == Enum.UserInputState.End then
        cursor.Visible = false
    end

    return Enum.ContextActionResult.Pass
end


local function mobileAction(): (string, Enum.UserInputState, InputObject) -> Enum.ContextActionResult
    local currentInput: InputObject? = nil
    local currentPosition: Vector3 = nil
    local startPosition: Vector3 = nil
    
    return function(_: string, state: Enum.UserInputState, input: InputObject): Enum.ContextActionResult
        if state == Enum.UserInputState.Begin then
            if currentInput then
                return Enum.ContextActionResult.Pass
            end
            
            startPosition = input.Position
            currentPosition = Vector3.new(cursor.AbsolutePosition.X, cursor.AbsolutePosition.Y, 0)
            currentInput = input
    
        elseif state == Enum.UserInputState.End then
            if input == currentInput then
                currentInput = nil
            end

        elseif state == Enum.UserInputState.Change then
            if not currentInput then
                return Enum.ContextActionResult.Pass
            end

            local delta = input.Position - startPosition

            move(currentPosition + delta)

            local newPosition = Cursor.getCursorPosition()
            Selector.action(state, Enum.UserInputType.MouseMovement, newPosition)
        end
    
        return Enum.ContextActionResult.Pass
    end
end


function Cursor.enable(deviceType: DeviceType)
    if deviceType == "Desktop" then
        Input.register(
            "CursorMove",
            desktopAction,
            Enum.ContextActionPriority.High.Value,
            true,
            Enum.UserInputType.MouseMovement
        )

    elseif deviceType == "Mobile" then
        Input.register(
            "CursorMove",
            mobileAction(),
            Enum.ContextActionPriority.High.Value,
            true,
            Enum.UserInputType.Touch
        )
    end
end


function Cursor.getCursorPosition(): Vector3
    return Vector3.new(cursor.AbsolutePosition.X, cursor.AbsolutePosition.Y, 0)
end


init()


return Cursor