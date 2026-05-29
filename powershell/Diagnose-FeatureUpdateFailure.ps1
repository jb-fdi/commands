#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Diagnoses Windows Feature Update failures by analyzing logs, event viewer, and system state.

.DESCRIPTION
    Collects and analyzes data from multiple sources to pinpoint why a Windows feature update failed:
    - Windows Update error codes and history
    - CBS (Component-Based Servicing) logs
    - SetupDiag analysis
    - Windows Setup logs (Panther)
    - Event Viewer (Setup, System, Windows Update)
    - Disk space and system health checks

.NOTES
    Run as Administrator. Output is saved to C:\FeatureUpdateDiag\ by default.
#>

param(
    [string]$OutputPath = "C:\FeatureUpdateDiag",
    [switch]$RunSetupDiag,
    [switch]$OpenReport
)

# ─────────────────────────────────────────────
# Setup
# ─────────────────────────────────────────────
$ErrorActionPreference = "SilentlyContinue"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$reportFile = Join-Path $OutputPath "FeatureUpdateReport_$timestamp.txt"

if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath | Out-Null
}

$report = [System.Collections.Generic.List[string]]::new()

function Write-Section {
    param([string]$Title)
    $line = "=" * 70
    $report.Add("`n$line")
    $report.Add("  $Title")
    $report.Add($line)
    Write-Host "`n[$Title]" -ForegroundColor Cyan
}

function Write-Entry {
    param([string]$Text, [string]$Color = "White")
    $report.Add($Text)
    Write-Host $Text -ForegroundColor $Color
}

function Add-Blank { $report.Add("") }


# ─────────────────────────────────────────────
# Header
# ─────────────────────────────────────────────
$report.Add("=" * 70)
$report.Add("  WINDOWS FEATURE UPDATE FAILURE DIAGNOSTIC REPORT")
$report.Add("  Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$report.Add("  Computer:  $env:COMPUTERNAME")
$report.Add("=" * 70)

Write-Host "`nWindows Feature Update Failure Diagnostics" -ForegroundColor Yellow
Write-Host "Report will be saved to: $reportFile`n" -ForegroundColor Gray


# ─────────────────────────────────────────────
# 1. Current OS Version
# ─────────────────────────────────────────────
Write-Section "CURRENT OS VERSION"
$os = Get-CimInstance Win32_OperatingSystem
Write-Entry "OS Name       : $($os.Caption)"
Write-Entry "Version       : $($os.Version)"
Write-Entry "Build         : $($os.BuildNumber)"
Write-Entry "Architecture  : $($os.OSArchitecture)"

$regVer = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -ErrorAction SilentlyContinue
if ($regVer) {
    Write-Entry "Display Version: $($regVer.DisplayVersion)"
    Write-Entry "UBR           : $($regVer.UBR)"
    Write-Entry "Edition       : $($regVer.EditionID)"
}


# ─────────────────────────────────────────────
# 2. Windows Update History (last 20 updates)
# ─────────────────────────────────────────────
Write-Section "WINDOWS UPDATE HISTORY (Last 20)"

$session = New-Object -ComObject Microsoft.Update.Session
$searcher = $session.CreateUpdateSearcher()
$histCount = $searcher.GetTotalHistoryCount()

if ($histCount -gt 0) {
    $history = $searcher.QueryHistory(0, [Math]::Min($histCount, 20))
    foreach ($entry in $history) {
        $status = switch ($entry.ResultCode) {
            1 { "In Progress" }
            2 { "SUCCESS" }
            3 { "SUCCESS (with errors)" }
            4 { "FAILED" }
            5 { "Aborted" }
            default { "Unknown ($($entry.ResultCode))" }
        }
        $color = if ($entry.ResultCode -eq 4) { "Red" } elseif ($entry.ResultCode -eq 2) { "Green" } else { "Yellow" }
        $hResult = "0x{0:X8}" -f [uint32]$entry.HResult
        $line = "{0,-12} {1,-12} {2} [HResult: {3}]" -f $entry.Date.ToString("yyyy-MM-dd"), $status, $entry.Title, $hResult
        Write-Entry $line $color
    }
} else {
    Write-Entry "No update history found."
}


# ─────────────────────────────────────────────
# 3. Windows Update Error from Registry
# ─────────────────────────────────────────────
Write-Section "WINDOWS UPDATE REGISTRY STATE"

$wuKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Install",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Setup\Results"
)

