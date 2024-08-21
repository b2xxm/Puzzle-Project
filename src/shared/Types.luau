export type Board = { [string]: PieceType }
export type PieceType = "red" | "orange" | "yellow" | "green" | "lblue" | "dblue" | "purple" | "brown" | "grey" | "blocker" | "none"
export type PieceShape = { number }
export type PieceData = { data: PieceShape, metadata: { height: number, width: number } }
export type PieceObjectInfo = { type: PieceType, shape: PieceShape, object: Frame }


return nil