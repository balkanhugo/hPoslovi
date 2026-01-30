lib.locale()

-- Helper function for debug logging
local function DebugLog(message)
    if Config.Debug then
        print('[hPoslovi DEBUG] ' .. message)
    end
end

local old = nil
local datafaz = {} -- Defined locally to avoid global scope issues
local isModifying = false -- Track if we're modifying an existing job

-- HELPER: Hex to RGB Converter
local function HexToRGB(hex)
    hex = hex:gsub("#", "")
    return {
        r = tonumber("0x"..hex:sub(1,2)) or 255,
        g = tonumber("0x"..hex:sub(3,4)) or 255,
        b = tonumber("0x"..hex:sub(5,6)) or 255
    }
end

-- HELPER: Check Permissions
local function CanAccessGroup(myGrade, requiredGrade)
    if not requiredGrade then return true end
    return myGrade >= (tonumber(requiredGrade) or 0)
end

-- WARDROBE FUNCTION - REDESIGNED WITH ILLENIUM APPEARANCE
YourWardRobeFunc = function(job)
    local PlayerData = ESX.GetPlayerData()
    
    -- Get boss grade for this job from database via callback
    lib.callback('hPoslovi:server:getBossGrade', false, function(bossGrade)
        local canManageOutfits = bossGrade and PlayerData.job.grade >= bossGrade
        
        -- Get outfits
        lib.callback('hPoslovi:server:getJobOutfits', false, function(outfits)
            BuildWardrobeMenu(job, outfits, canManageOutfits)
        end, job)
    end, job)
end

function BuildWardrobeMenu(job, outfits, canManageOutfits)
    local menuOptions = {}
    
    -- Button 1: Open Ped Menu (illenium-appearance) - AVAILABLE TO EVERYONE
    table.insert(menuOptions, {
        label = 'Open Outfit Menu',
        description = 'Create and customize your appearance',
        icon = 'user-pen',
        iconColor = '#3B82F6',
    })
    
    -- Button 2: Save Current Outfit (only for sboss grade or higher)
    if canManageOutfits then
        table.insert(menuOptions, {
            label = 'Save Current Outfit',
            description = 'Save your current appearance as a job outfit',
            icon = 'floppy-disk',
            iconColor = '#10B981',
        })
    end
        
        -- Buttons 3+: Available Outfits - AVAILABLE TO EVERYONE
        local outfitList = {}
        for outfitName, outfitData in pairs(outfits) do
            table.insert(outfitList, {name = outfitName, data = outfitData})
        end
        
        -- Sort outfits alphabetically for consistent display
        table.sort(outfitList, function(a, b) return a.name < b.name end)
        
        for _, outfit in ipairs(outfitList) do
            table.insert(menuOptions, {
                label = outfit.name,
                description = 'Click to wear this outfit',
                icon = 'shirt',
                iconColor = Config.IconColor or '#6366F1',
                args = {outfitName = outfit.name, outfitData = outfit.data}
            })
        end
        
        -- Add delete option at the end if user has permissions and outfits exist
        if canManageOutfits and next(outfits) then
            table.insert(menuOptions, {
                label = 'Delete Outfit',
                description = 'Remove a saved outfit',
                icon = 'trash',
                iconColor = '#EF4444',
            })
        end
        
        lib.registerMenu({
            id = 'wardrobe_menu_' .. job,
            title = 'Wardrobe - ' .. job,
            position = Config.MenuPosition or 'top-right',
            options = menuOptions
        }, function(selected, scrollIndex, args)
            local option = menuOptions[selected]
            if not option then return end
            
            -- Button 1: Open Ped Menu
            if option.label == 'Open Outfit Menu' then
                lib.hideMenu(true)
                TriggerEvent('illenium-appearance:client:openOutfitMenu')
                
            -- Button 2: Save Current Outfit
            elseif option.label == 'Save Current Outfit' then
                local input = lib.inputDialog('Save Outfit', {
                    {type = 'input', label = 'Outfit Name', description = 'Enter a name for this outfit', required = true, min = 3, max = 50}
                })
                if input and input[1] then
                    local appearance = exports['illenium-appearance']:getPedAppearance(PlayerPedId())
                    if appearance then
                        TriggerServerEvent('hPoslovi:server:saveJobOutfit', job, input[1], appearance)
                        lib.notify({
                            title = 'Wardrobe',
                            description = 'Outfit "' .. input[1] .. '" saved!',
                            type = 'success'
                        })
                        Wait(500)
                        YourWardRobeFunc(job)
                    else
                        lib.notify({
                            title = 'Wardrobe',
                            description = 'Failed to get appearance data',
                            type = 'error'
                        })
                    end
                end
                
            -- Delete Outfit option
            elseif option.label == 'Delete Outfit' then
                local deleteOptions = {}
                for outfitName in pairs(outfits) do
                    table.insert(deleteOptions, {
                        label = outfitName,
                        icon = 'trash',
                        iconColor = '#EF4444',
                    })
                end
                
                -- Sort delete options alphabetically
                table.sort(deleteOptions, function(a, b) return a.label < b.label end)
                
                lib.registerMenu({
                    id = 'delete_outfit_menu',
                    title = 'Delete Outfit',
                    position = Config.MenuPosition or 'top-right',
                    options = deleteOptions,
                    onClose = function()
                        YourWardRobeFunc(job)
                    end
                }, function(deleteSelected, scrollIndex2, args2)
                    local outfitToDelete = deleteOptions[deleteSelected].label
                    local confirm = lib.alertDialog({
                        header = 'Delete Outfit',
                        content = 'Are you sure you want to delete "' .. outfitToDelete .. '"?',
                        centered = true,
                        cancel = true
                    })
                    if confirm == 'confirm' then
                        TriggerServerEvent('hPoslovi:server:deleteJobOutfit', job, outfitToDelete)
                        lib.notify({
                            title = 'Wardrobe',
                            description = 'Outfit deleted',
                            type = 'info'
                        })
                        Wait(500)
                        YourWardRobeFunc(job)
                    end
                end)
                lib.showMenu('delete_outfit_menu')
                
            -- Buttons 3+: Load saved outfit
            elseif args and args.outfitData then
                exports['illenium-appearance']:setPlayerAppearance(args.outfitData)
                lib.notify({
                    title = 'Wardrobe',
                    description = 'Outfit "' .. args.outfitName .. '" applied',
                    type = 'success'
                })
                lib.hideMenu(true)
            end
        end)
        lib.showMenu('wardrobe_menu_' .. job)
