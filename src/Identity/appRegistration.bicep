resource appRegScript 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'createAppRegistration'
  location: 
  kind: 'AzureCLI'
  properties: {
    azCliVersion: 
    retentionInterval: 
  }
}
