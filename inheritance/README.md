# Naive Test for Inheritance

[naive_inheritance.sh](naive_inheritance.sh) is a CLI test of what's
described here:

https://openstack-k8s-operators.github.io/dataplane-operator/inheritance

The logic of this test should probably later be moved to:

https://github.com/openstack-k8s-operators/dataplane-operator/blob/main/controllers/suite_test.go

We should be able to create [role.yaml](role.yaml) and 
have [node1.yaml](node1.yaml) and [node2.yaml](node2.yaml)
created automatically. The test has an option to fake it
to see how things should look when it's done. 

For now when I run the test with this change to print the inventory

```diff
[fultonj@osp-storage-01 dataplane-operator]$ git diff controllers/openstackdataplanenode_controller.go
diff --git a/controllers/openstackdataplanenode_controller.go b/controllers/openstackdataplanenode_controller.go
index cf04365..00ed9d3 100644
--- a/controllers/openstackdataplanenode_controller.go
+++ b/controllers/openstackdataplanenode_controller.go
@@ -162,6 +162,7 @@ func (r *OpenStackDataPlaneNodeReconciler) GenerateInventory(ctx context.Context
                cm.Data = map[string]string{
                        "inventory": string(invData),
                }
+               fmt.Printf("inv: %s", string(invData))
                return nil
        })
        if err != nil {
[fultonj@osp-storage-01 dataplane-operator]$ 
```
I see this:
```yaml
inv: all:
  hosts:
    openstackdataplanenode-sample-inheritance-2:
      ansible_host: openstackdataplanenode-sample-2.localdomain
      ansible_port: "0"
      ansible_user: ""
```
So it's not inheriting port 22 and it's not creating the nodes automatically.

## Sample Output

1. Defaults
```bash
[fultonj@osp-storage-01 inheritance]$ ./naive_inheritance.sh 
~/zed/inheritance ~/zed/inheritance
Login successful.

You have access to 66 projects, the list has been suppressed. You can list all projects with 'oc projects'

Using project "openstack".
openstackdataplanerole.dataplane.openstack.org/openstackdataplanerole-sample-inheritance created
NAME                                        AGE
openstackdataplanerole-sample               5d23h
openstackdataplanerole-sample-inheritance   0s
Zero nodes were created (but two should have been)
openstackdataplanerole.dataplane.openstack.org "openstackdataplanerole-sample-inheritance" deleted
~/zed/inheritance
[fultonj@osp-storage-01 inheritance]$ 
```

2. Fake it

