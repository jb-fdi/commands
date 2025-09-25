$installerurl = $args[0]

if($installerurl -match "https://cloud.gravityzone.bitdefender.com"){
    new-item C:\utility -ItemType Directory -ErrorAction SilentlyContinue
    $path = 'c:\utility\'
    $fn = ($installerurl -split "/")[-1]


    invoke-restmethod $installerurl -OutFile ($path + 'temp.exe')

    Rename-Item -Path ($path + 'temp.exe') -NewName $fn

    start-process ($path + $fn) -argumentlist '/bdparams /silent'
}else{
   write-host "No/Invalid Bitdefender URL provided"
}
