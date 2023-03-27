# Install Ceph on EDPM Nodes

The steps below install Ceph on three edpm nodes for use with [NG and Ceph](README.md)

## Assumptions

- `ansible-galaxy collection install ansible.posix` has been run on hypervisor
- Three EDPM nodes exist with disks from [edpm-compute-disk.sh](edpm-compute-disk.sh)

Note that my [deploy.sh](../deploy.sh) has an `EDPM_NODE_DISKS` tag.

## Prerequisites

From hypervisor
```
OPT="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
RSA="~/install_yamls/out/edpm/ansibleee-ssh-key-id_rsa"
URL=https://raw.githubusercontent.com/ceph/ceph/quincy/src/cephadm/cephadm

for I in $(seq 0 2); do
    IP="192.168.122.10${I}"
    scp -i $RSA hosts root@$IP:/etc/hosts
    scp -i $RSA ceph_spec.yml root@$IP:/root/ceph_spec.yml
    scp -i $RSA initial_ceph.conf root@$IP:/root/initial_ceph.conf
    ssh -i $RSA $OPT root@$IP "curl --silent --remote-name --location $URL"
    ssh -i $RSA $OPT root@$IP "chmod +x cephadm"
    ssh -i $RSA $OPT root@$IP "dnf install podman lvm2 jq -y"
done
```

## Bootstrap 

From edpm-compute-0
```
IP=192.168.122.100
mkdir -p /etc/ceph

./cephadm bootstrap --config initial_ceph.conf --single-host-defaults --skip-monitoring-stack --skip-dashboard --skip-mon-network --mon-ip $IP

./cephadm shell -- ceph -s
```

## Distribute cephadm's SSH key

From hypervisor
```
IP=192.168.122.100
RSA="~/install_yamls/out/edpm/ansibleee-ssh-key-id_rsa"

scp -i $RSA root@$IP:/etc/ceph/ceph.pub .
URL=$(cat ceph.pub | curl -F 'sprunge=<-' http://sprunge.us)
rm ceph.pub

ansible -i 192.168.122.101,192.168.122.102 all -u root -b \
    --private-key $RSA -m ansible.posix.authorized_key -a "user=root key=$URL"
```

## Add other hosts to cluster

From edpm-compute-0

Verify ceph's SSH works:
```
./cephadm shell -- ceph cephadm get-ssh-config > ssh_config
./cephadm shell -- ceph config-key get mgr/cephadm/ssh_identity_key > key
chmod 600 key

ssh -F ssh_config -i key root@edpm-compute-1
ssh -F ssh_config -i key root@edpm-compute-2
```

Copy spec and keyring into current mon container
```
CID=$(./cephadm ls | jq '.[]' | jq 'select(.name | test("^mon*")).container_id' | sed s/\"//g);
podman cp /root/ceph_spec.yml $CID:/tmp/ceph_spec.yml
podman cp /etc/ceph/ceph.client.admin.keyring $CID:/etc/ceph/ceph.client.admin.keyring
```

Apply spec (and clean up temporary files)
```
NAME=$(./cephadm ls | jq '.[]' | jq 'select(.name | test("^mon*")).name' | sed s/\"//g);
./cephadm enter --name $NAME -- ceph orch apply --in-file /tmp/ceph_spec.yml
./cephadm enter --name $NAME -- rm /etc/ceph/ceph.client.admin.keyring /tmp/ceph_spec.yml
```

## Create key/pools for openstack

From edpm-compute-0

Ensure OSDs are up and health is OK
```
./cephadm shell -- ceph -s
```

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
The [ceph_secret.sh](ceph_secret.sh) script expects to find the above
files on edpm-comptue-0.

## Delete Ceph (Skip unless you want to start over)
From hypervisor
```
CMD="/root/cephadm rm-cluster --force --zap-osds --fsid"
OPT="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
RSA="~/install_yamls/out/edpm/ansibleee-ssh-key-id_rsa"

for I in $(seq 0 2); do
    IP="192.168.122.10${I}"
    FSID=$(ssh -i $RSA $OPT root@$IP "ls /var/lib/ceph/ | tail -1")
    ssh -i $RSA $OPT root@$IP "$CMD $FSID"
done
```
