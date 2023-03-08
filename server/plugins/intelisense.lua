wait_before_intelisense = true

-- Delete this file if you don't want to auto identify your database model
CreateThread(function()
    local tables = SQL.silent([[
        SELECT table_name as t, column_name as c FROM information_schema.columns WHERE 
        table_schema = DATABASE()
    ]])

    for row in each(tables) do
        local table, column = row.t, row.c

        if SQL.tables[table] then
            SQL.tables[table][column] = true
        else
            SQL.tables[table] = { [column] = true }
        end
    end

    emit('hydrus:database-ready')

    if GetResourceState('vrp') == 'started' then
        load_extension('vrp')
        printf(_('framework.detected', { name = 'vRP' }))
    end

    if SQL.has_table('vrp_infos') and SQL.has_table('vrp_permissions') then
        if load_extension('vrp/creative3') then
            printf('Creative v3 (by summerz) template was injected')
        end
    elseif SQL.has_table('summerz_characters') then
        if load_extension('vrp/creative4') then
            printf('Creative v4 (by summerz) template was injected')
        end
    elseif GetResourceMetadata('vrp', 'creative_network') then
        if load_extension('vrp/creative_network') then
            printf('Creative Network (by summerz) template was injected')
        end
    elseif SQL.has_table('nyo_character') then
        if load_extension('nfw') then
            print(_('framework.detected', { name = 'NFW' }))
        end
    end

    if ENV.enhanced_intelisense then
        local status, body = http_request('https://raw.githubusercontent.com/hydrusgg/fivem/master/server/enhanced/intelisense.lua', 'GET'):await()

        if status ~= 200 then
            printf('Failed to stream the intelisense from github, status: %d', status)
        else
            local fn, error = load(body, '#enhanced.lua')
            if error then
                printf('Intelisense got a syntax error: %s', error)
            else
                local ok, res = pcall(fn)
                if not ok then
                    printf('Intelisense got a critical error: %s', res)
                elseif res and res.resolve then
                    -- Await the promise
                    Citizen.Await(res)
                end
            end
        end
    end

    wait_before_intelisense = false
    emit('hydrus:intelisense-ready')
end)