#!/bin/bash

oc get pods | grep edpm
# watch -n 1 "oc get pods | grep edpm"

while true; do
    oc logs -f \
       $(oc get pods | grep dataplane-deployment | grep Running| cut -d ' ' -f1) \
       2>/dev/null || echo -n .;
    sleep 1;
done
