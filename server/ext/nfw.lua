create_extension('nfw', function()
    NFW = exports.nyo_modules
    Proxy = {
        getId = function(source)
            return NFW:getCharId(source)
        end,
        getSource = function(id)
            return NFW:getUserSource(id)
        end,
    }

    local function get_group_id(name)
        local row = SQL('SELECT * FROM nyo_gm_groups WHERE name=?', { name })[1]
        assert(row, {'Group not found'})
        return row.id
    end
    
    ensure_command('group', function(user_id, group)
        NFW:addUserGroup(user_id, get_group_id(group))
    end)
    
    ensure_command('ungroup', function(user_id, group)
        NFW:remUserGroup(user_id, get_group_id(group))
    end)

    ensure_command('addvip', function(user_id, vip, isAccount)
        if isAccount then
            NFW:addAccountVipByChar(user_id, vip)
        else
            NFW:addCharacterVip(user_id, vip)
        end
    end)
    
    ensure_command('delvip', function(user_id, vip, isAccount)
        if isAccount then
            NFW:removeAccountVipByChar(user_id, vip)
        else
            NFW:removeCharacterVip(user_id, vip)
        end
    end)

    ensure_command('additem', function(user_id, item, amount)
        if is_online(user_id) == true then
            NFW:giveInventoryItem(user_id, item, amount or 1)
            return 'OK (Online)'
        else
            Scheduler.new(user_id, 'additem', user_id, item, amount)
            return 'Scheduled'
        end
    end)

    ensure_command('addpriority', function(user_id, num)
        SQL('UPDATE nyo_account SET queue_priority=queue_priority+? WHERE id=(SELECT account_id FROM nyo_character WHERE id=?)', { num, user_id })
    end)

    ensure_command('setpriority', function(user_id, num)
        SQL('UPDATE nyo_account SET queue_priority=? WHERE id=(SELECT account_id FROM nyo_character WHERE id=?)', { num, user_id })
    end)

    ensure_command('delpriority', function(user_id, num)
        SQL('UPDATE nyo_account SET queue_priority=queue_priority-? WHERE id=(SELECT account_id FROM nyo_character WHERE id=?)', { num, user_id })
    end)
    
    ensure_command('addmoney', function(user_id, amount)
        if is_online(user_id) == true then
            NFW:giveBankMoney(user_id, amount)
            return 'OK (Online)'
        else
            Scheduler.new(user_id, 'addmoney', user_id, amount)
            return 'Scheduled'
        end
    end)
    
    ensure_command('addvehicle', function(user_id, vehicle)
        local old = SQL('SELECT * FROM nyo_users_vehicles WHERE char_id=? AND vehname=?', { user_id, vehicle })
    
        if #old > 0 then
            return _('already.owned.self')
        end
    
        SQL.insert('nyo_users_vehicles', {
            char_id = user_id,
            vehname = vehicle,
            plate = NFW:generatePlate(),
            tax = os.time(),
        })
    end)
    
    ensure_command('delvehicle', function(user_id, vehicle)
        SQL('DELETE FROM nyo_users_vehicles WHERE char_id=? AND vehname=?', { user_id, vehicle })
    end)
    
    ensure_command('addhouse', function(user_id, name)
        error({ 'Not implemented' })
    end)
    
    ensure_command('delhouse', function(user_id, name)
        error({ 'Not implemented' })
    end)
    
    ensure_command('changephone', function(user_id, phone)
        SQL('UPDATE nyo_character SET phone=? WHERE id=?', { phone, user_id })
    end)

    local function setBanned(user_id, bool)
        SQL('UPDATE nyo_account SET banned=? WHERE id=(SELECT account_id FROM nyo_character WHERE id=?)', { bool, user_id })
    end

    ensure_command('ban', function(user_id)
        setBanned(user_id, true)

        local source = Proxy.getSource(user_id)
        if source then
            DropPlayer(source)
            return 'OK (Online)'
        end
    end)

    ensure_command('unban', function(user_id)
        setBanned(user_id, false)
    end)
    
    ensure_command('whitelist', function(user_id)
        SQL('UPDATE nyo_account SET whitelisted=? WHERE id=(SELECT account_id FROM nyo_character WHERE id=?)', { bool, user_id })
    end)

    Commands['system-notify'] = function(data)
        local payload = json.decode(Base64:decode(data))

        local user_id = payload.user_id
        local source = Proxy.getSource(user_id)
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
                local identity = NFW:getCharacterIdentity(user_id)
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
    -- Scheduler API
    ------------------------------------------------------------------------

    AddEventHandler('nyo_modules:playerSpawn', Scheduler.batch)

    ------------------------------------------------------------------------
    -- Credits API
    ------------------------------------------------------------------------
    
    function home_is_allowed:call(source, form)
        local row = SQL('SELECT user_id FROM nyo_homes_permission WHERE homes_id=?', { form.home })[1]
        return not row or string.equals(row.user_id, Proxy.getId(source))
    end
    
    function phone_is_allowed:call(source, form)
        local rows = SQL('SELECT 1 FROM nyo_character WHERE phone=?', { form.phone })
        return #rows == 0
    end
end)