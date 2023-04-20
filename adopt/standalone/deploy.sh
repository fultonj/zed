#!/usr/bin/env bash

export INTERFACE=eth0
export IP=192.168.122.100
export VIP=192.168.122.108
export NETMASK=24
export DNS_SERVERS=192.168.122.1
export NTP_SERVERS=pool.ntp.org

cat <<EOF > standalone_parameters.yaml
parameter_defaults:
  CloudName: $IP
  ControlPlaneStaticRoutes: []
  Debug: true
  DeploymentUser: $USER
  DnsServers: $DNS_SERVERS
  NtpServer: $NTP_SERVERS
  # needed for vip & pacemaker
  KernelIpNonLocalBind: 1
  DockerInsecureRegistryAddress:
  - $IP:8787
  NeutronPublicInterface: $INTERFACE
  # domain name used by the host
  NeutronDnsDomain: localdomain
  # re-use ctlplane bridge for public net
  NeutronBridgeMappings: datacentre:br-ctlplane
  NeutronPhysicalBridge: br-ctlplane
  # enable to force metadata for public net
  #NeutronEnableForceMetadata: true
  StandaloneEnableRoutedNetworks: false
  StandaloneHomeDir: $HOME
  InterfaceLocalMtu: 1500
  # Needed if running in a VM
  NovaComputeLibvirtType: qemu
EOF

if [[ ! -d ~/templates ]]; then
    ln -s /usr/share/openstack-tripleo-heat-templates ~/templates
fi

sudo openstack tripleo deploy \
  --templates ~/templates \
  --local-ip=$IP/$NETMASK \
  --control-virtual-ip $VIP \
  -r ~/templates/roles/Standalone.yaml \
  -e ~/templates/environments/standalone/standalone-tripleo.yaml \
  -e ~/containers-prepare-parameters.yaml \
  -e standalone_parameters.yaml \
  --output-dir $HOME \
  --standalone $@
