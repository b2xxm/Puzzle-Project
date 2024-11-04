export type LookUp<T> = { [T]: boolean }
export type InputMethod = Enum.KeyCode | Enum.UserInputType
export type DeviceType = "Desktop" | "Mobile"


export type Board = { [string]: PieceType }

export type PieceType = "red" | "orange" | "yellow" | "green" | "lblue" | "dblue" | "purple" | "brown" | "grey" | "blocker" | "none"
export type PieceShape = { number }
export type PieceData = { shape: PieceShape, metadata: { height: number, width: number }, type: PieceType }
export type PieceObjectInfo = { pieceData: PieceData, object: GuiObject }
export type ReservedPieces = { { pieceData: PieceData, position: UDim2 } }

export type SimulationOptions = "Select" | "Unselect" | "Replace" | "Place" | "Unplace"


return nil