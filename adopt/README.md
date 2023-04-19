# Adoption Development Environment

Use
[install_yamls/devsetup](https://github.com/openstack-k8s-operators/install_yamls/tree/master/devsetup)
to configure edpm-compute-0 with isolated networks
which can access the new control plane on k8s.

Install OpenStack Wallaby using
[TripleO
Standalone](https://docs.openstack.org/project-deploy-guide/tripleo-docs/latest/deployment/standalone.html)
on the edpm-compute-0 node.

Use the resultant environment to practice migrating the Wallaby
OpenStack to the one which will run on k8s.

## Deploy CRC and edpm-compute

Use [deploy.sh](../ng/deploy.sh) with all tasks under `INFRA=1`
and `CONTROL_PLANE=1`.

An empty control plane will be deployed which you will migrate to.
It is necessary to do this in order to establish the isolated
networks before installing the wallaby overcloud.

## Configure Isolated Networks with EDPM Ansible

Run the edpm-ansible role to configure the network 
but not run other edpm-ansible roles. E.g. have it stop before
`InstallOS` in [deployment.go](https://github.com/openstack-k8s-operators/dataplane-operator/blob/main/pkg/deployment/deployment.go#L122).

For now we'll do this by creating [dataplane_cr.yaml](dataplane_cr.yaml)
but deleting it while the network validation is running as indicated
by [watch_ansible.sh](../ng/watch_ansible.sh). A better method can be
used later.
```
oc create -f dataplane_cr.yaml
./watch_ansible.sh
```
When `PLAY [osp.edpm.edpm_nodes_validation]` starts run the following:
```
oc delete -f dataplane_cr.yaml
```
SSH into the node 
```
$(bash ../ng/ssh_node.sh)
```

## Install TripleO

Follow
[TripleO Standalone](https://docs.openstack.org/project-deploy-guide/tripleo-docs/latest/deployment/standalone.html)
on edpm-compute-0 but make the following modifications.

### Network Isolation

In the following example:

  https://review.opendev.org/c/openstack/tripleo-quickstart-extras/+/834352/81/roles/standalone/tasks/storage-network.yml#47

TripleO Standalone CI uses a Heat environment file containing
`DeployedNetworkEnvironment`, `ControlPlaneVipData`, and
`NodePortMap` properties. This is done to tell TripleO to use
an already provisioned storage network. It should be possible to
expand this example so that all of the pre provisioned networks
are used by OpenStack.
