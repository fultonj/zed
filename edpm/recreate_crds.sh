#!/bin/bash
# Recreate the dataplane-operator CRDs
pushd ~/dataplane-operator
oc delete crd openstackdataplanenodes.dataplane.openstack.org
oc delete crd openstackdataplaneroles.dataplane.openstack.org
oc delete crd openstackdataplanes.dataplane.openstack.org
oc apply -f config/crd/bases/
popd