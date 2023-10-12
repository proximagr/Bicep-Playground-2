param location string
param tags object

@minLength(3)
@maxLength(24)
@description('Name for the Storage Account')
param storageName string

resource diagnosticStorage 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: storageName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}
