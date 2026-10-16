// Phase 0 – Guardrails
// Deploys at SUBSCRIPTION scope:
//   - core resource group (tagged) with a CanNotDelete lock
//   - monthly cost budget with email alerts
//   - Azure Policy: allowed locations, allowed RG locations, required tag on RGs
//
// Deploy:
//   az deployment sub create -l australiaeast -f main.bicep -p main.bicepparam

targetScope = 'subscription'

@description('Primary region for the lab.')
param location string = 'australiaeast'

@description('Regions the lab is allowed to use (enforced by Azure Policy).')
param allowedLocations array = [
  'australiaeast'
  'australiasoutheast'
]

@description('Your name/alias – written into the owner tag.')
param owner string

@description('Email that receives budget alerts.')
param alertEmail string

@description('Monthly budget amount, in your billing currency.')
param budgetAmount int = 30

@description('Budget start date: first day of a month, yyyy-MM-01. Keep it fixed – it cannot change after the budget is created.')
param budgetStartDate string = '2026-10-01'

@description('Tag every resource group must carry (enforced by policy).')
param requiredTagName string = 'env'

var tags = {
  env: 'lab'
  owner: owner
  project: 'az104'
  phase: '0'
}

// ---------- Resource group + lock ----------

resource rgCore 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-lab-core-aue'
  location: location
  tags: tags
}

module coreLock 'modules/lock.bicep' = {
  name: 'core-rg-lock'
  scope: rgCore
  params: {
    lockName: 'lock-core-nodelete'
    notes: 'Phase 0: protects shared lab resources. Remove with: az lock delete'
  }
}

// ---------- Budget ----------

resource budget 'Microsoft.Consumption/budgets@2023-11-01' = {
  name: 'budget-lab-monthly'
  properties: {
    category: 'Cost'
    amount: budgetAmount
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: budgetStartDate
    }
    notifications: {
      actual50: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 50
        thresholdType: 'Actual'
        contactEmails: [ alertEmail ]
      }
      actual90: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 90
        thresholdType: 'Actual'
        contactEmails: [ alertEmail ]
      }
      forecast100: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 100
        thresholdType: 'Forecasted'
        contactEmails: [ alertEmail ]
      }
    }
  }
}

// ---------- Azure Policy (built-in definitions) ----------

// Built-in: "Allowed locations" (resources)
resource polAllowedLocations 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'lab-allowed-locations'
  properties: {
    displayName: 'Lab: allowed locations for resources'
    policyDefinitionId: tenantResourceId('Microsoft.Authorization/policyDefinitions', 'e56962a6-4747-49cd-b67b-bf8b01975c4c')
    parameters: {
      listOfAllowedLocations: { value: allowedLocations }
    }
  }
}

// Built-in: "Allowed locations for resource groups"
resource polAllowedRgLocations 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'lab-allowed-rg-locations'
  properties: {
    displayName: 'Lab: allowed locations for resource groups'
    policyDefinitionId: tenantResourceId('Microsoft.Authorization/policyDefinitions', 'e765b5de-1225-4ba3-bd56-1ac6695af988')
    parameters: {
      listOfAllowedLocations: { value: allowedLocations }
    }
  }
}

// Built-in: "Require a tag on resource groups"
resource polRequireRgTag 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'lab-require-rg-tag'
  properties: {
    displayName: 'Lab: require "${requiredTagName}" tag on resource groups'
    policyDefinitionId: tenantResourceId('Microsoft.Authorization/policyDefinitions', '96670d01-0a4d-4649-9c89-2d3abc0a5025')
    parameters: {
      tagName: { value: requiredTagName }
    }
  }
}

output coreResourceGroup string = rgCore.name
output policyAssignments array = [
  polAllowedLocations.name
  polAllowedRgLocations.name
  polRequireRgTag.name
]
