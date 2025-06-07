# Backup

## Browser

Use [restic-browser](https://github.com/emuell/restic-browser) to browse the volsync backup.

Connection settings:

- Type: Amazon S3
- Bucket: `external-minio.{DOMAIN}/volsync/{BUCKET}` e.g. `external-minio.k8s.lan/volsync/gitea`
- AWS_ACCESS_KEY_ID: run `sudo grep "MINIO_ROOT_USER" /run/agenix/minio-credentials` on server 
- AWS_SECRET_ACCESS_KEY: run `sudo grep "MINIO_ROOT_PASSWORD" /run/agenix/minio-credentials` on server
- Repository Password: see `SECRET_VOLSYNC_RESTIC_PASSWORD` in `cluster-secrets.sops.yaml`


## Integrity Check and Repair

start with:

```sh
sudo btrfs scrub start /mnt/backup
```

get status with:

```sh
sudo btrfs scrub status /mnt/backup
```


## Replace Disk

Run all commands as root. Prepare new disk with:

```
wipefs --force --quiet --all /dev/disk/by-id/$disk
parted --script /dev/disk/by-id/$disk mklabel gpt
parted --script /dev/disk/by-id/$disk mkpart primary 1MiB 100% name 1 luks_$label
cryptsetup luksFormat --batch-mode /dev/disk/by-id/$disk-part1 /etc/secrets/disk.key
cryptsetup luksAddKey /dev/disk/by-id/$disk-part1 -d /etc/secrets/disk.key
cryptsetup open /dev/disk/by-id/$disk-part1 $label --key-file /etc/secrets/disk.key
```

### Replace

When the old disk is readable:

1. determine the device id (1,2,...): `btrfs filesystem show`
2. start backroudn replacement process: `btrfs replace start $DEVID /dev/mapper/luks_$label /mnt/backup`
3. monitor process with: `btrfs replace status /mnt/backup`

Advantages of Replace method:

- The btrfs replace command is faster than the balance method.
- The replacement can be used on a live, mounted filesystem

### Balance

When the disk is completely unreadable or missing:

1. Mount the Filesystem in Degraded Mode: `mkdir -p /tmp/recovery && mount -o degraded /tmp/recovery`
2. `btrfs device add /dev/mapper/luks_$label /tmp/recovery`
3. `btrfs device remove missing /tmp/recovery`
4. `btrfs balance start /tmp/recovery`
