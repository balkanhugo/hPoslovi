lib.locale()
local old = nil

-- IMPROVED GARAGE FUNCTION WITH PROPER VEHICLE SPAWNING
function ApriGarage(data, job)
    for k,v in pairs(data) do
        if v.job == job then
            local elements = {}
            
            -- Check if there are vehicles configured
            if v.garage and v.garage.veicoli and #v.garage.veicoli > 0 then
                for idx, vehicle in ipairs(v.garage.veicoli) do
                    -- Check if vehicle has args OR if it's stored directly with model
                    local vehicleData = vehicle.args or vehicle
                    
                    -- Only add actual vehicles, not temporary entries
                    if vehicleData and vehicleData.model and vehicleData.model ~= "" then
                        table.insert(elements, {
                            title = vehicle.label or vehicleData.label or vehicleData.model,
                            description = string.format('Model: %s | Min Grade: %s | %s', 
                                vehicleData.model, 
                                vehicleData.grado or 0,
                                vehicleData.fullkit and 'Full Kit' or 'Stock'
                            ),
                            icon = vehicle.icon or 'fa-car',
                            iconColor = vehicle.iconColor or Config.IconColor,
                            onSelect = function()
                                SpawnJobVehicle(v.garage, vehicleData)
                            end
                        })
                    end
                end
            end
            
            -- If no vehicles, show message
            if #elements == 0 then
                table.insert(elements, {
                    title = locale('vehiclenotavaible'),
                    description = 'No vehicles configured for this job',
                    icon = 'fa-exclamation-triangle',
                    iconColor = '#FF0000',
                    disabled = true
                })
            end
            
            lib.registerContext({
                id = 'garage_'..job,
                title = locale('garagetitle'),
                options = elements,
                canClose = true
            })
            
            lib.showContext('garage_'..job)
            break
        end
    end
end

-- VEHICLE SPAWNING FUNCTION
function SpawnJobVehicle(garageData, vehicleData)
    local PlayerData = ESX.GetPlayerData()
    local gradoJob = tonumber(vehicleData.grado) or 0
    
    -- Check if player has required grade
    if PlayerData.job.grade < gradoJob then
        Notify(locale('gradobasso'))
        return
    end
    
    -- Check if spawn point is configured
    if not garageData.pos2 then
        Notify('Garage spawn position not configured!')
        return
    end
    
    local spawnCoords = vector3(garageData.pos2.x, garageData.pos2.y, garageData.pos2.z)
    
    -- Check if spawn point is clear
    if not ESX.Game.IsSpawnPointClear(spawnCoords, 3.5) then
        Notify(locale('placeoccupat'))
        return
    end
    
    -- Request vehicle model
    local modelHash = type(vehicleData.model) == 'string' and joaat(vehicleData.model) or vehicleData.model
    
    if not IsModelInCdimage(modelHash) or not IsModelAVehicle(modelHash) then
        Notify('Invalid vehicle model: ' .. tostring(vehicleData.model))
        return
    end
    
    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 5000 do
        Wait(10)
        timeout = timeout + 10
    end
    
    if not HasModelLoaded(modelHash) then
        Notify('Failed to load vehicle model!')
        return
    end
    
    -- Spawn vehicle
    local vehicle = CreateVehicle(
        modelHash,
        spawnCoords.x,
        spawnCoords.y,
        spawnCoords.z,
        garageData.heading or 0.0,
        true,
        false
    )
    
    -- Wait for vehicle to exist
    timeout = 0
    while not DoesEntityExist(vehicle) and timeout < 3000 do
        Wait(10)
        timeout = timeout + 10
    end
    
    if not DoesEntityExist(vehicle) then
        Notify('Failed to spawn vehicle!')
        SetModelAsNoLongerNeeded(modelHash)
        return
    end
    
    -- Set vehicle properties
    SetVehicleOnGroundProperly(vehicle)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    SetVehicleNeedsToBeHotwired(vehicle, false)
    SetModelAsNoLongerNeeded(modelHash)
    
    -- Apply full kit if enabled
    if vehicleData.fullkit then
        SetVehicleModKit(vehicle, 0)
        SetVehicleMod(vehicle, 11, 3, false) -- Engine
        SetVehicleMod(vehicle, 12, 2, false) -- Brakes
        SetVehicleMod(vehicle, 13, 2, false) -- Transmission
        SetVehicleMod(vehicle, 15, 3, false) -- Suspension
        ToggleVehicleMod(vehicle, 18, true) -- Turbo
        ToggleVehicleMod(vehicle, 22, true) -- Xenon headlights
    end
    
    -- Set custom plate if provided
    if vehicleData.targa and vehicleData.targa ~= "" then
        SetVehicleNumberPlateText(vehicle, vehicleData.targa)
    end
    
    -- Set custom color if provided
    if vehicleData.colore then
        local r = math.floor(vehicleData.colore.r or 255)
        local g = math.floor(vehicleData.colore.g or 255)
        local b = math.floor(vehicleData.colore.b or 255)
        
        SetVehicleCustomPrimaryColour(vehicle, r, g, b)
        SetVehicleCustomSecondaryColour(vehicle, r, g, b)
    end
    
    -- Put player in vehicle
    TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
    
    Notify(locale('vehspawned') or 'Vehicle spawned successfully!')
    lib.hideContext()
