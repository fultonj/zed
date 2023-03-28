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

Use `watch "oc get pods | grep edpm"` and
[watch_ansible.sh](../watch_ansible.sh) to watch ansible run and
[test.sh](../test.sh) to boot an instance.

To re-run the EDPM Infra Ansible jobs use:
```
oc delete -f dataplane_cr.yaml
oc create -f dataplane_cr.yaml
```
If one of the Nova Ansible jobs fails, then delete the failed job and
restart the Nova operator to re-run it.

Identify failed jobs:
```
$ oc get openstackansibleees.ansibleee.openstack.org | grep False
nova-edpm-compute-0-deploy-libvirt                                                                        False    AnsibleExecutionJob error occured job.name nova-edpm-compute-0-deploy-libvirt job.namespace openstack failed
nova-edpm-compute-1-deploy-libvirt                                                                        False    AnsibleExecutionJob error occured job.name nova-edpm-compute-1-deploy-libvirt job.namespace openstack failed
nova-edpm-compute-2-deploy-libvirt                                                                        False    AnsibleExecutionJob error occured job.name nova-edpm-compute-2-deploy-libvirt job.namespace openstack failed
$
```
Delete failed jobs:
```
$ oc delete OpenStackAnsibleEE nova-edpm-compute-1-deploy-libvirt nova-edpm-compute-2-deploy-libvirt
openstackansibleee.ansibleee.openstack.org "nova-edpm-compute-1-deploy-libvirt" deleted
openstackansibleee.ansibleee.openstack.org "nova-edpm-compute-2-deploy-libvirt" deleted
$
```
Restart nova operator.
```
oc scale deploy nova-operator-controller-manager --replicas=0
oc scale deploy nova-operator-controller-manager --replicas=1
```
In my case I'm running a local copy so I just `^C` and
`OPERATOR_TEMPLATES=$PWD/templates ./bin/manager`. After that I see
the
[deploy-libvirt playbook](https://github.com/openstack-k8s-operators/nova-operator/tree/master/playbooks) running.
```
$ oc get pods | grep edpm | grep libvirt
nova-edpm-compute-0-deploy-libvirt-qnqlm                          1/1     Running     0             7s
nova-edpm-compute-1-deploy-libvirt-wdp7t                          1/1     Running     0             8s
nova-edpm-compute-2-deploy-libvirt-q7hxm                          1/1     Running     0             8s
$
```
