#!/bin/bash

CONTROLLER_IP=192.168.24.2
SRC=/var/lib/config-data/puppet-generated/nova/etc/nova/nova.conf
DST=/home/stack/tripleo-ansible/tripleo_ansible/inventory/99-custom
OPT='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'

ssh $OPT $CONTROLLER_IP -l stack \
    "sudo cp $SRC /tmp/nova.conf; sudo chown stack:stack /tmp/nova.conf"
scp $OPT stack@$CONTROLLER_IP:/tmp/nova.conf .
python3 genereate-99-custom.py ./nova.conf
rm -fv ./nova.conf
cat 99-custom missing_vars > $DST
