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

Then run [dataplane_cr.sh](dataplane_cr.sh).

### dataplane_cr.sh details

[dataplane_cr.sh](dataplane_cr.sh) creates an 
[OpenStackDataPlane](https://openstack-k8s-operators.github.io/dataplane-operator/openstack_dataplane) CR using the contents of [dataplane_cr](dataplane_cr):

- [dataplane_v1beta1_openstackdataplane.yaml](dataplane_cr/dataplane_v1beta1_openstackdataplane.yaml) is based on the output of `make edpm_deploy` but was modified to include `extraMounts`

- [kustomization.yaml](dataplane_cr/kustomization.yaml) is based on the output of `make edpm_deploy` but was modified to include `ansibleVars` for the [edpm_ceph_client_files role](https://github.com/openstack-k8s-operators/edpm-ansible/tree/main/roles/edpm_ceph_client_files). It is updated by [dataplane_cr.sh](dataplane_cr.sh) which is based on [install_yamls PR 156](https://github.com/openstack-k8s-operators/install_yamls/pull/156) `shell` calls in the Makefile to retrieve values like the `TRANSPORT_URL`.

In summary, dataplane_cr.sh updates kustomization.yaml with values from
`oc get` and then runs `oc kustomize dataplane_cr/ | oc apply -f -`.

### Observe the EDPM deployment

Use `watch "oc get pods | grep edpm"` and
[watch_ansible.sh](../watch_ansible.sh) to watch ansible run.
If necessary [re-run ansible](../rerun_ansible.md).

Use [test.sh](../test.sh) to boot an instance.

