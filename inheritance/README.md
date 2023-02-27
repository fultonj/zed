# Two Way Test for Inheritance

[nodes_from_role.sh](nodes_from_role.sh) is a CLI test of what's
described here:

https://openstack-k8s-operators.github.io/dataplane-operator/inheritance

We should be able to create [role.yaml](role.yaml) and 
have `node1` and `node2` created automatically.

The logic of this test could be moved to:

https://github.com/openstack-k8s-operators/dataplane-operator/blob/main/controllers/suite_test.go

Similarly if we directly create a node with a role like
[node3_from.yaml](node3_from.yaml) as tested by
[updated_role_from_node.sh](updated_role_from_node.sh) 
then we should see it added to the role list
in [role.yaml](role.yaml).

## Sample output

### Nodes from a Role

```
[fultonj@osp-storage-01 inheritance]$ ./nodes_from_role.sh 
~/zed/inheritance ~/zed/inheritance
Login successful.

You have access to 66 projects, the list has been suppressed. You can list all projects with 'oc projects'

Using project "openstack".
openstackdataplanenode.dataplane.openstack.org "openstackdataplanerole-sample-inheritance-node-0" deleted
openstackdataplanenode.dataplane.openstack.org "openstackdataplanerole-sample-inheritance-node-1" deleted
openstackdataplanerole.dataplane.openstack.org/openstackdataplanerole-sample-inheritance created
NAME                                        AGE
openstackdataplanerole-sample-inheritance   0s
null
2 inheritance nodes were created
openstackdataplanerole-sample-inheritance-node-0   True     DataPlaneNode ready
openstackdataplanerole-sample-inheritance-node-1   True     DataPlaneNode ready
{
  "apiVersion": "dataplane.openstack.org/v1beta1",
  "kind": "OpenStackDataPlaneNode",
  "metadata": {
    "creationTimestamp": "2023-02-27T23:02:50Z",
    "generation": 1,
    "name": "openstackdataplanerole-sample-inheritance-node-0",
    "namespace": "openstack",
    "resourceVersion": "25893707",
    "uid": "dc9f7832-61c1-4a99-8e95-ac5651569fba"
  },
  "spec": {
    "ansibleHost": "192.168.122.18",
    "deploy": false,
    "hostName": "openstackdataplanenode-sample-1.localdomain",
    "node": {
      "ansibleSSHPrivateKeySecret": "",
      "networkConfig": {
        "template": "templates/net_config_bridge.j2"
      },
      "networks": [
        {
          "fixedIP": "192.168.122.18",
          "network": "ctlplane"
        }
      ]
    },
    "role": "openstackdataplanerole-sample-inheritance"
  },
  "status": {
    "conditions": [
      {
        "lastTransitionTime": "2023-02-27T23:02:28Z",
        "message": "DataPlaneNode ready",
        "reason": "Ready",
        "status": "True",
        "type": "DataPlaneNodeReady"
      }
    ]
  }
}
{
  "apiVersion": "dataplane.openstack.org/v1beta1",
  "kind": "OpenStackDataPlaneNode",
  "metadata": {
    "creationTimestamp": "2023-02-27T23:02:50Z",
    "generation": 1,
    "name": "openstackdataplanerole-sample-inheritance-node-1",
    "namespace": "openstack",
    "resourceVersion": "25893708",
    "uid": "8b972f35-d975-40fc-ba43-02f29898282e"
  },
  "spec": {
    "ansibleHost": "192.168.122.19",
    "deploy": false,
    "hostName": "openstackdataplanenode-sample-2.localdomain",
    "node": {
      "ansibleSSHPrivateKeySecret": "",
      "managed": true,
      "networkConfig": {
        "template": "templates/net_config_bridge.j2"
      },
      "networks": [
        {
          "fixedIP": "192.168.122.19",
          "network": "ctlplane"
        }
      ]
    },
    "role": "openstackdataplanerole-sample-inheritance"
  },
  "status": {
    "conditions": [
      {
        "lastTransitionTime": "2023-02-27T23:02:28Z",
        "message": "DataPlaneNode ready",
        "reason": "Ready",
        "status": "True",
        "type": "DataPlaneNodeReady"
      }
    ]
  }
}
Each node has its own inventory:
dataplanenode-openstackdataplanerole-sample-inheritance-node-0-inventory   1      23m
dataplanenode-openstackdataplanerole-sample-inheritance-node-1-inventory   1      23m
apiVersion: v1
data:
  inventory: |
    all:
        hosts:
            openstackdataplanerole-sample-inheritance-node-0:
                ansible_host: 192.168.122.18
                ansible_port: "22"
                ansible_user: root
                managed: "false"
                management_network: ctlplane
                network_config: '{template: templates/net_config_bridge.j2}'
                networks: '[{fixedIP: 192.168.122.18, network: ctlplane}]'
kind: ConfigMap
metadata:
  creationTimestamp: "2023-02-27T22:39:30Z"
  name: dataplanenode-openstackdataplanerole-sample-inheritance-node-0-inventory
  namespace: openstack
  resourceVersion: "25882497"
  uid: aec9fbea-eaf0-4f20-b22a-80e356227d5a
apiVersion: v1
data:
  inventory: |
    all:
        hosts:
            openstackdataplanerole-sample-inheritance-node-1:
                ansible_host: 192.168.122.19
                ansible_port: "22"
                ansible_user: root
                managed: "true"
                management_network: ctlplane
                network_config: '{template: templates/net_config_bridge.j2}'
                networks: '[{fixedIP: 192.168.122.19, network: ctlplane}]'
kind: ConfigMap
metadata:
  creationTimestamp: "2023-02-27T22:39:30Z"
  name: dataplanenode-openstackdataplanerole-sample-inheritance-node-1-inventory
  namespace: openstack
  resourceVersion: "25882499"
  uid: 83f23133-2a95-4a39-bcf0-2b483730a4f2
Deleting inventories created by the node
configmap "dataplanenode-openstackdataplanerole-sample-inheritance-node-0-inventory" deleted
configmap "dataplanenode-openstackdataplanerole-sample-inheritance-node-1-inventory" deleted
Deleting nodes created by role
openstackdataplanenode.dataplane.openstack.org "openstackdataplanerole-sample-inheritance-node-0" deleted
openstackdataplanenode.dataplane.openstack.org "openstackdataplanerole-sample-inheritance-node-1" deleted
Deleting role
openstackdataplanerole.dataplane.openstack.org "openstackdataplanerole-sample-inheritance" deleted
~/zed/inheritance
[fultonj@osp-storage-01 inheritance]$ 
```

