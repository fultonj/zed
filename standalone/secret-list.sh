#!/bin/bash

LS_ETC_CEPH=0

if [ $LS_ETC_CEPH -eq 1 ]; then
    for POD in $(sudo podman ps --format "{{.Names}}" | grep nova); do
        echo $POD
        sudo podman exec $POD ls -l /etc/ceph/
    done
fi

for POD in $(sudo podman ps --format "{{.Names}}" | grep nova | grep virtsecretd); do
    echo $POD
    sudo podman exec $POD virsh secret-list
    for UUID in $(sudo podman exec $POD virsh secret-list | grep ceph | awk {'print $1'}); do
        if [[ $(echo $UUID | wc -c) -gt 1 ]]; then
	    sudo podman exec $POD virsh secret-get-value $UUID
        fi
    done
done
