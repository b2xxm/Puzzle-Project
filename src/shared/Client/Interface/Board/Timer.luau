local RunService = game:GetService("RunService")
local Players = game:GetService("Players")


local UPDATE_NAME: string = "TimerUpdate"
local RENDER_PRIORITY: number = 2000


local player: Player = Players.LocalPlayer


local Timer = {}


function Timer.start(startTime: number, duration: number): ()
    local playerGui = player.PlayerGui
    
    local gameUi = playerGui:WaitForChild("GameUi")
    local boardFrame = gameUi:WaitForChild("Board")
    local timer = boardFrame:WaitForChild("Timer")
    local bar = timer:WaitForChild("Bar") :: GuiObject

    local elapsed = time() - startTime
    
    RunService:UnbindFromRenderStep(UPDATE_NAME)
    RunService:BindToRenderStep(UPDATE_NAME, RENDER_PRIORITY, function(delta: number)
        if elapsed >= duration then
            bar.Size = UDim2.fromScale(1, 0)

            RunService:UnbindFromRenderStep(UPDATE_NAME)
        end
        
        local alpha = 1 - (elapsed / duration)

        bar.Size = UDim2.fromScale(1, alpha)

        elapsed += delta
    end)
end


return Timer