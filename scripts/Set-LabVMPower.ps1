<#
.SYNOPSIS
    Starts or stops (deallocates) all lab VMs in one command.

.DESCRIPTION
    Run "-Action Stop" at the end of every lab session so VMs stop costing money,
    and "-Action Start" when you come back. Only touches VMs tagged env=lab, so it
    can't accidentally hit anything else in the subscription.

.PARAMETER Action
    Start or Stop.

.PARAMETER ResourceGroupName
    Only act on VMs in this resource group. Leave it out for the whole subscription.

.PARAMETER TagName
    Tag used to pick out lab VMs. Default: env

.PARAMETER TagValue
    Value that tag must have. Default: lab

.EXAMPLE
    ./Set-LabVMPower.ps1 -Action Stop -WhatIf
    Shows which VMs WOULD be stopped, without changing anything.

.EXAMPLE
    ./Set-LabVMPower.ps1 -Action Stop
    Deallocates every running lab VM.

.NOTES
    Exam link: "Stopped" (shut down from inside the OS) still bills for compute.
    "Stopped (deallocated)" releases the hardware and stops compute billing.
    Stop-AzVM deallocates by default. Disks are still billed either way.
#>

# SupportsShouldProcess gives this script -WhatIf and -Confirm, just like the
# built-in cmdlets. Get in the habit: anything that changes resources should have it.
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Start', 'Stop')]
    [string]$Action,

    [string]$ResourceGroupName,
    [string]$TagName  = 'env',
    [string]$TagValue = 'lab'
)

$ErrorActionPreference = 'Stop'

# -Status adds the PowerState (running / deallocated) to each VM.
$params = @{ Status = $true }
if ($ResourceGroupName) { $params.ResourceGroupName = $ResourceGroupName }

# Keep only VMs with the lab tag. Where-Object filters a list.
$vms = @(Get-AzVM @params | Where-Object { $_.Tags -and $_.Tags[$TagName] -eq $TagValue })

if ($vms.Count -eq 0) {
    Write-Host "No VMs tagged $TagName=$TagValue found." -ForegroundColor Yellow
    return
}

foreach ($vm in $vms) {
    $state = $vm.PowerState   # e.g. "VM running" or "VM deallocated"

    if ($Action -eq 'Stop') {
        if ($state -eq 'VM deallocated') {
            Write-Host "Skip  $($vm.Name): already deallocated" -ForegroundColor DarkGray
            continue
        }
        # ShouldProcess is what makes -WhatIf work: it prints what would happen
        # and returns $false instead of running the command.
        if ($PSCmdlet.ShouldProcess($vm.Name, 'Stop (deallocate)')) {
            Write-Host "Stop  $($vm.Name) ($state)..." -ForegroundColor Cyan
            # -Force skips the "are you sure?" prompt. -NoWait returns straight away
            # so all VMs stop in parallel instead of one after another.
            Stop-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Force -NoWait | Out-Null
        }
    }
    else {
        if ($state -eq 'VM running') {
            Write-Host "Skip  $($vm.Name): already running" -ForegroundColor DarkGray
            continue
        }
        if ($PSCmdlet.ShouldProcess($vm.Name, 'Start')) {
            Write-Host "Start $($vm.Name) ($state)..." -ForegroundColor Cyan
            Start-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -NoWait | Out-Null
        }
    }
}

if (-not $WhatIfPreference) {
    Write-Host "`nRequests sent. Check progress with:" -ForegroundColor Green
    Write-Host '  Get-AzVM -Status | Select-Object Name, PowerState' -ForegroundColor Green
}
