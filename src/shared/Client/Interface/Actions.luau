local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")


local shared = ReplicatedStorage.Shared
local client = shared.Client


local Utils = require(shared.Utils)
local Types = require(shared.Types)
local Input = require(client.Input)
local Selector = require(client.Interface.Selector)
local Keybinding = require(client.Keybinding)
local Cursor = require(client.Cursor)


type DeviceType = Types.DeviceType


local player: Player = Players.LocalPlayer
local deviceType: DeviceType = "Desktop"


local Actions = {}


local function desktop(): ()
    local playerGui = player.PlayerGui
    local gameUi = playerGui:WaitForChild("GameUi")

    local actions = gameUi:WaitForChild("Actions")
    local desktopActions = actions:WaitForChild("Desktop") :: Frame

    desktopActions.Visible = true

    Input.register(
        "PieceSelector",
        function(_: string, state: Enum.UserInputState, input: InputObject): Enum.ContextActionResult
            Selector.action(state, input.UserInputType, input.Position)

            return Enum.ContextActionResult.Pass
        end,
        Enum.ContextActionPriority.High.Value,
        false,
        Enum.UserInputType.MouseButton1,
        Enum.UserInputType.MouseMovement
    )

    Input.register(
        "PieceAction",
        function(_: string, state: Enum.UserInputState, input: InputObject): Enum.ContextActionResult
            Selector.pieceAction(state, input.KeyCode)

            return Enum.ContextActionResult.Pass
        end,
        Enum.ContextActionPriority.High.Value + 1,
        false,
        Keybinding.PieceAction.FlipHorizontal,
        Keybinding.PieceAction.FlipVertical,
        Keybinding.PieceAction.RotateClockwise,
        Keybinding.PieceAction.RotateCounterClockwise
    )

    -- edit text based off of custom keybinds
end


local function mobile(): ()
    local playerGui = player.PlayerGui
    local gameUi = playerGui:WaitForChild("GameUi")

    local actions = gameUi:WaitForChild("Actions")
    local mobileActions = actions:WaitForChild("Mobile") :: Frame

    mobileActions.Visible = true
    
    local action = mobileActions:WaitForChild("Action"):WaitForChild("Button") :: GuiButton
    local horizontal = mobileActions:WaitForChild("Horizontal"):WaitForChild("Button") :: GuiButton
    local vertical = mobileActions:WaitForChild("Vertical"):WaitForChild("Button") :: GuiButton
    local clockwise = mobileActions:WaitForChild("Clockwise"):WaitForChild("Button") :: GuiButton
    local counterClockwise = mobileActions:WaitForChild("CounterClockwise"):WaitForChild("Button") :: GuiButton

    local partial = Utils.partial(Selector.pieceAction, Enum.UserInputState.Begin)

    horizontal.MouseButton1Click:Connect(Utils.partial(partial, Keybinding.PieceAction.FlipHorizontal))
    vertical.MouseButton1Click:Connect(Utils.partial(partial, Keybinding.PieceAction.FlipVertical))
    clockwise.MouseButton1Click:Connect(Utils.partial(partial, Keybinding.PieceAction.RotateClockwise))
    counterClockwise.MouseButton1Click:Connect(Utils.partial(partial, Keybinding.PieceAction.RotateCounterClockwise))

    action.MouseButton1Click:Connect(function()
        local currentSelection = Selector.getSelected()

        if not currentSelection then
            Selector.action(Enum.UserInputState.Begin, Enum.UserInputType.MouseButton1, Cursor.getCursorPosition())
        else
            Selector.action(Enum.UserInputState.End, Enum.UserInputType.MouseButton1, Cursor.getCursorPosition())
        end
    end)
end


function Actions.setup(newType: DeviceType): ()
    deviceType = newType

    if deviceType == "Desktop" then
        desktop()
    else
        mobile()
    end
end


function Actions.enable(): ()
    
end


return Actions
