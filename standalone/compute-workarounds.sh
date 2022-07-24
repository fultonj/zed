#!/usr/bin/env bash

UPLINK=1
YAML_YML=1

export CONTROLLER=192.168.122.252
export INTERFACE=eth1
export IP=192.168.122.251
export ROUTE=192.168.122.1
export NETMASK=24

if [[ $UPLINK -eq 1 ]]; then
    # TASK Run tripleo_os_net_config_module with network_config 
    # disables the Internet uplink on eth1 and assigns wrong IP
    # then playbook fails later when trying to access Internet.
    # When this failure happens, run these commands to restore.
    WRONG_IP=$(ip a s $INTERFACE | grep inet | grep -v inet6 | awk {'print $2'})
    sudo ip addr del $WRONG_IP dev $INTERFACE
    sudo ip link set dev $INTERFACE down
    sudo ip addr add $IP/$NETMASK dev $INTERFACE
    sudo ip link set dev $INTERFACE up
    sudo ip route add default via $ROUTE dev $INTERFACE proto static metric 100
    ip a s $INTERFACE
    ip r
    for TEST in $CONTROLLER $ROUTE 8.8.8.8 google.com; do
	ping -c 1 $TEST;
	if [[ ! $? -eq 0 ]]; then
	    echo "UPLINK connection to $TEST not working as expected."
	    exit 1
	fi
    done
fi

function yml_yaml {
    # symlink .yml files to .yaml files
    echo "yml_yaml: $1"
    pushd $1
    for F1 in $(ls *.yml); do
        F2=$(echo $F1 | sed -e s/yml/yaml/g)
        sudo ln -vsf $F1 $F2
    done
    popd
}

function yaml_yml {
    # symlink .yaml files to .yml files
    echo "yaml_yml: $1"
    pushd $1
    for F1 in $(ls *.yaml); do
        F2=$(echo $F1 | sed -e s/yaml/yml/g)
        sudo ln -vsf $F1 $F2
    done
    popd
}


if [[ $YAML_YML -eq 1 ]]; then
    yml_yaml /home/stack/tripleo-ansible/tripleo_ansible/roles/tripleo_nova_compute/tasks
    yaml_yml /home/stack/tripleo-ansible/tripleo_ansible/roles/tripleo_nova_libvirt/tasks
fi
