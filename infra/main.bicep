//==============================================================================
// BICEP TEMPLATE: Main Infrastructure Deployment
//==============================================================================

metadata name = 'APIM Authentication Infrastructure'
metadata description = 'Main template that deploys resource group, container services, and API Management for APIM authentication scenario'
metadata author = 'GitHub Copilot'
metadata version = '1.0.0'

targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

@minLength(1)
@description('The Azure region where all resources will be deployed')
param location string

@description('Principal ID of the user or service principal to assign application roles')
param principalId string = ''

@description('Additional resource tags to be applied to all deployed resources')
param additionalTags object = {}

var solutionName = 'eShopApp'

param deploymentTimestamp string = utcNow('yyyy-MM-dd HH:mm:ss')

var baseTags = {
  'azd-env-name': environmentName
  'solution-name': solutionName
  'deployment-timestamp': deploymentTimestamp
  'deployment-method': 'bicep'
}

var resourceGroupTags = union(baseTags, additionalTags, {
  Solution: solutionName
  environment: environmentName
  DeployedBy: 'Bicep'
  'resource-type': 'resource-group'
})

var moduleBaseTags = union(baseTags, additionalTags)

var resourceGroupName = '${solutionName}-${environmentName}-${location}-rg'

var microservicesDeploymentName = 'microservices-${uniqueString(deployment().name, environmentName)}'
var apimDeploymentName = 'apiManagement-${uniqueString(deployment().name, environmentName)}'

@description('Resource group to contain all solution resources')
resource rg 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: resourceGroupName
  location: location
  tags: resourceGroupTags
}

@description('Deploy foundational microservices infrastructure including container registry, managed identity, and container apps environment')
module microservices 'resources.bicep' = {
  scope: rg
  name: microservicesDeploymentName
  params: {
    location: location
    tags: moduleBaseTags
    principalId: principalId
    environmentName: environmentName
  }
}

@description('Deploy API Management service using configuration from YAML settings')
module apim 'azureAPIManagement/module.bicep' = {
  scope: rg
  name: apimDeploymentName
  params: {
    solutionName: solutionName
    location: location
    tags: moduleBaseTags
    environmentName: environmentName
  }
  dependsOn: [
    microservices
  ]
}

@description('The name of the resource group containing all deployed resources')
output AZURE_RESOURCE_GROUP_NAME string = rg.name

@description('Client ID of the user-assigned managed identity')
output MANAGED_IDENTITY_CLIENT_ID string = microservices.outputs.MANAGED_IDENTITY_CLIENT_ID

@description('Name of the user-assigned managed identity')
output MANAGED_IDENTITY_NAME string = microservices.outputs.MANAGED_IDENTITY_NAME

@description('Name of the Log Analytics Workspace')
output AZURE_LOG_ANALYTICS_WORKSPACE_NAME string = microservices.outputs.AZURE_LOG_ANALYTICS_WORKSPACE_NAME

@description('Login server URL for the Azure Container Registry')
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = microservices.outputs.AZURE_CONTAINER_REGISTRY_ENDPOINT

@description('Resource ID of the managed identity for container registry access')
output AZURE_CONTAINER_REGISTRY_MANAGED_IDENTITY_ID string = microservices.outputs.AZURE_CONTAINER_REGISTRY_MANAGED_IDENTITY_ID

@description('Name of the Azure Container Registry')
output AZURE_CONTAINER_REGISTRY_NAME string = microservices.outputs.AZURE_CONTAINER_REGISTRY_NAME

@description('Name of the Container Apps Environment')
output AZURE_CONTAINER_APPS_ENVIRONMENT_NAME string = microservices.outputs.AZURE_CONTAINER_APPS_ENVIRONMENT_NAME

@description('Resource ID of the Container Apps Environment')
output AZURE_CONTAINER_APPS_ENVIRONMENT_ID string = microservices.outputs.AZURE_CONTAINER_APPS_ENVIRONMENT_ID

@description('Default domain of the Container Apps Environment')
output AZURE_CONTAINER_APPS_ENVIRONMENT_DEFAULT_DOMAIN string = microservices.outputs.AZURE_CONTAINER_APPS_ENVIRONMENT_DEFAULT_DOMAIN

@description('The name of the deployed API Management instance')
output AZURE_APIM_NAME string = apim.outputs.AZURE_APIM_NAME

@description('The gateway URL of the deployed API Management instance')
output AZURE_APIM_URL string = apim.outputs.AZURE_APIM_URL

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
