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
and `CONTROL_PLANE=1` and include `SKIP_REPOS_0=1`.

An empty control plane will be deployed which you will migrate to.
It is necessary to do this in order to establish the isolated
networks before installing the wallaby overcloud.

Use [account.sh](account.sh) to create a stack user on edpm-compute0.
Use this account on the edpm-compute-0 host in the next section.

## Install TripleO

The commands in this section should be run on the edpm-compute-0 node.

Use the scripts of the [standalone](standalone) directory to install
[TripleO Standalone](https://docs.openstack.org/project-deploy-guide/tripleo-docs/latest/deployment/standalone.html)
on edpm-compute-0 with Ceph.

The [verify.sh](standalone/verify.sh) script creates a small workload
on the standalone Wallaby to migrate.

## Configure the Control Plane to use Ceph

The commands in this section should be run on the hypervisor.

In a migration scenario the internal Ceph cluster is left running and
the NG system is configured to use it externally.

Run [ceph_secret.sh](../ng/ceph/ceph_secret.sh) to extract the Ceph
configuration from `edpm-compute-0` and store it as a secret in the
`openstack` namespace.

Run [control_plane_to_ceph.sh]](../ng/ceph/control_plane_to_ceph.sh)
to configure the empty control plane to connect to the Ceph cluster
running on the standalone wallaby system.

Use [test.sh](../ng/test.sh) to confirm that Glance on the NG system
is using the ceph cluster.

## Configure EDPM Compute node

In this step edpm-compute-1 is configured as a compute node with
network isolation.

The [dataplane_cr.sh](dataplane_cr.sh) script will extract variables
from the k8s environment and use kustomize to create a dataplane CR
with edpm-compute-1 but not edpm-compute-0 since it should not be
configured as an EDPM node and remains a standalone tripleo node.
edpm-compute-1 should also be configured to use the Ceph cluster
on edpm-compute-0.

```
./dataplane_cr.sh > dataplane_cr.yaml
oc create -f dataplane_cr.yaml
```
