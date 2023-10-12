param location string
param tags object
param kvname string

//secret
@allowed([
  'standard'
  'premium'
])
param skuName string = 'standard'
param accessPolicies array = []
param sqlConnectionString string

resource KeyVault 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: kvname
  location: location
  tags: tags
   properties: {
    sku: {
      family: 'A'
      name: skuName
    }
    tenantId: subscription().tenantId
    accessPolicies: accessPolicies
   }
   resource secret 'secrets' = {
    name: 'sqlConnectionString'
    properties: {
      value: sqlConnectionString
    }
   }
}
