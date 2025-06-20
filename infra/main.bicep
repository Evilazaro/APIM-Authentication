//==============================================================================
// BICEP TEMPLATE: Main Infrastructure Deployment
//==============================================================================
// Description: This template orchestrates the deployment of all infrastructure
//             components including resource group, microservices, and API Management
// Author:     GitHub Copilot
// Version:    1.0
// Created:    June 2025
//==============================================================================

//==============================================================================
// METADATA
//==============================================================================
metadata name = 'APIM Authentication Infrastructure'
metadata description = 'Main template that deploys resource group, container services, and API Management for APIM authentication scenario'
metadata author = 'GitHub Copilot'
metadata version = '1.0.0'

//==============================================================================
// TARGET SCOPE
//==============================================================================
targetScope = 'subscription'

//==============================================================================
// PARAMETERS
//==============================================================================

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention')
@metadata({
  example: 'dev'
  purpose: 'Used for resource naming and environment-specific configurations'
  note: 'The resource group name will be constructed as: {solutionName}-{environmentName}-{location}-rg'
})
param environmentName string

@minLength(1)
@description('The Azure region where all resources will be deployed')
@metadata({
  example: 'eastus'
  purpose: 'Primary location for all infrastructure components'
  constraint: 'Must be a valid Azure region that supports all required services'
})
param location string

@description('Principal ID of the user or service principal to assign application roles')
@metadata({
  example: '12345678-1234-1234-1234-123456789012'
  purpose: 'Used for role-based access control assignments across deployed resources'
  note: 'Leave empty if no specific principal needs access'
})
param principalId string = ''

@description('Additional resource tags to be applied to all deployed resources')
@metadata({
  example: {
    project: 'apim-auth'
    owner: 'platform-team'
    costCenter: '12345'
  }
  purpose: 'Additional tags for resource organization and cost tracking'
})
param additionalTags object = {}

//==============================================================================
// VARIABLES
//==============================================================================

// Solution configuration
@description('Solution name used for resource naming and identification')
var solutionName = 'eShopApp'

// Generate deployment timestamp for tracking
param deploymentTimestamp string = utcNow('yyyy-MM-dd HH:mm:ss')

// Base tags that will be applied to all resources
var baseTags = {
  'azd-env-name': environmentName
  'solution-name': solutionName
  'deployment-timestamp': deploymentTimestamp
  'deployment-method': 'bicep'
}

// Resource group specific tags
var resourceGroupTags = union(baseTags, additionalTags, {
  Solution: solutionName
  Environment: environmentName
  DeployedBy: 'Bicep'
  'resource-type': 'resource-group'
})

// Tags to be passed to child modules
var moduleBaseTags = union(baseTags, additionalTags)

// Resource group name following naming convention
var resourceGroupName = '${solutionName}-${environmentName}-${location}-rg'

// Module deployment names with timestamps for uniqueness
var microservicesDeploymentName = 'microservices-${uniqueString(deployment().name, environmentName)}'
var apimDeploymentName = 'apiManagement-${uniqueString(deployment().name, environmentName)}'

//==============================================================================
// RESOURCES
//==============================================================================

//------------------------------------------------------------------------------
// Resource Group
//------------------------------------------------------------------------------
@description('Resource group to contain all solution resources')
resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: resourceGroupTags
}

//==============================================================================
// MODULES
//==============================================================================

//------------------------------------------------------------------------------
// Microservices Infrastructure Module
//------------------------------------------------------------------------------
@description('Deploy foundational microservices infrastructure including container registry, managed identity, and container apps environment')
module microservices 'resources.bicep' = {
  scope: rg
  name: microservicesDeploymentName
  params: {
    location: location
    tags: moduleBaseTags
    principalId: principalId
    environment: environmentName
    projectName: toLower(solutionName)
  }
}

