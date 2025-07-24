# Wallpaper Downloader Script for Unsplash
# Author: Beginner
# Version: 3.0 - Silent mode with error logging

param(
    [int]$Count = 20  # Number of wallpapers to download
)

# Configuration files
$ConfigFile = ".\config.json"
$HistoryFile = ".\history.json"
$LogFile = ".\wallpaper_downloader.log"

# Function to write error to log
function Write-ErrorLog {
    param(
        [string]$ErrorCode,
        [string]$Message
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp $ErrorCode : $Message"
    Add-Content -Path $LogFile -Value $logEntry -Encoding UTF8
}

# Function to clean old log entries (older than 7 days)
function Clear-OldLogs {
    if (Test-Path $LogFile) {
        try {
            $sevenDaysAgo = (Get-Date).AddDays(-7)
            $logContent = Get-Content $LogFile
            $filteredLogs = @()
            
            foreach ($line in $logContent) {
                if ($line -match "^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})") {
                    $logDate = [DateTime]::ParseExact($matches[1], "yyyy-MM-dd HH:mm:ss", $null)
                    if ($logDate -gt $sevenDaysAgo) {
                        $filteredLogs += $line
                    }
                }
            }
            
            if ($filteredLogs.Count -lt $logContent.Count) {
                $filteredLogs | Set-Content $LogFile -Encoding UTF8
            }
        }
        catch {
            Write-ErrorLog -ErrorCode "LOG_ERROR" -Message "Failed to clean old logs: $($_.Exception.Message)"
        }
    }
}

# Load configuration
if (!(Test-Path $ConfigFile)) {
    Write-ErrorLog -ErrorCode "CONFIG_ERROR" -Message "Configuration file not found: $ConfigFile"
    exit 1
}

try {
    $Config = Get-Content $ConfigFile -Raw | ConvertFrom-Json
}
catch {
    Write-ErrorLog -ErrorCode "CONFIG_ERROR" -Message "Error loading configuration: $($_.Exception.Message)"
    exit 1
}

# Clean old logs first
Clear-OldLogs

# Create wallpaper folder if it doesn't exist
$WallpaperFolder = $Config.folders.wallpapers
if (!(Test-Path $WallpaperFolder)) {
    try {
        New-Item -ItemType Directory -Path $WallpaperFolder -Force | Out-Null
    }
    catch {
        Write-ErrorLog -ErrorCode "FILE_ERROR" -Message "Failed to create wallpaper folder: $($_.Exception.Message)"
        exit 1
    }
}

# Function to clean old history entries (older than 7 days)
function Clear-OldHistory {
    param([object]$History)
    
    try {
        $sevenDaysAgo = (Get-Date).AddDays(-7)
        $filteredDownloads = @()
        
        foreach ($download in $History.downloads) {
            try {
                $downloadDate = [DateTime]::Parse($download.downloadDate)
                if ($downloadDate -gt $sevenDaysAgo) {
                    $filteredDownloads += $download
                }
                else {
                    # Remove old file if it still exists
                    if (Test-Path $download.filePath) {
                        try {
                            Remove-Item $download.filePath -Force
                        }
                        catch {
                            Write-ErrorLog -ErrorCode "FILE_ERROR" -Message "Failed to delete old history file $($download.fileName): $($_.Exception.Message)"
                        }
                    }
                }
            }
            catch {
                # Keep entries with invalid dates
                $filteredDownloads += $download
            }
        }
        
        $History.downloads = $filteredDownloads
        return $History
    }
    catch {
        Write-ErrorLog -ErrorCode "HISTORY_ERROR" -Message "Failed to clean old history: $($_.Exception.Message)"
        return $History
    }
}

# Function to load history from JSON
function Get-WallpaperHistory {
    if (Test-Path $HistoryFile) {
        try {
            $content = Get-Content $HistoryFile -Raw | ConvertFrom-Json
            return $content
        }
        catch {
            Write-ErrorLog -ErrorCode "FILE_ERROR" -Message "Error reading history file, creating new one"
        }
    }
    
    # Create new history structure
    return [PSCustomObject]@{
        downloads = @()
    }
}

# Function to save history to JSON
function Save-WallpaperHistory {
    param($History)
    
    try {
        $History | ConvertTo-Json -Depth 10 | Set-Content $HistoryFile -Encoding UTF8
    }
    catch {
        Write-ErrorLog -ErrorCode "FILE_ERROR" -Message "Failed to save history: $($_.Exception.Message)"
    }
}

# Function to get random wallpapers from Unsplash
function Get-UnsplashWallpapers {
    param([int]$Count = 10)
    
    $headers = @{
        "Authorization" = "Client-ID $($Config.unsplash.accessKey)"
    }
    
    $wallpapers = @()
    $errorCount = 0
    
    for ($i = 1; $i -le $Count; $i++) {
        try {
            $response = Invoke-RestMethod -Uri "https://api.unsplash.com/photos/random" -Headers $headers -Method Get -Body @{
                w = $Config.settings.imageWidth
                h = $Config.settings.imageHeight
            }
            
            $wallpapers += [PSCustomObject]@{
                id = $response.id
                url = $response.urls.full
                description = $response.description
                author = $response.user.name
            }
            
            Start-Sleep -Seconds 2  # Pause between API requests
        }
        catch {
            $errorCount++
            $errorMessage = $_.Exception.Message
            
            if ($errorMessage -like "*403*" -or $errorMessage -like "*Forbidden*") {
                Write-ErrorLog -ErrorCode "API_403" -Message "Rate limit or access denied for request $i"
            }
            elseif ($errorMessage -like "*404*") {
                Write-ErrorLog -ErrorCode "API_404" -Message "API endpoint not found for request $i"
            }
            elseif ($errorMessage -like "*500*") {
                Write-ErrorLog -ErrorCode "API_500" -Message "Server error for request $i"
            }
            else {
                Write-ErrorLog -ErrorCode "API_ERROR" -Message "API request $i failed: $errorMessage"
            }
        }
    }
    
    return @{
        wallpapers = $wallpapers
        errorCount = $errorCount
    }
}

# Function to download single image
function Download-Wallpaper {
    param(
        [string]$Url,
        [string]$FileName,
        [string]$FolderPath,
        [object]$WallpaperInfo
    )
    
    try {
        $FilePath = Join-Path $FolderPath $FileName
        
        Invoke-WebRequest -Uri $Url -OutFile $FilePath -UseBasicParsing
        
        if (Test-Path $FilePath) {
            $FileSize = (Get-Item $FilePath).Length
            
            # Return information for history
            return [PSCustomObject]@{
                fileName = $FileName
                filePath = $FilePath
                url = $Url
                unsplashId = $WallpaperInfo.id
                description = $WallpaperInfo.description
                author = $WallpaperInfo.author
                downloadDate = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
                fileSize = $FileSize
                folder = "wallpapers"
            }
        }
        else {
            Write-ErrorLog -ErrorCode "DOWNLOAD_FAILED" -Message "File not created: $FileName"
            return $null
        }
    }
    catch {
        Write-ErrorLog -ErrorCode "DOWNLOAD_FAILED" -Message "Download error for $FileName : $($_.Exception.Message)"
        return $null
    }
}

# Function to remove old wallpapers
function Remove-OldWallpapers {
    param([object]$History)
    
    if ($History.downloads.Count -gt $Config.settings.maxWallpapersPerFolder) {
        try {
            # Sort by date and keep only the latest ones
            $sortedDownloads = $History.downloads | Sort-Object downloadDate -Descending
            $toKeep = $sortedDownloads | Select-Object -First $Config.settings.maxWallpapersPerFolder
            $toDelete = $sortedDownloads | Select-Object -Skip $Config.settings.maxWallpapersPerFolder
            
            foreach ($item in $toDelete) {
                if (Test-Path $item.filePath) {
                    try {
                        Remove-Item $item.filePath -Force
                    }
                    catch {
                        Write-ErrorLog -ErrorCode "FILE_ERROR" -Message "Failed to delete old file $($item.fileName): $($_.Exception.Message)"
                    }
                }
            }
            
            # Update history - keep only current records
            $History.downloads = $toKeep
        }
        catch {
            Write-ErrorLog -ErrorCode "FILE_ERROR" -Message "Error during cleanup: $($_.Exception.Message)"
        }
    }
}

# Main download function
function Start-WallpaperDownload {
    param([object]$History)
    
    # Get wallpapers from Unsplash
    $result = Get-UnsplashWallpapers -Count $Count
    $wallpapers = $result.wallpapers
    $apiErrors = $result.errorCount
    
    if ($wallpapers.Count -eq 0) {
        Write-ErrorLog -ErrorCode "API_ERROR" -Message "Failed to get any wallpapers from Unsplash"
        return @{
            history = $History
            hasErrors = $true
        }
    }
    
    $downloadResults = @()
    $downloadErrors = 0
    
    foreach ($wallpaper in $wallpapers) {
        $fileName = "wallpaper_$($wallpaper.id)_$(Get-Date -Format 'yyyyMMdd_HHmmss').jpg"
        
        # Check if we already downloaded this wallpaper
        $existing = $History.downloads | Where-Object { $_.unsplashId -eq $wallpaper.id }
        if ($existing) {
            continue
        }
        
        $downloadResult = Download-Wallpaper -Url $wallpaper.url -FileName $fileName -FolderPath $WallpaperFolder -WallpaperInfo $wallpaper
        
        if ($downloadResult) {
            $History.downloads += $downloadResult
            $downloadResults += $downloadResult
        }
        else {
            $downloadErrors++
        }
        
        Start-Sleep -Seconds 1
    }
    
    # Determine if we have errors
    $hasErrors = ($apiErrors -gt 0) -or ($downloadErrors -gt 0) -or ($downloadResults.Count -eq 0)
    
    return @{
        history = $History
        hasErrors = $hasErrors
        downloadedCount = $downloadResults.Count
    }
}

# Main script logic
try {
    # Load history
    $history = Get-WallpaperHistory
    
    # Clean old history entries
    $history = Clear-OldHistory -History $history
    
    # Start download process
    $result = Start-WallpaperDownload -History $history
    
    # Only remove old files if no errors occurred
    if (-not $result.hasErrors -and $result.downloadedCount -gt 0) {
        Remove-OldWallpapers -History $result.history
    }
    elseif ($result.hasErrors) {
        Write-ErrorLog -ErrorCode "PROCESS_ERROR" -Message "Errors occurred during download, skipping cleanup"
    }
    
    # Save history
    Save-WallpaperHistory -History $result.history
    
    # Exit with appropriate code
    if ($result.hasErrors) {
        exit 1
    }
    else {
        exit 0
    }
}
catch {
    Write-ErrorLog -ErrorCode "CRITICAL_ERROR" -Message "Unhandled exception: $($_.Exception.Message)"
    exit 1
}