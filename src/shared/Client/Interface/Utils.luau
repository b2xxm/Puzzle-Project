local GuiService = game:GetService("GuiService")
local Workspace = game:GetService("Workspace")


local camera: Camera = Workspace.CurrentCamera


local Utils = {}


function Utils.toScalePosition(x: number, y: number): UDim2
    local inset = (GuiService:GetGuiInset()).Y

    return UDim2.fromScale(
        x / camera.ViewportSize.X,
        (y + inset) / camera.ViewportSize.Y
    )
end


function Utils.toOffsetPosition(x: number, y: number): UDim2
    local inset = (GuiService:GetGuiInset()).Y

    return UDim2.fromOffset(
        x * camera.ViewportSize.X, 
        (y * camera.ViewportSize.Y) - inset
    )
end


return Utils