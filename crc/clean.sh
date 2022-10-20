#!/bin/bash

CINDER=0
RABBIT=0
GLANCE=1
KEYSTONE=1
MARIA=1
CRC=0

if [[ ! -d ~/install_yamls ]]; then
    echo "~/install_yamls missing (did you run crc.sh?)"
    exit 1
fi

eval $(crc oc-env)
oc login -u kubeadmin -p 12345678 https://api.crc.testing:6443

pushd ~/install_yamls

# Clean CRs
# make neutron_deploy_cleanup

if [[ $CINDER -eq 1 ]]; then
    make cinder_deploy_cleanup
fi

if [[ $RABBIT -eq 1 ]]; then
    # curl https://raw.githubusercontent.com/openstack-k8s-operators/install_yamls/eae7c79c296fc06301ed141bc1c338cf3056564b/Makefile > Makefile
    make rabbitmq_deploy_cleanup
    # git reset --hard
fi

if [[ $GLANCE -eq 1 ]]; then
    make glance_deploy_cleanup
fi
if [[ $KEYSTONE -eq 1 ]]; then
    make keystone_deploy_cleanup
fi
if [[ $MARIA -eq 1 ]]; then
    make mariadb_deploy_cleanup
fi

# make crc_storage_cleanup

# -------------------------------------------------------
# Clean Operators
# make neutron_cleanup

if [[ $CINDER -eq 1 ]]; then
    make cinder_cleanup
fi

if [[ $RABBIT -eq 1 ]]; then
    # curl https://raw.githubusercontent.com/openstack-k8s-operators/install_yamls/eae7c79c296fc06301ed141bc1c338cf3056564b/Makefile > Makefile
    make rabbitmq_cleanup
    # git reset --hard
fi

if [[ $GLANCE -eq 1 ]]; then
    make glance_cleanup
fi
if [[ $KEYSTONE -eq 1 ]]; then
    make keystone_cleanup
fi
if [[ $MARIA -eq 1 ]]; then
    make mariadb_cleanup
fi

# Are the above pods gone?
oc get pods

# OVN for later
# pushd ~/
# git clone https://github.com/openstack-k8s-operators/osp-director-dev-tools
# oc delete -f osp-director-dev-tools/ansible/roles/cnosp/files/ovn || true
# oc delete cm ovn-connection
# popd

# Clean CRC

if [[ $CRC -eq 1 ]]; then
    read -p "Are you sure you want to delete CRC? " -n 1 -r
    echo    # (optional) move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
    fi
    make crc_storage_cleanup
    sleep 10
    crc cleanup
fi

popd
