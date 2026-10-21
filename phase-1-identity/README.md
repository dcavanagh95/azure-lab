# Phase 1 – Identity and RBAC

**Exam domain:** Manage Azure identities and governance (20–25%)
**Objectives covered:** Entra ID users and groups, external (guest) users, self-service password reset, built-in roles, role assignments at different scopes, interpreting access, custom roles
**Time:** ~2–3 hours  **Cost:** $0 (users, groups, role assignments and empty resource groups are free)

You already manage Entra ID groups at work. This phase connects that to **Azure RBAC**: which groups can do what, to which resources.

---

## Two different permission systems (the big idea)
| | **Entra ID roles** | **Azure RBAC roles** |
|---|---|---|
| Controls | The directory: users, groups, licences, app registrations | Azure resources: VMs, storage, networks |
| Examples | Global Administrator, User Administrator, Helpdesk Administrator | Owner, Contributor, Reader, VM Contributor |
| Scope | Tenant (or administrative unit) | Management group → subscription → resource group → resource |

Being a Global Administrator does **not** automatically give you access to Azure resources, and being a subscription Owner gives you nothing in Entra ID. *(A Global Admin can "elevate access" to get User Access Administrator over all subscriptions, but that's a deliberate step.)*

## What gets built
| Who | Group | Role | Scope |
|---|---|---|---|
| Carol (Auditor) | `grp-lab-readers` | **Reader** (built-in) | Whole subscription |
| Bob (Developer) | `grp-lab-vm-contributors` | **Virtual Machine Contributor** (built-in) | `rg-lab-sandbox-aue` only |
| Alice (Helpdesk) | `grp-lab-helpdesk` | **Lab VM Operator** (custom: start/restart/deallocate only) | `rg-lab-sandbox-aue` only |

Roles are always assigned to **groups**, never directly to users. That's best practice and how it's done at work: add someone to a group and they get its access.

---

## 1. Learn first (≈1 hr)
On Microsoft Learn, work through the AZ-104 modules on:
- Microsoft Entra ID: users, groups, guest users
- Azure role-based access control (RBAC)
- Self-service password reset

## 2. Create the users and groups
In Cloud Shell (**Bash**):
```bash
cd azure-lab/phase-1-identity
chmod +x *.sh
./create-identities.sh
```
**Write down the three temporary passwords.** They're only shown once.

## 3. Deploy the RBAC
```bash
./deploy.sh
```
The what-if preview should show **5 to create**: 1 resource group, 1 custom role and 3 role assignments. Type **y**.

## 4. Look around in the portal (≈15 min)
- **Entra ID → Users**: open Alice. Check her **Groups** and **Azure role assignments**.
- **Subscriptions → your subscription → Access control (IAM) → Role assignments**: find Carol's group with Reader.
- **rg-lab-sandbox-aue → Access control (IAM) → Role assignments**: you'll see the RG-level assignments **plus inherited ones** from the subscription (Carol's Reader, your Owner).
- **IAM → Roles**: search "Lab VM Operator", open it and view its **Permissions** and JSON.

## 5. Break it
Signing in as a test user: open an **InPrivate/Incognito** window, go to https://portal.azure.com and sign in as e.g. `lab.carol@<your-domain>`. You'll be asked to set a new password. Your own session stays signed in in the normal window.

