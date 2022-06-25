wait_before_intelisense = true

-- Delete this file if you don't want to auto identify your database model
CreateThread(function()
  local tables = table.pluck(SQL([[
    SELECT table_name AS name FROM information_schema.tables WHERE 
    table_schema = DATABASE()
  ]]), 'name')
  tables = table.reverse(tables)
  SQL.tables = tables

  if GetResourceState('vrp') == 'started' then
    load_extension('vrp/index.lua')
    print(_('framework.detected', { name = 'vRP' }))
  end

  if tables.vrp_infos and tables.vrp_permissions then
    if load_extension('vrp/creative.v3.lua') then
      logger('Creative v3 (by summerz) template was injected')
    end
  elseif tables.summerz_characters then
    if load_extension('vrp/creative.v4.lua') then
      logger('Creative v4 (by summerz) template was injected')
    end
  end

  if ENV.enhanced_intelisense then
    local status, body = http_request('https://raw.githubusercontent.com/hydrusgg/fivem/master/server/enhanced/intelisense.lua', 'GET'):await()

    if status ~= 200 then
        printf('Failed to stream the intelisense from github, status: %d', status)
    else
        local fn, error = load(body)
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