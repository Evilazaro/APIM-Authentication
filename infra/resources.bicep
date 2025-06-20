//==============================================================================
// BICEP TEMPLATE: Azure Resources for APIM Authentication
//==============================================================================
// Description: This template creates the foundational Azure resources required
//             for the Product Catalog API with APIM authentication support
// Author:     GitHub Copilot
// Version:    1.0
// Created:    June 2025
//==============================================================================

//==============================================================================
// METADATA
//==============================================================================
metadata name = 'APIM Authentication Resources'
metadata description = 'Creates managed identity, container registry, container apps environment, and log analytics workspace for APIM authentication scenario'
metadata author = 'GitHub Copilot'
metadata version = '1.0.0'

//==============================================================================
// TARGET SCOPE
//==============================================================================
targetScope = 'resourceGroup'

//==============================================================================
// PARAMETERS
//==============================================================================
@description('The Azure region where all resources will be deployed')
param location string = resourceGroup().location

@description('Principal ID of the user or service principal to assign application roles')
@metadata({
  example: '12345678-1234-1234-1234-123456789012'
  purpose: 'Used for role-based access control assignments'
})
param principalId string = ''

@description('Resource tags to be applied to all deployed resources')
@metadata({
  example: {
    environment: 'dev'
    project: 'apim-auth'
    owner: 'platform-team'
    costCenter: '12345'
  }
})
param tags object = {}

@description('Environment name for resource naming (dev, test, prod)')
@allowed(['dev', 'test', 'staging', 'prod'])
param environment string = 'dev'

@description('Project name for resource naming')
@minLength(2)
@maxLength(10)
param projectName string = 'apim'

@description('Container Registry SKU')
@allowed(['Basic', 'Standard', 'Premium'])
param containerRegistrySku string = 'Basic'

@description('Log Analytics Workspace pricing tier')
@allowed(['Free', 'PerNode', 'PerGB2018', 'Standalone', 'Standard', 'Premium'])
param logAnalyticsSkuName string = 'PerGB2018'

@description('Log Analytics Workspace data retention in days')
@minValue(30)
@maxValue(730)
param logAnalyticsRetentionDays int = 30

//==============================================================================
// VARIABLES
//==============================================================================
// Generate unique resource token for naming consistency
var resourceToken = toLower(uniqueString(resourceGroup().id, location, environment))

// Resource naming conventions
var namingConvention = {
  managedIdentity: 'mi-${projectName}-${environment}-${resourceToken}'
  containerRegistry: replace('acr${projectName}${environment}${resourceToken}', '-', '')
  logAnalyticsWorkspace: 'law-${projectName}-${environment}-${resourceToken}'
  containerAppEnvironment: 'cae-${projectName}-${environment}-${resourceToken}'
}

// Role definition IDs for Azure RBAC
var roleDefinitions = {
  acrPull: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
  contributor: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
  reader: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
}

// Common tags to be merged with user-provided tags
var commonTags = union(tags, {
  'deployment-method': 'bicep'
  'resource-group': resourceGroup().name
  'subscription-id': subscription().subscriptionId
  environment: environment
  project: projectName
})

//==============================================================================
// RESOURCES
//==============================================================================

//------------------------------------------------------------------------------
// Managed Identity
//------------------------------------------------------------------------------
@description('User-assigned managed identity for secure authentication across Azure services')
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: namingConvention.managedIdentity
  location: location
  tags: union(commonTags, {
    'resource-type': 'managed-identity'
    purpose: 'Container Apps authentication and ACR access'
  })
}

//------------------------------------------------------------------------------
// Container Registry
//------------------------------------------------------------------------------
@description('Azure Container Registry for storing container images')
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: namingConvention.containerRegistry
  location: location
  sku: {
    name: containerRegistrySku
  }
  properties: {
    adminUserEnabled: false
    policies: {
      quarantinePolicy: {
        status: 'enabled'
      }
      trustPolicy: {
        type: 'Notary'
        status: 'disabled'
      }
      retentionPolicy: {
        days: 7
        status: 'enabled'
      }
    }
    encryption: {
      status: 'disabled'
    }
    dataEndpointEnabled: false
    publicNetworkAccess: 'Enabled'
    networkRuleBypassOptions: 'AzureServices'
  }
  tags: union(commonTags, {
    'resource-type': 'container-registry'
    purpose: 'Container image storage for APIM authentication services'
  })
}

