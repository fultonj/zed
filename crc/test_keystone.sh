#!/bin/bash

eval $(crc oc-env)
oc login -u kubeadmin https://api.crc.testing:6443

oc get csv -l operators.coreos.com/keystone-operator.openstack
oc get pods -l service=keystone

mkdir -p ~/.config/openstack

if [[ ! -e ~/.config/openstack/clouds.yaml ]]; then
    cp ~/zed/crc/clouds.yaml ~/.config/openstack/clouds.yaml
    # oc get cm openstack-config -o json | jq -r '.data["clouds.yaml"]' \
    #                                         > ~/.config/openstack/clouds.yaml
fi
ls -l ~/.config/openstack/clouds.yaml
cat ~/.config/openstack/clouds.yaml

if [[ ! -e ~/.local/bin/openstack ]]; then
    pip3 install openstackclient
fi

if [[ $(grep 127.0.0.1 /etc/resolv.conf | wc -l) -eq 0 ]]; then
    echo "WARN: 'nameserver 127.0.0.1' should be in /etc/resolv.conf"
    echo "See https://github.com/code-ready/crc/issues/119"
fi

export OS_CLOUD=default
export OS_PASSWORD=12345678

openstack service list
openstack endpoint list
