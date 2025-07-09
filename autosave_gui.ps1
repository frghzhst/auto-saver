Add-Type -AssemblyName System.Windows.Forms
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
        $form = New-Object System.Windows.Forms.Form
        $form.Text = "Enter Value"
        $form.Size = New-Object System.Drawing.Size(300,150)
        $form.StartPosition = "CenterScreen"
        $form.TopMost = $false

        $label = New-Object System.Windows.Forms.Label
        $label.Text = "Please enter a value:"
        $label.AutoSize = $true
        $label.Location = New-Object System.Drawing.Point(10,10)

        $textBox = New-Object System.Windows.Forms.TextBox
        $textBox.Size = New-Object System.Drawing.Size(260,20)
        $textBox.Location = New-Object System.Drawing.Point(10,40)

        $okButton = New-Object System.Windows.Forms.Button
        $okButton.Text = "OK"
        $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $okButton.Location = New-Object System.Drawing.Point(50,70)

        $cancelButton = New-Object System.Windows.Forms.Button
        $cancelButton.Text = "Cancel"
        $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $cancelButton.Location = New-Object System.Drawing.Point(150,70)

        $form.Controls.AddRange(@($label, $textBox, $okButton, $cancelButton))
        $form.AcceptButton = $okButton
        $form.CancelButton = $cancelButton

        $okButton.Add_Click({
            $form.Tag = $textBox.Text
            $form.Close()
        })
        $cancelButton.Add_Click({
            $form.Tag = $null
            $form.Close()
        })

        $form.ShowDialog() | Out-Null

        if ($form.Tag -ne $null -and $form.Tag.Trim().Length -gt 0) {
            if (-not (Test-Path $form.Tag.Trim())) {
                [System.Windows.Forms.MessageBox]::Show("Invalid path, please re-enter")
                log "user entered invalid path"
                $path1 = getpath 
            } else {
                $path1 = $form.Tag.Trim()
                Set-Content -Path $script:filename -Value $path1
                log "new path: [$path1]"
            }
        }
    }
    $path1 = (Get-Content $script:filename -Raw).Trim()
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
        try {
            New-Item $script:filename -ItemType File | Out-Null
            log "[$script:filename] made"
        } catch {
            log "error creating file: $_"
        }
    }
    if (-not (Test-Path $script:savedir)) {
        try {
            New-Item $script:savedir -ItemType Directory | Out-Null
            log "[$script:savedir] directory made"
        } catch {
            log "error creating directory: $_"
        }
    }
}

function main {
    $script:path = getpath
    function usrdis {
        $form = New-Object System.Windows.Forms.Form
        $form.Text = "Options"
        $form.Size = New-Object System.Drawing.Size(300,150)
        $form.StartPosition = "CenterScreen"
        $form.TopMost = $false

        $label = New-Object System.Windows.Forms.Label
        $label.Text = "Choose an option:"
        $label.AutoSize = $true
        $label.Location = New-Object System.Drawing.Point(100,20)
        $form.Controls.Add($label)

        function Show-YesNoBox {
            param([string]$buttonName)
            $result = [System.Windows.Forms.MessageBox]::Show(
                "You chose to $buttonName. Do you want to continue?",
                "Confirm",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Question
            )
            if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                switch ($buttonName) {
                    'Save' {
                        log "user chose to save"
                        save -patht $script:path -dirto $savedir
                    }
                    'Change tdir' {
                        log "user chose to change target directory"
                        $script:path = getpath -fask
                        usrdis
                        return
                    }
                    'Restore' {
                        log "user chose to restore past save"
                        $oldfs = Get-ChildItem -Path $path
                        foreach ($item in $oldfs) {
                            try {
                                Remove-Item $item.FullName -Recurse -Force
                                log "removed: [$($item.Fullname)]"
                                Write-Output "removed: [$($item.Fullname)]"
                            } catch {
                                Write-Output "error occured trying to remove [$($item.Fullname)]: $_"
                                log "error occured trying to remove file [$($item.Fullname)]: $_"
                            }
                        }
                        save -patht $script:savedir -dirto $path
                        usrdis
                        return
                    }
                }
                [System.Windows.Forms.MessageBox]::Show("Success")
            } else {
                [System.Windows.Forms.MessageBox]::Show("Cancelled")
            }
        }

        $button1 = New-Object System.Windows.Forms.Button
        $button1.Text = "Save"
        $button1.Location = New-Object System.Drawing.Point(20,60)
        $button1.Add_Click({ Show-YesNoBox "Save" })
        $form.Controls.Add($button1)

        $button2 = New-Object System.Windows.Forms.Button
        $button2.Text = "Change tdir"
        $button2.Location = New-Object System.Drawing.Point(110,60)
        $button2.Add_Click({ Show-YesNoBox "Change tdir" })
        $form.Controls.Add($button2)

        $button3 = New-Object System.Windows.Forms.Button
        $button3.Text = "Restore"
        $button3.Location = New-Object System.Drawing.Point(200,60)
        $button3.Add_Click({ Show-YesNoBox "Restore" })
        $form.Controls.Add($button3)

        [void]$form.ShowDialog()
    }
    usrdis
}

try {
    log "--program started--"
    prep
    main
} catch {
    log "error occured trying to run: $_"
}
log "--program ended--"