//------------------------------------------------------------------------------
// Role Assignment: Managed Identity -> Container Registry (AcrPull)
//------------------------------------------------------------------------------
@description('Role assignment granting the managed identity AcrPull access to the container registry')
resource managedIdentityAcrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(
    containerRegistry.id,
    managedIdentity.id,
    roleDefinitions.acrPull
  )
  scope: containerRegistry
  properties: {
    description: 'Grants AcrPull permissions to the managed identity for container image pulls'
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      roleDefinitions.acrPull
    )
  }
}

//------------------------------------------------------------------------------
// Log Analytics Workspace  
//------------------------------------------------------------------------------
@description('Log Analytics Workspace for centralized logging and monitoring')
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: namingConvention.logAnalyticsWorkspace
  location: location
  properties: {
    sku: {
      name: logAnalyticsSkuName
    }
    retentionInDays: logAnalyticsRetentionDays
    features: {
      searchVersion: 1
      legacy: 0
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: -1
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
  tags: union(commonTags, {
    'resource-type': 'log-analytics-workspace'
    purpose: 'Centralized logging for Container Apps and monitoring'
  })
}

//------------------------------------------------------------------------------
// Container Apps Environment
//------------------------------------------------------------------------------
@description('Container Apps Environment with integrated monitoring and Aspire Dashboard')
resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: namingConvention.containerAppEnvironment
  location: location
  properties: {
    workloadProfiles: [
      {
        workloadProfileType: 'Consumption'
        name: 'consumption'
      }
    ]
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
    infrastructureResourceGroup: '${resourceGroup().name}-infrastructure'
  }
  tags: union(commonTags, {
    'resource-type': 'container-apps-environment'
    purpose: 'Hosting environment for containerized APIM authentication services'
  })

  //----------------------------------------------------------------------------
  // Aspire Dashboard Component
  //----------------------------------------------------------------------------
  resource aspireDashboard 'dotNetComponents@2024-03-01' = {
    name: 'aspire-dashboard'
    properties: {
      componentType: 'AspireDashboard'
      configurations: [
        {
          propertyName: 'ASPIRE_DASHBOARD_OTLP_ENDPOINT_URL'
          value: 'http://localhost:18889'
        }
      ]
    }
  }
}

//------------------------------------------------------------------------------
// Role Assignment: Principal -> Resource Group (if principalId provided)
//------------------------------------------------------------------------------
@description('Optional role assignment for provided principal ID')
resource principalRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(principalId)) {
  name: guid(
    resourceGroup().id,
    principalId,
    roleDefinitions.contributor
  )
  properties: {
    description: 'Grants Contributor access to the specified principal for resource management'
    principalId: principalId
    principalType: 'User'
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      roleDefinitions.contributor
    )
  }
}



//==============================================================================
// OUTPUTS
//==============================================================================

//------------------------------------------------------------------------------
// Managed Identity Outputs
//------------------------------------------------------------------------------
@description('Client ID of the user-assigned managed identity')
output MANAGED_IDENTITY_CLIENT_ID string = managedIdentity.properties.clientId

@description('Name of the user-assigned managed identity')
output MANAGED_IDENTITY_NAME string = managedIdentity.name

@description('Principal ID of the user-assigned managed identity')
output MANAGED_IDENTITY_PRINCIPAL_ID string = managedIdentity.properties.principalId

//------------------------------------------------------------------------------
// Log Analytics Workspace Outputs
//------------------------------------------------------------------------------
@description('Name of the Log Analytics Workspace')
output AZURE_LOG_ANALYTICS_WORKSPACE_NAME string = logAnalyticsWorkspace.name

@description('Resource ID of the Log Analytics Workspace')
output AZURE_LOG_ANALYTICS_WORKSPACE_ID string = logAnalyticsWorkspace.id

//------------------------------------------------------------------------------
// Container Registry Outputs
//------------------------------------------------------------------------------
@description('Login server URL for the Azure Container Registry')
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.properties.loginServer

@description('Resource ID of the user-assigned managed identity for ACR access')
output AZURE_CONTAINER_REGISTRY_MANAGED_IDENTITY_ID string = managedIdentity.id

@description('Name of the Azure Container Registry')
output AZURE_CONTAINER_REGISTRY_NAME string = containerRegistry.name

//------------------------------------------------------------------------------
// Container Apps Environment Outputs
//------------------------------------------------------------------------------
@description('Name of the Container Apps Environment')
output AZURE_CONTAINER_APPS_ENVIRONMENT_NAME string = containerAppEnvironment.name

@description('Resource ID of the Container Apps Environment')
output AZURE_CONTAINER_APPS_ENVIRONMENT_ID string = containerAppEnvironment.id

@description('Default domain of the Container Apps Environment')
output AZURE_CONTAINER_APPS_ENVIRONMENT_DEFAULT_DOMAIN string = containerAppEnvironment.properties.defaultDomain