end

-- =======================================================
-- COMPLETELY REWRITTEN GARAGE SYSTEM
-- =======================================================

-- GARAGE FUNCTION (Player Usage) - DATABASE VERSION
function ApriGarage(data, job)
    local jobData = nil
    for k,v in pairs(data) do
        if v.job == job then 
            jobData = v 
            break 
        end
    end

    if not jobData then 
        Notify('Job data not found!')
        return 
    end

    -- Ensure garage structure exists
    if not jobData.garage then
        Notify('Garage not configured for this job!')
        return
    end

    -- Load vehicles from database
    lib.callback('hPoslovi:server:getJobVehicles', false, function(vehicles)
        local elements = {}
        
        -- List Vehicles from database
        if vehicles and #vehicles > 0 then
            for idx, vehicle in ipairs(vehicles) do
                local gradeText = vehicle.min_grade and ("Min Grade: "..vehicle.min_grade) or "No Grade Required"
                table.insert(elements, {
                    label = vehicle.label,
                    description = vehicle.model .. " | " .. gradeText,
                    icon = 'car',
                    iconColor = Config.IconColor,
                    args = {
                        vehicleData = vehicle,
                        garageData = jobData.garage
                    }
                })
            end
        else
            table.insert(elements, {
                label = locale('vehiclenotavaible'),
                icon = 'circle-xmark',
                disabled = true
            })
        end

        lib.registerMenu({
            id = 'garage_menu_'..job,
            title = locale('garagetitle'),
            position = Config.MenuPosition or 'top-right',
            options = elements
        }, function(selected, scrollIndex, args)
            local option = elements[selected]
            if option and option.args then
                SpawnJobVehicle(option.args.vehicleData, option.args.garageData)
            end
        end)
        lib.showMenu('garage_menu_'..job)
    end, job)
