#!/bin/bash

eval $(crc oc-env)
oc login -u kubeadmin https://api.crc.testing:6443

oc get csv -l operators.coreos.com/keystone-operator.openstack
oc get pods -l service=keystone

mkdir -p ~/.config/openstack
oc get cm openstack-config -o json | jq -r '.data["clouds.yaml"]' \
                                        > ~/.config/openstack/clouds.yaml
ls -l ~/.config/openstack/clouds.yaml
cat ~/.config/openstack/clouds.yaml

if [[ ! -e ~/.local/bin/openstack ]]; then
    pip3 install openstackclient
fi

export OS_CLOUD=default
export OS_PASSWORD=12345678

openstack service list
openstack endpoint list
