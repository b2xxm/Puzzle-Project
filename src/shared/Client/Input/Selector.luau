local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local Workspace = game:GetService("Workspace")
local GuiService = game:GetService("GuiService")


local shared = ReplicatedStorage.Shared
local client = shared.Client


local Types = require(shared.Types)
local PieceService = require(shared.PieceService)
local BoardUtils = require(shared.BoardService.Utils)
local BoardConfig = require(shared.BoardService.Config)
local Reserve = require(client.Interface.Reserve)
local BoardInterface = require(client.Interface.Board)
local BoardInterfaceConfig = require(client.Interface.Board.Config)
local CellColours = require(client.Interface.Board.CellColours)


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
		vertical = Enum.KeyCode.T,
	},
	rotate = {
		clockwise = Enum.KeyCode.E,
		counterclockwise = Enum.KeyCode.Q,
	},
}


local player: Player = Players.LocalPlayer
local camera: Camera = Workspace.CurrentCamera
local selected: PieceObjectInfo? = nil
local currentHoveringAddress: string? = nil
local currentHoveringAddresses: { string } = {}


local Selector = {}
Selector.actionName = "PieceSelection"
Selector.inputs = {
	Enum.UserInputType.MouseButton1,
	Enum.UserInputType.MouseMovement,
}


local function getPosition(input: InputObject): UDim2
	local inset = (GuiService:GetGuiInset()).Y

	return UDim2.fromScale(input.Position.X / camera.ViewportSize.X, (input.Position.Y + inset) / camera.ViewportSize.Y)
end


local function pieceAction(_: string, state: Enum.UserInputState, input: InputObject): ()
	if state ~= Enum.UserInputState.Begin or not selected then
		return
	end

	local position = selected.object.Position

	selected.object:Destroy()

	if input.KeyCode == PIECE_ACTION_INPUTS.flip.horizontal then
		PieceService.flipHorizontal(selected.pieceData)

	elseif input.KeyCode == PIECE_ACTION_INPUTS.flip.vertical then
		PieceService.flipVertical(selected.pieceData)

	elseif input.KeyCode == PIECE_ACTION_INPUTS.rotate.clockwise then
		PieceService.rotate(selected.pieceData, true)

	elseif input.KeyCode == PIECE_ACTION_INPUTS.rotate.counterclockwise then
		PieceService.rotate(selected.pieceData, false)
	end

	selected.object = Reserve.generatePiece(selected.pieceData.shape, selected.pieceData.type)

	Selector.update(selected, input)

	selected.object.Position = position
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

			local shapeSizeX = ((cellObject.AbsoluteSize.X + padding) * shapeWidth) - padding
			local shapeSizeY = ((cellObject.AbsoluteSize.Y + padding) * shapeHeight) - padding

			local shapeCentreX = cellObject.AbsolutePosition.X + (shapeSizeX / 2)
			local shapeCentreY = cellObject.AbsolutePosition.Y + (shapeSizeY / 2)

			local distance = math.sqrt((shapeCentreX - mousePos.X) ^ 2 + (shapeCentreY - mousePos.Y) ^ 2)

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

			local address = BoardUtils.toAddress(x + (shapeWidth - bitPosition) - 1, y + rowIndex - 1) :: string

			table.insert(hoveringAddresses, address)
		end
	end

	return hoveringAddresses
end


function highlightColour(colour: Color3): Color3
	local r, g, b = colour.R, colour.G, colour.B

	local white = 1
	local alpha = 0.2

	local newR = r + (white - r) * alpha
	local newG = g + (white - g) * alpha
	local newB = b + (white - b) * alpha

	return Color3.new(newR, newG, newB)
end


function clearHighlights(): ()
	for _, address in currentHoveringAddresses do
		local pieceType: PieceType = BoardInterface.board[address]
		local cellObject = BoardInterface.cells[address]

		if pieceType == "blocker" then
			cellObject.Transparency = 1

		elseif pieceType == "none" then
			cellObject.BackgroundColor3 = CellColours.unoccupied
		else
			cellObject.BackgroundColor3 = CellColours.occupied[pieceType]
		end
	end
end


function Selector.update(objectInfo: PieceObjectInfo, input: InputObject): ()
	objectInfo.object.Position = getPosition(input)

	local hoveringAddresses = getHoveringAddresses(input.Position, objectInfo)

	if hoveringAddresses then
		clearHighlights()

		for _, address in hoveringAddresses do
			local pieceType: PieceType = BoardInterface.board[address]
			local cellObject = BoardInterface.cells[address]

			local colour = highlightColour(cellObject.BackgroundColor3)

			cellObject.BackgroundColor3 = colour

			if pieceType == "blocker" then
				cellObject.Transparency = 0.9
				cellObject.BackgroundColor3 = Color3.new(1, 0.2, 0.2)
			end
		end

		currentHoveringAddresses = hoveringAddresses
	end
end

function Selector.action(_: string, state: Enum.UserInputState, input: InputObject): ()
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if state == Enum.UserInputState.Begin then
			local playerGui = player.PlayerGui

			local x, y = input.Position.X, input.Position.Y
			local guiObjects = playerGui:GetGuiObjectsAtPosition(x, y)

			for _, object in guiObjects do
				for _, reserveInfo in Reserve.reserved do
					if object ~= reserveInfo.object then
						continue
					end

					selected = reserveInfo

					break
				end

				if selected then
					break
				end
			end

			if not selected then
				return
			end

			Selector.update(selected, input)

			ContextActionService:BindAction(
				PIECE_ACTION_NAME,
				pieceAction,
				false,
				PIECE_ACTION_INPUTS.flip.horizontal,
				PIECE_ACTION_INPUTS.flip.vertical,
				PIECE_ACTION_INPUTS.rotate.clockwise,
				PIECE_ACTION_INPUTS.rotate.counterclockwise
			)
		else
			if not selected then
				return
			end

			selected = nil
			currentHoveringAddress = nil

			clearHighlights()

			ContextActionService:UnbindAction(PIECE_ACTION_NAME)
		end
	else
		if state ~= Enum.UserInputState.Change or not selected then
			return
		end

		Selector.update(selected, input)
	end
end


return Selector
