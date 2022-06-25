Hydrus = API('https://api.hydrus.gg/plugin/v1', {
    Authorization = 'Bearer '..ENV.token
})
Store = {}

CreateThread(function()
    local ws, connected, seq = nil, false, 0

    local function push(job)
        if Queue:exists('id', job.id) then
            printf('Command %d already in queue', job.id)
        else
            Queue:push(job)
        end
    end

    function listener(event, payload)
        logger('Received event %s with %s', event, json.encode(payload))
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
            push(payload)
        elseif event == 'EXECUTE_COMMANDS' then
            for i, item in ipairs(payload) do
                push(item)
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

function main.get_url()
    while not Store.domain do Wait(250) end
    return Store.domain
end

exports('createCommand', function(command, ttl, scope)
    if type(command) == 'table' then
        command = table.concat(command, ' ')
    end
    return Hydrus('POST', '/commands', {
        command = command,
        scope = scope or 'plugin',
        ttl = ttl or 0,
    })
end)