# Ceph on NG

This subdirectory of [ng](..) contains variations to use HCI Ceph.

## Infrastructure

Use [deploy.sh](../deploy.sh) only with the `INFRA` meta-tag and then:

- Follow [install_ceph](install_ceph.md) to install Ceph on EDPM nodes
- Run [ceph_secret.sh](ceph_secret.sh) to create a secret viewable via
  `oc get secret ceph-conf-files -o json | jq -r '.data."ceph.conf"' | base64 -d`

## Control Plane

- Use [deploy.sh](../deploy.sh) only with the `OPERATOR` and
  `CONTROL_PLANE` meta-tags.

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

Create an 
[OpenStackDataPlane](https://openstack-k8s-operators.github.io/dataplane-operator/openstack_dataplane)
CR using [dataplane_cr.yaml](dataplane_cr.yaml).

```
oc create -f dataplane_cr.yaml
```

This CR is based on the output of `make edpm_deploy` but was modified
to include `extraMounts` and `ansibleVars` for the 
[edpm_ceph_client_files role](https://github.com/openstack-k8s-operators/edpm-ansible/tree/main/roles/edpm_ceph_client_files).

Use `watch -5 "oc get pods | grep edpm"` and
[watch_ansible.sh](../watch_ansible.sh) to watch ansible run and
[test.sh](../test.sh) to boot an instance which uses Ceph.
