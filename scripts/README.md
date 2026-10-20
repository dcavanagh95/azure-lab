# PowerShell admin scripts

Day-to-day admin scripts that run against the lab, using the **Az PowerShell module**.
Every line is commented, so reading them is part of learning PowerShell.

| Script | What it does | When to use it |
|---|---|---|
| `Get-LabInventory.ps1` | Lists every resource with type, region and tags; optional CSV export | Start and end of each session |
| `Test-TagCompliance.ps1` | Finds resource groups and resources missing `env`, `owner` or `project` tags | After deploying a new phase |
| `Set-LabVMPower.ps1` | Starts or deallocates all VMs tagged `env=lab`; supports `-WhatIf` | End of every session, from Phase 3 onwards |

## Running them in Cloud Shell
1. Open Cloud Shell and switch to **PowerShell** (dropdown at the top left of the shell).
2. Clone the repo and go to the scripts folder:
   ```powershell
   git clone https://github.com/dcavanagh95/azure-lab.git
   cd azure-lab/scripts
   ```
3. Run a script:
   ```powershell
   ./Get-LabInventory.ps1
   ./Test-TagCompliance.ps1
   ./Set-LabVMPower.ps1 -Action Stop -WhatIf
   ```
4. Every script has built-in help: `Get-Help ./Get-LabInventory.ps1 -Full`

## PowerShell concepts used (in order of difficulty)
- **Cmdlets** follow a `Verb-Noun` pattern: `Get-AzResource`, `Stop-AzVM`.
- **The pipeline** (`|`) passes objects, not text, from one cmdlet to the next.
- **`Where-Object` / `Select-Object` / `Sort-Object` / `Group-Object`** filter, shape, sort and count objects.
- **Parameters** (`param()` block), including `[ValidateSet()]` and `[Parameter(Mandatory)]`.
- **Splatting** (`@params`) passes a hashtable of parameters to a cmdlet.
- **Calculated properties** (`@{ Name=...; Expression={...} }`) add your own columns.
- **`SupportsShouldProcess`** gives a script `-WhatIf` and `-Confirm`, like the built-in cmdlets.

## CLI vs PowerShell (the exam shows both)
| Task | Azure CLI | Az PowerShell |
|---|---|---|
| List resources | `az resource list` | `Get-AzResource` |
| List resource groups | `az group list` | `Get-AzResourceGroup` |
| Stop (deallocate) a VM | `az vm deallocate -g RG -n VM` | `Stop-AzVM -ResourceGroupName RG -Name VM` |
| Start a VM | `az vm start -g RG -n VM` | `Start-AzVM -ResourceGroupName RG -Name VM` |
| Add or merge tags | `az tag update --resource-id ID --operation merge --tags k=v` | `Update-AzTag -ResourceId ID -Tag @{k='v'} -Operation Merge` |

> **Exam trap:** `az vm stop` only powers off the VM, and you **keep paying** for compute. Use `az vm deallocate`.
> In PowerShell, `Stop-AzVM` deallocates by default; `-StayProvisioned` gives the "stopped but still billed" state.
