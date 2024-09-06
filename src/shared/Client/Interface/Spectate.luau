local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")


local shared = ReplicatedStorage.Shared
local remotes = ReplicatedStorage.Remotes
local client = shared.Client


local Types = require(shared.Types)
local TweenUtils = require(shared.TweenUtils)
local PlayerListConfig = require(client.Interface.PlayerList.Config)
local BoardInterface = require(client.Interface.Board)
local Reserve = require(client.Interface.Reserve)


type Board = Types.Board
type PieceObjectInfo = Types.PieceObjectInfo
type ReservedPieces = Types.ReservedPieces


local SPECTATE_ACTION_NAME = "Spectate"
local SPECTATE_ACTION_INPUTS = {
    Enum.UserInputType.MouseButton1,
    Enum.UserInputType.MouseMovement
}


local player: Player = Players.LocalPlayer
local currentHover: GuiObject? = nil
local previousHover: GuiObject? = nil
local selected: GuiObject? = nil


local Spectate = {}
Spectate.canEnable = false


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


local function subscribe(shouldSubscribe: boolean, newName: string, oldName: string?): ()
    local board: Board?, pieces: ReservedPieces? = remotes.Spectate.Subscribe:InvokeServer(
        shouldSubscribe,
        newName,
        oldName
    )
    
    if not board then
        return
    end

    BoardInterface.loadBoard(board)
    Reserve.removePieceObjects()

    if pieces then
        for _, piece in pieces do
            local pieceData = piece.pieceData
    
            local pieceObject = Reserve.generatePiece(pieceData.shape, pieceData.type)
            pieceObject.object.Position = piece.position
        end
    end
end


local function selectNew(newSelection: GuiObject, oldSelection: GuiObject?): ()
    local newSelectRow = newSelection.Parent :: Instance

    local indicator = newSelection:WaitForChild("Indicator") :: GuiObject
    indicator.Visible = newSelectRow.Name ~= player.Name

    if oldSelection then
        local oldSelectionRow = oldSelection.Parent :: Instance

        local oldIndicator = oldSelection:WaitForChild("Indicator") :: GuiObject
        oldIndicator.Visible = false

        subscribe(true, newSelectRow.Name, oldSelectionRow.Name)
    else
        subscribe(true, newSelectRow.Name, nil)
    end

    selected = newSelection
end


local function unselect(currentSelection: GuiObject): ()
    local row = currentSelection.Parent :: Instance

    subscribe(false, row.Name, nil)

    local indicator = currentSelection:WaitForChild("Indicator") :: GuiObject
    indicator.Visible = false

    selected = nil
end


local function action(_: string, state: Enum.UserInputState, input: InputObject): Enum.ContextActionResult
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if state == Enum.UserInputState.Begin then
            if not currentHover then
                return Enum.ContextActionResult.Pass
            end
            
            if selected ~= currentHover then
                selectNew(currentHover, selected)
            else
                unselect(selected :: GuiObject)
            end
        end

    elseif input.UserInputType == Enum.UserInputType.MouseMovement then
        if state == Enum.UserInputState.Change then
            update(input)
        end
    end

    return Enum.ContextActionResult.Pass
end


function Spectate.enable(): ()
    if not Spectate.canEnable then
        return
    end

    ContextActionService:BindAction(
        SPECTATE_ACTION_NAME,
        action,
        false,
        table.unpack(SPECTATE_ACTION_INPUTS)
    )
end


function Spectate.disable(): ()
    ContextActionService:UnbindAction(SPECTATE_ACTION_NAME)

    if currentHover then
        hover(currentHover, false)

        currentHover = nil
    end

    if selected then
        unselect(selected)
    end
end


function Spectate.start(): ()
    -- start receiving broadcast
end


function Spectate.stop(): ()
    -- stop receiving broadcast and clear current broadcast
end


return Spectate