# OpenStack Operators on CRC

## CRC
- [crc.sh](crc.sh): clone [install_yamls](https://github.com/openstack-k8s-operators/install_yamls) and install CRC

## Deploy OpenStack without Meta Operator

- [maria.sh](maria.sh): Deploy MariaDB
- [keystone.sh](keystone.sh): Deploy Keystone
- [test_keystone.sh](test_keystone.sh): Test Keystone
- [glance.sh](glance.sh): Deploy Glance
- [test_glance.sh](test_glance.sh): Test Glance
- [glance_dev.sh](glance_dev.sh): Script to help Glance Operator development ([notes](glance_dev_notes.md))
- [rabbit.sh](rabbit.sh): Deploy RabbitMQ
- [cinder.sh](cinder.sh): Deploy Cinder
- [test_cinder.sh](test_cinder.sh): Test Cinder
- [clean.sh](clean.sh): Remove cinder, rabbit, glance, keystone, maria or crc

## Deploy OpenStack with Meta Operator

- [meta.sh](meta.sh): Deploy Maria, Keystone, Glance, RabbitMQ and Cinder
- [scale.sh](scale.sh): Scale openstack, glance and cinder controllers

## Other

- [cr](cr): Directory of CRs or scripts to create CRs for the glance or cinder operators.
- [Overview of lib-common interface to configure storage backends](config_files_to_services.md)
