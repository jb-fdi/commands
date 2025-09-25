# Might require tls 1.2 forced on
``` [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 ```

## Silent Install BitDefender
You will need to pass a bitdefender url found in the [download links](https://www.bitdefender.com/business/support/en/77209-158546-installing-and-configuring-bitdefender-endpoint-security-tools-for-vmware-tanzu.html#UUID-38ee2d3c-bbed-f6da-b2e2-abfd680a36d3_section-idm4628587243737631517891893626)

```
(new-object Net.WebClient).DownloadString('https://raw.githubusercontent.com/jb-fdi/commands/refs/heads/main/powershell/BitdefenderInstaller.ps1') | iex;

```
Example:  (new-object Net.WebClient).DownloadString('https://raw.githubusercontent.com/jb-fdi/commands/refs/heads/main/powershell/BitdefenderInstaller.ps1') | iex; InstallBitdefender -url <bitdefender url>


## Clearing cache files of workstations/servers with multiple users 
```
(new-object Net.WebClient).DownloadString('https://raw.githubusercontent.com/jb-fdi/commands/main/powershell/ClearCacheFiles.ps1') | iex;

```

## Clearing temp, cache, and memory dump files
```
(new-object Net.WebClient).DownloadString('https://raw.githubusercontent.com/jb-fdi/commands/main/powershell/clearTempFiles.ps1') | iex;
```

## Resetting vss services for veeam to run
```
(new-object Net.WebClient).DownloadString('https://raw.githubusercontent.com/jb-fdi/commands/main/powershell/VSSreset.ps1') | iex;
```

##Webroot removal

```
(new-object Net.WebClient).DownloadString('https://raw.githubusercontent.com/jb-fdi/commands/refs/heads/main/powershell/webrootRemove.ps1') | iex;
```

# windows server

## Get list of IPs failing to connect to server 
```
(new-object Net.WebClient).DownloadString('https://raw.githubusercontent.com/jb-fdi/commands/main/powershell/getInetfailedLogins.ps1') | iex;
```

## Get list of failed logins 
```
(new-object Net.WebClient).DownloadString('https://raw.githubusercontent.com/jb-fdi/commands/main/powershell/getFailedLogins.ps1') | iex;
```
## Generate last logon report
```
(new-object Net.WebClient).DownloadString('https://raw.githubusercontent.com/jb-fdi/commands/refs/heads/main/powershell/lastlogonreport.ps1') | iex;
```

# Linux

## disk clean up

```
curl -sSL https://raw.githubusercontent.com/jb-fdi/debian/refs/heads/main/script/cleanup.sh | sudo bash
```
