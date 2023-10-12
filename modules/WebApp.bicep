param location string
param tags object
param webfarmsku object
param siteConfig object
param managedIdentity bool = false

param webappname string
param webfarmname string

resource myWebFarm 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: webfarmname
  location: location
  tags: tags
  sku: webfarmsku
}

resource myWebApp 'Microsoft.Web/sites@2021-03-01' = {
  name: webappname
  location: location
  tags: tags
  identity: {
    type: managedIdentity ? 'SystemAssigned' : 'None'
  }
  properties: {
    serverFarmId: myWebFarm.id
    siteConfig: siteConfig
  }
}

output identity object = managedIdentity ? {
  tenantId: myWebApp.identity.tenantId
  principalId: myWebApp.identity.principalId
  type: myWebApp.identity.type
} : {}