end

-- SPAWN VEHICLE FUNCTION - DATABASE VERSION
function SpawnJobVehicle(vehicleData, garageData)
    local PlayerData = ESX.GetPlayerData()
    
    -- Support both old format (args) and new database format
    local args = vehicleData.args or vehicleData
    local gradoJob = tonumber(args.grado or args.min_grade) or 0
    
    -- Grade Check
    if PlayerData.job.grade < gradoJob then
        Notify(locale('gradobasso'))
        return
    end

    -- Validate spawn point
    if not garageData.pos2 then 
        Notify('Garage Spawn Point Not Set!') 
        return 
    end

    local spawnCoords = vector3(garageData.pos2.x, garageData.pos2.y, garageData.pos2.z)
    local heading = garageData.heading or 0.0

    -- Check if spawn point is clear
    if not ESX.Game.IsSpawnPointClear(spawnCoords, 3.0) then
        Notify(locale('placeoccupat'))
        return
    end

    -- Model validation
    local model = args.model or vehicleData.model
    local modelHash = type(model) == 'string' and joaat(model) or model
    
    if not IsModelInCdimage(modelHash) then 
        Notify('Invalid Model: ' .. tostring(model)) 
        return 
    end

    if not IsModelAVehicle(modelHash) then
        Notify('Model is not a vehicle: ' .. tostring(model))
        return
    end

    -- Load model
    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 5000 do 
        Wait(10) 
        timeout = timeout + 10
    end

    if not HasModelLoaded(modelHash) then
        Notify('Failed to load vehicle model')
        return
    end

    -- Create vehicle
    local vehicle = CreateVehicle(modelHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, heading, true, false)
    
    if not DoesEntityExist(vehicle) then
        Notify('Failed to create vehicle')
        SetModelAsNoLongerNeeded(modelHash)
        return
    end

    -- Wait for vehicle to be fully created
    local vehicleTimeout = 0
    while not DoesEntityExist(vehicle) and vehicleTimeout < 2000 do
        Wait(10)
        vehicleTimeout = vehicleTimeout + 10
    end

    -- Essential Network & Entity setup
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    SetVehicleNeedsToBeHotwired(vehicle, false)
    SetVehRadioStation(vehicle, 'OFF')
    
    -- Handle Color (Supports database format color_r/g/b and old colore format)
    if vehicleData.color_r and vehicleData.color_g and vehicleData.color_b then
        -- Database format
        SetVehicleCustomPrimaryColour(vehicle, vehicleData.color_r, vehicleData.color_g, vehicleData.color_b)
        SetVehicleCustomSecondaryColour(vehicle, vehicleData.color_r, vehicleData.color_g, vehicleData.color_b)
    elseif args.colore then
        -- Old format
        local r = args.colore.r or args.colore.x or 255
        local g = args.colore.g or args.colore.y or 255
        local b = args.colore.b or args.colore.z or 255
        SetVehicleCustomPrimaryColour(vehicle, r, g, b)
        SetVehicleCustomSecondaryColour(vehicle, r, g, b)
    end

    -- Handle Plate (supports both formats)
    local plate = vehicleData.plate or args.targa
    if plate and plate ~= "" then
        SetVehicleNumberPlateText(vehicle, tostring(plate))
    end

    -- Handle Mods (supports both formats)
    local fullkit = vehicleData.fullkit == 1 or args.fullkit
    if fullkit then
        SetVehicleModKit(vehicle, 0)
        SetVehicleMod(vehicle, 11, 3, false) -- Engine
        SetVehicleMod(vehicle, 12, 2, false) -- Brakes
        SetVehicleMod(vehicle, 13, 2, false) -- Transmission
        SetVehicleMod(vehicle, 15, 3, false) -- Suspension
        ToggleVehicleMod(vehicle, 18, true) -- Turbo
        ToggleVehicleMod(vehicle, 22, true) -- Xenon
    end

    -- Clean up model
    SetModelAsNoLongerNeeded(modelHash)

    -- Put player in vehicle
    TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
    Notify(locale('vehspawned'))
    lib.hideMenu(true)
