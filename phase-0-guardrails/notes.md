# Phase 0 – Notes

## Break-it #1: resource group without the `env` tag
`az group create -n rg-test -l australiaeast`  →  **blocked**

How to read a policy error:
- **Code `RequestDisallowedByPolicy`**: Azure Policy blocked the request.
- **Which policy**: `policyAssignmentDisplayName`, here *Lab: require "env" tag on resource groups*.
- **Why it failed**: `evaluatedExpressions`. `tags[env]` with `Exists` was `false`, because the tag was missing.
- **Effect `deny`**: blocks the request outright. (`audit` would only flag it and still let it through.)
- **Scope**: `policyAssignmentScope` is the subscription, so the policy covers every resource group in it.

## Break-it #2: right tag, wrong region
`az group create -n rg-test -l westus --tags env=lab`  →  **blocked**
- Blocked by *Lab: allowed locations for resource groups*: `location` `westus` was `NotIn` `[australiaeast, australiasoutheast]`.
- The tag check passed this time. Each policy is evaluated separately.
- **Exam point:** the built-in *Allowed locations* policy does **not** apply to resource groups. You need the separate *Allowed locations for resource groups* policy.

## Break-it #3: right tag, right region
`az group create -n rg-test -l australiaeast --tags env=lab`  →  **succeeded**
- It passed both policies.

## Break-it #4: delete a locked resource group as Owner
`az group delete -n rg-lab-core-aue --yes`  →  **blocked**
- **Code `ScopeLocked`** (a lock), as opposed to `RequestDisallowedByPolicy` (a policy).
- The message says "cannot perform **delete** operation", which means a CanNotDelete lock.
- **Locks override RBAC.** Even an Owner must remove the lock first (needs `Microsoft.Authorization/locks/delete`).

## Break-it #5: ReadOnly lock
`az lock create -n ro -g rg-test --lock-type ReadOnly`, then `az group update -n rg-test --set tags.x=1`  →  **blocked**
- The message says "cannot perform **write** operation". ReadOnly blocks every change, even adding a tag.
- **Exam trap:** ReadOnly on a storage account also blocks *listing access keys*, because that's a POST (write) action.

## Break-it #6: clean up
`az lock delete -n ro -g rg-test`, then `az group delete -n rg-test --yes`  →  **succeeded** (no output means success)
- A lock has to be removed before the resource can be changed or deleted.

## Quick reference
| Error code | Cause | Fix |
|---|---|---|
| `RequestDisallowedByPolicy` | Azure Policy, `deny` effect | Meet the policy (tag, region…) or get an exemption |
| `ScopeLocked`: "delete operation" | CanNotDelete lock | Remove the lock, then delete |
| `ScopeLocked`: "write operation" | ReadOnly lock | Remove the lock, then make the change |
