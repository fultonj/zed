#!/usr/bin/python3

import yaml

with open('/home/stack/ceph_client.yaml', 'r') as ceph_client_file:
    ceph_client = yaml.safe_load(ceph_client_file)

for i in range(0, len(ceph_client['keys'])):
    ceph_client['keys'][i]['name'] = 'client.' + ceph_client['keys'][i]['name']

standalone_vars = {
    'tripleo_ceph_client_config_home': '/var/lib/tripleo-config/ceph',
    'tripleo_cinder_enable_rbd_backend': True,
    'tripleo_ceph_cluster_fsid': ceph_client['tripleo_ceph_client_fsid'],
    'tripleo_ceph_cluster_keys': ceph_client['keys'],
    'tripleo_ceph_cluster_name': ceph_client['tripleo_ceph_client_cluster'],
    'external_cluster_mon_ips': ceph_client['external_cluster_mon_ips'],
}

config_dict = {
    'Compute': {
        'vars': standalone_vars,
        'hosts': 'localhost',
        'children': {
            'ceph_client': {
                'hosts': 'localhost'
            },
            'tripleo_nova_libvirt': {
                'hosts': 'localhost'
            }
        }
    }
}

with open('08-ceph', 'w') as f:
    f.write(yaml.safe_dump(config_dict, default_flow_style=False, width=10000))
