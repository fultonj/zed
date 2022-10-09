#!/usr/bin/python3

import yaml

multiple = True

with open('/home/stack/ceph_client.yaml', 'r') as ceph_client_file:
    ceph_client = yaml.safe_load(ceph_client_file)

for i in range(0, len(ceph_client['keys'])):
    ceph_client['keys'][i]['name'] = 'client.' + ceph_client['keys'][i]['name']

standalone_vars = {
    'tripleo_ceph_client_config_home': '/var/lib/tripleo-config/ceph',
    'tripleo_cinder_enable_rbd_backend': True,
    'tripleo_nova_libvirt_enable_rbd_backend': True,
    'tripleo_ceph_cluster_fsid': ceph_client['tripleo_ceph_client_fsid'],
    'tripleo_ceph_cluster_keys': ceph_client['keys'],
    'external_cluster_mon_ips': ceph_client['external_cluster_mon_ips'],
    'tripleo_ceph_cluster_name': ceph_client['tripleo_ceph_client_cluster'],
    'tripleo_ceph_client_user_name': ceph_client['keys'][0]['name'].replace('client.', '')
}

if multiple:
    with open('tripleo_ceph_cluster_multi_config.yml', 'r') as multi_file:
        ceph_clients = yaml.safe_load(multi_file)
    standalone_vars['tripleo_ceph_cluster_multi_config'] = \
        ceph_clients['tripleo_ceph_cluster_multi_config']

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
