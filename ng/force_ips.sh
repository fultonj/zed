#!/bin/bash

SSH="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ~/install_yamls/out/edpm/ansibleee-ssh-key-id_rsa -l root"

IP0=$( sudo virsh -q domifaddr edpm-compute-0 | awk 'NF>1{print $NF}' | cut -d/ -f1 )
if [[ $IP0 != "192.168.122.100" ]]; then
    if [[ $($SSH $IP0 "ip a | grep 192.168.122.100" | wc -l) -eq 0 ]]; then
        $SSH $IP0 "sudo ip addr add 192.168.122.100/24 dev eth0"
    else
        echo "edpm-compute-0 already has the right IP"
    fi
    $SSH 192.168.122.100 "echo good"
else
    echo "edpm-compute-0 already has $IP0"
fi

IP1=$( sudo virsh -q domifaddr edpm-compute-1 | awk 'NF>1{print $NF}' | cut -d/ -f1 )
if [[ $IP1 != "192.168.122.101" ]]; then
    if [[ $($SSH $IP1 "ip a | grep 192.168.122.101" | wc -l) -eq 0 ]]; then
        $SSH $IP1 "sudo ip addr add 192.168.122.101/24 dev eth0"
    else
        echo "edpm-compute-1 already has the the right IP"
    fi
    $SSH 192.168.122.101 "echo good"
else
    echo "edpm-compute-1 already has $IP1"
fi
