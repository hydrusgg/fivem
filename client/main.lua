function main.open_store(clone)
    SendNUIMessage({ 'set_credits', clone })
    SendNUIMessage({ 'set_visible', true })
    SetNuiFocus(true, true)
end

function main.popup(...)
    SendNUIMessage({ 'set_popup', ... })
end

RegisterNUICallback('close', function(data, cb)
    SetNuiFocus(false, false)
    cb('empty')
end)

RegisterNUICallback('remote', function(data, cb)
    local fname = table.remove(data, 1) -- Shift

    local res = { pcall(remote[fname], table.unpack(data)) }
    cb(res)
end)