Commands = {}

--[[
    Everything declared in the Commands table
    Will be acessible to the commands runtime
    Meaning that you can register as a command
    in any product

    example:

    function Commands.print(text)
        print(text)
    end

    Could be used on the platform as

    print $user_id

    And this will print the user_id when the user pay for the product
]]

function Commands.exports(script, method, ...)
    local parent = exports[script]
    local res = parent[method](parent, ...)

    return type(res) == 'string' and res
end

Commands.emit = TriggerEvent
Commands.cmd = function(...)
    local raw = table.concat({ ... }, ' ')
    ExecuteCommand(raw)
end

RegisterCommand('hydrus', function(source, args)
    if source == 0 then
        local name = table.remove(args, 1)

        if not name then
            return print('Missing command name')
        end

        for i, v in ipairs(args) do
            args[i] = tonumber(v) or v
        end

        if not Commands[name] then
            return printf('The command %s does not exists', name)
        end

        Commands[name](table.unpack(args))
    end
end)