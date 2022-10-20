#!/bin/bash

if [[ ! -d ~/install_yamls ]]; then
    echo "~/install_yamls missing (did you run crc.sh?)"
    exit 1
fi

eval $(crc oc-env)
oc login -u kubeadmin -p 12345678 https://api.crc.testing:6443

pushd ~/install_yamls

make rabbitmq
echo "sleeping 2 minutes"
sleep 120
make rabbitmq_deploy

popd

oc get pods | grep cluster-operator
oc get pods | egrep ^controller-manager
oc get pods | grep default-security-context

# oc logs default-security-context-server-0
