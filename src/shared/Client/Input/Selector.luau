local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")


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
local CellColours = require(client.Interface.Board.CellColours)
local InterfaceUtils = require(client.Interface.Utils)


type PieceType = Types.PieceType
type PieceObjectInfo = Types.PieceObjectInfo
type PieceActionInputs = {
    flip: { horizontal: Enum.KeyCode, vertical: Enum.KeyCode },
    rotate: { counterclockwise: Enum.KeyCode, clockwise: Enum.KeyCode },
}


local PIECE_ACTION_NAME: string = "PieceAction"
local PIECE_ACTION_INPUTS: PieceActionInputs = {
    flip = {
        horizontal = Enum.KeyCode.R,
        vertical = Enum.KeyCode.T
    },
    rotate = {
        clockwise = Enum.KeyCode.E,
        counterclockwise = Enum.KeyCode.Q
    }
}


local player: Player = Players.LocalPlayer
local selected: PieceObjectInfo? = nil
local currentHoveringAddress: string? = nil
local currentHoveringAddresses: { string } = {}


local Selector = {}
Selector.actionName = "PieceSelection"
Selector.inputs = {
    Enum.UserInputType.MouseButton1,
    Enum.UserInputType.MouseMovement
}


local function pieceAction(_: string, state: Enum.UserInputState, input: InputObject): ()
    if state ~= Enum.UserInputState.Begin or not selected then
        return
    end

    if input.KeyCode == PIECE_ACTION_INPUTS.flip.horizontal then
        PieceService.flipHorizontal(selected.pieceData)

    elseif input.KeyCode == PIECE_ACTION_INPUTS.flip.vertical then
        PieceService.flipVertical(selected.pieceData)

    elseif input.KeyCode == PIECE_ACTION_INPUTS.rotate.clockwise then
        PieceService.rotate(selected.pieceData, true)

    elseif input.KeyCode == PIECE_ACTION_INPUTS.rotate.counterclockwise then
        PieceService.rotate(selected.pieceData, false)
    end

    currentHoveringAddress = nil
    
    local objectInfo = Reserve.generatePiece(selected.pieceData.shape, selected.pieceData.type)

    local x = selected.object.AbsolutePosition.X + selected.object.AbsoluteSize.X / 2
    local y = selected.object.AbsolutePosition.Y + selected.object.AbsoluteSize.Y / 2

    Reserve.removePieceObject(selected)

    selected = objectInfo

    Selector.update(selected, Vector3.new(x, y, 0))
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

            local padding = BoardInterfaceConfig.padding

            local shapeSizeX = (cellObject.AbsoluteSize.X + padding) * shapeWidth - padding
            local shapeSizeY = (cellObject.AbsoluteSize.Y + padding) * shapeHeight - padding

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

        if pieceType == "blocker" then
            cellObject.Transparency = 1
        else
            if pieceType == "none" then
                cellObject.BackgroundColor3 = CellColours.unoccupied
            else
                cellObject.BackgroundColor3 = CellColours.occupied[pieceType]
            end

            cellObject.Transparency = 0
        end
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


function Selector.update(objectInfo: PieceObjectInfo, position: Vector3): ()
    local x, y = InterfaceUtils.toScalePosition(position.X, position.Y)

    objectInfo.object.Position = UDim2.fromScale(x, y)

    local playerGui = player.PlayerGui
    local gameUi = playerGui:WaitForChild("GameUi")
    local boardFrame = gameUi:WaitForChild("Board") :: Frame
        
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

        cellObject.Transparency = CellColours.valid.transparency
        cellObject.BackgroundColor3 = CellColours.valid.colour

        if pieceType ~= "none" then
            available = false

            cellObject.Transparency = CellColours.invalid.transparency
            cellObject.BackgroundColor3 = CellColours.invalid.colour
        end
    end

    setPieceVisibility(objectInfo.object, not available)

    currentHoveringAddresses = hoveringAddresses
end


function Selector.action(_: string, state: Enum.UserInputState, input: InputObject): ()
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if state == Enum.UserInputState.Begin then
            local playerGui = player.PlayerGui
            
            local x, y = input.Position.X, input.Position.Y
            local guiObjects = playerGui:GetGuiObjectsAtPosition(x, y)

            local clickedAddress = nil

            for _, object in guiObjects do
                for _, reserveInfo in Reserve.reserved do
                    if object == reserveInfo.object then
                        selected = reserveInfo
                        
                        break
                    end
                end

                if selected then
                    break
                end
                
                if not clickedAddress and BoardInterface.cells[object.Name] then
                    clickedAddress = object.Name
                end
            end

            if not selected then
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
                selected = Reserve.generatePiece(pieceData.shape, pieceType)

                BoardInterface.removePiece(occupyingAddresses)
            end

            Selector.update(selected :: PieceObjectInfo, input.Position)

            ContextActionService:BindAction(
                PIECE_ACTION_NAME,
                pieceAction,
                false,
                PIECE_ACTION_INPUTS.flip.horizontal,
                PIECE_ACTION_INPUTS.flip.vertical,
                PIECE_ACTION_INPUTS.rotate.clockwise,
                PIECE_ACTION_INPUTS.rotate.counterclockwise
            )

        elseif state == Enum.UserInputState.End then
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
                    end
                end

                currentHoveringAddress = nil
            end

            clearHighlights()
            setPieceVisibility(selected.object, false)
            
            selected = nil
            ContextActionService:UnbindAction(PIECE_ACTION_NAME)
        end
    else
        if state ~= Enum.UserInputState.Change or not selected then
            return
        end
        
        Selector.update(selected, input.Position)
    end
end


return Selector
