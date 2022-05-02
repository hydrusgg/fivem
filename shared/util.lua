function parse_int(str)
    return math.floor(tonumber(str))
end

parseInt = parse_int

function string:split(sep)
    local fields = {}
    local pattern = string.format("([^%s]+)", sep)
    self:gsub(pattern, function(c) table.insert(fields, c) end)
    return fields
end

function string:trim()
    return self:match'^%s*(.*%S)' or ''
end

function string.equals(a, b)
    return tostring(a) == tostring(b)
end

function assert(test, err)
    if test then
        return test
    end
    error(err)
end

function throw_if(test, err)
    if test then
        error(err)
    end
end

function table.join(...)
    local res = {}

    for _,array in ipairs({...}) do
        for _,v in ipairs(array) do
            table.insert(res, v)
        end
    end

    return res
end

function table:map(cb)
    local res = {}

    for k, v in pairs(self) do
        res[k] = cb(v, k)
    end

    return res
end

function table:includes(o)
    for i, v in pairs(self) do
        if v == o then
            return true
        end
    end
    return false
end

function table:pluck(key)
    local r = {}
    for k,v in ipairs(self) do
        r[k] = v[key]
    end
    return r
end

function table:reverse()
    local r = {}
    for k,v in pairs(self) do
        r[v] = k
    end
    return r
end

function table:find_key(o)
    for k, v in pairs(self) do
        if v == o then
            return k
        end
    end
end

function table:empty()
    for k,v in pairs(self) do
        return false
    end
    return true
end

function each(t)
    local i = 0
    return function()
        i = i + 1
        return t[i]
    end
end

function callable(func)
    return setmetatable({ call = func }, { 
        __call = function(self, ...)
            return self.call(...)
        end
    })
end

function optional(o, ...)
    for i,key in ipairs({...}) do
        if type(o) == 'table' then
            o = o[key]
        else return nil end
    end
    return o
end

-- Copying JS behavior (it's way easier)
emit = TriggerEvent
emitNet = TriggerClientEvent or TriggerServerEvent
onNet = RegisterNetEvent

-- Tunnel (Just like vRP)

script_name = GetCurrentResourceName()
local is_server = IsDuplicityVersion()

function printf(s, ...)
    print(s:format(...))
end

sprint = string.format

function print_if(bool, ...)
    if bool then
        printf(...)
    end
end

function debug(...)
    print_if(ENV.debug, ...)
end

function ternary(test, a, b)
    if test then 
        return a
    else
        return b
    end
end

function next_id()
    local id = (LastID or 0) + 1
    LastID = id
    return id
end

main = {}
remote = setmetatable({ __callbacks={} }, {
    __index = function(o, name)
        o[name] = function(...)
            local id = next_id()
            local p = promise.new()
            o.__callbacks[id] = p

            -- id, name
            -- source, id, name
    
            local args = { ... }
            table.insert(args, is_server and 2 or 1, id)
            table.insert(args, is_server and 3 or 2, name)

            emitNet('hydrus:req', table.unpack(args))
            return table.unpack(Citizen.Await(p))
        end
        return o[name]
    end
})

onNet('hydrus:res', function(id, ok, ...)
    local p = remote.__callbacks[id]
    if p then
        if ok then
            p:resolve({...})
        else
            p:reject(...)
        end
        remote.__callbacks[id] = nil
    end
end)

onNet('hydrus:req', function(id, name, ...)
    if is_server then
        local source = source
        local ok, err = pcall(main[name], source, ...)
        -- if not ok then
        --     while err:sub(1,1) == '@' do
        --         err = err:sub(math.max(err:find(':%d+: '))+1)
        --     end
        -- end
        emitNet('hydrus:res', source, id, ok, err) 
    else
        emitNet('hydrus:res', id, pcall(main[name], ...))
    end
end)