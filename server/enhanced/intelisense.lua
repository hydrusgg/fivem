AddEventHandler('hydrus:intelisense-ready', function()
    if SQL.hasTable('core_residences') and SQL.hasTable('core_homes') then
        
        function home_is_allowed:call(source, form)
            local user_id = vRP.getUserId(source)
            local row = SQL('SELECT 1 FROM core_homes WHERE name=? AND owner=1', { form.home })[1]
            return not row or string.equals(row.user_id, user_id)
        end

        function Commands.addhouse(user_id, name)
            local old = SQL('SELECT user_id FROM core_homes WHERE owner=1 AND name=?', { name })[1]
            
            if old then
                if string.equals(user_id, old.user_id) then 
                    return _('already.owned.self')
                end
                error(_('already.owned.someone'))
            end

            local info = SQL('SELECT * FROM core_residences WHERE name=?', { name })[1]

            assert(info, {'House not found'})
    
            SQL.insert('core_homes', {
                user_id = user_id,
                name = name,
                interior = info.interiorType,
                price = 0,
                owner = 1,
                tax = os.time(),
            })
        end
    
        function Commands.delhouse(user_id, name)
            local exists = SQL('SELECT 1 FROM core_homes WHERE user_id=? AND name=?', { user_id, name })[1]
            if exists then
                SQL('DELETE FROM core_homes WHERE name=?', { name })
            end
        end
    end

    if SQL.hasColumn('vrp_user_veiculos', 'veiculo') then
        ensure_command('addvehicle', function(user_id, vehicle)
            local old = SQL('SELECT * FROM vrp_user_veiculos WHERE user_id=? AND veiculo=?', { user_id, vehicle })
        
            if #old > 0 then
                return _('already.owned.self')
            end
        
            SQL.insert('vrp_user_veiculos', {
                user_id = user_id,
                veiculo = vehicle,
                placa = vRP.generate_plate('vrp_user_veiculos', 'placa'),
                ipva = os.time(),
            })
        end)
        
        ensure_command('delvehicle', function(user_id, vehicle)
            SQL('DELETE FROM vrp_user_veiculos WHERE user_id=? AND veiculo=?', { user_id, vehicle })
        end)
    end

    if SQL.hasTable('nation_user_vehicles') then
        ensure_command('addvehicle', function(user_id, vehicle)
            local plate = generate_plate('nation_user_vehicles', 'plate')
            exports["nation-garages"]:addUserVehicle(vehicle, user_id, { plate = plate })
            return plate
        end)

        ensure_command('delvehicle', function(user_id, plate)
            exports["nation-garages"]:deleteUserVehicle(plate)
            SQL('DELETE FROM nation_user_vehicles WHERE `user`=? AND `vehicle`=? LIMIT 1', { user_id, plate })
        end)

        function vehicle_execute:call(source, form)
            local user_id = Proxy.getId(source)
    
            local plate = Commands.addvehicle(user_id, form.vehicle)
    
            if self.days then
                local status = Hydrus('POST', '/commands', {
                    command = string.format('delvehicle %s %s', user_id, plate),
                    scope = 'plugin',
                    ttl = 86400 * self.days
                })
                if status ~= 200 then
                    Commands.delvehicle(user_id, plate)
                    error('Failed to store pending command in vehicle_execute')
                end
            end
        end
    end
end)