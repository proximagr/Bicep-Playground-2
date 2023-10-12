param location string
param tags object

param sqlservername string
param sqldbname string
param sqlserveradmin string
@secure()
param sqlpassword string
@allowed([
  'S0'
  'S1'
  'S2'
  'S3'
  'S4'
  'S6'
  'S7'
  'S9'
  'S12'
])
param databaseSkuName string = 'S1'


resource mySQLServer 'Microsoft.Sql/servers@2021-11-01-preview'= {
  name: sqlservername
  location: location
  tags: tags
  properties: {
    administratorLogin: sqlserveradmin
    administratorLoginPassword: sqlpassword
  }
  resource mySQLDB 'databases@2021-11-01-preview' = {
    name: sqldbname
    location: location
    tags: tags
    sku: {
      name: databaseSkuName
    }
  }
}

output id string = mySQLServer.id
output fullyQualifiedDomainName string = mySQLServer.properties.fullyQualifiedDomainName
output databaseName string = mySQLServer::mySQLDB.name
