// Assigns a role to a group at RESOURCE GROUP scope.
// main.bicep runs at subscription scope, so RG-level assignments go through this module.

param principalId string

@description('Full resource ID of the role definition')
param roleDefinitionId string

param assignmentDescription string = ''

resource assignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalId, roleDefinitionId)
  properties: {
    roleDefinitionId: roleDefinitionId
    principalId: principalId
    principalType: 'Group'
    description: assignmentDescription
  }
}
