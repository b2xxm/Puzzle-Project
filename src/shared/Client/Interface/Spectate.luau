local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")


local shared = ReplicatedStorage.Shared
local client = shared.Client


local TweenUtils = require(shared.TweenUtils)
local PlayerListConfig = require(client.Interface.PlayerList.Config)


local SPECTATE_ACTION_NAME = "Spectate"
local SPECTATE_ACTION_INPUTS = {
    Enum.UserInputType.MouseButton1,
    Enum.UserInputType.MouseMovement
}


local player: Player = Players.LocalPlayer
local currentHover: GuiObject? = nil
local previousHover: GuiObject? = nil


local Spectate = {}


local function hover(object: GuiObject, enabled: boolean): ()
    TweenUtils.cancel(object)

    local goal = PlayerListConfig.hover.goals[enabled]
    
    local tween = TweenUtils.create(object, PlayerListConfig.hover.tweenInfo, goal)
    tween:Play()
end


local function update(input: InputObject): ()
    local playerGui = player.PlayerGui
    local gameUi = playerGui:WaitForChild("GameUi")
    local playerList = gameUi:WaitForChild("Players") :: Frame
        
    local guiObjects = playerGui:GetGuiObjectsAtPosition(input.Position.X, input.Position.Y)

    previousHover = currentHover
    
    for _, row in playerList:GetChildren() do
        local name = row:FindFirstChild("PlayerName") :: GuiObject
        
        if not name then
            continue
        end

        local background = name:WaitForChild("Background") :: GuiObject

        if table.find(guiObjects, background) then
            currentHover = name
            
            break
        end

        currentHover = nil
    end

    if previousHover == currentHover then
        return Enum.ContextActionResult.Pass
    end

    if previousHover then
        hover(previousHover, false)
    end

    if currentHover then
        hover(currentHover, true)
    end
end


local function action(_: string, state: Enum.UserInputState, input: InputObject): Enum.ContextActionResult
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if state == Enum.UserInputState.Begin then
            -- select player to receive broadcast from
            -- or if same selected player then stop broadcast
            -- and other logic regarding switching to different broadcast
        end

    elseif input.UserInputType == Enum.UserInputType.MouseMovement then
        if state == Enum.UserInputState.Change then
            update(input)
        end
    end

    return Enum.ContextActionResult.Pass
end


function Spectate.enable(): ()
    -- ensure that player has finished the board

    ContextActionService:BindAction(
        SPECTATE_ACTION_NAME,
        action,
        false,
        table.unpack(SPECTATE_ACTION_INPUTS)
    )
end


function Spectate.disable(): ()
    -- stop receiving broadcast and clear current broadcast

    ContextActionService:UnbindAction(SPECTATE_ACTION_NAME)
end


function Spectate.start(): ()
    -- start receiving broadcast
end


function Spectate.stop(): ()
    -- stop receiving broadcast and clear current broadcast
end


Spectate.enable() -- temporary


return Spectate