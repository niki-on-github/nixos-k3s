# [VolSync](https://github.com/backube/volsync)

VolSync is a Kubernetes operator that performs asynchronous replication of persistent volumes within, or across, clusters. The replication provided by VolSync is independent of the storage system. This allows replication to and from storage types that don’t normally support remote replication. Additionally, it can replicate across different types (and vendors) of storage.

## Notes

You may need to add the following to you namespace `annotations` to get access to all files for the backup process (root):

```yaml
volsync.backube/privileged-movers: "true"
```
