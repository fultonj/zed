#!/bin/bash

OVER=1
IMAGE=1

eval $(crc oc-env)
oc login -u kubeadmin -p 12345678 https://api.crc.testing:6443
export OS_CLOUD=default
export OS_PASSWORD=12345678

if [[ $OVER -eq 1 ]]; then
    oc get pods -l service=glance
    openstack service list
    openstack image list
fi

if [[ $IMAGE -eq 1 ]]; then
    if [[ ! -e cirros-0.4.0-x86_64-disk.img ]]; then
        curl https://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img -o cirros-0.4.0-x86_64-disk.img
    fi
    openstack image create cirros --container-format bare --disk-format qcow2 --file cirros-0.4.0-x86_64-disk.img
    openstack image list
    # openstack image show cirros
fi
