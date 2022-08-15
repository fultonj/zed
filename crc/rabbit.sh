#!/bin/bash

if [[ ! -d ~/install_yamls ]]; then
    echo "~/install_yamls missing (did you run crc.sh?)"
    exit 1
fi

eval $(crc oc-env)
oc login -u kubeadmin -p 12345678 https://api.crc.testing:6443

pushd ~/install_yamls

curl https://raw.githubusercontent.com/openstack-k8s-operators/install_yamls/eae7c79c296fc06301ed141bc1c338cf3056564b/rabbit.yaml > rabbit.yaml
curl https://raw.githubusercontent.com/openstack-k8s-operators/install_yamls/eae7c79c296fc06301ed141bc1c338cf3056564b/Makefile > Makefile
git status

sed \
    -e s/50M/1000M/g \
    -i rabbit.yaml

make rabbitmq
sleep 60
oc apply -f rabbit.yaml

popd
