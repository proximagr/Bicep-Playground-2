targetScope = 'subscription'
param location string = deployment().location

//select the resources to deploy
param deployFirewall bool
param deployStorage bool
param deployAppSQLKv bool
param deployAppGw bool
param deployVM bool

//randomizer
param randomvalue string = substring((uniqueString(deployment().name)), 0, 5)

//set the tags
var tags = {
  Region: location
  Deployment:deployment().name
  RandomValue: randomvalue
}

//create random names
var rgname = 'rg-${randomvalue}'
var storageName = 'sa${randomvalue}'
var vnetName = 'vnet-${randomvalue}'
var mynsgname = 'nsg-${randomvalue}'

//AzuereSQL parameters
var sqlservername = 'sql${randomvalue}'
var sqldbname = 'db${randomvalue}'
param sqlserveradmin string = 'padmin'
param sqlConnectionString string = 'sqlConnectionString'

//WebApp parameters
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

//VMs parameters
param adminUserName string = 'padmin'
param vmName string = 'vm${randomvalue}'
@allowed([
    'Standard_B2s'
    'Standard_B2ls_v2'
    'Standard_D2s_v5'
  ])
param vmSize string

//passwords
@secure()
param vmpassword string
@secure()
param sqlpassword string

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
    deployVM: deployVM
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

module AppGw 'modules/applGW.bicep' = if (deployAppGw) {
  scope: resourceGroup(firstRG.name)
  name: 'AppGW-deployment'
  params: {
    appGwName: AppGwName
    location: location
    tags: tags
    appGwSubnetID: vnetnsg.outputs.AppGwSubnetId
  }
}

module VM 'modules/VM.bicep' = if (deployVM) {
  scope: resourceGroup(firstRG.name)
  name: 'VM-deployment'
  dependsOn: [
    vnetnsg
  ]
  params: {
    location: location
    tags: tags
    adminPassword: vmpassword
    adminUserName: adminUserName
    vmName: vmName
    vmSize: vmSize
    vmSubnetRef: vnetnsg.outputs. VMsSubenetId
  }
}
