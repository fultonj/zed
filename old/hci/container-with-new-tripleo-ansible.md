# Make container with updated tripleo-ansible

These are my notes on creating your own version of 
`quay.io/tripleomastercentos9/openstack-tripleo-ansible-ee`
with updated tripleo-ansible. It is based
on [https://quay.io/tutorial](https://quay.io/tutorial).

- Download the container
```
podman pull quay.io/tripleomastercentos9/openstack-tripleo-ansible-ee
```

- Idenitfy the IMAGE_ID
```
IMAGE_ID=$(podman images --filter reference=openstack-tripleo-ansible-ee --format "{{.Id}}")
```

- Run the container to create a CONTAINER_ID
```
podman run $IMAGE_ID ls -l
CONTAINER_ID=$(podman ps -ql)
```

- Update the container
```
podman cp ./tripleo_ansible/roles/tripleo_cephadm/tasks/pre.yaml $CONTAINER_ID:/usr/share/ansible/roles/tripleo_cephadm/tasks/pre.yaml
```
In the example above I'm in the tripleo-ansible directory which has
checked out the following branch with the change I want to apply:
[https://review.opendev.org/c/openstack/tripleo-ansible/+/869360](https://review.opendev.org/c/openstack/tripleo-ansible/+/869360)

- Commit the change
```
podman commit $CONTAINER_ID quay.io/fultonj/openstack-tripleo-ansible-ee-ceph
```

- Login to quay
```
podman login -u="fultonj" -p="$QUAY_PASSWORD" quay.io
```

- Push the change
```
podman push quay.io/fultonj/openstack-tripleo-ansible-ee-ceph
```
