$script:tdir = ""
$script:tdirf = "tdir.txt"
$script:lfile = "log.txt"
$script:slog = "save_log.txt"
$script:tprocess = ""

function log {
    param([string]$message)
    
    if (-not (Test-Path $script:lfile)) {
        try {
            New-Item $script:lfile -ItemType File -Force | Out-Null
        } catch {
            Write-Host "Failed to create log file: $_" -ForegroundColor Red
            return
        }
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$timestamp]: $message" | Out-File -FilePath $script:lfile -Append -Encoding utf8
}

function prep {
    $filesToCreate = @($script:tdirf, $script:lfile, $script:slog)
    
    foreach ($file in $filesToCreate) {
        if (-not (Test-Path $file)) {
            try {
                New-Item $file -ItemType File -Force | Out-Null
                log "Created file: [$file]"
            } catch {
                log "Error creating file [$file]: $_"
                Write-Host "Error creating $file : $_" -ForegroundColor Red
            }
        }
    }
}

function getpath {
    param([switch]$fask)
    
    if ($fask -or -not (Test-Path $script:tdirf) -or ((Get-Item $script:tdirf).Length -eq 0)) {
        do {
            $path1 = Read-Host "`nEnter full path of target directory to be saved"
            $path1 = $path1.Trim()
            
            if (-not (Test-Path $path1 -PathType Container)) {
                Write-Host "Path does not exist or is not a directory. Please try again." -ForegroundColor Yellow
                continue
            }
            
            Set-Content -Path $script:tdirf -Value $path1 -Force
            log "New path saved: [$path1]"
            break
        } while ($true)
    }
    
    $script:tdir = (Get-Content $script:tdirf -Raw).Trim()
    return $script:tdir
}

function save {
    param([switch]$s, [switch]$r)
    
    if (-not (Test-Path $script:tdir)) {
        log "Target directory does not exist: [$script:tdir]"
        Write-Host "Target directory does not exist!" -ForegroundColor Red
        return
    }

    if ($s) {
        log "Starting save operation"
        try {
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $timestamp | Out-File -Path $script:slog -Append
            
            Get-ChildItem -Path $script:tdir -File | ForEach-Object {
                try {
                    $fileBytes = [System.IO.File]::ReadAllBytes($_.FullName)
                    $hexString = [System.BitConverter]::ToString($fileBytes)
                    "$($_.FullName):|$hexString|" | Out-File -Path $script:slog -Append
                    log "Saved bytes of [$($_.FullName)]"
                } catch {
                    log "Error processing $($_.FullName): $_"
                    Write-Host "Error processing $($_.Name)" -ForegroundColor Yellow
                }
            }
            log "Save operation completed"
            Write-Host "Save completed successfully!" -ForegroundColor Green
        } catch {
            log "Save operation failed: $_"
            Write-Host "Save failed: $_" -ForegroundColor Red
        }
    }
    elseif ($r) {
        log "Starting restore operation"
        
        if (-not (Test-Path $script:slog) -or (Get-Item $script:slog).Length -eq 0) {
            log "No save data found to restore"
            Write-Host "No saved data available to restore!" -ForegroundColor Yellow
            return
        }

        try {
            # Display available backups
            $backups = @()
            $content = Get-Content -Path $script:slog
            $currentBackup = @()
            
            foreach ($line in $content) {
                if ($line -match '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$') {
                    if ($currentBackup.Count -gt 0) {
                        $backups += ,@($currentBackup)
                        $currentBackup = @()
                    }
                    $currentBackup += $line
                } else {
                    $currentBackup += $line
                }
            }
            
            if ($currentBackup.Count -gt 0) {
                $backups += ,@($currentBackup)
            }

            for ($i = 0; $i -lt $backups.Count; $i++) {
                Write-Host "$($i+1). $($backups[$i][0])"
            }

            $selection = [int](Read-Host "`nEnter the number to restore")
            if ($selection -lt 1 -or $selection -gt $backups.Count) {
                Write-Host "Invalid selection!" -ForegroundColor Red
                return
            }

            $confirm = Read-Host "Are you sure you want to restore? This will overwrite existing files! (y/n)"
            if ($confirm -notmatch '^[yY]') {
                log "Restore cancelled by user"
                return
            }

            $selectedBackup = $backups[$selection-1]
            $pattern = '^(.+):\|([^|]+)\|$'
            
            foreach ($line in $selectedBackup) {
                if ($line -match $pattern) {
                    $filePath = $matches[1]
                    $hexString = $matches[2]
                    
                    try {
                        $hexPairs = $hexString -split '-'
                        $bytes = [byte[]]::new($hexPairs.Count)
                        
                        for ($i = 0; $i -lt $hexPairs.Count; $i++) {
                            $bytes[$i] = [Convert]::ToByte($hexPairs[$i], 16)
                        }
                        
                        $dir = [System.IO.Path]::GetDirectoryName($filePath)
                        if (-not (Test-Path $dir)) {
                            New-Item -Path $dir -ItemType Directory -Force | Out-Null
                        }
                        
                        [System.IO.File]::WriteAllBytes($filePath, $bytes)
                        log "Restored file: $filePath"
                    } catch {
                        log "Error restoring $filePath : $_"
                        Write-Host "Error restoring $filePath" -ForegroundColor Yellow
                    }
                }
            }
            
            log "Restore operation completed"
            Write-Host "Restore completed successfully!" -ForegroundColor Green
        } catch {
            log "Restore operation failed: $_"
            Write-Host "Restore failed: $_" -ForegroundColor Red
        }
    }
}

