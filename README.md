# Bicep-Playground-2
Bicep script to create multiple resources. 

It will ask to deploy:
  * deployFirewall
  * deployStorage
  * deployAppSQLKv 
  * deployAppGw (WAF v2)

With the deployAppSQLKv will deploy an App Service, an Azure SQL and a KeyVault to Store the SQL connection string

This script runs on a subscription level, it will create the Resource Group.
I use a randomizer based on deployment name for the resource names

Script to deploy from Cli and answer interactivly:

az deployment sub create --template-file main.bicep --name deplname --location azureregion

Script to deploy from Cli with parameters:

az deployment sub create --template-file main.bicep --name deplname --location azureregion --parameters deployFirewall=true deployStorage=true deployAppSQLKv=true deployAppGw=true deployVM=true sqlpassword=############ vmpassword=############
