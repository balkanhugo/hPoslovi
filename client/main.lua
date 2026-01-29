lib.locale()
local old = nil

-- IMPROVED GARAGE FUNCTION
-- Add this to client/main.lua or replace the existing ApriGarage function

function ApriGarage(data, job)
    for k,v in pairs(data) do
        if v.job == job then
            local elements = {}
            
            -- Check if there are vehicles configured
            if v.garage and v.garage.veicoli and #v.garage.veicoli > 0 then
                for idx, vehicle in ipairs(v.garage.veicoli) do
                    -- Only add actual vehicles, not the "add vehicle" button
                    if vehicle.args and vehicle.args.model then
                        table.insert(elements, {
                            label = vehicle.label,
                            icon = vehicle.icon or 'fa-car',
                            iconColor = vehicle.iconColor or Config.IconColor,
                            args = vehicle.args
                        })
                    end
                end
            end
            
            -- If no vehicles, show message
            if #elements == 0 then
                table.insert(elements, {
                    label = locale('vehiclenotavaible'),
                    args = { model = 'null' }
                })
            end
            
            lib.registerMenu({
                id = 'garage'..job,
                title = locale('garagetitle'),
                position = Config.MenuPosition,
                options = elements,
                onClose = function()
                    -- Hide text UI when menu closes
                    lib.hideTextUI()
                end
            }, function(selected, scrollIndex, args)
                if args and args.model and args.model ~= 'null' then
                    local PlayerData = ESX.GetPlayerData()
                    local gradoJob = tonumber(args.grado) or 0
                    
                    -- Check if player has required grade
                    if PlayerData.job.grade >= gradoJob then
                        -- Check if spawn point is clear
                        if v.garage.pos2 then
                            local spawnCoords = vector3(v.garage.pos2.x, v.garage.pos2.y, v.garage.pos2.z)
                            
                            if ESX.Game.IsSpawnPointClear(spawnCoords, 3.5) then
                                -- Request vehicle model
                                local modelHash = type(args.model) == 'string' and joaat(args.model) or args.model
                                
                                RequestModel(modelHash)
                                while not HasModelLoaded(modelHash) do
                                    Wait(10)
                                end
                                
                                -- Spawn vehicle
                                local vehicle = CreateVehicle(
                                    modelHash,
                                    spawnCoords.x,
                                    spawnCoords.y,
                                    spawnCoords.z,
                                    v.garage.heading or 0.0,
                                    true,
                                    false
                                )
                                
                                -- Wait for vehicle to exist
                                while not DoesEntityExist(vehicle) do
                                    Wait(10)
                                end
                                
                                -- Set vehicle properties
                                SetVehicleOnGroundProperly(vehicle)
                                SetEntityAsMissionEntity(vehicle, true, true)
                                SetVehicleHasBeenOwnedByPlayer(vehicle, true)
                                SetVehicleNeedsToBeHotwired(vehicle, false)
                                SetModelAsNoLongerNeeded(modelHash)
                                
                                -- Apply full kit if enabled
                                if args.fullkit then
                                    SetVehicleModKit(vehicle, 0)
                                    SetVehicleMod(vehicle, 11, 3, false) -- Engine
                                    SetVehicleMod(vehicle, 12, 2, false) -- Brakes
                                    SetVehicleMod(vehicle, 13, 2, false) -- Transmission
                                    SetVehicleMod(vehicle, 15, 3, false) -- Suspension
                                    ToggleVehicleMod(vehicle, 18, true) -- Turbo
                                    ToggleVehicleMod(vehicle, 22, true) -- Xenon headlights
                                end
                                
                                -- Set custom plate if provided
                                if args.targa and args.targa ~= "" then
                                    SetVehicleNumberPlateText(vehicle, args.targa)
                                end
                                
                                -- Set custom color if provided
                                if args.colore then
                                    local r = math.floor(args.colore.x or args.colore.r or 255)
                                    local g = math.floor(args.colore.y or args.colore.g or 255)
                                    local b = math.floor(args.colore.z or args.colore.b or 255)
                                    
                                    SetVehicleCustomPrimaryColour(vehicle, r, g, b)
                                    SetVehicleCustomSecondaryColour(vehicle, r, g, b)
                                end
                                
                                -- Put player in vehicle
                                TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
                                
                                Notify(locale('vehspawned') or 'Vehicle spawned successfully!')
                                lib.hideMenu()
                            else
                                Notify(locale('placeoccupat'))
                            end
                        else
                            Notify('Garage spawn position not configured!')
                        end
                    else
                        Notify(locale('gradobasso'))
                    end
                end
            end)
            
            lib.showMenu('garage'..job)
            break
        end
    end
