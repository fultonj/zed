#!/bin/bash

if [ $# -eq 0 ]; then
    CINDER_REPLICAS=1
else
    CINDER_REPLICAS=$1
fi

OUT=core_v1beta1_openstackcontrolplane_ceph_backend.yaml

declare -A cephBackend
for KEY in cephFsid cephMons cephClientKey cephUser; do
    cephBackend[$KEY]=$(grep $KEY ~/cephBackend | awk {'print $2'} | sed s/\"//g)
done;
for KEY in glance cinder backup; do
    cephBackend[$KEY]=$(grep $KEY ~/cephBackend -A 1 | head -2 \
                            | tail -1 | awk {'print $2'} | sed s/\"//g)
done

RABBIT_SECRET=rabbitmq-default-user
TRANSPORT_URL=rabbit://$(oc get secret $RABBIT_SECRET -o json | jq -r '.data.username' | base64 -d):$(oc get secret $RABBIT_SECRET -o json | jq -r '.data.password' | base64 -d)@rabbitmq.openstack.svc:5672


cat <<EOF > $OUT
---
apiVersion: core.openstack.org/v1beta1
kind: OpenStackControlPlane
metadata:
  name: openstack
spec:
  secret: osp-secret
  storageClass: local-storage
  keystoneTemplate:
    containerImage: quay.io/tripleowallabycentos9/openstack-keystone:current-tripleo
    databaseInstance: openstack
  mariadbTemplate:
    containerImage: quay.io/tripleowallabycentos9/openstack-mariadb:current-tripleo
    storageRequest: 500M
  rabbitmqTemplate:
    replicas: 1
  placementTemplate:
    containerImage: quay.io/tripleowallabycentos9/openstack-placement-api:current-tripleo
  glanceTemplate:
    serviceUser: glance
    databaseInstance: openstack
    databaseUser: glance
    secret: osp-secret
    containerImage: quay.io/tripleowallabycentos9/openstack-glance-api:current-tripleo
    storageClass: 
    storageRequest: 1G
    customServiceConfig: |
      [DEFAULT]
      debug = true
      enabled_backends=default_backend:rbd
      [glance_store]
      default_backend=default_backend
      [default_backend]
      rbd_store_ceph_conf=/etc/ceph/ceph.conf
      rbd_store_user=${cephBackend[cephUser]}
      rbd_store_pool=${cephBackend[glance]}
      store_description=Ceph glance store backend.
    glanceAPIInternal:
      debug:
        service: false
      preserveJobs: false
      replicas: 1
    glanceAPIExternal:
      debug:
        service: false
      preserveJobs: false
      replicas: 1
    cephBackend:
      cephFsid: ${cephBackend[cephFsid]}
      cephMons: ${cephBackend[cephMons]}
      cephClientKey: ${cephBackend[cephClientKey]}
      cephUser: ${cephBackend[cephUser]}
      cephPools:
        cinder:
          name: ${cephBackend[glance]}
  cinderTemplate:
    customServiceConfig: |
      [DEFAULT]
      debug = true
      transport_url=$TRANSPORT_URL
    databaseInstance: openstack
    databaseUser: cinder
    cinderAPI:
      replicas: $CINDER_REPLICAS
      containerImage: quay.io/tripleowallabycentos9/openstack-cinder-api:current-tripleo
      debug:
        initContainer: false
        service: false
    cinderScheduler:
      replicas: $CINDER_REPLICAS
      containerImage: quay.io/tripleowallabycentos9/openstack-cinder-scheduler:current-tripleo
      debug:
        initContainer: false
        service: false
    cinderBackup:
      replicas: $CINDER_REPLICAS
      containerImage: quay.io/tripleowallabycentos9/openstack-cinder-backup:current-tripleo
      customServiceConfig: |
        [DEFAULT]
        backup_driver = cinder.backup.drivers.ceph.CephBackupDriver
        backup_ceph_pool = ${cephBackend[backup]}
        backup_ceph_user = ${cephBackend[cephUser]}
      debug:
        initContainer: false
        service: false
    secret: osp-secret
    cinderVolumes:
      volume1:
        containerImage: quay.io/tripleowallabycentos9/openstack-cinder-volume:current-tripleo
        replicas: 0
        # keep at zero since volume1 is a fake
      ceph:
        containerImage: quay.io/tripleowallabycentos9/openstack-cinder-volume:current-tripleo
        replicas: $CINDER_REPLICAS
        customServiceConfig: |
          [DEFAULT]
          enabled_backends=ceph
          [ceph]
          backend_host=hostgroup
          volume_backend_name=ceph
          volume_driver=cinder.volume.drivers.rbd.RBDDriver
          rbd_ceph_conf=/etc/ceph/ceph.conf
          rbd_user=${cephBackend[cephUser]}
          rbd_pool=${cephBackend[cinder]}
          rbd_flatten_volume_from_snapshot=False
          # will need this to be a real uuid when Nova is available
          rbd_secret_uuid=604c9994-1d82-11ed-8ae5-5254003d6107
          report_discard_supported=True
        debug:
          initContainer: false
          service: false
    cephBackend:
      cephFsid: ${cephBackend[cephFsid]}
      cephMons: ${cephBackend[cephMons]}
      cephClientKey: ${cephBackend[cephClientKey]}
      cephUser: ${cephBackend[cephUser]}
      cephPools:
        cinder:
          name: ${cephBackend[cinder]}
EOF

echo "oc apply -f $OUT"
