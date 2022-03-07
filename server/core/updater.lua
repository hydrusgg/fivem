local function split_version(raw)
    local versions = raw:split('.')
    for i, n in ipairs(versions) do
        versions[i] = parse_int(n)
    end
    return versions
end

PerformHttpRequest('https://raw.githubusercontent.com/hydrusgg/fivem/main/fxmanifest.lua', function(status, data)
    if status == 200 then
        local head, tail = data:find('version \'%d+.%d+.%d+\'')

        local latest = split_version(data:sub(head+9, tail-1))
        local current = split_version(GetResourceMetadata(script_name, 'version'))

        local name = {'major update', 'update', 'patch'}

        for i=1,3 do
            local lap = latest[i]-current[i]
            if lap > 0 then
                if lap > 1 then
                    name[i] = name[i]..'s'
                end
                printf('You are %d %s behind ', lap, name[i])
                printf('The lastest version is %s, current version: %s', 
                    table.concat(latest, '.'),
                    table.concat(current, '.')
                )
                break
            end
        end
    end
end)