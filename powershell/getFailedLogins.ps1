$logs = Get-WinEvent -MaxEvents 10000 -FilterHashTable @{LogName="Security"; ID=4625}

$out = @()

foreach($i in $logs){
    $ohhhhh =$i.Message -split "`n" | where {$_ -match "Account Name:"} 

    foreach($k in $ohhhhh){

        $out += ($k -split "`t")[-1]
    }

}

$out | Group-Object -NoElement | sort count -Descending | out-gridview
