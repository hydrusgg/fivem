ENV = {}

-- GlobalState is an easy way to share with the client
GlobalState['hydrus:lang'] = 'en'

ENV.debug = false
ENV.token = 'insert-your-token-here'
ENV.products = {}

AddEventHandler('hydrus:products-ready', function(scope)
    scope.addHomeProduct({
        name = 'Temporary Home', 
        credit = 'temporary_home',
        homes = 'LX:1-70,FH:1-100',
        days = 30
    })
    scope.addHomeProduct({
        name = 'Permanent Home',
        credit = 'permanent_home',
        homes = 'LX:1-70,FH:1-100',
    })
    scope.addHomeProduct({
        name = 'Casa VIP Ouro',
        credit = 'house_ouro',
        homes = 'LX:1-70,FH:1-100',
    })
    scope.addVehicleProduct({
        name = 'Temporary Vehicle',
        credit = 'temporary_vehicle',
        days = 30,
        vehicles = {
            hakuchou = 'Hakuchou'
        }
    })
    scope.addVehicleProduct({
        name = 'Permanent Vehicle',
        credit = 'permanent_vehicle',
        vehicles = {
            hakuchou = 'Hakuchou'
        }
    })
    
    -- Custom product
    -- table.insert(ENV.products, {
    --     name = 'Change phone number',
    --     consume = { 'phone_number', 1 },
    --     image = '',
    --     form = {
    --         {
    --             label = _('insert.phone'),
    --             name = 'phone',
    --             pattern = '000-000'
    --         }
    --     },
    --     -- Look at plugins/ext/products.lua for the reference
    --     is_allowed = phone_is_allowed,
    --     execute = phone_execute
    -- })
end)