targetScope='resourceGroup'

param location string
@description('Prefix used in the Naming for multiple Deployments in the same Subscription')
param prefix string
@description('Admin user variable')
param adminUsername string
@secure()
@description('Admin password variable')
param adminPassword string
@description('cloud-init script to be executed on the virtual machine')
param customData string = loadTextContent('vm.yaml')

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

// Virtual Machine
resource vm 'Microsoft.Compute/virtualMachines@2023-07-01' = {
  name: prefix
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2s_v5'
    }
    storageProfile: {
      osDisk: {
        name: prefix
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
          // id: disk.id //setting an external disk ID is not supported.
        }
        deleteOption:'Delete'

      }
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
    }
    osProfile: {
      computerName: prefix
      adminUsername: adminUsername
      adminPassword: adminPassword
      customData: !empty(customData) ? base64(customData) : null
      linuxConfiguration: {
        disablePasswordAuthentication: false
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
          properties:{
            deleteOption: 'Delete'
          }
        }
      ]
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

// Network Interface Card
resource nic 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: prefix
  location: location
  properties: {
    ipConfigurations: [
      {
        name: prefix
        properties:{
          subnet:{
            id: '${vnet.id}/subnets/${prefix}'
          }
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.0.0.4'
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
  }
}

// Bastion Host
resource bastionIp 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
  name: '${prefix}bastion'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2023-05-01' = {
  name: prefix
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    enableTunneling: true
    enableIpConnect: true
    ipConfigurations: [
      {
        name: '${prefix}bastion'
        properties: {
          publicIPAddress: {
            id: bastionIp.id
          }
          subnet: {
            id: '${vnet.id}/subnets/AzureBastionSubnet'
          }
        }
      }
    ]
    dnsName: '${prefix}.bastion.azure.com'
  }
}


