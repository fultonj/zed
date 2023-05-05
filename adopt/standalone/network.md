# Networking

The control plane netowrk (192.168.122.0/24) is pre-configured.

The following isolated networks are set up on the podified control
plane and edpm nodes after edpm-ansible runs.
```
Tenant   vlan22 172.10.0.0/24
Internal vlan20 172.17.0.0/24
Storage  vlan21 172.18.0.0/24
External vlan44 172.19.0.0/24
```
The [network.sh](network.sh) script configures the above networks on
edpm-compute-0 and modifes tripleo-ansible so that the standalone
deployment does not disable them.

We configure the above networks before running the
[standalone deploy](https://docs.openstack.org/project-deploy-guide/tripleo-docs/latest/deployment/standalone.html)
so that we can deploy ceph on the storage network.

## More Details

If we let edpm-ansible run on edpm-compute-0 we would have
[os-net-config-samples/edpm-compute-0.yaml](os-net-config-samples/edpm-compute-0.yaml).

[deploy.sh](deploy.sh) will effectively create
[os-net-config-samples/standalone.yaml](os-net-config-samples/standalone.yaml)
and `os-net-config -c` it (removing the vlans if they were
pre-configured with os-net-config).

We need a network configuration on edpm-compute-0 which
is compatible with both; i.e. produces a working standalone
overcloud but survives the [ping_test.sh](ping_test.sh).

Afer that the standalone deployment can be modified with a
[DeployedNetworkEnvironment](https://review.opendev.org/c/openstack/tripleo-quickstart-extras/+/834352/81/roles/standalone/tasks/storage-network.yml)
and actually use the isolated networks.

### Update standalone.j2 template

[standalone.j2](https://opendev.org/openstack/tripleo-ansible/src/branch/master/tripleo_ansible/roles/tripleo_network_config/templates/standalone.j2)
is installed in the following path after [pre.sh](pre.sh) runs:
```
/usr/share/ansible/roles/tripleo_network_config/templates/standalone.j2
```
Replace it with a modifed copy of [standalone.j2](standalone.j2)
before running [deploy.sh](deploy.sh) so the exteranl networks
survive the standalone deployment.