//------------------------------------------------------------------------------
// API Management Module
//------------------------------------------------------------------------------
@description('Deploy API Management service using configuration from YAML settings')
module apim 'azureAPIManagement/module.bicep' = {
  scope: rg
  name: apimDeploymentName
  params: {
    solutionName: solutionName
    location: location
    tags: moduleBaseTags
    environment: environmentName
  }
  dependsOn: [
    microservices
  ]
}

//==============================================================================
// OUTPUTS
//==============================================================================

//------------------------------------------------------------------------------
// Resource Group Outputs
//------------------------------------------------------------------------------
@description('The name of the resource group containing all deployed resources')
output AZURE_RESOURCE_GROUP_NAME string = rg.name

//------------------------------------------------------------------------------
// Managed Identity Outputs (From Microservices Module)
//------------------------------------------------------------------------------
@description('Client ID of the user-assigned managed identity')
output MANAGED_IDENTITY_CLIENT_ID string = microservices.outputs.MANAGED_IDENTITY_CLIENT_ID

@description('Name of the user-assigned managed identity')
output MANAGED_IDENTITY_NAME string = microservices.outputs.MANAGED_IDENTITY_NAME

//------------------------------------------------------------------------------
// Log Analytics Outputs (From Microservices Module)
//------------------------------------------------------------------------------
@description('Name of the Log Analytics Workspace')
output AZURE_LOG_ANALYTICS_WORKSPACE_NAME string = microservices.outputs.AZURE_LOG_ANALYTICS_WORKSPACE_NAME

//------------------------------------------------------------------------------
// Container Registry Outputs (From Microservices Module)
//------------------------------------------------------------------------------
@description('Login server URL for the Azure Container Registry')
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = microservices.outputs.AZURE_CONTAINER_REGISTRY_ENDPOINT

@description('Resource ID of the managed identity for container registry access')
output AZURE_CONTAINER_REGISTRY_MANAGED_IDENTITY_ID string = microservices.outputs.AZURE_CONTAINER_REGISTRY_MANAGED_IDENTITY_ID

@description('Name of the Azure Container Registry')
output AZURE_CONTAINER_REGISTRY_NAME string = microservices.outputs.AZURE_CONTAINER_REGISTRY_NAME

//------------------------------------------------------------------------------
// Container Apps Environment Outputs (From Microservices Module)
//------------------------------------------------------------------------------
@description('Name of the Container Apps Environment')
output AZURE_CONTAINER_APPS_ENVIRONMENT_NAME string = microservices.outputs.AZURE_CONTAINER_APPS_ENVIRONMENT_NAME

@description('Resource ID of the Container Apps Environment')
output AZURE_CONTAINER_APPS_ENVIRONMENT_ID string = microservices.outputs.AZURE_CONTAINER_APPS_ENVIRONMENT_ID

@description('Default domain of the Container Apps Environment')
output AZURE_CONTAINER_APPS_ENVIRONMENT_DEFAULT_DOMAIN string = microservices.outputs.AZURE_CONTAINER_APPS_ENVIRONMENT_DEFAULT_DOMAIN

//------------------------------------------------------------------------------
// API Management Outputs (From APIM Module)
//------------------------------------------------------------------------------
@description('The name of the deployed API Management instance')
output AZURE_APIM_NAME string = apim.outputs.AZURE_APIM_NAME

@description('The gateway URL of the deployed API Management instance')
output AZURE_APIM_URL string = apim.outputs.AZURE_APIM_URL

//------------------------------------------------------------------------------
// Deployment Context Outputs
//------------------------------------------------------------------------------
@description('Environment name used for this deployment')
output deploymentEnvironment string = environmentName

@description('Location where resources were deployed')
output deploymentLocation string = location

@description('Solution name used for resource naming')
output solutionName string = solutionName

@description('Timestamp when the deployment was executed')
output deploymentTimestamp string = deploymentTimestamp

@description('Resource group ID for reference in other deployments')
output resourceGroupId string = rg.id

//==============================================================================
// END OF TEMPLATE
//==============================================================================