end

-- =======================================================
-- ADMIN / JOB CREATION MENUS
-- =======================================================

function ApriMenu(label, job, modifica, selezionata)
    -- Set global modification state
    isModifying = modifica
    
    -- If modifying, load existing data from server
    if modifica then 
        print('[hPoslovi] Loading job data from database: ' .. job)
        lib.callback('hPoslovi:server:getAllJobs', false, function(data)
            for k,v in pairs(data) do 
                if v.job == job then 
                    datafaz = v
                    old = k
                    -- Ensure garage structure exists
                    if not datafaz.garage then
                        datafaz.garage = { veicoli = {} }
                    end
                    print('[hPoslovi] Loaded job data for: ' .. job)
                    
                    -- Now open the menu
                    OpenJobEditMenu(label, job, modifica)
                    break
                end
            end
        end)
    else
        -- Creating new job - initialize datafaz
        datafaz = {
            job = job,
            label = label,
            bossmenu = {},
            garage = {},
            inv = {},
            gradi = {}
        }
        
        -- Open menu immediately for new jobs
        OpenJobEditMenu(label, job, modifica)
    end
end

function OpenJobEditMenu(label, job, modifica)

    local opt = {
        {label = locale('bossmenu'), description = locale('bossmenudesc'), icon = 'user-tie', iconColor = Config.IconColor},
        {label = locale('inv'), description = locale('inv2'), icon = 'cart-flatbed', iconColor = Config.IconColor},
        {label = locale('camerino'), description = locale('descamerino'), icon = 'shirt', iconColor = Config.IconColor},
        {label = locale('garage'), description = locale('garage2'), icon = 'warehouse', iconColor = Config.IconColor},
        {label = locale('gradi'), description = locale('gradi2'), icon = 'crown', iconColor = Config.IconColor},
        {label = locale('conferma'), description = locale('conferma2'), icon = 'circle-check', iconColor = '#00FF00'},
    }
    
    if modifica then
        table.insert(opt, {
            label = locale('deletejob'), 
            description = locale('deletejob2'), 
            icon = 'trash', 
            iconColor = '#FF0000',
        })
    end

    lib.registerMenu({
        id = 'menufaz_'..job,
        title = locale('fazione').." "..label,
        position = Config.MenuPosition or 'top-right',
        options = opt
    }, function(selected, scrollIndex, args)
        if selected == 1 then
            -- Boss Menu
            local i = lib.inputDialog(locale('dialogboss1'), { locale('dialogboss2')})
            if not i then return end
            if not tonumber(i[1]) then Notify(locale('requirednumber')) return end
            
            datafaz.bossmenu.gradoboss = tonumber(i[1])
            
            if lib.alertDialog({header = locale('confirmpos'), content = locale('confirmpos2'), centered = true, cancel = true}) == 'confirm' then
                datafaz.bossmenu.pos = GetEntityCoords(PlayerPedId())
                Notify(locale('cofirmnotif'))
            end
            OpenJobEditMenu(label, job, modifica)  -- Reopen menu
        elseif selected == 2 then
            -- Inventory
            MenuInv()
        elseif selected == 3 then
            -- Wardrobe
            if lib.alertDialog({header = locale('confirmpos'), content = locale('confirmpos2'), centered = true, cancel = true}) == 'confirm' then
                datafaz.camerino = GetEntityCoords(PlayerPedId())
                Notify(locale('cofirmnotif'))
            end
            OpenJobEditMenu(label, job, modifica)  -- Reopen menu
        elseif selected == 4 then
            -- Garage
            MenuGarageSettings()
        elseif selected == 5 then
            -- Grades
            MenuGradi()
        elseif selected == 6 then
            -- Confirm
            if #datafaz.gradi == 0 then 
                Notify(locale('notgradesnot'))
                datafaz.gradi = Config.IfNotGrades
            end
            
            print('[hPoslovi] Sending job data to server: ' .. datafaz.job .. ' (isModifying: ' .. tostring(isModifying) .. ')')
            TriggerServerEvent('hPoslovi:server:createOrUpdateJob', datafaz, isModifying)
            datafaz = {}
            isModifying = false
            old = nil
            lib.hideMenu(true)
        elseif selected == 7 and modifica then
            -- Delete Job
            TriggerServerEvent('hPoslovi:server:deleteJob', datafaz.job)
            datafaz = {}
            isModifying = false
            old = nil
            lib.hideMenu(true)
        end
    end)
    lib.showMenu('menufaz_'..job)
