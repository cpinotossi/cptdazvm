targetScope='resourceGroup'

@description('Prefix used in the Naming for multiple Deployments in the same Subscription')
param prefix string

@description('Location of the virtual machine')
param location string


// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: prefix
  location: location
  properties:{
    addressSpace: {
      addressPrefixes:[
        '10.0.0.0/16'
      ]
    }
    subnets:[
      {
        name: prefix
        properties:{
          addressPrefix:'10.0.0.0/24'
          networkSecurityGroup:{
            id: nsg.id
          }
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties:{
          addressPrefix:'10.0.1.0/24'
        }
      }
    ]
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: prefix
  location: location
  properties:{
    securityRules:[
      {
        name: 'Heise'
        properties:{
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '193.99.144.85'
          access: 'Deny'
          priority: 110
          direction: 'Outbound'
        }
      }
    ]
  }
}
