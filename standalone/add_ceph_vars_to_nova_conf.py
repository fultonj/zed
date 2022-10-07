#!/usr/bin/python3

import yaml

with open('/home/stack/ceph_client.yaml', 'r') as ceph_client_file:
    ceph_client = yaml.safe_load(ceph_client_file)
    fsid = ceph_client['tripleo_ceph_client_fsid']

with open('99-standalone-vars-new', 'r') as standalone_vars_file:
    inv = yaml.safe_load(standalone_vars_file)
    vars = inv['Compute']['vars']
    
libvirt = {
    'rbd_secret_uuid': fsid,
    'images_rbd_ceph_conf': '/etc/ceph/ceph.conf',
    'images_rbd_glance_copy_poll_interval': '15',
    'images_rbd_glance_copy_timeout': '600',
    'images_rbd_glance_store_name': 'default_backend',
    'images_rbd_pool': 'vms',
    'images_type': 'rbd',
    'rbd_user': 'openstack'
}
vars['tripleo_nova_compute_config_overrides']['libvirt'] = libvirt

config_dict = {
    'Compute': {
        'vars': vars
    }
}

with open('99-standalone-vars-new-ceph', 'w') as f:
    f.write(yaml.safe_dump(config_dict, default_flow_style=False, width=10000))
