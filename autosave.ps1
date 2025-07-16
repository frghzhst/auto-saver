$script:tdir = ""
$script:tdirf = "tdir.txt"
$script:lfile = "log.txt"
$script:slog = "save_log.txt"

function log {
    param(
        [string]$message
    )
    if (-not (Test-Path $script:lfile)) {
        New-Item $lfile -ItemType File | Out-Null
    }
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$timestamp]: $message" | Out-File -FilePath $lfile -Append -Encoding utf8
}

function prep {
    if (-not (Test-Path $script:tdirf)) {
        try {
            New-Item $script:tdirf -ItemType File | Out-Null
            log "[$script:tdirf] made"
        } catch {
            log "error creating file: $_"
        }
    }
    if (-not (Test-Path $script:lfile)) {
        try {
            New-Item $script:lfile -ItemType File | Out-Null
            log "[$script:lfile] made"
        } catch {
            log "error creating file: $_"
        }
    }
    if (-not (Test-Path $script:slog)) {
        try {
            New-Item $script:slog -ItemType File | Out-Null
            log "[$script:slog] made"
        } catch {
            log "error creating file: $_"
        }
    }
}

function getpath {
    param (
        [switch]$fask
        )
    if ($fask -or (Get-Item $script:tdirf).Length -eq 0) {
        $path1 = Read-Host "`nenter full path of target directory to be saved"
        $path1 = $path1.Trim()
        Set-Content -Path $script:tdirf -Value $path1
        log "new path: [$path1]"
    }
    $path1 = (Get-Content $script:tdirf -Raw).Trim()
    #$path1 = Join-Path -Path $path1 -ChildPath '*'
    $script:tdir = $path1
    return $path1
}

function save {
    param (
        [switch]$s,
        [switch]$r
        )
    if ($s) {
        log "user chose to save"
        $items = Get-ChildItem -Path $script:tdir
        Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -Path $script:slog -Append -NoNewLine
        foreach ($item in $items) {
            try {
                $fileBytes = [System.IO.File]::ReadAllBytes($item) #get bytes
                $hexString = [System.BitConverter]::ToString($fileBytes)
                $format = "${item}:|$hexString|" | Out-File -Path $script:slog -Append -NoNewLine
                log "successfully got bytes of [$item], converted to hex and appended"
            } catch {
                log "error: $_"
            }
        }
        "" | Out-File -Path $script:slog -Append
        log "finished save"
    } elseif ($r) {
        log "user chose to restore"
        $contr = 0
        $items = Get-ChildItem -Path $script:tdir
        Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -Path $script:slog -Append -NoNewLine
        foreach ($item in $items) {
            try {
                $fileBytes = [System.IO.File]::ReadAllBytes($item) #get bytes
                $hexString = [System.BitConverter]::ToString($fileBytes)
                $format = "${item}:|$hexString|" | Out-File -Path $script:slog -Append -NoNewLine
                log "successfully got bytes of [$item], converted to hex and appended"
            } catch {
                log "error: $_"
            }
        }
        "" | Out-File -Path $script:slog -Append
        log "saved incase of user undo"
        foreach ($line in (Get-Content -Path $script:slog)) {
            $contr += 1
            $time = $line.Substring(0, 21)
            Write-Output "$contr. $time"
        }
        $ntr = Read-Host "`nenter a number to restore"
        $confirm = Read-Host "Are you sure (y/n)"
        if ($confirm -match '^(y|Y)$') {
            log "user confirms"
            foreach ($i in $script:tdir) {
                Remove-Item $i -Force
            }
            try {
                $content = Get-Content -Path $script:slog
                if ($ntr -gt 0 -and $ntr -le $content.Count) {
                    $line =  "$($content[$ntr - 1])"
                } else {
                    Write-Host "Error: Line number out of range (file has $($content.Count) lines)" -ForegroundColor Red
                }
            } catch {
                log "An error occurred: $_"
            }
            $pattern = '([^:|]+):\|([^|]+)\|'
            $match = [regex]::Matches($line, $pattern)
            $results = @{}
            foreach ($match in $matches) {
                $key = $match.Groups[1].Value
                $value = $match.Groups[2].Value
                $results[$key] = $value
                $temp = Join-Path -Path $script:tdir -ChildPath $key
                try {
                    New-Item -Path $temp -ItemType File
                    log "[$temp] created"
                } catch {
                    log "error: $_"
                }
                $hexPairs = $value.Split('-')
                $newBytes = [byte[]]::new($hexPairs.Count)
                for ($i = 0; $i -lt $hexPairs.Count; $i++) {
                    $newBytes[$i] = [Convert]::ToByte($hexPairs[$i], 16)
                }
                [System.IO.File]::WriteAllBytes($temp, $bytes)
            }
            log "restored successfully"
            #New-Item -Path (Join-Path -Path $script:tdir -ChildPath ) -ItemType File
        } else {
            return 
        }
    }
}

function ask {
    $ac = Read-Host "choose your action (s/r/n) s for save, r for restore and n for new target path"
    if ($ac -match '^(s|S)$') {
        save -s
    } elseif ($ac -match '^(r|R)$') {
        save -r
    } elseif ($ac -match '^(n|N)$') {
        getpath -fask 
    } else {
        Write-Output "exiting..."
        return
    }
}

function main {
    getpath
    function getproc {
        $trpoc = Read-Host "enter the name of a process to moniter"

        if ($trpoc -ne $null -and $trpoc.Trim().Length -gt 0 -and $trpoc.Trim() -ne "null") {
            $script:tprocess = $trpoc.Trim() -replace '\.exe$', ''
            log "will moniter process by name: [$script:tprocess]"
        } else {
            return
        }
        while (1) {
            while (-not (Get-Process -Name $script:tprocess -ErrorAction SilentlyContinue)) {
                Start-Sleep -Seconds 1
            }
            log "[$script:tprocess] started"
            try {
                Wait-Process -Name $script:tprocess
                log "[$script:tprocess] has ended"
                ask
            } catch {
                log "error occured: $_"
            }
        }
    }
    getproc
    ask
}

try {
    log "--program started--"
    prep
    main
    log "--program ended--"
} catch {
    log "error: $_"
}