```bash
[fultonj@osp-storage-01 inheritance]$ ./naive_inheritance.sh 
~/zed/inheritance ~/zed/inheritance
Login successful.

You have access to 66 projects, the list has been suppressed. You can list all projects with 'oc projects'

Using project "openstack".
openstackdataplanerole.dataplane.openstack.org/openstackdataplanerole-sample-inheritance created
NAME                                        AGE
openstackdataplanerole-sample               5d23h
openstackdataplanerole-sample-inheritance   0s
Zero nodes were created (but two should have been)
Faking it by directly creating node1 and node2
openstackdataplanenode.dataplane.openstack.org/openstackdataplanenode-sample-inheritance-1 created
openstackdataplanenode.dataplane.openstack.org/openstackdataplanenode-sample-inheritance-2 created
2 inheritance nodes were created
NAME                                          AGE
openstackdataplanenode-sample                 5d23h
openstackdataplanenode-sample-inheritance-1   0s
openstackdataplanenode-sample-inheritance-2   0s
openstackdataplanenode.dataplane.openstack.org "openstackdataplanenode-sample-inheritance-1" deleted
openstackdataplanenode.dataplane.openstack.org "openstackdataplanenode-sample-inheritance-2" deleted
openstackdataplanerole.dataplane.openstack.org "openstackdataplanerole-sample-inheritance" deleted
~/zed/inheritance
[fultonj@osp-storage-01 inheritance]$ 
```
3. Do not fake it but use verbosity:
```bash
[fultonj@osp-storage-01 inheritance]$ ./naive_inheritance.sh 
~/zed/inheritance ~/zed/inheritance
Login successful.

You have access to 66 projects, the list has been suppressed. You can list all projects with 'oc projects'

Using project "openstack".
openstackdataplanerole.dataplane.openstack.org/openstackdataplanerole-sample-inheritance created
NAME                                        AGE
openstackdataplanerole-sample               5d23h
openstackdataplanerole-sample-inheritance   0s
{
  "apiVersion": "dataplane.openstack.org/v1beta1",
  "kind": "OpenStackDataPlaneRole",
  "metadata": {
    "creationTimestamp": "2023-02-02T15:37:03Z",
    "generation": 1,
    "name": "openstackdataplanerole-sample-inheritance",
    "namespace": "openstack",
    "resourceVersion": "8372422",
    "uid": "385e38af-294f-4384-9395-b5cc28df20e0"
  },
  "spec": {
    "dataPlaneNodes": [
      {
        "node": {
          "ansibleHost": "192.168.122.18",
          "hostName": "openstackdataplanenode-sample-1.localdomain",
          "networks": [
            {
              "fixedIP": "192.168.122.18"
            }
          ]
        }
      },
      {
        "node": {
          "ansibleHost": "192.168.122.19",
          "hostName": "openstackdataplanenode-sample-2.localdomain",
          "networks": [
            {
              "fixedIP": "192.168.122.19"
            }
          ]
        }
      }
    ],
    "nodeTemplate": {
      "ansiblePort": 22,
      "ansibleUser": "root",
      "managed": false,
      "managementNetwork": "ctlplane",
      "networkConfig": {
        "template": "templates/net_config_bridge.j2"
      }
    }
  }
}
Zero nodes were created (but two should have been)
null
null
openstackdataplanerole.dataplane.openstack.org "openstackdataplanerole-sample-inheritance" deleted
~/zed/inheritance
[fultonj@osp-storage-01 inheritance]$ 
```
4. Fake it with verbosity:
```bash
[fultonj@osp-storage-01 inheritance]$ ./naive_inheritance.sh 
~/zed/inheritance ~/zed/inheritance
Login successful.

You have access to 66 projects, the list has been suppressed. You can list all projects with 'oc projects'

Using project "openstack".
openstackdataplanerole.dataplane.openstack.org/openstackdataplanerole-sample-inheritance created
NAME                                        AGE
openstackdataplanerole-sample               5d23h
openstackdataplanerole-sample-inheritance   0s
{
  "apiVersion": "dataplane.openstack.org/v1beta1",
  "kind": "OpenStackDataPlaneRole",
  "metadata": {
    "creationTimestamp": "2023-02-02T15:37:21Z",
    "generation": 1,
    "name": "openstackdataplanerole-sample-inheritance",
    "namespace": "openstack",
    "resourceVersion": "8372597",
    "uid": "8642e63e-0bb9-4d6f-a1bf-3455bd80b398"
  },
  "spec": {
    "dataPlaneNodes": [
      {
        "node": {
          "ansibleHost": "192.168.122.18",
          "hostName": "openstackdataplanenode-sample-1.localdomain",
          "networks": [
            {
              "fixedIP": "192.168.122.18"
            }
          ]
        }
      },
      {
        "node": {
          "ansibleHost": "192.168.122.19",
          "hostName": "openstackdataplanenode-sample-2.localdomain",
          "networks": [
            {
              "fixedIP": "192.168.122.19"
            }
          ]
        }
      }
    ],
    "nodeTemplate": {
      "ansiblePort": 22,
      "ansibleUser": "root",
      "managed": false,
      "managementNetwork": "ctlplane",
      "networkConfig": {
        "template": "templates/net_config_bridge.j2"
      }
    }
  }
}
Zero nodes were created (but two should have been)
null
null
Faking it by directly creating node1 and node2
openstackdataplanenode.dataplane.openstack.org/openstackdataplanenode-sample-inheritance-1 created
openstackdataplanenode.dataplane.openstack.org/openstackdataplanenode-sample-inheritance-2 created
2 inheritance nodes were created
NAME                                          AGE
openstackdataplanenode-sample                 5d23h
openstackdataplanenode-sample-inheritance-1   1s
openstackdataplanenode-sample-inheritance-2   1s
{
  "apiVersion": "dataplane.openstack.org/v1beta1",
  "kind": "OpenStackDataPlaneNode",
  "metadata": {
    "creationTimestamp": "2023-02-02T15:37:21Z",
    "generation": 1,
    "name": "openstackdataplanenode-sample-inheritance-1",
    "namespace": "openstack",
    "resourceVersion": "8372598",
    "uid": "f2bd82d4-6bc2-4c66-a846-dd02119bea3d"
  },
  "spec": {
    "node": {
      "ansibleHost": "192.168.122.18",
      "hostName": "openstackdataplanenode-sample-1.localdomain",
      "networks": [
        {
          "fixedIP": "192.168.122.18"
        }
      ]
    }
  }
}
{
  "apiVersion": "dataplane.openstack.org/v1beta1",
  "kind": "OpenStackDataPlaneNode",
  "metadata": {
    "creationTimestamp": "2023-02-02T15:37:21Z",
    "generation": 1,
    "name": "openstackdataplanenode-sample-inheritance-2",
    "namespace": "openstack",
    "resourceVersion": "8372599",
    "uid": "a468ef82-377d-44d5-b5cb-eda2ed42ad95"
  },
  "spec": {
    "node": {
      "ansibleHost": "192.168.122.19",
      "hostName": "openstackdataplanenode-sample-2.localdomain",
      "networks": [
        {
          "fixedIP": "192.168.122.19"
        }
      ]
    }
  }
}
openstackdataplanenode.dataplane.openstack.org "openstackdataplanenode-sample-inheritance-1" deleted
openstackdataplanenode.dataplane.openstack.org "openstackdataplanenode-sample-inheritance-2" deleted
openstackdataplanerole.dataplane.openstack.org "openstackdataplanerole-sample-inheritance" deleted
~/zed/inheritance
[fultonj@osp-storage-01 inheritance]$ 
```
