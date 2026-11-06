@description('Naming env for the resources e.g. dev, test, prod')
param env string
@description('The public SSH key')
@secure()
param publicsshKey string
@description('The name of the cluster')
param clusterName string
@description('The location of the resources')
param location string = resourceGroup().location
@description('The admin username for the nodes in the cluster')
param nodeAdminUsername string
@description('An array of AAD group object ids to give administrative access.')
param adminGroupObjectIDs array = []
@description('The VM size to use in the cluster')
param nodeVmSize string
@minValue(1)
@maxValue(50)
@description('The number of nodes for the cluster.')
param nodeCount int = 1
@maxValue(100)
@description('Max number of nodes to scale up to')
param maxNodeCount int = 3
@description('Disk size (in GB) to provision for each of the agent pool nodes. This value ranges from 0 to 1023. Specifying 0 will apply the default disk size for that agentVMSize')
param osDiskSizeGB int
@description('Log Analytics Workspace Tier')
@allowed([
  'Free'
  'Standalone'
  'PerNode'
  'PerGB2018'
  'Premium'
])
param workspaceTier string
@description('Tags for the resources')
param tags object

@description('Specifies the type for the user node pool: VirtualMachineScaleSets or AvailabilitySet')
@allowed([
  'VirtualMachineScaleSets'
  'AvailabilitySet'
])
param userNodePoolType string = 'VirtualMachineScaleSets'

@description('Specifies whether the httpApplicationRouting add-on is enabled or not.')
param httpApplicationRoutingEnabled bool = false

@description('Specifies whether the aciConnectorLinux add-on is enabled or not.')
param aciConnectorLinuxEnabled bool = false

@description('Specifies whether the azurepolicy add-on is enabled or not.')
param azurePolicyEnabled bool = true

@description('Specifies whether the kubeDashboard add-on is enabled or not.')
param kubeDashboardEnabled bool = false

@description('Specifies whether the pod identity addon is enabled..')
param podIdentityProfileEnabled bool = false

@description('Specifies the scan interval of the auto-scaler of the AKS cluster.')
param autoScalerProfileScanInterval string = '10s'

@description('Specifies the name of the Application Gateway.')
param applicationGatewayName string = 'appgw-${uniqueString(resourceGroup().id)}'

@description('Specifies the CIDR notation IP range from which to assign pod IPs when kubenet is used.')
param aksClusterPodCidr string = '10.244.0.0/16'

@description('A CIDR notation IP range from which to assign service cluster IPs. It must not overlap with any Subnet IP ranges.')
param aksClusterServiceCidr string = '10.3.0.0/16'

@description('Specifies the IP address assigned to the Kubernetes DNS service. It must be within the Kubernetes service address range specified in serviceCidr.')
param aksClusterDnsServiceIP string = '10.3.0.10'

@description('The virtual network address prefixes')
param vnetAddressPrefixes array

@description('The subnet address env')
param subnetAddressPrefix string

@description('Specifies the sku of the load balancer used by the virtual machine scale sets used by nodepools.')
@allowed([
  'basic'
  'standard'
])
param aksClusterLoadBalancerSku string = 'standard'

@description('Specifies the network plugin used for building Kubernetes network. - azure or kubenet.')
@allowed([
  'azure'
  'kubenet'
])
param aksClusterNetworkPlugin string = 'azure'

@description('Specifies the network policy used for building Kubernetes network. - calico or azure')
@allowed([
  'azure'
  'calico'
])
param aksClusterNetworkPolicy string = 'azure'

@description('Specifies outbound (egress) routing method. - loadBalancer or userDefinedRouting.')
@allowed([
  'loadBalancer'
  'userDefinedRouting'
])
param aksClusterOutboundType string = 'loadBalancer'

param appGatewayTier string

param publicipTier string

param systemNodePoolName string

param userNodePoolName string

var aksClusterUserDefinedManagedIdentityName = '${clusterName}ManagedIdentity'
var aadPodIdentityUserDefinedManagedIdentityName = '${clusterName}AadPodManagedIdentity'
var applicationGatewayUserDefinedManagedIdentityName = '${applicationGatewayName}ManagedIdentity'

