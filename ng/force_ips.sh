#!/bin/bash

export LIBVIRT_DEFAULT_URI=qemu:///system
OPT="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
RSA="~/install_yamls/out/edpm/ansibleee-ssh-key-id_rsa"
SSH="ssh $OPT -i $RSA -l root"

NODES=1

for I in $(seq 0 $NODES); do
    WANT_IP="192.168.122.10${I}"
    DOM_IP=$(virsh -q domifaddr edpm-compute-$I \
                 | awk 'NF>1{print $NF}' | cut -d/ -f1)
    if [[ -z $DOM_IP ]]; then
        echo "DOM_IP is empty"
        ping -c 1 $WANT_IP > /dev/null
        if [[ $? -eq 0 ]]; then
            echo -n "$WANT_IP responds to ping and returns the hostname: "
            $SSH $WANT_IP "hostname"
        fi
    else
        ping -c 1 $DOM_IP > /dev/null
        if [[ $? -gt 0 ]]; then
            echo "DOM_IP $IP does not respond to ping"
        else
            if [[ $DOM_IP == $WANT_IP ]]; then
                echo "edpm-compute-$I already has $WANT_IP"
            else
                echo "Going to force IP of edpm-compute-$I to $WANT_IP"
                if [[ $($SSH $DOM_IP "ip a | grep $WANT_IP" | wc -l) -eq 0 ]]; then
                    $SSH $DOM_IP "sudo ip addr add $WANT_IP/24 dev eth0"
                fi
                echo -n "SSH'ing to $WANT_IP returning the hostname: "
                $SSH $WANT_IP "hostname"
            fi
        fi
    fi
done
