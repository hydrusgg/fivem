-------------------------------------------------------------------------------------------
--  The credits are used to give something specific that may not be available while shopping
--  such as things that may be owned by other player (phone number, house, vehicle plate)
--  or something that has multiple choices
--
--  Very often vRP needs this implementation to sell houses (vrp_homes_permissions).
--  Here, we are going to use LoadResourceFile for quick implementation and compatibility
--  you can adapt this to vRP.getUData
-------------------------------------------------------------------------------------------
local memcache = json.decode(LoadResourceFile(GetCurrentResourceName(), 'database/credits.json') or '{}')

-- At the moment, only vRP is supported
local function to_child(source)
    return tostring(vRP.getUserId(source) or 'nil')
end

-- At the moment, only vRP is supported
local function from_child(child)
    return vRP.getUserSource(parse_int(child))
end

local function get_credit(child, name)
    child = tostring(child)
    return optional(memcache, child, name) or 0
end

local function get_credits(child, key)
    if key then
        return get_credit(child)[key] or 0
    end
    child = tostring(child)
    return memcache[child] or {}
end

local function add_credit(child, name, amount)
    amount = amount or 1
    child = tostring(child)
    local credits = memcache[child] or {}
    local sum = (credits[name] or 0) + amount

    credits[name] = ternary(sum > 0, sum, nil)
    memcache[child] = ternary(table.empty(credits), nil, credits)

    SaveResourceFile(GetCurrentResourceName(), 'database/credits.json', json.encode(memcache), -1)
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

        for _, field in ipairs(product.form or {}) do
            local selected = form[field.name]
            assert(selected ~= nil, 'The '..field.label..' is mandatory')
            if field.pattern then
                local r = '^'..product.pattern:gsub('0', '%%d'):gsub('-', '%%-')..'$'
                assert(selected:match(r), 'Invalid format, follow the pattern '..product.pattern)
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
        assert(get_credits(child, credit) >= price, _('credits.insufficient'))

        sub_credit(child, credit, price)
        local ok, retval = pcall(product.execute, product, source, form)
        if not ok then
            add_credit(child, credit, price)
            printf(_('error', { error = retval }))
            error(_('contact.support'))
        end
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
load_extension('products.lua')
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