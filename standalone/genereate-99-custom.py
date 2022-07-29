#!/usr/bin/python3

# https://review.opendev.org/c/openstack/tripleo-ansible/+/840509

import configparser
import re
import sys
import yaml

file = sys.argv[1]
config = configparser.ConfigParser(default_section=None)
config.read(file)

role_prefix = 'tripleo_nova_compute'
settings = {}
configs = {}

for section in config.sections():
    section_prefix = '{}_{}'.format(role_prefix, section)
    for option in config.options(section):
        section_dict = configs.setdefault(section, {})
        option_var = '{}_{}'.format(section_prefix, option)
        settings[option_var] = config.get(section, option, raw=True)
        section_dict[option] = '{{{{ {} }}}}'.format(option_var)

needed_vars = [
    # 'tripleo_nova_compute_DEFAULT_host',
    # 'tripleo_nova_compute_DEFAULT_my_ip',
    'tripleo_nova_compute_DEFAULT_transport_url',
    'tripleo_nova_compute_cache_memcache_servers',
    'tripleo_nova_compute_cinder_auth_url',
    'tripleo_nova_compute_cinder_password',
    # 'tripleo_nova_compute_libvirt_live_migration_inbound_addr',
    # 'tripleo_nova_compute_libvirt_live_migration_uri',
    'tripleo_nova_compute_neutron_auth_url',
    'tripleo_nova_compute_neutron_password',
    'tripleo_nova_compute_oslo_messaging_notifications_transport_url',
    'tripleo_nova_compute_placement_auth_url',
    'tripleo_nova_compute_placement_password',
    'tripleo_nova_compute_service_user_auth_url',
    'tripleo_nova_compute_service_user_password',
    # 'tripleo_nova_compute_vnc_novncproxy_base_url',
    # 'tripleo_nova_compute_vnc_server_listen',
    # 'tripleo_nova_compute_vnc_server_proxyclient_address',
    # 'tripleo_nova_compute_DEFAULT_reserved_host_memory_mb',
]

var_lines = []

for var in needed_vars:
    var_lines.append('{}="{}"'.format(var, settings[var]))

with open('99-custom', 'w') as f:
    f.write('[Compute:vars]\n')
    for line in var_lines:
        f.write(line)
        f.write('\n')
