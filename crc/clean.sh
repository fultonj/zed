#!/bin/bash

if [[ ! -d ~/install_yamls ]]; then
    echo "~/install_yamls missing (did you run crc.sh?)"
    exit 1
fi

eval $(crc oc-env)
oc login -u kubeadmin -p 12345678 https://api.crc.testing:6443

pushd ~/install_yamls

# Clean CRs

# make neutron_deploy_cleanup
make glance_deploy_cleanup
make keystone_deploy_cleanup
make mariadb_deploy_cleanup
# make crc_storage_cleanup

# Clean Operators
# make neutron_cleanup
make glance_cleanup
make cinder_cleanup
make keystone_cleanup
make mariadb_cleanup

# Are the above pods gone?
oc get pods

# OVN for later
# pushd ~/
# git clone https://github.com/openstack-k8s-operators/osp-director-dev-tools
# oc delete -f osp-director-dev-tools/ansible/roles/cnosp/files/ovn || true
# oc delete cm ovn-connection
# popd

# Clean CRC
echo "Clean crc:"
echo "make crc_storage_cleanup"
echo "crc cleanup"

popd
