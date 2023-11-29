function clearFiles(){
  
  $start = (Get-Volume -DriveLetter c).SizeRemaining
  
  
  ### System files
  $zed = @(
      "C:\Windows\Temp\",
      "C:\Windows\SoftwareDistribution\Download\",
      "C:\temp\",
      'C:\ProgramData\Microsoft\Windows Defender\Definition Updates', 
      'C:\ProgramData\Microsoft\Windows Defender\Scans',
      'C:\ProgramData\Microsoft\Windows\WER',
      'C:\Windows\memory.dmp',
      'C:\Windows\Minidump.dmp'
  )
  
  foreach($i in $zed){
  
      if(test-path $i){
          if((get-item $i)  -is [System.IO.DirectoryInfo]){
              gci $i  -Recurse -ErrorAction SilentlyContinue | remove-item -Recurse -Force -Confirm:$False  -ErrorAction SilentlyContinue
          }else{
               get-item $i -ErrorAction SilentlyContinue | remove-item -Recurse -Force -Confirm:$False  -ErrorAction SilentlyContinue
          }
  
      }
  }
  
  #user cache files
  
  $skip = @(".NET v4.5", ".NET v4.5 Classic ","admin", "svc" ,"public", 'MSSQL$MICROSOFT##WID', 'svc', 'sql' )
  $post =@()
  $pre = get-childitem "c:\users" | where {$skip -notcontains $_.Name }
  
  foreach($i in $pre){
      $check = 0
  
      foreach($k in $skip){
          if($i.name -match $k){$check++}
      }
  
      if($check-eq 0){
          $post += $i.FullName 
      }
  }
  
  $locations = @(
          "\AppData\Local\Microsoft\Windows\Temporary Internet Files\Content.Outlook\", 
          "\AppData\Local\Microsoft\Windows\Temporary Internet Files\Content.IE5",
          "\AppData\Local\Microsoft\Windows\WER\ReportQueue\",
          "\AppData\Local\Google\Chrome\User Data\Default\Media Cache\",
          "\AppData\Local\Microsoft\Windows\Temporary Internet Files\Content.MSO\",
          "\AppData\Local\Temp\",
          "\AppData\Local\Spotify\Browser\Cache\"
  )
  
  foreach($user in $post){
       try{
          foreach($location in $locations){
          
            if(test-path $i){
                  $i = $user + $location
             
                  if(test-path $i){
                      if((get-item $i)  -is [System.IO.DirectoryInfo]){
                          gci $i  -Recurse -ErrorAction SilentlyContinue | remove-item -Recurse -Force -Confirm:$False  -ErrorAction SilentlyContinue
                      }else{
                              get-item $i -ErrorAction SilentlyContinue | remove-item -Recurse -Force -Confirm:$False  -ErrorAction SilentlyContinue
                      }
                  }
              }
          }
  
         $gcaches = get-childitem ($user + "\AppData\Local\Google\Chrome\User Data\Default\") -filter "*cache*" -force -ErrorAction SilentlyContinue
         foreach($gs in $gcaches.FullName){
              Get-ChildItem $gs -Force -Recurse | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
         }
        
         $tcaches = get-childitem ($user + "\AppData\Roaming\Microsoft\Teams\Service Worker\")  -filter "*cache*" -force -ErrorAction SilentlyContinue
         foreach($gs in $tcaches.FullName){
              Get-ChildItem $gs -Force -Recurse | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
         }
  
         $packages = gci ($user + "\AppData\Local\Packages\"  ) -Filter "*oice*"
  
         foreach ($package in $packages){
           gci ($package.FullName + "\AC\Temp\Diagnostics\") -Recurse -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
         }
  
      }catch{}
  }
  
  
  #Start-Process -FilePath CleanMgr.exe -ArgumentList '/sagerun:1' -NoNewWindow -Wait
  #Get-Process -Name cleanmgr, dismhost -ErrorAction SilentlyContinue | Wait-Process
  
  $end = (Get-Volume -DriveLetter c).SizeRemaining
  
  $fin = [math]::Round( (($end -$start )/1gb),3)
  
  write-host "space cleared: " $fin "GB" -BackgroundColor Black -ForegroundColor White
  


}
