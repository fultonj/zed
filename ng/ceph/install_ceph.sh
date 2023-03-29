#!/bin/bash

PRE=0
BOOT=0
SSH_KEYS=0
SPEC=0
CEPHX=0

RSA="~/install_yamls/out/edpm/ansibleee-ssh-key-id_rsa"

if [ $PRE -eq 1 ]; then
    OPT="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
    URL=https://raw.githubusercontent.com/ceph/ceph/quincy/src/cephadm/cephadm

    for I in $(seq 0 2); do
	IP="192.168.122.10${I}"
	scp -i $RSA hosts root@$IP:/etc/hosts
	scp -i $RSA ceph_spec.yml root@$IP:/root/ceph_spec.yml
	scp -i $RSA initial_ceph.conf root@$IP:/root/initial_ceph.conf
	ssh -i $RSA $OPT root@$IP "curl --silent --remote-name --location $URL"
	ssh -i $RSA $OPT root@$IP "chmod +x cephadm"
	ssh -i $RSA $OPT root@$IP "mkdir -p /etc/ceph"
	ssh -i $RSA $OPT root@$IP "dnf install podman lvm2 jq -y"
    done
fi

IP=192.168.122.100

if [ $BOOT -eq 1 ]; then
    $(bash ../ssh_node.sh) "./cephadm bootstrap --config initial_ceph.conf --single-host-defaults --skip-monitoring-stack --skip-dashboard --skip-mon-network --mon-ip $IP"
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
