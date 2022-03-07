-------------------------------------------------------------------------------------------
--  The scheduler is used to deliver something that requires complex logic when the player
--  is offline, so we just wait until the player is online again, filtering by the identifier
--  and deleting by a random generated uuid
-------------------------------------------------------------------------------------------

local memcache = json.decode(LoadResourceFile(script_name, 'database/scheduler.json') or '{}')

local function uuid()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

Scheduler = {}

function Scheduler.new(identifier, command, ...)
    table.insert(memcache, {
        id = uuid(),
        identifier = identifier,
        command = command,
        args = { ... }
    })
end

function Scheduler.find(identifier)
    local r = {}

    for i, data in ipairs(memcache) do
        if data.identifier == identifier then
            table.insert(r, data)
        end
    end

    return r
end

function Scheduler.delete(id)
    for i=#memcache,1,-1 do
        if memcache[i].id == id then
            table.remove(memcache, i)
        end
    end
end

function Scheduler.save()
    SaveResourceFile(script_name, 'database/scheduler.json', json.encode(memcache), -1)
end