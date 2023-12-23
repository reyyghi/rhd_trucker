local target = exports.ox_target
local Busy = false
local Working = false

local Delivery = {
    vehicle = nil,
    coords = nil,
    radius = nil,
    salary = 0,
    blip = nil,
    box = 0
}

local Shops = {
    box = 0
}

local bn = 0
local tl = 0
local tc = {}
local ji = nil

local CarryBox = require "client.carrybox"

local function ReqModel (model)
    local timeout = 5000
    model = type('model') == 'string' and joaat(model) or model
    if not HasModelLoaded(model) and timeout > 0 then
        while not HasModelLoaded(model) do
            RequestModel(model)
            timeout -= 10
            Citizen.Wait(10)
        end
    end
end

local function DrawText3D(coords, text, size, font)
    local vector = type(coords) == "vector3" and coords or vec(coords.x, coords.y, coords.z)
    local camCoords = GetFinalRenderedCamCoord()
    local distance = #(vector - camCoords)

    if not size then
        size = 1
    end
    if not font then
        font = 0
    end

    local scale = (size / distance) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    scale = scale * fov

    SetTextScale(0.0, 0.55 * scale)
    SetTextFont(font)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    BeginTextCommandDisplayText('STRING')
    SetTextCentre(true)
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(vector.xyz, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

local setupBlip = function (coords)

    if DoesBlipExist(Delivery.blip) then
        RemoveBlip(Delivery.blip)
        ClearAllBlipRoutes()
        Delivery.blip = nil
        if not coords then return end
    end

    Delivery.blip = AddBlipForCoord(Delivery.coords.x, Delivery.coords.y, Delivery.coords.z)
    SetBlipColour(Delivery.blip, 60)
    SetBlipRoute(Delivery.blip, true)
    SetBlipRouteColour(Delivery.blip, 60)
end

local function setupLocation (data, fl)

    if data and data.locations then
        tc = data.locations
        tl = #data.locations


        if data.totalbox then
            if data.totalbox < tl then
                data.totalbox = (tl*2)
            end
        end

        Delivery.box = data.totalbox / tl
    end

    if next(tc) and Delivery.box > 0 then
        Delivery.coords = tc[#tc].coords
        Delivery.radius = tc[#tc].radius
        table.remove(tc, #tc)

        bn = Delivery.box

        if fl then
            lib.notify({
                description = 'Follow the GPS so you don\'t get the wrong destination',
                type = 'inform',
                position = 'center-right',
                duration = 8000
            })
        else
            lib.notify({
                description = 'go to the next location',
                type = 'inform',
                position = 'center-right',
                duration = 8000
            })
        end
    else
        Delivery.coords = nil
        Delivery.radius = nil

        lib.notify({
            description = 'Your work is finished, now go back to the warehouse to ask for your salary',
            type = 'success',
            position = 'center-right',
            duration = 10000
        })
    end

    setupBlip(Delivery.coords)
end

local function StartWork (self)
    local data = self.deliveryData
    local locdata = self.locationdata
    
    if data.locations and next(data.locations) then
        ReqModel(data.vehicle)
        Delivery.vehicle = CreateVehicle(data.vehicle, locdata.vehiclespawn.x, locdata.vehiclespawn.y, locdata.vehiclespawn.z, locdata.vehiclespawn.w, true, true)
        SetVehicleHasBeenOwnedByPlayer(Delivery.vehicle, true)
        SetVehicleFixed(Delivery.vehicle)
        SetVehicleNumberPlateText(Delivery.vehicle, ("RHD %s"):format(math.random(100, 999)))
        TaskWarpPedIntoVehicle(cache.ped, Delivery.vehicle, -1)
        SetVehicleFuelLevel(Delivery.vehicle, 100.0)
        setupLocation(data, true)
        Working = true ji = self.index
    end
end

local function OpenMenu (self)
    local data = self.locationdata
    
    local deliveryMenu = {
        id = "delivery_menu",
        title = "Delivery Menu",
        options = {}
    }

    for k, v in pairs(Config.Delivery) do
        deliveryMenu.options[#deliveryMenu.options+1] = {
            title = v.label,
            description = ('total income $%s'):format(lib.math.groupdigits(v.totalsalary, '.')),
            onSelect = StartWork,
            args = {
                deliveryData = v,
                locationdata = data,
                index = k
            }
        }
    end

    lib.registerContext(deliveryMenu)
    lib.showContext("delivery_menu")
end

local function TakeBox ()
    if lib.progressBar({
        duration = 5000,
        label = 'Take A Box Of Products..',
        useWhileDead = false,
        canCancel = true,
        anim = {
            dict = "anim@gangops@facility@servers@",
            clip = "hotwire",
            flag = 16,
        },
        disable = {
           move = true,
           car = true
        },
    }) then
        CarryBox.start()
        Busy = true
        StopAnimTask(cache.ped, "anim@gangops@facility@servers@", "hotwire", 1.0)
    else
        Busy = false
        StopAnimTask(cache.ped, "anim@gangops@facility@servers@", "hotwire", 1.0)
    end
end

local function DeliveryBox ()
    CarryBox.stop()
    TaskStartScenarioInPlace(cache.ped, "PROP_HUMAN_BUM_BIN", 0, true)
    if lib.progressBar({
        duration = 5000,
        label = 'Deliver Box Of Products',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true
        },
    }) then
        Busy = false
        bn -= 1 Shops.box += 1

        ClearPedTasks(cache.ped)
        if bn < 1 then
            setupLocation()
            return
        end

        lib.notify({
            description = ('managed to put the box, there are still %s boxes left'):format(math.floor(bn)),
            type = 'inform'
        })
    else
        CarryBox.start()
        ClearPedTasks(cache.ped)
    end
end

local function Looping ()
    local Sleep = 1000

    if not Working then return Sleep end
    if not Delivery.coords then return Sleep end
    if not Delivery.radius then return Sleep end
    if not DoesEntityExist(Delivery.vehicle) then return Sleep end

    if bn < 1 then return
        Sleep
    end

    local trunkCoords = GetOffsetFromEntityInWorldCoords(Delivery.vehicle, 0, -2.5, 0)
    local myCoords = GetEntityCoords(cache.ped)
    local shopsDistance = #(myCoords - Delivery.coords)
    local trunkDistance = #(myCoords - trunkCoords)

    if shopsDistance < Delivery.radius then
        DrawMarker(2, Delivery.coords, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.2, 0.15, 200, 0, 0, 222, false, false, false, true, false, false, false)

        if trunkDistance < 2.0 then
            DrawText3D(vec3(trunkCoords.x, trunkCoords.y, trunkCoords.z + 1), "[~g~E~s~] Take Box", 0.8)
        end
        
        if IsControlJustPressed(0, 38) then
            if trunkDistance < 2.0 and not Busy then
                TakeBox()
            elseif shopsDistance < 2.0 and Busy then
                DeliveryBox()
            end
        end
        Sleep = 10
    end
    return Sleep
end

CreateThread(function ()
    while not LocalPlayer.state.isLoggedIn do
        Citizen.Wait(100)
    end

    for k,v in pairs(Config.Location) do
        ReqModel(v.ped)
        local ped = CreatePed(0, v.ped, v.pedcoords.xyz, false, false)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)

        local expedisiBlip = AddBlipForCoord(v.pedcoords.xyz)
        SetBlipSprite(expedisiBlip, 479)
        SetBlipDisplay(expedisiBlip, 4)
        SetBlipScale(expedisiBlip, 0.6)
        SetBlipAsShortRange(expedisiBlip, true)
        SetBlipColour(expedisiBlip, 5)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName("Expedisi Cargo")
        EndTextCommandSetBlipName(expedisiBlip)

        target:addLocalEntity(ped, {
            {
                label = "deliver goods",
                icon = "fas fa-box",
                onSelect = OpenMenu,
                distance = 1.5,
                locationdata = v,
                canInteract = function ()
                    return not Working
                end
            },
            {
                label = "ask for salary",
                icon = "fas fa-hand-holding-dollar",
                onSelect = function ()
                    local totalbox = Config.Delivery[ji].totalbox
                    local totalsalary = Config.Delivery[ji].totalsalary

                    if DoesEntityExist(Delivery.vehicle) then
                        DeleteVehicle(Delivery.vehicle)
                    end
                    
                    if Shops.box >= totalbox then
                        TriggerServerEvent("rhd_expedisi:server:kasihguaduit", totalsalary)
                    else
                        lib.notify({
                            description = 'You will not get wages if there are still boxes left',
                            type = 'error',
                            duration = 8000,
                            position = 'center-right'
                        })
                    end

                    Working = false
                    Delivery.vehicle = nil
                    Shops.box = 0
                    bn = 0
                end,
                canInteract = function ()
                    return Working
                end
            }
        })
    end
end)

CreateThread(function ()
    while true do
        Citizen.Wait(Looping())
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if DoesEntityExist(Delivery.vehicle) then
            DeleteVehicle(Delivery.vehicle) 
        end
    end
end)