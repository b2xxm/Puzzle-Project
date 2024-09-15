local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


local shared = ReplicatedStorage.Shared
local prefabs = ReplicatedStorage.Prefabs
local client = shared.Client


local TweenUtils = require(shared.TweenUtils)
local PlayerListConfig = require(script.Config)
local Spectate = require(client.Interface.Spectate)
local Input = require(client.Input)


local player: Player = Players.LocalPlayer
local rows: { [Player]: GuiObject } = {}
local visibilityStatus: boolean = true


local PlayerList = {}


local function initialise(): ()
    for _, otherPlayer in Players:GetChildren() do
        PlayerList.addPlayer(otherPlayer)
    end
end


function PlayerList.addPlayer(otherPlayer: Player): ()
    local playerGui = player.PlayerGui
    
    local gameUi = playerGui:WaitForChild("GameUi")
    local playerList = gameUi:WaitForChild("Players")

    local rowPrefab = prefabs.PlayerList:WaitForChild("Row")
    local row = rowPrefab:Clone()
    row.Name = otherPlayer.Name
    row.PlayerName.Text = otherPlayer.Name
    row.Parent = playerList

    rows[otherPlayer] = row
end


function PlayerList.removePlayer(otherPlayer: Player): ()
    local row = rows[otherPlayer]

    if not row then
        return
    end

    row:Destroy()

    rows[otherPlayer] = nil
end


function PlayerList.setFinished(otherPlayer: Player): ()
    local row = rows[otherPlayer]

    if not row then
        return
    end

    local name = row:WaitForChild("PlayerName")
    local background = name:WaitForChild("Background") :: GuiObject

    background.BackgroundColor3 = PlayerListConfig.colours.finished
end


function PlayerList.reset(): ()
    for _, row in rows do
        local name = row:WaitForChild("PlayerName")
        local background = name:WaitForChild("Background") :: GuiObject

        background.BackgroundColor3 = PlayerListConfig.colours.unfinished
    end
end


function PlayerList.toggleVisibility(_: string, inputState: Enum.UserInputState, _: InputObject): Enum.ContextActionResult
    if inputState ~= Enum.UserInputState.Begin then
        return Enum.ContextActionResult.Pass
    end

    local playerGui = player.PlayerGui
    
    local gameUi = playerGui:WaitForChild("GameUi")
    local playerList = gameUi:WaitForChild("Players") :: GuiObject

    visibilityStatus = not visibilityStatus

    if not visibilityStatus then
        Spectate.disable()
    end

    local goal = PlayerListConfig.toggle.goals[visibilityStatus]
    
    for _, row in playerList:GetChildren() do
        if not row:IsA("GuiObject") then
            continue
        end

        TweenUtils.cancel(row)

        local rowLabel = row:WaitForChild("PlayerName") :: GuiObject
        local tween = TweenUtils.create(rowLabel, PlayerListConfig.toggle.tweenInfo, goal)

        tween.Completed:Once(function(_: Enum.PlaybackState)
            if not visibilityStatus then
                return
            end

            Spectate.enable()
        end)

        tween:Play()
    end

    return Enum.ContextActionResult.Pass
end


initialise()

Input.register(
    "TogglePlayerList",
    PlayerList.toggleVisibility,
    Enum.ContextActionPriority.Medium.Value,
    true,
    Enum.KeyCode.Tab
)


return PlayerList
