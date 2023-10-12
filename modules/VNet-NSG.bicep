param location string
param tags object

@minLength(2)
@maxLength(64)
@description('Name for the Virtual Network')
param vnetName string

param mynsgname string

param deployFirewall bool
var subnet0Name = deployFirewall ? 'AzureFirewallSubnet' : 'Subnet-0' 

param deployAppGw bool
var subnet1Name = deployAppGw ? 'AppGatewaySubnet' : 'Subnet-1' 

resource mynsg 'Microsoft.Network/networkSecurityGroups@2021-08-01' = {
  name: mynsgname
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'Allow-SSH'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow-HTTP'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 200
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow-HTTPS'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 300
          direction: 'Inbound'
        }
      }
      {
        name: 'applicationGatewayAccess'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '65200-65535'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 400
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnet0Name
        properties: {
          addressPrefix: '10.0.0.0/24'
        } 
      }
      {
        name: subnet1Name
        properties: {
          addressPrefix: '10.0.1.0/24'
          networkSecurityGroup:{
            id: mynsg.id
          }
        }
      }
      {
        name: 'Subnet-2'
        properties: {
          addressPrefix: '10.0.2.0/24'
          networkSecurityGroup:{
            id: mynsg.id
          }
        }
      }
    ]
  }
}

output AppGwSubnetId string = virtualNetwork.properties.subnets[2].id