foreach ($key in $wuKeys) {
    if (Test-Path $key) {
        Write-Entry "`nKey: $key"
        Get-ItemProperty $key | Format-List | Out-String | ForEach-Object { $report.Add($_) }
    }
}

# Upgrade result code
$upgradeKey = "HKLM:\SYSTEM\Setup\MoSetup"
if (Test-Path $upgradeKey) {
    $moSetup = Get-ItemProperty $upgradeKey
    Write-Entry "`nMoSetup (Feature Upgrade):"
    $moSetup.PSObject.Properties | Where-Object { $_.Name -notmatch "^PS" } | ForEach-Object {
        Write-Entry "  $($_.Name) = $($_.Value)"
    }
}


# ─────────────────────────────────────────────
# 4. Event Log - Setup Events
# ─────────────────────────────────────────────
Write-Section "EVENT LOG - SETUP (Errors & Warnings, last 48h)"

$since = (Get-Date).AddHours(-48)
$setupEvents = Get-WinEvent -FilterHashtable @{
    LogName   = 'Setup'
    StartTime = $since
    Level     = @(1, 2, 3)   # Critical, Error, Warning
} -MaxEvents 30 -ErrorAction SilentlyContinue

if ($setupEvents) {
    foreach ($evt in $setupEvents) {
        $color = if ($evt.Level -eq 2) { "Red" } else { "Yellow" }
        Write-Entry ("[{0}] ID:{1} {2}" -f $evt.TimeCreated.ToString("MM-dd HH:mm"), $evt.Id, $evt.Message.Split("`n")[0]) $color
    }
} else {
    Write-Entry "No Setup errors/warnings in the last 48 hours."
}


# ─────────────────────────────────────────────
# 5. Event Log - Windows Update Errors
# ─────────────────────────────────────────────
Write-Section "EVENT LOG - WINDOWS UPDATE (Errors, last 48h)"

$wuEvents = Get-WinEvent -FilterHashtable @{
    LogName   = 'System'
    ProviderName = 'Microsoft-Windows-WindowsUpdateClient'
    StartTime = $since
    Level     = @(1, 2, 3)
} -MaxEvents 20 -ErrorAction SilentlyContinue

if ($wuEvents) {
    foreach ($evt in $wuEvents) {
        Write-Entry ("[{0}] ID:{1} {2}" -f $evt.TimeCreated.ToString("MM-dd HH:mm"), $evt.Id, $evt.Message.Split("`n")[0]) "Red"
    }
} else {
    Write-Entry "No Windows Update errors in System log in the last 48 hours."
}


# ─────────────────────────────────────────────
# 6. CBS Log - Recent Errors
# ─────────────────────────────────────────────
Write-Section "CBS LOG - RECENT ERRORS (Last 100 error lines)"

$cbsLog = "$env:windir\Logs\CBS\CBS.log"
if (Test-Path $cbsLog) {
    $cbsErrors = Get-Content $cbsLog -Tail 5000 |
        Where-Object { $_ -match "\[SR\]|error|fail|0x8" } |
        Select-Object -Last 100
    if ($cbsErrors) {
        $cbsErrors | ForEach-Object { Write-Entry $_ "Red" }
    } else {
        Write-Entry "No obvious errors found in CBS log tail."
    }
} else {
    Write-Entry "CBS.log not found at $cbsLog"
}


# ─────────────────────────────────────────────
# 7. Windows Setup (Panther) Log
# ─────────────────────────────────────────────
Write-Section "WINDOWS SETUP PANTHER LOG - ERRORS"

$pantherPaths = @(
    "$env:windir\Panther\setuperr.txt",
    "$env:windir\Panther\setupact.log",
    "C:\`$WINDOWS.~BT\Sources\Panther\setuperr.txt",
    "C:\`$WINDOWS.~BT\Sources\Panther\setupact.log"
)

