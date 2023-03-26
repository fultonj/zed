#!/bin/bash

# return ssh command to reach one of the nodes

SUFFIX=0
if [ ! -z "$1" ]; then
    SUFFIX=$1
fi

IP=$( sudo virsh -q domifaddr edpm-compute-$SUFFIX | awk 'NF>1{print $NF}' | cut -d/ -f1 )
SSH="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ~/install_yamls/out/edpm/ansibleee-ssh-key-id_rsa"

echo "$SSH root@$IP"
