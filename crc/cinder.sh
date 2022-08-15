#!/bin/bash

if [[ ! -d ~/install_yamls ]]; then
    echo "~/install_yamls missing (did you run crc.sh?)"
    exit 1
fi

eval $(crc oc-env)
oc login -u kubeadmin -p 12345678 https://api.crc.testing:6443

pushd ~/install_yamls

# The following was used for rabbit but does not have cinder
# https://github.com/openstack-k8s-operators/install_yamls/pull/4/files
git reset --hard

# make cinder
# Pull abay's image until the following becomes the default
# https://github.com/openstack-k8s-operators/cinder-operator/pull/7
CINDER_IMG=quay.io/andrewbays/cinder-operator-index:v0.0.4 make cinder

sleep 60

cat > cinder.yaml << EOF
apiVersion: cinder.openstack.org/v1beta1
kind: Cinder
metadata:
  name: cinder
  namespace: openstack
spec:
  serviceUser: cinder
  customServiceConfig: |
    [DEFAULT]
    debug = true
    transport_url=rabbit://$(oc get secret sample-default-user -o json | jq -r '.data.username' | base64 -d):$(oc get secret sample-default-user -o json | jq -r '.data.password' | base64 -d)@sample.openstack.svc:5672
  defaultConfigOverwrite:
    nfs_shares: |
      # nfs shares
      10.0.0.1:/nfsshare
  databaseInstance: openstack
  databaseUser: cinder
  cinderAPI:
    replicas: 1
    containerImage: docker.io/tripleomaster/centos-binary-cinder-api:current-tripleo
    customServiceConfig: |
      # Custom API Conf
  cinderScheduler:
    replicas: 1
    containerImage: docker.io/tripleomaster/centos-binary-cinder-scheduler:current-tripleo
    customServiceConfig: |
      # Custom Scheduler Conf
  cinderBackup:
    replicas: 1
    containerImage: docker.io/tripleomaster/centos-binary-cinder-backup:current-tripleo
    customServiceConfig: |
      # Custom Backup Conf
  secret: osp-secret
  cinderVolumes:
    volume1:
      containerImage: docker.io/tripleomaster/centos-binary-cinder-volume:current-tripleo
      replicas: 1
      customServiceConfig: |
        [DEFAULT]
        enabled_backends = nfs
        [nfs]
        backend_host=hostgroup
        volume_backend_name=nfs
        volume_driver=cinder.volume.drivers.nfs.NfsDriver
        nfs_shares_config=/etc/cinder/nfs_shares
EOF

oc apply -f cinder.yaml

popd

oc get pods -l service=cinder


export OS_CLOUD=default
export OS_PASSWORD=12345678

openstack service list
openstack endpoint list
openstack volume list
