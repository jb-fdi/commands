# Requires: Microsoft.Graph module and ExchangeOnlineManagement module
# Install-Module Microsoft.Graph -Scope CurrentUser
# Install-Module ExchangeOnlineManagement -Scope CurrentUser


$appName = Read-Host "Enter the name for the new application"
$mailboxName = Read-Host "Enter the mailbox email the app will send as"


Connect-MgGraph 
Connect-ExchangeOnline 

$app = New-MgApplication -DisplayName $appName 

#Write-Host "Application registered: $($app.DisplayName)"
#Write-Host "Application (Client) ID: $($app.AppId)"
#Write-Host "Object ID: $($app.Id)"


$passwordCred = @{
   displayName = $appName
   endDateTime = (Get-Date).AddYears(1)
}

$secret = Add-MgApplicationPassword -applicationId $app.Id -PasswordCredential $passwordCred 
$sp = New-MgServicePrincipal -AppId $app.AppId

$exoSp = New-ServicePrincipal -AppId $sp.AppId -ObjectId $sp.Id

$exoSp | Set-ServicePrincipal -DisplayName "$appName-SP"

$scope = New-ManagementScope -Name "Scope_$($mailboxName.Split('@')[0])" `
    -RecipientRestrictionFilter "PrimarySmtpAddress -eq '$mailboxName'"

# Assign Application RBAC role
New-ManagementRoleAssignment -Name "AppSendAs_$($mailboxName.Split('@')[0])" `
    -Role "Application Mail.Send" `
    -App $app.AppId `
    -CustomResourceScope $scope.Name


# Test assignment
$result = Test-ServicePrincipalAuthorization -Identity $app.AppId -Resource $mailboxName
if ($result.InScope) {
    Write-Host "Success: The app can send as $mailboxName"

    Write-Host "Client Secret (store this safely, cannot be retrieved later): $($secret.SecretText)"

    Write-Host "`n=== Important ==="
    Write-Host "Store the following securely:"
    Write-Host "Application (Client) ID: $($app.AppId)"
    Write-Host "Tenant ID: $((Get-MgContext).TenantId)"
    Write-Host "Client Secret: $($secret.SecretText)"
    Write-Host "`nYou will need these for your application authentication."



} else {
    Write-Host "Warning: The app cannot send as $mailboxName"
}
