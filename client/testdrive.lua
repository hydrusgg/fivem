local test_location = { -888.8, -3212.37, 13.95, 58.0 }
local y_limit = -2370.87

function main.start_testdrive(spawn)
    DoScreenFadeOut(500)
    Wait(500)

    local x,y,z,h = table.unpack(test_location)

    local ped = PlayerPedId()
    SetEntityCoords(ped, x, y, z)

    RequestModel(spawn)
    while not HasModelLoaded(spawn) do
        Wait(50)
    end

    local vehicle = CreateVehicle(spawn, x, y, z, h, true)
    SetModelAsNoLongerNeeded(spawn)

    SetPedIntoVehicle(ped, vehicle, -1)

    DoScreenFadeIn(500)

    -- TriggerEvent('Notify', 'info', 'Leave the vehicle to leave the test drive')

    while IsPedInVehicle(ped, vehicle) and GetEntityCoords(ped).y < y_limit do
        Wait(400)
    end

    DoScreenFadeOut(500)
    Wait(500)

    DeleteEntity(vehicle)
    remote.exit_testdrive()

    DoScreenFadeIn(500)
end