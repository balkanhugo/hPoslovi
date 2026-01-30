# hPoslovi

## 📋 Configuration Guide

### Basic Configuration (`config/config.lua`)

```lua
-- ===========================================
-- DEBUG & LOCALE SETTINGS
-- ===========================================
Config.Debug = false  -- Set to true for detailed logging
Config.Locale = 'en'  -- Options: 'en', 'hr'

-- ===========================================
-- ADMIN GROUPS
-- ===========================================
Config.AdminGroups = {
    'admin',
    'superadmin',
    'developer'
}

-- ===========================================
-- COMMANDS
-- ===========================================
Config.CreateCommand = 'makejob'  -- Command to create new job
Config.EditCommand = 'editjob'    -- Command to edit existing job
```

### Changing the Language

**Step-by-Step**:
1. Open `/config/config.lua`
2. Locate line: `Config.Locale = 'en'`
3. Change value:
   - For English: `Config.Locale = 'en'`
   - For Croatian: `Config.Locale = 'hr'`
4. Save the file
5. Restart the resource: `/restart yourresourcename`

**Important**: The locale file must exist in `/locales/` folder. Available: `en.json`, `hr.json`

### Marker Configuration

```lua
Config.MarkerType = 21           -- Marker type (21 is default)
Config.MarkerDrawDistance = 3    -- Distance to see marker
Config.InteractDistance = 2      -- Distance to interact
Config.MarkerSize = vector3(0.8, 0.8, 0.8)
Config.MarkerColor = { r = 255, g = 255, b = 255 }
```

### Default Grades

When creating a job without specifying grades, these defaults apply:

```lua
Config.IfNotGrades = {
    { grade = 0, name = 'recruit', label = 'Recruit', salary = '0' },
    { grade = 1, name = 'employee', label = 'Employee', salary = '0' },
    { grade = 2, name = 'manager', label = 'Manager', salary = '0' },
    { grade = 3, name = 'boss', label = 'Boss', salary = '0' },
}
```

---

## 🎯 Key Features

### Wardrobe System
- **Everyone** can:
  - Open the ped/outfit menu
  - Apply saved outfits
- **Boss grade or higher** can:
  - Save new outfits
  - Delete existing outfits

### Boss Menu
- Accessible to players with grade **≥** boss grade
- Example: If boss is grade 3, grades 3, 4, 5, etc. can all access it

### Grade/Rank System
- Grades are preserved when editing jobs
- Only change when explicitly modified
- No more accidental resets!

### Marker System
- Auto-refreshes after job edits
- Supports custom textures
- Permission-based (job + grade required)

---

## 🔧 Troubleshooting

### Issue: Locale not changing
**Solution**: 
1. Check spelling: `Config.Locale = 'en'` (lowercase)
2. Ensure locale file exists: `/locales/en.json`
3. Restart resource completely

### Issue: Markers not showing
**Solution**:
1. Enable debug: `Config.Debug = true`
2. Check F8 console for marker registration messages
3. Verify ox_gridsystem is installed

### Issue: Can't save outfits
**Solution**:
1. Check your grade is >= boss grade
2. Verify illenium-appearance is installed
3. Check server console for errors

### Issue: Jobs not refreshing
**Solution**:
- Should work automatically now
- If not, check `ESX.RefreshJobs()` is being called in server logs (when Debug = true)

---

## 📦 Dependencies

**Required**:
- `es_extended` (ESX)
- `ox_lib`
- `oxmysql`
- `ox_inventory`
- `illenium-appearance`
- `esx_society`
- `ox_gridsystem` (for markers)

**Database Tables Required**:
- `hposlovi_jobs`
- `hposlovi_positions`
- `hposlovi_inventories`
- `hposlovi_vehicles`
- `hposlovi_outfits`

---

## 🚀 Installation

1. Extract files to your resources folder
2. Ensure all dependencies are installed
3. Import SQL file (if provided)
4. Add to `server.cfg`:
   ```
   ensure yourresourcename
   ```
5. Configure `config/config.lua` to your liking
6. Set your desired locale
7. Restart server

---

## 📝 Commands

- `/makejob` - Create a new job (admin only)
- `/editjob` - Edit an existing job (admin only)

---

## ⚙️ Technical Changes

### Server-Side
- Added `ESX.RefreshJobs()` after job creation/modification
- Added `hPoslovi:server:getBossGrade` callback
- Improved debug logging system
- Removed references to unsupported systems

### Client-Side
- Fixed grade checks (changed `==` to `>=`)
- Added wardrobe callback for boss grade checking
- Improved marker refresh system
- Conditional debug logging

### Configuration
- Simplified to only ESX Society + Illenium Appearance
- Added `Config.Debug` and `Config.Locale`
- Better organization and comments
- Removed legacy/unused options

---

## 🎨 Locale System Details

### Structure
Locales are stored as JSON files in `/locales/` folder:
- `en.json` - English
- `hr.json` - Croatian

### Using Locales in Code
```lua
locale('textuibossmenu')  -- Returns translated string
```

### Adding New Translations
1. Create new file in `/locales/` (e.g., `de.json` for German)
2. Copy structure from `en.json`
3. Translate all strings
4. Set `Config.Locale = 'de'` in config

---

## 📧 Support

If you encounter issues:
1. Enable debug mode: `Config.Debug = true`
2. Check F8 console and server console
3. Verify all dependencies are up to date
4. Check that locale files exist

---

## 🎉 Credits

- Original Script: nxs-dev
- Heaviely modified by: chiaroscuric using Claude
- Testing: Hugo Roleplay Staff

---

**Version**: 1.0  
**Release Date**: January 30, 2026  
**Status**: Stable Release
