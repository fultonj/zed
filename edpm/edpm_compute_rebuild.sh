#!/bin/bash

if [[ $(sudo virsh list | grep edpm-compute-0 | wc -l) -gt 0 ]]; then
    echo "shutting down edpm-compute-0"
    pushd ~/install_yamls/devsetup
    make edpm_compute_cleanup
    popd
fi

pushd ~/install_yamls/devsetup
make edpm_compute

echo "Waiting for edpm-compute node to be running and answering pings"
while [ 1 ]; do
    if [[ $(sudo virsh list | grep edpm-compute-0 | grep running | wc -l) -gt 0 ]]; then
        IP=$( sudo virsh -q domifaddr edpm-compute-0 | awk 'NF>1{print $NF}' | cut -d/ -f1 )
        if [[ ! -z $IP ]]; then
            ping -c 1 $IP
            if [[ $? -eq 0 ]]; then
                break
            else
                # wait for VM to answer pings
                echo -n "."
                sleep 1
            fi
        else
            # wait for VM to have an IP
            echo -n "."
            sleep 1
        fi
    else
        # wait for VM to be running
        echo -n "."
        sleep 1
    fi
done
make edpm_compute_repos
popd
