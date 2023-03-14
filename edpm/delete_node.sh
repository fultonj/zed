#!/bin/bash
echo -e "\nCleaning\n"

NODE_CR=edpm-compute-0.yaml
ROLE_CR=edpm-role-0.yaml

oc delete -f $NODE_CR
oc delete -f $ROLE_CR
oc get configmap -o name | grep dataplanerole | xargs oc delete
