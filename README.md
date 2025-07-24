# Wallpaper Downloader

PowerShell script for automatic wallpaper downloading from Unsplash API. Downloads high-quality wallpapers (4K) and manages them automatically.

## Features

- 🖼️ **High Quality**: Downloads 4K wallpapers (3840x2160)
- 🔄 **Smart Management**: Keeps only latest 20 wallpapers, removes old ones
- 🚫 **No Duplicates**: Tracks downloaded wallpapers to avoid duplicates
- 🤫 **Silent Operation**: Runs quietly in background, logs only errors
- 📅 **Scheduler Ready**: Perfect for Windows Task Scheduler automation
- 🧹 **Auto Cleanup**: Removes old logs and history (7 days)

## Quick Start

### 1. Get Unsplash API Key
1. Go to [Unsplash Developers](https://unsplash.com/developers)
2. Create new application
3. Get your Access Key

### 2. Setup Configuration
1. Copy `config.example.json` to `config.json`
2. Add your Unsplash API credentials
3. Set your wallpaper folder path

### 3. Run Script
```powershell
# Download 20 wallpapers (default)
.\WallpaperDownloader.ps1

# Download specific amount
.\WallpaperDownloader.ps1 -Count 10
```

## Configuration

Edit `config.json`:
```json
{
    "unsplash": {
        "applicationId": "YOUR_APP_ID",
        "accessKey": "YOUR_ACCESS_KEY",
        "secretKey": "YOUR_SECRET_KEY"
    },
    "folders": {
        "wallpapers": "C:\\Users\\YourName\\Pictures\\wallpapers"
    },
    "settings": {
        "maxWallpapersPerFolder": 20,
        "imageWidth": 3840,
        "imageHeight": 2160
    }
}
```

## Automation with Windows Task Scheduler

### Option 1: Run 10 minutes after computer startup

1. **Open Task Scheduler:**
   - Win + R → `taskschd.msc` → Enter

2. **Create Task:**
   - Action → Create Basic Task
   - Name: `Wallpaper at Startup`
   - Description: `Download wallpapers 10 minutes after startup`

3. **Configure Trigger:**
   - When: `When the computer starts`
   - Next

4. **Configure Action:**
   - What action: `Start a program`
   - Program/script: `powershell.exe`
   - Arguments: `-ExecutionPolicy Bypass -File "C:\path\to\WallpaperDownloader.ps1"`
   - Start in: `C:\path\to\script\folder`
   - Next → Finish

5. **Add Delay:**
   - Find created task in list
   - Double click → Triggers tab
   - Edit → Advanced settings
   - ✅ Delay task for: `10 minutes`
   - OK

### Option 2: Daily at 4:00 PM

1. **Create New Task:**
   - Action → Create Basic Task
   - Name: `Wallpaper Daily 4PM`
   - Description: `Download wallpapers daily at 4:00 PM`

2. **Configure Trigger:**
   - When: `Daily`
   - Start: `16:00:00`
   - Recur every: `1 days`
   - Next

3. **Configure Action:**
   - What action: `Start a program`
   - Program/script: `powershell.exe`
   - Arguments: `-ExecutionPolicy Bypass -File "C:\path\to\WallpaperDownloader.ps1"`
   - Start in: `C:\path\to\script\folder`
   - Next → Finish

### Additional Settings for Both Tasks:

**For each task:**
1. Double click on task
2. **General tab:**
   - ✅ Run whether user is logged on or not
   - ✅ Run with highest privileges
3. **Settings tab:**
   - ✅ Allow task to be run on demand
   - ✅ If the task fails, restart every: `1 minute` for up to `3 times`
4. OK

### Emergency Stop:

**How to stop:**
1. **Task Manager:** Ctrl + Shift + Esc → find `powershell.exe` → End Task
2. **Task Scheduler:** Find task → Right click → End
3. **PowerShell:** `Stop-Process -Name powershell -Force`

**What happens:**
- ✅ Downloaded files remain safe
- ✅ History is preserved
- ⚠️ Partially downloaded file may be corrupted
- 🔄 Next run will recover automatically

## Error Handling

- Errors are logged to `wallpaper_downloader.log`
- Script runs silently - no console output during normal operation
- Old wallpapers are only deleted after successful new downloads
- Automatic cleanup of old logs (7 days)

## Project Structure

```
wallpaper-downloader/
├── WallpaperDownloader.ps1    # Main script
├── config.example.json        # Configuration template
├── README.md                  # This file
└── .gitignore                # Git ignore rules

# Generated files (not in repository):
├── config.json               # Your configuration
├── history.json              # Download history
└── wallpaper_downloader.log  # Error logs
```

## Requirements

- Windows PowerShell 5.0+
- Internet connection
- Unsplash API key (free)

## License

MIT License - feel free to use and modify!