end

-- IMPROVED VEHICLE MENU WITH BETTER VALIDATION
function MenuAddAuto()
    local vehicleList = {}
    
    -- Add existing vehicles to list
    for idx, veh in ipairs(datafaz.garage.veicoli) do
        local vehicleData = veh.args or veh
        if vehicleData and vehicleData.model and vehicleData.model ~= "" then
            table.insert(vehicleList, {
                title = veh.label or vehicleData.label or vehicleData.model,
                icon = 'fa-car',
                iconColor = Config.IconColor,
                description = string.format('Model: %s | Grade: %s | %s', 
                    vehicleData.model, 
                    vehicleData.grado or 0,
                    vehicleData.fullkit and 'Full Kit' or 'Stock'
                ),
                onSelect = function()
                    -- Show vehicle options (edit or delete)
                    lib.registerContext({
                        id = 'vehicle_options_'..idx,
                        title = veh.label or vehicleData.model,
                        menu = 'vehicle_menu',
                        canClose = true,
                        options = {
                            {
                                title = 'Delete Vehicle',
                                description = 'Remove this vehicle from the list',
                                icon = 'fa-trash',
                                iconColor = '#FF0000',
                                onSelect = function()
                                    local alert = lib.alertDialog({
                                        header = locale('deleteveh'),
                                        content = locale('deleteveh2'),
                                        centered = false,
                                        cancel = true
                                    })
                                    
                                    if alert == 'confirm' then
                                        table.remove(datafaz.garage.veicoli, idx)
                                        Notify(locale('confirmremove'))
                                        MenuAddAuto()
                                    else
                                        Notify(locale('deleteveh3'))
                                        MenuAddAuto()
                                    end
                                end
                            },
                            {
                                title = 'Test Spawn',
                                description = 'Spawn this vehicle to test it',
                                icon = 'fa-play',
                                iconColor = '#00FF00',
                                onSelect = function()
                                    if datafaz.garage.pos2 then
                                        SpawnJobVehicle(datafaz.garage, vehicleData)
                                    else
                                        Notify('Please set spawn position first!')
                                    end
                                end
                            }
                        }
                    })
                    lib.showContext('vehicle_options_'..idx)
                end
            })
        end
    end
    
    -- Add "Add Vehicle" button at the end
    table.insert(vehicleList, {
        title = locale('addvehicle'),
        description = locale('addvehdesc'),
        icon = 'fa-plus',
        iconColor = Config.IconColor,
        onSelect = function()
            local input = lib.inputDialog('VEHICLE SETTINGS', {
                {type = 'input', label = locale('label'), placeholder = 'Police Car', required = true},
                {type = 'input', label = locale('modelmaiusc'), placeholder = 'police', required = true},
                {type = 'color', label = locale('color'), default = '#FFFFFF'},
                {type = 'checkbox', label = locale('fullkit')},
                {type = 'input', label = locale('plate'), placeholder = 'POLICE', maxlength = 8},
                {type = 'number', label = locale('gradomin'), placeholder = '0', required = true, min = 0}
            })
            
            if not input then
                MenuAddAuto()
                return
            end
            
            -- Validate model exists
            local modelHash = joaat(input[2])
            if not IsModelInCdimage(modelHash) or not IsModelAVehicle(modelHash) then
                Notify('Invalid vehicle model: ' .. input[2])
                MenuAddAuto()
                return
            end
            
            -- Parse color from hex
            local colorHex = input[3] or '#FFFFFF'
            local r, g, b = 255, 255, 255
            
            if colorHex and type(colorHex) == 'string' then
                -- Remove # if present
                colorHex = colorHex:gsub('#', '')
                
                -- Convert hex to RGB
                if #colorHex == 6 then
                    r = tonumber(colorHex:sub(1,2), 16) or 255
                    g = tonumber(colorHex:sub(3,4), 16) or 255
                    b = tonumber(colorHex:sub(5,6), 16) or 255
                end
            end
            
            -- Add vehicle to list
            table.insert(datafaz.garage.veicoli, {
                label = input[1],
                icon = 'fa-car',
                iconColor = Config.IconColor,
                args = {
                    model = input[2],
                    fullkit = input[4],
                    targa = input[5] or '',
                    grado = tonumber(input[6]) or 0,
                    colore = {
                        r = r,
                        g = g,
                        b = b
                    }
                }
            })
            
            Notify('Vehicle added successfully!')
            MenuAddAuto()
        end
    })
    
    lib.registerContext({
        id = 'vehicle_menu',
        title = locale('garagemenu'),
        menu = 'garage_settings',
        canClose = true,
        options = vehicleList
    })
    
    lib.showContext('vehicle_menu')
