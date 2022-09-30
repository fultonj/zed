#!/bin/bash

for POD in $(sudo podman ps --format "{{.Names}}" | grep nova); do
    echo $POD
    sudo podman exec $POD virsh secret-list
    UUID=$(sudo podman exec $POD virsh secret-list | grep ceph | awk {'print $1'})
    if [[ $(echo $UUID | wc -c) -gt 1 ]]; then
	sudo podman exec $POD virsh secret-get-value $UUID
    fi
done