foreach ($path in $pantherPaths) {
    if (Test-Path $path) {
        Write-Entry "`nFile: $path" "Cyan"
        $errors = Get-Content $path -ErrorAction SilentlyContinue |
            Where-Object { $_ -match "error|fail|0x8" } |
            Select-Object -Last 50
        if ($errors) {
            $errors | ForEach-Object { Write-Entry $_ "Red" }
        } else {
            Write-Entry "(No errors matched in this file)"
        }
    }
}

# Copy Panther logs to output directory
$pantherDest = Join-Path $OutputPath "PantherLogs_$timestamp"
$pantherDirs = @("$env:windir\Panther", "C:\`$WINDOWS.~BT\Sources\Panther")
foreach ($dir in $pantherDirs) {
    if (Test-Path $dir) {
        Copy-Item -Path $dir -Destination $pantherDest -Recurse -Force -ErrorAction SilentlyContinue
        Write-Entry "(Panther logs copied to $pantherDest)"
    }
}


# ─────────────────────────────────────────────
# 8. Disk Space Check
# ─────────────────────────────────────────────
Write-Section "DISK SPACE"

Get-PSDrive -PSProvider FileSystem | ForEach-Object {
    $free = [math]::Round($_.Free / 1GB, 2)
    $used = [math]::Round($_.Used / 1GB, 2)
    $total = $free + $used
    $color = if ($free -lt 10) { "Red" } elseif ($free -lt 25) { "Yellow" } else { "Green" }
    Write-Entry ("Drive {0}:  {1} GB free of {2} GB total" -f $_.Name, $free, $total) $color
}

$sysDrive = $env:SystemDrive.TrimEnd(':')
$freeGB = [math]::Round((Get-PSDrive $sysDrive).Free / 1GB, 2)
if ($freeGB -lt 20) {
    Write-Entry "`n*** WARNING: Less than 20 GB free on system drive. Feature updates require at least 20 GB. ***" "Red"
}


# ─────────────────────────────────────────────
# 9. System File Checker & DISM Status
# ─────────────────────────────────────────────
Write-Section "SYSTEM HEALTH"

# SFC last run result from CBS
Write-Entry "Checking CBS log for last SFC result..."
if (Test-Path $cbsLog) {
    $sfcResult = Get-Content $cbsLog -Tail 2000 |
        Where-Object { $_ -match "Windows Resource Protection" } |
        Select-Object -Last 5
    if ($sfcResult) {
        $sfcResult | ForEach-Object { Write-Entry $_ }
    } else {
        Write-Entry "No recent SFC result found. Run: sfc /scannow"
    }
}

# DISM log
$dismLog = "$env:windir\Logs\DISM\dism.log"
if (Test-Path $dismLog) {
    Write-Entry "`nDISM Log - Recent Errors:"
    Get-Content $dismLog -Tail 3000 |
        Where-Object { $_ -match "error|fail" } |
        Select-Object -Last 20 |
        ForEach-Object { Write-Entry $_ "Yellow" }
}


# ─────────────────────────────────────────────
# 10. Pending Reboots / Conflicting State
# ─────────────────────────────────────────────
Write-Section "PENDING REBOOTS & CONFLICTING STATE"

$rebootKeys = @{
    "CBS Reboot Pending"       = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"
    "Windows Update Reboot"    = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
    "File Rename Reboot"       = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\FileRenameOperations"
    "Post-Update Reboot"       = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
}

foreach ($label in $rebootKeys.Keys) {
    $exists = Test-Path $rebootKeys[$label]
    $color  = if ($exists) { "Yellow" } else { "Green" }
    Write-Entry ("{0,-35}: {1}" -f $label, $(if ($exists) { "PENDING" } else { "None" })) $color
}


# ─────────────────────────────────────────────
# 11. SetupDiag (optional, downloads if needed)
# ─────────────────────────────────────────────
Write-Section "SETUPDIAG"

$setupDiagPath = Join-Path $OutputPath "SetupDiag.exe"
$setupDiagResult = Join-Path $OutputPath "SetupDiagResults_$timestamp.xml"

