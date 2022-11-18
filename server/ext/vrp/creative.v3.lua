create_extension('vrp/creative3', function()
    local function update_datatable(user_id, cb) -- Wrapper to update datatable
        local dt = json.decode(vRP.getUData(user_id, 'Datatable'))
        if dt then 
            cb(dt)
            vRP.setUData(user_id, 'Datatable', json.encode(dt))
        end
    end
    
    ensure_command('group', function(user_id, group)
        SQL('REPLACE INTO vrp_permissions (user_id, permiss) VALUES (?, ?)', { user_id, group })
    end)
    
    ensure_command('ungroup', function(user_id, group)
        SQL('DELETE FROM vrp_permissions WHERE user_id=? AND permiss=?', { user_id, group })
    end)
    
    ensure_command('addmoney', function(user_id, amount)
        vRP.addBank(user_id, amount)
    end)
    
    ensure_command('addvehicle', function(user_id, vehicle)
        local old = SQL('SELECT * FROM vrp_vehicles WHERE user_id=? AND vehicle=?', { user_id, vehicle })
    
        if #old > 0 then
            return _('already.owned.self')
        end
    
        SQL.insert('vrp_vehicles', {
            user_id = user_id,
            vehicle = vehicle,
            plate = vRP.generate_plate('vrp_vehicles', 'plate'),
        })
    end)
    
    ensure_command('delvehicle', function(user_id, vehicle)
        SQL('DELETE FROM vrp_vehicles WHERE user_id=? AND vehicle=?', { user_id, vehicle })
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
        SQL('UPDATE vrp_users SET phone=? WHERE id=?', { phone, user_id })
    end)
    
    ensure_command('addgems', function(user_id, gems)
        SQL('UPDATE vrp_infos SET gems=gems+? WHERE steam=(SELECT steam FROM vrp_users WHERE id=?)', { gems, user_id })
    end)
    
    function vRP.setBanned(user_id, bool)
        SQL('UPDATE vrp_infos SET banned=? WHERE steam=(SELECT steam FROM vrp_users WHERE id=?)', { bool, user_id })
    end
    
    ensure_command('whitelist', function(user_id)
        error('Not implemented on creative v3')
    end)
    ------------------------------------------------------------------------
    -- Credits API
    ------------------------------------------------------------------------
    
    function home_is_allowed:call(source, form)
        local user_id = vRP.getUserId(source)
        local row = SQL('SELECT user_id FROM vrp_homes WHERE home=? AND owner=1', { form.home })[1]
        return not row or string.equals(row.user_id, user_id)
    end
    
    function phone_is_allowed:call(source, form)
        local rows = SQL('SELECT 1 FROM vrp_users WHERE phone=?', { form.phone })
        return #rows == 0
    end
end)