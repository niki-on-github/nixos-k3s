# [democratic-csi](https://github.com/democratic-csi/democratic-csi)

democratic-csi implements the csi (container storage interface) spec providing storage for various container orchestration systems (ie: Kubernetes).

The current drivers implement the depth and breadth of the csi spec, so you have access to resizing, snapshots, clones, etc functionality.

## local-hostpath

This driver provisions node-local storage. I choose this implementation because it allows to reuse a volume on re-provisioning by using the `idTemplate`. Of course, this only makes sense on a single node cluster.
