# Bicep-Playground-2
Bicep script to create multiple resources. 

It will ask to deploy:
  * deployFirewall
  * deployStorage
  * deployAppSQLKv
  * deployAppGw

This script runs on a subscription level, it will create the Resource Group.
I use a randomizer based on deployment name for the resource names

Script to deploy from Cli with parameters:

az deployment sub create --template-file main.bicep --location swedencentral --name deplname --parameters deployFirewall=true deployStorage=true deployAppSQLKv=true deployAppGw=true sqlpassword=############
