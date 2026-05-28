if(test-path "c:\Program Files (x86)\webroot\wrsa.exe"){
    $path = "c:\Program Files (x86)\webroot\wrsa.exe"
}elseif(test-path "c:\Program Files\webroot\wrsa.exe"){
   $path = "c:\Program Files\webroot\wrsa.exe"
}else{
    exit
}


start-process $path -ArgumentList "-poll"  -wait
sleep 30
start-process $path -ArgumentList "-poll"  -wait
sleep 30
start-process $path -ArgumentList "-poll"  -wait
sleep 30

start-process $path -ArgumentList "-uninstall"  -wait
sleep 30

start-process "c:\program files (x86)\webroot\wrsa.exe" -argumentlist "/uninstall" -wait
sleep 30
# Removes Webroot SecureAnywhere by force
# Run the script once, reboot, then run again

# Webroot SecureAnywhere registry keys
$RegKeys = @(
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\WRUNINST",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\WRUNINST",
    "HKLM:\SOFTWARE\WOW6432Node\WRData",
    "HKLM:\SOFTWARE\WOW6432Node\webroot",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WRUNINST",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\WRUNINST",
    "HKLM:\SOFTWARE\WRData",
    "HKLM:\SOFTWARE\webroot",
    "HKLM:\SYSTEM\ControlSet001\services\WRSVC",
    "HKLM:\SYSTEM\ControlSet001\services\WRkrn",
    "HKLM:\SYSTEM\ControlSet001\services\WRBoot",
    "HKLM:\SYSTEM\ControlSet001\services\wrUrlFlt",
    "HKLM:\SYSTEM\ControlSet002\services\WRSVC",
    "HKLM:\SYSTEM\ControlSet002\services\WRkrn",
    "HKLM:\SYSTEM\ControlSet002\services\WRBoot",
    "HKLM:\SYSTEM\ControlSet002\services\wrUrlFlt",
    "HKLM:\SYSTEM\CurrentControlSet\services\WRSVC",
    "HKLM:\SYSTEM\CurrentControlSet\services\WRkrn",
    "HKLM:\SYSTEM\CurrentControlSet\services\WRBoot",
    "HKLM:\SYSTEM\CurrentControlSet\services\wrUrlFlt"
)

# Webroot SecureAnywhere startup registry item paths
$RegStartupPaths = @(
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
)

# Webroot SecureAnywhere folders
$Folders = @(
    "$env:ProgramData\WRData",
    "$env:ProgramFiles\Webroot",
    "${env:ProgramFiles(x86)}\Webroot",
    "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Webroot SecureAnywhere"
)

# Stop & Delete Webroot SecureAnywhere service
sc.exe stop WRSVC
sc.exe delete WRSVC

# Stop Webroot SecureAnywhere process
Stop-Process -Name "WRSA" -Force

# Remove Webroot SecureAnywhere registry keys
ForEach ($RegKey in $RegKeys) {
    Write-Host "Removing $RegKey"
    Remove-Item -Path $RegKey -Force -Recurse -ErrorAction SilentlyContinue
}

# Remove Webroot SecureAnywhere registry startup items
ForEach ($RegStartupPath in $RegStartupPaths) {
    Write-Host "Removing WRSVC from $RegStartupPath"
    Remove-ItemProperty -Path $RegStartupPath -Name "WRSVC"
}

# Remove Webroot SecureAnywhere folders
ForEach ($Folder in $Folders) {
    Write-Host "Removing $Folder"
    Remove-Item -Path "$Folder" -Force -Recurse -ErrorAction SilentlyContinue
}
