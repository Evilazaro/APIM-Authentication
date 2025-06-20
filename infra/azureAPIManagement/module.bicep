//==============================================================================
// BICEP MODULE: Azure API Management Service Module
//==============================================================================

metadata name = 'Azure API Management Module'
metadata description = 'Module that loads YAML configuration and deploys API Management service'
metadata author = 'GitHub Copilot'
metadata version = '1.0.0'

targetScope = 'resourceGroup'

@description('API Management service name from configuration used as prefix for resource naming')
@minLength(1)
@maxLength(20)
@metadata({
  example: 'contoso-api'
  purpose: 'Used as prefix for constructing the API Management service name'
  validation: 'Must be 1-20 characters, alphanumeric and hyphens only'
})
param solutionName string

@description('Azure region for the API Management service deployment')
@metadata({
  example: 'eastus'
  purpose: 'Location where the API Management service will be deployed'
  note: 'Defaults to resource group location if not specified'
})
param location string = resourceGroup().location

@description('Resource tags to be applied to all API Management resources')
@metadata({
  example: {
    environment: 'dev'
    project: 'api-platform'
    owner: 'platform-team'
    costCenter: '12345'
  }
  purpose: 'Tags for resource organization, cost tracking, and governance'
})
param tags object = {}

@description('Environment name for resource configuration and naming')
@allowed(['dev', 'test', 'staging', 'prod'])
@metadata({
  purpose: 'Used for environment-specific configurations and resource naming'
})
param environment string = 'dev'

@description('Configuration settings loaded from YAML file containing SKU, publisher, and identity settings')
var apimSettings = loadYamlContent('../settings/apimsettings.yaml')

param deploymentTimestamp string = utcNow('yyyyMMdd-HHmmss')
var moduleDeploymentName = 'apim-deployment-${deploymentTimestamp}'

var commonTags = union(tags, {
  'deployment-method': 'bicep-module'
  'module-name': 'api-management-module'
  'solution-name': solutionName
  environment: environment
  'last-deployed': deploymentTimestamp
})

@description('Deploy Azure API Management service using loaded YAML configuration')
module apiManagementInstance 'apiManagement.bicep' = {
  name: moduleDeploymentName
  scope: resourceGroup()
  params: {
    apimSettings: apimSettings
    solutionName: solutionName
    location: location
    tags: commonTags
  }
}

@description('The name of the deployed API Management instance')
output AZURE_APIM_NAME string = apiManagementInstance.outputs.AZURE_APIM_NAME

@description('The gateway URL of the deployed API Management instance')
output AZURE_APIM_URL string = apiManagementInstance.outputs.AZURE_APIM_URL

@description('Resource ID of the deployed API Management service')
output apimResourceId string = apiManagementInstance.outputs.apimResourceId

@description('Management API URL for administrative operations')
output apimManagementUrl string = apiManagementInstance.outputs.apimManagementUrl

@description('Developer portal URL for API documentation and testing')
output apimDeveloperPortalUrl string = apiManagementInstance.outputs.apimDeveloperPortalUrl

@description('System-assigned managed identity principal ID (if enabled)')
output apimPrincipalId string = apiManagementInstance.outputs.apimPrincipalId

@description('API Management service provisioning state')
output apimProvisioningState string = apiManagementInstance.outputs.apimProvisioningState

@description('Public IP addresses assigned to the API Management service')
output apimPublicIpAddresses array = apiManagementInstance.outputs.apimPublicIpAddresses

@description('Configuration settings that were loaded from YAML file')
output loadedConfiguration object = apimSettings

@description('Environment configuration used for deployment')
output deploymentEnvironment string = environment

@description('Tags applied to the API Management resources')
output appliedTags object = commonTags
