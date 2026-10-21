# PowerShell – Notes

## 21 Oct 2026: first run against the lab
| Step | Command | Result |
|---|---|---|
| Inventory | `./Get-LabInventory.ps1` | "No resources found". Correct: policies, locks and budgets aren't resources, and the resource group was empty |
| Tag check | `./Test-TagCompliance.ps1` | 1 item checked, all compliant (`rg-lab-core-aue` has env, owner and project) |
| Create a non-compliant resource group | `New-AzResourceGroup -Name rg-test -Location australiaeast -Tag @{env='lab'}` | Created (passes the policy, because only `env` is enforced) |
| Tag check | `./Test-TagCompliance.ps1` | Caught `rg-test` missing `owner, project` |
| Fix | `Update-AzTag -ResourceId $rg.ResourceId -Tag @{owner='dcavanagh'; project='az104'} -Operation Merge` | Tag check came back all compliant |
| Break it | `Update-AzTag ... -Tag @{owner='dcavanagh'} -Operation Replace` | **Blocked by policy**: Replace would have removed `env` |
| Clean up | `Remove-AzResourceGroup -Name rg-test -Force` | `True` |

## Lessons
- `Get-AzResource` lists resources only. Resource groups, policies, locks and budgets don't appear in it.
- Tags in PowerShell are a hashtable: `@{key='value'; key2='value2'}`.
- Storing an object in a variable (`$rg = Get-AzResourceGroup ...`) lets you reuse its properties (`$rg.ResourceId`). PowerShell passes objects, not text.
- `Update-AzTag -Operation`: **Merge** adds or updates tags, **Replace** overwrites *all* tags, **Delete** removes the tags you list.
- **Deny policies check updates as well as new resources.** They stop a compliant resource becoming non-compliant later.
- `-Force` in PowerShell is like `--yes` in Azure CLI: it skips the confirmation prompt.
