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
    subnet: ((i == 0) ? azureFirewallSubnetJSON : null)
    publicIPAddress: {
      id: fwPublicIP[i].id
    }
  }
}]

resource workloadIpGroup 'Microsoft.Network/ipGroups@2022-01-01' = {
  name: 'workloadIpGroup'
  location: location
  properties: {
    ipAddresses: [
      '10.20.0.0/24'
      '10.30.0.0/24'
    ]
  }
}

resource infraIpGroup 'Microsoft.Network/ipGroups@2022-01-01' = {
  name: 'infraIpGroup'
  location: location
  properties: {
    ipAddresses: [
      '10.40.0.0/24'
      '10.50.0.0/24'
    ]
  }
}

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

resource networkRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2022-01-01' = {
  parent: AzFirewallPolicy
  name: 'DefaultNetworkRuleCollectionGroup'
  properties: {
    priority: 200
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        name: 'azure-global-services-nrc'
        priority: 1250
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'time-windows'
            ipProtocols: [
              'UDP'
            ]
            destinationAddresses: [
              '13.86.101.172'
            ]
            sourceIpGroups: [
              workloadIpGroup.id
              infraIpGroup.id
            ]
            destinationPorts: [
              '123'
            ]
          }
        ]
      }
    ]
  }
}

resource applicationRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2022-01-01' = {
  parent: AzFirewallPolicy
  name: 'DefaultApplicationRuleCollectionGroup'
  dependsOn: [
    networkRuleCollectionGroup
  ]
  properties: {
    priority: 300
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'global-rule-url-arc'
        priority: 1000
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'ApplicationRule'
            name: 'winupdate-rule-01'
            protocols: [
              {
                protocolType: 'Https'
                port: 443
              }
              {
                protocolType: 'Http'
                port: 80
              }
            ]
            fqdnTags: [
              'WindowsUpdate'
            ]
            terminateTLS: false
            sourceIpGroups: [
              workloadIpGroup.id
              infraIpGroup.id
            ]
          }
        ]
      }
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        name: 'Global-rules-arc'
        priority: 1202
        rules: [
          {
            ruleType: 'ApplicationRule'
            name: 'global-rule-01'
            protocols: [
              {
                protocolType: 'Https'
                port: 443
              }
            ]
            targetFqdns: [
              'www.microsoft.com'
            ]
            terminateTLS: false
            sourceIpGroups: [
              workloadIpGroup.id
              infraIpGroup.id
            ]
          }
        ]
      }
    ]
  }
}


resource AzFirewall 'Microsoft.Network/azureFirewalls@2021-08-01' = {
  name: fwname
  location: location
  tags: tags
  dependsOn: [
    workloadIpGroup
    infraIpGroup
    networkRuleCollectionGroup
    applicationRuleCollectionGroup
  ]
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
