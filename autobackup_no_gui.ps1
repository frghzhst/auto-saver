$script:filename = "tdir.txt"
$script:savedir = "auto_save"
$script:lfile = "log.txt"

function log {
    param(
        [string]$message
        )
    if (-not (Test-Path $script:lfile)) {
        New-Item $lfile -ItemType File | Out-Null
    }
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$timestamp] $message" | Out-File -FilePath $lfile -Append
}

function getpath {
    param (
        [switch]$fask
        )
    if ($fask -or (Get-Item $script:filename).Length -eq 0) {
        $path1 = Read-Host "`nenter full path of target directory to be saved"
        $path1 = $path1.Trim()
        Set-Content -Path $script:filename -Value $path1
        log "new path: [$path1]"
    }
    $path1 = (Get-Content $script:filename -Raw).Trim()
    #$path1 = Join-Path -Path $path1 -ChildPath '*'
    return $path1
}

function save {
    param (
        [string]$patht,
        [string]$dirto
        )
    try {
        $patht = Join-Path -Path $patht -ChildPath '*'
        Copy-Item -Path $patht -Destination $dirto -Recurse -Force
        Write-Output "success"
        log "saved [$patht] to [$dirto]"
    } catch {
        Write-Output "an error occured: $_"
        log "error occured: $_"
    }
}

function prep {
    if (-not (Test-Path $script:filename)) {
        Write-Host "file does not exist, creating now"
        try {
            New-Item $script:filename -ItemType File | Out-Null
            log "[$script:filename] made"
        } catch {
            log "error creating file: $_"
        }

    }
    if (-not (Test-Path $script:savedir)) {
        try {
            New-Item $savedir -ItemType Directory | Out-Null
            log "[$savedir] directory made"
        } catch {
            log "error creating file: $_"
        }
    }
}

function main {
    $path = getpath
    $saveconfirm = Read-Host "`ndo you want to override past save (y/n) (e to change save target) (r to restore save)"
    if ($saveconfirm -match '^(y|Y)$') {
        log "user chose to save"
        save -patht $path -dirto $savedir
    } elseif ($saveconfirm -match '^(e|E)$') {
        log "user chose to change target directory"
        $path = getpath -fask
        main
    }  elseif ($saveconfirm -match '^(r|R)$') {
        log "user chose to restore save"
        $sure = Read-Host "are you sure (y/n)"
        if ($sure -match '^(y|Y)$') {
            log "user confirmed restore"
            $oldfs = Get-ChildItem -Path $path
            foreach ($item in $oldfs) {
                try {
                    #Remove-Item $item.FullName -Recurse -Confirm
                    Remove-Item $item.FullName -Recurse -Force
                    log "removed: [$($item.Fullname)]" 
                    Write-Output "removed: [$($item.Fullname)]" 
                } catch {
                    Write-Output "error occured trying to remove [$($item.Fullname)]: $_"
                    log "error occured trying to remove file [$($item.Fullname)]: $_"
                }
            }
            save -patht $savedir -dirto $path
        }
        main
    } else {
        Write-Host "`nok, exiting"
        log "--program exits--"
        return
    }
}

try {
    log "--program started--"
    prep
    main
} catch {
    log "error occured trying to run: $_"
}
log "--program ended--"