## Setting the script paramaters
param (
    [parameter(Mandatory = $true)]
    [String]$ExportPath
)
$Results = @()
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
$GPOReports = Get-GPOReport -Guid $Gpo.ID -ReportType Xml -Domain $Domain
ForEach ($GPOReport In $GPOReports) {
  $GPO = ([xml]$GPOReport).GPO
  ForEach ($ExtensionData In $GPO.User.ExtensionData) {
    If ($ExtensionData.Name -eq "Scripts") {
      $Scripts = $ExtensionData.Extension.Script
      ForEach ($Script In $Scripts){
        $ReportLine = New-Object PSObject -Property @{
          Domain     = $Domain
          GPO        = $GPO.Name
          Command    = $Script.Command
          Parameters = $Script.Parameters
          Type       = $Script.Type
        }
        $Results += $ReportLine
      }
     }
    }
   }
  }
 }
}
$Results | Select Domain,GPO,Command,Parameters,Type | Export-Csv -Path $ExportPath\GPOScriptSettingsReport.Csv -NoTypeInformation