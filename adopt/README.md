# Adoption Development Environment

Use
[install_yamls/devsetup](https://github.com/openstack-k8s-operators/install_yamls/tree/master/devsetup)
to configure edpm-compute-0 with isolated networks
which can acceess the new control plane on k8s.

Install OpenStack Wallaby using
[TripleO
Standalone](https://docs.openstack.org/project-deploy-guide/tripleo-docs/latest/deployment/standalone.html)
on the edpm-compute-0 node.

Use the resultant environment to practice migrating the Wallaby
OpenStack to the one which will run on k8s.

## Deploy CRC and edpm-compute

Use [deploy.sh](../ng/deploy.sh) with nearly all tasks under INFRA=1
to get an edpm-compute-0 node with a potential isolated network
connection, CRC, and OpenStack operators but no control-plane and
data-plane. Do not `make edpm_compute_repos` since we will configure
repos for TripleO Wallaby instead later.

## Configure Isolated Networks with EDPM Ansible

Run the edpm-ansible role to configure and verify the network
but not run other edpm-ansible roles.

Use
[Running a local copy of an operator for development without conflicts](https://github.com/openstack-k8s-operators/docs/blob/main/running_local_operator.md)
to run a local copy of the
[stop_after patch](https://github.com/fultonj/dataplane-operator/tree/stop_after)
(TODO).

Use [dataplane_cr.sh](../ng/dataplane_cr.sh) to create
an OpenStackDataPlane CR.
```
./dataplane_cr.sh > dataplane_cr.yaml
```
Modify `dataplane_cr.yaml` to stop after the after
`ConfigureNetwork` and `ValidateNetwork` from
[deployment.go](https://github.com/openstack-k8s-operators/dataplane-operator/blob/main/pkg/deployment/deployment.go)
```
StopAfter: ValidateNetwork
```
Set `Deploy: false` for all nodes except edpm-compute-0.

Create the partial dataplane CR
```
oc create -f dataplane_cr.yaml
```

After the validate network job has completed successfully
and the operator has reported it has suceeded because of
the `stop_after` patch, set `Deploy: False` for edpm-compute-0
and re-apply the spec. We do this because we don't want our operators
modifying edpm-compute-0 further since it will be managed by TripleO.
When other edpm-compute nodes are added later, set `Deploy: True` for
them at that time.

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
