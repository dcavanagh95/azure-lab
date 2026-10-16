# Phase 0 – Guardrails (Governance)

**Exam domain:** Manage Azure identities and governance (20–25%)
**Objectives covered:** resource groups, tags, resource locks, Azure Policy, cost management (budgets, alerts, Advisor), management groups
**Time:** ~2 hours  **Cost:** $0 (policies, locks, budgets and empty resource groups are free)

Build this first and leave it running for the whole lab. It stops you deploying to the wrong region and emails you before the bill gets out of hand.

---

## 1. Learn first (≈45 min)
On Microsoft Learn, work through the AZ-104 governance modules covering:
- Azure Policy
- Resource locks and tags
- Management groups
- Cost Management and budgets

Skills outline: https://learn.microsoft.com/certifications/resources/study-guides/az-104

## 2. Prerequisites
```bash
az login
az account list -o table
az account set --subscription "<your-subscription-name-or-id>"
az bicep install && az bicep version
```
Edit `main.bicepparam` and set your `owner` and `alertEmail`.

## 3. Management groups (CLI, manual)
These are created at tenant scope, so do them by hand to see how the hierarchy works.
```bash
az account management-group create --name mg-lab --display-name "Lab"
az account management-group subscription add --name mg-lab --subscription "<sub-id>"
az account management-group show --name mg-lab --expand -o jsonc
```
> If you get an authorisation error, open **Management groups** in the portal once. That initialises the tenant root group, after which the CLI works.

## 4. Deploy the guardrails
```bash
cd phase-0-guardrails
chmod +x deploy.sh teardown.sh
./deploy.sh
```
`what-if` runs first and shows exactly what will change. Read the output before you type `y`. It's the same habit the exam tests for ARM/Bicep.

## 5. Explore in the portal (≈20 min)
- **Policy → Assignments**: open each `Lab:` assignment, then look at its definition JSON. Find the `effect`.
- **Policy → Compliance**: it can take up to ~30 min to populate. To force a scan: `az policy state trigger-scan`
- **Cost Management → Budgets**: open `budget-lab-monthly` and look at the alert conditions.
- **Advisor**: note the categories (Cost, Security, Reliability, Operational excellence, Performance).
- **Resource groups → rg-lab-core-aue → Locks / Tags**.

## 6. Break it (this is where the learning sticks)
Do each one, read the full error, and write one line in `notes.md` about what you learned.

| # | Try this | Expect |
|---|---|---|
| 1 | `az group create -n rg-test -l australiaeast` | **Denied**: missing `env` tag. Find the policy name in the error. |
| 2 | `az group create -n rg-test -l westus --tags env=lab` | **Denied**: location not allowed. |
| 3 | `az group create -n rg-test -l australiaeast --tags env=lab` | Works. |
| 4 | `az group delete -n rg-lab-core-aue` | **Blocked by the lock**, even though you're Owner. |
| 5 | `az lock create -n ro -g rg-test --lock-type ReadOnly` then `az group update -n rg-test --set tags.x=1` | **Fails**: ReadOnly blocks all management-plane writes. |
| 6 | Remove the ReadOnly lock, then `az group delete -n rg-test --yes` | Works. |

## 7. Exam traps to remember
- **Locks override RBAC.** Even an Owner can't delete a locked resource. They have to remove the lock first.
- **Locks are inherited** by everything below the scope where they're applied.
- **ReadOnly is stronger than you'd think.** On a storage account, for example, it blocks *listing access keys* because that's a POST operation.
- **Tags are NOT inherited** from resource groups by default. You need a policy (for example *Inherit a tag from the resource group*, with the Modify effect) to make that happen.
- **Budgets only alert.** They don't stop spending on their own. You'd need an action group with automation for that.
- **Policy controls *what* can be deployed; RBAC controls *who* can do it.**
- **Policy assignments are inherited down the scope chain:** management group → subscription → resource group → resource.
- Existing non-compliant resources are **flagged, not deleted**, when a policy is assigned.
- The management group hierarchy can be **six levels** deep, not counting the root and subscription levels.

## 8. Done checklist
- [ ] `mg-lab` exists and contains your subscription
- [ ] Three `Lab:` policy assignments show in the portal
- [ ] Budget alerts point to your email
- [ ] `rg-lab-core-aue` has a CanNotDelete lock and four tags
- [ ] All six "break it" exercises done, with notes written
- [ ] Changes committed and pushed

## Teardown
Keep Phase 0 deployed for the whole lab. If you ever need to remove it: `./teardown.sh`
