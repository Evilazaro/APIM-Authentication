//==============================================================================
// BICEP TEMPLATE: Azure API Management Service Deployment
//==============================================================================

metadata name = 'Azure API Management Service'
metadata description = 'Deploys Azure API Management service with configuration loaded from YAML settings file'
metadata author = 'GitHub Copilot'
metadata version = '1.0.0'

targetScope = 'resourceGroup'

@description('API Management service name from configuration used as prefix for resource naming')
@minLength(1)
@maxLength(20)
param solutionName string

@description('Azure region for the API Management service deployment')
param location string = resourceGroup().location

@description('Configuration settings loaded from YAML file containing SKU, publisher, and identity settings')
param apimSettings object

@description('Resource tags to be applied to the API Management service')
param tags object = {}

var resourceToken = uniqueString(resourceGroup().id)

var apimServiceName = '${solutionName}-${resourceToken}-apim'

var isConsumptionSku = apimSettings.sku.name == 'Consumption'

var commonTags = union(tags, {
  'resource-type': 'api-management'
  'solution-name': solutionName
  'deployment-method': 'bicep'
})

@description('Azure API Management service instance with configuration from YAML settings')
resource apiManagementInstance 'Microsoft.ApiManagement/service@2022-08-01' = {
  name: apimServiceName
  location: location
  tags: commonTags

  sku: {
    name: apimSettings.sku.name
    capacity: isConsumptionSku ? null : apimSettings.sku.capacity
  }

  identity: {
    type: apimSettings.identity.type
  }

  properties: {
    publisherEmail: apimSettings.publisherEmail
    publisherName: apimSettings.publisherName
  }
}

@description('The name of the deployed API Management instance')
output AZURE_APIM_NAME string = apiManagementInstance.name

@description('The gateway URL of the deployed API Management instance for API access')
output AZURE_APIM_URL string = apiManagementInstance.properties.gatewayUrl

@description('Resource ID of the API Management service for referencing in other templates')
output apimResourceId string = apiManagementInstance.id

@description('Management API URL for administrative operations and configuration')
output apimManagementUrl string = apiManagementInstance.properties.managementApiUrl

@description('Developer portal URL for API documentation and testing')
output apimDeveloperPortalUrl string = apiManagementInstance.properties.developerPortalUrl

@description('System-assigned managed identity principal ID (if enabled)')
output apimPrincipalId string = contains(apimSettings.identity.type, 'SystemAssigned')
  ? apiManagementInstance.identity.principalId
  : ''

@description('API Management service provisioning state')
output apimProvisioningState string = apiManagementInstance.properties.provisioningState

@description('Public IP addresses assigned to the API Management service')
output apimPublicIpAddresses array = apiManagementInstance.properties.publicIPAddresses
