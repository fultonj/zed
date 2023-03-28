# Re-run Ansible on EDPM

To re-run the EDPM Infra Ansible jobs recreate the CR. For example:
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
