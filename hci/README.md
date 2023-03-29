# HCI Proof of Concept (Work in Progress)

## High Level Deployment

1. Deploy OpenShift on a set of servers
2. Deploy RHEL on a set of servers (minimum 3)
3. Install Ceph on the RHEL systems from step 2
4. Create OpenStack pools on Ceph cluster and export cephx/ceph.conf to an OpenShift Ceph secret
5. Create CR to deploy OpenStack (which uses Ceph secret)
6. Create CR to have AnsibleEE configure RHEL as Nova Compute

Nova Compute and Ceph will collocate the same RHEL node.
The Ansible triggered in step 6 could also validate the following:

- That the Ceph cluster was deployed correctly
- That Ceph or Nova are tuned for HCI
- Optionally, they could change Ceph or Nova

This extends the "bring your own RHEL" concept to "bring your own
Ceph" for installation and day 2 management even though there is
collocation.

## Proof of Concept Environment

One large hypervisor with the following virtual machines:

- CRC
- edpm-compute-0
- edpm-compute-1
- edpm-compute-2

## Deployment Scripts

As of March 2023 I'm deploying HCI as described under
[ng/ceph](../ng/ceph).

The scripts here along with the [old docs](old_hci.md) are obsolete.
