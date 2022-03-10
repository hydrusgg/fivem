Hydrus = API('https://api.hydrus.gg/plugin/v1', {
    Authorization = 'Bearer '..ENV.token
})
Store = {}

local safety_lock = {}
safety_lock.running = false

local function handle_command(id, raw)
    if safety_lock[id] then
        return printf('safety_lock catch %d', id)
    end

    repeat Wait(0)
    until not safety_lock.running
    safety_lock.running = true

    safety_lock[id] = true

    local ok, retval = pcall(function()
        local args = raw:split(' ')
        assert(#args > 0, {'Empty command'})

        -- Automatically parse every argument to number if possible
        for index, raw in ipairs(args) do
            args[index] = tonumber(raw) or raw
        end

        local fname = table.remove(args, 1)
        local func = Commands[fname]
        assert(type(func) == 'function', {'Commands["'..fname..'"] is not a function'})

        return func(table.unpack(args))
    end)

    if not ok and type(retval) == 'table' then
        retval = retval[1]
    end

    while true do
        local status = Hydrus('PATCH', 'commands/'..id, {
            status = ok and 'done' or 'failed',
            message = retval or 'OK'
        })
        if status ~= 200 then
            printf('Failed to UPDATE the command %d, the script will try again in 10 seconds', id)
            Wait(10e3)
        else
            break 
        end
    end
    
    safety_lock[id] = nil
    safety_lock.running = false
end

CreateThread(function()
    local ws, connected, seq = nil, false, 0

    function listener(event, payload)
        debug('Received event %s with %s', event, json.encode(payload))
        if event == 'HANDSHAKE' then
            if payload.error then
                print(_('connection.error', payload))
            else
                print(_('connection.ok'))
                Store.domain = payload.domain
                connected = true
                seq = 0
            end
        elseif event == '$error' then
            seq = seq + 1
            if seq >= 5 then
                print(_('connection.outage'))
                Wait(60000)
                seq = 0
            else
                Wait(5000)
            end
            ws.reconnect()
        elseif event == '$close' and connected then
            connected = false
            ws.reconnect()
        elseif event == 'EXECUTE_COMMAND' then
            handle_command(payload.id, payload.command)
        elseif event == 'EXECUTE_COMMANDS' then
            for i, item in ipairs(payload) do
                handle_command(item.id, item.command)
            end
        end
    end

    Wait(3000) -- Avoid conflicts with already connected
    while wait_before_intelisense do
        Wait(100)
    end
    ws = exports[script_name]:createWebSocket('wss://rtc.hydrus.gg/'..ENV.token..'/plugin', listener)

    while true do
        Wait(60e3)
        if connected then
            ws.ping()
        end
    end
end)

function load_extension(name)
    local file = LoadResourceFile(script_name, 'server/plugins/ext/'..name)

    if not file then
        print(_('extension.not_found', { name=name }))
        return false
    end

    local func, err = load(file)

    if not func then
        print(_('extension.error', { name=name, error=err }))
        return false
    end

    local ok, err = pcall(load(file))
    if not ok then
        print(_('extension.error', { name=name, error=err }))
    end
    return ok, err
end