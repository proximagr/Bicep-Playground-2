param location string
param tags object
param fwname string
param fwpolicyname string
param vnetName string
param azureFirewallSubnetName string = 'AzureFirewallSubnet'
param publicIPNamePrefix string = 'fwip'
@description('Availability zone numbers e.g. 1,2,3.')
param availabilityZones array = [
  '1'
  '2'
  '3'
]

@description('Number of public IP addresses for the Azure Firewall')
@minValue(1)
@maxValue(100)
param numberOfFirewallPublicIPAddresses int = 1

var azureFirewallSubnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, azureFirewallSubnetName)
var azureFirewallSubnetJSON = json('{"id": "${azureFirewallSubnetId}"}')

var azureFirewallIpConfigurations = [for i in range(0, numberOfFirewallPublicIPAddresses): {
  name: 'IpConf${i}'
  properties: {
    subnet: ((i == 0) ? azureFirewallSubnetJSON : json('null'))
    publicIPAddress: {
      id: fwPublicIP[i].id
    }
  }
}]

resource fwPublicIP 'Microsoft.Network/publicIPAddresses@2021-08-01' = [for i in range(0, numberOfFirewallPublicIPAddresses): {
  name: '${publicIPNamePrefix}${i+1}'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
  zones: availabilityZones
}]

resource AzFirewallPolicy 'Microsoft.Network/firewallPolicies@2021-08-01' = {
  name: fwpolicyname
  location: location
  tags: tags

}

resource AzFirewall 'Microsoft.Network/azureFirewalls@2021-08-01' = {
  name: fwname
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    ipConfigurations: azureFirewallIpConfigurations
    firewallPolicy: {
      id: AzFirewallPolicy.id
    }
  }
}
