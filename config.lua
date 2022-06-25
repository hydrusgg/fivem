ENV = {}

-- GlobalState is an easy way to share with the client
GlobalState['hydrus:lang'] = 'en'

ENV.debug = false
ENV.token = 'insert-your-token-here'
-- Loads the intelisense from the github using load()
ENV.enhanced_intelisense = true
ENV.products = {}
ENV.testdrive = true

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
-- Styles for the /vip command
ENV.vip_styles = ENV.chat_styles
ENV.vip_command = 'vip'

AddEventHandler('hydrus:products-ready', function(scope)
    scope.addHomeProduct({
        name = 'Temporary Home', 
        credit = 'temporary_home',
        -- image = 'https://i.imgur.com/SMxEwXT.png', (Default)
        homes = 'LX:1-70,FH:1-100',
        days = 30,
    })
    scope.addHomeProduct({
        name = 'Permanent Home',
        credit = 'permanent_home',
        -- image = 'https://i.imgur.com/SMxEwXT.png', (Default)
        homes = 'LX:1-70,FH:1-100,Middle:1-100',
    })
    scope.addHomeProduct({
        name = 'Permanent Home',
        credit = 'permanent_home',
        -- image = 'https://i.imgur.com/SMxEwXT.png', (Default)
        homes = 'LX:1-70,FH:1-100',
    })
    scope.addVehicleProduct({
        name = 'Temporary Vehicle',
        credit = 'temporary_vehicle',
        -- image = 'https://i.imgur.com/samafbT.png', (Default)
        days = 30,
        vehicles = {
            ['hakuchou'] = 'Hakuchou'
        }
    })
    -- scope.addVehicleProduct({
    --     name = 'Permanent Vehicle',
    --     credit = 'permanent_vehicle',
    --     -- image = 'https://i.imgur.com/samafbT.png', (Default)
    --     vehicles = {
    --         ['hakuchou'] = 'Hakuchou'
    --     }
    -- })
    
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