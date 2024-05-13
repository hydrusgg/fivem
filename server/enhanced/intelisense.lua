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

            local data = {
                user_id = user_id,
                veiculo = vehicle,
                ipva = os.time(),
            }

            if SQL.hasColumn('vrp_user_veiculos', 'placa') then
                data.placa = vRP.generate_plate('vrp_user_veiculos', 'placa')
            end
        
            SQL.insert('vrp_user_veiculos', data)
        end)
        
        ensure_command('delvehicle', function(user_id, vehicle)
            SQL('DELETE FROM vrp_user_veiculos WHERE user_id=? AND veiculo=?', { user_id, vehicle })
        end)
    end

    if SQL.hasTable('nation_user_vehicles') then
        ensure_command('addvehicle', function(user_id, vehicle)
            local exists = SQL('SELECT 1 FROM nation_user_vehicles WHERE `user`=? AND `vehicle`=?', { user_id, vehicle })[1]

            if exists then
                return _('already.owned.self')
            end

            local plate = generate_plate('nation_user_vehicles', 'plate')
            exports["nation-garages"]:addUserVehicle(vehicle, user_id, { plate = plate })
        end)

        ensure_command('delvehicle', function(user_id, vehicle)
            SQL('DELETE FROM nation_user_vehicles WHERE `user`=? AND (`vehicle`=? OR `plate`=?) LIMIT 1', { user_id, vehicle, vehicle })
        end)
    end
end)

CreateThread(function()
    while not ENV.ignore_update do
        print('Este script foi descontinuado e não recebe mais correções ou atualizações, por favor atualize para a nova versão: https://docs.hydrus.gg/pt-br/jogos/fivem/configuracao')
        print('Para ignorar este aviso, insira ENV.ignore_update = true em sua config.lua')
        Wait(60000)
    end
end)