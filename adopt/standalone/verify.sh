#!/bin/bash

export OS_CLOUD=standalone

OVERVIEW=1
GLANCE=1
CINDER=1
NOVA=1
RGW=1
CEPH=1
CEPHADM=1

GITHUB=fultonj.keys

function ceph() {
    if [[ $CEPHADM -eq 1 ]]; then
        sudo cephadm shell -- $1
    else
        MON=ceph-mon-standalone
        sudo podman exec $MON $1
    fi
}

if [[ $OVERVIEW -eq 1 ]]; then
    openstack endpoint list
    if [[ $CEPH -eq 1 ]]; then
        ceph "ceph -s"
    fi
fi

if [[ $GLANCE -eq 1 ]]; then
    curl https://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img -o cirros-0.4.0-x86_64-disk.img
    openstack image create cirros --container-format bare --disk-format qcow2 --public --file cirros-0.4.0-x86_64-disk.img
    if [[ $CEPH -eq 1 ]]; then
        ceph "rbd ls -l images"
    fi
    openstack image list
fi

if [[ $CINDER -eq 1 ]]; then
    openstack volume create --size 1 test-volume
    openstack volume list
    if [[ $CEPH -eq 1 ]]; then
        ceph "rbd ls -l volumes"
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
    SEC=1
    NET=1
    ROUTE=1
    PRE=1
    VM=1
    SSH=0
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
    fi
    if [[ $ROUTE -eq 1 ]]; then
        # create router
        # NOTE(aschultz): In this case an IP will be automatically assigned
        # out of the allocation pool for the subnet.
        openstack router create vrouter
        openstack router set vrouter --external-gateway public
        openstack router add subnet vrouter private-net
    fi
    if [[ $PRE -eq 1 ]]; then
        openstack floating ip create public
        openstack flavor create --ram 512 --disk 1 --ephemeral 0 --vcpus 1 --public m1.tiny
    fi
    if [[ $VM -eq 1 ]]; then
        openstack server create --flavor m1.tiny --image cirros --key-name default --network private --security-group basic myserver
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
    fi
    if [[ $SSH -eq 1 ]]; then
        IP=$(openstack floating ip list -c "Floating IP Address" -f value)
        openstack server add floating ip myserver $IP
        ssh cirros@$IP "lsblk"
    fi
fi

if [[ $RGW -eq 1 ]]; then
    COUNT=5
    echo -n "Creating $COUNT 'Swift' containers and observing "
    echo "the RGW buckets.index OBJECTS field increment"
    for I in $(seq 0 $COUNT); do 
        openstack container create mydir$I
        sleep 1
        ceph "ceph df" | egrep "POOL|index"
    done

    echo "Deleting the $COUNT 'Swift' containers"
    openstack container list
    for I in $(seq 0 $COUNT); do 
        openstack container delete mydir$I
    done
    openstack container list
fi
