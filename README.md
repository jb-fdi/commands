Might require tls 1.2 forced on
``` [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 ```

Get list of failed logins 
```
(new-object Net.WebClient).DownloadString('https://raw.githubusercontent.com/jb-fdi/commands/main/powershell/getFailedLogins.ps1') | iex;
```

Get list of IPs failing to connect to server 
```
(new-object Net.WebClient).DownloadString('https://raw.githubusercontent.com/jb-fdi/commands/main/powershell/getInetfailedLogins.ps1') | iex;
```

Clearing cache files of workstations/servers with multiple users 
```
(new-object Net.WebClient).DownloadString('https://raw.githubusercontent.com/jb-fdi/commands/main/powershell/ClearCacheFiles.ps1') | iex;

```

Clearing temp, cache, and memory dump files
```
(new-object Net.WebClient).DownloadString('https://raw.githubusercontent.com/jb-fdi/commands/main/powershell/clearTempFiles.ps1') | iex;
```

Resetting vss services for veeam to run
```
(new-object Net.WebClient).DownloadString('https://raw.githubusercontent.com/jb-fdi/commands/main/powershell/VSSreset.ps1') | iex;
```

Webroot removal

```
(new-object Net.WebClient).DownloadString('https://raw.githubusercontent.com/jb-fdi/commands/refs/heads/main/powershell/webrootRemove.ps1') | iex;
```


# Linux

disk clean up

```
curl -sSL https://raw.githubusercontent.com/jb-fdi/debian/refs/heads/main/script/cleanup.sh | sudo bash
```
