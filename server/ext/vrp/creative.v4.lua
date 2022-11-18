create_extension('vrp/creative4', function()
    vRP.getUserSource = vRP.userSource
    vRP.getUserIdentity = vRP.userIdentity
    Proxy = {
        getId = vRP.getUserId,
        getSource = vRP.userSource,
    }

    local function update_datatable(user_id, cb) -- Wrapper to update datatable
        local dt = json.decode(vRP.userData(user_id, 'Datatable'))
        if dt then 
            cb(dt)

            local params = { json.encode(dt), 'Datatable', user_id }
            SQL('UPDATE summerz_playerdata SET dvalue=? WHERE dkey=? AND user_id=?', params)
        end
    end

    ensure_command('group', function(user_id, group)
        vRP.setPermission(user_id, group)
    end)

    ensure_command('ungroup', function(user_id, group)
        vRP.remPermission(user_id, group)
    end)

    ensure_command('addmoney', function(user_id, amount)
        vRP.addBank(user_id, amount)
    end)

    ensure_command('addvehicle', function(user_id, vehicle)
        local old = SQL('SELECT * FROM summerz_vehicles WHERE user_id=? AND vehicle=?', { user_id, vehicle })

        if #old > 0 then
            return _('already.owned.self')
        end

        local data = { user_id = user_id, vehicle = vehicle }

        data.plate = vRP.generate_plate('summerz_vehicles', 'plate')
        data.tax = os.time()
        data.ipva = os.time()

        SQL.insert('summerz_vehicles', data)
    end)

    ensure_command('delvehicle', function(user_id, vehicle)
        SQL('DELETE FROM summerz_vehicles WHERE user_id=? AND vehicle=?', { user_id, vehicle })
    end)

    ensure_command('addhouse', function(user_id, name)
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
    end)

    ensure_command('delhouse', function(user_id, name)
        SQL('DELETE FROM vrp_homes WHERE user_id=? AND home=?', { user_id, name })
    end)

    ensure_command('changephone', function(user_id, phone)
        SQL('UPDATE summerz_characters SET phone=? WHERE id=?', { phone, user_id })
    end)

    ensure_command('addgems', function(user_id, gems)
        SQL([[UPDATE summerz_accounts SET gems=gems+?
            WHERE steam=(SELECT steam FROM summerz_characters WHERE id=?)
        ]], { gems, user_id })
    end)

    function vRP.setBanned(user_id, bool)
        local row = SQL('SELECT steam FROM summerz_characters WHERE id=?', { user_id })[1]
        
        if bool then
            SQL('INSERT INTO summerz_banneds (steam,days) VALUES (?,999)', { row.steam })
        else
            SQL('DELETE FROM summerz_banneds WHERE steam=?', { row.steam })
        end
    end

    ensure_command('whitelist', function(user_id)
        error('Not implemented on creative v4')
    end)

    ensure_command('reset_character', function(user_id)
        error('Not implemented on creative v4')
    end)

    AddEventHandler('playerConnect', Scheduler.batch)

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
end)