--!strict

local BoardConfig = require(script.Parent.Config)


local ASCII_OFFSET: number = 64


local Utils = {}


local function validateCoordinates(x: number?, y: number?): boolean
    if typeof(x) ~= "number" or typeof(y) ~= "number" then
        return false
    end

    if x < 1 or x > BoardConfig.columns then
        return false
    end

    if y < 1 or y > BoardConfig.rows then
        return false
    end

    return true
end


function Utils.toAddress(x: number, y: number): string?
    if not validateCoordinates(x, y) then
        return
    end

    local row = Utils.getRow(y)
    local column = tostring(x)

    return row .. column
end


function Utils.toCoordinates(address: string): (number?, number?)
    local row, column = Utils.seperateAddress(address)

    local x = tonumber(column)
    local y = string.byte(row) - ASCII_OFFSET

    if not validateCoordinates(x, y) then
        return
    end

    return x, y
end


function Utils.seperateAddress(address: string): (string, string)
    local row = address:gsub("%A", "")
    local column = address:gsub("%D", "")

    return row, column
end


function Utils.getRow(y: number): string
    return string.char(y + ASCII_OFFSET)
end


return Utils
