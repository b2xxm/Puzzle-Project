local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")


local shared = ReplicatedStorage.Shared


local Types = require(shared.Types)


type InputMethod = Types.InputMethod
type RegisterDetails = { callback: (...any) -> Enum.ContextActionResult, priority: number, inputs: { InputMethod } }


local registered: { [string]: RegisterDetails } = {}


local Input = {}


function Input.register(name: string, callback: (...any) -> Enum.ContextActionResult, priority: number,  ...: InputMethod): ()

    if registered[name] then
        warn(`[{name}] is already used to register a different action`)

        return
    end

    registered[name] = {
        callback = callback,
        priority = priority,
        inputs = { ... }
    }
end


function Input.enable(name: string): ()
    local details = registered[name]

    if not details then
        warn(`[{name}] is not registered`)
    end

    ContextActionService:BindActionAtPriority(name, details.callback, false, details.priority, table.unpack(details.inputs))
end


function Input.disable(name: string): ()
    local details = registered[name]

    if not details then
        warn(`[{name}] is not registered`)
    end

    ContextActionService:UnbindAction(name)
end


return Input