#!/usr/bin/env bash
# Phase 0 – remove everything this phase created.
# Normally you KEEP Phase 0 running for the whole lab (it costs nothing).
set -euo pipefail

read -rp "Remove Phase 0 guardrails (policies, budget, lock, core RG)? [y/N] " ok
[[ "$ok" =~ ^[Yy]$ ]] || { echo "Cancelled."; exit 0; }

az lock delete -n lock-core-nodelete -g rg-lab-core-aue || true
for a in lab-allowed-locations lab-allowed-rg-locations lab-require-rg-tag; do
  az policy assignment delete -n "$a" || true
done
az consumption budget delete --budget-name budget-lab-monthly || true
az group delete -n rg-lab-core-aue --yes --no-wait || true
echo "Teardown started."
