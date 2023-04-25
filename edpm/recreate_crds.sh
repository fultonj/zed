#!/bin/bash
# Recreate the dataplane-operator CRDs

AEE=0

pushd ~/dataplane-operator
oc delete crd openstackdataplanenodes.dataplane.openstack.org
oc delete crd openstackdataplaneroles.dataplane.openstack.org
oc delete crd openstackdataplanes.dataplane.openstack.org
oc delete crd openstackdataplaneservices.dataplane.openstack.org
oc apply -f config/crd/bases/
popd

if [ $AEE -eq 1 ]; then
    if [[ -d ~/openstack-ansibleee-operator/ ]]; then
        pushd ~/openstack-ansibleee-operator/
        oc delete crd openstackansibleees.ansibleee.openstack.org
        oc apply -f config/crd/bases/
        popd
    fi
fi