end

-- INVENTORY SETTINGS
function MenuInv()
    local elements = {}
    
    -- Add existing
    for i, inv in ipairs(datafaz.inv) do
        table.insert(elements, {
            label = inv.label,
            description = "Slots: "..inv.slots.." | Grade: "..inv.grado,
            icon = 'box',
            args = {index = i}
        })
    end

    -- Add New Button
    table.insert(elements, {
        label = locale('agginv'),
        icon = 'plus',
    })

    lib.registerMenu({
        id = 'menu_inv',
        title = locale('invtitle'),
        position = Config.MenuPosition or 'top-right',
        options = elements,
        onClose = function()
            OpenJobEditMenu(datafaz.label, datafaz.job, isModifying)
        end
    }, function(selected, scrollIndex, args)
        local option = elements[selected]
        if option.args and option.args.index then
            -- Delete inventory
            if lib.alertDialog({header = locale('deleteinv'), content = locale('deleteinv2'), centered = true, cancel = true}) == 'confirm' then
                table.remove(datafaz.inv, option.args.index)
                Notify(locale('confirmremove'))
                MenuInv()
            end
        elseif option.label == locale('agginv') then
            -- Add new inventory
            local input = lib.inputDialog(locale('impostazionidep'), {
                {type = 'input', label = locale('nomedep'), required = true}, 
                {type = 'number', label = locale('pesodep'), required = true}, 
                {type = 'number', label = locale('slots'), required = true}, 
                {type = 'number', label = locale('gradomin'), required = true}
            })
            
            if input then
                table.insert(datafaz.inv, {
                    pos = GetEntityCoords(PlayerPedId()),
                    nomedeposito = input[1],
                    peso = input[2] * 1000,
                    slots = input[3],
                    grado = input[4],
                    label = input[1], 
                })
                MenuInv()
            end
        end
    end)
    lib.showMenu('menu_inv')
end

-- GARAGE SETTINGS MENU - IMPROVED
function MenuGarageSettings()
    lib.registerMenu({
        id = 'menu_garage_settings',
        title = locale('garagemenu'),
        position = Config.MenuPosition or 'top-right',
        options = {
            {
                label = locale('garagemenuritir'), 
                icon = 'map-pin', 
            },
            {
                label = locale('garagemenuspawn'), 
                icon = 'car-side', 
            },
            {
                label = locale('garagemenulist'), 
                icon = 'list', 
                description = 'Manage Vehicles',
            },
        },
        onClose = function()
            OpenJobEditMenu(datafaz.label, datafaz.job, isModifying)
        end
    }, function(selected, scrollIndex, args)
        if selected == 1 then
            -- Set pickup location
            if lib.alertDialog({header = locale('confirmpos'), content = locale('confirmpos2'), centered = true, cancel = true}) == 'confirm' then
                if not datafaz.garage then datafaz.garage = {} end
                datafaz.garage.pos1 = GetEntityCoords(PlayerPedId())
                Notify(locale('cofirmnotif'))
            end
            MenuGarageSettings()
        elseif selected == 2 then
            -- Set spawn location
            if lib.alertDialog({header = locale('confirmpos'), content = locale('confirmpos2'), centered = true, cancel = true}) == 'confirm' then
                if not datafaz.garage then datafaz.garage = {} end
                datafaz.garage.pos2 = GetEntityCoords(PlayerPedId())
                datafaz.garage.heading = GetEntityHeading(PlayerPedId())
                Notify(locale('cofirmnotif'))
            end
            MenuGarageSettings()
        elseif selected == 3 then
            -- Vehicle list
            MenuAddAuto()
        end
    end)
    lib.showMenu('menu_garage_settings')