function ask {
    do {
        $ac = Read-Host "`nChoose your action (s/r/n/q):`ns - Save current state`nr - Restore from backup`nn - Set new target path`nq - Quit"
        
        switch -Regex ($ac) {
            '^[sS]$' {
                save -s
                break
            }
            '^[rR]$' {
                save -r
                break
            }
            '^[nN]$' {
                getpath -fask
                break
            }
            '^[qQ]$' {
                Write-Host "Exiting..."
                return $false
            }
            default {
                Write-Host "Invalid option, please try again." -ForegroundColor Yellow
                continue
            }
        }
        return $true
    } while ($true)
}

function main {
    prep
    
    # Get initial target path
    getpath
    
    # Check if we should monitor a process
    $monitorProcess = Read-Host "Do you want to monitor a process? (y/n)"
    if ($monitorProcess -match '^[yY]') {
        do {
            $trpoc = Read-Host "Enter the name of a process to monitor (without .exe) or 'q' to quit"
            
            if ($trpoc -match '^[qQ]$') {
                break
            }
            
            $trpoc = $trpoc.Trim()
            if (-not $trpoc) {
                continue
            }
            
            $script:tprocess = $trpoc
            log "Monitoring process: [$script:tprocess]"
            
            while ($true) {
                try {
                    # Wait for process to start
                    while (-not (Get-Process -Name $script:tprocess -ErrorAction SilentlyContinue)) {
                        Start-Sleep -Seconds 1
                    }
                    
                    log "[$script:tprocess] started"
                    Write-Host "Process [$script:tprocess] detected!" -ForegroundColor Green
                    
                    # Wait for process to exit
                    Wait-Process -Name $script:tprocess -ErrorAction Stop
                    log "[$script:tprocess] has ended"
                    
                    # Ask for action
                    if (-not (ask)) {
                        return
                    }
                    
                } catch {
                    log "Error monitoring process: $_"
                    Write-Host "Error monitoring process: $_" -ForegroundColor Red
                    break
                }
            }
        } while ($true)
    }
    
    # If not monitoring a process, just ask once
    ask | Out-Null
}

try {
    log "-- Program started --"
    main
    log "-- Program ended --"
} catch {
    log "Unhandled error: $_"
    Write-Host "Fatal error: $_" -ForegroundColor Red
}