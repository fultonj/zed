#!/bin/bash
echo -e "\nCleaning\n"
oc delete -f edpm-compute-0.yaml
oc delete -f edpm-role-0.yaml
oc get configmap -o name | grep dataplanenode | xargs oc delete
