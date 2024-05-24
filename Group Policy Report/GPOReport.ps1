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
# Create a custom object holding all the information for each GPO component Version and Enabled state
foreach ($Gpo in $GPOs) {
    [xml]$GpReport = Get-GPOReport -ReportType Xml -Guid $Gpo.Id -Domain $Domain
# Create a custom object holding all the GPOs and their links
    foreach ($i in $GpReport.GPO.LinksTo){
    $ReportLine = New-Object PSObject -Property @{
        "Domain"= $Domain
        "GPO Name" = $GpReport.GPO.Name
        "Created Time" = $GpReport.GPO.CreatedTime
        "Modified Time" = $GpReport.GPO.ModifiedTime
        "WMIFilter Name" = $GPO.WmiFilter.Name
        "WMIFilter Path" = $GPO.WmiFilter.Path
        "Link" = $i.SOMPath
        "Link Enabled" = $i.Enabled
        "Comp Version" = $GpReport.GPO.Computer.VersionDirectory
        "Comp Sysvol" = $GpReport.GPO.Computer.VersionSysvol
        "Comp Enabled" = $GpReport.GPO.Computer.Enabled
        "User Version" = $GpReport.GPO.User.VersionDirectory
        "User Sysvol" = $GpReport.GPO.User.VersionSysvol
        "User Enabled" = $GpReport.GPO.User.Enabled
        }
    $Report +=$ReportLine
        }
       }
      }
     }
$Report| Select "Domain", "GPO Name", "Created Time", "Modified Time", "WMIFilter Name", "WMIFilter Path", "Link", "Link Enabled", "Comp Version", "Comp Sysvol", "Comp Enabled", "User Version", "User Sysvol", "User Enabled" | Export-Csv -Path $ExportPath\GPReport.csv -NoTypeInformation