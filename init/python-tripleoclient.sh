#!/usr/bin/env bash
# Speed up my work on deployed_ceph

pushd /home/stack/python-tripleoclient
python3 setup.py bdist_egg
sudo python3 setup.py install --verbose
#openstack overcloud ceph deploy --help
popd
