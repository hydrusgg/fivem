wait_before_intelisense = true

-- Delete this file if you don't want to auto identify your database model
CreateThread(function()
  local tables = table.pluck(SQL([[
    SELECT table_name AS name FROM information_schema.tables WHERE 
    table_schema = DATABASE()
  ]]), 'name')
  tables = table.reverse(tables)

  if GetResourceState('vrp') == 'started' then
    load_extension('vrp/index.lua')
    print(_('framework.detected', { name = 'vRP' }))
  end

  if tables.vrp_infos and tables.vrp_permissions then
    if load_extension('vrp/creative.lua') then
      debug('Creative (by summerz) template was injected')
    end
  elseif tables.summerz_characters then
    if load_extension('vrp/bahamas.lua') then
      debug('Bahamas (by summerz) template was injected')
    end
  end

  wait_before_intelisense = false
end)