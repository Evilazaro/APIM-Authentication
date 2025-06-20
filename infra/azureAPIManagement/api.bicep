param apiManagementName string

param apiLink string

resource apiManagementInstance 'Microsoft.ApiManagement/service@2024-05-01' existing = {
  name: apiManagementName
}

resource productCatalogAPI 'Microsoft.ApiManagement/service/apis@2024-05-01' = {
  name: 'productCatalogAPI'
  parent: apiManagementInstance
  properties: {
    path: 'productcatalog'
    displayName: 'Product Catalog API'
    apiType: 'http'
    format: 'openapi-link'
    value: apiLink
    isCurrent: true
    description: 'API for managing product catalog'
    protocols: [
      'https'
      'http'
    ]
  }
}
