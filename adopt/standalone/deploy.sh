#!/usr/bin/env bash

export NEUTRON_INTERFACE=eth0
# export NEUTRON_INTERFACE=vlan44
export CTLPLANE_IP=192.168.122.100
export CTLPLANE_VIP=192.168.122.99
export NETMASK=24
export DNS_SERVERS=192.168.122.1
export NTP_SERVERS=pool.ntp.org
#export NTP_SERVER=clock.corp.redhat.com
export GATEWAY=192.168.122.1
export BRIDGE="br-ctlplane"
# export BRIDGE="br-ex"

cat <<EOF > standalone_parameters.yaml
parameter_defaults:
  CloudName: $CTLPLANE_IP
  ControlPlaneStaticRoutes:
    - ip_netmask: 0.0.0.0/0
      next_hop: $GATEWAY
      default: true
  Debug: true
  DeploymentUser: $USER
  DnsServers: $DNS_SERVERS
  NtpServer: $NTP_SERVERS
  # needed for vip & pacemaker
  KernelIpNonLocalBind: 1
  DockerInsecureRegistryAddress:
  - $CTLPLANE_IP:8787
  NeutronPublicInterface: $NEUTRON_INTERFACE
  # domain name used by the host
  NeutronDnsDomain: localdomain
  # re-use ctlplane bridge for public net
  NeutronBridgeMappings: datacentre:$BRIDGE
  NeutronPhysicalBridge: $BRIDGE
  # enable to force metadata for public net
  #NeutronEnableForceMetadata: true
  StandaloneEnableRoutedNetworks: false
  StandaloneHomeDir: $HOME
  InterfaceLocalMtu: 1500
  # Needed if running in a VM
  NovaComputeLibvirtType: qemu
  ValidateGatewaysIcmp: false
  ValidateControllersIcmp: false
EOF

if [[ ! -d ~/templates ]]; then
    ln -s /usr/share/openstack-tripleo-heat-templates ~/templates
fi

sudo openstack tripleo deploy \
  --templates ~/templates \
  --standalone-role Standalone \
  -e ~/templates/environments/standalone/standalone-tripleo.yaml \
  -e ~/templates/environments/low-memory-usage.yaml \
  -e ~/containers-prepare-parameters.yaml \
  -e standalone_parameters.yaml \
  -e ~/templates/environments/cephadm/cephadm.yaml \
  -e ~/deployed_ceph.yaml \
  -e ~/templates/environments/deployed-network-environment.yaml \
  -e deployed_network.yaml \
  -r ~/templates/roles/Standalone.yaml \
  -n network_data.yaml \
  --local-ip=$CTLPLANE_IP/$NETMASK \
  --control-virtual-ip=$CTLPLANE_VIP \
  --output-dir $HOME $@
