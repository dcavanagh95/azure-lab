<#
.SYNOPSIS
    Lists every resource in the lab with its type, region, resource group and tags.

.DESCRIPTION
    A quick inventory of what is deployed. Handy at the start and end of each lab
    session to check nothing expensive has been left running.
    Optionally exports the results to a CSV file.

.PARAMETER ResourceGroupName
    Only list resources in this resource group. Leave it out to list the whole subscription.

.PARAMETER ExportPath
    If given, saves the results to this CSV file as well as showing them on screen.

.EXAMPLE
    ./Get-LabInventory.ps1
    Lists everything in the subscription.

.EXAMPLE
    ./Get-LabInventory.ps1 -ResourceGroupName rg-lab-core-aue -ExportPath ./inventory.csv
    Lists one resource group and saves it to a CSV.

.NOTES
    Run in Azure Cloud Shell (PowerShell), or locally after Connect-AzAccount.
    Needs the Az PowerShell module (already installed in Cloud Shell).
#>

# [CmdletBinding()] turns this script into an "advanced" script, so it gets the
# common parameters like -Verbose for free.
[CmdletBinding()]
param(
    [string]$ResourceGroupName,
    [string]$ExportPath
)

# Stop on any error instead of carrying on with half the data.
$ErrorActionPreference = 'Stop'

# Show which subscription we're about to inventory. Get-AzContext reads the
# current login without making any changes.
$context = Get-AzContext
if (-not $context) {
    throw 'Not logged in. Run Connect-AzAccount first (not needed in Cloud Shell).'
}
Write-Host "Subscription: $($context.Subscription.Name)" -ForegroundColor Cyan

# Get-AzResource returns every resource. If a resource group was given, we pass
# it through using "splatting": a hashtable of parameters prefixed with @.
$params = @{}
if ($ResourceGroupName) { $params.ResourceGroupName = $ResourceGroupName }
$resources = Get-AzResource @params

if (-not $resources) {
    Write-Host 'No resources found.' -ForegroundColor Yellow
    return
}

# Build a tidy object for each resource. Select-Object with @{Name=...;Expression=...}
# creates "calculated properties". Here we turn the Tags hashtable into readable
# text like "env=lab; owner=dcavanagh".
$inventory = $resources | Select-Object `
    Name,
    @{ Name = 'Type';          Expression = { $_.ResourceType } },
    @{ Name = 'ResourceGroup'; Expression = { $_.ResourceGroupName } },
    Location,
    @{ Name = 'Tags'; Expression = {
            if ($_.Tags) { ($_.Tags.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join '; ' }
            else { '(none)' }
        }
    } |
    Sort-Object ResourceGroup, Type, Name

# Show the results as a table on screen.
$inventory | Format-Table -AutoSize

# Summary: how many resources of each type. Group-Object counts them for us.
Write-Host "`nResource count by type:" -ForegroundColor Cyan
$inventory | Group-Object Type | Sort-Object Count -Descending |
    Format-Table @{ Name = 'Count'; Expression = { $_.Count } }, @{ Name = 'Type'; Expression = { $_.Name } } -AutoSize

# Optionally save to CSV so you can open it in Excel.
if ($ExportPath) {
    $inventory | Export-Csv -Path $ExportPath -NoTypeInformation
    Write-Host "Saved $($inventory.Count) resources to $ExportPath" -ForegroundColor Green
}
