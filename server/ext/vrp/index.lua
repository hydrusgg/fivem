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

    function is_online(user_id) -- For some reason the vRP recognizes the source but throws silent errors
        local source = vRP.getUserSource(user_id)
        return source and source < 65500
    end

    function Commands.group(user_id, group)
        -- check if the user is online
        if is_online(user_id) then
            vRP.addUserGroup(user_id, group)
            return 'OK (Online)'
        else
            update_datatable(user_id, function(d)
                d.groups = d.groups or {}
                d.groups[group] = true
            end)
            return 'OK (Offline)'
        end
    end

    function Commands.ungroup(user_id, group)
        -- check if the user is online
        if is_online(user_id) then
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
    end
    create_command_ref('delgroup', 'ungroup')

    function Commands.additem(user_id, item, amount)
        -- check if the user is online
        if is_online(user_id) then
            vRP.giveInventoryItem(user_id, item, amount or 1)
            return 'OK (Online)'
        else
            -- Save for later execution, since the player is offline
            Scheduler.new(user_id, 'additem', user_id, item, amount or 1)
            return 'Scheduled'
        end
    end

    function Commands.additems(user_id, ...)
        local args = { ... }
        for i = 1, #args, 2 do
            Commands.additem(user_id, args[i], args[i+1])
        end
    end

    function Commands.addmoney(user_id, amount)
        -- check if the user is online
        if is_online(user_id) then
            vRP.giveBankMoney(user_id, amount)
            return 'OK (Online)'
        else
            SQL('UPDATE vrp_user_moneys SET bank=bank+? WHERE user_id=?', { amount, user_id })
            return 'OK (Offline)'
        end
    end

    function Commands.addvehicle(user_id, vehicle)
        local old = SQL('SELECT 1 FROM vrp_user_vehicles WHERE user_id=? AND vehicle=?', { user_id, vehicle })

        if #old > 0 then
            return _('already.owned.self')
        end

        local data = { user_id = user_id, vehicle = vehicle } 
        local tax = SQL.firstColumn('vrp_user_vehicles', 'tax', 'ipva')

        if tax then
            data[tax] = os.time()
        end

        SQL.insert('vrp_user_vehicles', data)
    end

    function Commands.addvehicles(user_id, ...)
        for _, spawn in ipairs({ ... }) do
            Commands.addvehicle(user_id, spawn)
        end
    end

    function Commands.delvehicle(user_id, vehicle)
        SQL('DELETE FROM vrp_user_vehicles WHERE user_id=? AND vehicle=?', { user_id, vehicle })
    end

    function Commands.delvehicles(user_id, ...)
        for _, spawn in pairs({ ... }) do
            Commands.delvehicle(user_id, spawn)
        end
    end

    function Commands.addhouse(user_id, name)
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
            tax = os.time(),
        })
    end
    
    function Commands.delhouse(user_id, name)
        local exists = SQL('SELECT 1 FROM vrp_homes_permissions WHERE user_id=? AND home=?', { user_id, name })[1]
        if exists then
            SQL('DELETE FROM vrp_homes_permissions WHERE home=?', { name })
        end
    end

    function Commands.changephone(user_id, phone)
        SQL('UPDATE vrp_user_identities SET phone=? WHERE user_id=?', { phone, user_id })
    end

    function Commands.ban(user_id)
        vRP.setBanned(user_id, true)

        local source = vRP.getUserSource(user_id)
        if source then
            DropPlayer(source)
            return 'OK (Online)'
        end
    end

    function Commands.unban(user_id)
        vRP.setBanned(user_id, false)
    end

    function Commands.whitelist(user_id)
        SQL('UPDATE vrp_users SET whitelisted = 1 WHERE id=?', { user_id })
    end

    function Commands.reset_character(user_id)
        SQL('UPDATE vrp_user_data SET dvalue=0 WHERE dkey=? AND user_id=?', { 'vRP:spawnController', user_id })
    end

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

    AddEventHandler('vRP:playerSpawn', function(user_id, source)
        local all = Scheduler.find(user_id)
        if #all > 0 then
            for _, data in ipairs(all) do
                if type(data.args) == 'table' then
                    local func = Commands[data.command]
                    local ok, err = pcall(func, table.unpack(data.args))
                    print_if(not ok, 'Error on schedule: %s %s\n%s', data.command, json.encode(data.args), err)
                    Scheduler.delete(data.id)
                else
                    printf('Scheduled command %d args isnt a table', data.id)
                end
            end
        end
        pcall(notify_credits, tostring(user_id), source)
    end)

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