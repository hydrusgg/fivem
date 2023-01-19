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
    
    ensure_command('group', function(char_id, group)
        NFW:addUserGroup(char_id, get_group_id(group))
    end)
    
    ensure_command('ungroup', function(char_id, group)
        NFW:remUserGroup(char_id, get_group_id(group))
    end)

    ensure_command('addvip', function(char_id, vip, isAccount)
        if isAccount then
            NFW:addAccountVipByChar(char_id, vip)
        else
            NFW:addCharacterVip(char_id, vip)
        end
    end)
    
    ensure_command('delvip', function(char_id, vip, isAccount)
        if isAccount then
            NFW:removeAccountVipByChar(char_id, vip)
        else
            NFW:removeCharacterVip(char_id, vip)
        end
    end)

    ensure_command('additem', function(char_id, item, amount)
        if is_online(char_id) == true then
            NFW:giveInventoryItem(char_id, item, amount or 1)
            return 'OK (Online)'
        else
            Scheduler.new(char_id, 'additem', char_id, item, amount)
            return 'Scheduled'
        end
    end)

    ensure_command('addpriority', function(char_id, num)
        SQL('UPDATE nyo_account SET queue_priority=queue_priority+? WHERE id=(SELECT account_id FROM nyo_character WHERE id=?)', { num, char_id })
    end)

    ensure_command('setpriority', function(char_id, num)
        SQL('UPDATE nyo_account SET queue_priority=? WHERE id=(SELECT account_id FROM nyo_character WHERE id=?)', { num, char_id })
    end)

    ensure_command('delpriority', function(char_id, num)
        SQL('UPDATE nyo_account SET queue_priority=queue_priority-? WHERE id=(SELECT account_id FROM nyo_character WHERE id=?)', { num, char_id })
    end)
    
    ensure_command('addmoney', function(char_id, amount)
        if is_online(char_id) == true then
            NFW:giveBankMoney(char_id, amount)
            return 'OK (Online)'
        else
            Scheduler.new(char_id, 'addmoney', char_id, amount)
            return 'Scheduled'
        end
    end)
    
    ensure_command('addvehicle', function(char_id, vehicle)
        local old = SQL('SELECT * FROM nyo_users_vehicles WHERE char_id=? AND vehname=?', { char_id, vehicle })
    
        if #old > 0 then
            return _('already.owned.self')
        end
    
        SQL.insert('nyo_users_vehicles', {
            char_id = char_id,
            vehname = vehicle,
            plate = NFW:generatePlate(),
            tax = os.time(),
        })
    end)
    
    ensure_command('delvehicle', function(char_id, vehicle)
        SQL('DELETE FROM nyo_users_vehicles WHERE char_id=? AND vehname=?', { char_id, vehicle })
    end)
    
    ensure_command('addhouse', function(char_id, id)
        -- error({ 'Not implemented' })
        SQL.replace('nyo_homes_permission', {
            homes_id = id,
            charId = char_id,
            owner = 1,
            vault = 1,
        })
    end)
    
    ensure_command('delhouse', function(char_id, id)
        local row = SQL('SELECT 1 FROM nyo_homes_permission WHERE homes_id=? AND charId=?', { id, char_id })[1]

        if row then
            SQL('DELETE FROM nyo_homes_permission WHERE homes_id=?', { id })
            return 'OK (Owner)'
        end
    end)
    
    ensure_command('changephone', function(char_id, phone)
        SQL('UPDATE nyo_character SET phone=? WHERE id=?', { phone, char_id })
    end)

    local function setBanned(char_id, bool)
        SQL('UPDATE nyo_account SET banned=? WHERE id=(SELECT account_id FROM nyo_character WHERE id=?)', { bool, char_id })
    end

    ensure_command('ban', function(char_id)
        setBanned(char_id, true)

        local source = Proxy.getSource(char_id)
        if source then
            DropPlayer(source)
            return 'OK (Online)'
        end
    end)

    ensure_command('unban', function(char_id)
        setBanned(char_id, false)
    end)
    
    ensure_command('whitelist', function(char_id)
        SQL('UPDATE nyo_account SET whitelisted=? WHERE id=(SELECT account_id FROM nyo_character WHERE id=?)', { bool, char_id })
    end)

    Commands['system-notify'] = function(data)
        local payload = json.decode(Base64:decode(data))

        local char_id = payload.user_id
        local source = Proxy.getSource(char_id)
        if not source then
            -- The player is offline, try again later...
            Scheduler.new(char_id, 'system-notify', data)
        else
            local status,order = Hydrus('GET', '/orders/'..payload.order_id)

            if status ~= 200 then
                logger('Failed to fetch order: %d', status)
                return 'Order not found'
            end

            if ENV.chat_styles then
                local identity = NFW:getCharacterIdentity(char_id)
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
        local row = SQL('SELECT charId FROM nyo_homes_permission WHERE homes_id=? AND owner=1', { form.home })[1]
        return not row or string.equals(row.charId, Proxy.getId(source))
    end
    
    function phone_is_allowed:call(source, form)
        local rows = SQL('SELECT 1 FROM nyo_character WHERE phone=?', { form.phone })
        return #rows == 0
    end
end)