end

-- VEHICLE LIST (EDIT MODE) - DATABASE VERSION
function MenuAddAuto()
    -- Load vehicles from database
    lib.callback('hPoslovi:server:getJobVehicles', false, function(vehicles)
        local elements = {}

        -- Existing Vehicles from database
        if vehicles and #vehicles > 0 then
            for i, veh in ipairs(vehicles) do
                table.insert(elements, {
                    label = veh.label,
                    description = veh.model .. " | Grade: " .. (veh.min_grade or 0),
                    icon = 'car',
                    args = {id = veh.id, index = i}
                })
            end
        end

        -- Add New Vehicle
        table.insert(elements, {
            label = locale('addvehicle'),
            description = locale('addvehdesc'),
            icon = 'plus',
        })

        lib.registerMenu({
            id = 'menu_veh_list',
            title = 'Garage Vehicles',
            position = Config.MenuPosition or 'top-right',
            options = elements,
            onClose = function()
                MenuGarageSettings()
            end
        }, function(selected, scrollIndex, args)
            local option = elements[selected]
            
            if option.args and option.args.id then
                -- Delete vehicle
                if lib.alertDialog({header = locale('deleteveh'), content = locale('deleteveh2'), centered = true, cancel = true}) == 'confirm' then
                    TriggerServerEvent('hPoslovi:server:deleteVehicle', option.args.id, datafaz.job)
                    Wait(300)
                    MenuAddAuto() -- Refresh menu
                end
            elseif option.label == locale('addvehicle') then
                -- Add new vehicle
                local input = lib.inputDialog('VEHICLE SETTINGS', {
                    {type = 'input', label = locale('label'), required = true},
                    {type = 'input', label = locale('modelmaiusc'), required = true},
                    {type = 'color', label = locale('color'), default = "#FFFFFF"},
                    {type = 'checkbox', label = locale('fullkit')},
                    {type = 'input', label = locale('plate')},
                    {type = 'number', label = locale('gradomin'), default = 0}
                })
                
                if input then
                    -- Validate model name
                    local modelName = string.upper(input[2])
                    
                    -- Color Conversion
                    local rgbColor = HexToRGB(input[3])

                    local newVehicle = {
                        label = input[1],
                        model = modelName,
                        fullkit = input[4],
                        plate = input[5],
                        min_grade = input[6],
                        color_r = rgbColor.r,
                        color_g = rgbColor.g,
                        color_b = rgbColor.b
                    }
                    
                    TriggerServerEvent('hPoslovi:server:addVehicle', datafaz.job, newVehicle)
                    Wait(300)
                    MenuAddAuto() -- Refresh menu
                end
            end
        end)
        lib.showMenu('menu_veh_list')
    end, datafaz.job)
end

-- GRADES MENU
function MenuGradi()
    local elements = {}
    
    for i, grade in ipairs(datafaz.gradi) do
        table.insert(elements, {
            label = grade.label,
            description = "Salary: $"..grade.salary,
            icon = 'user',
            args = {index = i}
        })
    end

    table.insert(elements, {
        label = locale('addgrade'),
        icon = 'plus',
    })

    lib.registerMenu({
        id = 'menu_gradi',
        title = 'Grades Management',
        position = Config.MenuPosition or 'top-right',
        options = elements,
        onClose = function()
            OpenJobEditMenu(datafaz.label, datafaz.job, isModifying)
        end
    }, function(selected, scrollIndex, args)
        local option = elements[selected]
        
        if option.args and option.args.index then
            -- Delete grade
            if lib.alertDialog({header = locale('deletegrade'), content = locale('gradeconfirm'), centered = true, cancel = true}) == 'confirm' then
                table.remove(datafaz.gradi, option.args.index)
                Notify(locale('confirmremove'))
                MenuGradi()
            end
        elseif option.label == locale('addgrade') then
            -- Add new grade
            local i = lib.inputDialog(locale('putname'), {
                {type = 'input', label = locale('namegrade'), required = true}, 
                {type = 'input', label = locale('labelgrade'), required = true}, 
                {type = 'number', label = locale('salary'), required = true}
            })
            if i then
                table.insert(datafaz.gradi, {
                    grade = #datafaz.gradi, 
                    name = string.lower(i[1]), 
                    label = i[2], 
                    salary = tonumber(i[3]), 
                })
                MenuGradi()
            end
        end
    end)
    lib.showMenu('menu_gradi')
