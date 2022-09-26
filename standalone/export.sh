#!/bin/bash

CONTROLLER_IP=192.168.24.2
SRC=/home/stack/ext/tripleo-ansible/scripts/tripleo-standalone-vars
DST=/home/stack/ext/tripleo-ansible/tripleo_ansible/inventory/99-custom
OPT='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'

scp $OPT $SRC stack@$CONTROLLER_IP:/home/stack/tripleo-standalone-vars

ssh $OPT $CONTROLLER_IP -l stack "python3 \
  tripleo-standalone-vars \
  -c \$(ls /home/stack/ | grep standalone-ansible) \
  -r Standalone"

scp $OPT stack@$CONTROLLER_IP:/home/stack/99-standalone-vars 99-standalone-vars

if [[ ! -e 99-standalone-vars ]]; then
    echo "Unable to get a copy of 99-standalone-vars from $CONTROLLER_IP"
    exit 1
fi

# workaround service_net_map issues
# https://review.opendev.org/c/openstack/tripleo-ansible/+/840509/36/scripts/tripleo-standalone-vars#95
sed -i '/service_net_map/d' 99-standalone-vars


cat 99-standalone-vars missing_vars > $DST

if [[ -e 03-tripleo ]]; then
    # workaround https://paste.opendev.org/show/bW1qCm8K5SsdaYYpm2vX/
    # 03-tripleo is provided by https://review.opendev.org/840509
    cp 03-tripleo $DST
fi
