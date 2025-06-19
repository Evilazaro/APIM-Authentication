/*
  Azure API Management Service Deployment
  
  This template deploys an Azure API Management service with configuration 
  loaded from a YAML settings file.
*/

// Validate that required settings exist in the YAML file
@description('API Management service name from configuration')
param solutionName string

@description('Azure region for the API Management service deployment')
param location string = resourceGroup().location

@description('Configuration settings loaded from YAML file')
var apimSettings = loadYamlContent('../settings/apimsettings.yaml')

@description('API Management service instance')
resource apiManagementInstance 'Microsoft.ApiManagement/service@2024-05-01' = {
  name: '${solutionName}-${uniqueString(resourceGroup().id)}-apim' // Construct the name using the solution name
  location: location

  // SKU configuration defines the pricing tier and capacity
  sku: {
    name: apimSettings.sku.name // e.g., 'Developer', 'Basic', 'Standard', 'Premium', 'Consumption'
    capacity: (apimSettings.sku.name != 'Consumption') ? apimSettings.sku.capacity : null // Set capacity only if not 'Consumption'
  }

  // Identity configuration for authentication with other Azure services
  identity: {
    type: apimSettings.identity.type // e.g., 'SystemAssigned', 'UserAssigned', etc.
  }

  // Core API Management service properties
  properties: {
    publisherEmail: apimSettings.publisherEmail // Required contact email
    publisherName: apimSettings.publisherName // Required publisher name
  }
}

// Output the API Management service name for reference in other templates or scripts
@description('The name of the deployed API Management instance')
output AZURE_APIM_NAME string = apiManagementInstance.name

