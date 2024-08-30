local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")


local prefabs = ReplicatedStorage.Prefabs


local Colours = require(script.Colours)


local TWEEN_INFO = TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local GOALS = {
    [true] = { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0) },
    [false] = { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(1, 10, 0.5, 0) }
}


local player: Player = Players.LocalPlayer
local rows: { [Player]: GuiObject } = {}
local visibilityStatus: boolean = true
local tweens: { [GuiObject]: Tween } = {}


local PlayerList = {}
PlayerList.actionName = "ToggleList"
PlayerList.input = Enum.KeyCode.Tab


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

    background.BackgroundColor3 = Colours.finished
end


function PlayerList.reset(): ()
    for _, row in rows do
        local name = row:WaitForChild("PlayerName")
        local background = name:WaitForChild("Background") :: GuiObject

        background.BackgroundColor3 = Colours.unfinished
    end
end


function PlayerList.toggleVisibility(_: string, inputState: Enum.UserInputState, _: InputObject): ()
    if inputState ~= Enum.UserInputState.Begin then
        return
    end

    for _, activeTween in tweens do
        activeTween:Cancel()
    end

    local playerGui = player.PlayerGui
    
    local gameUi = playerGui:WaitForChild("GameUi")
    local playerList = gameUi:WaitForChild("Players") :: GuiObject

    visibilityStatus = not visibilityStatus

    local goal = GOALS[visibilityStatus]
    
    for _, row in playerList:GetChildren() do
        if not row:IsA("GuiObject") then
            continue
        end

        local rowLabel = row:WaitForChild("PlayerName") :: GuiObject
        local newTween = TweenService:Create(rowLabel, TWEEN_INFO, goal)

        newTween.Completed:Connect(function(playbackState: Enum.PlaybackState)
            if playbackState ~= Enum.PlaybackState.Completed then
                if playbackState ~= Enum.PlaybackState.Cancelled then
                    return
                end
            end

            newTween:Destroy()
            
            tweens[row] = nil
        end)

        newTween:Play()

        tweens[row] = newTween
    end
end


initialise()


return PlayerList
