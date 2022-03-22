vRP.getUserSource = vRP.userSource
vRP.getUserIdentity = vRP.userIdentity

local function update_datatable(user_id, cb) -- Wrapper to update datatable
    local dt = json.decode(vRP.userData(user_id, 'Datatable'))
    if dt then 
        cb(dt)

        local params = { json.encode(dt), 'Datatable', user_id }
        SQL('UPDATE summerz_playerdata SET dvalue=? WHERE dkey=? AND user_id=?', params)
    end
end

function Commands.group(user_id, group)
    vRP.setPermission(user_id, group)
end

function Commands.ungroup(user_id, group)
    vRP.remPermission(user_id, group)
end
Commands.delgroup = Commands.ungroup

function Commands.addmoney(user_id, amount)
    vRP.addBank(user_id, amount)
end

local function generate_plate()
    local chars = "QWERTYUIOPASDFGHJKLZXCVBNM"
    local nums = "0123456789"
    
    local plate = string.gsub('DDLLLDDD', '[DL]', function(letter)
        local all = letter == 'D' and nums or chars
        local index = math.random(#all)
        return all:sub(index, index)
    end)

    -- Check if the plate already exists on the database
    if #SQL('SELECT 1 FROM summerz_vehicles WHERE plate=?'. { plate }) > 0 then
        return generate_plate()
    end

    return plate
end

function Commands.addvehicle(user_id, vehicle)
    local old = SQL('SELECT * FROM summerz_vehicles WHERE user_id=? AND vehicle=?', { user_id, vehicle })

    if #old > 0 then
        return _('already.owned.self')
    end

    SQL.insert('summerz_vehicles', {
        user_id = user_id,
        vehicle = vehicle,
        plate = generate_plate(),
    })
end

function Commands.delvehicle(user_id, vehicle)
  SQL('DELETE FROM summerz_vehicles WHERE user_id=? AND vehicle=?', { user_id, vehicle })
end

function Commands.addhouse(user_id, name)
  local old = SQL('SELECT * FROM vrp_homes WHERE owner=1 AND home=?', { name })[1]
  
  if old then
      if string.equals(user_id, old.user_id) then 
          return _('already.owned.self')
      end
      error(_('already.owned.someone'))
  end

  SQL.insert('vrp_homes', {
      user_id = user_id,
      home = name,
      owner = 1,
      tax = os.time(),
  })
end

function Commands.delhouse(user_id, name)
  SQL('DELETE FROM vrp_homes WHERE user_id=? AND home=?', { user_id, name })
end

function Commands.changephone(user_id, phone)
  SQL('UPDATE summerz_characters SET phone=? WHERE id=?', { phone, user_id })
end

function Commands.addgems(user_id, gems)
    SQL([[UPDATE summerz_accounts SET gems=gems+?
        WHERE steam=(SELECT steam FROM summerz_characters WHERE id=?)
    ]], { gems, user_id })
end

function vRP.setBanned(user_id, bool)
    local row = SQL('SELECT steam FROM summerz_characters WHERE id=?', { user_id })[1]
    
    if bool then
        SQL('INSERT INTO summerz_banneds (steam,days) VALUES (?,999)', { row.steam })
    else
        SQL('DELETE FROM summerz_banneds WHERE steam=?', { row.steam })
    end
end

------------------------------------------------------------------------
-- Credits API
------------------------------------------------------------------------

function home_is_allowed:call(source, form)
    local user_id = vRP.getUserId(source)
    local row = SQL('SELECT user_id FROM vrp_homes WHERE home=? AND owner=1', { form.home })[1]
    return not row or string.equals(row.user_id, user_id)
end

function phone_is_allowed:call(source, form)
    local rows = SQL('SELECT 1 FROM summerz_characters WHERE phone=?', { form.phone })
    return #rows == 0
end