end

function ApriMenu(label, job, modifica, selezionata)
    datafaz = {}
    datafaz.job = job
    datafaz.label = label
    datafaz.bossmenu = {}
    datafaz.garage = {
        veicoli = {}
    }
    datafaz.inv = {}
    datafaz.gradi = {}
    
    local opt = {
        {
            title = locale('bossmenu'),
            description = locale('bossmenudesc'),
            icon = 'fa-user-tie',
            iconColor = Config.IconColor,
            onSelect = function()
                local i = lib.inputDialog(locale('dialogboss1'), { locale('dialogboss2')})
                if not i then return end
                if not tonumber(i[1]) then 
                    Notify(locale('requirednumber'))
                    lib.showContext('menufaz'..job)
                    return 
                end
                datafaz.bossmenu.gradoboss = tonumber(i[1])
                
                local alert = lib.alertDialog({
                    header = locale('confirmpos'),
                    content = locale('confirmpos2'),
                    centered = true,
                    cancel = true
                })
                if alert == 'confirm' then
                    datafaz.bossmenu.pos = GetEntityCoords(PlayerPedId())
                    Notify(locale('cofirmnotif'))
                else
                    Notify(locale('cancelnotif'))
                end
                lib.showContext('menufaz'..job)
            end
        },
        {
            title = locale('inv'),
            description = locale('inv2'),
            icon = 'fa-cart-flatbed',
            iconColor = Config.IconColor,
            onSelect = function()
                MenuGarage()
            end
        },
        {
            title = locale('camerino'),
            description = locale('descamerino'),
            icon = 'fa-shirt',
            iconColor = Config.IconColor,
            onSelect = function()
                local alert = lib.alertDialog({
                    header = locale('confirmpos'),
                    content = locale('confirmpos2'),
                    centered = true,
                    cancel = true
                })
                if alert == 'confirm' then
                    datafaz.camerino = GetEntityCoords(PlayerPedId())
                    Notify(locale('cofirmnotif'))
                else
                    Notify(locale('cancelnotif'))
                end
                lib.showContext('menufaz'..job)
            end
        },
        {
            title = locale('garage'),
            description = locale('garage2'),
            icon = 'fa-warehouse',
            iconColor = Config.IconColor,
            onSelect = function()
                MenuGarageg()
            end
        },
        {
            title = locale('gradi'),
            description = locale('gradi2'),
            icon = 'fa-crown',
            iconColor = Config.IconColor,
            onSelect = function()
                MenuGradi()
            end
        },
        {
            title = locale('conferma'),
            description = locale('conferma2'),
            icon = 'fa-solid fa-circle-check',
            iconColor = Config.IconColor,
            onSelect = function()
                -- Clean up temporary entries
                for i = #datafaz.gradi, 1, -1 do
                    if datafaz.gradi[i].args == 'ins' then
                        table.remove(datafaz.gradi, i)
                    end
                end
                for i = #datafaz.inv, 1, -1 do
                    if datafaz.inv[i].args == 'ins' then
                        table.remove(datafaz.inv, i)
                    end
                end
                -- Clean up invalid vehicles
                for i = #datafaz.garage.veicoli, 1, -1 do
                    local veh = datafaz.garage.veicoli[i]
                    local vehData = veh.args or veh
                    if not vehData or not vehData.model or vehData.model == "" then
                        table.remove(datafaz.garage.veicoli, i)
                    end
                end
                
                if #datafaz.gradi == 0 then 
                    Notify(locale('notgradesnot'))
                    datafaz.gradi = Config.IfNotGrades
                end
                if modifica then
                    TriggerServerEvent('creafaz', datafaz, selezionata)
                    datafaz = nil
                else
                    TriggerServerEvent('creafaz', datafaz)
                    datafaz = nil
                end
            end
        }
    }
    
    if modifica then 
        for k,v in pairs(json.decode(LoadResourceFile(GetCurrentResourceName(), 'config/data.json'))) do 
            if v.job == job then 
                datafaz = v
            end
        end
        table.insert(opt, {
            title = locale('deletejob'),
            description = locale('deletejob2'),
            icon = 'fa-trash',
            iconColor = '#FF0000',
            onSelect = function()
                TriggerServerEvent('eliminafaz', datafaz, selezionata)
            end
        })
    end

    lib.registerContext({
        id = 'menufaz'..job,
        title = locale('fazione')..label,
        canClose = true,
        options = opt
    })
    
    lib.showContext('menufaz'..job)
