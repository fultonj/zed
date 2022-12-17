#!/bin/bash

# Run after running 'make edpm-compute' but before running 'make edpm-play'
# https://github.com/slagle/install_yamls/tree/edpm-integration/devsetup#edpm-deployment

CHANGE=0

OLD_IP=192.168.122.139
MAC=$(sudo virsh dumpxml edpm-compute-0 | grep 'mac address' | awk {'print $2'} \
      | sed -e s/\\///g -e s/\>//g -e s/\'//g | awk 'BEGIN { FS = "=" } ; { print $2 }')
IP=$(arp -n | grep $MAC | awk {'print $1'})

if [[ $CHANGE -eq 1 ]]; then
    sed -i s/$OLD_IP/$IP/g  ~/install_yamls/devsetup/edpm/edpm-play.yaml
else
    echo $IP
    echo "sed -i s/$OLD_IP/$IP/g  ~/install_yamls/devsetup/edpm/edpm-play.yaml"
fi
