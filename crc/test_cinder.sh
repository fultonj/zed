#!/bin/bash

eval $(crc oc-env)
oc login -u kubeadmin https://api.crc.testing:6443

# ls -l ~/.config/openstack/clouds.yaml
# cat ~/.config/openstack/clouds.yaml

oc get pods -l service=cinder

export OS_CLOUD=default
export OS_PASSWORD=12345678

openstack service list
#openstack endpoint list
openstack volume service list

# openstack volume list
# returns "public endpoint for compute service in regionOne region not found"

# openstack volume create test --size 1
# returns "public endpoint for image service in regionOne region not found"
