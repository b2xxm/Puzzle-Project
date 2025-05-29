local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")


local shared = ReplicatedStorage.Shared
local client = shared.Client


local Types = require(shared.Types)
local TweenUtils = require(shared.TweenUtils)
local Configuration = require(shared.Configuration)
local Remotes = require(shared.Remotes)
local BoardInterface = require(client.Interface.Board)
local Reserve = require(client.Interface.Reserve)
local Input = require(client.Input)


type Board = Types.Board
type PieceObjectInfo = Types.PieceObjectInfo
type ReservedPieces = Types.ReservedPieces
type SimulationOptions = Types.SimulationOptions
type PieceType = Types.PieceType
type PieceData = Types.PieceData


local player: Player = Players.LocalPlayer
local currentHover: GuiObject? = nil
local previousHover: GuiObject? = nil
local spectating: GuiObject? = nil
local playerList: GuiObject = nil
local cursor: GuiObject = nil
local selectedPiece: PieceObjectInfo? = nil
local optionToFunctionMap: { [SimulationOptions]: (...any) -> () } = nil


local Spectate = {}
Spectate.enabled = false


local function init(): ()
    local playerGui = player.PlayerGui
    local gameUi = playerGui:WaitForChild("GameUi")

    cursor = gameUi:WaitForChild("Cursor") :: GuiObject
    playerList = gameUi:WaitForChild("Players") :: Frame

    optionToFunctionMap = {
        Select = Spectate.selectPiece,
        Unselect = Spectate.unselectPiece,
        Replace = Spectate.replacePiece,
        Place = Spectate.placePiece,
        Unplace = Spectate.unplacePiece
    }
end


local function hover(object: GuiObject, enabled: boolean): ()
    TweenUtils.cancel(object)

    local goal = Configuration.playerList.hover.goals[enabled]
    local tween = TweenUtils.create(object, Configuration.playerList.hover.tweenInfo, goal)

    tween:Play()
end


local function update(input: InputObject): ()
    local playerGui = player.PlayerGui
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


local function loadBoard(board: Board, pieces: ReservedPieces?): ()
    BoardInterface.loadBoard(board)
    Reserve.removePieceObjects()

    if pieces then
        cursor.Visible = true

        for _, piece in pieces do
            local pieceData = piece.pieceData
    
            local pieceObject = Reserve.generatePiece(pieceData.shape, pieceData.type)
            pieceObject.object.Position = piece.position
        end
    else
        cursor.Visible = false
    end
end


local function subscribe(serviceName: string): ()
    local board: Board?, pieces: ReservedPieces? = Remotes.Spectate.Subscribe.invoke(serviceName)

    if not board then
        return
    end

    loadBoard(board, pieces)
end


local function unsubscribe(serviceName: string, isSubscribing: boolean): ()
    local board: Board?, pieces: ReservedPieces? = Remotes.Spectate.Unsubscribe.invoke(serviceName)

    if not board then
        return
    end

    if isSubscribing then
        return
    end

    loadBoard(board, pieces)
end


local function selectNew(newSelection: GuiObject, oldSelection: GuiObject?): ()
    local newSelectRow = newSelection.Parent :: Instance

    local indicator = newSelection:WaitForChild("Indicator") :: GuiObject
    indicator.Visible = newSelectRow.Name ~= player.Name

    if oldSelection then
        local oldSelectionRow = oldSelection.Parent :: Instance

        local oldIndicator = oldSelection:WaitForChild("Indicator") :: GuiObject
        oldIndicator.Visible = false

        unsubscribe(oldSelectionRow.Name, true)
        subscribe(newSelectRow.Name)
    else
        subscribe(newSelectRow.Name)
    end

    spectating = newSelection
end


local function unselect(currentSelection: GuiObject): ()
    local row = currentSelection.Parent :: Instance

    unsubscribe(row.Name, false)

    local indicator = currentSelection:WaitForChild("Indicator") :: GuiObject
    indicator.Visible = false

    spectating = nil
end


local function action(_: string, state: Enum.UserInputState, input: InputObject): Enum.ContextActionResult
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if state == Enum.UserInputState.Begin then
            if not currentHover then
                return Enum.ContextActionResult.Pass
            end
            
            if spectating ~= currentHover then
                selectNew(currentHover, spectating)
            else
                unselect(spectating :: GuiObject)
            end
        end

    elseif input.UserInputType == Enum.UserInputType.MouseMovement then
        if state == Enum.UserInputState.Change then
            update(input)
        end
    end

    return Enum.ContextActionResult.Pass
end


function Spectate.serviceLeft(service: Player): ()
    if not spectating then
        return
    end

    local row = spectating.Parent

    if row and row.Name == service.Name then
        unsubscribe(service.Name, false)

        spectating = nil
    end
end


function Spectate.enable(): ()
    Spectate.enabled = true

    Input.enable("Spectate")
end


function Spectate.disable(): ()
    Spectate.enabled = false

    Input.disable("Spectate")

    if currentHover then
        hover(currentHover, false)

        currentHover = nil
    end

    if spectating then
        unselect(spectating)
    end
end


function Spectate.moveMouse(mouseX: number, mouseY: number): ()
    cursor.Position = UDim2.fromScale(mouseX, mouseY)

    if selectedPiece then
        selectedPiece.object.Position = cursor.Position
    end
end


function Spectate.simulate(option: SimulationOptions, ...: any): ()
    local mappedFunction = optionToFunctionMap[option]

    if mappedFunction then
        mappedFunction(...)
    end
end


function Spectate.selectPiece(pieceType: PieceType): ()
    local piece = (Reserve.findPieceByType(pieceType))

    if piece then
        selectedPiece = piece
        piece.object.Position = cursor.Position
    end
end


function Spectate.unselectPiece(): ()
    selectedPiece = nil
end


function Spectate.replacePiece(pieceData: PieceData): ()
    local objectInfo = (Reserve.findPieceByType(pieceData.type))

    if objectInfo then
        Reserve.removePieceObject(objectInfo)
    end

    local piece = Reserve.generatePiece(pieceData.shape, pieceData.type)
    piece.object.Position = cursor.Position

    selectedPiece = piece
end


function Spectate.placePiece(addresses: { string }, pieceType: PieceType): ()
    local success = BoardInterface.placePiece(addresses, pieceType)

    selectedPiece = nil

    if not success then
        return
    end

    local objectInfo = Reserve.findPieceByType(pieceType)

    if objectInfo then
        Reserve.removePieceObject(objectInfo)

        if #Reserve.reserved == 0 then
            cursor.Visible = false
        end
    end
end


function Spectate.unplacePiece(addresses: { string }, pieceData: PieceData ): ()
    BoardInterface.removePiece(addresses)
    
    local piece = Reserve.generatePiece(pieceData.shape, pieceData.type)
    piece.object.Position = cursor.Position

    selectedPiece = piece
end


init()


Input.register(
    "Spectate",
    action,
    Enum.ContextActionPriority.Medium.Value,
    false,
    Enum.UserInputType.MouseButton1,
    Enum.UserInputType.MouseMovement
)


return Spectate