## Setting the script paramaters
param (

    [parameter(Mandatory = $true)]
    [String]$ExportPath
)

Function Get-AppSettings ($ExtData, $Gpo, $Scope){
  $Result = @()
  ForEach ($ExtensionData In $ExtData) {
    If ($ExtensionData.Name -eq "Software Installation") {
      $Apps = $ExtensionData.Extension.msiApplication
      ForEach ($App In $Apps) {
          $AppInstaller = New-Object PSObject -Property @{
          Domain= $Domain
          GPO = $GPO.Name
          LinkCount = $LinkCount
          Enabled = $Enabled
          Name = $App.name
          Path = $App.Path
          Scope = $Scope
          Type = $App.DeploymentType
          OutOfScope = $App.LossOfScopeAction
        }
        $Result += $AppInstaller
      }
    }
  }
  Write-Output $Result
}

$AppInstallers = @()
## Looping through each domain specified in the domain variable
$Domains = (Get-ADForest).Domains
 
If($? -and $Domains -ne $Null)
{
    ForEach($Domain in $Domains) {
    
Write-Host "Checking GPO's on $($Domain)" -ForegroundColor Green

## Get list of all GPOs on domain
$Gpos = Get-GPO -All -Domain $Domain

## Looping through each GPO
foreach ($Gpo in $Gpos) {

## typecast XML results
$Reports = Get-GPOReport -Guid $Gpo.ID -ReportType Xml -Domain $Domain

ForEach ($Report In $Reports) {
  $GPO = ([xml]$Report).GPO
  $LinkCount = ([string[]]([xml]$Report).GPO.LinksTo).Count
  $Enabled = $GPO.Computer.Enabled
  $ExtData = $GPO.Computer.ExtensionData
  $AppInstallers += Get-AppSettings $ExtData $GPO "Computer"
  $Enabled = $GPO.User.Enabled
  $ExtData = $GPO.User.ExtensionData
  $AppInstallers += Get-AppSettings $ExtData $GPO "User"
  }
 }
}
$AppInstallers | Select Domain,GPO,LinkCount,Enabled,Name,Path,Type,OutOfScope | Export-Csv -Path $ExportPath\GPOSoftwareInstalltionFolderReport.csv -NoTypeInformation
}