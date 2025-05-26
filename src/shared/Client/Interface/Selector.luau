local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


local shared = ReplicatedStorage.Shared
local remotes = ReplicatedStorage.Remotes
local client = shared.Client


local Types = require(shared.Types)
local PieceService = require(shared.PieceService)
local BoardUtils = require(shared.BoardService.Utils)
local BoardConfig = require(shared.BoardService.Config)
local Reserve = require(client.Interface.Reserve)
local BoardInterface = require(client.Interface.Board)
local BoardInterfaceConfig = require(client.Interface.Board.Config)
local InterfaceUtils = require(client.Interface.Utils)
local Spectate = require(client.Interface.Spectate)
local Input = require(client.Input)
local Keybinding = require(client.Keybinding)


type Board = Types.Board
type PieceType = Types.PieceType
type PieceObjectInfo = Types.PieceObjectInfo
type ReservedPieces = Types.ReservedPieces
type DeviceType = Types.DeviceType


local player: Player = Players.LocalPlayer
local selected: PieceObjectInfo? = nil
local currentHoveringAddress: string? = nil
local currentHoveringAddresses: { string } = {}
local shouldBroadcast: boolean = false
local boardFrame: GuiObject = nil
local deviceType: DeviceType = "Desktop"


local Selector = {}


local function init(): ()
    local playerGui = player.PlayerGui
    local gameUi = playerGui:WaitForChild("GameUi")

    boardFrame = gameUi:WaitForChild("Board") :: GuiObject
end


local function getHoveringAddresses(mousePos: Vector3, objectInfo: PieceObjectInfo): { string }?
    local hoveringAddresses = {}
    local hoveringAddress = nil
    local closestDistance = math.huge

    local shapeHeight = objectInfo.pieceData.metadata.height
    local shapeWidth = objectInfo.pieceData.metadata.width

    for y = 1, BoardConfig.rows - shapeHeight + 1 do
        for x = 1, BoardConfig.columns - shapeWidth + 1 do
            local address = BoardUtils.toAddress(x, y) :: string
            local cellObject = BoardInterface.cells[address]

            local shapeSizeX = (cellObject.AbsoluteSize.X) * shapeWidth
            local shapeSizeY = (cellObject.AbsoluteSize.Y) * shapeHeight

            local shapeCentreX = cellObject.AbsolutePosition.X + shapeSizeX / 2
            local shapeCentreY = cellObject.AbsolutePosition.Y + shapeSizeY / 2

            local deltaX, deltaY = shapeCentreX - mousePos.X, shapeCentreY - mousePos.Y
            local distance = math.sqrt(deltaX ^ 2 + deltaY ^ 2)

            if distance < closestDistance then
                closestDistance = distance
                hoveringAddress = address
            end
        end
    end

    if currentHoveringAddress == hoveringAddress then
        return
    end

    currentHoveringAddress = hoveringAddress

    local x, y = BoardUtils.toCoordinates(hoveringAddress)
    
    if not x or not y then
        return
    end
    
    for rowIndex, shapeRow in objectInfo.pieceData.shape do
        for bitPosition = 0, shapeWidth - 1 do
            local bit = bit32.extract(shapeRow, bitPosition, 1)

            if bit == 0 then
                continue
            end

            local address = BoardUtils.toAddress(
                x + (shapeWidth - bitPosition) - 1,
                y + rowIndex - 1
            ) :: string

            table.insert(hoveringAddresses, address)
        end
    end

    return hoveringAddresses
end


local function clearHighlights(): ()
    for _, address in currentHoveringAddresses do
        local pieceType: PieceType = BoardInterface.board[address]
        local cellObject = BoardInterface.cells[address]

        if pieceType == "none" or pieceType == "blocker" then
            cellObject.BackgroundColor3 = BoardInterfaceConfig.colours.unoccupied
        else
            cellObject.BackgroundColor3 = BoardInterfaceConfig.colours.occupied[pieceType]
        end

        cellObject.Transparency = 0
    end
end


local function setPieceVisibility(pieceObject: GuiObject, translucent: boolean): ()
    for _, rowContainer in pieceObject:GetChildren() do
        if not rowContainer:IsA("Frame") then
            continue
        end

        for _, cell in rowContainer:GetChildren() do
            if not cell:IsA("Frame") or cell.Transparency == 1 then
                continue
            end

            cell.Transparency = if translucent then 0.8 else 0
        end
    end
end


local function begin(inputPosition: Vector3): ()
    local playerGui = player.PlayerGui
            
    local x, y = inputPosition.X, inputPosition.Y
    local guiObjects = playerGui:GetGuiObjectsAtPosition(x, y)

    local clickedAddress = nil
    local newSelected = nil

    for _, object in guiObjects do
        for _, reserveInfo in Reserve.reserved do
            if object == reserveInfo.object then
                newSelected = reserveInfo
                
                break
            end
        end

        if newSelected then
            break
        end
        
        if not clickedAddress and BoardInterface.cells[object.Name] then
            clickedAddress = object.Name
        end
    end

    if not newSelected then
        if not clickedAddress then
            return
        end

        local pieceType: PieceType = BoardInterface.board[clickedAddress]

        if pieceType == "blocker" or pieceType == "none" then
            return
        end

        local occupyingAddresses = {}

        for address, otherPieceType in BoardInterface.board do
            if otherPieceType ~= pieceType then
                continue
            end

            table.insert(occupyingAddresses, address)
        end
        
        local pieceData = PieceService.getPieceDataByAddress(occupyingAddresses, pieceType)
        newSelected = Reserve.generatePiece(pieceData.shape, pieceType)

        BoardInterface.removePiece(occupyingAddresses)

        if shouldBroadcast then
            remotes.Spectate.Simulate:FireServer("Unplace", occupyingAddresses, pieceData)
        end
    end

    selected = newSelected

    Selector.update(newSelected, inputPosition)

    if shouldBroadcast then
        remotes.Spectate.Simulate:FireServer("Select", newSelected.pieceData.type)
    end
