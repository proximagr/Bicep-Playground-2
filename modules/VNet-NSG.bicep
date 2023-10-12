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
