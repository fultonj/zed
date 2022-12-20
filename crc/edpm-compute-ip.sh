#!/bin/bash

# Returns the IP address of the currently running EDPM compute by suffix
# If no suffix is provided then it assumes the suffix 0

# $ ./edpm-compute-ip.sh
# 192.168.122.227
# $ ./edpm-compute-ip.sh 0
# 192.168.122.227
# $ ./edpm-compute-ip.sh 2
# 192.168.122.166
# $ ./edpm-compute-ip.sh 1
# 192.168.122.254

# Run after running 'make edpm-compute' but before running 'make edpm-play'
# https://github.com/slagle/install_yamls/tree/edpm-integration/devsetup#edpm-deployment

if [ $# -eq 0 ]; then
    SUFFIX=0
else
    SUFFIX=$1
fi

VM=edpm-compute-${SUFFIX}

CHANGE=0

OLD_IP=192.168.122.139
MAC=$(sudo virsh dumpxml $VM | grep 'mac address' | awk {'print $2'} \
      | sed -e s/\\///g -e s/\>//g -e s/\'//g | awk 'BEGIN { FS = "=" } ; { print $2 }')
IP=$(arp -n | grep $MAC | awk {'print $1'})

if [[ $CHANGE -eq 1 ]]; then
    sed -i s/$OLD_IP/$IP/g  ~/install_yamls/devsetup/edpm/edpm-play.yaml
else
    echo $IP
    #echo "sed -i s/$OLD_IP/$IP/g cr/edpm-play.yaml"
fi
