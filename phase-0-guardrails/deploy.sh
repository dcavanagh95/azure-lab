#!/usr/bin/env bash
# Phase 0 – deploy guardrails at subscription scope.
# Usage: ./deploy.sh            (what-if preview, then deploy)
set -euo pipefail
cd "$(dirname "$0")"

LOCATION="australiaeast"
NAME="phase0-guardrails-$(date +%Y%m%d%H%M)"

echo "Subscription: $(az account show --query '{name:name, id:id}' -o tsv)"

echo "== What-if preview =="
az deployment sub what-if -l "$LOCATION" -f main.bicep -p main.bicepparam

read -rp "Deploy? [y/N] " ok
[[ "$ok" =~ ^[Yy]$ ]] || { echo "Cancelled."; exit 0; }

az deployment sub create -n "$NAME" -l "$LOCATION" -f main.bicep -p main.bicepparam -o table

echo "== Check =="
az policy assignment list --query "[?starts_with(name,'lab-')].{name:name, display:displayName}" -o table
az lock list -g rg-lab-core-aue -o table
az consumption budget list --query "[].{name:name, amount:amount, grain:timeGrain}" -o table
