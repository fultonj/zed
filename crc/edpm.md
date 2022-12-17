# Set up basic EDPM environment

[slagle's intall_yamls edpm branch](https://github.com/slagle/install_yamls/tree/edpm-integration)
should be in home directory.

## Control Plane

- [crc.sh](crc.sh)
- [maria.sh](maria.sh): Deploy MariaDB
- [keystone.sh](keystone.sh): Deploy Keystone
- [test_keystone.sh](test_keystone.sh): Test Keystone

## Ceph / Glance

- [ceph_secret.sh](cr/ceph_secret.sh): Create a ceph-secret
- [glance.sh](glance.sh): Deploy Glance
- [glance_dev.sh](glance_dev.sh): Script to help Glance Operator development ([notes](glance_dev_notes.md))
- oc create -f [glance_v1beta1_ceph_secret.yaml](cr/glance_v1beta1_ceph_secret.yaml)
- [test_glance.sh](test_glance.sh): Test Glance

## EDPM

Boot CentOS9 VM to configure as compute node
```
 pushd ~/install_yamls
 make ansibleee
 oc get crds | grep ansible
 
 cd ~/install_yamls/devsetup
 make crc_attach_default_interface
 make edpm-compute
 popd
```

- [edpm-compute-ip.sh](edpm-compute-ip.sh): to update IP in next CR
- oc create -f [edpm-play.yaml](cr/edpm-play.yaml)
