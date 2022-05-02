local function parse(string)
    local method, rawArgs = string:match('^vrp%.(.+)%((.+)%)$')

    if method then
        local args = table.map(
            rawArgs:split(','),
            function(item)
                return item:trim():match('"?([^"]+)"?')
            end
        )

        if method == 'removeGroup' then
            return ('ungroup %d %s'):format(args[1], args[2])
        elseif method == 'removeVehicle' then
            return ('delvehicle %d %s'):format(args[1], args[2])
        elseif method == 'removeHouse' or method == 'removeHome' or method == 'removeHousePermission' then
            return ('delhouse %d %s'):format(args[1], args[2])
        end
    end
end

function Commands.migrate_from_legacy()
    local rows = SQL([[
        SELECT id,`command`,UNIX_TIMESTAMP(expires_at) as expires_at
        FROM fstore_appointments
    ]])
    
    printf('Found %d appointments to migrate', #rows)

    local errors = {}
    local batch = {}

    for row in each(rows) do
        local ttl = math.max(0, row.expires_at - os.time())
        local parsed = parse(row.command)

        if not parsed then
            table.insert(errors, string.format(
                'ID: %d -> %s -> %d (Failed to parse)',
                row.id, row.command, row.expires_at
            ))
        else
            table.insert(batch, {
                command = parsed,
                execute_at = os.date('!%Y-%m-%dT%H:%M:%SZ', row.expires_at)
            })
        end
    end

    local status,body = Hydrus('POST', '/migrate_appointments', { commands = batch })

    if status ~= 200 then
        printf('Unable to migrate, status returned -> %d', status)
        return
    end

    if #errors > 0 then
        SaveResourceFile(script_name, 'errors.log', table.concat(errors, '\n'), -1)
        printf('Found %d errors, dumped at errors.log')
    end
    print('Migration finished.')
end