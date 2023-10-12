targetScope = 'subscription'

param deployFirewall bool
param deployStorage bool
param deployAppSQLKv bool
param deployAppGw bool

@allowed([
  'swedencentral'
  'northeurope'
  'uksouth'
  'westeurope'
  'francecentral'
  'germanywestcentral'
  'norwayeast'
  'switzerlandnorth'
  'francesouth'
  'germanynorth'
  'norwaywest'
  'switzerlandwest'
  'ukwest'
])
param location string = 'germanywestcentral'

var tags = {
  Region: location
  Deployment:deployment().name
}

param randomvalue string = uniqueString(deployment().name)

@description('Create resource names based to the deployment name')
var rgname = 'rg-${randomvalue}'

//Storage
var storageName = 'sa${randomvalue}'

//Vnet-NSG
var vnetName = 'vnet-${randomvalue}'
var mynsgname = 'nsg-${randomvalue}'

//AzuereSQL
var sqlservername = 'sql${randomvalue}'
var sqldbname = 'db${randomvalue}'
param sqlserveradmin string = 'padmin'
@secure()
param sqlpassword string
param sqlConnectionString string = 'sqlConnectionString'

//WebApp
var webfarmsku = {
  name: 'f1'
  capacity: 1
}
var webappname = 'wa${randomvalue}'
var webfarmname = 'wf${randomvalue}'
var siteConfig = {
  netFrameworkVersion: 'v5.0'
  connectionStrings: [
    {
      name: 'sqlConnectionString'
      connectionString: '@Microsoft.KeyVault(VaultName=${kvname};SecretName=${sqlConnectionString})'
      type: 'SQLAzure'
    }
  ]
}

//KeyVault
var kvname = 'kv-${randomvalue}'

//AzFirewall
var fwname = 'fw-${randomvalue}'
var fwpolicyname = 'fwp-${randomvalue}'

//AppGW
var AppGwName = 'appGw-${randomvalue}'


resource firstRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgname
  location: location
  tags: tags
}

module vnetnsg 'modules/VNet-NSG.bicep' = {
  scope: resourceGroup(firstRG.name)
  name: 'vnetnsg-deployment'
  params: {
    location: location
    tags: tags
    vnetName: vnetName
    mynsgname: mynsgname
    deployFirewall: deployFirewall
    deployAppGw: deployAppGw
  }
}

module storage 'modules/storage.bicep' = if (deployStorage) {
  scope: resourceGroup(firstRG.name)
  name: 'storage-deployment'
  params: {
    location: location
    tags: tags
    storageName: storageName
    }
}

module mySQLServer 'modules/PaaS-SQL.bicep' = if (deployAppSQLKv) {
  scope: resourceGroup(firstRG.name)
  name: 'AzureSQL-deployment'
  params: {
    location: location
    sqldbname: sqldbname
    sqlpassword: sqlpassword
    sqlserveradmin: sqlserveradmin
    sqlservername: sqlservername
    tags: tags
    databaseSkuName: 'S1'
  }
}

module myKeyVAult 'modules/KeyVault.bicep' = if (deployAppSQLKv) {
  scope: resourceGroup(firstRG.name)
  name: 'KeyVault-deployment'
  params: {
    kvname: kvname
    location: location
    tags: tags
    sqlConnectionString: deployAppSQLKv ? 'Data Source=tcp:${mySQLServer.outputs.fullyQualifiedDomainName}, 1433;Initial Catalog=${mySQLServer.outputs.databaseName};User Id=${sqlserveradmin};Password=${sqlpassword};' : ''
    accessPolicies: [
      {
        tenantId: deployAppSQLKv ? WebApp.outputs.identity.tenantId : ''
        objectId: deployAppSQLKv ? WebApp.outputs.identity.principalId : ''
        permissions: {
          secrets: [
            'get'
          ]
        }
      }
    ]
  }
}

module WebApp 'modules/WebApp.bicep' = if (deployAppSQLKv) {
  scope: resourceGroup(firstRG.name)
  name: 'WebApp-deployment'
  params: {
    location: location
    tags: tags
    webappname: webappname
    webfarmname: webfarmname
    webfarmsku: webfarmsku
    siteConfig: siteConfig
    managedIdentity: true
  }
}

module AzFirewall 'modules/AzFirewall.bicep' = if (deployFirewall) {
  scope: resourceGroup(firstRG.name)
  name: 'AzFirewall-deployment'
  params: {
    fwname: fwname
    location: location
    tags: tags
    vnetName: vnetName
    fwpolicyname: fwpolicyname
  }
}

module AppGw 'modules/applGW.bicep' = {
  scope: resourceGroup(firstRG.name)
  name: 'AppGW-deployment'
  params: {
    appGwName: AppGwName
    location: location
    tags: tags
    appGwSubnetID: vnetnsg.outputs.AppGwSubnetId
  }
}
