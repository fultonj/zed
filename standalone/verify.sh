#!/bin/bash

export OS_CLOUD=standalone

OVERVIEW=1
CEPH=0
CLEAN=0
GLANCE=0
CINDER=0
NOVA=1

# HYPER=standalone.localdomain
HYPER=centos.example.com

GITHUB=fultonj.keys
OPT='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
EXT_CEPH="192.168.122.253"

function ceph() {
    ssh $OPT $EXT_CEPH -l stack "sudo cephadm shell -- $1" 
}

if [[ $OVERVIEW -eq 1 ]]; then
    openstack endpoint list
    openstack compute service list
    if [[ $CEPH -eq 1 ]]; then
        ssh $OPT $EXT_CEPH -l stack "sudo cephadm shell -- ceph -s"
    fi
fi

if [[ $GLANCE -eq 1 ]]; then
    if [[ $CLEAN -eq 1 ]]; then
        openstack image delete cirros 2> /dev/null
    fi
    if [[ ! -e cirros-0.4.0-x86_64-disk.img ]]; then
        curl https://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img -o cirros-0.4.0-x86_64-disk.img
    fi
    openstack image create cirros --container-format bare --disk-format qcow2 --public --file cirros-0.4.0-x86_64-disk.img
    if [[ $CEPH -eq 1 ]]; then
        ceph "rbd ls -l images"
    fi
    openstack image list
    if [[ $CLEAN -eq 1 ]]; then
        openstack image delete cirros
    fi
fi

if [[ $CINDER -eq 1 ]]; then
    if [[ $CLEAN -eq 1 ]]; then
        openstack volume delete test-volume  2> /dev/null
    fi
    openstack volume create --size 1 test-volume
    openstack volume list
    if [[ $CEPH -eq 1 ]]; then
        ceph "rbd ls -l volumes"
    fi
    if [[ $CLEAN -eq 1 ]]; then
        openstack volume delete test-volume
        openstack volume list
    fi
fi

if [[ $NOVA -eq 1 ]]; then
    export GATEWAY=192.168.24.1
    export STANDALONE_HOST=192.168.24.2
    export PUBLIC_NETWORK_CIDR=192.168.24.0/24
    export PRIVATE_NETWORK_CIDR=192.168.100.0/24
    export PUBLIC_NET_START=192.168.24.4
    export PUBLIC_NET_END=192.168.24.5
    export DNS_SERVER=1.1.1.1
    KEYS=1
    SEC=0
    NET=0
    ROUTE=0
    FLAV=1
    VM=1
    SSH=0
    if [[ $CLEAN -eq 1 ]]; then
        openstack server delete myserver-$HYPER 2> /dev/null
    fi
    if [[ $KEYS -eq 1 ]]; then
        curl --remote-name --location --insecure https://github.com/$GITHUB
        tail -1 $GITHUB > ~/.ssh/id_ed25519.pub
        openstack keypair create --public-key ~/.ssh/id_ed25519.pub default
        rm $GITHUB
    fi
    if [[ $SEC -eq 1 ]]; then
        # create basic security group to allow ssh/ping/dns
        openstack security group create basic
        # allow ssh
        openstack security group rule create basic --protocol tcp --dst-port 22:22 --remote-ip 0.0.0.0/0
        # allow ping
        openstack security group rule create --protocol icmp basic
        # allow DNS
        openstack security group rule create --protocol udp --dst-port 53:53 basic
    fi
    if [[ $NET -eq 1 ]]; then
        openstack network create --external --provider-physical-network datacentre --provider-network-type flat public
        openstack network create --internal private
        openstack subnet create public-net \
                  --subnet-range $PUBLIC_NETWORK_CIDR \
                  --no-dhcp \
                  --gateway $GATEWAY \
                  --allocation-pool start=$PUBLIC_NET_START,end=$PUBLIC_NET_END \
                  --network public
        openstack subnet create private-net \
                  --subnet-range $PRIVATE_NETWORK_CIDR \
                  --network private
        openstack floating ip create public
    fi
    if [[ $ROUTE -eq 1 ]]; then
        # create router
        # NOTE(aschultz): In this case an IP will be automatically assigned
        # out of the allocation pool for the subnet.
        openstack router create vrouter
        openstack router set vrouter --external-gateway public
        openstack router add subnet vrouter private-net
    fi
    if [[ $FLAV -eq 1 ]]; then
        openstack flavor create --ram 512 --disk 1 --ephemeral 0 --vcpus 1 --public m1.tiny
    fi
    if [[ $VM -eq 1 ]]; then
        openstack server create \
                  --nic none \
                  --os-compute-api-version 2.74 --hypervisor-hostname $HYPER \
                  --flavor m1.tiny --image cirros --key-name default \
                  myserver-$HYPER

        # It is expected at this point that instance networking won't work
        # --network private --security-group basic \
        openstack server list
        echo "Waiting for building server to boot..."
        while [[ $(openstack server list -c Status -f value) == "BUILD" ]]; do
            echo -n "."
            sleep 2
        done
        echo ""
        openstack server list
        if [[ $CEPH -eq 1 ]]; then
            ceph "rbd ls -l vms"
        fi
        openstack server show myserver-$HYPER \
                  -c OS-EXT-SRV-ATTR:hypervisor_hostname \
                  -c name
        
    fi
    if [[ $SSH -eq 1 ]]; then
        IP=$(openstack floating ip list -c "Floating IP Address" -f value)
        openstack server add floating ip myserver-$HYPER $IP
        ssh cirros@$IP "lsblk"
    fi
    if [[ $CLEAN -eq 1 ]]; then
        openstack server delete myserver-$HYPER
    fi
fi
