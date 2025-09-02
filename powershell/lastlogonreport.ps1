<#
.SYNOPSIS
    Yet another report to get the date of when was a user's last time to log onto the domain
.DESCRIPTION
    Yet another report to get the date of when was a user's last time to log onto the domain, but this one is FAST.
    
    Most administrators know they can use LastLogonDate to get the last time a user logged into the domain.
    What you may not realize is how inaccurate this date is.  Active Directory does not automatically feed
    the logon data into this field, it instead logs it into the lastLogon field.  The problem here is lastLogon
    is not replicated between the domain controlles, so in 2003 Microsoft introduced LastLogonDate, which is
    replicated (though very slowly).  So you have two potential areas of lag, when AD updates LastLogonDate 
    from lastLogon, and how long it takes LastLogonDate to replicate to all domain controllers.  In larger
    environment's this can take as long as 11 days!  This renders the field useless in large environments.
    
    To solve this problem you have to get the lastLogon field from ALL domain controllers, convert it to 
    date/time and then keep the oldest date.  This can be a VERY slow process.  This script speeds this process
    up by retrieving all users from a domain controller all at once, and by multi-threading this process across
    all of the domain controllers.  It then collates the data and produces the desired report.  Supported reports 
    are object, CSV and HTML.
    
    In testing, 4,307 users across 14 domain controllers was completed in 1 minutes and 35 seconds.
    
    Additional customization of the HTML report is possible by editing the CSS located in the $Header variable
    below.
    
.PARAMETER SearchBase
    FQDN of the OU you wish to limit the reporting to.
.PARAMETER Age
    You can filter the report to only show users who haven't logged in in "x" days.
.PARAMETER HTML
    Designate you want an HTML report
.PARAMETER CSV
    Designate you want a CSV report
.PARAMETER Path
    Designate where you want the report to be saved.  If not specified the report will be saved in the same
    directory as the script.
.PARAMETER MaxThreads
    Limit the number of concurrent threads that are running.  In my testing the bottle neck was always waiting
    for the domain controllers to return information, so a high thread count is recommended.
.INPUTS
    None
.OUTPUTS
    HTML:               .\LastLogonReport-(current date).html
    CSV:                .\LastLogonReport-(current date).csv
    Object:             LastName
                        FirstName
                        DisplayName
                        SamAccountName
                        Enabled (true/false)
                        SetChangePassword (true/false)
                        LastLogonDate
        
.EXAMPLE
.EXAMPLE
.NOTES
    Author:             Martin Pugh
    Twitter:            @thesurlyadm1n
    Spiceworks:         Martin9700
    Blog:               www.thesurlyadmin.com
      
    Changelog:
        1.0             Initial Release
.LINK
    http://community.spiceworks.com/scripts/show/2618-last-logon-report-new-lastlogonreport-ps1
#>
#requires -Version 3.0
[CmdletBinding(DefaultParameterSetName="obj")]
Param (
    [Parameter(ParameterSetName="obj")]
    [Parameter(ParameterSetName="html")]
    [Parameter(ParameterSetName="csv")]
    [string]$SearchBase,
    
    [Parameter(ParameterSetName="obj")]
    [Parameter(ParameterSetName="html")]
    [Parameter(ParameterSetName="csv")]
    [int]$Age,
    
    [Parameter(ParameterSetName="html")]
    [switch]$HTML,
    
    [Parameter(ParameterSetName="csv")]
    [switch]$CSV,
    
    [Parameter(ParameterSetName="html")]
    [Parameter(ParameterSetName="csv")]
    [string]$Path,
    
    [Parameter(ParameterSetName="obj")]
    [Parameter(ParameterSetName="html")]
    [Parameter(ParameterSetName="csv")]
    [string]$MaxThreads = 15
)

