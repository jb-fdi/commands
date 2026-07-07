# --- PowerShell version gate ---
# Try loading the Veeam module. If it demands PS7 and we're on 5.1, re-launch under pwsh.
$veeamLoaded = $false

try {
    Import-Module Veeam.Backup.PowerShell -InformationAction SilentlyContinue -ErrorAction Stop -WarningAction SilentlyContinue
    $veeamLoaded = $true
} catch {
    # Check if it's the "requires PS 7" error
    if ($_.Exception.Message -match 'minimum Windows PowerShell version') {
        # Re-launch this same script under PowerShell 7
        $pwshPath = "C:\Program Files\PowerShell\7\pwsh.exe"
        if (-not (Test-Path $pwshPath)) {
            # Try finding it on PATH
            $pwshPath = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
        }
        if ($pwshPath) {
            # When run inline (not from a .ps1 file), $MyInvocation.MyCommand.Definition
            # contains the script body, not a path. Write it to a temp file for pwsh.
            $scriptBody = $MyInvocation.MyCommand.Definition
            $tempScript = Join-Path $env:TEMP "veeam_monitor_$(Get-Random).ps1"
            try {
                Set-Content -Path $tempScript -Value $scriptBody -Encoding UTF8
                & $pwshPath -NoProfile -ExecutionPolicy Bypass -File $tempScript
                exit $LASTEXITCODE
            } finally {
                Remove-Item -Path $tempScript -Force -ErrorAction SilentlyContinue
            }
        } else {
            Write-Error "Veeam 13+ requires PowerShell 7 but pwsh.exe was not found. Install PowerShell 7."
            exit 1
        }
    }

    # Fallback for older Veeam (snap-in style)
    try {
        Add-PSSnapin VeeamPSSnapIn -ErrorAction Stop
        $veeamLoaded = $true
    } catch {
        Write-Error "Failed to load Veeam PowerShell module or snap-in: $_"
        exit 1
    }
}

if (-not $veeamLoaded) {
    Write-Error "Veeam PowerShell module could not be loaded."
    exit 1
}



$config = Get-VBRConfigurationBackupJob
if(-not  $config.enabled){
    write-host "Config Backups Not Enabled"
    exit 1
}

if($config.Repository.FriendlyPath -match "c:\\"){

    write-host "Config Backups saved to C:\ drive, should be NAS"
    exit 1
}

if( $config.ScheduleOptions.Enabled -ne $true){
    write-host "Config Backup schedule not enabled"
    exit 1
}

if( $config.ScheduleOptions.Enabled -ne $true){
    write-host "Config Backup schedule not enabled"
    exit 1
}

write-host "ok"
exit
