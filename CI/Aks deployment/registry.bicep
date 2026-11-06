@description('The name of the container registry')
param registryName string
@description('The principal ID of the AKS cluster')
param aksPrincipalId string
@description('Tags for the resources')
param tags object

param acrPullRoleId string

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: registryName
  location: resourceGroup().location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
  tags: tags
}

resource assignAcrPullToAks 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, registryName, aksPrincipalId, 'AssignAcrPullToAks')
  scope: containerRegistry
  properties: {
    description: 'Assign AcrPull role to AKS'
    principalId: aksPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: acrPullRoleId
  }
}

output name string = containerRegistry.name
