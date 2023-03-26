# Ceph on NG

This subdirectory of [ng](../ng) contains variations to use with Ceph.
The steps below install Ceph on three edpm nodes.

## Assumptions

- Three EDPM nodes exist with disks from [edpm-compute-disk.sh](edpm-compute-disk.sh)

Note that my [deploy.sh](../deploy.sh) has an `EDPM_NODE_DISKS` tag.

## Prerequisites

From hypervisor
```
OPT="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
RSA="~/install_yamls/out/edpm/ansibleee-ssh-key-id_rsa"

for I in $(seq 0 2); do
    IP="192.168.122.10${I}"
    scp -i $RSA hosts root@$IP:/etc/hosts
    ssh -i $RSA $OPT root@$IP "dnf install podman lvm2 -y"
done

```

## Bootstrap 

From edpm-compute-0
```
IP=192.168.122.100

curl --silent --remote-name --location https://raw.githubusercontent.com/ceph/ceph/quincy/src/cephadm/cephadm
chmod +x cephadm
mkdir -p /etc/ceph

./cephadm bootstrap --skip-monitoring-stack --skip-dashboard --skip-mon-network --mon-ip $IP

./cephadm shell -- ceph -s
```

## Distribute Ceph's SSH key

From hypervisor
```
IP=192.168.122.100
OPT="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
RSA="~/install_yamls/out/edpm/ansibleee-ssh-key-id_rsa"

scp -i $RSA root@$IP:/etc/ceph/ceph.pub .
URL=$(cat ceph.pub | curl -F 'sprunge=<-' http://sprunge.us)

ansible-galaxy collection install ansible.posix

ansible -i 192.168.122.101,192.168.122.102 all -u root -b \
    --private-key $RSA -m ansible.posix.authorized_key -a "user=root key=$URL"
```
## Add other hosts

From edpm-compute-0

Verify ceph's SSH works:
```
./cephadm shell -- ceph cephadm get-ssh-config > ssh_config
./cephadm shell -- ceph config-key get mgr/cephadm/ssh_identity_key > key
chmod 600 key

ssh -F ssh_config -i key root@edpm-compute-1
ssh -F ssh_config -i key root@edpm-compute-2
```

Add hosts
```
./cephadm shell -- ceph orch host add edpm-compute-1
./cephadm shell -- ceph orch host add edpm-compute-2
./cephadm shell -- ceph orch daemon add mon edpm-compute-1
./cephadm shell -- ceph orch daemon add mon edpm-compute-2

```

Use their disks as OSDs
```
./cephadm shell -- ceph orch device ls
./cephadm shell -- ceph orch apply osd --all-available-devices
```

## Create key/pools for openstack

Create pools/key
```
./cephadm shell
for P in vms volumes images; do ceph osd pool create $P; done
for P in vms volumes images; do ceph osd pool application enable $P rbd; done

ceph auth add client.openstack mgr 'allow *' mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=vms, allow rwx pool=volumes, allow rwx pool=images'
```

Test it
```
./cephadm shell 
ceph auth get client.openstack > /etc/ceph/ceph.client.openstack.keyring

rbd -n client.openstack --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.openstack.keyring ls images

rbd -n client.openstack --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.openstack.keyring create --size 1024 images/foo

rbd -n client.openstack --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.openstack.keyring rm images/foo
```

Export files useful for clients
```
./cephadm shell -- ceph auth get client.openstack > /etc/ceph/ceph.client.openstack.keyring
./cephadm shell -- ceph config generate-minimal-conf > /etc/ceph/ceph.conf
```

## Delete Ceph (Skip unless you want to start over)
From edpm-compute-0
```
FSID=$(ls /var/lib/ceph/ | tail -1)
./cephadm rm-cluster --force --zap-osds --fsid 
```
