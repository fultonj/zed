#!/bin/bash
# Install standalone ceph with pools for openstack

MON_IP=192.168.122.250

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
fi
FSID=$(sudo cephadm ls | jq '.[]' | jq 'select(.name | test("^mon*")).fsid');
echo $FSID

echo "Ensure all available devices are OSDs"
sudo cephadm shell -- ceph orch apply osd --all-available-devices

sudo cephadm shell -- ceph -s
