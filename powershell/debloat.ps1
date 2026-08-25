
$bloatwarePackages = @(
    "king.com.CandyCrush",
    "king.com.CandyCrushSaga"
)

foreach($package in $bloatwarePackages) {
    try {
        Get-ProvisionedAppxPackage -Online | Where-Object { $_.PackageName -like ($package + '*') } |
        Remove-ProvisionedAppxPackage -Online -ErrorAction SilentlyContinue
        Write-Host "Removed provisioned package: $package"
    }
    catch {
        Write-Host "Could not remove provisioned packages for $package : $_"
    }
}

Write-Host "`nRemoving provisioned packages..."

foreach($i in $bloatwarePackages){
	$bloat = '*' + ($i -split "\." | select -last 1) + '*'
	try {
		Get-ProvisionedAppxPackage -Online | Where-Object { $_.PackageName -like  $bloat } |
		Remove-ProvisionedAppxPackage -Online -ErrorAction SilentlyContinue
		Write-Host "Removed provisioned packages"
	}
	catch {
		Write-Host "Could not remove provisioned packages: $_"
	}
}
Write-Host "`nUninstall process complete."
