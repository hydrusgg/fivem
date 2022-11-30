-- Blips that open the store when the player press E
local blips = {
    vector(148.71, -1031.4, 29.35)
}

-- DrawMarker layout
local r,g,b,alpha = 22, 163, 74, 100
local iconMarker = 29
local circleMarker = 27

local function renderBlip(vec)
    local active = true

    CreateThread(function()
        while active do
            DrawMarker(circleMarker,vec.x, vec.y, vec.z-0.95,0,0,0,0,180.0,130.0,1.0,1.0,1.0,r, g, b, alpha,0,0,0,1)
            DrawMarker(iconMarker,vec.x, vec.y, vec.z+0.20,0,0,0,0,360.0,180.0,1.0,0.3,1.0,r, g, b, alpha,1,0,0,1)

            if IsControlJustPressed(0, 38) and #(GetEntityCoords(PlayerPedId()) - vec) <= 2 then
                local url = remote.get_url()
                SendNUIMessage({ 'open_iframe', 'https://'..url })
                SetNuiFocus(true, true)
            end

            Wait(0)
        end
    end)

    return function()
        active = false
    end
end

CreateThread(function()
    if #blips == 0 then
        return
    end

    local active = {}

    while true do
        local cds = GetEntityCoords(PlayerPedId())
        for key, vec in ipairs(blips) do
            local distance = #(cds - vec)
            if distance <= 10 and not active[key] then
                active[key] = renderBlip(vec)
            elseif distance > 10 and active[key] then
                active[key]()
                active[key] = nil
            end
        end
        Wait(1000)
    end
end)