# Phase 0 – Notes

## Break-it #1: resource group without the `env` tag
`az group create -n rg-test -l australiaeast`  →  **blocked**

How to read a policy error:
- **Code `RequestDisallowedByPolicy`**: Azure Policy blocked the request.
- **Which policy**: `policyAssignmentDisplayName`, here *Lab: require "env" tag on resource groups*.
- **Why it failed**: `evaluatedExpressions`. `tags[env]` with `Exists` was `false`, because the tag was missing.
- **Effect `deny`**: blocks the request outright. (`audit` would only flag it and still let it through.)
- **Scope**: `policyAssignmentScope` is the subscription, so the policy covers every resource group in it.

## Break-it #2: wrong region
`az group create -n rg-test -l westus --tags env=lab`
- Prediction:
- Result:
- Lesson:

## Break-it #3–6
(fill in as you go)