end

RegisterNetEvent('modificafaz', function(data)
    ListaFazs(data)
end)

ListaFazs = function(data)
    local elementi = {}
    for k,v in pairs(data) do 
        table.insert(elementi, {
            title = v.label,
            description = 'Job: ' .. v.job,
            icon = 'fa-briefcase',
            iconColor = Config.IconColor,
            onSelect = function()
                ApriMenu(v.label, v.job, true, k)
            end
        })
    end
    
    lib.registerContext({
        id = 'lista',
        title = locale('titleeditjob'),
        canClose = true,
        options = elementi
    })
    
    lib.showContext('lista')
end

RegisterNetEvent('creafazione', function()
    local input = lib.inputDialog(locale('nomefaz'), {locale('nomefaz2'), locale('nomefaz3')})
    if not input then return end
    ApriMenu(input[1], input[2], false, false)
end)

-- INV
function MenuGarage()
    local invOptions = {}
    
    -- Add existing inventories
    for idx, inv in ipairs(datafaz.inv) do
        if inv.nomedeposito then -- Only add actual inventories
            table.insert(invOptions, {
                title = inv.label or inv.nomedeposito,
                icon = 'fa-solid fa-box',
                iconColor = Config.IconColor,
                description = string.format('Slots: %s | Weight: %skg | Grade: %s', inv.slots, inv.peso/1000, inv.grado),
                onSelect = function()
                    local alert = lib.alertDialog({
                        header = locale('deleteinv'),
                        content = locale('deleteinv2'),
                        centered = false,
                        cancel = true
                    })
                    if alert == 'confirm' then
                        table.remove(datafaz.inv, idx)
                        Notify(locale('confirmremove'))
                    else
                        Notify(locale('mantenutolist'))
                    end
                    MenuGarage()
                end
            })
        end
    end
    
    -- Add "Add Inventory" button
    table.insert(invOptions, {
        title = locale('agginv'),
        icon = 'fa-plus',
        iconColor = Config.IconColor,
        description = locale('invdesc'),
        onSelect = function()
            local input = lib.inputDialog(locale('impostazionidep'), {
                locale('nomedep'),
                locale('pesodep'),
                locale('slots'),
                locale('gradomin')
            })
        
            if not input then 
                MenuGarage()
                return 
            end
            
            if tonumber(input[2]) and tonumber(input[3]) and tonumber(input[4]) then 
                table.insert(datafaz.inv, {
                    pos = GetEntityCoords(PlayerPedId()),
                    nomedeposito = input[1],
                    peso = tonumber(input[2]) * 1000,
                    slots = input[3],
                    grado = input[4],
                    label = input[1], 
                    icon = 'fa-solid fa-box', 
                    iconColor = Config.IconColor
                })
                Notify('Inventory added successfully!')
            else
                Notify(locale('compile'))
            end
            MenuGarage()
        end
    })
    
    lib.registerContext({
        id = 'inv_menu',
        title = locale('invtitle'),
        menu = 'menufaz'..datafaz.job,
        canClose = true,
        options = invOptions
    })
    
    lib.showContext('inv_menu')
end

