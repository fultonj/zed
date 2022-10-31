#!/bin/bash

eval $(crc oc-env)
oc login -u kubeadmin -p 12345678 https://api.crc.testing:6443

for op in openstack cinder glance placement; do
    oc scale deployment $op-operator-controller-manager --replicas=0
done
