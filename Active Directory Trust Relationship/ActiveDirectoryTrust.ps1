## Setting the script paramaters
param (

    [parameter(Mandatory = $true)]
    [String]$ExportPath
)

$Results= @()
Import-module ActiveDirectory
## Looping through each domain specified in the domain variable
$Domains = (Get-ADForest).Domains
 
If($? -and $Domains -ne $Null)
{
    ForEach($Domain in $Domains)
    { 
        Write-Host "Get list of AD Domain Trusts in $Domain" -ForegroundColor Yellow
        $ADDomainTrusts = Get-ADTrust -Filter {ObjectClass -eq "trustedDomain"} -Server $Domain -Properties * -EA 0
 
        If($? -and $ADDomainTrusts -ne $Null)
        {
            If($ADDomainTrusts -is [array])
            {
                [int]$ADDomainTrustsCount = $ADDomainTrusts.Count 
            }
            Else
            {
                [int]$ADDomainTrustsCount = 1
            }
             
            Write-Host "Discovered $ADDomainTrustsCount trusts in $Domain" -ForegroundColor Green
             
            ForEach($Trust in $ADDomainTrusts) 
            { 
                $TrustName = $Trust.Name 
                $TrustObjectClass = $Trust.ObjectClass 
                $TrustCreated = $Trust.Created 
                $TrustModified = $Trust.Modified
                $TrustSource= $Trust.Source
                $TrustTaget= $Trust.Target
                $TrustDirectionNumber = $Trust.TrustDirection
                $TrustTypeNumber = $Trust.TrustType
                $TrustAttributesNumber = $Trust.TrustAttributes
 
                #http://msdn.microsoft.com/en-us/library/cc220955.aspx
                
                Switch ($TrustTypeNumber) 
                { 
                    1 { $TrustType = "Downlevel (Windows NT domain external)"} 
                    2 { $TrustType = "Uplevel (Active Directory domain - parent-child, root domain, shortcut, external, or forest)"} 
                    3 { $TrustType = "MIT (non-Windows) Kerberos version 5 realm"} 
                    4 { $TrustType = "DCE (Theoretical trust type - DCE refers to Open Group's Distributed Computing Environment specification)"} 
                    Default { $TrustType = $TrustTypeNumber }
                } 
 
                #http://msdn.microsoft.com/en-us/library/cc223779.aspx

                Switch ($TrustAttributesNumber) 
                { 
                    1 { $TrustAttributes = "Non-Transitive"} 
                    2 { $TrustAttributes = "Uplevel clients only (Windows 2000 or newer"} 
                    4 { $TrustAttributes = "Quarantined Domain (External)"} 
                    8 { $TrustAttributes = "Forest Trust"} 
                    16 { $TrustAttributes = "Cross-Organizational Trust (Selective Authentication)"} 
                    32 { $TrustAttributes = "Intra-Forest Trust (Trust within the forest)"} 
                    64 { $TrustAttributes = "Inter-Forest Trust (Trust with another forest)"} 
                    Default { $TrustAttributes = $TrustAttributesNumber }
                }
                 
                #http://msdn.microsoft.com/en-us/library/cc223768.aspx

                Switch ($TrustDirectionNumber) 
                { 
                    0 { $TrustDirection = "Disabled (The trust relationship exists but has been disabled)"} 
                    1 { $TrustDirection = "Inbound (Trusting Domain)"} 
                    2 { $TrustDirection = "Outbound (Trusted Domain)"} 
                    3 { $TrustDirection = "Bidirectional (Two-Way Trust)"} 
                    Default { $TrustDirection = $TrustDirectionNumber }
                }
                        
                $ReportLine = New-Object PSObject -Property @{
                Domain= $Domain
                TrustName= $TrustName
                ObjectClass= $TrustObjectClass
                Created= $TrustCreated
                Modified= $TrustModified
                Source=$TrustSource
                Target=$TrustTaget
                Direction= $TrustDirection
                Type= $TrustType
                Attributes= $TrustAttributes}
                $Results += $ReportLine 
                
            } 

        }
        ElseIf(!$?)
        {
            #error retrieving domain trusts
            Write-Host "Error retrieving domain trusts for $Domain" -ForegroundColor Red
        }
        Else
        {
            #no domain trust data
            Write-Host "No domain trust data for $Domain" -ForegroundColor Magenta
        }
    } 
}
ElseIf(!$?)
{
    #error retrieving domains
    Write-Host "Error retrieving domains" -ForegroundColor Red
}
Else
{
    #no domain data
    Write-Host "No domain data" -ForegroundColor Magenta
}
$Results | Select Domain, TrustName, ObjectClass, Created, Modified, Source, Target, Direction, Type, Attributes | Export-Csv -Path $ExportPath\ActiveDirectoryTrust.csv
