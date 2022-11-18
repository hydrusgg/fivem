create_extension('products', function()
    ------------------------------------------------
    -- Injecting into env context
    ------------------------------------------------

    local scope = {}

    --[[
        (LX, 1, 70) will output an table with 70 values
        LX01, LX02, LX03, LX04 ........... LX70
    ]]
    function scope.home_range(prefix, from, to, pad)
        local res = {}

        for i=from, to do
            while #(tostring(i)) < pad do
                i = '0'..i
            end
            table.insert(res, {
                label = prefix .. i,
                value = prefix .. i
            })
        end

        return res
    end

    function scope.compile_homes(raw)
        local options = {}
        for _, part in ipairs(raw:split(',')) do
            local prefix, interval = table.unpack(part:split(':'))
            local head, tail, pad = table.unpack(interval:split('-'))
            if not tail then
                tail = head
            end
            options = table.join(options, scope.home_range(prefix, parse_int(head), parse_int(tail), parse_int(pad or 2)))
        end
        return options
    end

    -- Using that way, the intelisense.lua it's capable of overwriting the default behavior
    home_is_allowed = callable(function()
        error('home_is_allowed is not implemented')
    end)

    home_execute = callable(function(self, source, form)
        local user_id = Proxy.getId(source)

        local owned = Commands.addhouse(user_id, form.home)

        if self.days then
            local status = Hydrus('POST', '/commands', {
                command = string.format('delhouse %s %s', user_id, form.home),
                scope = 'plugin',
                ttl = 86400 * self.days
            })
            if status ~= 200 then
                if not owned then
                    Commands.delhouse(user_id, form.home)
                end
                error('Failed to store pending command in home_execute, status: '..status)
            end
        end
    end)

    function scope.addHomeProduct(data)
        table.insert(ENV.products, {
            name = data.name,
            category = data.category,
            consume = { data.credit, 1 },
            image = data.image or 'https://i.imgur.com/SMxEwXT.png',
            form = {
                {
                    label = _('select.home'),
                    name = 'home',
                    options = scope.compile_homes(data.homes)
                }
            },
            type = 'home',
            days = data.days,
            is_allowed = home_is_allowed,
            execute = home_execute
        })
    end

    function scope.compile_vehicles(t)
        local options = {}
        for k,v in pairs(t) do
            table.insert(options, { value = k, label = v })
        end
        table.sort(options, function(a, b)
            return a.label < b.label
        end)
        return options
    end

    -- Using that way, the intelisense.lua it's capable of overwriting the default behavior
    vehicle_is_allowed = callable(function()
        return true
    end)

    vehicle_execute = callable(function(self, source, form)
        local user_id = Proxy.getId(source)

        local owned = Commands.addvehicle(user_id, form.vehicle)

        if self.days then
            local status = Hydrus('POST', '/commands', {
                command = string.format('delvehicle %s %s', user_id, form.vehicle),
                scope = 'plugin',
                ttl = 86400 * self.days
            })
            if status ~= 200 then
                if not owned then
                    Commands.delvehicle(user_id, form.vehicle)
                end
                error('Failed to store pending command in vehicle_execute')
            end
        end
    end)

    -- Using that way, the intelisense.lua it's capable of overwriting the default behavior
    phone_is_allowed = callable(function()
        error('phone_is_allowed is not implemented')
    end)

    -- Using that way, the intelisense.lua it's capable of overwriting the default behavior
    phone_execute = callable(function()
        error('phone_execute is not implemented')
    end)

    function scope.addVehicleProduct(data)
        table.insert(ENV.products, {
            name = data.name,
            category = data.category,
            consume = { data.credit, 1 },
            image = data.image or 'https://i.imgur.com/samafbT.png',
            form = {
                {
                    label = _('select.vehicle'),
                    name = 'vehicle',
                    options = scope.compile_vehicles(data.vehicles)
                }
            },
            type = ternary(ENV.testdrive == false, nil, 'vehicle'),
            days = data.days,
            is_allowed = vehicle_is_allowed,
            execute = vehicle_execute
        })
    end

    emit('hydrus:products-ready', scope)
end)