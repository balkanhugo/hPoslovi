Config = {
    --  MENU  --
    IconColor = '#00ADED',
    MenuPosition = 'top-right',

    --  MARKERS  --
    MarkerType = 21, -- to active custom markers you have to put this -1
    MarkerDrawDistance = 3,
    InteractDistance = 2,
    MarkerSize = vector3(0.8, 0.8, 0.8),
    MarkerColor = { r = 255, g = 255, b = 255 },

    -- IF YOU WANT CUSTOM MARKERS 
    MarkerYTD = false, -- this is the texture dict

    InventoryMarker = false,  -- if you don't want this put false
    WardRobeMarker = false, -- if you don't want this put false
    BossMenuMarker = false, -- if you don't want this put false
    Vehicle1Marker = false, -- if you don't want this put false
    Vehicle2Marker = false, -- if you don't want this put false

    --  IF YOU DON'T PUT GRADES IN THE MENU THIS WILL BE THE DEFAULT GRADES  --
    IfNotGrades = {
        { grade = 0, name = 'grade0', label = 'Role 0', salary = '100' },
        { grade = 1, name = 'grade1', label = 'Role 1', salary = '250' },
        { grade = 2, name = 'viceboss', label = 'Vice Boss', salary = '500' },
        { grade = 3, name = 'boss', label = 'Boss', salary = '750' },
    },
    
    CreateCommand = 'makejob',
    EditCommand = 'editjob',
    AutoSetJobs = true, -- put this false if you don't want to set you the job you created

    AdminGroups = {
        'jaankeza',
        'developer'
    },

    -- WARDROBE CONFIGURATION
    -- Choose your wardrobe system: 'esx_skin', 'illenium-appearance', 'fivem-appearance', or 'custom'
    WardrobeSystem = 'illenium-appearance',

    -- BOSS MENU CONFIGURATION  
    -- Choose your boss menu system: 'esx_society', 'qb-management', or 'custom'
    BossMenuSystem = 'esx_society',
}

-- WARDROBE FUNCTION
YourWardRobeFunc = function(job)
    if Config.WardrobeSystem == 'esx_skin' then
        -- ESX Skin / Skinchanger
        TriggerEvent('esx_skin:openSaveableMenu')
        
    elseif Config.WardrobeSystem == 'illenium-appearance' then
        -- Illenium Appearance
        exports['illenium-appearance']:openWardrobe()
        
    elseif Config.WardrobeSystem == 'fivem-appearance' then
        -- Fivem Appearance
        exports['fivem-appearance']:startPlayerCustomization(function(appearance)
            if appearance then
                TriggerServerEvent('fivem-appearance:save', appearance)
            end
        end)
        
    elseif Config.WardrobeSystem == 'custom' then
        -- ADD YOUR CUSTOM WARDROBE TRIGGER HERE
        -- Example: TriggerEvent('your_wardrobe:open', job)
        print('Custom wardrobe for job: ' .. job)
        
    else
        -- Default ESX wardrobe
        TriggerEvent('esx_skin:openSaveableMenu')
    end
end

-- BOSS MENU FUNCTION
YourBossmenuFunc = function(job)
    if Config.BossMenuSystem == 'esx_society' then
        -- ESX Society Boss Menu
        TriggerEvent('esx_society:openBossMenu', job, function(data, menu)
            menu.close()
        end, {
            wash = false -- Set to true if you want money washing option
        })
        
    elseif Config.BossMenuSystem == 'qb-management' then
        -- QB Management (if you're using QB core compatible)
        TriggerEvent('qb-bossmenu:client:OpenMenu')
        
    elseif Config.BossMenuSystem == 'custom' then
        -- ADD YOUR CUSTOM BOSS MENU TRIGGER HERE
        -- Example: TriggerEvent('your_bossmenu:open', job)
        print('Custom boss menu for job: ' .. job)
        
    else
        -- Default fallback - opens a basic menu
        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'boss_actions', {
            title = 'Boss Menu - ' .. job,
            align = 'top-left',
            elements = {
                {label = 'Employee Management', value = 'employee_management'},
                {label = 'Society Money', value = 'society_money'},
            }
        }, function(data, menu)
            if data.current.value == 'employee_management' then
                -- Add your employee management code
                ESX.ShowNotification('Employee management - Add your code here')
            elseif data.current.value == 'society_money' then
                -- Add your society money code
                ESX.ShowNotification('Society money - Add your code here')
            end
        end, function(data, menu)
            menu.close()
        end)
    end
end

-- TEXT UI FUNCTION
FunzioneTextUI = function(msg)
    lib.showTextUI('[E] - '..msg, {
        position = 'right-center',
        icon = icona,
        style = {
            borderRadius = 10,
            backgroundColor = 'rgba(0, 0, 0, 0.5)',
            color = '#ffffff',
        },
    })
end

-- NOTIFICATION FUNCTION
Notify = function(msg)
    ESX.ShowNotification(msg)
end
