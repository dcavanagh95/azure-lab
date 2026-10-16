// Resource-group lock. main.bicep runs at subscription scope, so anything that lives
// inside a resource group has to be deployed through a module with `scope: <resource group>`.

@description('Name of the lock.')
param lockName string

@allowed([
  'CanNotDelete'
  'ReadOnly'
])
param level string = 'CanNotDelete'

param notes string = ''

resource lock 'Microsoft.Authorization/locks@2020-05-01' = {
  name: lockName
  properties: {
    level: level
    notes: notes
  }
}
