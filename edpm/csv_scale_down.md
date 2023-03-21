# Scale down a service for local development

`make openstack` deploys operators including the DPO
([Data Plane Operator](https://github.com/openstack-k8s-operators/dataplane-operator)).

When running a local copy of the operator with commands like the
following conflicts might occur and you might get more than one
operator trying to reconcile your CR. To avoid the conflict scale
down the operator deployed by the meta operator by removing it from
the CSV.

```
cd ~/dataplane-operator
make manifests generate build
OPERATOR_TEMPLATES=$PWD/templates ./bin/manager
```

## Removing a service from the CSV

Query the CSV to identify the index of the service you want to scale down.
```
oc get csv openstack-operator.v0.0.1 -o json \
  | jq -r '.spec.install.spec.deployments[].name'
```
Update the CSV
```
oc patch csv openstack-baremetal-operator.v0.0.1 --type json \
  -p='[{"op": "remove", "path": "/spec/install/spec/deployments/<index>"}]'
```

## Explanation Provided by ChatGPT

In Kubernetes, CSV (Cluster Service Version) is a Custom Resource Definition (CRD) that enables the operator to manage the lifecycle of a specific application in a Kubernetes cluster. The CSV defines the deployment strategy, dependencies, and upgrade paths for the application.

To remove a deployment from the CSV, you need to update the CSV file and remove the reference to the deployment. Here are the steps to do so:

1. Use the kubectl get csv command to get the name of the CSV that contains the deployment you want to remove.

2. Use the kubectl edit csv <csv-name> command to open the CSV in an editor. This command will open the YAML file for the CSV in the default editor specified by your system.

3. Locate the spec.install.spec.deployments section in the YAML file. This section contains a list of all the deployments managed by the CSV.

4. Remove the deployment that you want to delete from the list. Save the changes and close the editor.

5. Verify that the deployment has been removed by running the kubectl get deployments command. The deployment should no longer be listed.

Note: Removing a deployment from the CSV does not delete the deployment from the cluster. You need to delete the deployment manually using the kubectl delete deployment <deployment-name> command.
