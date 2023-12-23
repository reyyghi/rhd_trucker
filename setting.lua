Config = {}

Config.Location = {
    {
        ped = "a_f_y_femaleagent", --- model ped nya
        pedcoords = vec(136.5396, -3112.1184, 4.8963, 8.3707), --- lokasi ped
        vehiclespawn = vec(141.4093, -3095.3662, 5.8963, 266.8303) --- lokasi spawn kendaraan
    }
}

Config.Delivery = {
    {
        label = "Expedisi 1", -- Label di context menu
        vehicle = "mule3", --- kode spawn kendaraan
        totalbox = 100, --- total box yang harus di kirim
        totalsalary = 40000, --- total pendapatan nya
        locations = { --- ini lokasi nya tinggal tambahin aja
            {
                coords = vec(-41.1676, -1748.1117, 29.5689), --- lokasi toko
                radius = 10.5 --- jarak interaksi nya
            },
            {
                coords = vec(31.1242, -1340.3440, 29.4970),
                radius = 15.5
            }
        }
    },
    {
        label = "Expedisi 2",
        vehicle = "mule3",
        totalbox = 200,
        totalsalary = 70000,
        locations = {
            {
                coords = vec(-41.1676, -1748.1117, 29.5689),
                radius = 10.5
            },
            {
                coords = vec(31.1242, -1340.3440, 29.4970),
                radius = 15.5
            }
        }
    }
}