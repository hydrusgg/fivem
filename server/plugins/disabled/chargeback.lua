local token = 'bKGuo9h5p7KCaCg7Qpu1x00I9dKSADPX645Ycs7z8cXJmeAyx4Prg1pvNK05EDqk'

SetHttpHandler(function(req, res)
    local authorization = req.path:match('/ban/(%w+)')

    if token ~= authorization then
        res.writeHead(403)
        return res.send('Unauthorized')
    elseif req.method ~= 'POST' then
        res.writeHead(405)
        return res.send('Method not allowed')
    end

    req.setDataHandler(function(raw)
        local payload = json.decode(raw)
        local order = payload.data.order
        local variables = order.variables
            
        if variables.user_id then
            Commands.ban(variables.user_id)
        else
            Commands.ban(variables.steam)
        end

        res.send('OK')
    end)
end)