### Updated Role from a Node

```
[fultonj@osp-storage-01 inheritance]$ ./updated_role_from_node.sh 
~/zed/inheritance ~/zed/inheritance
Login successful.

You have access to 66 projects, the list has been suppressed. You can list all projects with 'oc projects'

Using project "openstack".
No resources found in openstack namespace.
openstackdataplanerole.dataplane.openstack.org/openstackdataplanerole-sample-inheritance created

Creating node3_from
-------------------
openstackdataplanenode.dataplane.openstack.org/openstackdataplanenode-sample-3-from-inheritance created
apiVersion: dataplane.openstack.org/v1beta1
kind: OpenStackDataPlaneNode
metadata:
  creationTimestamp: "2023-02-27T23:03:49Z"
  generation: 1
  name: openstackdataplanenode-sample-3-from-inheritance
  namespace: openstack
  resourceVersion: "25894234"
  uid: 834aa93e-1969-46e9-a718-f5254d5b32f0
spec:
  ansibleHost: 192.168.122.20
  deploy: true
  hostName: openstackdataplanenode-sample-3.localdomain
  node:
    networks:
    - fixedIP: 192.168.122.20
      network: ctlplane
  role: openstackdataplanerole-sample-inheritance
status:
  conditions:
  - lastTransitionTime: "2023-02-27T23:03:28Z"
    message: ConfigureNetwork not yet ready
    reason: Requested
    severity: Info
    status: "False"
    type: ConfigureNetworkReady
  - lastTransitionTime: "2023-02-27T23:03:28Z"
    message: DataPlaneNode not yet ready
    reason: Requested
    severity: Info
    status: "False"
    type: DataPlaneNodeReady

Showing role of node3_from
--------------------------
apiVersion: dataplane.openstack.org/v1beta1
kind: OpenStackDataPlaneRole
metadata:
  creationTimestamp: "2023-02-27T23:03:49Z"
  generation: 2
  name: openstackdataplanerole-sample-inheritance
  namespace: openstack
  resourceVersion: "25894231"
  uid: ca00e6fd-6662-4f13-b824-e49b0663b341
spec:
  dataPlaneNodes:
  - ansibleHost: 192.168.122.18
    deploy: true
    hostName: openstackdataplanenode-sample-1.localdomain
    node:
      ansibleSSHPrivateKeySecret: ""
      networkConfig:
        template: templates/net_config_bridge.j2
      networks:
      - fixedIP: 192.168.122.18
        network: ctlplane
  - ansibleHost: 192.168.122.19
    deploy: true
    hostName: openstackdataplanenode-sample-2.localdomain
    node:
      ansibleSSHPrivateKeySecret: ""
      managed: true
      networkConfig:
        template: templates/net_config_bridge.j2
      networks:
      - fixedIP: 192.168.122.19
        network: ctlplane
  - deploy: false
    node:
      ansibleSSHPrivateKeySecret: ""
      networkConfig:
        template: templates/net_config_bridge.j2
    nodeFrom: openstackdataplanenode-sample-3-from-inheritance
  nodeTemplate:
    ansiblePort: 22
    ansibleSSHPrivateKeySecret: ""
    ansibleUser: root
    managementNetwork: ctlplane
    networkConfig:
      template: templates/net_config_bridge.j2

Note that the dataPlaneNodes list ^ was updated to include sample-3.

Showing inventory of node3_from
-------------------------------
apiVersion: v1
data:
  inventory: |
    all:
        hosts:
            openstackdataplanenode-sample-3-from-inheritance:
                ansible_host: 192.168.122.20
                ansible_port: "22"
                ansible_user: root
                managed: "false"
                management_network: ctlplane
                network_config: '{template: {}}'
                networks: '[{fixedIP: 192.168.122.20, network: ctlplane}]'
kind: ConfigMap
metadata:
  creationTimestamp: "2023-02-27T23:03:49Z"
  name: dataplanenode-openstackdataplanenode-sample-3-from-inheritance-inventory
  namespace: openstack
  resourceVersion: "25894232"
  uid: c0a8e1bb-7344-4906-a717-d23eccc613c7

Note that the sample-3 inherited from its role's template (e.g. ansible port)

Deleting inventory created by the node
configmap "dataplanenode-openstackdataplanenode-sample-3-from-inheritance-inventory" deleted
Deleting node
openstackdataplanenode.dataplane.openstack.org "openstackdataplanenode-sample-3-from-inheritance" deleted
Deleting role
openstackdataplanerole.dataplane.openstack.org "openstackdataplanerole-sample-inheritance" deleted
[fultonj@osp-storage-01 inheritance]$ 
```