var contributorRoleDefinitionName = 'b24988ac-6180-42a0-ab88-20f7382dd24c'
var acrPullRoleDefinitionName = '7f951dda-4ed3-4680-a7ca-43fe172d538d'

var contributorRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', contributorRoleDefinitionName)
var acrPullRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', acrPullRoleDefinitionName)

module vnet 'vnet.bicep' = {
  name: 'vnetDeploy'
  params: {
    vnetName: '${env}-vnet-${clusterName}-${location}'
    subnetName: '${env}-snet-${clusterName}-${location}'
    vnetAddressPrefixes: vnetAddressPrefixes
    subnetAddressPrefix: subnetAddressPrefix
    tags: tags
  }
}

module identity 'identity.bicep' = {
  name: 'identityComponent'
  params: {
    location: location
    applicationGatewayUserDefinedManagedIdentityName: applicationGatewayUserDefinedManagedIdentityName
    aksClusterUserDefinedManagedIdentityName: aksClusterUserDefinedManagedIdentityName
    aadPodIdentityUserDefinedManagedIdentityName: aadPodIdentityUserDefinedManagedIdentityName
  }
}

module appgateway 'appgateway.bicep' = {
  name: 'ingressGatewayDeploy'
  params: {
    vnet_name: '${env}-vnet-${clusterName}-${location}'
    applicationGatewayUserDefinedManagedIdentityId: identity.outputs.applicationGatewayUserDefinedManagedIdentityId
    appGatewayTier: appGatewayTier
    publicipTier: publicipTier

  }

  dependsOn: [
    vnet
  ]
}

module aks 'aks.bicep' = {
  name: 'aksDeploy'
  params: {
    env: env
    clusterName: clusterName    
    subnetId: vnet.outputs.subnetId
    agwId: appgateway.outputs.applicationGatewayId
    nodeAdminUsername: nodeAdminUsername
    adminGroupObjectIDs: adminGroupObjectIDs
    nodeVmSize: nodeVmSize
    nodeCount: nodeCount
    maxNodeCount: maxNodeCount
    osDiskSizeGB: osDiskSizeGB
    sshPublicKey: publicsshKey
    workspaceTier: workspaceTier
    aksClusterUserDefinedManagedIdentityPrincipalId: identity.outputs.aksClusterUserDefinedManagedIdentityPrincipalId
    aksClusterUserDefinedManagedIdentityId: identity.outputs.aksClusterUserDefinedManagedIdentityId
    contributorRoleId: contributorRoleId
    tags: tags
    httpApplicationRoutingEnabled: httpApplicationRoutingEnabled 
    aciConnectorLinuxEnabled: aciConnectorLinuxEnabled 
    azurePolicyEnabled: azurePolicyEnabled 
    kubeDashboardEnabled: kubeDashboardEnabled
    podIdentityProfileEnabled: podIdentityProfileEnabled
    aksClusterDnsServiceIP: aksClusterDnsServiceIP
    aksClusterLoadBalancerSku: aksClusterLoadBalancerSku
    aksClusterNetworkPlugin: aksClusterNetworkPlugin
    aksClusterNetworkPolicy: aksClusterNetworkPolicy
    aksClusterOutboundType: aksClusterOutboundType
    aksClusterPodCidr: aksClusterPodCidr
    aksClusterServiceCidr: aksClusterServiceCidr
    systemNodePoolName: systemNodePoolName
    userNodePoolName: userNodePoolName
  }

  dependsOn: [
    vnet
    appgateway
  ]
}

module registry 'registry.bicep' = {
  name: 'registryDeploy'
  params: {
    registryName: 'your-acr-name'
    acrPullRoleId: acrPullRoleId
    aksPrincipalId: aks.outputs.aksClusterKubeletidentityObjectId
    tags: tags
  }

  dependsOn: [
    aks
  ]
}

module roleAssignment 'roleassignment.bicep' = {
  name: 'roleAssignmentComponent'
  params: {
    applicationGatewayUserDefinedManagedIdentityId: identity.outputs.applicationGatewayUserDefinedManagedIdentityId
    applicationGatewayId: appgateway.outputs.applicationGatewayId
    aksClusterIngressApplicationGatewayObjectId: aks.outputs.aksClusteringressApplicationGatewayIdentity
  }
  dependsOn: [
    aks
    appgateway
    identity
  ]
}
