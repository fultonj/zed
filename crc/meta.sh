#!/bin/bash

CREATE=1
UPDATE=1
DELETE=0
PV=0

if [[ ! -d ~/install_yamls ]]; then
    echo "~/install_yamls missing (did you run crc.sh?)"
    exit 1
fi

eval $(crc oc-env)
oc login -u kubeadmin -p 12345678 https://api.crc.testing:6443

if [[ $CREATE -eq 1 ]]; then
    pushd ~/install_yamls
    make openstack
    sleep 60
    make openstack_deploy
    popd
fi

if [[ $(( $CREATE + $UPDATE )) -eq 2 ]]; then
    echo "Give 'make openstack_deploy' 60 seconds before updating CR"
    sleep 60
fi

if [[ $UPDATE -eq 1 ]]; then
    # update glance and cinder to use ceph
    # update cinder to use transport_url via customServiceConfig
    # scale cinder-volume-volume1-0 down to 0 replicas
    pushd cr
    bash meta_cr.sh
    oc apply -f core_v1beta1_openstackcontrolplane_ceph_backend.yaml
    popd
fi

if [[ $DELETE -eq 1 ]]; then
    pushd ~/install_yamls
    make openstack_deploy_cleanup
    sleep 60
    make openstack_cleanup
    popd
fi

if [[ $PV -eq 1 ]]; then
    for i in $(oc get pv | egrep "Failed|Released" | awk {'print $1'}); do
	oc patch pv $i --type='json' -p='[{"op": "remove", "path": "/spec/claimRef"}]';
    done
fi
