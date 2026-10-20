<#
.SYNOPSIS
    Finds resource groups and resources that are missing required tags.

.DESCRIPTION
    The Phase 0 policy only enforces the "env" tag on resource groups, and tags are
    NOT inherited by the resources inside them. This script checks the lab's full
    tagging standard (env, owner, project) on both resource groups and resources,
    and reports anything that's missing.

.PARAMETER RequiredTags
    The tag names every resource group and resource should have.

.PARAMETER ResourceGroupName
    Only check this resource group. Leave it out to check the whole subscription.

.EXAMPLE
    ./Test-TagCompliance.ps1
    Checks the whole subscription against the default tags.

.EXAMPLE
    ./Test-TagCompliance.ps1 -RequiredTags env, owner
    Checks for just two tags.

.NOTES
    Exam link: tags are not inherited by default. Azure Policy with the "Modify"
    effect (e.g. "Inherit a tag from the resource group") can add them automatically.
#>

[CmdletBinding()]
param(
    [string[]]$RequiredTags = @('env', 'owner', 'project'),
    [string]$ResourceGroupName
)

$ErrorActionPreference = 'Stop'

# A small helper function: given an object's tags, return the required tag names
# that are missing. Tags can be $null when an object has none at all.
function Get-MissingTags {
    param($Tags, [string[]]$Required)
    foreach ($tag in $Required) {
        if (-not $Tags -or -not $Tags.ContainsKey($tag)) { $tag }
    }
}

# Collect the resource groups and resources to check.
if ($ResourceGroupName) {
    $groups    = @(Get-AzResourceGroup -Name $ResourceGroupName)
    $resources = @(Get-AzResource -ResourceGroupName $ResourceGroupName)
}
else {
    $groups    = @(Get-AzResourceGroup)
    $resources = @(Get-AzResource)
}

# Check each one and build a list of problems. [pscustomobject] makes a simple
# object with named properties, which prints nicely as a table.
$results = @()

foreach ($rg in $groups) {
    $missing = @(Get-MissingTags -Tags $rg.Tags -Required $RequiredTags)
    if ($missing.Count -gt 0) {
        $results += [pscustomobject]@{
            Kind        = 'ResourceGroup'
            Name        = $rg.ResourceGroupName
            Location    = $rg.Location
            MissingTags = $missing -join ', '
        }
    }
}

foreach ($res in $resources) {
    $missing = @(Get-MissingTags -Tags $res.Tags -Required $RequiredTags)
    if ($missing.Count -gt 0) {
        $results += [pscustomobject]@{
            Kind        = $res.ResourceType
            Name        = "$($res.ResourceGroupName)/$($res.Name)"
            Location    = $res.Location
            MissingTags = $missing -join ', '
        }
    }
}

# Report.
$checked = $groups.Count + $resources.Count
Write-Host "Checked $checked items for tags: $($RequiredTags -join ', ')" -ForegroundColor Cyan

if ($results.Count -eq 0) {
    Write-Host 'All compliant.' -ForegroundColor Green
}
else {
    Write-Host "$($results.Count) item(s) missing tags:" -ForegroundColor Yellow
    $results | Sort-Object Kind, Name | Format-Table -AutoSize -Wrap
    Write-Host 'Fix with: Update-AzTag -ResourceId <id> -Tag @{owner="you"} -Operation Merge' -ForegroundColor DarkGray
}
