function clearCache(){
  $start = (Get-Volume -DriveLetter c).SizeRemaining
  $post =@()
  $pre = get-childitem "c:\users" | where {$skip -notcontains $_.Name }
  
  
  $OldFilesData = (Get-Date).AddDays(-14)
  # Complete cleanup of cache folders
  $clear_paths = @(
      'AppData\Local\Temp'
      'AppData\Local\Microsoft\Terminal Server Client\Cache'
      'AppData\Local\Microsoft\Windows\WER'
      'AppData\Local\Microsoft\Windows\AppCache'
      'AppData\Roaming\Microsoft\Teams\Service Worker\CacheStorage'
      'AppData\Local\CrashDumps'
      'AppData\Local\Google\Chrome\User Data\Default\Cache'
      'AppData\Local\Google\Chrome\User Data\Default\Cache2\entries'
      'AppData\Local\Google\Chrome\User Data\Default\Cookies'
      'AppData\Local\Google\Chrome\User Data\Default\Media Cache'
      'AppData\Local\Google\Chrome\User Data\Default\Cookies-Journal'
      'AppData\Local\Google\Chrome\User Data\Default\Service Worker\CacheStorage\'
      'AppData\Local\Microsoft\Windows\Temporary Internet Files\Content.Outlook\'
      'AppData\Local\Microsoft\Windows\Temporary Internet Files\Content.IE5'
      'AppData\Local\Microsoft\Windows\WER\ReportQueue\'
      'AppData\Local\Google\Chrome\User Data\Default\Media Cache\'
      'AppData\Local\Microsoft\Windows\Temporary Internet Files\Content.MSO\'
      'AppData\Local\Temp\'
      'AppData\Local\Spotify\Browser\Cache\'
      'AppData\Local\Microsoft\Windows\INetCache\IE\'
      'AppData\Local\Microsoft\Windows\webcache\'
      'AppData\Roaming\Mozilla\Firefox\Profiles\*\storage\default\*\cache\'
      'AppData\Roaming\Microsoft\Teams\Service Worker\CacheStorage\'
      'AppData\Roaming\Microsoft\Teams\Code Cache\js'
      'AppData\Local\Microsoft\Windows\INetCache\Content.Outlook\'
      'AppData\Local\WebEx\wbxcache\'
      'AppData\Roaming\Zoom\logs\'
      'AppData\Roaming\Microsoft\Teams\Code Cache\js\'
      'AppData\Local\Microsoft\Edge\User Data\Default\Service Worker\CacheStorage\'
      'AppData\Roaming\Microsoft\Teams\Cache\Cache_Data\'
      '\AppData\Local\Microsoft\Office\16.0\Wef\webview2\*\1\EBWebView\Default\Cache\Cache_Data\'
      '\AppData\Local\Google\Chrome\User Data\*\Code Cache\*\'
      '\AppData\Local\Google\Chrome\User Data\*\Cache\Cache_Data\'
      '\AppData\Roaming\Slack\Service Worker\CacheStorage\*'
  
  )
  
  # If you want to clear the Google Chrome cache folder, stop the chrome.exe process
  $currentuser = $env:UserDomain + "\"+ $env:UserName
  
  foreach($i in (gci C:\Users | where {$_.name -notin @(".NET v4.5",".NET v4.5 Classic","Administrator","public")} | where {$_.name -notmatch '\$'})){
     
  
      ForEach ($path In $clear_paths) {
          If ((Test-Path -Path "$($i.FullName)\$path") -eq $true) {
                
              Get-ChildItem -Path "$($i.FullName)\$path" -Recurse -Force -ErrorAction SilentlyContinue | ? {!$_.pscontainer} | remove-item -Force -Confirm:$false -Recurse -ErrorAction SilentlyContinue
          }
      }
  
  }
  
  
  $end = (Get-Volume -DriveLetter c).SizeRemaining
  $fin = [math]::Round( (($end -$start )/1gb),3)
  
  write-host "space cleared: " $fin "GB" -BackgroundColor Black -ForegroundColor White
}
