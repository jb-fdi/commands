$installerurl = read-host "enter the installer url"

if($installerurl -match "https://cloud.gravityzone.bitdefender.com"){
    new-item C:\utility -ItemType Directory -ErrorAction SilentlyContinue
    $path = 'c:\utility\'
    $fn = ($installerurl -split "/")[-1]

    invoke-restmethod $installerurl -OutFile ($path + 'temp.exe')

    Rename-Item -Path ($path + 'temp.exe') -NewName $fn

    start-process ($path + $fn) -argumentlist '/bdparams /silent'
}
