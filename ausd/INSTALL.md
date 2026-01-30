# hPoslovi V1.0 - Quick Start Guide

## ✅ V1 Release Checklist - ALL COMPLETED

### What Was Fixed:

✅ **Wardrobe System** - Save outfits works for sboss grade+, ped menu available to all  
✅ **Boss Menu** - Visible to everyone >= boss grade  
✅ **Locales** - EN and HR redone and improved  
✅ **Code Cleanup** - Only ESX Society + Illenium Appearance  
✅ **Job Refresh** - ESX.RefreshJobs() called automatically  
✅ **Grade Preservation** - Ranks don't reset when editing jobs  
✅ **Marker Refresh** - Markers refresh after job edits  
✅ **Debug Logging** - Console logs only show when Config.Debug = true  
✅ **Config Cleanup** - Organized and simplified  

---

## 🚀 Quick Installation

1. **Upload Files**
   ```
   Place all files in: resources/[your-scripts]/hposlovi/
   ```

2. **Configure**
   Open `config/config.lua` and set:
   ```lua
   Config.Debug = false           -- Set to true for debugging
   Config.Locale = 'en'           -- or 'hr' for Croatian
   
   Config.AdminGroups = {
       'admin',
       'superadmin',
       'developer'
   }
   ```

3. **Add to server.cfg**
   ```
   ensure hposlovi
   ```

4. **Restart Server**

---

## 🌍 How to Change Language

### Step 1: Open Config
Open file: `config/config.lua`

### Step 2: Find Locale Line
Look for:
```lua
Config.Locale = 'en'
```

### Step 3: Change Value
- For English: `Config.Locale = 'en'`
- For Croatian: `Config.Locale = 'hr'`

### Step 4: Restart Resource
```
/restart hposlovi
```

**That's it!** The language will change immediately.

---

## 📋 Available Locales

| Code | Language | File |
|------|----------|------|
| `en` | English | `locales/en.json` |
| `hr` | Croatian (Hrvatski) | `locales/hr.json` |

---

## 🔧 Key Configuration Options

### Debug Mode
```lua
Config.Debug = false  -- Set to true to see detailed console logs
```

### Commands
```lua
Config.CreateCommand = 'makejob'  -- Create new job
Config.EditCommand = 'editjob'    -- Edit existing job
```

### Auto-Set Job
```lua
Config.AutoSetJob = true  -- Give creator the job when making it
```

---

## 🎯 What Changed from Previous Version

### Boss Menu Access
**Before:** Only exact boss grade could access  
**After:** Boss grade and HIGHER can access (>=)

### Wardrobe System
**Before:** Everyone could save outfits  
**After:** Only sboss grade+ can save/delete, everyone can use saved outfits

### Console Logs
**Before:** Always printing to console  
**After:** Only prints when Config.Debug = true

### Job Editing
**Before:** Grades reset to default every edit  
**After:** Grades preserved unless explicitly changed

### Markers
**Before:** Needed server restart to show  
**After:** Auto-refresh on all clients

---

## 📦 Dependencies

**Required:**
- es_extended (ESX)
- ox_lib
- oxmysql
- ox_inventory
- illenium-appearance
- esx_society
- ox_gridsystem

---

## 🎮 Commands

| Command | Permission | Description |
|---------|-----------|-------------|
| `/makejob` | Admin | Create a new job |
| `/editjob` | Admin | Edit existing job |

---

## 🐛 Troubleshooting

### Language Won't Change
1. Check spelling: `Config.Locale = 'en'` (lowercase)
2. File must exist: `locales/en.json`
3. Restart resource: `/restart hposlovi`

### Console Spam
1. Set `Config.Debug = false`
2. Restart resource

### Grades Resetting
Fixed in V1.0! Grades now preserve properly.

### Markers Not Showing
1. Enable debug to see logs
2. Check ox_gridsystem is installed
3. Verify job has positions set

---

## 📞 Support

For detailed documentation, see `README.md`

For issues:
1. Enable debug mode
2. Check F8 console
3. Check server console
4. Verify all dependencies installed

---

**Version:** 1.0  
**Status:** Stable Release  
**Last Updated:** January 30, 2026
