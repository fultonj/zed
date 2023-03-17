# EDPM - External Data Plane Management Notes

These are my notes on building an environment to test patches of
the dataplane operator.

Creating an
[OpenStackDataPlaneNode](https://openstack-k8s-operators.github.io/dataplane-operator/openstack_dataplanenode)
CR should result in pods being created which run Ansible
to configure RHEL systems as OpenStack Data Plane nodes.

You can observe this behavior on a single hypervisor with two VMs: one
to run OpenShift and one to run RHEL.

## Outline

1. [Environment Up](#environment-up)
2. [Run Ansible by creating DataPlane CRs](#run-ansible-by-creating-dataplane-crs)
3. [Run your own operator for development](#run-your-own-operator-for-development)
4. [Environment Down](#environment-down)

----------------------------------

## Environment Up

### Assumptions

The following are checked out in my home directory on my RHEL8
[hypervisor](https://pcpartpicker.com/user/fultonj/saved/v9KLD3)

- [dataplane-operator](https://github.com/openstack-k8s-operators/dataplane-operator)
- [install_yamls](https://github.com/openstack-k8s-operators/install_yamls)
- [pull-secret.txt](https://console.redhat.com/openshift/create/local)

### CRC VM

Install [CRC](https://developers.redhat.com/products/openshift-local/overview)
```
pushd ~/install_yamls/devsetup
cp ~/pull-secret.txt pull-secret.txt
make download_tools
make CPUS=8 MEMORY=32768 crc
cd ..
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

Deploy openstack control plane.
```
pushd ~/install_yamls
make ceph TIMEOUT=90
make openstack
make openstack_deploy
popd
```
The above includes an optional step to deploy a toy ceph cluster with
`make ceph` before deploying openstack. This also creates a Ceph
secret to access the ceph cluster.
```
oc get secret | grep ceph
oc get secret ceph-conf-files -o json | jq -r '.data."ceph.conf"' | base64 -d
```
#### Optional Storage Tests
Update the cinder and glance pods with
[kustomize/kustomization.yaml](kustomize/kustomization.yaml)
to use the toy ceph cluster.
```
pushd ~/zed/edpm
cp ~/install_yamls/out/openstack/openstack/cr/core_v1beta1_openstackcontrolplane.yaml kustomize/
oc kustomize kustomize/ | oc apply -f -
popd
```
Confirm keystone is working and that cinder can create a volume.
```
oc exec openstackclient -- openstack service list
oc exec openstackclient -- openstack volume create test --size 1
oc exec openstackclient -- openstack volume list
```
Confirm the ceph cluster volumes pool has the same cinder volume UUID.
```
oc exec ceph -- ceph df
oc exec ceph -- rbd ls -l -p volumes
```

### Data Plane VM
```
pushd ~/install_yamls/devsetup
make crc_attach_default_interface
make edpm_compute
make edpm_compute_repos
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

## Run Ansible by creating DataPlane CRs

[edpm-compute-0.yaml](edpm-compute-0.yaml) is an example
[OpenStackDataPlaneNode](https://openstack-k8s-operators.github.io/dataplane-operator/openstack_dataplanenode) CR and
[edpm-role-0.yaml](edpm-role-0.yaml) is an example
[OpenStackDataPlaneRole](https://openstack-k8s-operators.github.io/dataplane-operator/openstack_dataplanerole) CR

Instantiate the role
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
oc get pods | grep dataplane-deployment
```
Each pod should be created sequentially for each ansible run in
[deployment.go](https://github.com/openstack-k8s-operators/dataplane-operator/blob/main/pkg/deployment/deployment.go)
```
[fultonj@hamfast edpm]$ oc get pods | grep dataplane
NAME                                                READY   STATUS      RESTARTS   AGE
dataplane-deployment-configure-networkqcbht-7v6h6                 0/1     Completed   0          7m32s
dataplane-deployment-configure-openstackfcl8c-9cj29               0/1     Completed   0          95s
dataplane-deployment-configure-osl2zcb-9sp5t                      0/1     Completed   0          3m30s
dataplane-deployment-install-openstack5mj8v-w8txd                 0/1     Completed   0          115s
dataplane-deployment-install-os2rg76-75tlf                        0/1     Completed   0          4m21s
dataplane-deployment-run-openstack4mzrw-s4cnz                     0/1     Completed   0          70s
dataplane-deployment-run-os95mln-vknmk                            0/1     Completed   0          2m40s
dataplane-deployment-validate-networkc4fgm-vhjsn                  0/1     Completed   0          4m36s
[fultonj@hamfast edpm]$
```
Their ansible logs may be observed
```
[fultonj@hamfast edpm]$ oc logs dataplane-deployment-validate-networkc4fgm-vhjsn | tail
skipping: [edpm-compute-0]

TASK [edpm_nodes_validation : Check Controllers availability] ******************
skipping: [edpm-compute-0]

TASK [edpm_nodes_validation : Verify the configured FQDN vs /etc/hosts] ********
skipping: [edpm-compute-0]

PLAY RECAP *********************************************************************
edpm-compute-0             : ok=3    changed=0    unreachable=0    failed=0    skipped=3    rescued=0    ignored=0
[fultonj@hamfast edpm]$
```
Delete the node configuration instance
```
oc delete -f edpm-compute-0.yaml
```
After running the above the completed jobs observed from `oc get pods
| grep dataplane` will be removed and running `oc create -f
edpm-compute-0.yaml` again will trigger the same ansible jobs though
the same server will be running so no configuration changes will be
made (only reasserted).

Delete the role
```
oc delete -f edpm-role-0.yaml
```
[create_node.sh](create_node.sh) is a wrapper to run commands like the above

## Run your own operator for development

### Scale Down Deployed Operators which will be run locally

`make openstack` deploys operators including the DPO
([Data Plane Operator](https://github.com/openstack-k8s-operators/dataplane-operator))
and AEE
([Ansible Execution Environment (Operator)](https://github.com/openstack-k8s-operators/openstack-ansibleee-operator)).

Before running a local copy of the DPO or AEE (as described in
the next section), scale down the DPO or AEE operator deployed by
`make openstack` to ensure they do not conflict.
```
oc scale deploy dataplane-operator-controller-manager --replicas=0
```
For example:
```
[fultonj@hamfast cr]$ oc scale deploy dataplane-operator-controller-manager --replicas=0
deployment.apps/dataplane-operator-controller-manager scaled
[fultonj@hamfast cr]$
```
Then observe that there are zero copies of the DPO and one of the AEE.
```
[fultonj@hamfast cr]$ oc get deploy | egrep "ansible|dataplane"
dataplane-operator-controller-manager             0/0     0            0           133m
openstack-ansibleee-operator-controller-manager   1/1     1            1           133m
[fultonj@hamfast cr]$
```
Repeat for the AEE if necessary.

Note:
running [delete_node.sh](delete_node.sh) and
then [create_node.sh](create_node.sh) can result
in the `dataplane-operator-controller-manager`
deployed by the meta operator restarting. A
crude workaround is to use
[scale_down.sh](scale_down.sh) to ensure
it never comes back to create a conflict.

### Run a local copy of the dataplane-operator

Check out a branch to work on and run it
```
cd ~/dataplane-operator
make generate && make manifests && make build
OPERATOR_TEMPLATES=$PWD/templates ./bin/manager -metrics-bind-address ":6666"
```
Leave the above running in a separate terminal

### Run a local copy of the openstack-ansibleee-operator

Running a local [openstack-ansibleee-operator](https://github.com/openstack-k8s-operators/openstack-ansibleee-operator)
is only necessary if you need a change which is not yet available in the
[container](https://quay.io/repository/openstack-k8s-operators/openstack-ansibleee-operator?tab=tags)

```
cd ~/openstack-ansibleee-operator/
make manifests generate build
OPERATOR_TEMPLATES=$PWD/templates ./bin/manager -metrics-bind-address ":6667" -health-probe-bind-address ":8082"
```
Leave the above running in a separate terminal.

### Test your patch

Patch the AEE or DPO accordingly and restart them locally.
Create a test CR and observe the outcome as described in
[Run Ansible by creating DataPlane CRs](#run-ansible-by-creating-dataplane-crs).

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
