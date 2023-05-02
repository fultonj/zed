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
and `CONTROL_PLANE=1` but don't run `EDPM_NODE_REPOS` for
`EDPM_COMPUTE_SUFFIX=0`.

An empty control plane will be deployed which you will migrate to.
It is necessary to do this in order to establish the isolated
networks before installing the wallaby overcloud.

Use [account.sh](account.sh) to create a stack user on edpm-compute0.
Use this account on the edpm-compute-0 host in the next section.

## Install TripleO

Use the scripts of the [standalone](standalone) directory to install
[TripleO Standalone](https://docs.openstack.org/project-deploy-guide/tripleo-docs/latest/deployment/standalone.html)
on edpm-compute-0.

Ensure edpm-compute-0 has NOT been had it's repos configured with
`make edpm_compute_repos`.

<!--
### Network Isolation

In the following example:

  https://review.opendev.org/c/openstack/tripleo-quickstart-extras/+/834352/81/roles/standalone/tasks/storage-network.yml#47

TripleO Standalone CI uses a Heat environment file containing
`DeployedNetworkEnvironment`, `ControlPlaneVipData`, and
`NodePortMap` properties. This is done to tell TripleO to use
an already provisioned storage network. It should be possible to
expand this example so that all of the pre provisioned networks
are used by OpenStack.
-->

## Configure EDPM Compute node

In this step edpm-compute-1 is configured as a compute node with
network isolation.

Ensure edpm-compute-1 has its repos configured
```
pushd ~/install_yamls/devsetup/
make edpm_compute_repos EDPM_COMPUTE_SUFFIX=1
popd
```

The [dataplane_cr.sh](dataplane_cr.sh) script will extract variables
from the k8s environment and use kustomize to create a dataplane CR
with `deployStrategy: false` for edpm-compute-0 so it is not
configured as an EDPM node and remains a standalone tripleo node.

```
./dataplane_cr.sh > dataplane_cr.yaml
oc create -f dataplane_cr.yaml
```
