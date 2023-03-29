# HCI POC Before EDPM CRDs

The example below is from January 2023 before we had
[dataplane-operator](http://github.com/openstack-k8s-operators/dataplane-operator).
I'm only keeping it here for archival purposes.

As of March 2023 I'm deploying it as described under [ng/ceph](../ng/ceph).

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

## Install Ceph

This simulates _3. Install Ceph on the RHEL systems from step 2_.

Deployers can do this by running
[cephadm](https://docs.ceph.com/en/quincy/cephadm/index.html)
directly on the RHEL nodes created from the previous section.
For my example I'll create CRs which call tripleo-ansilbe's cephadm
roles. If we want to ship and support CRs like this that's another
matter.

Create a Ceph spec file from
[ceph-spec-configmap.yaml](ceph-spec-configmap.yaml)
and Ceph vars file from
[ceph-vars-configmap.yaml](ceph-vars-configmap.yaml)
Use [ip-inventory.sh](ip-inventory.sh) to update the IPs.
```
./ip-inventory.sh ceph-spec-configmap.yaml
oc create -f ceph-spec-configmap.yaml

./ip-inventory.sh ceph-vars-configmap.yaml
oc create -f ceph-vars-configmap.yaml
```

[ceph-internal-opt.yaml](ceph-internal-opt.yaml)
provides an option to deploy "internal ceph".
```
oc create -f ceph-internal-opt.yaml
```
This CR uses [my own version](container-with-new-tripleo-ansible.md)
of `quay.io/tripleomastercentos9/openstack-tripleo-ansible-ee`
with a very small change to the tripleo-ansible contents inside the
container.

## Create OpenStack pools on Ceph cluster and export them to a secret

- Connect to a ceph node
```
IP=$(bash ~/zed/crc/edpm-compute-ip.sh 0)
ssh -i ~/install_yamls/out/edpm/ansibleee-ssh-key-id_rsa root@$IP
```
- Create the pools
```
for P in vms volumes images; do sudo cephadm shell -- ceph osd pool create $P; done
for P in vms volumes images; do sudo cephadm shell -- ceph osd pool application enable $P rbd; done
```
- Create the cephx key
```
sudo cephadm shell -- ceph auth add client.openstack mgr 'allow *' mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=vms, allow rwx pool=volumes, allow rwx pool=images'
```
- Export the cephx key and ceph.conf
```
sudo cephadm shell -- ceph auth get client.openstack > ceph.client.openstack.keyring
sudo cephadm shell -- ceph config generate-minimal-conf > ceph.conf
```
Disconnect from the Ceph node and save a local copy of the exported
cephx key and ceph.conf
```
exit
scp -i ~/install_yamls/out/edpm/ansibleee-ssh-key-id_rsa root@$IP:/root/ceph.conf .
scp -i ~/install_yamls/out/edpm/ansibleee-ssh-key-id_rsa root@$IP:/root/ceph.client.openstack.keyring .
```
Create a
[secret](https://kubernetes.io/docs/concepts/configuration/secret)
containing the cephx key and ceph.conf. I do this
with [ceph-secret.sh](ceph-secret.sh).

```
./ceph-secret.sh
oc create -f ceph-secret.yaml
oc get secret ceph-client-conf -o json | jq -r '.data."ceph.conf"' | base64 -d
```

## Create CR to deploy OpenStack (which uses Ceph secret)

Use the OpenStack operator.
```
pushd ~/install_yamls
make openstack
make openstack_deploy
popd
```

I have a [kustomize](https://kustomize.io) directory for Ceph,
with a [kustomization.yaml](kustomize-ceph/kustomization.yaml)
file to update the OpenStackControlPlane object (output by the
`make openstack_deploy` command) to use Ceph.
```
cp ~/install_yamls/out/openstack/openstack/cr/core_v1beta1_openstackcontrolplane.yaml kustomize-ceph/
oc kustomize kustomize-ceph/ | oc apply -f -
```
The [kustomization.yaml](kustomize-ceph/kustomization.yaml) is missing
the real FSID from `ceph-client-conf` but it can be set before running
`oc kustomize` like this:
```
FSID=$(oc get secret ceph-client-conf -o json | jq -r '.data."ceph.conf"' | base64 -d | grep fsid | awk 'BEGIN { FS = "=" } ; { print $2 }' | xargs)
sed -i kustomize-ceph/kustomization.yaml -e s/FSID/$FSID/g
```
Because cinderBackup is not yet working in my enviornment
the kustomization.yaml sets its replica count to 0.

At this point both both Glance and Cinder should work with Ceph.
I verify this with [test_glance.sh](../crc/test_glance.sh) and
[test_cinder.sh](../crc/test_cinder.sh).

## Create CR to have AnsibleEE configure RHEL as Nova Compute

Work in progress:
```
oc create -f compute-vars-configmap.yaml
oc create -f edpm-play.yaml
oc logs $(oc get pods -l job-name=deploy-external-dataplane-compute -o name)
```

[compute-vars-configmap.yaml](compute-vars-configmap.yaml) and
[edpm-play.yaml](edpm-play.yaml)
are based on
[slagle's edpm-play.yaml](https://github.com/slagle/install_yamls/blob/edpm-integration/devsetup/edpm/edpm-play.yaml).

I store compute vars in a separate configmap (not the inventory) since
I already have a working inventory but otherwise I include the same
roles. I also include the `tripleo_ceph_client_files` role as
[documented](https://docs.openstack.org/project-deploy-guide/tripleo-docs/latest/features/ceph_external.html#standalone-ansible-roles-for-external-ceph)
to configure the compute nodes as Ceph clients using the
`ceph-client-conf` secret created previously.

## Configure Nova

### Add a new Cell

Deploy an additional RabbitMQCluster for cell1
with [rabbit_cell1.yaml](rabbit_cell1.yaml).

```
oc create -f rabbit_cell1.yaml
```

Add cell1 to Nova in the OpenStackControlPlane CR.
In my case
[kustomize-nova/kustomization.yaml](kustomize-nova/kustomization.yaml)
contains
[kustomize-ceph/kustomization.yaml](kustomize-ceph/kustomization.yaml)
but adds two `ops` for Nova. I still replace FSID before applying it.

```
FSID=$(oc get secret ceph-client-conf -o json | jq -r '.data."ceph.conf"' | base64 -d | grep fsid | awk 'BEGIN { FS = "=" } ; { print $2 }' | xargs)
sed -i kustomize-nova/kustomization.yaml -e s/FSID/$FSID/g
oc kustomize kustomize-nova/ | oc apply -f -
```

With the above `openstack compute service list` should return
two conductors (thanks gibi).
```
[fultonj@osp-storage-01 ~]$ export OS_CLOUD=default
[fultonj@osp-storage-01 ~]$ export OS_PASSWORD=12345678
[fultonj@osp-storage-01 ~]$ openstack compute service list
+--------------------------------------+----------------+------------------------+----------+---------+-------+----------------------------+
| ID                                   | Binary         | Host                   | Zone     | Status  | State | Updated At                 |
+--------------------------------------+----------------+------------------------+----------+---------+-------+----------------------------+
| 09e9134d-44a0-4105-bf77-3ae512e29dd7 | nova-conductor | nova-cell0-conductor-0 | internal | enabled | down  | 2023-01-13T15:05:01.000000 |
| 3eedd901-030d-45de-ad28-4733a2c6f91b | nova-conductor | nova-cell1-conductor-0 | internal | enabled | up    | 2023-01-13T15:09:47.000000 |
+--------------------------------------+----------------+------------------------+----------+---------+-------+----------------------------+
[fultonj@osp-storage-01 ~]$
```

### Network Hacks

CRC runs dnsmasq so that keystone is accessible:

```
$ host keystone-public-openstack.apps-crc.testing
keystone-public-openstack.apps-crc.testing has address 192.168.130.11
```

In [edpm-play.yaml](edpm-play.yaml) ansible sets up an `sshuttle` in a `tmux`.

```
[root@edpm-compute-0 ~]# ps axu | grep -i ssh
...
root     2169761  0.0  0.0   5784  2932 ?        Ss   Jan10   0:00 tmux new-session -d -s sshuttle sshuttle -r root@192.168.122.1 192.168.130.0/24
```
So an EDPM node can reach the 192.168.130.1 gateway.
```
[root@edpm-compute-2 ~]# ping 192.168.130.1 -c 1
PING 192.168.130.1 (192.168.130.1) 56(84) bytes of data.
64 bytes from 192.168.130.1: icmp_seq=1 ttl=64 time=0.086 ms

--- 192.168.130.1 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.086/0.086/0.086/0.000 ms
[root@edpm-compute-2 ~]#
```
But not the IP for keystone or other OpenStack services.
```
[root@edpm-compute-0 ~]# ping -c 1 192.168.130.11
PING 192.168.130.11 (192.168.130.11) 56(84) bytes of data.
From 192.168.122.1 icmp_seq=1 Destination Port Unreachable

--- 192.168.130.11 ping statistics ---
1 packets transmitted, 0 received, +1 errors, 100% packet loss, time 0ms

[root@edpm-compute-0 ~]#
```
On the hypervisor run the following to allow the edpm-compute node to
reach the openstack services at their API (thanks ralfieri).
```
sudo iptables -R LIBVIRT_FWI 2 -o crc -s 192.168.122.0/24 -d 192.168.130.0/24 -j ACCEPT
```
Confirm the edpm-compute node can now reach `ping 192.168.130.11 -c 1`.