-- GARAGE 
function MenuGarageg()
    local garageOptions = {
        {
            title = locale('garagemenuritir'),
            icon = 'fa-map-pin',
            iconColor = Config.IconColor,
            description = datafaz.garage.pos1 and 'Position set' or 'Not configured',
            onSelect = function()
                local alert = lib.alertDialog({
                    header = locale('confirmpos'),
                    content = locale('confirmpos2'),
                    centered = true,
                    cancel = true
                })
                if alert == 'confirm' then
                    datafaz.garage.pos1 = GetEntityCoords(PlayerPedId())
                    Notify(locale('cofirmnotif'))
                else
                    Notify(locale('cancelnotif'))
                end
                MenuGarageg()
            end
        },
        {
            title = locale('garagemenuspawn'),
            icon = 'fa-map-pin',
            iconColor = Config.IconColor,
            description = datafaz.garage.pos2 and 'Position set' or 'Not configured',
            onSelect = function()
                local alert = lib.alertDialog({
                    header = locale('confirmpos'),
                    content = locale('confirmpos2'),
                    centered = true,
                    cancel = true
                })
                if alert == 'confirm' then
                    datafaz.garage.pos2 = GetEntityCoords(PlayerPedId())
                    datafaz.garage.heading = GetEntityHeading(PlayerPedId())
                    Notify(locale('cofirmnotif'))
                else
                    Notify(locale('cancelnotif'))
                end
                MenuGarageg()
            end
        },
        {
            title = locale('garagemenulist'),
            icon = 'fa-list',
            iconColor = Config.IconColor,
            description = string.format('%d vehicles configured', #datafaz.garage.veicoli),
            onSelect = function()
                MenuAddAuto()
            end
        }
    }
    
    lib.registerContext({
        id = 'garage_settings',
        title = locale('garagemenu'),
        menu = 'menufaz'..datafaz.job,
        canClose = true,
        options = garageOptions
    })
    
    lib.showContext('garage_settings')
end

MenuGradi = function()
    local gradeOptions = {}
    
    -- Add existing grades
    for idx, grade in ipairs(datafaz.gradi) do
        if grade.name then -- Only add actual grades
            table.insert(gradeOptions, {
                title = grade.label,
                icon = 'fa-user',
                iconColor = Config.IconColor,
                description = string.format('Name: %s | Salary: $%s', grade.name, grade.salary),
                onSelect = function()
                    local alert = lib.alertDialog({
                        header = locale('deletegrade'),
                        content = locale('gradeconfirm'),
                        centered = false,
                        cancel = true
                    })
                    if alert == 'confirm' then
                        table.remove(datafaz.gradi, idx)
                        Notify(locale('confirmremove'))
                    else
                        Notify(locale('tenggrado'))
                    end
                    Wait(300)
                    MenuGradi()
                end
            })
        end
    end
    
    -- Add "Add Grade" button
    table.insert(gradeOptions, {
        title = locale('addgrade'),
        description = locale('gradedesc'),
        icon = 'fa-plus',
        iconColor = Config.IconColor,
        onSelect = function()
            local i = lib.inputDialog(locale('putname'), {
                locale('namegrade'),
                locale('labelgrade'),
                locale('salary')
            })
            
            if i and tonumber(i[3]) then
                table.insert(datafaz.gradi, {
                    grade = #datafaz.gradi,
                    name = string.lower(i[1]),
                    label = i[2],
                    salary = tonumber(i[3]),
                    icon = 'fa-user',
                    iconColor = Config.IconColor
                })
                Notify('Grade added successfully!')
            else
                Notify(locale('compile'))
            end
            Wait(300)
            MenuGradi()
        end
    })
    
    lib.registerContext({
        id = 'gradi',
        title = 'Gradi',
        menu = 'menufaz'..datafaz.job,
        canClose = true,
        options = gradeOptions
    })
    
    lib.showContext('gradi')
end

RegisterNetEvent('creafaz-cl', function(data)
    CreaMark(data)
end)

RegisterNetEvent('eliminafaz-cl', function(data)
    TriggerEvent('ox_gridsystem:unregisterMarker', 'bossmenu'..data.job)
    TriggerEvent('ox_gridsystem:unregisterMarker', 'camerino'..data.job)
    TriggerEvent('ox_gridsystem:unregisterMarker', 'garage1'..data.job)
    TriggerEvent('ox_gridsystem:unregisterMarker', 'garage2'..data.job)
    for k,v in pairs(data.inv) do
        TriggerEvent('ox_gridsystem:unregisterMarker', 'inv'..k)
    end
end)

CreateThread(function()
    local jsn = LoadResourceFile(GetCurrentResourceName(), 'config/data.json')
    local dcd = json.decode(jsn)
    CreaMark(dcd)
end)

function CreaMark(data)
    for k,v in pairs(data) do
        TriggerEvent('ox_gridsystem:unregisterMarker', 'bossmenu'..v.job)
        TriggerEvent('ox_gridsystem:unregisterMarker', 'camerino'..v.job)
        TriggerEvent('ox_gridsystem:unregisterMarker', 'garage1'..v.job)
        TriggerEvent('ox_gridsystem:unregisterMarker', 'garage2'..v.job)
        Wait(500)
        if v.bossmenu.pos then
            TriggerEvent('ox_gridsystem:registerMarker', {
                name = 'bossmenu'..v.job,
                pos = vector3(v.bossmenu.pos.x, v.bossmenu.pos.y, v.bossmenu.pos.z),
                size = Config.MarkerSize,
                scale = Config.MarkerSize,
                type = Config.MarkerType,
                drawDistance = Config.MarkerDrawDistance,
                interactDistance = Config.InteractDistance,
                color = Config.MarkerColor,
                msg = locale('textuibossmenu'),
                permission = v.job,
                jobGrade = v.bossmenu.gradoboss,
                texture = Config.BossMenuMarker,  
                textureDict = Config.MarkerYTD,
                action = function()
                    YourBossmenuFunc(v.job)
                end
            })
        end
        for a,b in pairs(v.inv) do
            if a then
                TriggerEvent('ox_gridsystem:unregisterMarker', 'inv'..a)
                Wait(500)
                TriggerEvent('ox_gridsystem:registerMarker', {
                    name = 'inv'..a,
                    pos = vector3(b.pos.x, b.pos.y, b.pos.z),
                    size = Config.MarkerSize,
                    scale = Config.MarkerSize,
                    type = Config.MarkerType,
                    drawDistance = Config.MarkerDrawDistance,
                    interactDistance = Config.InteractDistance,
                    color = Config.MarkerColor,
                    msg = locale('textuideposito'),
                    permission = v.job,
                    jobGrade = tonumber(b.grado),
                    texture = Config.InventoryMarker,  
                    textureDict = Config.MarkerYTD,
                    action = function()
                        exports.ox_inventory:openInventory('stash', v.job..a)
                    end
                })
            end
        end
        if v.camerino then
            TriggerEvent('ox_gridsystem:registerMarker', {
                name = 'camerino'..v.job,
                pos = vector3(v.camerino.x, v.camerino.y, v.camerino.z),
                size = Config.MarkerSize,
                scale = Config.MarkerSize,
                type = Config.MarkerType,
                drawDistance = Config.MarkerDrawDistance,
                interactDistance = Config.InteractDistance,
                color = Config.MarkerColor,
                msg = locale('textuiwardrobe'),
                permission = v.job,
                jobGrade = 0,
                texture = Config.WardRobeMarker,  
                textureDict = Config.MarkerYTD,
                action = function()
                    YourWardRobeFunc(v.job)
                end
            })
        end
        if v.garage.pos1 then
            TriggerEvent('ox_gridsystem:registerMarker', {
                name = 'garage1'..v.job,
                pos = vector3(v.garage.pos1.x, v.garage.pos1.y, v.garage.pos1.z),
                size = Config.MarkerSize,
                scale = Config.MarkerSize,
                type = Config.MarkerType,
                drawDistance = Config.MarkerDrawDistance,
                interactDistance = Config.InteractDistance,
                color = Config.MarkerColor,
                msg = locale('texuigarage1'),
                permission = v.job,
                jobGrade = 0,
                texture = Config.Vehicle1Marker,  
                textureDict = Config.MarkerYTD,
                action = function()
                    ApriGarage(data, v.job)
                end,
                onExit = function()
                    lib.hideContext()
                end
            })
            TriggerEvent('ox_gridsystem:registerMarker', {
                name = 'garage2'..v.job,
                pos = vector3(v.garage.pos2.x, v.garage.pos2.y, v.garage.pos2.z),
                size = Config.MarkerSize,
                scale = Config.MarkerSize,
                type = Config.MarkerType,
                drawDistance = Config.MarkerDrawDistance,
                interactDistance = Config.InteractDistance,
                color = Config.MarkerColor,
                msg = locale('texuigarage2'),
                permission = v.job,
                jobGrade = 0,
                texture = Config.Vehicle2Marker,  
                textureDict = Config.MarkerYTD,
                action = function()
                    if IsPedInAnyVehicle(PlayerPedId()) then
                        ESX.Game.DeleteVehicle(GetVehiclePedIsIn(PlayerPedId()))
                        Notify(locale('vehdeposited'))
                    else
                        Notify(locale('notveh'))
                    end
                end,
                onExit = function()
                    lib.hideContext()
                end
            })
        end
    end
end