end

-- IMPROVED VEHICLE MENU WITH BETTER VALIDATION
function MenuAddAuto()
    local vehicleList = {}
    
    -- Add existing vehicles to list
    for idx, veh in ipairs(datafaz.garage.veicoli) do
        if veh.args and veh.args.model then
            table.insert(vehicleList, {
                label = veh.label,
                icon = 'fa-car',
                iconColor = Config.IconColor,
                description = 'Model: ' .. veh.args.model .. ' | Grade: ' .. (veh.args.grado or 0),
                args = veh.args
            })
        end
    end
    
    -- Add "Add Vehicle" button at the end
    table.insert(vehicleList, {
        label = locale('addvehicle'),
        description = locale('addvehdesc'),
        args = 'ins',
        icon = 'fa-plus',
        iconColor = Config.IconColor
    })
    
    lib.registerMenu({
        id = 'some_menu_id4',
        title = locale('garagemenu'),
        position = Config.MenuPosition,
        options = vehicleList,
        onClose = function(keyPressed)
            MenuGarageg()
        end,
    }, function(selected, scrollIndex, args)
        if args == 'ins' then
            local input = lib.inputDialog('VEHICLE SETTINGS', {
                {type = 'input', label = locale('label'), placeholder = 'Police Car', required = true},
                {type = 'input', label = locale('modelmaiusc'), placeholder = 'police', required = true},
                {type = 'color', label = locale('color'), format = 'rgb', default = '#FFFFFF'},
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
            
            -- Parse color
            local color = lib.math.torgba(input[3])
            
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
                        r = color.x,
                        g = color.y,
                        b = color.z
                    }
                }
            })
            
            Notify('Vehicle added successfully!')
            MenuAddAuto()
        else
            -- Delete vehicle
            local alert = lib.alertDialog({
                header = locale('deleteveh'),
                content = locale('deleteveh2'),
                centered = false,
                cancel = true
            })
            
            if alert == 'confirm' then
                table.remove(datafaz.garage.veicoli, selected)
                Notify(locale('confirmremove'))
            else
                Notify(locale('deleteveh3'))
            end
            
            MenuAddAuto()
        end
    end)
    
    lib.showMenu('some_menu_id4')
end

