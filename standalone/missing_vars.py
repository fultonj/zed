#!/usr/bin/python3

import yaml

with open('99-standalone-vars', 'r') as standalone_vars_file:
    inv = yaml.safe_load(standalone_vars_file)
    vars = inv['Compute']['vars']

my_ip = "192.168.24.100"
controller_hostname = "standalone.localdomain"
controller_ip = "192.168.24.2"
vnc_url = vars['tripleo_nova_compute_vnc_novncproxy_base_url'] + '/vnc_auto.html'

vars['tripleo_ovn_encap_ip'] = my_ip
vars['tenant_ip'] = my_ip
vars['tripleo_nova_compute_DEFAULT_my_ip'] = my_ip
vars['tripleo_nova_compute_vncserver_proxyclient_address'] = controller_ip
vars['tripleo_nova_compute_vnc_server_listen'] = controller_ip
vars['tripleo_nova_compute_vnc_server_proxyclient_address'] = controller_ip
vars['tripleo_nova_compute_libvirt_live_migration_inbound_addr'] = controller_hostname
vars['tripleo_nova_compute_vncproxy_host'] = vnc_url
vars['tripleo_nova_compute_DEFAULT_reserved_host_memory_mb'] = '1024'
vars['tripleo_nova_compute_reserved_host_memory'] = '1024'
vars['tripleo_nova_libvirt_need_libvirt_secret'] = False

# add missing var to service_user
vars['tripleo_nova_compute_config_overrides']['service_user']['username'] = 'nova'

# add missing vars to neutron
missing_vars = {
    'auth_type': 'v3password',
    'project_name': 'service',
    'user_domain_name': 'Default',
    'project_domain_name': 'Default',
    'region_name': 'regionOne',
    'username': 'neutron',
}
for k,v in missing_vars.items():
    vars['tripleo_nova_compute_config_overrides']['neutron'][k] = v

config_dict = {
    'Compute': {
        'vars': vars
    }
}

with open('99-standalone-vars-new', 'w') as f:
    f.write(yaml.safe_dump(config_dict, default_flow_style=False, width=10000))
