// Phase 1 – RBAC
// Deploys at SUBSCRIPTION scope:
//   - rg-lab-sandbox-aue: a resource group used to test scoped access
//   - Reader on the SUBSCRIPTION            -> grp-lab-readers         (Carol)
//   - Virtual Machine Contributor on the RG -> grp-lab-vm-contributors (Bob)
//   - Custom role "Lab VM Operator" (start/restart/deallocate VMs only),
//     assigned on the RG                     -> grp-lab-helpdesk        (Alice)
//
// The group object IDs are looked up by deploy.sh and passed in as parameters.

targetScope = 'subscription'

param location string = 'australiaeast'
param owner string

@description('Object ID of grp-lab-readers')
param readersGroupId string

@description('Object ID of grp-lab-vm-contributors')
param vmContributorsGroupId string

@description('Object ID of grp-lab-helpdesk')
param helpdeskGroupId string

var tags = {
  env: 'lab'
  owner: owner
  project: 'az104'
  phase: '1'
}

// Built-in role IDs are the same in every tenant.
var readerRoleId = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
var vmContributorRoleId = '9980e02c-c2be-4d73-94e8-173b1dc7cf3c'

// ---------- Resource group to scope access to ----------

resource rgSandbox 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-lab-sandbox-aue'
  location: location
  tags: tags
}

// ---------- Subscription scope: Reader ----------

// Role assignment names must be GUIDs. guid() builds a stable one from its inputs,
// so redeploying updates the same assignment instead of creating duplicates.
resource readersAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, readersGroupId, readerRoleId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', readerRoleId)
    principalId: readersGroupId
    principalType: 'Group'
    description: 'Lab phase 1: auditors can view everything in the subscription'
  }
}

// ---------- Custom role ----------

resource vmOperatorRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: guid(subscription().id, 'lab-vm-operator')
  properties: {
    roleName: 'Lab VM Operator'
    description: 'Can view, start, restart and deallocate VMs. Cannot create, change or delete them.'
    type: 'CustomRole'
    permissions: [
      {
        actions: [
          'Microsoft.Resources/subscriptions/resourceGroups/read'
          'Microsoft.Compute/virtualMachines/read'
          'Microsoft.Compute/virtualMachines/instanceView/read'
          'Microsoft.Compute/virtualMachines/start/action'
          'Microsoft.Compute/virtualMachines/restart/action'
          'Microsoft.Compute/virtualMachines/deallocate/action'
        ]
        notActions: []
      }
    ]
    assignableScopes: [
      subscription().id
    ]
  }
}

// ---------- Resource group scope ----------

module vmContributorsAssignment 'modules/rg-role-assignment.bicep' = {
  name: 'ra-vm-contributors'
  scope: rgSandbox
  params: {
    principalId: vmContributorsGroupId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', vmContributorRoleId)
    assignmentDescription: 'Lab phase 1: developers manage VMs in the sandbox RG only'
  }
}

module helpdeskAssignment 'modules/rg-role-assignment.bicep' = {
  name: 'ra-helpdesk-vm-operator'
  scope: rgSandbox
  params: {
    principalId: helpdeskGroupId
    roleDefinitionId: vmOperatorRole.id
    assignmentDescription: 'Lab phase 1: helpdesk can start/stop VMs in the sandbox RG only'
  }
}

output sandboxResourceGroup string = rgSandbox.name
output customRoleId string = vmOperatorRole.id