#You can edit the CSS to match your style just keep the .odd and .even class names
$Header = @"
<style>
TABLE {border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}
TH {border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color: #6495ED;}
TD {border-width: 1px;padding: 3px;border-style: solid;border-color: black;}
.odd  { background-color:#ffffff; }
.even { background-color:#dddddd; }
</style>
"@



cls
Write-Verbose "$(Get-Date): New-LastLogonReport script started"

#Functions
Function Set-AlternatingRows {
	<#
	.SYNOPSIS
		Simple function to alternate the row colors in an HTML table
	.LINK
		http://community.spiceworks.com/scripts/show/1745-set-alternatingrows-function-modify-your-html-table-to-have-alternating-row-colors
	#>
    [CmdletBinding()]
   	Param(
       	[Parameter(Mandatory,ValueFromPipeline)]
        [string]$Line,
       
   	    [Parameter(Mandatory)]
       	[string]$CSSEvenClass,
       
        [Parameter(Mandatory)]
   	    [string]$CSSOddClass
   	)
	Begin {
		$ClassName = $CSSEvenClass
	}
	Process {
		If ($Line.Contains("<tr><td>"))
		{	$Line = $Line.Replace("<tr>","<tr class=""$ClassName"">")
			If ($ClassName -eq $CSSEvenClass)
			{	$ClassName = $CSSOddClass
			}
			Else
			{	$ClassName = $CSSEvenClass
			}
		}
		Return $Line
	}
}

$Select = @{}
$Jobs = @()

#Validation
If ($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent)
{   Write-Verbose "$(Get-Date): Debug switch detected, only scanning the first 4 DC's"
    $Select.Add("First",4)
}

Try {
    Write-Verbose "$(Get-Date): Getting domain information..."
    $Domain = (Get-ADDomain -ErrorAction Stop).NetBIOSName
}
Catch {
    Write-Warning "$(Get-Date): Problem getting domain information because ""$($Error[0])"""
    Exit
}

If ($SearchBase)
{   Try {
        Get-ADOrganizationalUnit $SearchBase -ErrorAction Stop | Out-Null
    }
    Catch {
        Write-Warning "$(Get-Date): Unable to locate $SearchBase OU in $Domain"
        Exit
    }
}

If ($Path)
{   If (-not (Test-Path $Path))
    {   Write-Warning "$(Get-Date): Unable to locate $Path"
        Exit
    }
}
Else
{   $Path = Split-Path $MyInvocation.MyCommand.Path
}

#Loop through the DC's for user information
ForEach ($DC in (Get-ADDomainController -Filter * | Select -ExpandProperty HostName | Select @Select))
{   Write-Verbose "$(Get-Date): Retrieving users from domain controller $DC in $Domain"
    
    While (@(Get-Job | Where State -eq "Running").Count -ge $MaxThreads) {
       Write-Verbose "$(Get-Date): Waiting for open thread...($MaxThreads Maximum)"
       Start-Sleep -Seconds 3
    }
    
    $Jobs += Start-Job -ArgumentList $SearchBase,$DC -ScriptBlock {
        Param (
            [string]$SearchBase,
            [string]$DC
        )
        
        $Params = @{
            Filter = "*"
            Server = $DC
            Properties = "LastLogon","PwdLastSet"
            ErrorAction = "Stop"
        }
        If ($SearchBase)
        {   $Params.Add("SearchBase",$SearchBase)
        }
        
        Try {
            Get-ADUser @Params | Select Surname,GivenName,Name,distinguishedName,LastLogon,SamAccountName,@{Name="DC";Expression={$DC}},Enabled,PwdLastSet
        }
        Catch {
            [PSCustomObject]@{
                DC = $DC
            }
            Throw "$(Get-Date): Unable to contact $DC because ""$($Error[0])"""
        }
    }
}

Write-Verbose "$(Get-Date): Waiting for background jobs to finish (this could take awhile)"
$Jobs | Wait-Job | Out-Null
$DomainUsers = @()
ForEach ($Job in $Jobs)
{   If ($Job.State -eq "Failed")
    {   $JobData = Receive-Job $Job 2>$null
        Write-Warning "$($Error[0])"
    }
    Else
    {   $DomainUsers += Receive-Job $Job
    }
    $Job | Remove-Job | Out-Null
}

Write-Verbose "$(Get-Date): Processing $($DomainUsers.Count) records...(#User * #DomainControllers)"
$Users = @{}
ForEach ($User in $DomainUsers)
{   $LastLogon = [datetime]::FromFileTime($User.LastLogon)
    If ($Users.ContainsKey($User.distinguishedName))
    {   If ($LastLogon -gt $Users[$User.distinguishedName].LastLogonDate -and $LastLogon -ne [datetime]"12/31/1600 7:00:00 pm")
        {   $Users[$User.distinguishedName].LastLogonDate = $LastLogon
        }
    }
    Else
    {   $Users.Add($User.distinguishedName,($User | 
            Select @{Name="LastName";Expression={$_.Surname}},@{Name="FirstName";Expression={$_.GivenName}},@{Name="DisplayName";Expression={$_.Name}},SamAccountName,Enabled,@{Name="SetChangePassword";Expression={($_.PwdLastSet -eq 0)}},@{Name="LastLogonDate";Expression={If ($LastLogon -eq [datetime]"12/31/1600 7:00:00 pm") { $null } Else { $LastLogon }}}))
    }
}

#Produce the reports based on parameter settings
If ($Age)
{   $Results = $Users.Values | Where LastLogonDate -LE ((Get-Date).AddDays(-$Age)).Date | Sort LastLogonDate -Descending
}
Else
{   $Results = $Users.Values | Sort LastLogonDate -Descending
}

If ($HTML)
{   $FilePath = Join-Path -Path $Path -ChildPath "LastLogonReport-$(Get-Date -format 'MM-dd-yy-hh-mm').html"
    Write-Verbose "$(Get-Date): Producing HTML report at $FilePath"
    Try {
        $Results | ConvertTo-Html -Head $Header -PreContent "<p><h2>Last Logon Report</h2></p>" -PostContent "<p><br /><h4>Run on: $(Get-Date)</h4></p>" | Set-AlternatingRows -CSSEvenClass even -CSSOddClass odd | Out-File $FilePath -Encoding ASCII
    }
    Catch {
        Write-Warning "$(Get-Date): Unable to save $FilePath because ""$($Error[0])"""
        Exit
    }
}
ElseIf ($CSV)
{   $FilePath = Join-Path -Path $Path -ChildPath "LastLogonReport-$(Get-Date -format 'MM-dd-yy-hh-mm').csv"
    Write-Verbose "$(Get-Date): Producing CSV report at $FilePath"
    Try {
        $Results | Export-Csv $FilePath -NoTypeInformation
    }
    Catch {
        Write-Warning "$(Get-Date): Unable to save $FilePath because ""$($Error[0])"""
        Exit
    }
}
Else
{   $Results
}

#In debug mode, open the report file (if any)
If ($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent -and $FilePath)
{   & $FilePath
}
    
Write-Verbose "$(Get-Date): Script completed!"
