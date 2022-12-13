#!/bin/bash

eval $(crc oc-env)
oc login -u kubeadmin -p 12345678 https://api.crc.testing:6443

# ls -l ~/.config/openstack/clouds.yaml
# cat ~/.config/openstack/clouds.yaml

oc get pods -l service=cinder

export OS_CLOUD=default
export OS_PASSWORD=12345678

openstack service list
openstack endpoint list
openstack volume service list

if [[ ! -e ~/.local/bin/cinder ]]; then
    python3 -m pip install openstackclient
fi
if [[ ! -e ~/.local/bin/cinder ]]; then
    echo "unable to install cinder client"
    exit 1
fi
if [[ ! -e admin-rc ]]; then
    echo "admin-rc is missing"
    exit 1
fi

source admin-rc
cinder list
cinder create --name foo 1
cinder list
cinder delete foo