end

-- EVENTS
RegisterNetEvent('hPoslovi:client:openEditMenu', function()
    lib.callback('hPoslovi:server:getAllJobs', false, function(data)
        if not data or #data == 0 then
            Notify('No jobs found in database!')
            return
        end
        
        local elements = {}
        for k,v in pairs(data) do 
            table.insert(elements, {
                label = v.label, 
                description = v.job,
                args = {job = v.job, index = k}
            })
        end
        
        lib.registerMenu({
            id = 'list_jobs',
            title = locale('titleeditjob'),
            position = Config.MenuPosition or 'top-right',
            options = elements
        }, function(selected, scrollIndex, args)
            local option = elements[selected]
            if option.args then
                ApriMenu(option.label, option.args.job, true, option.args.index)
            end
        end)
        lib.showMenu('list_jobs')
    end)
end)

RegisterNetEvent('hPoslovi:client:openCreateMenu', function()
    local input = lib.inputDialog(locale('nomefaz'), {locale('nomefaz2'), locale('nomefaz3')})
    if input then
        ApriMenu(input[1], input[2], false, false)
    end
end)

RegisterNetEvent('hPoslovi:client:refreshJobs', function()
    DebugLog('Refreshing markers from database...')
    lib.callback('hPoslovi:server:getAllJobs', false, function(data)
        if data then
            CreaMark(data)
        end
    end)
end)

CreateThread(function()
    Wait(2000) -- Wait for server to load
    DebugLog('Loading markers from database...')
    lib.callback('hPoslovi:server:getAllJobs', false, function(data)
        if data then
            CreaMark(data)
        else
            DebugLog('No jobs found in database')
        end
    end)
end)

function CreaMark(data)
    if not data then 
        DebugLog('ERROR: CreaMark called with nil data')
        return 
    end
    
    DebugLog('Creating markers for ' .. #data .. ' jobs')
    
    for k,v in pairs(data) do
        DebugLog('Processing job: ' .. (v.job or 'unknown'))
        
        -- Unregister Old
        TriggerEvent('ox_gridsystem:unregisterMarker', 'bossmenu'..v.job)
        TriggerEvent('ox_gridsystem:unregisterMarker', 'camerino'..v.job)
        TriggerEvent('ox_gridsystem:unregisterMarker', 'garage1'..v.job)
        TriggerEvent('ox_gridsystem:unregisterMarker', 'garage2'..v.job)

        Wait(100) 

        -- Register New
        if v.bossmenu and v.bossmenu.pos then
            DebugLog('Registering boss menu marker for ' .. v.job)
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

        if v.inv then
            for a,b in pairs(v.inv) do
                if a and b.pos then
                    TriggerEvent('ox_gridsystem:unregisterMarker', 'inv'..a)
                    Wait(100)
                    DebugLog('Registering inventory marker ' .. a .. ' for ' .. v.job)
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
        end

        if v.camerino then
            DebugLog('Registering wardrobe marker for ' .. v.job)
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

        if v.garage and v.garage.pos1 then
            DebugLog('Registering garage markers for ' .. v.job)
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
                    lib.hideMenu(true)
                end
            })
            
            if v.garage.pos2 then
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
                        lib.hideMenu(true)
                    end
                })
            end
        end
    end
    
    DebugLog('Marker creation complete')
end
-- Refresh vehicle list when updated
RegisterNetEvent('hPoslovi:client:refreshVehicles', function(jobName)
    -- If the menu is open for this job, refresh it
    if datafaz and datafaz.job == jobName then
        Wait(100)
        -- Menu will auto-refresh when reopened
    end
end)