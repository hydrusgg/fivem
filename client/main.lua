function main.open_store(clone)
    SendNUIMessage({ 'set_credits', clone })
    SendNUIMessage({ 'set_visible', true })
    SetNuiFocus(true, true)
end

function main.close_store(clone)
    SendNUIMessage({ 'set_visible', false })
    SetNuiFocus(false)
end

function main.popup(...)
    SendNUIMessage({ 'add_popup', ... })
end

RegisterNetEvent('hydrus:popup', function(name, image_url)
    SendNUIMessage({ 'add_popup', name, image_url })
end)

function main.open_url(url)
    SendNUIMessage({ 'open_url', url })
end

onNet('hydrus:credits', function(count)
    SendNUIMessage({ 'set_pending', count })
end)

RegisterNUICallback('close', function(data, cb)
    SetNuiFocus(false, false)
    cb('empty')
end)

RegisterNUICallback('remote', function(data, cb)
    local fname = table.remove(data, 1) -- Shift

    local res = { pcall(remote[fname], table.unpack(data)) }
    cb(res)
end)