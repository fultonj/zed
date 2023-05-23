# Ceph on NG

This subdirectory of [ng](..) contains variations to use HCI Ceph.

## Infrastructure

Use [deploy.sh](../deploy.sh) only with the `INFRA` meta-tag and then:

- Follow [install_ceph](install_ceph.md) to install Ceph on EDPM nodes
  (or use [install_ceph.sh](install_ceph.sh))
- Run [ceph_secret.sh](ceph_secret.sh) to create a secret viewable via
  `oc get secret ceph-conf-files -o json | jq -r '.data."ceph.conf"' | base64 -d`

## Control Plane

- Use [deploy.sh](../deploy.sh) only with the `CONTROL_PLANE` meta-tag

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

Create a single OpenStackDataPlane CR or create a
OpenStackDataPlaneRole CR with multiple OpenStackDataPlaneNode CRs.

### Create a single OpenStackDataPlane CR
```
./dataplane_cr.sh > dataplane_cr.yaml
oc create -f dataplane_cr.yaml
```
I use [dataplane_cr.sh](dataplane_cr.sh) to create 
a OpenStackDataPlane CR with necessary the Ceph properties.
I can then easily create and delete the CR to
[re-run ansible](../rerun_ansible.md).

This option was used for the asciinema demo below but does not
configure Nova to use the `vms` pool.

### Create a OpenStackDataPlaneRole and multiple OpenStackDataPlaneNodes

This option uses the
[novaTemplate](https://openstack-k8s-operators.github.io/dataplane-operator/openstack_dataplanerole/#novatemplate)
feature so that nova is configured to use the `vms` pool. Becuase the
`novaTemplate` is not supported for OpenStackDataPlane (which contains
both nodes and roles) a role is created with the `novaTemplate` and
then nodes are created under that role.
```
./dataplane_role_cr.sh > dataplane_role_cr.yaml
oc create -f dataplane_role_cr.yaml
oc create -f edpm-compute-0.yaml
oc create -f edpm-compute-1.yaml
oc create -f edpm-compute-2.yaml
```

## Deploy EDPM

The `oc create` commands from either of last sections should have
launched Ansible. Use `watch "oc get pods | grep edpm"` and
[watch_ansible.sh](../watch_ansible.sh) to watch ansible run.

Use the PET option in [test.sh](../test.sh) to boot an instance from a volume.

[![asciicast](https://asciinema.org/a/571558.svg)](https://asciinema.org/a/571558)
