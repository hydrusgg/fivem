create_extension('vrp/creative_network', function()
    vRP.getUserSource = vRP.Source
    vRP.getUserIdentity = vRP.Identity
    vRP.giveInventoryItem = vRP.GiveItem
    Proxy = {
        getId = vRP.Passport,
        getSource = vRP.Source,
    }

    local function not_implemented()
        error('Not implemented on creative network')
    end

    ensure_command('group', function(user_id, group, level)
        vRP.SetPermission(user_id, group, level)
    end)
    
    ensure_command('ungroup', function(user_id, group, level)
        if not level or vRP.HasPermission(user_id, group, level) then
            vRP.RemovePermission(user_id, group)
        end
    end)
    
    ensure_command('addmoney', function(user_id, amount)
        vRP.GiveBank(user_id, amount)
    end)
    
    ensure_command('addvehicle', function(user_id, vehicle)
        local old = SQL('SELECT * FROM vehicles WHERE Passport=? AND vehicle=?', { user_id, vehicle })
    
        if #old > 0 then
            return _('already.owned.self')
        end
    
        SQL.insert('vehicles', {
            Passport = user_id,
            vehicle = vehicle,
            plate = vRP.generate_plate('vehicles', 'plate'),
            doors = '{}',
            windows = '{}',
            tyres = '{}',
        })
    end)
    
    ensure_command('delvehicle', function(user_id, vehicle)
        SQL('DELETE FROM vehicles WHERE Passport=? AND vehicle=?', { user_id, vehicle })
    end)
    
    ensure_command('addhouse', not_implemented)
    ensure_command('delhouse', not_implemented)
    
    ensure_command('changephone', function(user_id, phone)
        SQL('UPDATE characters SET phone=? WHERE id=?', { phone, user_id })
    end)
    
    ensure_command('addgems', function(user_id, gems)
        SQL('UPDATE accounts SET gems=gems+? WHERE license=(SELECT license FROM characters WHERE id=?)', { gems, user_id })
    end)
    
    function vRP.setBanned(user_id, bool)
        SQL('UPDATE accounts SET banned=? WHERE license=(SELECT license FROM characters WHERE id=?)', { bool, user_id })
    end
    
    ensure_command('whitelist', not_implemented)

    AddEventHandler('Connect', Scheduler.batch)
    ------------------------------------------------------------------------
    -- Credits API
    ------------------------------------------------------------------------
    
    function home_is_allowed:call(source, form)
        local user_id = vRP.Passport(source)
        local row = SQL('SELECT Passport FROM propertys WHERE Name=?', { form.home })[1]
        return not row or string.equals(row.Passport, user_id)
    end
    
    function phone_is_allowed:call(source, form)
        local rows = SQL('SELECT 1 FROM characters WHERE phone=?', { form.phone })
        return #rows == 0
    end
end)