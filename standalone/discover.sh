#!/bin/bash

function nova_manage () {
    sudo podman exec -ti nova_scheduler nova-manage cell_v2 $1
}

nova_manage list_hosts
nova_manage discover_hosts --verbose
nova_manage list_hosts
