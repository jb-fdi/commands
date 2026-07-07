# --- PowerShell version gate ---
# Try loading the Veeam module. If it demands PS7 and we're on 5.1, re-launch under pwsh
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
            $pwshPath = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
        }

        if ($pwshPath) {
            $scriptBody = $MyInvocation.MyCommand.Definition
            $tempScript = Join-Path $env:TEMP "veeam_monitor_$(Get-Random).ps1"
            try {
                Set-Content -Path $tempScript -Value $scriptBody -Encoding UTF8
                & $pwshPath -NoProfile -ExecutionPolicy Bypass -File $tempScript
                $childExit = $LASTEXITCODE
            } finally {
                Remove-Item -Path $tempScript -Force -ErrorAction SilentlyContinue
            }
            # Parent takes on the child's result and stops here - do not fall through.
            exit $childExit
        } else {
            Write-Error "Veeam requires PowerShell 7 but pwsh.exe was not found. Install PowerShell 7."
            exit 1
        }
    }

    # Fallback for older Veeam (snap-in style) - only reached if the error above
    # was NOT the PS7 version error.
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

# --- Config backup checks ---
$config = Get-VBRConfigurationBackupJob
$failed = $false

if (-not $config.Enabled) {
    Write-Host "FAIL: Config backup job not enabled"
    $failed = $true
}

if ($config.Repository.FriendlyPath -match '^[a-zA-Z]:\\') {
    Write-Host "FAIL: Config backup saved to local drive ($($config.Repository.FriendlyPath)), should be NAS"
    $failed = $true
}

if ($config.ScheduleOptions.Enabled -ne $true) {
    Write-Host "FAIL: Config backup schedule not enabled"
    $failed = $true
}

if ($config.LastResult -ne 'Success') {
    Write-Host "FAIL: Last config backup result was '$($config.LastResult)', not Success"
    $failed = $true
}

if ($failed) {
    exit 1
}

Write-Host "OK"
exit 0
