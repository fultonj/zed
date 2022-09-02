#!/bin/bash

CEPH=0
GLANCE_CR=$PWD/cr/glance_cr_template.yaml

if [[ $CEPH -eq 1 ]]; then
    if [[ ! -e ~/ceph.conf ]]; then
        echo "~/ceph.conf is missing"
        exit 1
    fi
    if [[ ! -e ~/ceph.client.automation-10.keyring ]]; then
        echo "~/ceph.client.automation-10.keyring is missing"
        exit 1
    fi
    FSID=$(grep fsid ~/ceph.conf | awk {'print $3'})
    MONS=$(grep mon_host ~/ceph.conf | awk {'print $3'})
    KEY=$(grep key ~/ceph.client.automation-10.keyring | xargs | awk {'print $3'})
    cat $GLANCE_CR | sed \
                         -e s/FSID/$FSID/g \
                         -e s/MONS/$MONS/g \
                         -e s/KEY/$KEY/g
else
    cat $GLANCE_CR | grep -v -i ceph
fi