| # | Try this | Expect |
|---|---|---|
| 1 | **As Carol** (Reader): open the subscription, then try to create a resource group | She can **see** everything (including `rg-lab-core-aue`) but **can't create** anything: an authorization error |
| 2 | **As Bob** (VM Contributor on sandbox RG): look at the list of resource groups | He only sees `rg-lab-sandbox-aue`. **No access to anything outside his scope** |
| 3 | **As Bob**: in `rg-lab-sandbox-aue`, try to create a **storage account** | **Denied**: VM Contributor covers VMs, not storage |
| 4 | **As yourself**: `az role assignment list --assignee lab.bob@<your-domain> --all -o table` | **Empty!** Bob's access comes through his *group*, and this only lists *direct* assignments. Run it again with `--include-groups` and the role appears. Also try the portal: **rg-lab-sandbox-aue → IAM → Check access → Bob** |
| 5 | **As yourself**: remove Carol from `grp-lab-readers` (`az ad group member remove --group grp-lab-readers --member-id <carol-id>`), then refresh her InPrivate window | She **loses access**. It can take a few minutes, or a sign-out and sign-in, because her token is cached |
| 6 | **As yourself**: delete Bob (`az ad user delete --id lab.bob@<domain>`), then restore him in **Entra ID → Users → Deleted users** | He comes back **with his group memberships**. Deleted users are kept for **30 days** |

Write what you learned in `notes.md`.

## 6. Guest users (external identities)
Invite your own Gmail address as a guest, so you can see what a guest experiences:
```bash
az rest --method post --url "https://graph.microsoft.com/v1.0/invitations" \
  --headers "Content-Type=application/json" \
  --body '{"invitedUserEmailAddress":"<your-other-email>","inviteRedirectUrl":"https://portal.azure.com","sendInvitationMessage":true}'
```
Or use the portal: **Entra ID → Users → New user → Invite external user**.
- Check the email, accept the invite, and look at the guest in **Users**. Note **User type: Guest** and the `#EXT#` in its user principal name.
- **External collaboration settings** (Entra ID → External Identities) controls who can invite guests and what they can see.

## 7. Self-service password reset (optional)
SSPR for normal users needs **Entra ID P1 or P2**. You can start a free P1 trial in **Entra ID → Licenses → All products → Try / Buy** if you want to test it, but it's optional.
- **Entra ID → Password reset → Properties**: enable for **Selected** → `grp-lab-helpdesk`.
- **Authentication methods**: number of methods required (1 or 2), and which methods are allowed.
- Sign in as Alice and register at https://aka.ms/ssprsetup, then test at https://aka.ms/sspr.

## 8. Exam traps to remember
- **Entra ID roles ≠ Azure RBAC roles** (see the table above).
- **RBAC is inherited downwards:** management group → subscription → resource group → resource. You can't block inherited access with an RBAC assignment.
- **RBAC is additive:** your effective access is the **sum** of all your role assignments. Deny assignments exist, but you can't create them yourself (they come from things like Blueprints and managed apps).
- **Owner vs Contributor vs User Access Administrator:** Contributor can manage resources but **can't grant access**. User Access Administrator can **only** grant access. Owner can do both.
- **Custom roles:** `Actions` minus `NotActions` gives the allowed permissions. `assignableScopes` controls where the role can be assigned. **NotActions is not a deny**: another role can still grant the same permission.
- **`DataActions`** are for data inside resources (like reading blobs), separate from management `Actions`.
- **Dynamic groups** (membership by rules, e.g. `user.department -eq "IT"`) need **Entra ID P1**.
- **Group types:** *Security* (for access) vs *Microsoft 365* (mailbox, Teams, SharePoint). Membership: *Assigned*, *Dynamic user*, *Dynamic device*.
- **Deleted users and Microsoft 365 groups** can be restored for **30 days**.
- **Bulk operations** (portal): bulk create, invite and delete users from a CSV template.
- **Role assignment changes** can take up to ~10 minutes to apply. The user may need to sign out and back in.

## 9. Done checklist
- [ ] 3 users and 3 groups created, with each user in the right group
- [ ] RBAC deployed: Reader (subscription), VM Contributor (RG), custom role (RG)
- [ ] All six break-it exercises done, with notes written
- [ ] Guest invited and accepted
- [ ] (Optional) SSPR tested with a P1 trial

## Teardown
Leave Phase 1 in place for now. Later phases use the groups to test access. To remove it: `./teardown.sh`
