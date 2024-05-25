## Setting the script paramaters
param (
    [parameter(Mandatory = $true)]
    [String]$ExportPath
)
$DriveMappings = @()
## Looping through each domain specified in the domain variable
$Domains = (Get-ADForest).Domains
 
If($? -and $Domains -ne $Null)
{
    ForEach($Domain in $Domains) {
    
Write-Host "Checking GPO's on $($Domain)" -ForegroundColor Green

## Get list of all GPOs on domain
$AllGpos = Get-GPO -All -Domain $Domain

## Looping through each GPO
foreach ($Gpo in $AllGpos) {

## typecast XML results
$Reports = Get-GPOReport -Guid $Gpo.ID -ReportType Xml -Domain $Domain

ForEach ($Report In $Reports) {
  $GPO = ([xml]$Report).GPO
  $LinkCount = ([string[]]([xml]$Report).GPO.LinksTo).Count
  $Enabled = $GPO.User.Enabled
  ForEach ($ExtensionData In $GPO.User.ExtensionData) {
    If ($ExtensionData.Name -eq "Drive Maps") {
      $Mappings = $ExtensionData.Extension.DriveMapSettings.Drive
      ForEach ($Mapping In $Mappings) {
        $DriveMapping = New-Object PSObject -Property @{
          Domain      = $Domain
          GPO         = $GPO.Name
          LinkCount   = $LinkCount
          Enabled     = $Enabled
          DriveLetter = $Mapping.Properties.Letter + ":"
          Label       = $Mapping.Properties.label
          Path        = $Mapping.Properties.Path
        }
        $DriveMappings += $DriveMapping
     }
    }
   }
  }
 }
}
$DriveMappings | Select Domain,GPO,LinkCount,Enabled,DriveLetter,Label,Path | Export-Csv -Path $ExportPath\GPODriveMappingReport.csv -NoTypeInformation
}
