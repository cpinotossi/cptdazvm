targetScope='resourceGroup'

@description('Prefix used in the Naming for multiple Deployments in the same Subscription')
param prefix string

@description('Location of the virtual machine')
param location string

resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' existing = {
  name: prefix
}

resource vmNameextenstion'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = {
  parent: vm
  name: 'installcustomscript'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      commandToExecute: 'echo "this has been written via cloud-init" + $(date) >> /home/chpinoto/test3.txt'
    }
  }
}
