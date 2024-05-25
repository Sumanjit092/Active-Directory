## Setting the script paramaters
param (

    [parameter(Mandatory = $true)]
    [String]$ExportPath
)

$Report = @()
Import-module ActiveDirectory
## Looping through each domain specified in the domain variable
$Domains = (Get-ADForest).Domains
 
If($? -and $Domains -ne $Null)
{
    ForEach($Domain in $Domains) {
    Write-Host "Checking GPO's on $($Domain)" -ForegroundColor Green
     
## Looping through each Group Policy

$GPOs = Get-GPO -Domain $Domain -All 
foreach ($GPO in $GPOs) {
    $Access= Get-GPPermissions -Guid $GPO.Id -Domain $Domain -All
    foreach ($Acc in $Access){
    $ReportLine= New-Object PSObject -Property @{ 
    Domain= $Domain
    GPOName= $GPO.DisplayName
    AccountDomain = $Acc.Trustee.Domain
    AccountName= $Acc.Trustee.Name
    AccountType= $Acc.Trustee.SidType.ToString()
    Permissions= $Acc.Permission
    }
    $Report +=$ReportLine
   }
  } 
 }
}
$Report| Select Domain, GPOName, AccountDomain, AccountName, AccountType, Permissions | Export-Csv -Path $ExportPath\GPODelegation.csv -NoTypeInformation
