local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")


local shared = ReplicatedStorage.Shared


local Types = require(shared.Types)


type InputMethod = Types.InputMethod
type ActionCallback = (name: string, state: Enum.UserInputState, input: InputObject) -> Enum.ContextActionResult
type RegisterDetails = { callback: ActionCallback, priority: number, inputs: { InputMethod } }


local registered: { [string]: RegisterDetails } = {}


local Input = {}


function Input.register(name: string, callback: ActionCallback, priority: number, preEnabled: boolean, ...: InputMethod): ()
    if registered[name] then
        warn(`[{name}] is already used to register a different action`)

        return
    end

    registered[name] = {
        callback = callback,
        priority = priority,
        inputs = { ... }
    }

    if preEnabled then
        Input.enable(name)
    end
end


function Input.unregister(name: string): ()
    if not registered[name] then
        warn(`[{name}] does in exist in registry`)

        return
    end

    Input.disable(name)
    
    registered[name] = nil
end


function Input.enable(name: string): ()
    local details = registered[name]

    if not details then
        warn(`[{name}] is not registered`)

        return
    end

    ContextActionService:BindActionAtPriority(name, details.callback, false, details.priority, table.unpack(details.inputs))
end


function Input.disable(name: string): ()
    local details = registered[name]

    if not details then
        warn(`[{name}] is not registered`)

        return
    end

    ContextActionService:UnbindAction(name)
end


return Input