#!/usr/bin/env bash

# Run this script to confirm that
# edpm-compute-0 (standalone) can ping edpm-compute-1
# on its IPs on the following networks
#
# Tenant   vlan22 172.10.0.0/24
# Internal vlan20 172.17.0.0/24
# Storage  vlan21 172.18.0.0/24
# External vlan44 172.19.0.0/24

for IP in 192.168.122.101 172.10.0.101 172.17.0.101 172.18.0.101; do 
    ping -c 1 $IP;
done
