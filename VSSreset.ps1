$Service = @(
    "VSS"
    "Winmgmt"
    "SQLWriter"
    "MSExchangeIS"
)

foreach($i in $Service){
  if(  (Get-Service $i -ErrorAction SilentlyContinue).name -ne $null){
        Get-Service $i | stop-Service -Force
  }
}

sleep -s 30

foreach($i in $Service){
    $z = (get-process $i -erroraction SilentlyContinue)

    if($z.count -gt 0){
        foreach($p in $z){
          $cmd = "taskkill /f /im " + $p.id
          Invoke-Expression $cmd
        }
    
    }
}

sleep -s 30

foreach($i in $Service){
  if(  (Get-Service $i -ErrorAction SilentlyContinue).name -ne $null){
        Get-Service $i | start-Service
  }
}


#safety
sleep -s 45

Invoke-Expression "net start vmms"

foreach($i in $Service){
    if(((Get-Service $i -ErrorAction SilentlyContinue).name -ne $null) -and ((Get-Service $i -ErrorAction SilentlyContinue).Status -ne "Running") ){
            Get-Service $i | start-Service -Force
      }


}


get-service | where {$_.DisplayName -match "veeam"} | Start-Service
get-service | where {$_.DisplayName -match "veeam"} | Start-Service
get-service | where {$_.DisplayName -match "azure"} | Start-Service


foreach($i in $Service){
    Get-Service $i 
}
