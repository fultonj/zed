#!/bin/bash

# Creates OpenStackDataPlane CR using the contents of dataplane_cr.
# dataplane_cr directory is based on the output of 'make edpm_deploy'
# but was modified https://paste.opendev.org/show/b83gbomPXtlJk9ldrIxD

TRANSPORT_URL=$(oc get secret rabbitmq-transport-url-neutron-neutron-transport -o json | jq -r .data.transport_url | base64 -d)
SB_CONNECTION=$(oc get ovndbcluster ovndbcluster-sb -o json | jq -r .status.dbAddress)

OVN_DBS=$(oc get ovndbcluster ovndbcluster-sb -o json | jq -r '.status.networkAttachments."openstack/internalapi"[0]')

TARGET="dataplane_cr/kustomization.yaml"

sed -i -e "s|TRANSPORT_URL|$TRANSPORT_URL|g" $TARGET 
sed -i -e "s|SB_CONNECTION|$SB_CONNECTION|g" $TARGET 
sed -i -e "s|OVN_DBS|$OVN_DBS|g" $TARGET 

FSID=$(oc get secret ceph-conf-files -o json | jq -r '.data."ceph.conf"' | base64 -d | grep fsid | sed -e 's/fsid = //' | xargs)
sed -i "s/_FSID_/${FSID}/" dataplane_cr/dataplane_v1beta1_openstackdataplane.yaml

oc kustomize dataplane_cr/
