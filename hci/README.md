# HCI Proof of Concept (Work in Progress)

## High Level Deployment

1. Deploy OpenShift on a set of servers
2. Deploy RHEL on a set of servers (minimum 3)
3. Install Ceph on the RHEL systems from step 2
4. Create OpenStack pools on Ceph cluster and export cephx/ceph.conf to OpenShift Ceph secreta
5. Create CR to deploy OpenStack (which uses Ceph secret)
6. Create CR to have AnsibleEE configure RHEL as Nova Compute

Nova Compute and Ceph will collocate the same RHEL node.
The Ansible triggered in step 6 could also validate the following:

- That the Ceph cluster was deployed correctly
- That Ceph or Nova are tuned for HCI
- Optionally, they could change Ceph or Nova

This extends the "bring your own RHEL" concept to "bring your own
Ceph" for installation and day 2 management even though there is
collocation.

## Proof of Concept Environment

One large hypervisor with the following virtual machines:

- CRC
- edpm-compute-0
- edpm-compute-1
- edpm-compute-2

## Deploy Virtual Hardware

### Assumptions:

- [slagle's intall_yamls edpm branch](https://github.com/slagle/install_yamls/tree/edpm-integration)
  should be in home directory `git clone -b edpm-integration git@github.com:slagle/install_yamls.git`

### Provision crc

This simulates _1. Deploy OpenShift on a set of servers_. 

Use `make crc` as described in 
[install_yamls](https://github.com/openstack-k8s-operators/install_yamls/tree/master/devsetup#crc).
I personally use [crc.sh](../crc/crc.sh).

### Provision three edpm-compute nodes

This simulates _2. Deploy RHEL on a set of servers (minimum 3)_.

Use `make edpm-compute` as described in
[slagle's intall_yamls edpm branch](https://github.com/slagle/install_yamls/tree/edpm-integration/devsetup#edpm-deployment).
I personally run the following:
```
 pushd ~/install_yamls
 make ansibleee
 oc get crds | grep ansible

 cd ~/install_yamls/devsetup
 make crc_attach_default_interface
 for I in 0 1 2; do make edpm-compute EDPM_COMPUTE_SUFFIX=$I; done
 popd
```
To run Ceph on these systems you need to add disks. I use
[edpm-compute-disk.sh](../crc/edpm-compute-disk.sh).
```
 for I in 0 1 2; do bash ~/zed/crc/edpm-compute-disk.sh $I; done
```
To remove the edpm-compute VMs:
```
 pushd ~/install_yamls/devsetup
 for I in 0 1 2; do make edpm-compute-cleanup EDPM_COMPUTE_SUFFIX=$I; done
 popd
```

### Verify Ansible is working

Create an Ansible inventory as a 
[ConfigMap](https://kubernetes.io/docs/concepts/configuration/configmap)
which has the IPs of the nodes created in the previous step and run a
simple playbook to verify Ansible can connect.

I use [ip-inventory.sh](ip-inventory.sh) which updates 
[inventory-configmap.yaml](inventory-configmap.yaml)
using the IPs reported by
[edpm-compute-ip.sh](../crc/edpm-compute-ip.sh). The
[verify-ansible.yaml](verify-ansible.yaml) AnsibleEE
CR uses the SSH key secret (created in the previous
step) and the inventory ConfigMap to run a simple playbook
on all nodes.
```
./ip-inventory.sh
oc create -f inventory-configmap.yaml
oc create -f verify-ansible.yaml
```
The output of the playbook should also confirm that the disks were
created in the previous step.
```
 oc logs $(oc get pods -l job-name=verify-ansible -o name)
```
If you need to directly debug on one of the VMs, SSH like this:
```
 IP=$(bash ~/zed/crc/edpm-compute-ip.sh 0)
 ssh -i ~/install_yamls/out/edpm/ansibleee-ssh-key-id_rsa root@$IP
```

### Install Ceph

