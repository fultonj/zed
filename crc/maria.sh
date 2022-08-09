#!/bin/bash

if [[ ! -d ~/install_yamls ]]; then
    echo "~/install_yamls missing (did you run crc.sh?)"
    exit 1
fi

eval $(crc oc-env)
oc login -u kubeadmin https://api.crc.testing:6443

pushd ~/install_yamls

make mariadb
sleep 60
make mariadb_deploy

popd
