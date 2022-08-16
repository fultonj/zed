#!/bin/bash
# Install standalone ceph with pools for openstack

MON_IP=192.168.122.253

echo "Ensure all dependencies are installed"
for PKG in container-selinux podman catatonit util-linux lvm2 jq; do
    rpm -q $PKG > /dev/null
    if [[ $? -gt 0 ]]; then
        sudo dnf install -y $PKG
    fi
done
if [[ ! -e /usr/sbin/cephadm ]]; then
    URL=https://cbs.centos.org/kojifiles/packages/cephadm/16.2.9/1.el9s/noarch/cephadm-16.2.9-1.el9s.noarch.rpm
    sudo dnf install -y $URL
fi

echo "Ensure Ceph mon/mgr is running and we have an FSID"
FSID=$(sudo cephadm ls | jq '.[]' | jq 'select(.name | test("^mon*")).fsid');
if [ -z "$FSID" ]; then
    sudo cephadm bootstrap \
         --log-to-file \
         --skip-prepare-host \
         --allow-fqdn-hostname \
         --mon-ip $MON_IP \
         --single-host-defaults
    FSID=$(sudo cephadm ls | jq '.[]' | jq 'select(.name | test("^mon*")).fsid');
fi
echo $FSID

echo "Create OSDs if necessary"
OSD_COUNT=$(sudo cephadm shell -- ceph status --format json 2> /dev/null | jq .osdmap.num_up_osds)
if [[ $OSD_COUNT -eq 0 ]]; then
    # you must have on free block device for this to work e.g. /dev/vdb
    sudo cephadm shell -- ceph orch apply osd --all-available-devices
    echo "wating 30 seconds for OSDs to come up"
    date
    sleep 30
    date
    OSD_COUNT=$(sudo cephadm shell -- ceph status --format json 2> /dev/null | jq .osdmap.num_up_osds)
fi
echo "OSD Count: $OSD_COUNT"
sudo cephadm shell -- ceph -s 2> /dev/null

echo "Ensure pools for openstack exist"
for POOL in vms volumes images; do
    # pool creation is idempotent
    sudo cephadm shell -- ceph osd pool create $POOL 2> /dev/null
done
sudo cephadm shell -- ceph df 2> /dev/null

echo "Create cephx key for openstack client if necessary"
CEPHX=$(sudo cephadm shell -- ceph auth get client.openstack 2> /dev/null | grep key | awk {'print $3'})
if [ -z "$CEPHX" ]; then
    sudo cephadm shell -- ceph auth add client.openstack mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=vms, allow rwx pool=volumes, allow rwx pool=images'
    CEPHX=$(sudo cephadm shell -- ceph auth get client.openstack 2> /dev/null | grep key | awk {'print $3'})
fi
echo $CEPHX

echo "Create ceph_client.yaml file for external compute nodes"
cat <<EOF > ceph_client.yaml
---
tripleo_ceph_client_fsid: $FSID
tripleo_ceph_client_cluster: ceph
external_cluster_mon_ips: $MON_IP
keys:
- name: openstack
  key: $CEPHX
  mon: 'allow r'
  osd: 'allow class-read object_prefix rbd_children, allow rwx pool=vms, allow rwx pool=volumes, allow rwx pool=images'
EOF
ls -l ceph_client.yaml

echo "Create ceph_heat.yaml file for standalone installer"
cat <<EOF > ceph_heat.yaml
---
parameter_defaults:
  CephClusterFSID: $FSID
  CephClientKey: $CEPHX
  CephExternalMonHost: $MON_IP
EOF
ls -l ceph_heat.yaml
