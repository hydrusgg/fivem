-- Base64 Encode

Base64 = {
    chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
}

function Base64:encode(data)
    return ((data:gsub('.', function(x) 
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return self.chars:sub(c+1,c+1)
    end))
end

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

exports('createFastCheckout', function(payload)
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

    local url = 'https://%s/checkout?fastCheckout=%s'
    local fastCheckout = Base64:encode(json.encode(payload))
    return url:format(Store.domain, fastCheckout)
end)