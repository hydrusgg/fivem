--[[
    The platform supports a fast checkout route.

    The payload must follow this interface
    {
        cart: [
            { id: productId, amount: 1 },
            { id: productId, amount: 4 }
        ],
        customer: {
            name: 'John Doe',
            email: 'johndoe@email.com',
            document: '00000000191'
        },
        variables: {
            user_id: 1
        },
        integrations: {
            discord: 1928390128324,
            steam: 349089839012832
        }
    }
    Every entry is optional, not filling anything will result in an empty checkout
]]
local defaultAvatar = {
    discord = 'https://cdn.discordapp.com/embed/avatars/2.png',
    steam = 'http://platform.hydrus.gg/assets/steam_placeholder.png'
}

exports('createFastCheckout', function(payload, source)
    local integrations = payload.integrations
    if integrations then -- Cast integrations id to objects with id, name and avatarURL
        for platform in each { 'discord', 'steam' } do
            if type(integrations[platform]) == 'number' then
                integrations[platform] = {
                    id = integrations[platform],
                    name = _('autofilled'),
                    avatarURL = defaultAvatar[platform]
                }
            end
        end
    end

    local encoded = Base64:encode(json.encode(payload))
    local url = string.format('https://%s/checkout?fastCheckout=%s', Store.domain, encoded)

    if source then
        CreateThread(function()
            remote.open_url(source, url)
        end)
    end

    return url
end)

exports('findProduct', function(id)
    local status, data = http_request('https://api.hydrus.gg/shopping/packages/'..id, 'GET', nil, {
        ['x-hydrus-domain'] = Store.domain
    })

    throw_if(status ~= 200, 'Product not found')
    return data
end)