#!/bin/bash

# Does steps from this
# https://docs.ceph.com/en/latest/cephadm/install/

MON_IP=192.168.122.250

if [[ ! -e /usr/sbin/cephadm ]]; then
    URL=https://cbs.centos.org/kojifiles/packages/cephadm/16.2.9/1.el9s/noarch/cephadm-16.2.9-1.el9s.noarch.rpm
    sudo dnf install -y $URL
fi

sudo cephadm bootstrap \
     --allow-fqdn-hostname \
     --mon-ip $MON_IP \
     --single-host-defaults

sudo cephadm shell -- ceph orch apply osd --all-available-devices

sleep 30

sudo cephadm shell -- ceph -s
