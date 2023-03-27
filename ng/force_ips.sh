#!/bin/bash

export LIBVIRT_DEFAULT_URI=qemu:///system
OPT="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
RSA="~/install_yamls/out/edpm/ansibleee-ssh-key-id_rsa"
SSH="ssh $OPT -i $RSA -l root"

# node0 node1 node2
NODES=2

for I in $(seq 0 $NODES); do
    WANT_IP="192.168.122.10${I}"
    DOM_IP=$(virsh -q domifaddr edpm-compute-$I \
                 | awk 'NF>1{print $NF}' | cut -d/ -f1)
    if [[ -z $DOM_IP ]]; then
        echo "DOM_IP for edpm-compute-$I is empty"
        ping -c 1 $WANT_IP > /dev/null
        if [[ $? -eq 0 ]]; then
            echo -n "$WANT_IP responds to ping and returns the hostname: "
            $SSH $WANT_IP "hostname"
        fi
    else
        ping -c 1 $DOM_IP > /dev/null
        if [[ $? -gt 0 ]]; then
            echo "DOM_IP for edpm-compute-$I does not respond to ping"
            echo "sudo virsh destroy edpm-compute-$I; sudo virsh start edpm-compute-$I"
        else
            if [[ $DOM_IP == $WANT_IP ]]; then
                echo "edpm-compute-$I already has $WANT_IP (same as DOM_IP)"
            else
                if [[ $($SSH $DOM_IP "ip a | grep $WANT_IP" | wc -l) -eq 0 ]]; then
                    echo "Going to force IP of edpm-compute-$I to $WANT_IP"
                    $SSH $DOM_IP "sudo ip addr add $WANT_IP/24 dev eth0"
                else
                    # In this case the DOM_IP != WANT_IP
                    # But the WANT_IP was added by above
                    # and program is being re-run
                    echo "edpm-compute-$I already has $WANT_IP (diff from DOM_IP)"
                fi
                echo -n "SSH'ing to $WANT_IP returning the hostname: "
                $SSH $WANT_IP "hostname"
            fi
        fi
    fi
    echo "~~~"
done
