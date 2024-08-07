--!strict

local dices: { { string } } = {
    { "B4", "C3", "C4", "D3", "D4", "E3" },
    { "A4", "B5", "C5", "C6", "D6", "F6" },
    { "A5", "A5", "B6", "E1", "F2", "F2" },
    { "D5", "E4", "E5", "E6", "F4", "F5" },
    { "A1", "C1", "D1", "D2", "E2", "F3" },
    { "A2", "A3", "B1", "B2", "B3", "C2" },
    { "A6", "A6", "A6", "F1", "F1", "F1" }
}


local Dices = {}


function Dices.roll(): { string }
    local addresses: { string } = table.create(#dices)

    for index, faces in dices do
        local faceIndex = math.random(1, #faces)
        local face = faces[faceIndex]

        addresses[index] = face
    end

    return addresses
end


return Dices
