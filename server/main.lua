local jsn = LoadResourceFile(GetCurrentResourceName(), 'config/data.json')
local dcd = json.decode(jsn)

-- Store job outfits
local jobOutfits = {}

CreateThread(function()
    for k,v in pairs(dcd) do 
        for a,b in pairs(v.inv) do 
            exports.ox_inventory:RegisterStash(v.job..a,b.nomedeposito, tonumber(b.slots), b.peso, false)
        end
        -- Initialize outfit storage for each job
        jobOutfits[v.job] = {}
    end
end)

-- Save outfit for job (boss only)
RegisterNetEvent('hPoslovi:server:saveJobOutfit', function(jobName, outfitName, outfitData)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    -- Check if player has the job
    if xPlayer.job.name ~= jobName then
        xPlayer.showNotification('You are not part of this job!')
        return
    end
    
    -- Get boss grade from job data
    local bossGrade = nil
    for k,v in pairs(dcd) do
        if v.job == jobName and v.bossmenu and v.bossmenu.gradoboss then
            bossGrade = tonumber(v.bossmenu.gradoboss)
            break
        end
    end
    
    -- Check if player has sufficient grade (higher or equal to boss grade)
    if not bossGrade or xPlayer.job.grade < bossGrade then
        xPlayer.showNotification('You need to be at least grade ' .. (bossGrade or 0) .. ' to save outfits!')
        return
    end
    
    -- Initialize if needed
    if not jobOutfits[jobName] then
        jobOutfits[jobName] = {}
    end
    
    -- Save outfit
    jobOutfits[jobName][outfitName] = outfitData
    
    xPlayer.showNotification('Outfit "' .. outfitName .. '" saved successfully!')
end)

-- Get available outfits for job
lib.callback.register('hPoslovi:server:getJobOutfits', function(source, jobName)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return {} end
    
    -- Check if player has the job
    if xPlayer.job.name ~= jobName then
        return {}
    end
    
    return jobOutfits[jobName] or {}
end)

-- Delete outfit for job (boss only)
RegisterNetEvent('hPoslovi:server:deleteJobOutfit', function(jobName, outfitName)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    -- Check if player has the job
    if xPlayer.job.name ~= jobName then
        xPlayer.showNotification('You are not part of this job!')
        return
    end
    
    -- Get boss grade from job data
    local bossGrade = nil
    for k,v in pairs(dcd) do
        if v.job == jobName and v.bossmenu and v.bossmenu.gradoboss then
            bossGrade = tonumber(v.bossmenu.gradoboss)
            break
        end
    end
    
    -- Check if player has sufficient grade
    if not bossGrade or xPlayer.job.grade < bossGrade then
        xPlayer.showNotification('You need to be at least grade ' .. (bossGrade or 0) .. ' to delete outfits!')
        return
    end
    
    if jobOutfits[jobName] and jobOutfits[jobName][outfitName] then
        jobOutfits[jobName][outfitName] = nil
        xPlayer.showNotification('Outfit "' .. outfitName .. '" deleted successfully!')
    end
end)

RegisterNetEvent('creafaz', function(data, modifica)
    local xPlayer = ESX.GetPlayerFromId(source)
    if CheckPerms(source) then 
        if modifica then
            MySQL.Async.execute('DELETE FROM jobs WHERE name = @job', { ['@job'] = data.job })
            MySQL.Async.execute('DELETE FROM job_grades WHERE job_name = @job', { ['@job'] = data.job })
            for c,grado in pairs(data.gradi) do 
                MySQL.insert('INSERT IGNORE INTO jobs (name, label) VALUES (?, ?)', { data.job, data.label })
                MySQL.prepare('INSERT INTO job_grades (job_name, grade, name, label, salary) VALUES (?, ?, ?, ?, ?)', {data.job, grado.grade, grado.name, grado.label, grado.salary})
            end
            Wait(500)
            ESX.RefreshJobs()
            if Config.AutoSetJob then
                xPlayer.setJob(data.job, 0)
            end
            table.remove(dcd, old)
            table.insert(dcd, data)
            SaveResourceFile(GetCurrentResourceName(), "config/data.json", json.encode(dcd, { indent = true }), -1)
            TriggerClientEvent('creafaz-cl', -1, dcd)
            for k,v in pairs(data) do 
                for a,b in pairs(data.inv) do 
                    exports.ox_inventory:RegisterStash(data.job..a,b.nomedeposito, tonumber(b.slots), b.peso, false)
                end
            end
            -- Initialize outfit storage
            if not jobOutfits[data.job] then
                jobOutfits[data.job] = {}
            end
        else
            for c,grado in pairs(data.gradi) do 
                MySQL.insert('INSERT IGNORE INTO jobs (name, label) VALUES (?, ?)', { data.job, data.label })
                MySQL.prepare('INSERT INTO job_grades (job_name, grade, name, label, salary) VALUES (?, ?, ?, ?, ?)', {data.job, grado.grade, grado.name, grado.label, grado.salary})
            end
            Wait(500)
            ESX.RefreshJobs()
            if Config.AutoSetJob then
                xPlayer.setJob(data.job, 0)
            end
            table.insert(dcd, data)
            SaveResourceFile(GetCurrentResourceName(), "config/data.json", json.encode(dcd, { indent = true }), -1)
            TriggerClientEvent('creafaz-cl', -1, dcd)
            for k,v in pairs(data) do 
                for a,b in pairs(data.inv) do 
                    exports.ox_inventory:RegisterStash(data.job..a,b.nomedeposito, tonumber(b.slots), b.peso, false)
                end
            end
            -- Initialize outfit storage
            if not jobOutfits[data.job] then
                jobOutfits[data.job] = {}
            end
        end
    end

end)

RegisterNetEvent('eliminafaz', function(data, selezionata)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.group ~= 'user' then 
        MySQL.Async.execute('DELETE FROM jobs WHERE name = @job', { ['@job'] = data.job })
        MySQL.Async.execute('DELETE FROM job_grades WHERE job_name = @job', { ['@job'] = data.job })
        TriggerClientEvent('eliminafaz-cl', -1, data)
        Wait(500)
        table.remove(dcd, selezionata)
        SaveResourceFile(GetCurrentResourceName(), "config/data.json", json.encode(dcd, { indent = true }), -1)
        ESX.RefreshJobs()
        -- Clear outfit storage
        jobOutfits[data.job] = nil
    end
end)

RegisterCommand(Config.EditCommand, function(source)
    if CheckPerms(source) then
        local jsn = LoadResourceFile(GetCurrentResourceName(), 'config/data.json')
        local dcd = json.decode(jsn)
        TriggerClientEvent("modificafaz", source, dcd)
    end
end)

RegisterCommand(Config.CreateCommand, function(source)
    if CheckPerms(source) then
        TriggerClientEvent("creafazione", source)
    end
end)

CheckPerms = function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    for k,v in pairs(Config.AdminGroups) do 
        if v == xPlayer.getGroup() then 
            return true
        end
    end
    xPlayer.showNotification(locale('noperms'))
    return false
end
