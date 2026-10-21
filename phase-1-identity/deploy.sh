#!/usr/bin/env bash
# Phase 1 – deploy RBAC (run create-identities.sh first).
set -euo pipefail
cd "$(dirname "$0")"

LOCATION="australiaeast"
NAME="phase1-rbac-$(date +%Y%m%d%H%M)"

# Look up each group's object ID: RBAC assigns roles to IDs, not names.
gid() { az ad group show --group "$1" --query id -o tsv; }
READERS=$(gid grp-lab-readers)
VMCONTRIB=$(gid grp-lab-vm-contributors)
HELPDESK=$(gid grp-lab-helpdesk)
OWNER=$(az ad signed-in-user show --query displayName -o tsv | tr ' ' '-' | tr '[:upper:]' '[:lower:]')

echo "Subscription: $(az account show --query name -o tsv)"
echo "Groups      : readers=$READERS"
echo "              vm-contributors=$VMCONTRIB"
echo "              helpdesk=$HELPDESK"

PARAMS=(owner="$OWNER" readersGroupId="$READERS" vmContributorsGroupId="$VMCONTRIB" helpdeskGroupId="$HELPDESK")

echo "== What-if preview =="
az deployment sub what-if -l "$LOCATION" -f main.bicep -p "${PARAMS[@]}"

read -rp "Deploy? [y/N] " ok
[[ "$ok" =~ ^[Yy]$ ]] || { echo "Cancelled."; exit 0; }

az deployment sub create -n "$NAME" -l "$LOCATION" -f main.bicep -p "${PARAMS[@]}" -o table

echo "== Role assignments created =="
for g in grp-lab-readers grp-lab-vm-contributors grp-lab-helpdesk; do
  az role assignment list --assignee "$(gid $g)" --all \
    --query "[].{group:'$g', role:roleDefinitionName, scope:scope}" -o table
done
