local Utils = {}


function Utils.partial<R...>(callback: (...any) -> (R...), ...: any): (...any) -> (R...)
    local original = { ... }

    return function(...: any)
		local arguments = { table.unpack(original) }
		local newArguments = { ... }
		
		table.move(newArguments, 1, #newArguments, #arguments + 1, arguments)
		
        return callback(table.unpack(arguments))
    end
end


return Utils