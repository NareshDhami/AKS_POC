@description('The environment env of the Managed Cluster resource e.g. dev, test & prod')
param env string

@description('The name of the Managed Cluster resource')
param clusterName string

@description('Resource location')
param location string = resourceGroup().location

@description('Kubernetes version to use')
param kubernetesVersion string = '1.31.1'

@description('The VM Size to use for each node')
param nodeVmSize string

@minValue(1)
@maxValue(50)
@description('The number of nodes for the cluster.')
param nodeCount int

@maxValue(100)
@description('Max number of nodes to scale up to')
param maxNodeCount int

@description('The node pool name')
param systemNodePoolName string = 'systemVMNodePool'

@description('The node pool name')
param userNodePoolName string = 'spotVMNodePool'

@minValue(0)
@maxValue(1023)
@description('Disk size (in GB) to provision for each of the agent pool nodes. This value ranges from 0 to 1023. Specifying 0 will apply the default disk size for that agentVMSize')
param osDiskSizeGB int
param nodeAdminUsername string

@description('Availability zones to use for the cluster nodes')
param availabilityZones array = ['1'] // this needs to be different for prod. may be enable more zones.

@description('Allow the cluster to auto scale to the max node count')
param enableAutoScaling bool = true

@description('SSH RSA public key for all the nodes')
@secure()
param sshPublicKey string

@description('Tags for the resources')
param tags object

@description('Log Analytics Workspace Tier')
@allowed([
'CapacityReservation'
'Free'
'LACluster'
'PerGB2018'
'PerNode'
'Premium'
'Standalone'
'Standard' 
])
param workspaceTier string

@description('Subnet id to use for the cluster')
param subnetId string

@description('An array of AAD group object ids for administration')
param adminGroupObjectIDs array = []

@description('id of the application gateway')
param agwId string
param contributorRoleId string
param aksClusterUserDefinedManagedIdentityPrincipalId string
param aksClusterUserDefinedManagedIdentityId string
param aciConnectorLinuxEnabled bool
param azurePolicyEnabled bool
param kubeDashboardEnabled bool
param podIdentityProfileEnabled bool
param aksClusterNetworkPlugin string
param aksClusterNetworkPolicy string
param aksClusterPodCidr string
param aksClusterServiceCidr string
param aksClusterDnsServiceIP string
param aksClusterOutboundType string
param aksClusterLoadBalancerSku string

param httpApplicationRoutingEnabled bool = false

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: '${env}-oms-${clusterName}-${location}'
  location: location
  properties: {
    sku: {
      name: workspaceTier
    }
  }
  tags: tags
}

resource aksContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, aksClusterUserDefinedManagedIdentityPrincipalId, 'Contributor')
  properties: {
    roleDefinitionId: contributorRoleId
    description: 'Assign the cluster user-defined managed identity contributor role on the resource group.'
    principalId: aksClusterUserDefinedManagedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource aksCluster 'Microsoft.ContainerService/managedClusters@2024-09-01' = {
  name: '${env}-aks-${clusterName}-${location}'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${aksClusterUserDefinedManagedIdentityId}': {}
    }
  }
  tags: tags  
  properties: {
    kubernetesVersion: kubernetesVersion
    dnsPrefix: '${clusterName}-dns' 
    agentPoolProfiles: [
      {        
        name: systemNodePoolName
        osDiskSizeGB: osDiskSizeGB
        osDiskType: 'Ephemeral'        
        count: nodeCount
        enableAutoScaling: enableAutoScaling
        minCount: nodeCount
        maxCount: maxNodeCount
        vmSize: nodeVmSize       
        osType: 'Linux'
        type: 'VirtualMachineScaleSets'
        mode: 'System'
        availabilityZones: availabilityZones
        enableEncryptionAtHost: false
        vnetSubnetID: subnetId
      }
      {        
        name: userNodePoolName
        osDiskSizeGB: osDiskSizeGB
        osDiskType: 'Ephemeral'        
        count: nodeCount
        enableAutoScaling: enableAutoScaling
        minCount: nodeCount
        maxCount: maxNodeCount
        vmSize: 'Standard_B2ps_v2'
        scaleSetPriority: 'Spot' //default: regular. spot is cheaper.
        scaleSetEvictionPolicy: 'Delete'
        spotMaxPrice: -1 // Accepts the current Spot price, ensuring the lowest cost         
        osType: 'Linux'
        type: 'VirtualMachineScaleSets'
        mode: 'User'
        availabilityZones: availabilityZones
        enableEncryptionAtHost: false
        vnetSubnetID: subnetId
      }
    ]

    networkProfile: {
      networkPlugin: aksClusterNetworkPlugin
      networkPolicy: aksClusterNetworkPolicy
      podCidr: aksClusterPodCidr
      serviceCidr: aksClusterServiceCidr
      dnsServiceIP: aksClusterDnsServiceIP
      outboundType: aksClusterOutboundType
      loadBalancerSku: aksClusterLoadBalancerSku
    }

    aadProfile: !empty(adminGroupObjectIDs) ? {
      managed: true
      adminGroupObjectIDs: adminGroupObjectIDs
    } : null

    addonProfiles: {
      httpApplicationRouting: {
        enabled: httpApplicationRoutingEnabled
      }

      aciConnectorLinux: {
        enabled: aciConnectorLinuxEnabled
      }

      azurepolicy: {
        enabled: azurePolicyEnabled
        config: {
          version: 'v2'
        }
      }

      kubeDashboard: {
        enabled: kubeDashboardEnabled
      }

      omsAgent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: logAnalyticsWorkspace.id
        }
      }

      ingressApplicationGateway: {
        config: {
          applicationGatewayId: agwId
        }
        enabled: true
      } 
    }

    podIdentityProfile: {
      enabled: podIdentityProfileEnabled
    }
    enableRBAC: true

    linuxProfile: {      
      adminUsername: nodeAdminUsername
      ssh: {
        publicKeys: [
          {
            keyData: sshPublicKey
          }
        ]
      }      
    }
  }

  dependsOn: [
    logAnalyticsWorkspace    
  ]
}

output controlPlaneFQDN string = reference('${env}-aks-${clusterName}-${location}').fqdn
output aksClusterKubeletidentityObjectId string = aksCluster.properties.identityProfile.kubeletidentity.objectId
output aksClusteringressApplicationGatewayIdentity string = aksCluster.properties.addonProfiles.ingressApplicationGateway.identity.objectId
