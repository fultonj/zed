#!/bin/bash

OVER=1
CIRROS=1
IMAGE=1
CLEAN=0
PROJECT_ID_BUG=0

eval $(crc oc-env)
oc login -u kubeadmin -p 12345678 https://api.crc.testing:6443
export OS_CLOUD=default
export OS_PASSWORD=12345678

if [[ $OVER -eq 1 ]]; then
    oc get pods -l service=glance-external
    oc get pods -l service=glance-internal
    openstack service list
    openstack image list
fi

URL=https://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img
if [[ $CIRROS -eq 1 ]]; then
    if [[ ! -e cirros-0.4.0-x86_64-disk.img ]]; then
        curl $URL -o cirros-0.4.0-x86_64-disk.img
    fi
fi

if [[ $IMAGE -eq 1 ]]; then
    openstack image create cirros --container-format bare --disk-format qcow2 --file cirros-0.4.0-x86_64-disk.img
    openstack image list
    # openstack image show cirros
fi

if [[ $CLEAN -eq 1 ]]; then
    for ID in $(openstack image list -f value -c ID); do
        openstack image delete $ID
    done
fi

if [[ $PROJECT_ID_BUG -eq 1 ]]; then
    # https://etherpad.opendev.org/p/nextgen-efforts-glance-testing
    if [[ ! -e admin-rc ]]; then
        echo "admin-rc is missing"
        exit 1
    fi
    if [[ ! -e ~/.local/bin/glance ]]; then
        echo "~/.local/bin/glance is missing"
        exit 1
    fi
    source admin-rc
    # Scenario 1: Create image without using import workflow
    NAME=image-without-owner
    ID=$(openstack image show -f value -c id $NAME)
    if [[ -z "$ID" ]]; then
        glance image-create --disk-format qcow2 --container-format bare --name $NAME --file cirros-0.4.0-x86_64-disk.img
        ID=$(openstack image show -f value -c id $NAME)
    fi
    glance image-show $ID | grep owner
    echo "Image is created successfully, and is active but owner is None"
    # Scenario 2: Create image using import workflow web-download import method
    NAME=image-web-download
    ID=$(openstack image show -f value -c id $NAME)
    if [[ -z "$ID" ]]; then
        glance image-create-via-import \
               --disk-format qcow2 --container-format bare \
               --name $NAME --import-method web-download --uri $URL
        ID=$(openstack image show -f value -c id $NAME)
    fi
    glance image-show $ID
    echo "Both scenarios fail because project_id is not set in context"
fi
