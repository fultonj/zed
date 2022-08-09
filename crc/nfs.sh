#!/bin/bash
# https://www.server-world.info/en/note?os=Fedora_35&p=nfs&f=1

if [[ ! -e /usr/bin/crudini ]]; then
    sudo dnf install crudini -y
fi
if [[ ! -e /usr/sbin/nfsconf ]]; then
    sudo dnf install nfs-utils -y
fi

echo 'Domain in /etc/idmapd.conf is:'
sudo crudini --set /etc/idmapd.conf General Domain $(hostname)
crudini --get /etc/idmapd.conf General Domain

echo '/home/nfsshare 10.0.0.0/24(rw,no_root_squash)' > /tmp/exports
sudo mv /tmp/exports /etc/exports
ls -l /etc/exports
echo 'Contains: '
cat /etc/exports

sudo mkdir -p /home/nfsshare
sudo systemctl enable --now rpcbind nfs-server

# Firewall
sudo firewall-cmd --add-service=nfs

# Next line is only if we're serving NFS3
#sudo firewall-cmd --add-service={nfs3,mountd,rpc-bind}

#sudo firewall-cmd --runtime-to-permanent
