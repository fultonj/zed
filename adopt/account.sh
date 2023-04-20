#!/bin/bash

KEY=https://github.com/fultonj.keys
SSH=$(bash ../ng/ssh_node.sh)
echo "Creating stack user"
$SSH 'useradd stack'
$SSH 'echo "stack ALL=(root) NOPASSWD:ALL" | tee -a /etc/sudoers.d/stack'
$SSH 'chmod 0440 /etc/sudoers.d/stack'
$SSH "mkdir /home/stack/.ssh/; chmod 700 /home/stack/.ssh/; curl $KEY > /home/stack/.ssh/authorized_keys; chmod 600 /home/stack/.ssh/authorized_keys; chcon system_u:object_r:ssh_home_t:s0 /home/stack/.ssh ; chcon unconfined_u:object_r:ssh_home_t:s0 /home/stack/.ssh/authorized_keys; chown -R stack:stack /home/stack/.ssh/ "
