Hydrus = API('https://api.hydrus.gg/plugin/v1', {
    Authorization = 'Bearer '..ENV.token
})
Store = {}

function is_online(id)
    local source = Proxy.getSource(id)
    if source then
        return ternary(source > 65000, 'queue', true)
    end
    return false
end

CreateThread(function()
    local ws, connected, seq = nil, false, 0
    local pid = math.abs(GetHashKey(GetResourcePath(script_name)))

    logger('PID: %s', pid)

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
                Wait(60e3)
                seq = 0
            else
                Wait(5e3)
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

    while wait_before_intelisense do
        Wait(100)
    end
    ws = exports[script_name]:createWebSocket('wss://rtc.hydrus.gg', {
        ['authorization'] = ENV.token,
        ['x-scope'] = 'plugin',
        ['x-pid'] = pid,
    }, listener)

    while true do
        Wait(60e3)
        if connected then
            ws.ping()
        end
    end
end)

local extensions = {}

function create_extension(name, moduleFn)
    extensions[name] = moduleFn
end

function load_extension(name)
    local old = extensions[name]
    if type(old) == 'function' then
        extensions[name] = old() or {}
        return extensions[name]
    elseif old ~= nil then
        return old
    end
    error(_('extension.not_found', { name=name }))
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