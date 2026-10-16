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
