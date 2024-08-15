$log =  (gci C:\inetpub\logs\LogFiles\W3SVC1\ | sort LastWriteTime -Descending)[0].FullName

$raw = Get-Content $log
$out = @()

$regex = [regex] "\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b"


foreach($i in $raw){

    foreach($k in ($i -split " ")){
        if($k -match $regex){
            $out += $k
        }

    }
}

$tested = @()
foreach($i in $out){

     if ($i -notMatch '(^127\.)|(^192\.168\.)|(^10\.)|(^172\.1[6-9]\.)|(^172\.2[0-9]\.)|(^172\.3[0-1]\.)') {
           if($i.split("/").count -le 1){
           
            $tested +=$i
            }
        }


}

$tested | Group-Object -NoElement | sort count -Descending| out-gridview

