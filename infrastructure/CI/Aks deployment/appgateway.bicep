@description('Name of the Application Gateway subnet')
param appgw_subnet string = 'appgw-subnet-001'

@description('Name of the Application Gateway Public IP')
param appgw_public_ip_name string = 'appgwPublicIP'

@description('Name of the Application Gateway')
param appgw_name string = 'appgw-01'

@description('Address prefix for the Application Gateway subnet')
param appgw_subnet_prefix string = '10.240.2.0/24'

@description('Name of the existing Virtual Network')
param vnet_name string

@description('Location of the resources')
param location string = resourceGroup().location

param applicationGatewayUserDefinedManagedIdentityId string

param appGatewayTier string ='standard'

param publicipTier string ='standard'

var applicationGatewayBackendAddressPoolName = 'applicationGatewayBackendPool'
var applicationGatewayBackendAddressPoolId = resourceId(
  'Microsoft.Network/applicationGateways/backendAddressPools',
  appgw_name,
  applicationGatewayBackendAddressPoolName
)
var applicationGatewayRequestRoutingRuleName = 'default'

var applicationGatewayHttpListenerName = 'applicationGatewayHttpListener'
var applicationGatewayHttpListenerId = resourceId(
  'Microsoft.Network/applicationGateways/httpListeners',
  appgw_name,
  applicationGatewayHttpListenerName
)

var applicationGatewayBackendHttpSettingsName = 'applicationGatewayBackendHttpSettings'
var applicationGatewayBackendHttpSettingsId = resourceId(
  'Microsoft.Network/applicationGateways/backendHttpSettingsCollection',
  appgw_name,
  applicationGatewayBackendHttpSettingsName
)

var applicationGatewayFrontendPortName = 'applicationGatewayFrontendPort'
var applicationGatewayFrontendPortId = resourceId(
  'Microsoft.Network/applicationGateways/frontendPorts',
  appgw_name,
  applicationGatewayFrontendPortName
)

var applicationGatewayIPConfigurationName = 'applicationGatewayIPConfiguration'
var applicationGatewayFrontendIPConfigurationName = 'applicationGatewayFrontendIPConfiguration'
var applicationGatewayFrontendIPConfigurationId = resourceId(
  'Microsoft.Network/applicationGateways/frontendIPConfigurations',
  appgw_name,
  applicationGatewayFrontendIPConfigurationName
)

resource publicIp 'Microsoft.Network/publicIPAddresses@2023-02-01' = {
  name: appgw_public_ip_name
  location: location
  sku: {
    name: publicipTier
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-02-01' existing = {
  name: vnet_name
}

resource appgwSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-02-01' = {
  parent: vnet
  name: appgw_subnet
  properties: {
    addressPrefix: appgw_subnet_prefix
  }
}

resource appGateway 'Microsoft.Network/applicationGateways@2023-02-01' = {
  name: appgw_name
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${applicationGatewayUserDefinedManagedIdentityId}': {}
    }
  }
  properties: {
    sku: {
      name: appGatewayTier
      tier: appGatewayTier
      //remove capacity when autoscale is enabled
      capacity: 1 
    }
    gatewayIPConfigurations: [
      {
        name: applicationGatewayIPConfigurationName
        properties: {
          subnet: {
            id: appgwSubnet.id
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: applicationGatewayFrontendIPConfigurationName
        properties: {
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: applicationGatewayFrontendPortName
        properties: {
          port: 80
        }
      }
    ]
    // remove capacity config in sku when autoscale is enabled.
    /*
    autoscaleConfiguration: {
      maxCapacity: 2
      minCapacity: 0
    }
    */
    enableHttp2: false
    probes: [
      {
        name: 'defaultHttpProbe'
        properties: {
          protocol: 'Http'
          path: '/'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: true
          minServers: 0
        }
      }
      {
        name: 'defaultHttpsProbe'
        properties: {
          protocol: 'Https'
          path: '/'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: true
          minServers: 0
        }
      }
    ]
    backendAddressPools: [
      {
        name: applicationGatewayBackendAddressPoolName
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: applicationGatewayBackendHttpSettingsName
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
        }
      }
    ]
    httpListeners: [
      {
        name: applicationGatewayHttpListenerName
        properties: {
          frontendIPConfiguration: {
            id: applicationGatewayFrontendIPConfigurationId
          }
          frontendPort: {
            id: applicationGatewayFrontendPortId
          }
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: applicationGatewayRequestRoutingRuleName
        properties: {
          ruleType: 'Basic'
          priority: 1
          httpListener: {
            id: applicationGatewayHttpListenerId
          }
          backendAddressPool: {
            id: applicationGatewayBackendAddressPoolId
          }
          backendHttpSettings: {
            id: applicationGatewayBackendHttpSettingsId
          }
        }
      }
    ]
  }
  dependsOn: [
    publicIp
    vnet
  ]
}

output applicationGatewayId string = appGateway.id
output agwsubnetId string = appgwSubnet.id
