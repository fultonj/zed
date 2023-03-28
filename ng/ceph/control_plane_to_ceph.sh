#!/bin/bash

eval $(crc oc-env)
oc login -u kubeadmin -p 12345678 https://api.crc.testing:6443

curl -o /tmp/core_v1beta1_openstackcontrolplane_network_isolation_ceph.yaml \
     https://raw.githubusercontent.com/openstack-k8s-operators/openstack-operator/master/config/samples/core_v1beta1_openstackcontrolplane_network_isolation_ceph.yaml

FSID=$(oc get secret ceph-conf-files -o json | jq -r '.data."ceph.conf"' | base64 -d | grep fsid | sed -e 's/fsid = //') && echo $FSID

sed -i "s/_FSID_/${FSID}/" /tmp/core_v1beta1_openstackcontrolplane_network_isolation_ceph.yaml

sed -i "s/replicas:\ 0/replicas:\ 1/g" /tmp/core_v1beta1_openstackcontrolplane_network_isolation_ceph.yaml

oc apply -f /tmp/core_v1beta1_openstackcontrolplane_network_isolation_ceph.yaml

