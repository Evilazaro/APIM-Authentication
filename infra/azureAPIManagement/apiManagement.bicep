//==============================================================================
// BICEP TEMPLATE: Azure API Management Service Deployment
//==============================================================================
// Description: This template deploys an Azure API Management service with 
//             configuration loaded from a YAML settings file
// Author:     GitHub Copilot
// Version:    1.0
// Created:    June 2025
//==============================================================================

//==============================================================================
// METADATA
//==============================================================================
metadata name = 'Azure API Management Service'
metadata description = 'Deploys Azure API Management service with configuration loaded from YAML settings file'
metadata author = 'GitHub Copilot'
metadata version = '1.0.0'

//==============================================================================
// TARGET SCOPE
//==============================================================================
targetScope = 'resourceGroup'

//==============================================================================
// PARAMETERS
//==============================================================================

@description('API Management service name from configuration used as prefix for resource naming')
@minLength(1)
@maxLength(20)
@metadata({
  example: 'contoso-api'
  purpose: 'Used as prefix for constructing the API Management service name'
})
param solutionName string

@description('Azure region for the API Management service deployment')
@metadata({
  example: 'eastus'
  purpose: 'Location where the API Management service will be deployed'
})
param location string = resourceGroup().location

@description('Configuration settings loaded from YAML file containing SKU, publisher, and identity settings')
@metadata({
  purpose: 'Contains all API Management configuration including SKU, publisher information, and managed identity settings'
  schema: 'Must include: sku.name, sku.capacity, publisherEmail, publisherName, identity.type'
  example: {
    sku: {
      name: 'Developer'
      capacity: 1
    }
    publisherEmail: 'admin@contoso.com'
    publisherName: 'Contoso API Team'
    identity: {
      type: 'SystemAssigned'
    }
  }
})
param apimSettings object

@description('Resource tags to be applied to the API Management service')
@metadata({
  example: {
    environment: 'dev'
    project: 'api-platform'
    owner: 'platform-team'
    costCenter: '12345'
  }
})
param tags object = {}

//==============================================================================
// VARIABLES
//==============================================================================

// Generate unique resource token for naming consistency
var resourceToken = uniqueString(resourceGroup().id)

// Construct API Management service name using solution name and unique string
var apimServiceName = '${solutionName}-${resourceToken}-apim'

// SKU validation - check if Consumption tier (capacity not applicable)
var isConsumptionSku = apimSettings.sku.name == 'Consumption'

// Common tags to be applied to all resources
var commonTags = union(tags, {
  'resource-type': 'api-management'
  'solution-name': solutionName
  'deployment-method': 'bicep'
})

//==============================================================================
// RESOURCES
//==============================================================================

//------------------------------------------------------------------------------
// API Management Service Instance
//------------------------------------------------------------------------------
@description('Azure API Management service instance with configuration from YAML settings')
resource apiManagementInstance 'Microsoft.ApiManagement/service@2024-05-01' = {
  name: apimServiceName
  location: location
  tags: commonTags

  // SKU configuration defines the pricing tier and capacity
  sku: {
    name: apimSettings.sku.name // Supported values: 'Developer', 'Basic', 'Standard', 'Premium', 'Consumption'
    capacity: isConsumptionSku ? null : apimSettings.sku.capacity // Set capacity only if not 'Consumption' tier
  }

  // Identity configuration for authentication with other Azure services
  identity: {
    type: apimSettings.identity.type // Supported values: 'SystemAssigned', 'UserAssigned', 'None'
  }

  // Core API Management service properties
  properties: {
    publisherEmail: apimSettings.publisherEmail // Required: Contact email for the API publisher
    publisherName: apimSettings.publisherName // Required: Name of the API publisher organization
  }
}

//==============================================================================
// OUTPUTS
//==============================================================================

//------------------------------------------------------------------------------
// Primary Outputs (Original Names Preserved)
//------------------------------------------------------------------------------
@description('The name of the deployed API Management instance')
output AZURE_APIM_NAME string = apiManagementInstance.name

@description('The gateway URL of the deployed API Management instance for API access')
output AZURE_APIM_URL string = apiManagementInstance.properties.gatewayUrl

//------------------------------------------------------------------------------
// Additional Outputs for Reference and Integration
//------------------------------------------------------------------------------
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
