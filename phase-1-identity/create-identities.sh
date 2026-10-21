#!/usr/bin/env bash
# Phase 1 – create Entra ID test users and groups.
#
# Entra ID (users, groups) lives in the TENANT, not in a subscription, so it isn't
# deployed with Bicep like Azure resources are. We use `az ad` commands instead.
#
# Creates:
#   Users  : lab.alice (Helpdesk), lab.bob (Developer), lab.carol (Auditor)
#   Groups : grp-lab-helpdesk, grp-lab-vm-contributors, grp-lab-readers
#
# Safe to re-run: anything that already exists is skipped.
set -euo pipefail

# Find the tenant's default domain (e.g. yourname.onmicrosoft.com) via Microsoft Graph.
DOMAIN=$(az rest --method get --url "https://graph.microsoft.com/v1.0/domains" \
  --query "value[?isDefault].id | [0]" -o tsv)
echo "Tenant domain: $DOMAIN"
echo

# user-alias : display name : job title : group
PEOPLE=(
  "lab.alice:Alice (Lab Helpdesk):Helpdesk:grp-lab-helpdesk"
  "lab.bob:Bob (Lab Developer):Developer:grp-lab-vm-contributors"
  "lab.carol:Carol (Lab Auditor):Auditor:grp-lab-readers"
)

# ---------- Groups ----------
for g in grp-lab-helpdesk grp-lab-vm-contributors grp-lab-readers; do
  if az ad group show --group "$g" -o none 2>/dev/null; then
    echo "Group exists : $g"
  else
    az ad group create --display-name "$g" --mail-nickname "$g" \
      --description "AZ-104 lab group (phase 1)" -o none
    echo "Group created: $g"
  fi
done
echo

# ---------- Users ----------
CREATED=()
for p in "${PEOPLE[@]}"; do
  IFS=":" read -r alias name title group <<< "$p"
  upn="$alias@$DOMAIN"

  if az ad user show --id "$upn" -o none 2>/dev/null; then
    echo "User exists  : $upn"
  else
    # Random password that meets Entra complexity rules. The user must change it
    # at first sign-in (--force-change-password-next-sign-in).
    pw="Lab!$(openssl rand -base64 9 | tr -dc 'A-Za-z0-9')9a"
    az ad user create --display-name "$name" --user-principal-name "$upn" \
      --password "$pw" --force-change-password-next-sign-in true -o none
    # `az ad` has no job-title flag, so set it by calling Microsoft Graph directly.
    az rest --method patch --url "https://graph.microsoft.com/v1.0/users/$upn" \
      --headers "Content-Type=application/json" --body "{\"jobTitle\": \"$title\"}" -o none || true
    echo "User created : $upn"
    CREATED+=("$upn  $pw")
  fi

  # Add the user to their group (skip if already a member).
  uid=$(az ad user show --id "$upn" --query id -o tsv)
  if [[ "$(az ad group member check --group "$group" --member-id "$uid" --query value -o tsv)" == "true" ]]; then
    echo "  already in $group"
  else
    az ad group member add --group "$group" --member-id "$uid"
    echo "  added to   $group"
  fi
done

# ---------- Summary ----------
echo
echo "== Group membership =="
for g in grp-lab-helpdesk grp-lab-vm-contributors grp-lab-readers; do
  printf '%-26s %s\n' "$g" "$(az ad group member list --group "$g" --query "[].userPrincipalName" -o tsv | tr '\n' ' ')"
done

if (( ${#CREATED[@]} > 0 )); then
  echo
  echo "== Temporary passwords (shown ONCE – write them down) =="
  printf '%s\n' "${CREATED[@]}"
  echo "Each user must set a new password at first sign-in."
fi
