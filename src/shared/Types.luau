export type Board = { [string]: PieceType }
export type PieceType = "red" | "orange" | "yellow" | "green" | "lblue" | "dblue" | "purple" | "brown" | "grey" | "blocker" | "none"
export type PieceData = { data: { number }, metadata: { rows: number, columns: number } }


return nil