#!/usr/bin/env bash

SPEC=1
CEPH_USER=1
CEPH=1

export CEPH_IP=172.18.0.100

ping -c 1 $CEPH_IP > /dev/null
if [[ $? -gt 0 ]]; then
    echo "FATAL: Cannot ping CEPH_IP=$CEPH_IP"
    exit 1
fi

# My system has /dev/vdb /dev/vdc so I don't need osd_spec.yaml

if [[ $SPEC -eq 1 ]]; then
    sudo openstack overcloud ceph spec \
         --standalone \
         --mon-ip $CEPH_IP \
         --output $HOME/ceph_spec.yaml
fi

if [[ $CEPH_USER -eq 1 ]]; then
    sudo openstack overcloud ceph user enable \
         --standalone \
         $HOME/ceph_spec.yaml
fi

cat <<EOF > $HOME/initial_ceph.conf
[global]
osd pool default size = 1
[mon]
mon_warn_on_pool_no_redundancy = false
EOF

if [[ $CEPH -eq 1 ]]; then
    sudo openstack overcloud ceph deploy \
         --mon-ip $CEPH_IP \
         --ceph-spec $HOME/ceph_spec.yaml \
         --config $HOME/initial_ceph.conf \
         --standalone \
         --single-host-defaults \
         --skip-hosts-config \
         --skip-container-registry-config \
         --skip-user-create \
         --network-data network_data.yaml \
         --output $HOME/deployed_ceph.yaml
fi
