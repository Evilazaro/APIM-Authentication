// Validate that required settings exist in the YAML file
@description('API Management service name from configuration')
param solutionName string

@description('Azure region for the API Management service deployment')
param location string = resourceGroup().location

@description('Configuration settings loaded from YAML file')
var apimSettings = loadYamlContent('../settings/apimsettings.yaml')

@description('API Management service instance')
module apiManagementInstance 'apiManagement.bicep' = {
  name: 'apiManagementInstance'
  params: {
    apimSettings: apimSettings
    solutionName: solutionName
    location: location
  }
}

@description('Product Catalog API resource')
module productCatalogApi 'api.bicep' = {
  name: 'productCatalogApi'
  params: {
    apiManagementName: apiManagementInstance.name
    apiLink: apiManagementInstance.outputs.AZURE_APIM_URL // Link to the OpenAPI specification for the Product Catalog API
  }
  dependsOn: [
    apiManagementInstance
  ]
}

@description('The name of the deployed API Management instance')
output AZURE_APIM_NAME string = apiManagementInstance.name

@description('The URL of the deployed API Management instance')
output AZURE_APIM_URL string = apiManagementInstance.outputs.AZURE_APIM_URL
