-------------------------------------------------------------------------------------------
--  The credits are used to give something specific that may not be available while shopping
--  such as things that may be owned by other player (phone number, house, vehicle plate)
--  or something that has multiple choices
--
--  Very often vRP needs this implementation to sell houses (vrp_homes_permissions).
--  you can adapt this to vRP.getUData instead of using the provided database table
-------------------------------------------------------------------------------------------
AddEventHandler('hydrus:database-ready', function()
    if not SQL.has_table('hydrus_credits') then
        SQL([[CREATE TABLE hydrus_credits (
            player_id VARCHAR(100) NOT NULL,
            name VARCHAR(100) NOT NULL,
            amount INT DEFAULT 0,
            PRIMARY KEY(player_id, name)
        )]])

        SQL.tables.hydrus_credits = { player_id = true, name = true, amount = true }

        local memcache = json.decode(LoadResourceFile(script_name, 'database/credits.json') or '{}')

        for player_id, credits in pairs(memcache) do
            for name, amount in pairs(credits) do
                SQL.replace('hydrus_credits', { player_id=player_id, name=name, amount=amount })
            end
        end

        SaveResourceFile(script_name, 'database/credits.json', '{}', -1)
    end
end)

local function get_credit(child, name)
    local rows = SQL.silent('SELECT amount FROM hydrus_credits WHERE player_id=? AND name=?', { child, name })
    return optional(rows, 1, 'amount') or 0
end

local function get_credits(child, key)
    if not child then
        return {}
    end

    local all = {}
    local rows = SQL.silent('SELECT name,amount FROM hydrus_credits WHERE player_id=?', { child })

    for row in each(rows) do
        all[row.name] = row.amount
    end

    return all
end

local function add_credit(child, name, amount)
    amount = amount or 1

    if amount > 0 then
        SQL([[
            INSERT INTO hydrus_credits (player_id, name, amount) VALUES (?,?,?)
            ON DUPLICATE KEY UPDATE amount=amount+?
        ]], { child, name, amount, amount })
    elseif amount < 0 then
        SQL('UPDATE hydrus_credits SET amount=amount-? WHERE player_id=? AND name=?', { math.abs(amount), child, name })
    end

    notify_credits(child, Proxy.getSource(child))
end

Commands.addcredit = add_credit

local function sub_credit(child, name, amount)
    add_credit(child, name, 0-(amount or 1))
end

Commands.subcredit = sub_credit
Commands.delcredit = sub_credit

function notify_credits(child, source)
    if not source then
        return
    end

    local user_credits = get_credits(child)

    local i = 0

    for index,v in ipairs(ENV.products) do
        local credit, amount = table.unpack(v.consume)
        local balance = user_credits[credit] or 0
        i+= math.floor(balance / amount)
    end
    
    emitNet('hydrus:credits', source, i)
end

AddEventHandler('hydrus:products-ready', function(scope)
    Wait(10e3)

    for _, source in ipairs(GetPlayers()) do
        local child = Proxy.getId(source)
        if child then
            notify_credits(child, source)
        end
    end
end)

local redeem_lock = {}

exports('addCredit', add_credit)

exports('consumeCredit', function(player_id, name, amount)
    amount = amount or 1
    assert(amount >= 1, 'Amount must be greater than 0')

    while redeem_lock[player_id] do
        Wait(0)
    end
    redeem_lock[player_id] = true

    local balance = SQL.scalar('SELECT amount FROM hydrus_credits WHERE player_id=? AND name=?', { player_id, name }) or 0
    local ok = balance >= amount

    if ok then
        SQL('UPDATE hydrus_credits SET amount=amount-? WHERE player_id=? AND name=?', { amount, player_id, name })
    end

    redeem_lock[player_id] = nil
    return ok
end)

local function lock(source, func)
    assert(not redeem_lock[source], 'Wait your past transaction to finish')
    redeem_lock[source] = true
    local ok, retval = pcall(func)
    redeem_lock[source] = nil
    assert(ok, retval)
    return retval
end

function main.redeem(source, index, form)
    return lock(source, function()
        local product = assert(ENV.products[index], 'Product not found')

        for field in each(product.form or {}) do
            local selected = form[field.name]
            assert(selected ~= nil, _('field.mandatory', { field = field.label }))
            if field.pattern then
                local r = '^'..field.pattern:gsub('0', '%%d'):gsub('-', '%%-')..'$'
                assert(selected:match(r), _('field.pattern.invalid', { pattern = field.pattern }))
            elseif field.options then
                local opt
                for _, option in pairs(field.options) do
                    if option.value == selected then
                        opt = option
                        break
                    end
                end
                assert(opt, 'Value not present in options')
            end
        end

        if product.is_allowed then
            assert(product:is_allowed(source, form), _('already.owned.someone'))
        end

        local credit, price = table.unpack(product.consume)
        local child = assert(Proxy.getId(source), 'Invalid child')

        local balance = get_credit(child, credit)
        assert(balance >= price, _('credits.insufficient'))

        sub_credit(child, credit, price)
        logger('%s reedemed credit "%s" Balance: %s -> %s [%s]', child, product.name, balance, balance-price, credit)
        local ok, retval = pcall(product.execute, product, source, form)
        if not ok then
            add_credit(child, credit, price)
            logger('%s was chargebacked due an error %s [%s]', child, price, credit)
            printf(_('error', { error = retval }))
            error(_('contact.support'))
        end
        emit('hydrus:redeem', child, product, form)
        return retval
    end)
end

local in_testdrive = {}

function main.testdrive(source, spawn)
    throw_if(in_testdrive[source], 'Already in testdrive')
    in_testdrive[source] = {
        bucket = GetPlayerRoutingBucket(source),
        origin = GetEntityCoords(GetPlayerPed(source))
    }

    SetPlayerRoutingBucket(source, 1000 + source)

    remote.start_testdrive(source, spawn)
end

function main.exit_testdrive(source)
    local info = in_testdrive[source]
    if info then
        SetPlayerRoutingBucket(source, info.bucket)

        local x,y,z = table.unpack(info.origin)
        SetEntityCoords(GetPlayerPed(source), x, y, z)
        in_testdrive[source] = nil
    end
end

------------------------------------------------
-- Create all the products
------------------------------------------------
load_extension('products')
------------------------------------------------
-- Command implementation
------------------------------------------------
RegisterCommand('store', function(source, args)
    if in_testdrive[source] then
        return
    end

    local user_credits = get_credits(Proxy.getId(source))

    local clone = {}
    for index,v in ipairs(ENV.products) do
        local credit, amount = table.unpack(v.consume)
        local balance = user_credits[credit] or 0

        if balance >= amount then
            table.insert(clone, {
                id = index,
                type = v.type,
                name = v.name,
                image = v.image,
                form = v.form,
                credits = balance,
            })
        end
    end

    if #clone == 0 then
        return
    end

    remote.open_store(source, clone)
end)