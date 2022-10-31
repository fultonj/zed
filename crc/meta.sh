#!/bin/bash

CREATE=1
DELETE=0
PV=0

if [[ ! -d ~/install_yamls ]]; then
    echo "~/install_yamls missing (did you run crc.sh?)"
    exit 1
fi

eval $(crc oc-env)
oc login -u kubeadmin -p 12345678 https://api.crc.testing:6443

pushd ~/install_yamls

if [[ $CREATE -eq 1 ]]; then
    make openstack
    sleep 60
    make openstack_deploy
fi


if [[ $DELETE -eq 1 ]]; then
    make openstack_deploy_cleanup
    sleep 60
    make openstack_cleanup
fi

if [[ $PV -eq 1 ]]; then
    for i in $(oc get pv | egrep "Failed|Released" | awk {'print $1'}); do
	oc patch pv $i --type='json' -p='[{"op": "remove", "path": "/spec/claimRef"}]';
    done
fi

popd