function ApriMenu(label,job, modifica, selezionata)
    datafaz = {}
    datafaz.job = job
    datafaz.label = label
    datafaz.bossmenu = {}
    datafaz.garage = {
        veicoli = {}
    }
    datafaz.inv = {}
    datafaz.gradi = {}
    
    opt = {
        {label = locale('bossmenu'), description = locale('bossmenudesc'), icon = 'fa-user-tie', iconColor = Config.IconColor},
        {label = locale('inv'), description = locale('inv2'), icon = 'fa-cart-flatbed', iconColor = Config.IconColor},
        {label = locale('camerino'), description = locale('descamerino'), icon = 'fa-shirt', iconColor = Config.IconColor},
        {label = locale('garage'), description = locale('garage2'), icon = 'fa-warehouse', iconColor = Config.IconColor},
        {label = locale('gradi'), description = locale('gradi2'), icon = 'fa-crown', iconColor = Config.IconColor},
        {label = locale("blip"), description = locale('blip2'), icon = 'fa-ellipsis-vertical', iconColor = Config.IconColor},
        {label = locale('conferma'), description = locale('conferma2'), icon = 'fa-solid fa-circle-check', iconColor = Config.IconColor},
    }
    print(modifica)
    if modifica then 
        print(json.decode(LoadResourceFile(GetCurrentResourceName(), 'config/data.json')))
        for k,v in pairs(json.decode(LoadResourceFile(GetCurrentResourceName(), 'config/data.json'))) do 
            if v.job == job then 
                datafaz = v
            end
        end
        table.insert(opt, {label = locale('deletejob'), description = locale('deletejob2')})
    end

    lib.registerMenu({
        id = 'menufaz'..job,
        title = locale('fazione')..label,
        position = Config.MenuPosition,
        options = opt
    }, function(selected, scrollIndex, args)
        if selected == 1 then 
            
            local i = lib.inputDialog(locale('dialogboss1'), { locale('dialogboss2')})
            if not i then return end
            if not tonumber(i[1]) then Notify(locale('requirednumber')) lib.showMenu('menufaz'..job) return end
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
            lib.showMenu('menufaz'..job)
        elseif selected == 2 then 
            MenuGarage()
        elseif selected == 3 then 
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
            lib.showMenu('menufaz'..job)
        elseif selected == 4 then
            MenuGarageg()
        elseif selected == 5 then 
            MenuGradi()
        elseif selected == 7 then
            table.remove(datafaz.gradi, #datafaz.gradi)
            table.remove(datafaz.inv, #datafaz.inv)
            table.remove(datafaz.garage.veicoli, #datafaz.garage.veicoli)
            
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
        elseif selected == 8 then
            
            TriggerServerEvent('eliminafaz', datafaz, selezionata)
        end
    end)
    lib.showMenu('menufaz'..job)
end

RegisterNetEvent('modificafaz', function(data)
    ListaFazs(data)
end)

ListaFazs = function(data)
    elementi = {}
    for k,v in pairs(data) do 
        table.insert(elementi, {label = v.label, args = {label = v.label, job = v.job}})
    end
    lib.registerMenu({
        id = 'lista',
        title = locale('titleeditjob'),
        position = Config.MenuPosition,
        options = elementi
    }, function(selected, scrollIndex, args)
        ApriMenu(args.label, args.job, true, selected)  
    end)
    lib.showMenu('lista')
end

RegisterNetEvent('creafazione', function()
    local input = lib.inputDialog(locale('nomefaz'), {locale('nomefaz2'), locale('nomefaz3')})

    if not input then return end
    ApriMenu(input[1], input[2], false, false)
end)

-- INV

function MenuGarage()
    table.insert(datafaz.inv, {label = locale('agginv'), icon = 'fa-plus', iconColor = Config.IconColor, description = locale('invdesc'), args = 'ins'})

    local nextIndex = #datafaz.inv + 1
    
    lib.registerMenu({
        id = 'some_menu_id2',
        title = locale('invtitle'),
        position = Config.MenuPosition,
        options = datafaz.inv,
        onClose = function(keyPressed)
            lib.showMenu('menufaz'..datafaz.job)
        end,
    }, function(selected, scrollIndex, args)
        if args == 'ins' then 
            local input = lib.inputDialog(locale('impostazionidep'), {locale('nomedep'), locale('pesodep'), locale('slots'), locale('gradomin')})
        
            if not input then return end
            if tonumber(input[2]) and tonumber(input[3]) and tonumber(input[4]) then 
                
                
                table.remove(datafaz.inv, #datafaz.inv)
                table.insert(datafaz.inv, {
                    pos = GetEntityCoords(PlayerPedId()),
                    nomedeposito = input[1],
                    peso = input[2] * 1000,
                    slots = input[3],
                    grado = input[4],
                    label = input[1], 
                    icon = 'fa-solid fa-box', 
                    iconColor = Config.IconColor
                })
                MenuGarage()
            else
                Notify(locale('compile'))
                table.remove(datafaz.inv, #datafaz.inv)
                MenuGarage()
            end
        else
            local alert = lib.alertDialog({
                header = locale('deleteinv'),
                content = locale('deleteinv2'),
                centered = false,
                cancel = true
            })
            if alert == 'confirm' then
                table.remove(datafaz.inv, selected)
                table.remove(datafaz.inv, #datafaz.inv)
                Notify(locale('confirmremove'))
                MenuGarage()
            else
                Notify(locale('mantenutolist'))
            end
        end
    end)
    lib.showMenu('some_menu_id2')
end

-- GARAGE 

function MenuGarageg()
    lib.registerMenu({
        id = 'some_menu_id3',
        title = locale('garagemenu'),
        position = Config.MenuPosition,
        options = {
            {label = locale('garagemenuritir'), icon = 'fa-map-pin', iconColor = Config.IconColor},
            {label = locale('garagemenuspawn'), icon = 'fa-map-pin', iconColor = Config.IconColor},
            {label = locale('garagemenulist'), icon = 'fa-list', iconColor = Config.IconColor},
        },
        onClose = function(keyPressed)
            lib.showMenu('menufaz'..datafaz.job)
        end,
    }, function(selected, scrollIndex, args)
        if selected == 1 then 
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
        elseif selected == 2 then
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
        elseif selected == 3 then
            MenuAddAuto()
        elseif selected == 4 then
            lib.showMenu('menufaz'..datafaz.job)
        end
    end)
    
    lib.showMenu('some_menu_id3')
end


MenuGradi = function()
    table.insert(datafaz.gradi, {label = locale('addgrade'), description = locale('gradedesc'), args = 'ins', icon = 'fa-plus', iconColor = Config.IconColor})
    lib.registerMenu({
        id = 'gradi',
        title = 'Gradi',
        position = Config.MenuPosition,
        onClose = function(keyPressed)
            lib.showMenu('menufaz'..datafaz.job)
        end,
        options = datafaz.gradi,
    }, function(selected, scrollIndex, args)
        if args == 'ins' then 
            local i = lib.inputDialog(locale('putname'), {locale('namegrade'), locale('labelgrade'), locale('salary')})
            if i and tonumber(i[3]) then
                table.remove(datafaz.gradi, #datafaz.gradi)
                table.insert(datafaz.gradi, {grade = #datafaz.gradi, name = string.lower(i[1]), label = i[2], salary = tonumber(i[3]), icon = 'fa-user', iconColor = Config.IconColor})
            else
                Notify(locale('compile'))
                MenuGradi()
            end
        else
            local alert = lib.alertDialog({
                header = locale('deletegrade'),
                content = locale('gradeconfirm'),
                centered = false,
                cancel = true
            })
            if alert == 'confirm' then
                table.remove(datafaz.gradi, selected)
                table.remove(datafaz.gradi, #datafaz.gradi)
                Notify(locale('confirmremove'))
            else
                Notify(locale('tenggrado'))
            end
        end
        Wait(300)
        MenuGradi()
    end)
    lib.showMenu('gradi')
end


RegisterNetEvent('creafaz-cl', function(data)
    CreaMark(data)
end)


RegisterNetEvent('eliminafaz-cl', function(data)
    TriggerEvent('ox_gridsystem:unregisterMarker', 'bossmenu'..data.job)
    TriggerEvent('ox_gridsystem:unregisterMarker', 'camerino'..data.job)
    TriggerEvent('ox_gridsystem:unregisterMarker', 'garage1'..data.job)
    TriggerEvent('ox_gridsystem:unregisterMarker', 'garage2'..data.job)
    print(data.inv)
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
                    lib.hideMenu()
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
                    lib.hideMenu()
                end
            })
        end
    end
end
