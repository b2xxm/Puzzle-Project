local GuiService = game:GetService("GuiService")
local Workspace = game:GetService("Workspace")


local camera: Camera = Workspace.CurrentCamera


local Utils = {}


function Utils.toScalePosition(x: number, y: number): (number, number)
    local inset = (GuiService:GetGuiInset()).Y

    return x / camera.ViewportSize.X, (y + inset) / camera.ViewportSize.Y
end


function Utils.toOffsetPosition(x: number, y: number): (number, number)
    local inset = (GuiService:GetGuiInset()).Y

    return x * camera.ViewportSize.X, (y * camera.ViewportSize.Y) - inset
end


return Utils