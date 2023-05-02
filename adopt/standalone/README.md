# Standlone Wallaby on EDPM Node

Clone this directory to the edpm node and run the following scripts.

- `git clone git@github.com:fultonj/zed.git -b adopt`
- [pre.sh](pre.sh)
- [network.sh](network.sh)
- [deploy.sh](deploy.sh)
- [ping_test.sh](ping_test.sh)
- [verify.sh](verify.sh)

## Networking

The control plane netowrk (192.168.122.0/24) is pre-configured.

The following isolated networks are set up on the podified control
plane and edpm nodes after edpm-ansible runs.
```
Tenant   vlan22 172.10.0.0/24
Internal vlan20 172.17.0.0/24
Storage  vlan21 172.18.0.0/24
External vlan44 172.19.0.0/24
```
If we let edpm-ansible run on edpm-compute-0 we would have
[os-net-config-samples/edpm-compute-0.yaml](os-net-config-samples/edpm-compute-0.yaml).

[deploy.sh](deploy.sh) will effectively create
[os-net-config-samples/standalone.yaml](os-net-config-samples/standalone.yaml)
and `os-net-config -c` it.

We need a network configuration on edpm-compute-0 which
is compatible with both; i.e. produces a working standalone
overcloud but survives the [ping_test.sh](ping_test.sh).

Afer that the standalone deployment can be modified with a
[DeployedNetworkEnvironment](https://review.opendev.org/c/openstack/tripleo-quickstart-extras/+/834352/81/roles/standalone/tasks/storage-network.yml)
and actually use the isolated networks.
