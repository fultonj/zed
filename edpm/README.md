# EDPM - External Data Plane Management Notes

These are my notes on building an environment to test patches of
the dataplane operator.

Creating an
[OpenStackDataPlaneNode](https://openstack-k8s-operators.github.io/dataplane-operator/openstack_dataplanenode)
CR should result in pods being created which run Ansible
to configure RHEL systems as OpenStack Data Plane nodes.

You can observe this behavior on a single hypervisor with two VMs: one
to run OpenShift and one to run RHEL.

## Assumptions

The following are checked out in my home directory on my RHEL8
[hypervisor](https://pcpartpicker.com/user/fultonj/saved/v9KLD3)

- [dataplane-operator](https://github.com/openstack-k8s-operators/dataplane-operator)
- [install_yamls](https://github.com/openstack-k8s-operators/install_yamls)
- [pull-secret.txt](https://console.redhat.com/openshift/create/local)

## Environment Up

### CRC VM

Install [CRC](https://developers.redhat.com/products/openshift-local/overview)
```
pushd ~/install_yamls/devsetup
cp ~/pull-secret.txt pull-secret.txt
make download_tools
make CPUS=8 MEMORY=32768 crc
make crc_storage
popd
```
Confirm k8s access
```
eval $(crc oc-env)
oc login -u kubeadmin -p 12345678 https://api.crc.testing:6443
```
Confirm SSH access to CRC VM
```
ssh -i ~/.crc/machines/crc/id_ecdsa core@192.168.130.11 "cat /etc/redhat-release"
```

### Control Plane

Deploy openstack operator.
```
pushd ~/install_yamls
make openstack
make openstack_deploy
popd
```
Optionally, after it's running, delete the OpenStack services:
```
oc delete -f ~/install_yamls/out/openstack/openstack/cr/core_v1beta1_openstackcontrolplane.yaml
```
This has a side effect of defining CRDs the next step would otherwise
complain about. Use `oc get crds | grep openstack` to show the
OpenStack CRDs.

### Data Plane VM
```
pushd ~/install_yamls/devsetup
make crc_attach_default_interface
make edpm_compute
popd
```
The above creates a CentOS Stream 9 VM and stores an SSH key to access
it in a k8s secret
```
oc get secret | grep ssh
```
Confirm SSH access to EDPM VM
```
IP=$( sudo virsh -q domifaddr edpm-compute-0 | awk 'NF>1{print $NF}' | cut -d/ -f1 )
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ~/install_yamls/out/edpm/ansibleee-ssh-key-id_rsa root@$IP
```
Use the SSH connection to run the commands below to configure RDO
repos on the EDPM VM
```
rpm -q git || sudo yum -y install git
sudo yum -y install python-setuptools python-requests python3-pip
git clone https://git.openstack.org/openstack/tripleo-repos
pushd tripleo-repos
sudo python3 setup.py install
popd
sudo /usr/local/bin/tripleo-repos current-tripleo-dev
```
## Run a local copy of the openstack-ansibleee-operator

Running a local [openstack-ansibleee-operator](https://github.com/openstack-k8s-operators/openstack-ansibleee-operator)
is only necessary if you need a change which is not yet available in the
[container](https://quay.io/repository/openstack-k8s-operators/openstack-ansibleee-operator?tab=tags)

```
cd ~/openstack-ansibleee-operator/
make generate && make manifests && make build
oc project default
OPERATOR_TEMPLATES=$PWD/templates ./bin/manager -metrics-bind-address ":6667" -health-probe-bind-address ":8082"
```
Leave the above running in a separate terminal

The openstack operator leaves an AnsibleEE pod running in the
openstack namespace so this local copy is run in the default
namespace as a workaround to prevent conflicts

## Run a local copy of the dataplane-operator

Leave the following running in a terminal
```
cd ~/dataplane-operator
make generate && make manifests && make build
OPERATOR_TEMPLATES=$PWD/templates ./bin/manager -metrics-bind-address ":6666"
```
[edpm-compute-0.yaml](edpm-compute-0.yaml) is an example
[OpenStackDataPlaneNode](https://openstack-k8s-operators.github.io/dataplane-operator/openstack_dataplanenode) CR and
[edpm-role-0.yaml](edpm-role-0.yaml) is an example
[OpenStackDataPlaneRole](https://openstack-k8s-operators.github.io/dataplane-operator/openstack_dataplanerole) CR

In another terminal instantiate the role
```
oc create -f edpm-role-0.yaml
```
Instantiate the node
```
oc create -f edpm-compute-0.yaml
```
Observe the Ansible inventory which was created with data from both
the role and node
```
oc get configmap dataplanenode-edpm-compute-0-inventory -o yaml
```
Observe dataplane-deployment pods
```
oc get pods -o name | grep dataplane-deployment
```
Each of the pods following completed their ansible run
```
[fultonj@hamfast edpm]$ oc get pods | grep dataplane
NAME                                                READY   STATUS      RESTARTS   AGE
dataplane-deployment-configure-networklhgmw-mb5tg   0/1     Completed   0          3m56s
dataplane-deployment-validate-network7fj77-zc68j    0/1     Completed   0          52s
dataplane-deployment-validate-networkkzbh7-xg9m2    0/1     Completed   0          52s
[fultonj@hamfast edpm]$
```
Their ansible logs may be observed
```
[fultonj@hamfast edpm]$ oc logs dataplane-deployment-validate-networkkzbh7-xg9m2 | tail
skipping: [edpm-compute-0]

TASK [edpm_nodes_validation : Check Controllers availability] ******************
skipping: [edpm-compute-0]

TASK [edpm_nodes_validation : Verify the configured FQDN vs /etc/hosts] ********
skipping: [edpm-compute-0]

PLAY RECAP *********************************************************************
edpm-compute-0             : ok=3    changed=0    unreachable=0    failed=0    skipped=3    rescued=0    ignored=0
[fultonj@hamfast edpm]$
```
The output of the Ansible run can be seen in the pod logs
```
oc logs $(oc get pods -o name | grep dataplane-deployment-configure-network | tail -1 )
```
Delete the node configuration instance
```
oc delete -f edpm-compute-0.yaml
```
Delete the role
```
oc delete -f edpm-role-0.yaml
```
[create_node.sh](create_node.sh) is a wrapper to run commands like the above

## Environment Down
Use the following to cleanly remove the environment so it can be
recreated as needed.

### Remove Data Plane and its RHEL VM
Delete edpm VM
```
pushd ~/install_yamls/devsetup
make edpm_compute_cleanup
popd
```
### Remove Control Plane and its CoreOS VM
Delete crc VM
```
pushd ~/install_yamls
make crc_storage_cleanup
crc cleanup
popd
```
