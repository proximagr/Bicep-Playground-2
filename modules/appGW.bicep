param location string
param tags object
param appGwName string
param appGwSubnetID string
var appGwPubIPName = 'pip-${appGwName}'
var appGwIPConfiguration = '${appGwName}-ip-configuration'
var appGwFEIPConfiguration = 'feip-${appGwName}'
var appGwFEPortHttp = '${appGwName}-HTTP'
var backendAddressPool = '${appGwName}-beAPool'
param backendSettingsHTTP string = 'backendSettingsHTTP'
param httpListener string = 'httpListener'

resource appGwPip 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: appGwPubIPName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'    
    dnsSettings: {
      domainNameLabel: toLower('pip${appGwName}')
    }
  }
}

resource myAppGw 'Microsoft.Network/applicationGateways@2021-08-01' = {
  name: appGwName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
    }
    autoscaleConfiguration: {
      minCapacity: 1
      maxCapacity: 2
    }
    gatewayIPConfigurations: [
      {
        name: appGwIPConfiguration
        properties: {
          subnet: {
            id: appGwSubnetID
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: appGwFEIPConfiguration
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: appGwPip.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: appGwFEPortHttp
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: backendAddressPool
        properties: {
          backendAddresses: []
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: backendSettingsHTTP
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          affinityCookieName: 'ApplicationGatewayAffinity'
          requestTimeout: 20
        }
      }
    ]
    httpListeners: [
      {
        name: httpListener
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGwName, appGwFEIPConfiguration)
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGwName, appGwFEPortHttp)
          }
          protocol: 'Http'
          hostNames: []
          requireServerNameIndication: false
        }
      }
    ]
    requestRoutingRules: [
      {
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGwName, httpListener)
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGwName, backendAddressPool)
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGwName, backendSettingsHTTP)
          }
        }
      }
    ]
  }
}
