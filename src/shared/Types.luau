export type LookUp<T> = { [T]: boolean }

export type Board = { [string]: PieceType }
export type PieceType = "red" | "orange" | "yellow" | "green" | "lblue" | "dblue" | "purple" | "brown" | "grey" | "blocker" | "none"
export type PieceShape = { number }
export type PieceData = { shape: PieceShape, metadata: { height: number, width: number }, type: PieceType }
export type PieceObjectInfo = { pieceData: PieceData, object: GuiObject }


return nil