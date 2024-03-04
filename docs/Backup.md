# Backup

## Browser

Use [restic-browser](https://github.com/emuell/restic-browser) to browse the volsync backup.

Connection settings:

- Type: Amazon S3
- Bucket: `external-minio.{DOMAIN}/volsync/{BUCKET}` e.g. `external-minio.k8s.lan/volsync/gitea`
- AWS_ACCESS_KEY_ID: run `grep "MINIO_ROOT_USER" /run/agenix/minio-credentials` on server 
- AWS_SECRET_ACCESS_KEY: run `grep "MINIO_ROOT_PASSWORD" /run/agenix/minio-credentials` on server
- Repository Password: see `SECRET_VOLSYNC_RESTIC_PASSWORD` in `cluster-secrets.sops.yaml`
