# Ceph on NG

This subdirectory of [ng](..) contains variations to use Ceph in two
possible Topologies.

## Topologies

### HCI
- edpm-compute0: Ceph mon/mgr/osd and Nova compute
- edpm-compute1: Ceph mon/mgr/osd and Nova compute
- edpm-compute2: Ceph mon/mgr/osd and Nova compute

Ceph is currently deployed without network isolation in this
configuration.

### External
- edpm-compute0: Ceph mon/mgr/osd
- edpm-compute1: Nova compute
- edpm-compute2: Nova compute

The advantage of this is that you can rebuild edpm-compute{1,2}
without needing to re-install Ceph. Just run [clean.sh](../clean.sh)
with `NODE_START=1` to not clean up edpm-compute0. Ceph is also
configured with network isolation.

## HCI Infrastructure

Use [deploy.sh](../deploy.sh) only with the `INFRA` meta-tag with
`NODE_START=0` and then:

Follow [install_ceph](install_ceph.md) to install Ceph on all EDPM
nodes or use [install_ceph.sh](install_ceph.sh) with the following
parameters:
```
NET=0
ISO=0
PRE=1
BOOT=1
SINGLE_OSD=0
SSH_KEYS=1
SPEC=1
CEPHX=1
NODES=2
```
Run [ceph_secret.sh](ceph_secret.sh) to create a secret viewable via
`oc get secret ceph-conf-files -o json | jq -r '.data."ceph.conf"' |
base64 -d`

## External Ceph Infrastructure

Use [deploy.sh](../deploy.sh) only with the `INFRA` meta-tag and with
the following tags so that only edpm-compute0 is deployed.
```
EDPM_NODE=1
EDPM_NODE_DISKS=1
NODES=0
NODE_START=0
```
Use [install_ceph.sh](install_ceph.sh) to install Ceph with network
isolation one a single node with the following parameters.
```
NET=1
ISO=1
PRE=1
BOOT=1
SINGLE_OSD=1
SSH_KEYS=0
SPEC=0
CEPHX=1
NODES=0
```
Run [ceph_secret.sh](ceph_secret.sh) to create a secret viewable via
`oc get secret ceph-conf-files -o json | jq -r '.data."ceph.conf"' | base64 -d`

Use [deploy.sh](../deploy.sh) only with the `INFRA` meta-tag and with
the following tags so that edpm-compute0 is not affected but that
edpm-compute1 and edpm-compute2 are created.
```
EDPM_NODE=1
EDPM_NODE_REPOS=1
EDPM_NODE_DISKS=0
NODES=2
NODE_START=1
```

## Control Plane

- Use [deploy.sh](../deploy.sh) only with the `CONTROL_PLANE` meta-tag

- `oc edit csv/openstack-operator.v0.0.1` and set replicas of `openstack-baremetal-operator-controller-manager` to `0`.

- Run [control_plane_to_ceph.sh](control_plane_to_ceph.sh) which will
  configure the existing Glance pods to use Ceph and create a
  `cinder-volume-ceph` pod.

- Use [test.sh](../test.sh) with `GLANCE` or `CINDER` to confirm
  they are using Ceph.

## Data Plane

Use
[Running a local copy of an operator for development without conflicts](https://github.com/openstack-k8s-operators/docs/blob/main/running_local_operator.md)
to run a local copy of
[nova-operator PR301](https://github.com/openstack-k8s-operators/nova-operator/pull/301).

Create a dataplane CR: 
```
./dataplane_cr.sh > dataplane_cr.yaml
oc create -f dataplane_cr.yaml
```
I use [dataplane_cr.sh](dataplane_cr.sh) to create 
a OpenStackDataPlane CR with necessary the Ceph properties.
I can then easily create and delete the CR to
[re-run ansible](../rerun_ansible.md).

Use `watch "oc get pods | grep edpm"` and
[watch_ansible.sh](../watch_ansible.sh) to watch ansible run.

Use the PET option in [test.sh](../test.sh) to boot an instance from a volume.

### Demo with HCI

[![asciicast](https://asciinema.org/a/571558.svg)](https://asciinema.org/a/571558)
