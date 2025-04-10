local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")


local remotes = ReplicatedStorage.Remotes
local shared = ReplicatedStorage.Shared
local client = shared.Client


local Cursor = require(client.Cursor)
local Board = require(client.Interface.Board)
local PlayerList = require(client.Interface.PlayerList)
local Selector = require(client.Interface.Selector)
local Reserve = require(client.Interface.Reserve)
local Timer = require(client.Interface.Board.Timer)
local Spectate = require(client.Interface.Spectate)
local Input = require(client.Input)
local Actions = require(client.Interface.Actions)
local Types = require(shared.Types)


type DeviceType = Types.DeviceType


local function newGame(blockerAddresses: { string }, startTime: number, duration: number): ()
    Board.newGame(blockerAddresses)
    Reserve.scatter()
    PlayerList.reset()
    Timer.start(startTime, duration)
    Selector.enable()
end


local function init(): ()
    GuiService.TouchControlsEnabled = false
    UserInputService.MouseIconEnabled = false

    local deviceType: DeviceType = if not UserInputService.KeyboardEnabled then "Mobile" else "Desktop"

    Cursor.enable(deviceType)
    Actions.setup(deviceType)
    Selector.setDeviceType(deviceType)
end


init()


remotes.BroadcastNewBoard.OnClientEvent:Connect(newGame)
remotes.UpdateFinishers.OnClientEvent:Connect(PlayerList.setFinished)
remotes.Spectate.Broadcast.OnClientEvent:Connect(Spectate.moveMouse)
remotes.Spectate.Simulate.OnClientEvent:Connect(Spectate.simulate)

Players.PlayerAdded:Connect(PlayerList.addPlayer)
Players.PlayerRemoving:Connect(PlayerList.removePlayer)

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)


remotes.Spectate.Request.OnClientInvoke = Selector.setBroadcastStatus

Input.register(
    "SinkMovement",
    function()
        return Enum.ContextActionResult.Sink
    end,
    Enum.ContextActionPriority.High.Value,
    true,
    table.unpack(Enum.PlayerActions:GetEnumItems())
)