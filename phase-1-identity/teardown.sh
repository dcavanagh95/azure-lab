#!/usr/bin/env bash
# Phase 1 – remove everything this phase created.
set -euo pipefail

read -rp "Remove Phase 1 (role assignments, custom role, sandbox RG, lab users and groups)? [y/N] " ok
[[ "$ok" =~ ^[Yy]$ ]] || { echo "Cancelled."; exit 0; }

# 1. Role assignments. A custom role can't be deleted while it's still assigned.
for g in grp-lab-readers grp-lab-vm-contributors grp-lab-helpdesk; do
  id=$(az ad group show --group "$g" --query id -o tsv 2>/dev/null || true)
  [[ -z "$id" ]] && continue
  # --all finds assignments at every scope (subscription AND resource group).
  ids=$(az role assignment list --assignee "$id" --all --query "[].id" -o tsv)
  [[ -n "$ids" ]] && az role assignment delete --ids $ids && echo "Removed role assignments for $g"
done

# 2. Custom role
az role definition delete --name "Lab VM Operator" 2>/dev/null || true

# 3. Sandbox resource group
az group delete -n rg-lab-sandbox-aue --yes --no-wait 2>/dev/null || true

# 4. Users and groups. Deleted users stay in "Deleted users" for 30 days and can be restored.
DOMAIN=$(az rest --method get --url "https://graph.microsoft.com/v1.0/domains" --query "value[?isDefault].id | [0]" -o tsv)
for u in lab.alice lab.bob lab.carol; do
  az ad user delete --id "$u@$DOMAIN" 2>/dev/null && echo "Deleted user $u" || true
done
for g in grp-lab-helpdesk grp-lab-vm-contributors grp-lab-readers; do
  az ad group delete --group "$g" 2>/dev/null && echo "Deleted group $g" || true
done
echo "Phase 1 teardown done."
