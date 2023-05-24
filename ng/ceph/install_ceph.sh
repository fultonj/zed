#!/bin/bash

NET=0
ISO=0
PRE=0
BOOT=0
SINGLE_OSD=0
SSH_KEYS=0
SPEC=0
CEPHX=0
NODES=1

RSA="~/install_yamls/out/edpm/ansibleee-ssh-key-id_rsa"
OPT="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
IP=192.168.122.100

if [ $NET -eq 1 ]; then
    # install os-net-config on edpm-compute-0 to configure network isolation
    scp -i $RSA wallaby_repos.sh root@$IP:/tmp/wallaby_repos.sh
    ssh -i $RSA $OPT root@$IP "bash /tmp/wallaby_repos.sh"
    ssh -i $RSA $OPT root@$IP "dnf install -y os-net-config openvswitch"
    scp -i $RSA ../../adopt/standalone/network.sh root@$IP:/tmp/network.sh
    ssh -i $RSA $OPT root@$IP "bash /tmp/network.sh"
fi

if [ $ISO -eq 1 ]; then
    # If we're deploying with network isolation
    MON_IP=172.18.0.100
    crudini --set initial_ceph.conf global cluster_network 172.20.0.0/24
    crudini --set initial_ceph.conf global public_network 172.18.0.0/24
    crudini --set initial_ceph.conf mon public_network 172.18.0.0/24
else
    MON_IP=$IP
fi

if [ $PRE -eq 1 ]; then
    URL=https://raw.githubusercontent.com/ceph/ceph/quincy/src/cephadm/cephadm
    for I in $(seq 0 $NODES); do
	IPL="192.168.122.10${I}"
	scp -i $RSA hosts root@$IP:/etc/hosts
	scp -i $RSA ceph_spec.yml root@$IP:/root/ceph_spec.yml
	scp -i $RSA initial_ceph.conf root@$IP:/root/initial_ceph.conf
	ssh -i $RSA $OPT root@$IPL "curl --silent --remote-name --location $URL"
	ssh -i $RSA $OPT root@$IPL "chmod +x cephadm"
	ssh -i $RSA $OPT root@$IPL "mkdir -p /etc/ceph"
	ssh -i $RSA $OPT root@$IPL "dnf install podman lvm2 jq -y"
    done
fi

if [ $BOOT -eq 1 ]; then
    $(bash ../ssh_node.sh) "./cephadm bootstrap --config initial_ceph.conf --single-host-defaults --skip-monitoring-stack --skip-dashboard --skip-mon-network --mon-ip $MON_IP"
fi

if [ $SINGLE_OSD -eq 1 ]; then
    # If only deploying a single OSD node and not using spec, then add OSDs like this
    $(bash ../ssh_node.sh) "./cephadm shell -- ceph orch apply osd --all-available-devices"
fi

if [ $SSH_KEYS -eq 1 ]; then
    scp -i $RSA root@$IP:/etc/ceph/ceph.pub .
    URL=$(cat ceph.pub | curl -F 'sprunge=<-' http://sprunge.us)
    rm ceph.pub

    ansible -i 192.168.122.101,192.168.122.102 all -u root -b \
	    --private-key $RSA -m ansible.posix.authorized_key -a "user=root key=$URL"
fi

if [ $SPEC -eq 1 ]; then
    scp -i $RSA apply_spec.sh root@$IP:/root/apply_spec.sh
    $(bash ../ssh_node.sh) "bash /root/apply_spec.sh"
fi

if [ $CEPHX -eq 1 ]; then
    scp -i $RSA cephx.sh root@$IP:/root/cephx.sh
    $(bash ../ssh_node.sh) "bash /root/cephx.sh"
    $(bash ../ssh_node.sh) "ls -l /etc/ceph/"
fi
