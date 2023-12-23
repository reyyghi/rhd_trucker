local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('rhd_expedisi:server:kasihguaduit', function(amount)
    if GetInvokingResource() then return print(("Hayooo ngapain %s"):format(GetPlayerName(source))) end
    if exports.ox_inventory:AddItem(source, "money", amount) then
        lib.notify(source, {
            description = ('You receive a salary of $%s from sending goods'):format(amount),
            type = 'success',
            duration = 10000,
            position = 'center-right'
        })
    end
end)

RegisterNetEvent('rhd_expedisi:server:kasihjaminancoy', function(amount)
    if GetInvokingResource() then return print(("Hayooo ngapain %s"):format(GetPlayerName(source))) end
    local player = QBCore.Functions.GetPlayer(source)
    player.Functions.RemoveMoney("bank", amount, "work truck guarantee")
end)