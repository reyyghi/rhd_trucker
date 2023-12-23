local Carry = {}
local Looping = false
local ObjectCreated = nil

function Carry.start ()
    Looping = true

    RequestAnimDict('anim@heists@box_carry@')
    while not HasAnimDictLoaded('anim@heists@box_carry@') do Wait(0) end
    TaskPlayAnim(cache.ped, 'anim@heists@box_carry@', 'idle', 5.0, -1, -1, 50, 0, false, false, false)

    local boxObject = "hei_prop_heist_box"
    local pos = GetEntityCoords(cache.ped, true)
    RequestModel(boxObject)
    while not HasModelLoaded(boxObject) do Wait(0) end
    local object = CreateObject(boxObject, pos.x, pos.y, pos.z, true, true, true)
    AttachEntityToEntity(object, cache.ped, GetPedBoneIndex(cache.ped, 57005), 0.1, 0.1, -0.25, 300.0, 250.0, 15.0, true, true, false, true, 1, true)

    ObjectCreated = object

    CreateThread(function ()
        while Looping do
            SetPlayerSprint(cache.PlayerId, false)
            DisableControlAction(0, 21, true)
            DisableControlAction(0, 22, true)
            if not IsEntityPlayingAnim(PlayerPedId(), 'anim@heists@box_carry@', 'idle', 3) then
                TaskPlayAnim(PlayerPedId(), 'anim@heists@box_carry@', 'idle', 8.0, 8.0, -1, 50, 0, false, false, false)
            end
            Wait(10)
        end
    end)
end

function Carry.stop ()
    Looping = false
    if DoesEntityExist(ObjectCreated) then
        DetachEntity(ObjectCreated, true, true)
        DeleteObject(ObjectCreated)
    end
    StopAnimTask(cache.ped, 'anim@heists@box_carry@', 'idle', 1.0)
end

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then  
        if DoesEntityExist(ObjectCreated) then
            DetachEntity(ObjectCreated, true, true)
            DeleteObject(ObjectCreated)
        end
    end
end)

return Carry