if ($RunSetupDiag) {
    Write-Entry "Downloading SetupDiag from Microsoft..."
    $dlUrl = "https://go.microsoft.com/fwlink/?linkid=870142"
    try {
        Invoke-WebRequest -Uri $dlUrl -OutFile $setupDiagPath -UseBasicParsing
        Write-Entry "Running SetupDiag..." "Yellow"
        Start-Process -FilePath $setupDiagPath -ArgumentList "/Output:$setupDiagResult /Format:xml" -Wait -NoNewWindow
        if (Test-Path $setupDiagResult) {
            [xml]$diagXml = Get-Content $setupDiagResult
            $failedRule = $diagXml.SetupDiag.ResultCode
            Write-Entry "SetupDiag Result: $failedRule" "Red"
        }
    } catch {
        Write-Entry "Could not download/run SetupDiag: $_" "Yellow"
        Write-Entry "You can download it manually from: https://go.microsoft.com/fwlink/?linkid=870142"
    }
} else {
    Write-Entry "SetupDiag not run. Re-run script with -RunSetupDiag to download and run it automatically."
    Write-Entry "Or download manually: https://go.microsoft.com/fwlink/?linkid=870142"
}


# ─────────────────────────────────────────────
# 12. Common Error Code Reference
# ─────────────────────────────────────────────
Write-Section "COMMON FEATURE UPDATE ERROR CODES"

$errorCodes = @{
    "0x80070070" = "Not enough disk space - free up at least 20 GB on C:"
    "0x80070020" = "File in use by another process - check antivirus / third-party apps"
    "0x8007002C" = "CBS package installation failed - run SFC and DISM"
    "0x80070002" = "File not found - source files missing or corrupted"
    "0xC1900101" = "Driver compatibility issue - update or uninstall problematic drivers"
    "0xC1900200" = "PC doesn't meet minimum requirements for this update"
    "0xC1900208" = "Incompatible app blocking update - check compatibility report"
    "0x80070005" = "Access denied - check permissions or conflicting security software"
    "0x80070017" = "Media is corrupted - re-download update media"
    "0x800700B7" = "Cannot create a file that already exists - Windows Update cleanup needed"
    "0x80073712" = "Windows Update component store is corrupted - run DISM /RestoreHealth"
    "0x8007001F" = "General device failure - check hardware and drivers"
    "0xC1900107" = "Cleanup condition not met from previous upgrade attempt - reboot required"
}

foreach ($code in $errorCodes.Keys | Sort-Object) {
    Write-Entry ("{0}  →  {1}" -f $code, $errorCodes[$code])
}


# ─────────────────────────────────────────────
# 13. Recommended Fix Commands
# ─────────────────────────────────────────────
Write-Section "RECOMMENDED REMEDIATION COMMANDS"

$fixes = @"
# 1. Reset Windows Update components
net stop wuauserv & net stop cryptSvc & net stop bits & net stop msiserver
ren C:\Windows\SoftwareDistribution SoftwareDistribution.old
ren C:\Windows\System32\catroot2 catroot2.old
net start wuauserv & net start cryptSvc & net start bits & net start msiserver

# 2. Run SFC scan
sfc /scannow

# 3. Run DISM to repair component store
DISM /Online /Cleanup-Image /CheckHealth
DISM /Online /Cleanup-Image /ScanHealth
DISM /Online /Cleanup-Image /RestoreHealth

# 4. Free disk space
cleanmgr /sageset:1
cleanmgr /sagerun:1

# 5. Remove stuck update files
Remove-Item "C:\`$WINDOWS.~BT" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "C:\`$WINDOWS.~WS" -Recurse -Force -ErrorAction SilentlyContinue
"@

Write-Entry $fixes


# ─────────────────────────────────────────────
# Save report
# ─────────────────────────────────────────────
$report | Out-File -FilePath $reportFile -Encoding UTF8
Write-Host "`n✔ Report saved to: $reportFile" -ForegroundColor Green

if ($OpenReport) {
    Start-Process notepad.exe $reportFile
}

Write-Host "`nTip: Run again with -RunSetupDiag for deeper analysis using Microsoft's SetupDiag tool." -ForegroundColor DarkGray
Write-Host "Tip: Run with -OpenReport to open the report in Notepad automatically.`n" -ForegroundColor DarkGray
