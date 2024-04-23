targetScope='resourceGroup'

@description('Prefix used in the Naming for multiple Deployments in the same Subscription')
param prefix string
@description('object id of the user which will be assigned as virtual machine administrator role')
param userObjectId string
@description('Location of the virtual machine')
param location string

resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' existing = {
  name: prefix
}

resource vmaadextension 'Microsoft.Compute/virtualMachines/extensions@2023-07-01' = {
  parent: vm
  name: 'AADSSHLoginForLinux'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADSSHLoginForLinux'
    typeHandlerVersion: '1.0'
  }
}

var roleVirtualMachineAdministratorName = '1c0163c0-47e6-4577-8991-ea5c82e286e4' //Virtual Machine Administrator Login

resource raMe2VM 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id,prefix,'Virtual Machine Administrator Login')
  scope: vm
  properties: {
    principalId: userObjectId
    roleDefinitionId: tenantResourceId('Microsoft.Authorization/roleDefinitions',roleVirtualMachineAdministratorName)
  }
}
