ENV = {}

-- GlobalState is an easy way to share with the client
GlobalState['hydrus:lang'] = 'en'

ENV.debug = false
ENV.token = 'insert-your-token-here'
ENV.products = {}

-- Delete or comment this to disable the chat broadcast.
ENV.chat_styles = {
    'padding: 10px',
    'margin: 5px 0',
    'background-image: linear-gradient(to right, #b752ff 3%, #b752ff19 95%)',
    'border-radius: 5px',
    'color: snow',
    'display: flex',
    'align-items: center',
    'justify-content: center',
    'font-weight: bold',
}

AddEventHandler('hydrus:products-ready', function(scope)
    scope.addHomeProduct({
        name = 'Temporary Home', 
        category = 'Homes',
        credit = 'temporary_home',
        -- image = 'https://i.imgur.com/SMxEwXT.png', (Default)
        homes = 'LX:1-70,FH:1-100',
        days = 30
    })
    scope.addHomeProduct({
        name = 'Permanent Home',
        category = 'Homes',
        credit = 'permanent_home',
        -- image = 'https://i.imgur.com/SMxEwXT.png', (Default)
        homes = 'LX:1-70,FH:1-100',
    })
    scope.addVehicleProduct({
        name = 'Temporary Vehicle',
        category = 'Vehicles',
        credit = 'temporary_vehicle',
        -- image = 'https://i.imgur.com/samafbT.png', (Default)
        days = 30,
        vehicles = {
            hakuchou = 'Hakuchou'
        }
    })
    scope.addVehicleProduct({
        name = 'Permanent Vehicle',
        category = 'Vehicles',
        credit = 'permanent_vehicle',
        -- image = 'https://i.imgur.com/samafbT.png', (Default)
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