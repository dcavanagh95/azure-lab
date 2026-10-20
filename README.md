# azure-lab

A hands-on Azure lab that grows phase by phase while studying for **AZ-104: Microsoft Azure Administrator**.
Everything is deployed with Azure CLI and Bicep, with PowerShell scripts for day-to-day admin, so any phase can be torn down and rebuilt in minutes.

## Study loop (every session)
1. **Learn**: do the Microsoft Learn module for the topic.
2. **Build**: deploy it here (portal once, then CLI/Bicep).
3. **Break it**: misconfigure something on purpose and fix it.
4. **Tear down**: delete anything that costs money; it's all in code.

## Phases
| Phase | Folder | Exam domain | Weight | Status |
|---|---|---|---|---|
| 0 | [`phase-0-guardrails`](phase-0-guardrails) | Identities & governance: policy, locks, tags, budgets, management groups | 20–25% | 🟡 Deployed, break-it in progress |
| 1 | `phase-1-identity` | Identities & governance: Entra users/groups, guests, RBAC, SSPR | | ⏳ |
| 2 | `phase-2-networking` | Virtual networking: hub-spoke, peering, NSG/ASG, UDR, DNS, Bastion | 15–20% | ⏳ |
| 3 | `phase-3-compute` | Compute: VMs, VMSS + load balancer, App Service, containers | 20–25% | ⏳ |
| 4 | `phase-4-storage` | Storage: blob tiers, lifecycle, SAS, private endpoints, Azure Files | 15–20% | ⏳ |
| 5 | `phase-5-monitoring` | Monitor & maintain: Log Analytics, KQL, alerts, backup, Network Watcher | 10–15% | ⏳ |
| — | [`scripts`](scripts) | PowerShell admin scripts: inventory, tag compliance, VM start/stop | all | ✅ Ready |

Exam skills outline (as of 17 April 2026): https://learn.microsoft.com/certifications/resources/study-guides/az-104

## Conventions
- **Region:** `australiaeast` (`australiasoutheast` for paired-region and DR work)
- **Naming:** `<type>-lab-<workload>-aue`, for example `rg-lab-core-aue` or `vnet-lab-hub-aue`
- **Tags on everything:** `env=lab`, `owner`, `project=az104`, `phase`

## Requirements
- Azure subscription
- Azure CLI with Bicep (`az bicep install`)
- Az PowerShell module, for `scripts/` (preinstalled in Cloud Shell)
- bash (macOS, Linux, WSL or Cloud Shell)

## Cost safety
- Phase 0 sets a monthly budget with email alerts. Deploy it first.
- Deallocate VMs after every session: `az vm deallocate -g <rg> -n <vm>`
- Delete Bastion, VPN gateways and load balancers when you're done with them.
