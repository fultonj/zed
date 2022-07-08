#!/bin/bash

# Update $SRC with data from $CONTROLLER_IP and localhost
# Set WRITE to 1 if you want to acutally change $SRC (else dry run mode)

WRITE=1
CONTROLLER_IP=192.168.24.2
SRC=/home/stack/tripleo-ansible/tripleo_ansible/inventory/99-custom
DEF=/tmp/$(basename $SRC)
cp -v -f $SRC $DEF

function ssh_run () {
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        $CONTROLLER_IP -l stack "$1"
}

if [[ ! -e $DEF ]]; then
    echo "Failing $DEF is missing"
    exit 1
fi

# Extract data
# tripleo_nova_compute_libvirt_live_migration_inbound_addr="sm9.ctlplane.localdomain"
OLD_CONTROLLER_HOSTNAME=$(grep tripleo_nova_compute_libvirt_live_migration_inbound_addr \
                               $DEF \
                              | awk 'BEGIN { FS = "=" } ; { print $2 }' \
                              | sed s/\"//g)
NEW_CONTROLLER_HOSTNAME=$(ssh_run "hostname")

#tripleo_nova_compute_DEFAULT_host="tsr"
OLD_COMPUTE_HOSTNAME=$(grep tripleo_nova_compute_DEFAULT_host \
                            $DEF \
                           | awk 'BEGIN { FS = "=" } ; { print $2 }' \
                           | sed s/\"//g)
NEW_COMPUTE_HOSTNAME=$(hostname)

# tripleo_nova_compute_cinder_password
OLD_CINDER=$(grep tripleo_nova_compute_cinder_password \
                  $DEF \
                 | awk 'BEGIN { FS = "=" } ; { print $2 }' \
                 | sed s/\"//g)
NEW_CINDER=$(ssh_run "grep -i cinder tripleo-standalone-passwords.yaml | awk {'print \$2'}")

# tripleo_nova_compute_DEFAULT_transport_url
# tripleo_nova_compute_oslo_messaging_notifications_transport_url
# (these also use NEW_CONTROLLER_HOSTNAME)
OLD_RABBIT=$(grep tripleo_nova_compute_DEFAULT_transport_url \
                  $DEF \
                 | awk 'BEGIN { FS = "=" } ; { print $2 }' \
                 | awk 'BEGIN { FS = ":" } ; { print $3 }' \
                 | awk 'BEGIN { FS = "@" } ; { print $1 }' \
                 | sed s/\"//g)
NEW_RABBIT=$(ssh_run "grep -i RabbitPassword tripleo-standalone-passwords.yaml | awk {'print \$2'}")

sed -i $DEF \
    -e s/$OLD_CONTROLLER_HOSTNAME/$NEW_CONTROLLER_HOSTNAME/g \
    -e s/$OLD_COMPUTE_HOSTNAME/$NEW_COMPUTE_HOSTNAME/g \
    -e s/$OLD_CINDER/$NEW_CINDER/g \
    -e s/$OLD_RABBIT/$NEW_RABBIT/g

diff -u $SRC $DEF

if [[ $WRITE -eq 1 ]]; then
    cp -v -f $DEF $SRC
fi
