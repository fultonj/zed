#!/bin/bash
echo -e "\nCleaning\n"

NODE_CR=edpm-compute-0.yaml
ROLE_CR=edpm-role-0.yaml
# NODE_CR=dataplane_v1beta1_openstackdataplanenode_deployment.yaml
# ROLE_CR=dataplane_v1beta1_openstackdataplanerole.yaml

oc delete -f $NODE_CR
oc delete -f $ROLE_CR
oc get configmap -o name | grep dataplanenode | xargs oc delete
