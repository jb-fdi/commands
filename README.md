
Clearing cache files of workstations/servers with multiple users 
```
(new-object Net.WebClient).DownloadString('https://raw.githubusercontent.com/jb-fdi/commands/main/ClearCachFiles.ps1') | iex;

clearCache
```

Clearing temp, cache, and memory dump files
```
(new-object Net.WebClient).DownloadString('https://raw.githubusercontent.com/jb-fdi/commands/main/clearTempFiles.ps1') | iex;

clearFiles
```

Resetting vss services for veeam to run
```
(new-object Net.WebClient).DownloadString('https://raw.githubusercontent.com/jb-fdi/commands/main/VSSreset.ps1') | iex;
```