end


local function release(): ()
    if not selected then
        return
    end

    if currentHoveringAddress then
        local success = BoardInterface.placePiece(
            currentHoveringAddresses,
            selected.pieceData.type
        )
        
        if success then
            Reserve.removePieceObject(selected)

            if #Reserve.reserved == 0 then
                remotes.SubmitSolution:FireServer(BoardInterface.board)

                Selector.disable()
            end

            if shouldBroadcast then
                remotes.Spectate.Simulate:FireServer("Place", currentHoveringAddresses, selected.pieceData.type)
            end
        end

        currentHoveringAddress = nil
    end

    clearHighlights()
    setPieceVisibility(selected.object, false)
    
    selected = nil

    if shouldBroadcast then
        remotes.Spectate.Simulate:FireServer("Unselect")
    end
end


function Selector.action(state: Enum.UserInputState, inputType: Enum.UserInputType, position: Vector3): Enum.ContextActionResult
    if state == Enum.UserInputState.Cancel then
        return Enum.ContextActionResult.Pass
    end
    
    if selected and selected.object.Parent == nil then
        selected = nil
    end

    if inputType == Enum.UserInputType.MouseButton1 then
        if state == Enum.UserInputState.Begin then
            begin(position)

        elseif state == Enum.UserInputState.End then
            release()
        end
    else
        if shouldBroadcast then
            local scaleX, scaleY = InterfaceUtils.toScalePosition(position.X, position.Y)
            remotes.Spectate.Broadcast:FireServer(scaleX, scaleY)
        end

        if state ~= Enum.UserInputState.Change or not selected then
            return Enum.ContextActionResult.Pass
        end
        
        Selector.update(selected, position)
    end

    return Enum.ContextActionResult.Pass
end


function Selector.update(objectInfo: PieceObjectInfo, position: Vector3): ()
    local x, y = InterfaceUtils.toScalePosition(position.X, position.Y)
    local scalePosition = UDim2.fromScale(x, y)

    objectInfo.object.Position = scalePosition

    local playerGui = player.PlayerGui
    local guiObjects = playerGui:GetGuiObjectsAtPosition(position.X, position.Y)

    if not table.find(guiObjects, boardFrame) then
        clearHighlights()
        setPieceVisibility(objectInfo.object, false)

        currentHoveringAddress = nil

        return
    end
    
    local hoveringAddresses = getHoveringAddresses(position, objectInfo)

    if not hoveringAddresses then
        return
    end

    clearHighlights()

    local available = true

    for _, address in hoveringAddresses do
        local pieceType: PieceType = BoardInterface.board[address]
        local cellObject = BoardInterface.cells[address]

        cellObject.Transparency = BoardInterfaceConfig.colours.valid.transparency
        cellObject.BackgroundColor3 = BoardInterfaceConfig.colours.valid.colour

        if pieceType ~= "none" then
            available = false

            cellObject.Transparency = BoardInterfaceConfig.colours.invalid.transparency
            cellObject.BackgroundColor3 = BoardInterfaceConfig.colours.invalid.colour
        end
    end

    setPieceVisibility(objectInfo.object, not available)

    currentHoveringAddresses = hoveringAddresses
end


function Selector.enable(): ()
    if deviceType == "Desktop" then
        Input.enable("PieceSelector")
        
        -- make enable mobile selector
    end

    Spectate.disable()
end


function Selector.disable(): ()
    if deviceType == "Desktop" then
        Input.enable("PieceSelector")
        
        -- make disable mobile selector
    end

    Spectate.enable()
end


function Selector.setBroadcastStatus(enabled: boolean): (Board?, ReservedPieces?)
    shouldBroadcast = enabled

    if shouldBroadcast then
        local pieces = {}

        for _, pieceObjectInfo in Reserve.reserved do
            local pieceInfo = {}
            pieceInfo.pieceData = pieceObjectInfo.pieceData
            pieceInfo.position = pieceObjectInfo.object.Position

            table.insert(pieces, pieceInfo)
        end

        return BoardInterface.board, pieces
    end

    return
end


function Selector.pieceAction(state: Enum.UserInputState, keycode: Enum.KeyCode): ()
    if state ~= Enum.UserInputState.Begin or not selected then
        return
    end

    if keycode == Keybinding.PieceAction.FlipHorizontal then
        PieceService.flipHorizontal(selected.pieceData)

    elseif keycode == Keybinding.PieceAction.FlipVertical then
        PieceService.flipVertical(selected.pieceData)

    elseif keycode == Keybinding.PieceAction.RotateClockwise then
        PieceService.rotate(selected.pieceData, true)

    elseif keycode == Keybinding.PieceAction.RotateCounterClockwise then
        PieceService.rotate(selected.pieceData, false)
    end

    currentHoveringAddress = nil
    
    local objectInfo = Reserve.generatePiece(selected.pieceData.shape, selected.pieceData.type)

    local x = selected.object.AbsolutePosition.X + selected.object.AbsoluteSize.X / 2
    local y = selected.object.AbsolutePosition.Y + selected.object.AbsoluteSize.Y / 2

    Reserve.removePieceObject(selected)

    selected = objectInfo

    Selector.update(selected, Vector3.new(x, y, 0))

    if shouldBroadcast then
        remotes.Spectate.Simulate:FireServer("Replace", objectInfo.pieceData)
    end
end


function Selector.setDeviceType(newType: DeviceType): ()
    deviceType = newType
end


function Selector.getSelected(): PieceObjectInfo?
    return selected
end


init()


return Selector
