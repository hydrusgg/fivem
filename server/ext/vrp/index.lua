create_extension('vrp', function()
    vRP = {}

    ----------------------------------------------
    -- You don't need to understand that part, but
    -- if you do, feel free to change anything
    -- (Currently everything is awaited)
    ----------------------------------------------

    vRP.__pointer = 0
    vRP.__callbacks = {}

    function vRP.__index(self, name) -- Lua magic methods
        self[name] = function(...)
            local p = promise.new()

            local id = self.__pointer + 1
            self.__pointer = id

            self.__callbacks[id] = p
            emit('vRP:proxy', name, {...}, script_name, id)

            return table.unpack(Citizen.Await(p))
        end
        return self[name]
    end

    AddEventHandler('vRP:'..script_name..':proxy_res', function(id, args)
        local p = vRP.__callbacks[id]
        if p then
            p:resolve(args)
            vRP.__callbacks[id] = nil
        end
    end)

    setmetatable(vRP, vRP)

    Proxy = {
        getId = vRP.getUserId,
        getSource = vRP.getUserSource,
    }

    function vRP.generate_plate(table, column)
        local chars = 'QWERTYUIOPASDFGHJKLZXCVBNM'
        local nums = '0123456789'
        
        local plate = string.gsub(ENV.plate_format or 'DDLLLDDD', '[DL]', function(letter)
            local all = letter == 'D' and nums or chars
            local index = math.random(#all)
            return all:sub(index, index)
        end)
    
        -- Check if the plate already exists on the database
        if #SQL.silent(sprint('SELECT 1 FROM %s WHERE %s=?', table, column), { plate }) > 0 then
            return vRP.generate_plate(table, column)
        end
    
        return plate
    end

    ----------------------------------------------
    -- COMMANDS
    --
    -- user_id always come as string, so parsing
    -- is mandatory when working with vRP functions
    ----------------------------------------------

    local function update_datatable(user_id, cb) -- Wrapper to update datatable
        local dt = json.decode(vRP.getUData(user_id, 'vRP:datatable'))
        if dt then 
            cb(dt)
            vRP.setUData(user_id, 'vRP:datatable', json.encode(dt))
        end
    end

    ensure_command('group', function(user_id, group)
        local online = is_online(user_id)

        if online == 'queue' then
            Scheduler.new(user_id, 'group', user_id, group)
            return 'Scheduled'
        elseif online then
            vRP.addUserGroup(user_id, group)
            return 'OK (Online)'
        else
            update_datatable(user_id, function(d)
                d.groups = d.groups or {}
                d.groups[group] = true
            end)
            return 'OK (Offline)'
        end
    end)

    ensure_command('ungroup', function(user_id, group)
        local online = is_online(user_id)

        if online == 'queue' then
            Scheduler.new(user_id, 'ungroup', user_id, group)
            return 'Scheduled'
        elseif online then
            vRP.removeUserGroup(user_id, group)
            return 'OK (Online)'
        else
            update_datatable(user_id, function(d)
                if d.groups then
                    d.groups[group] = nil
                end
            end)
            return 'OK (Offline)'
        end
    end)
    create_command_ref('delgroup', 'ungroup')

    ensure_command('additem', function(user_id, item, amount)
        -- check if the user is online
        if is_online(user_id) == true then
            vRP.giveInventoryItem(user_id, item, amount or 1)
            return 'OK (Online)'
        else
            -- Save for later execution, since the player is offline
            Scheduler.new(user_id, 'additem', user_id, item, amount or 1)
            return 'Scheduled'
        end
    end)

    ensure_command('additems', function(user_id, ...)
        local args = { ... }
        for i = 1, #args, 2 do
            Commands.additem(user_id, args[i], args[i+1])
        end
    end)

    ensure_command('addmoney', function(user_id, amount)
        local online = is_online(user_id)
        if online == true then
            vRP.giveBankMoney(user_id, amount)
            return 'OK (Online)'
        else
            Scheduler.new(user_id, 'addmoney', user_id, amount)
            return 'Scheduled'
        end
    end)

    ensure_command('addvehicle', function(user_id, vehicle)
        local old = SQL('SELECT 1 FROM vrp_user_vehicles WHERE user_id=? AND vehicle=?', { user_id, vehicle })

        if #old > 0 then
            return _('already.owned.self')
        end

        local data = { user_id = user_id, vehicle = vehicle } 
        local tax = SQL.first_column('vrp_user_vehicles', 'tax', 'ipva')
        local plate = SQL.first_column('vrp_user_vehicles', 'plate', 'placa')

        if tax then
            data[tax] = os.time()
        end
        if plate then
            data[plate] = vRP.generate_plate('vrp_user_vehicles', plate)
        end

        SQL.insert('vrp_user_vehicles', data)
    end)

    ensure_command('addvehicles', function(user_id, ...)
        for _, spawn in ipairs({ ... }) do
            Commands.addvehicle(user_id, spawn)
        end
    end)

    ensure_command('delvehicle', function(user_id, vehicle)
        SQL('DELETE FROM vrp_user_vehicles WHERE user_id=? AND vehicle=?', { user_id, vehicle })
    end)

    ensure_command('delvehicles', function(user_id, ...)
        for _, spawn in pairs({ ... }) do
            Commands.delvehicle(user_id, spawn)
        end
    end)

    ensure_command('addhouse', function(user_id, name)
        local old = SQL('SELECT user_id FROM vrp_homes_permissions WHERE owner=1 AND home=?', { name })[1]
        
        if old then
            if string.equals(user_id, old.user_id) then 
                return _('already.owned.self')
            end
            error(_('already.owned.someone'))
        end

        SQL.insert('vrp_homes_permissions', {
            user_id = user_id,
            home = name,
            owner = 1,
            garage = 1,
            tax = os.time(),
        })
    end)
    
    ensure_command('delhouse', function(user_id, name)
        local exists = SQL('SELECT 1 FROM vrp_homes_permissions WHERE user_id=? AND home=?', { user_id, name })[1]
        if exists then
            SQL('DELETE FROM vrp_homes_permissions WHERE home=?', { name })
        end
    end)

    ensure_command('changephone', function(user_id, phone)
        SQL('UPDATE vrp_user_identities SET phone=? WHERE user_id=?', { phone, user_id })
    end)

    ensure_command('ban', function(user_id)
        vRP.setBanned(user_id, true)

        local source = vRP.getUserSource(user_id)
        if source then
            DropPlayer(source)
            return 'OK (Online)'
        end
    end)

    ensure_command('unban', function(user_id)
        vRP.setBanned(user_id, false)
    end)

    ensure_command('whitelist', function(user_id)
        SQL('UPDATE vrp_users SET whitelisted = 1 WHERE id=?', { user_id })
    end)

    ensure_command('reset_character', function(user_id)
        SQL('UPDATE vrp_user_data SET dvalue=0 WHERE dkey=? AND user_id=?', { 'vRP:spawnController', user_id })
    end)

    Commands['system-notify'] = function(data)
        local payload = json.decode(Base64:decode(data))

        local user_id = payload.user_id
        local source = vRP.getUserSource(user_id)
        if not source then
            -- The player is offline, try again later...
            Scheduler.new(user_id, 'system-notify', data)
        else
            local status,order = Hydrus('GET', '/orders/'..payload.order_id)

            if status ~= 200 then
                logger('Failed to fetch order: %d', status)
                return 'Order not found'
            end

            emit('hydrus:system-notify', user_id, order)

            if ENV.chat_styles then
                local identity = vRP.getUserIdentity(user_id)
                local name = identity.name or identity.nome or identity.firstname

                local packages = {}
                for package in each(order.packages) do
                    table.insert(packages, package.pivot.amount..'x '..package.name)
                end

                emitNet('chat:addMessage', -1, {
                    template = string.format([[<div style="%s">%s</div>]], 
                        table.concat(ENV.chat_styles, ';'), _('chat.template')
                    ),
                    args = { name, table.concat(packages, ', ') }
                })
            end

            for item in each(order.packages) do
                remote.popup_async(source, item.name, item.image and item.image.url or 'http://platform.hydrus.gg/assets/image_unavailable.jpg')
            end
        end
        return '__delete__'
    end
    
    ------------------------------------------------------------------------
    -- SCHEDULER
    ------------------------------------------------------------------------

    AddEventHandler('vRP:playerSpawn', Scheduler.batch)

    ------------------------------------------------------------------------
    -- Credits API
    ------------------------------------------------------------------------

    function home_is_allowed:call(source, form)
        local user_id = vRP.getUserId(source)
        local row = SQL('SELECT user_id FROM vrp_homes_permissions WHERE home=? AND owner=1', { form.home })[1]
        return not row or string.equals(row.user_id, user_id)
    end

    function phone_is_allowed:call(source, form)
        local rows = SQL('SELECT 1 FROM vrp_user_identities WHERE phone=?', { form.phone })
        return #rows == 0
    end

    function phone_execute:call(source, form)
        local user_id = vRP.getUserId(source)
        return Commands.changephone(user_id, form.phone)
    end
end)