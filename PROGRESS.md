# Progress log

## 16 Oct 2026 – Session 1
**Done**
- Created Azure free account (US$200 credit, valid for 30 days)
- Set up Cloud Shell (Bash, ephemeral) and registered resource providers
- Created management group `mg-lab` and moved the subscription into it
- Deployed Phase 0: 3 policies, lock on `rg-lab-core-aue`, monthly budget (30) with email alerts
- Break-it #1: tagless resource group blocked by policy (see `phase-0-guardrails/notes.md`)

**Next time, start here**
1. Open Cloud Shell (Bash) and run:
   `git clone https://github.com/dcavanagh95/azure-lab.git && cd azure-lab/phase-0-guardrails`
   You don't need to redeploy: Phase 0 is still live in Azure.
2. Break-it #2: `az group create -n rg-test -l westus --tags env=lab`
3. Finish break-it #3–6 from the Phase 0 README, then start Phase 1 (identity and RBAC)

## 20 Oct 2026
**Done**
- Added PowerShell admin scripts in `scripts/` (inventory, tag compliance, VM start/stop)

**Next time, start here**
1. Break-it #2 to #6 (Phase 0), in Cloud Shell **Bash**
2. Switch Cloud Shell to **PowerShell**, then run `./Get-LabInventory.ps1` and `./Test-TagCompliance.ps1` from `scripts/`
3. Start Phase 1 (identity and RBAC)

## 21 Oct 2026
**Done**
- Phase 0 break-it #2 to #6 complete. **Phase 0 finished** (see `phase-0-guardrails/notes.md`)

- Ran the PowerShell scripts against the lab: found, fixed and re-checked a non-compliant resource group (see `scripts/notes.md`)

**Next time, start here**
1. Start Phase 1 (identity and RBAC)
