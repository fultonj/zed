#!/bin/bash

if [[ ! -d ~/install_yamls ]]; then
    echo "~/install_yamls missing (did you run crc.sh?)"
    exit 1
fi

eval $(crc oc-env)
oc login -u kubeadmin -p 12345678 https://api.crc.testing:6443

pushd ~/install_yamls

make mariadb
sleep 60
make mariadb_deploy

popd

oc get csv -l operators.coreos.com/mariadb-operator.openstack
oc get pods -l app=mariadb
sleep 15;
oc exec -it  pod/mariadb-openstack -- mysql -uroot -p12345678 -e "show databases;"
