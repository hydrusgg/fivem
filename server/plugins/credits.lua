-------------------------------------------------------------------------------------------
--  The credits are used to give something specific that may not be available while shopping
--  such as things that may be owned by other player (phone number, house, vehicle plate)
--  or something that has multiple choices
--
--  Very often vRP needs this implementation to sell houses (vrp_homes_permissions).
--  you can adapt this to vRP.getUData instead of using the provided database table
-------------------------------------------------------------------------------------------
AddEventHandler('hydrus:database-ready', function()
    if not SQL.hasTable('hydrus_credits') then
        SQL([[CREATE TABLE hydrus_credits (
            player_id VARCHAR(100) NOT NULL,
            name VARCHAR(100) NOT NULL,
            amount INT DEFAULT 0,
            PRIMARY KEY(player_id, name)
        )]])

        local memcache = json.decode(LoadResourceFile(script_name, 'database/credits.json') or '{}')

        for player_id, credits in pairs(memcache) do
            for name, amount in pairs(credits) do
                SQL.replace('hydrus_credits', { player_id=player_id, name=name, amount=amount })
            end
        end

        SaveResourceFile(script_name, 'database/credits.json', '{}', -1)
    end
end)

-- At the moment, only vRP is supported
local function to_child(source)
    return tostring(vRP.getUserId(source) or 'nil')
end

-- At the moment, only vRP is supported
local function from_child(child)
    return vRP.getUserSource(parse_int(child))
end

local function get_credit(child, name)
    local rows = SQL('SELECT amount FROM hydrus_credits WHERE player_id=? AND name=?', { child, name })
    return optional(rows, 1, 'amount') or 0
end

local function get_credits(child, key)
    local all = {}
    local rows = SQL('SELECT name,amount FROM hydrus_credits WHERE player_id=?', { child })

    for row in each(rows) do
        all[row.name] = row.amount
    end

    return all
end

local function add_credit(child, name, amount)
    amount = amount or 1
    SQL([[
        INSERT INTO hydrus_credits (player_id, name, amount) VALUES (?,?,?)
        ON DUPLICATE KEY UPDATE amount=amount+?
    ]], { child, name, amount, amount })

    notify_credits(child, from_child(child))
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
        local child = to_child(source)
        if child ~= 'nil' then
            notify_credits(child, source)
        end
    end
end)

local redeem_lock = {}

local function lock(source, func)
    assert(not redeem_lock[source], 'Wait your past transaction to finish')
    
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
            product:is_allowed(source, form)
        end

        local credit, price = table.unpack(product.consume)

        local child = to_child(source)
        local balance = get_credit(child, credit)
        assert(balance >= price, _('credits.insufficient'))

        sub_credit(child, credit, price)
        logger('%s reedemed credit "%s" Balance: %d -> %d [%s]', child, product.name, balance, balance-price, credit)
        local ok, retval = pcall(product.execute, product, source, form)
        if not ok then
            add_credit(child, credit, price)
            logger('%s was chargebacked due an error %d [%s]', price, credit)
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

    local user_credits = get_credits(to_child(source))

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