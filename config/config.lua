Config = {}

-- ===========================================
-- DEBUG & LOCALE SETTINGS
-- ===========================================
Config.Debug = false -- Set to true to enable debug console logs
Config.Locale = 'hr' -- Available: 'en', 'hr'

-- ===========================================
-- MENU SETTINGS
-- ===========================================
Config.IconColor = '#00ADED'
Config.MenuPosition = 'top-right'

-- ===========================================
-- MARKER SETTINGS
-- ===========================================
Config.MarkerType = 21 -- Set to -1 for custom markers
Config.MarkerDrawDistance = 3
Config.InteractDistance = 2
Config.MarkerSize = vector3(0.8, 0.8, 0.8)
Config.MarkerColor = { r = 255, g = 255, b = 255 }

-- Custom marker textures (if MarkerType = -1)
Config.MarkerYTD = false -- Texture dictionary name

-- Marker texture overrides (set to false to disable, or texture name to use custom)
Config.InventoryMarker = false
Config.WardRobeMarker = false
Config.BossMenuMarker = false
Config.Vehicle1Marker = false
Config.Vehicle2Marker = false

-- ===========================================
-- JOB SYSTEM SETTINGS
-- ===========================================

-- Default grades if not configured
Config.IfNotGrades =  {
    { grade = 0, name = 'pocetnik', label = 'Pocetnik', salary = '0' },
    { grade = 1, name = 'diler', label = 'Diler', salary = '0' },
    { grade = 2, name = 'desna_ruka', label = 'Desna Ruka', salary = '0' },
    { grade = 3, name = 'zamjenik', label = 'Zamjenik Bossa', salary = '0' },
    { grade = 4, name = 'boss', label = 'Boss', salary = '0' },
}

-- Commands
Config.CreateCommand = 'makejob'
Config.EditCommand = 'editjob'

-- Auto-set job to creator when making a job
Config.AutoSetJob = true

-- Admin groups that can use job creation/editing
Config.AdminGroups = {
    'jaankeza',
    'developer'
}

-- ===========================================
-- INTEGRATION SETTINGS
-- ===========================================

-- Wardrobe System: Only 'illenium-appearance' supported
Config.WardrobeSystem = 'illenium-appearance'

-- Boss Menu System: Only 'esx_society' supported
Config.BossMenuSystem = 'esx_society'

-- ===========================================
-- FUNCTIONS
-- ===========================================

-- Wardrobe Function (illenium-appearance only)
YourWardRobeFunc = function(job)
    exports['illenium-appearance']:openWardrobe()
end

-- Boss Menu Function (esx_society only)
YourBossmenuFunc = function(job)
    TriggerEvent('esx_society:openBossMenu', job, function(data, menu)
        menu.close()
    end, {
        wash = false
    })
end

-- Text UI Function
FunzioneTextUI = function(msg)
    lib.showTextUI('[E] - '..msg, {
        position = 'right-center',
        icon = 'circle',
        style = {
            borderRadius = 10,
            backgroundColor = 'rgba(0, 0, 0, 0.5)',
            color = '#ffffff',
        },
    })
end

-- Notification Function
Notify = function(msg)
    ESX.ShowNotification(msg)
end

