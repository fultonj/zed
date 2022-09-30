#!/bin/bash

CMD="virsh secret-list"
for POD in $(sudo podman ps --format "{{.Names}}" | grep nova); do
    echo $POD; sudo podman exec $POD $CMD;
done
